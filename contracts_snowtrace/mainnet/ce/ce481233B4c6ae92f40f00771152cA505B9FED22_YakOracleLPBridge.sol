// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IYakStrategy is IERC20Metadata {
  function getSharesForDepositTokens(uint256 amount)
    external
    view
    returns (uint256);

  function getDepositTokensForShares(uint256 amount)
    external
    view
    returns (uint256);

  function totalDeposits() external view returns (uint256);

  function estimateReinvestReward() external view returns (uint256);

  function checkReward() external view returns (uint256);

  function estimateDeployedBalance() external view returns (uint256);

  function withdraw(uint256 amount) external;

  function deposit(uint256 amount) external;

  function deposit() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

import '../interfaces/IYakStrategy.sol';
import '../interfaces/IPair.sol';

contract YakOracleLPBridge is AggregatorV3Interface {
  // Chainlink price source
  AggregatorV3Interface public immutable priceSource1;
  AggregatorV3Interface public immutable priceSource2;

  IPair public immutable underlyingToken;

  // The YRT token
  IYakStrategy public immutable shareToken;

  constructor(
    address priceSource1_,
    address priceSource2_,
    address underlyingToken_,
    address shareToken_
  ) {
    assert(priceSource1_ != address(0));
    assert(priceSource2_ != address(0));
    assert(shareToken_ != address(0));
    assert(underlyingToken_ != address(0));
    priceSource1 = AggregatorV3Interface(priceSource1_);
    priceSource2 = AggregatorV3Interface(priceSource2_);
    underlyingToken = IPair(underlyingToken_);
    shareToken = IYakStrategy(shareToken_); // YRT token
  }

  function sqrt(uint256 x) internal pure returns (uint128) {
    if (x == 0) return 0;
    uint256 xx = x;
    uint256 r = 1;
    if (xx >= 0x100000000000000000000000000000000) {
      xx >>= 128;
      r <<= 64;
    }
    if (xx >= 0x10000000000000000) {
      xx >>= 64;
      r <<= 32;
    }
    if (xx >= 0x100000000) {
      xx >>= 32;
      r <<= 16;
    }
    if (xx >= 0x10000) {
      xx >>= 16;
      r <<= 8;
    }
    if (xx >= 0x100) {
      xx >>= 8;
      r <<= 4;
    }
    if (xx >= 0x10) {
      xx >>= 4;
      r <<= 2;
    }
    if (xx >= 0x8) {
      r <<= 1;
    }
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1;
    r = (r + x / r) >> 1; // Seven iterations should be enough
    uint256 r1 = x / r;
    return uint128(r < r1 ? r : r1);
  }

  function decimals() external pure override returns (uint8) {
    return 8;
  }

  function description() external view override returns (string memory) {
    return
      string(
        abi.encodePacked(priceSource1.description(), priceSource2.description())
      );
  }

  function version() external view override returns (uint256) {
    return priceSource1.version();
  }

  function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return priceSource1.getRoundData(_roundId);
  }

  function calculateLPPrice(int256 answer1, int256 answer2)
    internal
    view
    returns (uint256)
  {
    // get reserves
    (uint256 reserve0, uint256 reserve1, ) = underlyingToken.getReserves();

    // Normalize everything to 18 decimals (useful for usdc, btc)
    uint256 normalizedReserve0 = reserve0 *
      (10**(18 - IERC20Metadata(underlyingToken.token0()).decimals()));
    uint256 normalizedReserve1 = reserve1 *
      (10**(18 - IERC20Metadata(underlyingToken.token1()).decimals()));

    // Fair pricing, based off: https://blog.alphafinance.io/fair-lp-token-pricing/
    uint256 k = sqrt(normalizedReserve0 * normalizedReserve1);
    // Calculate the fair price
    uint256 totalValue = (2 *
      k *
      sqrt(
        uint256(answer1 * answer2) *
          10**(36 - priceSource1.decimals() - priceSource2.decimals())
      )) / underlyingToken.totalSupply();
    return totalValue / 1e10;
  }

  // The one we edit for compounder!
  function latestRoundData()
    external
    view
    virtual
    override
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    // Lets do some calcs!
    (
      uint80 roundId,
      int256 answer1,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = priceSource1.latestRoundData();
    // Lets do some calcs!
    (, int256 answer2, , , ) = priceSource2.latestRoundData();

    require(answer1 >= 0, 'Chainlink pricefeed 1 returned bad value.');
    require(answer2 >= 0, 'Chainlink pricefeed 2 returned bad value.');
    uint256 totalValue = calculateLPPrice(answer1, answer2);
    uint256 newPrice = (shareToken.getDepositTokensForShares(
      10**underlyingToken.decimals()
    ) * uint256(totalValue)) / 10**underlyingToken.decimals();
    return (roundId, int256(newPrice), startedAt, updatedAt, answeredInRound);
  }
}