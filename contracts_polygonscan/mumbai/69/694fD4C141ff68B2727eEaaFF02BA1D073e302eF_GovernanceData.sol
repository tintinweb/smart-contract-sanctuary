// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GovernanceData is Ownable {
    int256 public initialMarginRatio;
    int256 public maintenanceMarginRatio;
    int256 public minLiquidationReward;
    int256 public maxLiquidationReward;
    int256 public liquidationCutRatio;
    int256 public protocolFeeCollectRatio;
    address public symbolOracleAddress;
    address public symbolVolatilityAddress;
    int256 public symbolMultiplier;
    int256 public symbolFeeRatio;
    int256 public symbolDeltaFundingCoefficient; // intrisic value

    /**
     * @dev set initial state of the data
     */
    constructor(
        int256 _initialMarginRatio,
        int256 _maintenanceMarginRatio,
        int256 _minLiquidationReward,
        int256 _maxLiquidationReward,
        int256 _liquidationCutRatio,
        int256 _protocolFeeCollectRatio,
        address _symbolOracleAddress,
        address _symbolVolatilityAddress,
        int256 _symbolMultiplier,
        int256 _symbolFeeRatio,
        int256 _symbolDeltaFundingCoefficient
    ) {
        initialMarginRatio = _initialMarginRatio;
        maintenanceMarginRatio = _maintenanceMarginRatio;
        minLiquidationReward = _minLiquidationReward;
        maxLiquidationReward = _maxLiquidationReward;
        liquidationCutRatio = _liquidationCutRatio;
        protocolFeeCollectRatio = _protocolFeeCollectRatio;
        symbolOracleAddress = _symbolOracleAddress;
        symbolVolatilityAddress = _symbolVolatilityAddress;
        symbolMultiplier = _symbolMultiplier;
        symbolFeeRatio = _symbolFeeRatio;
        symbolDeltaFundingCoefficient = _symbolDeltaFundingCoefficient;
    }

    function setInitialMarginRatio(int256 _initialMarginRatio) external onlyOwner {
        initialMarginRatio = _initialMarginRatio;
    }

    function setMaintenanceMarginRatio(int256 _maintenanceMarginRatio) external onlyOwner {
        maintenanceMarginRatio = _maintenanceMarginRatio;
    }

    function setMinLiquidationReward(int256 _minLiquidationReward) external onlyOwner {
        minLiquidationReward = _minLiquidationReward;
    }

    function setMaxLiquidationReward(int256 _maxLiquidationReward) external onlyOwner {
        maxLiquidationReward = _maxLiquidationReward;
    }

    function setLiquidationCutRatio(int256 _liquidationCutRatio) external onlyOwner {
        liquidationCutRatio = _liquidationCutRatio;
    }

    function setProtocolFeeCollectRatio(int256 _protocolFeeCollectRatio) external onlyOwner {
        protocolFeeCollectRatio = _protocolFeeCollectRatio;
    }

    function setSymbolOracleAddress(address _symbolOracleAddress) external onlyOwner {
        symbolOracleAddress = _symbolOracleAddress;
    }

    function setSymbolVolatilityAddress(address _symbolVolatilityAddress) external onlyOwner {
        symbolVolatilityAddress = _symbolVolatilityAddress;
    }

    function setSymbolMultiplier(int256 _symbolMultiplier) external onlyOwner {
        symbolMultiplier = _symbolMultiplier;
    }

    function setSymbolFeeRatio(int256 _symbolFeeRatio) external onlyOwner {
        symbolFeeRatio = _symbolFeeRatio;
    }

    function setSymbolDeltaFundingCoefficient(int256 _symbolDeltaFundingCoefficient) external onlyOwner {
        symbolDeltaFundingCoefficient = _symbolDeltaFundingCoefficient;
    }

    function getParameters()
        external
        view
        returns (
            int256,
            int256,
            int256,
            int256,
            int256,
            int256
        )
    {
        return (
            initialMarginRatio,
            maintenanceMarginRatio,
            minLiquidationReward,
            maxLiquidationReward,
            liquidationCutRatio,
            protocolFeeCollectRatio
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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