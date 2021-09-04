// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Interfaces
import {IERC20} from '../interfaces/IERC20.sol';
import {IPriceOracleAggregator} from '../interfaces/IPriceOracleAggregator.sol';
import {IOracle} from '../interfaces/IOracle.sol';

contract PriceOracleAggregator is IPriceOracleAggregator {
    /// @dev admin allowed to update price oracle
    address public immutable admin;

    /// @notice token to the oracle address
    mapping(address => IOracle) public assetToOracle;

    modifier onlyAdmin() {
        require(msg.sender == admin, 'ONLY_ADMIN');
        _;
    }

    constructor(address _admin) {
        require(_admin != address(0), 'INVALID_ADMIN');
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
        require(address(_oracle) != address(0), 'INVALID_ORACLE');
        assetToOracle[_asset] = _oracle;
        emit UpdateOracle(_asset, _oracle);
    }

    /// @notice returns price of token in USD in 1e8 decimals
    /// @param _token token to fetch price
    function getPriceInUSD(address _token) external override returns (uint256) {
        require(address(assetToOracle[_token]) != address(0), 'INVALID_ORACLE');
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
        require(address(assetToOracle[_token]) != address(0), 'INVALID_ORACLE');
        return assetToOracle[_token].viewPriceInUSD();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IOracle } from "./IOracle.sol";

interface IPriceOracleAggregator {
  event UpdateOracle(address token, IOracle oracle);

  function getPriceInUSD(address _token) external returns (uint256);

  function updateOracleForAsset(address _asset, IOracle _oracle) external;

  function viewPriceInUSD(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOracle {
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