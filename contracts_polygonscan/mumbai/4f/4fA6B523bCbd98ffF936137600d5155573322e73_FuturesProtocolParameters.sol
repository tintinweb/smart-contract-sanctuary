// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Structs.sol";

// ! TODO: EMIT THE EVENTS AND ADD VALIDATIONS

/**
 * @title future parameters controlled by governance
 * @notice the owner of this contract is the timelock controller of the governance feature
 */
contract FuturesProtocolParameters is Ownable {
    int256 public minPoolMarginRatio;
    int256 public minInitialMarginRatio;
    int256 public minMaintenanceMarginRatio;
    int256 public minLiquidationReward;
    int256 public maxLiquidationReward;
    int256 public liquidationCutRatio;
    int256 public protocolFeeCollectRatio;
    address public futuresOracleAddress;
    int256 public futuresMultiplier;
    int256 public futuresFeeRatio;
    int256 public futuresFundingRateCoefficient;
    uint256 public oracleDelay;

    event MinPoolMarginRatioUpdated(address value);
    event MinInitialMarginRatioUpdated(address value);
    event MinMaintenanceMarginRatioUpdated(address value);
    event MinLiquidationRewardUpdated(address value);
    event MaxLiquidationRewardUpdated(address value);
    event LiquidationCutRatioUpdated(address value);
    event ProtocolFeeCollectRatioUpdated(address value);
    event OracleDelayUpdated(address value);
    event FuturesOracleAddressUpdated(address value);
    event FuturesMultiplierUpdated(int256 value);
    event FuturesFeeRatioUpdated(int256 value);
    event FuturesFundingRateCoefficientUpdated(int256 value);

    /**
     * @dev set initial state of the data
     */
    constructor(
        MainParams memory mainParams,
        address _futuresOracleAddress,
        int256 _futuresMultiplier,
        int256 _futuresFeeRatio,
        int256 _futuresFundingRateCoefficient,
        uint256 _oracleDelay,
        address _governanceContractAddress
    ) {
        require(_futuresOracleAddress != address(0), "Oracle address can't be zero");
        require(_futuresMultiplier > 0, "Invalid futures multiplier");
        require(_futuresFeeRatio > 0, "Invalid futures fee ratio");
        require(_futuresFundingRateCoefficient > 0, "Invalid futures funding rate coefficient");

        minPoolMarginRatio = mainParams.minPoolMarginRatio;
        minInitialMarginRatio = mainParams.minInitialMarginRatio;
        minMaintenanceMarginRatio = mainParams.minMaintenanceMarginRatio;
        minLiquidationReward = mainParams.minLiquidationReward;
        maxLiquidationReward = mainParams.maxLiquidationReward;
        liquidationCutRatio = mainParams.liquidationCutRatio;
        protocolFeeCollectRatio = mainParams.protocolFeeCollectRatio;
        futuresOracleAddress = _futuresOracleAddress;
        futuresMultiplier = _futuresMultiplier;
        futuresFeeRatio = _futuresFeeRatio;
        futuresFundingRateCoefficient = _futuresFundingRateCoefficient;
        oracleDelay = _oracleDelay;

        // transfer ownership
        transferOwnership(_governanceContractAddress);
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

    function setFuturesOracleAddress(address futuresOracleAddress_) external onlyOwner {
        require(futuresOracleAddress_ != address(0), "Oracle address can't be zero");
        futuresOracleAddress = futuresOracleAddress_;
        emit FuturesOracleAddressUpdated(futuresOracleAddress_);
    }

    function setFuturesMultiplier(int256 futuresMultiplier_) external onlyOwner {
        require(futuresMultiplier_ > 1 hours, "Invalid futures multiplier");
        futuresMultiplier = futuresMultiplier_;
        emit FuturesMultiplierUpdated(futuresMultiplier_);
    }

    function setFuturesFeeRatio(int256 futuresFeeRatio_) external onlyOwner {
        require(futuresFeeRatio_ > 1 hours, "Invalid futures fee ratio");
        futuresFeeRatio = futuresFeeRatio_;
        emit FuturesFeeRatioUpdated(futuresFeeRatio_);
    }

    function setFuturesFundingRateCoefficient(int256 futuresFundingRateCoefficient_) external onlyOwner {
        require(futuresFundingRateCoefficient_ > 1 hours, "Invalid futures funding rate coefficient");
        futuresFundingRateCoefficient = futuresFundingRateCoefficient_;
        emit FuturesFundingRateCoefficientUpdated(futuresFundingRateCoefficient_);
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
pragma solidity ^0.8.4;

struct MainParams {
    int256 minPoolMarginRatio;
    int256 minInitialMarginRatio;
    int256 minMaintenanceMarginRatio;
    int256 minLiquidationReward;
    int256 maxLiquidationReward;
    int256 liquidationCutRatio;
    int256 protocolFeeCollectRatio;
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

