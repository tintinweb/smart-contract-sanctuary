// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ProtocolParameters is Ownable {
    int256 public minPoolMarginRatio;
    int256 public minInitialMarginRatio;
    int256 public minMaintenanceMarginRatio;
    int256 public minLiquidationReward;
    int256 public maxLiquidationReward;
    int256 public liquidationCutRatio;
    int256 public protocolFeeCollectRatio;
    address public symbolOracleAddress;
    int256 public symbolMultiplier;
    int256 public symbolFeeRatio;
    int256 public symbolFundingRateCoefficient;
    uint256 public oracleDelay;

    /**
     * @dev set initial state of the data
     */
    constructor(
        int256 _minPoolMarginRatio,
        int256 _minInitialMarginRatio,
        int256 _minMaintenanceMarginRatio,
        int256 _minLiquidationReward,
        int256 _maxLiquidationReward,
        int256 _liquidationCutRatio,
        int256 _protocolFeeCollectRatio,
        address _symbolOracleAddress,
        int256 _symbolMultiplier,
        int256 _symbolFeeRatio,
        int256 _symbolFundingRateCoefficient,
        uint256 _oracleDelay
    ) {
        minPoolMarginRatio = _minPoolMarginRatio;
        minInitialMarginRatio = _minInitialMarginRatio;
        minMaintenanceMarginRatio = _minMaintenanceMarginRatio;
        minLiquidationReward = _minLiquidationReward;
        maxLiquidationReward = _maxLiquidationReward;
        liquidationCutRatio = _liquidationCutRatio;
        protocolFeeCollectRatio = _protocolFeeCollectRatio;
        symbolOracleAddress = _symbolOracleAddress;
        symbolMultiplier = _symbolMultiplier;
        symbolFeeRatio = _symbolFeeRatio;
        symbolFundingRateCoefficient = _symbolFundingRateCoefficient;
        oracleDelay = _oracleDelay;
    }

    function setMinPoolMarginRatio(int256 _minPoolMarginRatio) external onlyOwner {
        minPoolMarginRatio = _minPoolMarginRatio;
    }

    function setMinInitialMarginRatio(int256 _minInitialMarginRatio) external onlyOwner {
        minInitialMarginRatio = _minInitialMarginRatio;
    }

    function setMinMaintenanceMarginRatio(int256 _minMaintenanceMarginRatio) external onlyOwner {
        minMaintenanceMarginRatio = _minMaintenanceMarginRatio;
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

    function setSymbolMultiplier(int256 _symbolMultiplier) external onlyOwner {
        symbolMultiplier = _symbolMultiplier;
    }

    function setSymbolFeeRatio(int256 _symbolFeeRatio) external onlyOwner {
        symbolFeeRatio = _symbolFeeRatio;
    }

    function setSymbolFundingRateCoefficient(int256 _symbolFundingRateCoefficient) external onlyOwner {
        symbolFundingRateCoefficient = _symbolFundingRateCoefficient;
    }

    function setOracleDelay(uint256 _oracleDelay) external onlyOwner {
       oracleDelay = _oracleDelay;
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

