// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@solidstate/contracts/access/OwnableInternal.sol';
import '@solidstate/contracts/token/ERC20/ERC20.sol';
import '@solidstate/contracts/token/ERC20/IERC20.sol';
import '@solidstate/contracts/token/ERC1155/ERC1155Enumerable.sol';
import '@solidstate/contracts/utils/IWETH.sol';

import '../pair/IPair.sol';
import './PoolStorage.sol';

import { ABDKMath64x64 } from 'abdk-libraries-solidity/ABDKMath64x64.sol';
import { ABDKMath64x64Token } from '../libraries/ABDKMath64x64Token.sol';
import { OptionMath } from '../libraries/OptionMath.sol';

// TODO: handle safe-transfer reverts

/**
 * @title Median option pool
 * @dev deployed standalone and referenced by PoolProxy
 */
contract Pool is OwnableInternal, ERC20, ERC1155Enumerable {
  using ABDKMath64x64 for int128;
  using ABDKMath64x64Token for int128;
  using EnumerableSet for EnumerableSet.AddressSet;
  using PoolStorage for PoolStorage.Layout;

  enum TokenType { LONG_CALL, SHORT_CALL }

  address private immutable WETH_ADDRESS;

  constructor (
    address weth
  ) {
    WETH_ADDRESS = weth;
  }

  /**
   * @notice get address of PairProxy contract
   * @return pair address
   */
  function getPair () external view returns (address) {
    return PoolStorage.layout().pair;
  }

  /**
   * @notice calculate price of option contract
   * @param variance64x64 64x64 fixed point representation of variance
   * @param maturity timestamp of option maturity
   * @param strike64x64 64x64 fixed point representation of strike price
   * @param spot64x64 64x64 fixed point representation of spot price
   * @param amount size of option contract
   * @return cost64x64 64x64 fixed point representation of option cost denominated in underlying currency
   * @return cLevel64x64 64x64 fixed point representation of C-Level of Pool after purchase
   */
  function quote (
    int128 variance64x64,
    uint64 maturity,
    int128 strike64x64,
    int128 spot64x64,
    uint256 amount
  ) public view returns (int128 cost64x64, int128 cLevel64x64) {
    PoolStorage.Layout storage l = PoolStorage.layout();

    int128 timeToMaturity64x64 = ABDKMath64x64.divu(maturity - block.timestamp, 365 days);

    int128 amount64x64 = ABDKMath64x64Token.fromDecimals(amount, l.underlyingDecimals);
    int128 oldLiquidity64x64 = l.totalSupply64x64();
    int128 newLiquidity64x64 = oldLiquidity64x64.sub(amount64x64);

    // TODO: validate values without spending gas
    // assert(oldLiquidity64x64 >= newLiquidity64x64);
    // assert(variance64x64 > 0);
    // assert(strike64x64 > 0);
    // assert(spot64x64 > 0);
    // assert(timeToMaturity64x64 > 0);

    int128 price64x64;

    (price64x64, cLevel64x64) = OptionMath.quotePrice(
      variance64x64,
      strike64x64,
      spot64x64,
      timeToMaturity64x64,
      l.cLevel64x64,
      oldLiquidity64x64,
      newLiquidity64x64,
      OptionMath.ONE_64x64,
      true
    );

    cost64x64 = price64x64.mul(amount64x64).mul(
      OptionMath.ONE_64x64.add(l.fee64x64)
    ).mul(spot64x64);
  }

  /**
   * @notice purchase call option
   * @param maturity timestamp of option maturity
   * @param strike64x64 64x64 fixed point representation of strike price
   * @param amount size of option contract
   * @param maxCost maximum acceptable cost after accounting for slippage
   * @return cost quantity of tokens required to purchase long position
   */
  function purchase (
    uint64 maturity,
    int128 strike64x64,
    uint256 amount,
    uint256 maxCost
  ) external payable returns (uint256 cost) {
    // TODO: specify payment currency

    require(amount <= totalSupply(), 'Pool: insufficient liquidity');

    require(maturity >= block.timestamp + (1 days), 'Pool: maturity must be at least 1 day in the future');
    require(maturity < block.timestamp + (29 days), 'Pool: maturity must be at most 28 days in the future');
    require(maturity % (1 days) == 0, 'Pool: maturity must correspond to end of UTC day');

    PoolStorage.Layout storage l = PoolStorage.layout();

    (int128 spot64x64, int128 variance64x64) = IPair(l.pair).updateAndGetLatestData();

    require(strike64x64 <= spot64x64 << 1, 'Pool: strike price must not exceed two times spot price');
    require(strike64x64 >= spot64x64 >> 1, 'Pool: strike price must be at least one half spot price');

    (int128 cost64x64, int128 cLevel64x64) = quote(
      variance64x64,
      maturity,
      strike64x64,
      spot64x64,
      amount
    );

    cost = cost64x64.toDecimals(l.underlyingDecimals);
    uint256 fee = cost64x64.mul(l.fee64x64).div(
      OptionMath.ONE_64x64.add(l.fee64x64)
    ).toDecimals(l.underlyingDecimals);

    require(cost <= maxCost, 'Pool: excessive slippage');
    _pull(l.underlying, cost);

    // mint free liquidity tokens for treasury (ERC20)
    _mint(l.treasury, fee);

    // mint long option token for buyer (ERC1155)
    _mint(msg.sender, _tokenIdFor(TokenType.LONG_CALL, maturity, strike64x64), amount, '');

    // remaining premia to be distributed to underwriters
    uint256 costRemaining = cost - fee;

    uint256 shortTokenId = _tokenIdFor(TokenType.SHORT_CALL, maturity, strike64x64);
    address underwriter;

    while (amount > 0) {
      underwriter = l.liquidityQueueAscending[underwriter];

      // amount of liquidity provided by underwriter, accounting for reinvested premium
      uint256 intervalAmount = balanceOf(underwriter) * (amount + costRemaining) / amount;
      if (amount < intervalAmount) intervalAmount = amount;
      amount -= intervalAmount;

      // amount of premium paid to underwriter
      uint256 intervalCost = costRemaining * intervalAmount / amount;
      costRemaining -= intervalCost;

      // burn free liquidity tokens from underwriter (ERC20)
      _burn(underwriter, intervalAmount - intervalCost);
      // mint short option token for underwriter (ERC1155)
      _mint(underwriter, shortTokenId, intervalAmount, '');
    }

    // update C-Level, accounting for slippage and reinvested premia separately

    int128 totalSupply64x64 = l.totalSupply64x64();

    l.cLevel64x64 = OptionMath.calculateCLevel(
      cLevel64x64, // C-Level after liquidity is reserved
      totalSupply64x64.sub(cost64x64),
      totalSupply64x64,
      OptionMath.ONE_64x64
    );
  }

  /**
   * @notice exercise call option
   * @param tokenId ERC1155 token id
   * @param amount quantity of option contract tokens to exercise
   */
  function exercise (
    uint256 tokenId,
    uint256 amount
  ) public {
    (TokenType tokenType, uint64 maturity, int128 strike64x64) = _parametersFor(tokenId);
    require(tokenType == TokenType.LONG_CALL, 'Pool: invalid token type');

    PoolStorage.Layout storage l = PoolStorage.layout();

    int128 spot64x64 = IPair(l.pair).updateAndGetHistoricalPrice(
      maturity < block.timestamp ? maturity : block.timestamp
    );

    // burn long option tokens from sender (ERC1155)
    _burn(msg.sender, tokenId, amount);

    uint256 exerciseValue;
    uint256 amountRemaining = amount;

    if (spot64x64 > strike64x64) {
      // option has a non-zero exercise value
      exerciseValue = spot64x64.sub(strike64x64).div(spot64x64).mulu(amount);
      _push(l.underlying, exerciseValue);
      amountRemaining -= exerciseValue;
    }

    int128 oldLiquidity64x64 = l.totalSupply64x64();

    uint256 shortTokenId = _tokenIdFor(TokenType.SHORT_CALL, maturity, strike64x64);
    EnumerableSet.AddressSet storage underwriters = ERC1155EnumerableStorage.layout().accountsByToken[shortTokenId];

    while (amount > 0) {
      address underwriter = underwriters.at(underwriters.length() - 1);

      // amount of liquidity provided by underwriter
      uint256 intervalAmount = balanceOf(underwriter, shortTokenId);
      if (amountRemaining < intervalAmount) intervalAmount = amountRemaining;

      // amount of liquidity returned to underwriter, accounting for premium earned by buyer
      uint256 freedAmount = intervalAmount * (amount - exerciseValue) / amount;
      amountRemaining -= freedAmount;

      // mint free liquidity tokens for underwriter (ERC20)
      _mint(underwriter, freedAmount);
      // burn short option tokens from underwriter (ERC1155)
      _burn(underwriter, shortTokenId, intervalAmount);
    }

    int128 newLiquidity64x64 = l.totalSupply64x64();

    l.setCLevel(oldLiquidity64x64, newLiquidity64x64);
  }

  /**
   * @notice deposit underlying currency, underwriting calls of that currency with respect to base currency
   * @param amount quantity of underlying currency to deposit
   */
  function deposit (
    uint256 amount
  ) external payable {
    PoolStorage.Layout storage l = PoolStorage.layout();

    l.depositedAt[msg.sender] = block.timestamp;

    _pull(l.underlying, amount);

    int128 oldLiquidity64x64 = l.totalSupply64x64();
    // mint free liquidity tokens for sender (ERC20)
    _mint(msg.sender, amount);
    int128 newLiquidity64x64 = l.totalSupply64x64();

    l.setCLevel(oldLiquidity64x64, newLiquidity64x64);
  }

  /**
   * @notice redeem pool share tokens for underlying asset
   * @param amount quantity of share tokens to redeem
   */
  function withdraw (
    uint256 amount
  ) external {
    PoolStorage.Layout storage l = PoolStorage.layout();

    require(
      l.depositedAt[msg.sender] + (1 days) < block.timestamp,
      'Pool: liquidity must remain locked for 1 day'
    );

    int128 oldLiquidity64x64 = l.totalSupply64x64();
    // burn free liquidity tokens from sender (ERC20)
    _burn(msg.sender, amount);
    int128 newLiquidity64x64 = l.totalSupply64x64();

    _push(l.underlying, amount);

    l.setCLevel(oldLiquidity64x64, newLiquidity64x64);
  }

  /**
   * @notice reassign short position to new liquidity provider
   * @param tokenId ERC1155 token id
   * @param amount quantity of option contract tokens to reassign
   * @return cost quantity of tokens required to reassign short position
   */
  function reassign (
    uint256 tokenId,
    uint256 amount
  ) external returns (uint256 cost) {
    (TokenType tokenType, uint64 maturity, int128 strike64x64) = _parametersFor(tokenId);
    require(tokenType == TokenType.SHORT_CALL, 'Pool: invalid token type');
    require(maturity > block.timestamp, 'Pool: option must not be expired');

    // TODO: allow exit of expired position

    PoolStorage.Layout storage l = PoolStorage.layout();

    uint256 costRemaining;

    {
      (int128 spot64x64, int128 variance64x64) = IPair(l.pair).updateAndGetLatestData();
      (int128 cost64x64, int128 cLevel64x64) = quote(
        variance64x64,
        maturity,
        strike64x64,
        spot64x64,
        amount
      );

      cost = cost64x64.toDecimals(l.underlyingDecimals);
      uint256 fee = cost64x64.mul(l.fee64x64).div(
        OptionMath.ONE_64x64.add(l.fee64x64)
      ).toDecimals(l.underlyingDecimals);

      _push(l.underlying, amount - cost - fee);

      // update C-Level, accounting for slippage and reinvested premia separately

      int128 totalSupply64x64 = l.totalSupply64x64();

      l.cLevel64x64 = OptionMath.calculateCLevel(
        cLevel64x64, // C-Level after liquidity is reserved
        totalSupply64x64,
        totalSupply64x64.add(cost64x64),
        OptionMath.ONE_64x64
      );

      // mint free liquidity tokens for treasury (ERC20)
      _mint(l.treasury, fee);

      // remaining premia to be distributed to underwriters
      costRemaining = cost - fee;
    }

    address underwriter;

    while (amount > 0) {
      underwriter = l.liquidityQueueAscending[underwriter];

      // amount of liquidity provided by underwriter, accounting for reinvested premium
      uint256 intervalAmount = balanceOf(underwriter) * (amount + costRemaining) / amount;
      if (amount < intervalAmount) intervalAmount = amount;
      amount -= intervalAmount;

      // amount of premium paid to underwriter
      uint256 intervalCost = costRemaining * intervalAmount / amount;
      costRemaining -= intervalCost;

      // burn free liquidity tokens from underwriter (ERC20)
      _burn(underwriter, intervalAmount - intervalCost);
      // transfer short option token (ERC1155)
      _transfer(msg.sender, msg.sender, underwriter, tokenId, intervalAmount, '');
    }
  }

  /**
   * @notice calculate ERC1155 token id for given option parameters
   * @param tokenType TokenType enum
   * @param maturity timestamp of option maturity
   * @param strike64x64 64x64 fixed point representation of strike price
   * @return tokenId token id
   */
  function _tokenIdFor (
    TokenType tokenType,
    uint64 maturity,
    int128 strike64x64
  ) internal pure returns (uint256 tokenId) {
    assembly {
      tokenId := add(strike64x64, add(shl(128, maturity), shl(248, tokenType)))
    }
  }

  /**
   * @notice derive option maturity and strike price from ERC1155 token id
   * @param tokenId token id
   * @return tokenType TokenType enum
   * @return maturity timestamp of option maturity
   * @return strike64x64 option strike price
   */
  function _parametersFor (
    uint256 tokenId
  ) internal pure returns (TokenType tokenType, uint64 maturity, int128 strike64x64) {
    assembly {
      tokenType := shr(248, tokenId)
      maturity := shr(128, tokenId)
      strike64x64 := tokenId
    }
  }

  /**
   * @notice transfer ERC20 tokens to message sender
   * @param token ERC20 token address
   * @param amount quantity of token to transfer
   */
  function _push (
    address token,
    uint256 amount
  ) internal {
    require(
      IERC20(token).transfer(msg.sender, amount),
      'Pool: ERC20 transfer failed'
    );
  }

  /**
   * @notice transfer ERC20 tokens from message sender
   * @param token ERC20 token address
   * @param amount quantity of token to transfer
   */
  function _pull (
    address token,
    uint256 amount
  ) internal {
    if (token == WETH_ADDRESS) {
      amount -= msg.value;
      IWETH(WETH_ADDRESS).deposit{ value: msg.value }();
    } else {
      require(
        msg.value == 0,
        'Pool: function is payable only if deposit token is WETH'
      );
    }

    if (amount > 0) {
      require(
        IERC20(token).transferFrom(msg.sender, address(this), amount),
        'Pool: ERC20 transfer failed'
      );
    }
  }

  /**
   * @notice ERC20 hook: track eligible underwriters
   * @param from token sender
   * @param to token receiver
   * @param amount token quantity transferred
   */
  function _beforeTokenTransfer (
    address from,
    address to,
    uint256 amount
  ) override internal {
    super._beforeTokenTransfer(from, to, amount);

    // TODO: enforce minimum balance

    if (amount > 0) {
      PoolStorage.Layout storage l = PoolStorage.layout();

      if (from != address(0) && balanceOf(from) == amount) {
        l.removeUnderwriter(from);
      }

      if (to != address(0) && balanceOf(to) == 0) {
        l.addUnderwriter(to);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './OwnableStorage.sol';

abstract contract OwnableInternal {
  using OwnableStorage for OwnableStorage.Layout;

  modifier onlyOwner {
    require(
      msg.sender == OwnableStorage.layout().owner,
      'Ownable: sender must be owner'
    );
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC20Base.sol';
import './ERC20Extended.sol';
import './ERC20Metadata.sol';

abstract contract ERC20 is ERC20Base, ERC20Extended, ERC20Metadata {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  function totalSupply () external view returns (uint256);

  function balanceOf (
    address account
  ) external view returns (uint256);

  function transfer (
    address recipient,
    uint256 amount
  ) external returns (bool);

  function allowance (
    address owner,
    address spender
  ) external view returns (uint256);

  function approve (
    address spender,
    uint256 amount
  ) external returns (bool);

  function transferFrom (
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../utils/EnumerableSet.sol';
import './ERC1155Base.sol';
import './ERC1155EnumerableStorage.sol';

contract ERC1155Enumerable is ERC1155Base {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  function totalSupply (uint id) public view returns (uint) {
    return ERC1155EnumerableStorage.layout().totalSupply[id];
  }

  function totalHolders (uint id) public view returns (uint) {
    return ERC1155EnumerableStorage.layout().accountsByToken[id].length();
  }

  function accountsByToken (uint id) public view returns (address[] memory) {
    EnumerableSet.AddressSet storage accounts = ERC1155EnumerableStorage.layout().accountsByToken[id];

    address[] memory addresses = new address[](accounts.length());

    for (uint i; i < accounts.length(); i++) {
      addresses[i] = accounts.at(i);
    }

    return addresses;
  }

  function tokensByAccount (address account) public view returns (uint[] memory) {
    EnumerableSet.UintSet storage tokens = ERC1155EnumerableStorage.layout().tokensByAccount[account];

    uint[] memory ids = new uint[](tokens.length());

    for (uint i; i < tokens.length(); i++) {
      ids[i] = tokens.at(i);
    }

    return ids;
  }

  function _beforeTokenTransfer (
    address operator,
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) virtual override internal {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    if (from != to) {
      ERC1155EnumerableStorage.Layout storage l = ERC1155EnumerableStorage.layout();
      mapping (uint => EnumerableSet.AddressSet) storage tokenAccounts = l.accountsByToken;
      EnumerableSet.UintSet storage fromTokens = l.tokensByAccount[from];
      EnumerableSet.UintSet storage toTokens = l.tokensByAccount[to];

      for (uint i; i < ids.length; i++) {
        uint amount = amounts[i];

        if (amount > 0) {
          uint id = ids[i];

          if (from == address(0)) {
            l.totalSupply[id] += amount;
          } else if (balanceOf(from, id) == amount) {
            tokenAccounts[id].remove(from);
            fromTokens.remove(id);
          }

          if (to == address(0)) {
            l.totalSupply[id] -= amount;
          } else if (balanceOf(to, id) == 0) {
            tokenAccounts[id].add(to);
            toTokens.add(id);
          }
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../token/ERC20/IERC20.sol';
import '../token/ERC20/IERC20Metadata.sol';

/**
 * @title WETH (Wrapped ETH) interface
 */
interface IWETH is IERC20, IERC20Metadata {
  /**
   * @notice convert ETH to WETH
   */
  function deposit () external payable;

  /**
   * @notice convert WETH to ETH
   * @dev if caller is a contract, it should have a fallback or receive function
   * @param amount quantity of WETH to convert, denominated in wei
   */
  function withdraw (
    uint amount
  ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IPair {
  /**
   * @notice update cache and get most recent price and variance
   * @return price64x64 64x64 fixed point representation of price
   * @return variance64x64 64x64 fixed point representation of EMA of annualized variance
   */
  function updateAndGetLatestData () external returns (int128 price64x64, int128 variance64x64);

  /**
   * @notice update cache and get price for given timestamp
   * @param timestamp timestamp of price to query
   * @return price64x64 64x64 fixed point representation of price
   */
  function updateAndGetHistoricalPrice (
    uint256 timestamp
  ) external returns (int128 price64x64);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@solidstate/contracts/token/ERC20/ERC20BaseStorage.sol';

import { ABDKMath64x64Token } from '../libraries/ABDKMath64x64Token.sol';
import { OptionMath } from '../libraries/OptionMath.sol';

library PoolStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'median.contracts.storage.Pool'
  );

  struct Layout {
    address treasury;
    address pair;
    address underlying;
    uint8 underlyingDecimals;
    int128 cLevel64x64;
    int128 fee64x64;

    mapping (address => uint256) depositedAt;

    // doubly linked list of free liquidity intervals
    mapping (address => address) liquidityQueueAscending;
    mapping (address => address) liquidityQueueDescending;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function totalSupply64x64 (
    Layout storage l
  ) internal view returns (int128) {
    return ABDKMath64x64Token.fromDecimals(
      ERC20BaseStorage.layout().totalSupply, l.underlyingDecimals
    );
  }

  function addUnderwriter (
    Layout storage l,
    address account
  ) internal {
    l.liquidityQueueAscending[l.liquidityQueueDescending[address(0)]] = account;
  }

  function removeUnderwriter (
    Layout storage l,
    address account
  ) internal {
    address prev = l.liquidityQueueDescending[account];
    address next = l.liquidityQueueAscending[account];
    l.liquidityQueueAscending[prev] = next;
    l.liquidityQueueDescending[next] = prev;
    delete l.liquidityQueueAscending[account];
    delete l.liquidityQueueDescending[account];
  }

  function setCLevel (
    Layout storage l,
    int128 oldLiquidity64x64,
    int128 newLiquidity64x64
  ) internal {
    l.cLevel64x64 = OptionMath.calculateCLevel(
      l.cLevel64x64,
      oldLiquidity64x64,
      newLiquidity64x64,
      OptionMath.ONE_64x64
    );
  }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ABDKMath64x64 } from 'abdk-libraries-solidity/ABDKMath64x64.sol';

library ABDKMath64x64Token {
  using ABDKMath64x64 for int128;

  /**
   * @notice convert 64x64 fixed point representation of token amount to decimal
   * @param value64x64 64x64 fixed point representation of token amount
   * @param decimals token display decimals
   * @return value decimal representation of token amount
   */
  function toDecimals (
    int128 value64x64,
    uint8 decimals
  ) internal pure returns (uint256 value) {
    value = value64x64.mulu(10 ** decimals);
  }

  /**
   * @notice convert decimal representation of token amount to 64x64 fixed point
   * @param value decimal representation of token amount
   * @param decimals token display decimals
   * @return value64x64 64x64 fixed point representation of token amount
   */
  function fromDecimals (
    uint256 value,
    uint8 decimals
  ) internal pure returns (int128 value64x64) {
    value64x64 = ABDKMath64x64.divu(value, 10 ** decimals);
  }

  /**
   * @notice convert 64x64 fixed point representation of token amount to wei (18 decimals)
   * @param value64x64 64x64 fixed point representation of token amount
   * @return value wei representation of token amount
   */
  function toWei (
    int128 value64x64
  ) internal pure returns (uint256 value) {
    value = toDecimals(value64x64, 18);
  }

  /**
   * @notice convert wei representation (18 decimals) of token amount to 64x64 fixed point
   * @param value wei representation of token amount
   * @return value64x64 64x64 fixed point representation of token amount
   */
  function fromWei (
    uint256 value
  ) internal pure returns (int128 value64x64) {
    value64x64 = fromDecimals(value, 18);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ABDKMath64x64 } from 'abdk-libraries-solidity/ABDKMath64x64.sol';

library OptionMath {
  using ABDKMath64x64 for int128;

  // 64x64 fixed point integer constants
  int128 internal constant ONE_64x64 = 0x10000000000000000;
  int128 internal constant THREE_64x64 = 0x30000000000000000;

  // 64x64 fixed point representation of 2e
  int128 internal constant INITIAL_C_LEVEL_64x64 = 0x56fc2a2c515da32ea;

  // 64x64 fixed point constants used in Choudhury’s approximation of the Black-Scholes CDF
  int128 private constant CDF_CONST_0 = 0x09109f285df452394; // 2260 / 3989
  int128 private constant CDF_CONST_1 = 0x19abac0ea1da65036; // 6400 / 3989
  int128 private constant CDF_CONST_2 = 0x0d3c84b78b749bd6b; // 3300 / 3989

  /**
   * @notice calculate the exponential decay coefficient for a given interval
   * @param oldTimestamp timestamp of previous update
   * @param newTimestamp current timestamp
   * @return 64x64 fixed point representation of exponential decay coefficient
   */
  function decay (
    uint256 oldTimestamp,
    uint256 newTimestamp
  ) internal pure returns (int128) {
    return ONE_64x64.sub(
      (-ABDKMath64x64.divu(newTimestamp - oldTimestamp, 7 days)).exp()
    );
  }

  /**
   * @notice calculate the rolling EMA of an uneven time series
   * @param oldEmaLogReturns64x64 64x64 fixed point representation of previous EMA
   * @param logReturns64x64 64x64 fixed point representation of natural log of rate of return for current period
   * @param oldTimestamp timestamp of previous update
   * @param newTimestamp current timestamp
   * @return 64x64 fixed point representation of EMA
   */
  function unevenRollingEma (
    int128 oldEmaLogReturns64x64,
    int128 logReturns64x64,
    uint256 oldTimestamp,
    uint256 newTimestamp
  ) internal pure returns (int128) {
    int128 decay64x64 = decay(oldTimestamp, newTimestamp);

    return logReturns64x64.mul(decay64x64).add(
      ONE_64x64.sub(decay64x64).mul(oldEmaLogReturns64x64)
    );
  }

  /**
   * @notice calculate the rolling EMA variance of an uneven time series
   * @param oldEmaLogReturns64x64 64x64 fixed point representation of previous EMA
   * @param oldEmaVariance64x64 64x64 fixed point representation of previous variance
   * @param logReturns64x64 64x64 fixed point representation of natural log of rate of return for current period
   * @param oldTimestamp timestamp of previous update
   * @param newTimestamp current timestamp
   * @return 64x64 fixed point representation of EMA of variance
   */
  function unevenRollingEmaVariance (
    int128 oldEmaLogReturns64x64,
    int128 oldEmaVariance64x64,
    int128 logReturns64x64,
    uint256 oldTimestamp,
    uint256 newTimestamp
  ) internal pure returns (int128) {
    int128 decay64x64 = decay(oldTimestamp, newTimestamp);
    int128 difference64x64 = logReturns64x64.sub(oldEmaLogReturns64x64);

    return ONE_64x64.sub(decay64x64).mul(
      // squaring via mul is cheaper than via pow
      decay64x64.mul(difference64x64).mul(difference64x64).add(oldEmaVariance64x64)
    );
  }

  /**
   * @notice calculate Choudhury’s approximation of the Black-Scholes CDF
   * @param input64x64 64x64 fixed point representation of random variable
   * @return 64x64 fixed point representation of the approximated CDF of x
   */
  function N (
    int128 input64x64
  ) internal pure returns (int128) {
    // squaring via mul is cheaper than via pow
    int128 inputSquared64x64 = input64x64.mul(input64x64);

    int128 value64x64 = (-inputSquared64x64 >> 1).exp().div(
      CDF_CONST_0.add(
        CDF_CONST_1.mul(input64x64.abs())
      ).add(
        CDF_CONST_2.mul(inputSquared64x64.add(THREE_64x64).sqrt())
      )
    );

    return input64x64 > 0 ? ONE_64x64.sub(value64x64) : value64x64;
  }

  /**
   * @notice calculate the price of an option using the Black-Scholes model
   * @param emaVarianceAnnualized64x64 64x64 fixed point representation of annualized EMA of variance
   * @param strike64x64 64x64 fixed point representation of strike price
   * @param spot64x64 64x64 fixed point representation of spot price
   * @param timeToMaturity64x64 64x64 fixed point representation of duration of option contract (in years)
   * @param isCall whether to price "call" or "put" option
   * @return 64x64 fixed point representation of Black-Scholes option price
   */
  function bsPrice (
    int128 emaVarianceAnnualized64x64,
    int128 strike64x64,
    int128 spot64x64,
    int128 timeToMaturity64x64,
    bool isCall
  ) internal pure returns (int128) {
    int128 cumulativeVariance64x64 = timeToMaturity64x64.mul(emaVarianceAnnualized64x64);
    int128 cumulativeVarianceSqrt64x64 = cumulativeVariance64x64.sqrt();

    int128 d1_64x64 = spot64x64.div(strike64x64).ln().add(cumulativeVariance64x64 >> 1).div(cumulativeVarianceSqrt64x64);
    int128 d2_64x64 = d1_64x64.sub(cumulativeVarianceSqrt64x64);

    if (isCall) {
      return spot64x64.mul(N(d1_64x64)).sub(strike64x64.mul(N(d2_64x64)));
    } else {
      return -spot64x64.mul(N(-d1_64x64)).sub(strike64x64.mul(N(-d2_64x64)));
    }
  }

  /**
   * @notice recalculate C-Level based on change in liquidity
   * @param initialCLevel64x64 64x64 fixed point representation of C-Level of Pool before update
   * @param oldPoolState64x64 64x64 fixed point representation of liquidity in pool before update
   * @param newPoolState64x64 64x64 fixed point representation of liquidity in pool after update
   * @param steepness64x64 64x64 fixed point representation of steepness coefficient
   * @return 64x64 fixed point representation of new C-Level
   */
  function calculateCLevel (
    int128 initialCLevel64x64,
    int128 oldPoolState64x64,
    int128 newPoolState64x64,
    int128 steepness64x64
  ) internal pure returns (int128) {
    return newPoolState64x64.sub(oldPoolState64x64).div(
      oldPoolState64x64 > newPoolState64x64 ? oldPoolState64x64 : newPoolState64x64
    ).mul(steepness64x64).neg().exp().mul(initialCLevel64x64);
  }

  /**
   * @notice calculate the price of an option using the Median Finance model
   * @param emaVarianceAnnualized64x64 64x64 fixed point representation of annualized EMA of variance
   * @param strike64x64 64x64 fixed point representation of strike price
   * @param spot64x64 64x64 fixed point representation of spot price
   * @param timeToMaturity64x64 64x64 fixed point representation of duration of option contract (in years)
   * @param oldCLevel64x64 64x64 fixed point representation of C-Level of Pool before purchase
   * @param oldPoolState 64x64 fixed point representation of current state of the pool
   * @param newPoolState 64x64 fixed point representation of state of the pool after trade
   * @param steepness64x64 64x64 fixed point representation of Pool state delta multiplier
   * @param isCall whether to price "call" or "put" option
   * @return medianPrice64x64 64x64 fixed point representation of Median option price
   * @return cLevel64x64 64x64 fixed point representation of C-Level of Pool after purchase
   */
  function quotePrice (
    int128 emaVarianceAnnualized64x64,
    int128 strike64x64,
    int128 spot64x64,
    int128 timeToMaturity64x64,
    int128 oldCLevel64x64,
    int128 oldPoolState,
    int128 newPoolState,
    int128 steepness64x64,
    bool isCall
  ) internal pure returns (int128 medianPrice64x64, int128 cLevel64x64) {
    int128 deltaPoolState64x64 = newPoolState.sub(oldPoolState).div(oldPoolState).mul(steepness64x64);
    int128 tradingDelta64x64 = deltaPoolState64x64.neg().exp();

    int128 bsPrice64x64 = bsPrice(emaVarianceAnnualized64x64, strike64x64, spot64x64, timeToMaturity64x64, isCall);
    cLevel64x64 = tradingDelta64x64.mul(oldCLevel64x64);

    medianPrice64x64 = bsPrice64x64.mul(cLevel64x64).mul(
      // slippage coefficient
      ONE_64x64.sub(tradingDelta64x64).div(deltaPoolState64x64)
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.Ownable'
  );

  struct Layout {
    address owner;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function setOwner (
    Layout storage l,
    address owner
  ) internal {
    l.owner = owner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC20.sol';
import './ERC20BaseStorage.sol';

abstract contract ERC20Base is IERC20 {
  function totalSupply () override virtual public view returns (uint) {
    return ERC20BaseStorage.layout().totalSupply;
  }

  function balanceOf (
    address account
  ) override virtual public view returns (uint) {
    return ERC20BaseStorage.layout().balances[account];
  }

  function allowance (
    address holder,
    address spender
  ) override virtual public view returns (uint) {
    return ERC20BaseStorage.layout().allowances[holder][spender];
  }

  function transfer (
    address recipient,
    uint amount
  ) override virtual public returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom (
    address sender,
    address recipient,
    uint amount
  ) override virtual public returns (bool) {
    _approve(
      sender,
      msg.sender,
      // TODO: error message
      // ERC20BaseStorage.layout().allowances[sender][msg.sender].sub(amount, 'ERC20: transfer amount exceeds allowance')
      ERC20BaseStorage.layout().allowances[sender][msg.sender] - amount
    );
    _transfer(sender, recipient, amount);
    return true;
  }

  function approve (
    address spender,
    uint amount
  ) override virtual public returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function _mint (
    address account,
    uint amount
  ) virtual internal {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
    l.totalSupply += amount;
    l.balances[account] += amount;

    emit Transfer(address(0), account, amount);
  }

  function _burn (
    address account,
    uint amount
  ) virtual internal {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
    l.balances[account] -= amount;
    l.totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  function _transfer (
    address sender,
    address recipient,
    uint amount
  ) virtual internal {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
    // TODO: error message
    // l.balances[sender] = l.balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
    l.balances[sender] -= amount;
    l.balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function _approve (
    address holder,
    address spender,
    uint amount
  ) virtual internal {
    require(holder != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    ERC20BaseStorage.layout().allowances[holder][spender] = amount;

    emit Approval(holder, spender, amount);
  }

  function _beforeTokenTransfer (
    address from,
    address to,
    uint amount
  ) virtual internal {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC20Base.sol';

abstract contract ERC20Extended is ERC20Base {
  function increaseAllowance (address spender, uint amount) virtual public returns (bool) {
    _approve(
      msg.sender,
      spender,
      // TODO: error message
      // ERC20BaseStorage.layout().allowances[msg.sender][spender].add(amount)
      ERC20BaseStorage.layout().allowances[msg.sender][spender] += amount
    );
    return true;
  }

  function decreaseAllowance (address spender, uint amount) virtual public returns (bool) {
    _approve(
      msg.sender,
      spender,
      // TODO: error message
      // ERC20BaseStorage.layout().allowances[msg.sender][spender].sub(amount)
      ERC20BaseStorage.layout().allowances[msg.sender][spender] -= amount
    );
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC20MetadataStorage.sol';
import './IERC20Metadata.sol';

abstract contract ERC20Metadata is IERC20Metadata {
  function name () virtual override public view returns (string memory) {
    return ERC20MetadataStorage.layout().name;
  }

  function symbol () virtual override public view returns (string memory) {
    return ERC20MetadataStorage.layout().symbol;
  }

  function decimals () virtual override public view returns (uint8) {
    return ERC20MetadataStorage.layout().decimals;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC20BaseStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC20Base'
  );

  struct Layout {
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;
    uint totalSupply;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC20MetadataStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC20Metadata'
  );

  struct Layout {
    string name;
    string symbol;
    uint8 decimals;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function setName (
    Layout storage l,
    string memory name
  ) internal {
    l.name = name;
  }

  function setSymbol (
    Layout storage l,
    string memory symbol
  ) internal {
    l.symbol = symbol;
  }

  function setDecimals (
    Layout storage l,
    uint8 decimals
  ) internal {
    l.decimals = decimals;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20Metadata {
  function name () external view returns (string memory);

  function symbol () external view returns (string memory);

  function decimals () external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
  struct Set {
    bytes32[] _values;
    // 1-indexed to allow 0 to signify nonexistence
    mapping (bytes32 => uint) _indexes;
  }

  struct Bytes32Set {
    Set _inner;
  }

  struct AddressSet {
    Set _inner;
  }

  struct UintSet {
    Set _inner;
  }

  function at (
    Bytes32Set storage set,
    uint index
  ) internal view returns (bytes32) {
    return _at(set._inner, index);
  }

  function at (
    AddressSet storage set,
    uint index
  ) internal view returns (address) {
    return address(uint160(uint(_at(set._inner, index))));
  }

  function at (
    UintSet storage set,
    uint index
  ) internal view returns (uint) {
    return uint(_at(set._inner, index));
  }

  function contains (
    Bytes32Set storage set,
    bytes32 value
  ) internal view returns (bool) {
    return _contains(set._inner, value);
  }

  function contains (
    AddressSet storage set,
    address value
  ) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint(uint160(value))));
  }

  function contains (
    UintSet storage set,
    uint value
  ) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  function indexOf (
    Bytes32Set storage set,
    bytes32 value
  ) internal view returns (uint) {
    return _indexOf(set._inner, value);
  }

  function indexOf (
    AddressSet storage set,
    address value
  ) internal view returns (uint) {
    return _indexOf(set._inner, bytes32(uint(uint160(value))));
  }

  function indexOf (
    UintSet storage set,
    uint value
  ) internal view returns (uint) {
    return _indexOf(set._inner, bytes32(value));
  }

  function length (
    Bytes32Set storage set
  ) internal view returns (uint) {
    return _length(set._inner);
  }

  function length (
    AddressSet storage set
  ) internal view returns (uint) {
    return _length(set._inner);
  }

  function length (
    UintSet storage set
  ) internal view returns (uint) {
    return _length(set._inner);
  }

  function add (
    Bytes32Set storage set,
    bytes32 value
  ) internal returns (bool) {
    return _add(set._inner, value);
  }

  function add (
    AddressSet storage set,
    address value
  ) internal returns (bool) {
    return _add(set._inner, bytes32(uint(uint160(value))));
  }

  function add (
    UintSet storage set,
    uint value
  ) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  function remove (
    Bytes32Set storage set,
    bytes32 value
  ) internal returns (bool) {
    return _remove(set._inner, value);
  }

  function remove (
    AddressSet storage set,
    address value
  ) internal returns (bool) {
    return _remove(set._inner, bytes32(uint(uint160(value))));
  }

  function remove (
    UintSet storage set,
    uint value
  ) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  function _at (
    Set storage set,
    uint index
  ) private view returns (bytes32) {
    require(set._values.length > index, 'EnumerableSet: index out of bounds');
    return set._values[index];
  }

  function _contains (
    Set storage set,
    bytes32 value
  ) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  function _indexOf (
    Set storage set,
    bytes32 value
  ) private view returns (uint) {
    unchecked {
      return set._indexes[value] - 1;
    }
  }

  function _length (
    Set storage set
  ) private view returns (uint) {
    return set._values.length;
  }

  function _add (
    Set storage set,
    bytes32 value
  ) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove (
    Set storage set,
    bytes32 value
  ) private returns (bool) {
    uint valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      uint index = valueIndex - 1;
      bytes32 last = set._values[set._values.length - 1];

      // move last value to now-vacant index

      set._values[index] = last;
      set._indexes[last] = index + 1;

      // clear last index

      set._values.pop();
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// TODO: remove ERC165

import './IERC1155.sol';
import './IERC1155Receiver.sol';
import './ERC1155BaseStorage.sol';
import '../../introspection/ERC165.sol';
import '../../utils/AddressUtils.sol';

abstract contract ERC1155Base is IERC1155, ERC165 {
  using AddressUtils for address;

  function balanceOf (
    address account,
    uint id
  ) override public view returns (uint) {
    require(account != address(0), 'ERC1155: balance query for the zero address');
    return ERC1155BaseStorage.layout().balances[id][account];
  }

  function balanceOfBatch (
    address[] memory accounts,
    uint[] memory ids
  ) override public view returns (uint[] memory) {
    require(accounts.length == ids.length, 'ERC1155: accounts and ids length mismatch');

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    uint[] memory batchBalances = new uint[](accounts.length);

    for (uint i; i < accounts.length; i++) {
      require(accounts[i] != address(0), 'ERC1155: batch balance query for the zero address');
      batchBalances[i] = balances[ids[i]][accounts[i]];
    }

    return batchBalances;
  }

  function isApprovedForAll (
    address account,
    address operator
  ) override public view returns (bool) {
    return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
  }

  function setApprovalForAll (
    address operator,
    bool status
  ) override public {
    require(msg.sender != operator, 'ERC1155: setting approval status for self');
    ERC1155BaseStorage.layout().operatorApprovals[msg.sender][operator] = status;
    emit ApprovalForAll(msg.sender, operator, status);
  }

  function safeTransferFrom (
    address from,
    address to,
    uint id,
    uint amount,
    bytes memory data
  ) override public {
    require(from == msg.sender || isApprovedForAll(from, msg.sender), 'ERC1155: caller is not owner nor approved');
    _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    _transfer(msg.sender, from, to, id, amount, data);
  }

  function safeBatchTransferFrom (
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) override public {
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');
    require(from == msg.sender || isApprovedForAll(from, msg.sender), 'ERC1155: caller is not owner nor approved');
    _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    _transferBatch(msg.sender, from, to, ids, amounts, data);
  }

  function _mint (
    address account,
    uint id,
    uint amount,
    bytes memory data
  ) internal {
    require(account != address(0), 'ERC1155: mint to the zero address');

    _beforeTokenTransfer(msg.sender, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

    mapping (address => uint) storage balances = ERC1155BaseStorage.layout().balances[id];
    balances[account] += amount;

    emit TransferSingle(msg.sender, address(0), account, id, amount);

    _doSafeTransferAcceptanceCheck(msg.sender, address(0), account, id, amount, data);
  }

  function _mintBatch (
    address account,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) internal {
    require(account != address(0), 'ERC1155: mint to the zero address');
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

    _beforeTokenTransfer(msg.sender, address(0), account, ids, amounts, data);

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    for (uint i; i < ids.length; i++) {
      uint id = ids[i];
      balances[id][account] += amounts[i];
    }

    emit TransferBatch(msg.sender, address(0), account, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), account, ids, amounts, data);
  }

  function _burn (
    address account,
    uint id,
    uint amount
  ) internal {
    require(account != address(0), 'ERC1155: burn from the zero address');

    _beforeTokenTransfer(msg.sender, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), '');

    mapping (address => uint) storage balances = ERC1155BaseStorage.layout().balances[id];
    require(balances[account] >= amount, 'ERC1155: burn amount exceeds balances');
    balances[account] -= amount;

    emit TransferSingle(msg.sender, account, address(0), id, amount);
  }

  function _burnBatch (
    address account,
    uint[] memory ids,
    uint[] memory amounts
  ) internal {
    require(account != address(0), 'ERC1155: burn from the zero address');
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

    _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    for (uint i; i < ids.length; i++) {
      uint id = ids[i];
      require(balances[id][account] >= amounts[i], 'ERC1155: burn amount exceeds balance');
      balances[id][account] -= amounts[i];
    }

    emit TransferBatch(msg.sender, account, address(0), ids, amounts);
  }

  function _transfer (
    address operator,
    address sender,
    address recipient,
    uint id,
    uint amount,
    bytes memory data
  ) virtual internal {
    require(recipient != address(0), 'ERC1155: transfer to the zero address');

    _beforeTokenTransfer(operator, sender, recipient, _asSingletonArray(id), _asSingletonArray(amount), data);

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    // TODO: error message
    // balances[id][sender] = balances[id][sender].sub(amount, 'ERC1155: insufficient balances for transfer');
    balances[id][sender] -= amount;
    balances[id][recipient] += amount;

    emit TransferSingle(operator, sender, recipient, id, amount);
  }

  function _transferBatch (
    address operator,
    address sender,
    address recipient,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) virtual internal {
    require(recipient != address(0), 'ERC1155: transfer to the zero address');

    _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    for (uint i; i < ids.length; i++) {
      uint token = ids[i];
      uint amount = amounts[i];
      // TODO: error message
      // balances[id][sender] = balances[id][sender].sub(amount, 'ERC1155: insufficient balances for transfer');
      balances[token][sender] -= amount;
      balances[token][recipient] += amount;
    }

    emit TransferBatch(operator, sender, recipient, ids, amounts);
  }

  function _asSingletonArray (
    uint element
  ) private pure returns (uint[] memory) {
    uint[] memory array = new uint[](1);
    array[0] = element;
    return array;
  }

  function _doSafeTransferAcceptanceCheck (
    address operator,
    address from,
    address to,
    uint id,
    uint amount,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        if (response != IERC1155Receiver(to).onERC1155Received.selector) {
          revert('ERC1155: ERC1155Receiver rejected tokens');
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert('ERC1155: transfer to non ERC1155Receiver implementer');
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck (
    address operator,
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
        if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
          revert('ERC1155: ERC1155Receiver rejected tokens');
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert('ERC1155: transfer to non ERC1155Receiver implementer');
      }
    }
  }

  function _beforeTokenTransfer (
    address operator,
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) virtual internal {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../utils/EnumerableSet.sol';

library ERC1155EnumerableStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC1155Enumerable'
  );

  struct Layout {
    mapping (uint => uint) totalSupply;
    mapping (uint => EnumerableSet.AddressSet) accountsByToken;
    mapping (address => EnumerableSet.UintSet) tokensByAccount;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../introspection/IERC165.sol';

interface IERC1155 is IERC165 {
  event TransferSingle (
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  event TransferBatch (
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  event ApprovalForAll (
    address indexed account,
    address indexed operator,
    bool approved
  );

  event URI (
    string value,
    uint256 indexed id
  );

  function balanceOf (
    address account,
    uint256 id
  ) external view returns (uint256);

  function balanceOfBatch (
    address[] calldata accounts,
    uint256[] calldata ids
  ) external view returns (uint256[] memory);

  function setApprovalForAll (
    address operator,
    bool approved
  ) external;

  function isApprovedForAll (
    address account,
    address operator
  ) external view returns (bool);

  function safeTransferFrom (
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  function safeBatchTransferFrom (
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../introspection/IERC165.sol';

interface IERC1155Receiver is IERC165 {
  function onERC1155Received (
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns(bytes4);

  function onERC1155BatchReceived (
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC1155BaseStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC1155Base'
  );

  struct Layout {
    mapping (uint => mapping (address => uint)) balances;
    mapping (address => mapping (address => bool)) operatorApprovals;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC165.sol';
import './ERC165Storage.sol';

abstract contract ERC165 is IERC165 {
  using ERC165Storage for ERC165Storage.Layout;

  function supportsInterface (bytes4 interfaceId) override public view returns (bool) {
    return ERC165Storage.layout().isSupportedInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressUtils {
  function toString (address account) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(account)));
    bytes memory alphabet = '0123456789abcdef';
    bytes memory chars = new bytes(42);

    chars[0] = '0';
    chars[1] = 'x';

    for (uint256 i = 0; i < 20; i++) {
      chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
      chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }

    return string(chars);
  }

  function isContract (address account) internal view returns (bool) {
    // TODO: validate against extcodehash method used by OpenZeppelin
    uint size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }

  function sendValue (address payable account, uint amount) internal {
    (bool success, ) = account.call{ value: amount }('');
    require(success, 'AddressUtils: failed to send value');
  }

  function functionCall (address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'AddressUtils: failed low-level call');
  }

  function functionCall (address target, bytes memory data, string memory error) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, error);
  }

  function functionCallWithValue (address target, bytes memory data, uint value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'AddressUtils: failed low-level call with value');
  }

  function functionCallWithValue (address target, bytes memory data, uint value, string memory error) internal returns (bytes memory) {
    require(address(this).balance >= value, 'AddressUtils: insufficient balance for call');
    return _functionCallWithValue(target, data, value, error);
  }

  function _functionCallWithValue (address target, bytes memory data, uint value, string memory error) private returns (bytes memory) {
    require(isContract(target), 'AddressUtils: function call to non-contract');

    (bool success, bytes memory returnData) = target.call{ value: value }(data);

    if (success) {
      return returnData;
    } else if (returnData.length > 0) {
      assembly {
        let returnData_size := mload(returnData)
        revert(add(32, returnData), returnData_size)
      }
    } else {
      revert(error);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
  function supportsInterface (
    bytes4 interfaceId
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC165'
  );

  struct Layout {
    // TODO: use EnumerableSet to allow post-diamond-cut auditing
    mapping (bytes4 => bool) supportedInterfaces;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function isSupportedInterface (
    Layout storage l,
    bytes4 interfaceId
  ) internal view returns (bool) {
    return l.supportedInterfaces[interfaceId];
  }

  function setSupportedInterface (
    Layout storage l,
    bytes4 interfaceId,
    bool status
  ) internal {
    require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
    l.supportedInterfaces[interfaceId] = status;
  }
}

