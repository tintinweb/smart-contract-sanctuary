// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../interfaces/IManager.sol';

import '../libraries/LibSherX.sol';
import '../libraries/LibPool.sol';

contract Manager is IManager {
  using SafeMath for uint256;

  // Once transaction has been mined, protocol is officialy insured.

  //
  // Modifiers
  //

  modifier onlyGovMain() {
    require(msg.sender == GovStorage.gs().govMain, 'NOT_GOV_MAIN');
    _;
  }

  function onlyValidToken(PoolStorage.Base storage ps, IERC20 _token) private view {
    require(address(_token) != address(this), 'SHERX');
    require(ps.premiums, 'WHITELIST');
  }

  //
  // State changing methods
  //

  function setTokenPrice(IERC20 _token, uint256 _newUsd) external override onlyGovMain {
    LibPool.payOffDebtAll(_token);
    (uint256 usdPerBlock, uint256 usdPool) = _getData();
    (usdPerBlock, usdPool) = _setTokenPrice(_token, _newUsd, usdPerBlock, usdPool);
    _setData(usdPerBlock, usdPool);
  }

  function setTokenPrice(IERC20[] memory _token, uint256[] memory _newUsd)
    external
    override
    onlyGovMain
  {
    require(_token.length == _newUsd.length, 'LENGTH');

    (uint256 usdPerBlock, uint256 usdPool) = _getData();
    for (uint256 i; i < _token.length; i++) {
      LibPool.payOffDebtAll(_token[i]);
      (usdPerBlock, usdPool) = _setTokenPrice(_token[i], _newUsd[i], usdPerBlock, usdPool);
    }
    _setData(usdPerBlock, usdPool);
  }

  function setProtocolPremium(
    bytes32 _protocol,
    IERC20 _token,
    uint256 _premium
  ) external override onlyGovMain {
    LibPool.payOffDebtAll(_token);
    (uint256 usdPerBlock, uint256 usdPool) = _getData();
    (usdPerBlock, usdPool) = _setProtocolPremium(_protocol, _token, _premium, usdPerBlock, usdPool);
    _setData(usdPerBlock, usdPool);
  }

  function setProtocolPremium(
    bytes32 _protocol,
    IERC20[] memory _token,
    uint256[] memory _premium
  ) external override onlyGovMain {
    require(_token.length == _premium.length, 'LENGTH');

    (uint256 usdPerBlock, uint256 usdPool) = _getData();

    for (uint256 i; i < _token.length; i++) {
      LibPool.payOffDebtAll(_token[i]);
      (usdPerBlock, usdPool) = _setProtocolPremium(
        _protocol,
        _token[i],
        _premium[i],
        usdPerBlock,
        usdPool
      );
    }
    _setData(usdPerBlock, usdPool);
  }

  function setProtocolPremium(
    bytes32[] memory _protocol,
    IERC20[][] memory _token,
    uint256[][] memory _premium
  ) external override onlyGovMain {
    require(_protocol.length == _token.length, 'LENGTH_1');
    require(_protocol.length == _premium.length, 'LENGTH_2');

    (uint256 usdPerBlock, uint256 usdPool) = _getData();

    for (uint256 i; i < _protocol.length; i++) {
      require(_token[i].length == _premium[i].length, 'LENGTH_3');
      for (uint256 j; j < _token[i].length; j++) {
        LibPool.payOffDebtAll(_token[i][j]);
        (usdPerBlock, usdPool) = _setProtocolPremium(
          _protocol[i],
          _token[i][j],
          _premium[i][j],
          usdPerBlock,
          usdPool
        );
      }
    }
    _setData(usdPerBlock, usdPool);
  }

  function setProtocolPremiumAndTokenPrice(
    bytes32 _protocol,
    IERC20 _token,
    uint256 _premium,
    uint256 _newUsd
  ) external override onlyGovMain {
    LibPool.payOffDebtAll(_token);
    (uint256 usdPerBlock, uint256 usdPool) = _getData();

    (usdPerBlock, usdPool) = _setProtocolPremiumAndTokenPrice(
      _protocol,
      _token,
      _premium,
      _newUsd,
      usdPerBlock,
      usdPool
    );
    _setData(usdPerBlock, usdPool);
  }

  function setProtocolPremiumAndTokenPrice(
    bytes32 _protocol,
    IERC20[] memory _token,
    uint256[] memory _premium,
    uint256[] memory _newUsd
  ) external override onlyGovMain {
    require(_token.length == _premium.length, 'LENGTH_1');
    require(_token.length == _newUsd.length, 'LENGTH_2');

    (uint256 usdPerBlock, uint256 usdPool) = _getData();

    for (uint256 i; i < _token.length; i++) {
      LibPool.payOffDebtAll(_token[i]);
      (usdPerBlock, usdPool) = _setProtocolPremiumAndTokenPrice(
        _protocol,
        _token[i],
        _premium[i],
        _newUsd[i],
        usdPerBlock,
        usdPool
      );
    }
    _setData(usdPerBlock, usdPool);
  }

  function setProtocolPremiumAndTokenPrice(
    bytes32[] memory _protocol,
    IERC20 _token,
    uint256[] memory _premium,
    uint256 _newUsd
  ) external override onlyGovMain {
    require(_protocol.length == _premium.length, 'LENGTH');
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    onlyValidToken(ps, _token);
    LibPool.payOffDebtAll(_token);

    uint256 oldPremium = ps.totalPremiumPerBlock;
    uint256 newPremium = oldPremium;
    (uint256 usdPerBlock, uint256 usdPool) = _getData();

    uint256 oldUsd = _setTokenPrice(_token, _newUsd);

    for (uint256 i; i < _protocol.length; i++) {
      require(ps.isProtocol[_protocol[i]], 'NON_PROTOCOL');
      newPremium = newPremium.sub(ps.protocolPremium[_protocol[i]]).add(_premium[i]);
      ps.protocolPremium[_protocol[i]] = _premium[i];
    }
    ps.totalPremiumPerBlock = newPremium;
    (usdPerBlock, usdPool) = _updateData(
      ps,
      usdPerBlock,
      usdPool,
      oldPremium,
      newPremium,
      oldUsd,
      _newUsd
    );
    _setData(usdPerBlock, usdPool);
  }

  function setProtocolPremiumAndTokenPrice(
    bytes32[] memory _protocol,
    IERC20[][] memory _token,
    uint256[][] memory _premium,
    uint256[][] memory _newUsd
  ) external override onlyGovMain {
    (uint256 usdPerBlock, uint256 usdPool) = _getData();
    require(_protocol.length == _token.length, 'LENGTH_1');
    require(_protocol.length == _premium.length, 'LENGTH_2');
    require(_protocol.length == _newUsd.length, 'LENGTH_3');

    for (uint256 i; i < _protocol.length; i++) {
      require(_token[i].length == _premium[i].length, 'LENGTH_4');
      require(_token[i].length == _newUsd[i].length, 'LENGTH_5');
      for (uint256 j; j < _token[i].length; j++) {
        LibPool.payOffDebtAll(_token[i][j]);
        (usdPerBlock, usdPool) = _setProtocolPremiumAndTokenPrice(
          _protocol[i],
          _token[i][j],
          _premium[i][j],
          _newUsd[i][j],
          usdPerBlock,
          usdPool
        );
      }
    }
    _setData(usdPerBlock, usdPool);
  }

  function _setTokenPrice(
    IERC20 _token,
    uint256 _newUsd,
    uint256 usdPerBlock,
    uint256 usdPool
  ) private returns (uint256, uint256) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    onlyValidToken(ps, _token);

    uint256 oldUsd = _setTokenPrice(_token, _newUsd);
    uint256 premium = ps.totalPremiumPerBlock;
    (usdPerBlock, usdPool) = _updateData(
      ps,
      usdPerBlock,
      usdPool,
      premium,
      premium,
      oldUsd,
      _newUsd
    );
    return (usdPerBlock, usdPool);
  }

  function _setTokenPrice(IERC20 _token, uint256 _newUsd) private returns (uint256 oldUsd) {
    SherXStorage.Base storage sx = SherXStorage.sx();

    oldUsd = sx.tokenUSD[_token];
    // used for setProtocolPremiumAndTokenPrice, if same token prices are updated
    if (oldUsd != _newUsd) {
      sx.tokenUSD[_token] = _newUsd;
    }
  }

  function _setProtocolPremium(
    bytes32 _protocol,
    IERC20 _token,
    uint256 _premium,
    uint256 usdPerBlock,
    uint256 usdPool
  ) private returns (uint256, uint256) {
    SherXStorage.Base storage sx = SherXStorage.sx();
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    onlyValidToken(ps, _token);

    (uint256 oldPremium, uint256 newPremium) = _setProtocolPremium(ps, _protocol, _premium);

    uint256 usd = sx.tokenUSD[_token];
    (usdPerBlock, usdPool) = _updateData(
      ps,
      usdPerBlock,
      usdPool,
      oldPremium,
      newPremium,
      usd,
      usd
    );
    return (usdPerBlock, usdPool);
  }

  function _setProtocolPremium(
    PoolStorage.Base storage ps,
    bytes32 _protocol,
    uint256 _premium
  ) private returns (uint256 oldPremium, uint256 newPremium) {
    require(ps.isProtocol[_protocol], 'NON_PROTOCOL');

    oldPremium = ps.totalPremiumPerBlock;
    newPremium = oldPremium.sub(ps.protocolPremium[_protocol]).add(_premium);

    ps.totalPremiumPerBlock = newPremium;
    ps.protocolPremium[_protocol] = _premium;
  }

  function _setProtocolPremiumAndTokenPrice(
    bytes32 _protocol,
    IERC20 _token,
    uint256 _premium,
    uint256 _newUsd,
    uint256 usdPerBlock,
    uint256 usdPool
  ) private returns (uint256, uint256) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    onlyValidToken(ps, _token);

    uint256 oldUsd = _setTokenPrice(_token, _newUsd);
    (uint256 oldPremium, uint256 newPremium) = _setProtocolPremium(ps, _protocol, _premium);
    (usdPerBlock, usdPool) = _updateData(
      ps,
      usdPerBlock,
      usdPool,
      oldPremium,
      newPremium,
      oldUsd,
      _newUsd
    );
    return (usdPerBlock, usdPool);
  }

  function _getData() private view returns (uint256 usdPerBlock, uint256 usdPool) {
    SherXStorage.Base storage sx = SherXStorage.sx();
    usdPerBlock = sx.totalUsdPerBlock;
    usdPool = LibSherX.viewAccrueUSDPool();
  }

  function _updateData(
    PoolStorage.Base storage ps,
    uint256 usdPerBlock,
    uint256 usdPool,
    uint256 _oldPremium,
    uint256 _newPremium,
    uint256 _oldUsd,
    uint256 _newUsd
  ) private view returns (uint256, uint256) {
    uint256 sub = _oldPremium.mul(_oldUsd);
    uint256 add = _newPremium.mul(_newUsd);
    if (sub > add) {
      usdPerBlock = usdPerBlock.sub(sub.sub(add).div(10**18));
    } else {
      usdPerBlock = usdPerBlock.add(add.sub(sub).div(10**18));
    }

    // Dont change usdPool is prices are equal
    if (ps.sherXUnderlying > 0) {
      if (_newUsd > _oldUsd) {
        usdPool = usdPool.add(_newUsd.sub(_oldUsd).mul(ps.sherXUnderlying).div(10**18));
      } else if (_newUsd < _oldUsd) {
        usdPool = usdPool.sub(_oldUsd.sub(_newUsd).mul(ps.sherXUnderlying).div(10**18));
      }
    }

    return (usdPerBlock, usdPool);
  }

  function _setData(uint256 usdPerBlock, uint256 usdPool) private {
    SherXStorage.Base storage sx = SherXStorage.sx();
    SherXERC20Storage.Base storage sx20 = SherXERC20Storage.sx20();

    LibSherX.accrueSherX();

    uint256 _currentTotalSupply = sx20.totalSupply;

    if (usdPerBlock > 0 && _currentTotalSupply == 0) {
      // initial accrue
      sx.sherXPerBlock = 10**18;
    } else if (usdPool > 0) {
      sx.sherXPerBlock = _currentTotalSupply.mul(usdPerBlock).div(usdPool);
    } else {
      sx.sherXPerBlock = 0;
    }
    sx.internalTotalSupply = _currentTotalSupply;
    sx.internalTotalSupplySettled = block.number;

    sx.totalUsdPerBlock = usdPerBlock;
    sx.totalUsdPool = usdPool;
    sx.totalUsdLastSettled = block.number;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
  @title Sherlock Protocol Manager
  @author Evert Kors
  @notice Managing the amounts protocol are due to Sherlock
*/
interface IManager {
  //
  // State changing methods
  //

  /**
    @notice Set internal price of `_token` to `_newUsd`
    @param _token Token to be updated
    @param _newUsd USD amount of token
    @dev Updating token price for 1 token
  */
  function setTokenPrice(IERC20 _token, uint256 _newUsd) external;

  /**
    @notice Set internal price of multiple tokens
    @param _token Array of token addresses
    @param _newUsd Array of USD amounts
    @dev Updating token price for 1+ tokens
  */
  function setTokenPrice(IERC20[] memory _token, uint256[] memory _newUsd) external;

  /**
    @notice Set `_token` premium for `_protocol` to `_premium` per block
    @param _protocol Protocol identifier
    @param _token Token address
    @param _premium Amount of tokens to be paid per block
    @dev Updating protocol premium for 1 token
  */
  function setProtocolPremium(
    bytes32 _protocol,
    IERC20 _token,
    uint256 _premium
  ) external;

  /**
    @notice Set multiple token premiums for `_protocol`
    @param _protocol Protocol identifier
    @param _token Array of token addresses
    @param _premium Array of amount of tokens to be paid per block
    @dev Updating protocol premium for 1+ tokens
  */
  function setProtocolPremium(
    bytes32 _protocol,
    IERC20[] memory _token,
    uint256[] memory _premium
  ) external;

  // NOTE: note implemented for now, same call with price has better use case
  // updating multiple protocol's premiums for 1 tokens
  // function setProtocolPremium(
  //   bytes32[] memory _protocol,
  //   IERC20 memory _token,
  //   uint256[] memory _premium
  // ) external;

  /**
    @notice Set multiple tokens premium for multiple protocols
    @param _protocol Array of protocol identifiers
    @param _token 2 dimensional array of token addresses
    @param _premium 2 dimensional array of amount of tokens to be paid per block
    @dev Updating multiple protocol's premium for 1+ tokens
  */
  function setProtocolPremium(
    bytes32[] memory _protocol,
    IERC20[][] memory _token,
    uint256[][] memory _premium
  ) external;

  /**
    @notice Set `_token` premium for `_protocol` to `_premium` per block and internal price to `_newUsd`
    @param _protocol Protocol identifier
    @param _token Token address
    @param _premium Amount of tokens to be paid per block
    @param _newUsd USD amount of token
    @dev Updating protocol premium and token price for 1 token
  */
  function setProtocolPremiumAndTokenPrice(
    bytes32 _protocol,
    IERC20 _token,
    uint256 _premium,
    uint256 _newUsd
  ) external;

  /**
    @notice Set multiple token premiums for `_protocol` and update internal prices
    @param _protocol Protocol identifier
    @param _token Array of token addresses
    @param _premium Array of amount of tokens to be paid per block
    @param _newUsd Array of USD amounts
    @dev Updating protocol premiums and token price for 1+ token
  */
  function setProtocolPremiumAndTokenPrice(
    bytes32 _protocol,
    IERC20[] memory _token,
    uint256[] memory _premium,
    uint256[] memory _newUsd
  ) external;

  /**
    @notice Set `_token` premium for protocols and internal price to `_newUsd`
    @param _protocol Array of protocol identifiers
    @param _token Token address
    @param _premium Array of amount of tokens to be paid per block
    @param _newUsd USD amount
    @dev Updating multiple protocol premiums for 1 token, including price
  */
  function setProtocolPremiumAndTokenPrice(
    bytes32[] memory _protocol,
    IERC20 _token,
    uint256[] memory _premium,
    uint256 _newUsd
  ) external;

  /**
    @notice Update multiple token premiums and prices for multiple protocols
    @param _protocol Array of protocol identifiers
    @param _token 2 dimensional array of tokens
    @param _premium 2 dimensional array of amounts to be paid per block
    @param _newUsd 2 dimensional array of USD amounts
    @dev Updating multiple protocol premiums for multiple tokens, including price
  */
  function setProtocolPremiumAndTokenPrice(
    bytes32[] memory _protocol,
    IERC20[][] memory _token,
    uint256[][] memory _premium,
    uint256[][] memory _newUsd
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../storage/PoolStorage.sol';
import '../storage/GovStorage.sol';

import './LibSherXERC20.sol';
import './LibPool.sol';

library LibSherX {
  using SafeMath for uint256;

  function viewAccrueUSDPool() public view returns (uint256 totalUsdPool) {
    SherXStorage.Base storage sx = SherXStorage.sx();
    totalUsdPool = sx.totalUsdPool.add(
      block.number.sub(sx.totalUsdLastSettled).mul(sx.totalUsdPerBlock)
    );
  }

  function accrueUSDPool() external returns (uint256 totalUsdPool) {
    SherXStorage.Base storage sx = SherXStorage.sx();
    totalUsdPool = viewAccrueUSDPool();
    sx.totalUsdPool = totalUsdPool;
    sx.totalUsdLastSettled = block.number;
  }

  function settleInternalSupply(uint256 _deduct) external {
    SherXStorage.Base storage sx = SherXStorage.sx();
    sx.internalTotalSupply = getTotalSherX().sub(_deduct);
    sx.internalTotalSupplySettled = block.number;
  }

  function getTotalSherX() public view returns (uint256) {
    // calc by taking base supply, block at, and calc it by taking base + now - block_at * sherxperblock
    // update baseSupply on every premium update
    SherXStorage.Base storage sx = SherXStorage.sx();
    return
      sx.internalTotalSupply.add(
        block.number.sub(sx.internalTotalSupplySettled).mul(sx.sherXPerBlock)
      );
  }

  function calcUnderlying(uint256 _amount)
    external
    view
    returns (IERC20[] memory tokens, uint256[] memory amounts)
  {
    GovStorage.Base storage gs = GovStorage.gs();

    tokens = new IERC20[](gs.tokensSherX.length);
    amounts = new uint256[](gs.tokensSherX.length);

    uint256 total = getTotalSherX();

    for (uint256 i; i < gs.tokensSherX.length; i++) {
      IERC20 token = gs.tokensSherX[i];
      tokens[i] = token;

      if (total > 0) {
        PoolStorage.Base storage ps = PoolStorage.ps(token);
        amounts[i] = ps.sherXUnderlying.add(LibPool.getTotalAccruedDebt(token)).mul(_amount).div(
          total
        );
      } else {
        amounts[i] = 0;
      }
    }
  }

  function accrueSherX(IERC20 _token) public {
    SherXStorage.Base storage sx = SherXStorage.sx();
    uint256 sherX = _accrueSherX(_token, sx.sherXPerBlock);
    if (sherX > 0) {
      LibSherXERC20.mint(address(this), sherX);
    }
  }

  function accrueSherXWatsons() public {
    SherXStorage.Base storage sx = SherXStorage.sx();
    _accrueSherXWatsons(sx.sherXPerBlock);
  }

  function accrueSherX() external {
    // loop over pools, increase the pool + pool_weight based on the distribution weights
    SherXStorage.Base storage sx = SherXStorage.sx();
    GovStorage.Base storage gs = GovStorage.gs();
    uint256 sherXPerBlock = sx.sherXPerBlock;
    uint256 sherX;
    for (uint256 i; i < gs.tokensStaker.length; i++) {
      sherX = sherX.add(_accrueSherX(gs.tokensStaker[i], sherXPerBlock));
    }
    if (sherX > 0) {
      LibSherXERC20.mint(address(this), sherX);
    }

    _accrueSherXWatsons(sherXPerBlock);
  }

  function _accrueSherXWatsons(uint256 sherXPerBlock) private {
    GovStorage.Base storage gs = GovStorage.gs();

    uint256 sherX =
      block
        .number
        .sub(gs.watsonsSherxLastAccrued)
        .mul(sherXPerBlock)
        .mul(gs.watsonsSherxWeight)
        .div(10**18);
    // need to settle before return, as updating the sherxperlblock/weight
    // after it was 0 will result in a too big amount (accured will be < block.number)
    gs.watsonsSherxLastAccrued = block.number;
    if (sherX == 0) {
      return;
    }
    LibSherXERC20.mint(gs.watsonsAddress, sherX);
  }

  function _accrueSherX(IERC20 _token, uint256 sherXPerBlock) private returns (uint256 sherX) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    sherX = block.number.sub(ps.sherXLastAccrued).mul(sherXPerBlock).mul(ps.sherXWeight).div(
      10**18
    );
    // need to settle before return, as updating the sherxperlblock/weight
    // after it was 0 will result in a too big amount (accured will be < block.number)
    ps.sherXLastAccrued = block.number;
    if (sherX == 0) {
      return 0;
    }
    if (address(_token) == address(this)) {
      ps.stakeBalance = ps.stakeBalance.add(sherX);
    } else {
      ps.unallocatedSherX = ps.unallocatedSherX.add(sherX);
      ps.sWeight = ps.sWeight.add(sherX);
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../storage/PoolStorage.sol';
import '../storage/SherXStorage.sol';

library LibPool {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for ILock;

  function accruedDebt(bytes32 _protocol, IERC20 _token) public view returns (uint256) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    return _accruedDebt(ps, _protocol, block.number.sub(ps.totalPremiumLastPaid));
  }

  function getTotalAccruedDebt(IERC20 _token) public view returns (uint256) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    return _getTotalAccruedDebt(ps, block.number.sub(ps.totalPremiumLastPaid));
  }

  function getTotalUnmintedSherX(IERC20 _token) public view returns (uint256 sherX) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    SherXStorage.Base storage sx = SherXStorage.sx();
    sherX = block.number.sub(ps.sherXLastAccrued).mul(sx.sherXPerBlock).mul(ps.sherXWeight).div(
      10**18
    );
  }

  function getUnallocatedSherXFor(address _user, IERC20 _token)
    external
    view
    returns (uint256 withdrawable_amount)
  {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);

    uint256 userAmount = ps.lockToken.balanceOf(_user);
    uint256 totalAmount = ps.lockToken.totalSupply();
    if (totalAmount == 0) {
      return 0;
    }

    uint256 raw_amount =
      ps.sWeight.add(getTotalUnmintedSherX(_token)).mul(userAmount).div(totalAmount);
    withdrawable_amount = raw_amount.sub(ps.sWithdrawn[_user]);
  }

  function stake(
    PoolStorage.Base storage ps,
    uint256 _amount,
    address _receiver
  ) external returns (uint256 lock) {
    uint256 totalLock = ps.lockToken.totalSupply();
    if (totalLock == 0) {
      // mint initial lock
      lock = 10**18;
    } else {
      // mint lock based on funds in pool
      lock = _amount.mul(totalLock).div(ps.stakeBalance);
    }
    ps.stakeBalance = ps.stakeBalance.add(_amount);
    ps.lockToken.mint(_receiver, lock);
  }

  function payOffDebtAll(IERC20 _token) external {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    uint256 blocks = block.number.sub(ps.totalPremiumLastPaid);

    for (uint256 i = 0; i < ps.protocols.length; i++) {
      _payOffDebt(ps, ps.protocols[i], blocks);
    }
    // TODO gas optimalisation check
    // _getTotalAccruedDebt reads 1 variable from storage (200 gas)
    // is it cheaper to sum up the debt return value of _payOffDebt()
    // and store that into ps.sherXUnderlying?
    uint256 totalAccruedDebt = _getTotalAccruedDebt(ps, blocks);
    // move funds to the sherX etf
    ps.sherXUnderlying = ps.sherXUnderlying.add(totalAccruedDebt);
    ps.totalPremiumLastPaid = block.number;
  }

  function _payOffDebt(
    PoolStorage.Base storage ps,
    bytes32 _protocol,
    uint256 _blocks
  ) private {
    uint256 debt = _accruedDebt(ps, _protocol, _blocks);
    ps.protocolBalance[_protocol] = ps.protocolBalance[_protocol].sub(debt);
  }

  function _accruedDebt(
    PoolStorage.Base storage ps,
    bytes32 _protocol,
    uint256 _blocks
  ) private view returns (uint256) {
    return _blocks.mul(ps.protocolPremium[_protocol]);
  }

  function _getTotalAccruedDebt(PoolStorage.Base storage ps, uint256 _blocks)
    private
    view
    returns (uint256)
  {
    return _blocks.mul(ps.totalPremiumPerBlock);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../interfaces/ILock.sol';

// TokenStorage
library PoolStorage {
  string constant POOL_STORAGE_PREFIX = 'diamond.sherlock.pool.';

  struct Base {
    address govPool;
    //
    // Staking
    //
    bool stakes;
    ILock lockToken;
    uint256 activateCooldownFee;
    uint256 stakeBalance;
    mapping(address => UnstakeEntry[]) unstakeEntries;
    uint256 firstMoneyOut;
    uint256 unallocatedSherX;
    // How much sherX is distributed to stakers of this token
    uint256 sherXWeight;
    uint256 sherXLastAccrued;
    // Non-native variables
    mapping(address => uint256) sWithdrawn;
    uint256 sWeight;
    //
    // Protocol payments
    //
    bool premiums;
    mapping(bytes32 => uint256) protocolBalance;
    mapping(bytes32 => uint256) protocolPremium;
    uint256 totalPremiumPerBlock;
    uint256 totalPremiumLastPaid;
    // How much token (this) is available for sherX holders
    uint256 sherXUnderlying;
    mapping(bytes32 => bool) isProtocol;
    bytes32[] protocols;
  }

  struct UnstakeEntry {
    uint256 blockInitiated;
    uint256 lock;
  }

  function ps(IERC20 _token) internal pure returns (Base storage psx) {
    bytes32 position = keccak256(abi.encode(POOL_STORAGE_PREFIX, _token));
    assembly {
      psx.slot := position
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library GovStorage {
  bytes32 constant GOV_STORAGE_POSITION = keccak256('diamond.sherlock.gov');

  struct Base {
    address govMain;
    // NOTE: UNUSED
    mapping(bytes32 => address) protocolManagers;
    mapping(bytes32 => address) protocolAgents;
    uint256 unstakeCooldown;
    uint256 unstakeWindow;
    mapping(bytes32 => bool) protocolIsCovered;
    IERC20[] tokensStaker;
    IERC20[] tokensSherX;
    address watsonsAddress;
    uint256 watsonsSherxWeight;
    uint256 watsonsSherxLastAccrued;
  }

  function gs() internal pure returns (Base storage gsx) {
    bytes32 position = GOV_STORAGE_POSITION;
    assembly {
      gsx.slot := position
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz

* Inspired by: https://github.com/pie-dao/PieVaults/blob/master/contracts/facets/ERC20/LibERC20.sol
/******************************************************************************/

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../storage/SherXERC20Storage.sol';

library LibSherXERC20 {
  using SafeMath for uint256;

  // Need to include events locally because `emit Interface.Event(params)` does not work
  event Transfer(address indexed from, address indexed to, uint256 amount);

  function mint(address _to, uint256 _amount) internal {
    SherXERC20Storage.Base storage sx20 = SherXERC20Storage.sx20();

    sx20.balances[_to] = sx20.balances[_to].add(_amount);
    sx20.totalSupply = sx20.totalSupply.add(_amount);
    emit Transfer(address(0), _to, _amount);
  }

  function burn(address _from, uint256 _amount) internal {
    SherXERC20Storage.Base storage sx20 = SherXERC20Storage.sx20();

    sx20.balances[_from] = sx20.balances[_from].sub(_amount);
    sx20.totalSupply = sx20.totalSupply.sub(_amount);
    emit Transfer(_from, address(0), _amount);
  }

  function approve(
    address _from,
    address _to,
    uint256 _amount
  ) internal returns (bool) {
    SherXERC20Storage.sx20().allowances[_from][_to] = _amount;
    return true;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
  @title Lock Token
  @author Evert Kors
  @notice Lock tokens represent a stake in Sherlock
*/
interface ILock is IERC20 {
  /**
    @notice Returns the owner of this contract
    @return Owner address
    @dev Should be equal to the Sherlock address
  */
  function getOwner() external view returns (address);

  /**
    @notice Returns token it represents
    @return Token address
  */
  function underlying() external view returns (IERC20);

  /**
    @notice Mint `_amount` tokens for `_account`
    @param _account Account to receive tokens
    @param _amount Amount to be minted
  */
  function mint(address _account, uint256 _amount) external;

  /**
    @notice Burn `_amount` tokens for `_account`
    @param _account Account to be burned
    @param _amount Amount to be burned
  */
  function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.1;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz

* Inspired by: https://github.com/pie-dao/PieVaults/blob/master/contracts/facets/ERC20/LibERC20Storage.sol
/******************************************************************************/

library SherXERC20Storage {
  bytes32 constant SHERX_ERC20_STORAGE_POSITION = keccak256('diamond.sherlock.x.erc20');

  struct Base {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
  }

  function sx20() internal pure returns (Base storage sx20x) {
    bytes32 position = SHERX_ERC20_STORAGE_POSITION;
    assembly {
      sx20x.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library SherXStorage {
  bytes32 constant SHERX_STORAGE_POSITION = keccak256('diamond.sherlock.x');

  struct Base {
    mapping(IERC20 => uint256) tokenUSD;
    uint256 totalUsdPerBlock;
    uint256 totalUsdPool;
    uint256 totalUsdLastSettled;
    uint256 sherXPerBlock;
    uint256 internalTotalSupply;
    uint256 internalTotalSupplySettled;
  }

  function sx() internal pure returns (Base storage sxx) {
    bytes32 position = SHERX_STORAGE_POSITION;
    assembly {
      sxx.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

