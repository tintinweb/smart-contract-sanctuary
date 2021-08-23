// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IPriceOracleAggregator.sol";
import "../../interfaces/IOracle.sol";

contract PriceOracleAggregator is IPriceOracleAggregator {
  /// @dev admin allowed to update price oracle
  address public immutable admin;

  /// @notice token to the oracle address
  mapping(address => IOracle) public assetToOracle;

  modifier onlyAdmin() {
    require(msg.sender == admin, "ONLY_ADMIN");
    _;
  }

  constructor(address _admin) {
    require(_admin != address(0), "INVALID_ADMIN");
    admin = _admin;
  }

  /// @notice adds oracle for an asset e.g. ETH
  /// @param _asset the oracle for the asset
  /// @param _oracle the oracle address
  function updateOracleForAsset(address _asset, IOracle _oracle)
    external
    override
    onlyAdmin
  {
    require(address(_oracle) != address(0), "INVALID_ORACLE");
    assetToOracle[_asset] = _oracle;
    emit UpdateOracle(_asset, _oracle);
  }

  /// @notice returns price of token in USD in 1e8 decimals
  /// @param _token token to fetch price
  function getPriceInUSD(address _token) external override returns (uint256) {
    require(address(assetToOracle[_token]) != address(0), "INVALID_ORACLE");
    return assetToOracle[_token].getPriceInUSD();
  }

  /// @notice returns price of token in USD
  /// @param _token view price of token
  function viewPriceInUSD(address _token)
    external
    view
    override
    returns (uint256)
  {
    require(address(assetToOracle[_token]) != address(0), "INVALID_ORACLE");
    return assetToOracle[_token].viewPriceInUSD();
  }
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

import "./IOracle.sol";

interface IPriceOracleAggregator {
  event UpdateOracle(address token, IOracle oracle);

  function getPriceInUSD(address _token) external returns (uint256);

  function updateOracleForAsset(address _asset, IOracle _oracle) external;

  function viewPriceInUSD(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
  /// @notice Price update event
  /// @param asset the asset
  /// @param newPrice price of the asset
  event PriceUpdated(address asset, uint256 newPrice);

  function getPriceInUSD() external returns (uint256);

  function viewPriceInUSD() external view returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}