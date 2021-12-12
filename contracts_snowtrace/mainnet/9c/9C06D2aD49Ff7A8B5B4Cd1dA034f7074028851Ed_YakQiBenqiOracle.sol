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

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

import './interfaces/IYakStrategy.sol';

contract OracleBridge is AggregatorV3Interface {
  // Chainlink price source
  AggregatorV3Interface public immutable priceSource;
  IERC20Metadata public immutable underlyingToken;

  // The YRT token
  IYakStrategy public immutable shareToken;

  constructor(
    address priceSource_,
    address underlyingToken_,
    address shareToken_
  ) {
    assert(priceSource_ != address(0));
    assert(shareToken_ != address(0));
    assert(underlyingToken_ != address(0));
    priceSource = AggregatorV3Interface(priceSource_);
    underlyingToken = IERC20Metadata(underlyingToken_);
    shareToken = IYakStrategy(shareToken_); // YRT token
  }

  function decimals() external view override returns (uint8) {
    return priceSource.decimals();
  }

  function description() external view override returns (string memory) {
    return priceSource.description();
  }

  function version() external view override returns (uint256) {
    return priceSource.version();
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
    return priceSource.getRoundData(_roundId);
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
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = priceSource.latestRoundData();

    require(answer >= 0, 'Chainlink pricefeed returned bad value.');
    // Return price of 1 YRT
    uint256 newPrice = (shareToken.getDepositTokensForShares(
      10**underlyingToken.decimals()
    ) * uint256(answer)) / 10**underlyingToken.decimals();

    return (roundId, int256(newPrice), startedAt, updatedAt, answeredInRound);
  }
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

import '../OracleBridge.sol';

contract YakQiBenqiOracle is OracleBridge {
  constructor(
    address priceSource_,
    address underlyingToken_,
    address shareToken_
  ) OracleBridge(priceSource_, underlyingToken_, shareToken_) {}
}