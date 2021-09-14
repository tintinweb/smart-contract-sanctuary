// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IRequestFeesCalculator.sol";

contract RequestFeesCalculator is IRequestFeesCalculator, Ownable {

	uint168 public constant MAX_FEE_PERCENTAGE = 10000;

	uint32 public minTimeWindow = 1 hours;
	uint32 public maxTimeWindow = 3 hours;

	uint16 public minTimeDelayFeePercent = 0;
	uint16 public maxTimeDelayFeePercent = 100;

	uint32 public minWaitTime = 15 minutes;

	//TOOD: Default values
	uint16 public beforeTargetTimeMaxPenaltyFeePercent = 300;
	uint16 public afterTargetMidTimePenaltyFeePercent = 300;
	uint16 public afterTargetMaxTimePenaltyFeePercent = 500;

	uint16 public findersFeePercent = 5000;

	uint32 public afterTargetMidTime = 1 hours;
	uint32 public afterTargetMaxTime = 12 hours;

	function calculateTimePenaltyFee(IVolatilityToken.Request calldata _request) external view override returns (uint16 feePercentage) {
		feePercentage = afterTargetMaxTimePenaltyFeePercent;

		if (block.timestamp < _request.targetTimestamp) {
			// Linear decreasing between beforeTargetTimeMaxPenaltyFeePercent and 0
            require(block.timestamp >= _request.requestTimestamp + minWaitTime, "Min wait time not over");
            //TOOD: Safe cast?
			feePercentage = uint16((_request.targetTimestamp - block.timestamp) * beforeTargetTimeMaxPenaltyFeePercent / (_request.targetTimestamp - _request.requestTimestamp - minWaitTime));
		} else if (block.timestamp < _request.targetTimestamp + afterTargetMidTime) {
			// Linear increasing between 0 and afterTargetMidTimePenaltyFeePercent
			feePercentage = uint16((block.timestamp - _request.targetTimestamp) * afterTargetMidTimePenaltyFeePercent / afterTargetMidTime);
		} else if (block.timestamp < _request.targetTimestamp + afterTargetMaxTime) {
			// Between afterTargetMidTimePenaltyFeePercent and afterTargetMaxTimePenaltyFeePercent
			feePercentage = uint16(((block.timestamp - _request.targetTimestamp - afterTargetMidTime) * (afterTargetMaxTimePenaltyFeePercent - afterTargetMidTimePenaltyFeePercent) / 
                (afterTargetMaxTime - afterTargetMidTime)) + afterTargetMidTimePenaltyFeePercent);
		}
	}

    function calculateTimeDelayFee(uint256 _timeDelay) external view override returns (uint16 feePercentage) {
    	require(_timeDelay >= minTimeWindow, "Time delay too small");
    	require(_timeDelay <= maxTimeWindow, "Time delay too big");

        // Can convert to uint16 as result will mathematically never be larger, due to _timeDelay range verifications
    	feePercentage = uint16(maxTimeDelayFeePercent - (_timeDelay - minTimeWindow) * (maxTimeDelayFeePercent - minTimeDelayFeePercent) / (maxTimeWindow - minTimeWindow));
    }

    function calculateFindersFee(uint256 tokensLeftAmount) external view override returns (uint256 findersFeeAmount) {
    	return tokensLeftAmount * findersFeePercent / MAX_FEE_PERCENTAGE;
    }

    function isLiquidable(IVolatilityToken.Request calldata _request) external view override returns (bool liquidable) {
    	if (block.timestamp > _request.targetTimestamp + afterTargetMaxTime) {
    		return true;
    	}

    	return false;
    }

    function setTimeWindow(uint32 _minTimeWindow, uint32 _maxTimeWindow) external override onlyOwner {
    	require(_minTimeWindow <= _maxTimeWindow, "Max is less than min");

    	minTimeWindow = _minTimeWindow;
    	maxTimeWindow = _maxTimeWindow;
    }

    function setTimeDelayFeesParameters(uint16 _minTimeDelayFeePercent, uint16 _maxTimeDelayFeePercent) external override onlyOwner {
    	require(_minTimeDelayFeePercent <= MAX_FEE_PERCENTAGE, "Min fee larger than max fee");
    	require(_maxTimeDelayFeePercent <= MAX_FEE_PERCENTAGE, "Max fee larger than max fee");
    	require(_minTimeDelayFeePercent <= _maxTimeDelayFeePercent, "Max is less than min");
    	minTimeDelayFeePercent = _minTimeDelayFeePercent;
    	maxTimeDelayFeePercent = _maxTimeDelayFeePercent;
    }

    function setMinWaitTime(uint32 _minWaitTime) external override onlyOwner {
    	require(_minWaitTime < minTimeWindow, "Min wait time in window");
    	minWaitTime = _minWaitTime;
    }

    function setTimePenaltyFeeParameters(uint16 _beforeTargetTimeMaxPenaltyFeePercent, uint32 _afterTargetMidTime, uint16 _afterTargetMidTimePenaltyFeePercent, uint32 _afterTargetMaxTime, uint16 _afterTargetMaxTimePenaltyFeePercent) external override onlyOwner {
    	require(_beforeTargetTimeMaxPenaltyFeePercent <= MAX_FEE_PERCENTAGE, "Min fee larger than max fee");
    	require(_afterTargetMidTimePenaltyFeePercent <= MAX_FEE_PERCENTAGE, "Mid fee larger than max fee");
    	require(_afterTargetMaxTimePenaltyFeePercent <= MAX_FEE_PERCENTAGE, "Max fee larger than max fee");
    	require(_afterTargetMidTime <= _afterTargetMaxTime, "Max time before mid time");
    	require(_afterTargetMidTimePenaltyFeePercent <= _afterTargetMaxTimePenaltyFeePercent, "Max fee less than mid fee");

    	beforeTargetTimeMaxPenaltyFeePercent = _beforeTargetTimeMaxPenaltyFeePercent;
    	afterTargetMidTime = _afterTargetMidTime;
    	afterTargetMidTimePenaltyFeePercent = _afterTargetMidTimePenaltyFeePercent;
    	afterTargetMaxTime = _afterTargetMaxTime;
    	afterTargetMaxTimePenaltyFeePercent = _afterTargetMaxTimePenaltyFeePercent;
    }

    function setFindersFee(uint16 _findersFeePercent) external override onlyOwner {
    	require(_findersFeePercent <= MAX_FEE_PERCENTAGE, "Fee larger than max");
    	findersFeePercent = _findersFeePercent;
    }

    function getMaxFees() external view override returns (uint16 maxFeesPercent) {
		return afterTargetMaxTimePenaltyFeePercent;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./IPlatform.sol";
import "./IRequestFeesCalculator.sol";
import "./ICVIOracle.sol";

interface IVolatilityToken {

	struct Request {
		uint8 requestType; // 1 => mint, 2 => burn, 3 => collateralized mint
		uint168 tokenAmount;
        uint16 timeDelayRequestFeesPercent;
		uint16 maxRequestFeesPercent;
        address owner;
        uint32 requestTimestamp;
        uint32 targetTimestamp;
    }

    event SubmitRequest(uint256 requestId, uint8 requestType, address indexed account, uint256 tokenAmount, uint256 submitFeesAmount, uint32 targetTimestamp);
    event FulfillRequest(uint256 requestId, address indexed account, uint256 fulfillFeesAmount);
    event LiquidateRequest(uint256 requestId, uint8 requestType, address indexed account, address indexed liquidator, uint256 findersFeeAmount);
    event Mint(address indexed account, uint256 tokenAmount, uint256 mintedTokens);
    event CollateralizedMint(address indexed account, uint256 tokenAmount, uint256 mintedTokens, uint256 mintedShortTokens);
    event Burn(address indexed account, uint256 tokenAmount, uint256 burnedTokens);

    function rebaseCVI() external;

    function submitMintRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);
    function submitBurnRequest(uint168 tokenAmount, uint32 timeDelay) external returns (uint256 requestId);

    function fulfillMintRequest(uint256 requestId, uint16 maxBuyingPremiumFeePercentage) external returns (uint256 tokensMinted);
    function fulfillBurnRequest(uint256 requestId) external returns (uint256 tokensBurned);
    function fulfillCollateralizedMintRequest(uint256 requestId) external returns (uint256 tokensMinted, uint256 shortTokensMinted);

    function liquidateRequest(uint256 requestId) external returns (uint256 findersFeeAmount);

    function setPlatform(IPlatform newPlatform) external;
    function setFeesCalculator(IFeesCalculator newFeesCalculator) external;
    function setFeesCollector(IFeesCollector newCollector) external;
    function setRequestFeesCalculator(IRequestFeesCalculator newRequestFeesCalculator) external;
    function setCVIOracle(ICVIOracle newCVIOracle) external;
    function setMinDeviation(uint16 newMinDeviationPercentage) external;
    function setRebaseLag(uint8 newRebaseLag) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IRewardsCollector {
	function reward(address account, uint256 positionUnits, uint8 leverage) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./IVolatilityToken.sol";

interface IRequestFeesCalculator {
    function calculateTimePenaltyFee(IVolatilityToken.Request calldata request) external view returns (uint16 feePercentage);
    function calculateTimeDelayFee(uint256 timeDelay) external view returns (uint16 feePercentage);
    function calculateFindersFee(uint256 tokensLeftAmount) external view returns (uint256 findersFeeAmount);

    function isLiquidable(IVolatilityToken.Request calldata request) external view returns (bool liquidable);

    function setTimeWindow(uint32 minTimeWindow, uint32 maxTimeWindow) external;
    function setTimeDelayFeesParameters(uint16 minTimeDelayFeePercent, uint16 maxTimeDelayFeePercent) external;
    function setMinWaitTime(uint32 minWaitTime) external;
    function setTimePenaltyFeeParameters(uint16 beforeTargetTimeMaxPenaltyFeePercent, uint32 afterTargetMidTime, uint16 afterTargetMidTimePenaltyFeePercent, uint32 afterTargetMaxTime, uint16 afterTargetMaxTimePenaltyFeePercent) external;
    function setFindersFee(uint16 findersFeePercent) external;

    function getMaxFees() external view returns (uint16 maxFeesPercent);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./ICVIOracle.sol";
import "./IFeesCalculator.sol";
import "./IRewardsCollector.sol";
import "./IFeesCollector.sol";
import "./ILiquidation.sol";

interface IPlatform {

    struct Position {
        uint168 positionUnitsAmount;
        uint8 leverage;
        uint16 openCVIValue;
        uint32 creationTimestamp;
        uint32 originalCreationTimestamp;
    }

    event Deposit(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event Withdraw(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event OpenPosition(address indexed account, uint256 tokenAmount, uint8 leverage, uint256 feeAmount, uint256 positionUnitsAmount, uint256 cviValue);
    event ClosePosition(address indexed account, uint256 tokenAmount, uint256 feeAmount, uint256 positionUnitsAmount, uint8 leverage, uint256 cviValue);
    event LiquidatePosition(address indexed positionAddress, uint256 currentPositionBalance, bool isBalancePositive, uint256 positionUnitsAmount);

    function deposit(uint256 tokenAmount, uint256 minLPTokenAmount) external returns (uint256 lpTokenAmount);
    function withdraw(uint256 tokenAmount, uint256 maxLPTokenBurnAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);
    function withdrawLPTokens(uint256 lpTokenAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);

    function increaseSharedPool(uint256 tokenAmount) external;

    function openPositionWithoutPremiumFee(uint168 tokenAmount, uint16 maxCVI, uint8 leverage) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount);
    function openPosition(uint168 tokenAmount, uint16 maxCVI, uint16 maxBuyingPremiumFeePercentage, uint8 leverage) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount);
    function closePosition(uint168 positionUnitsAmount, uint16 minCVI) external returns (uint256 tokenAmount);

    function liquidatePositions(address[] calldata positionOwners) external returns (uint256 finderFeeAmount);
    function getLiquidableAddresses(address[] calldata positionOwners) external view returns (address[] memory);

    function setAddressSpecificParameters(address holderAddress, bool shouldLockPosition, bool noPremiumFeeAllowed, bool increaseSharedPoolAllowed) external;

    function setRevertLockedTransfers(bool revertLockedTransfers) external;

    function setSubContracts(IFeesCollector newCollector, ICVIOracle newOracle, IRewardsCollector newRewards, ILiquidation newLiquidation, address _newStakingContractAddress) external;
    function setFeesCalculator(IFeesCalculator newCalculator) external;

    function setLatestOracleRoundId(uint80 newOracleRoundId) external;
    function setMaxTimeAllowedAfterLatestRound(uint32 newMaxTimeAllowedAfterLatestRound) external;

    function setLockupPeriods(uint256 newLPLockupPeriod, uint256 newBuyersLockupPeriod) external;

    function setEmergencyParameters(bool newEmergencyWithdrawAllowed, bool newCanPurgeSnapshots) external;

    function setMaxAllowedLeverage(uint8 newMaxAllowedLeverage) external;

    function calculatePositionBalance(address positionAddress) external view returns (uint256 currentPositionBalance, bool isPositive, uint168 positionUnitsAmount, uint8 leverage, uint256 fundingFees, uint256 marginDebt);
    function calculatePositionPendingFees(address positionAddress, uint168 positionUnitsAmount) external view returns (uint256 pendingFees);

    function totalBalance() external view returns (uint256 balance);
    function totalBalanceWithAddendum() external view returns (uint256 balance);

    function calculateLatestTurbulenceIndicatorPercent() external view returns (uint16);

    function positions(address positionAddress) external view returns (uint168 positionUnitsAmount, uint8 leverage, uint16 openCVIValue, uint32 creationTimestamp, uint32 originalCreationTimestamp);
    function buyersLockupPeriod() external view returns (uint256);
    function maxCVIValue() external view returns (uint16);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ILiquidation {	
	function setMinLiquidationThresholdPercents(uint16[8] calldata newMinThresholdPercents) external;
	function setMinLiquidationRewardPercent(uint16 newMinRewardPercent) external;
	function setMaxLiquidationRewardPercents(uint16[8] calldata newMaxRewardPercents) external;
	function isLiquidationCandidate(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint16 openCVIValue, uint8 leverage) external view returns (bool);
	function getLiquidationReward(uint256 positionBalance, bool isPositive, uint168 positionUnitsAmount, uint16 openCVIValue, uint8 leverage) external view returns (uint256 finderFeeAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeesCollector {
    function sendProfit(uint256 amount, IERC20 token) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./ICVIOracle.sol";

interface IFeesCalculator {

    struct CVIValue {
        uint256 period;
        uint16 cviValue;
    }

    struct SnapshotUpdate {
        uint256 latestSnapshot;
        uint256 singleUnitFundingFee;
        uint256 totalTime;
        uint256 totalRounds;
        uint256 cviValueTimestamp;
        uint80 newLatestRoundId;
        uint16 cviValue;
        bool updatedSnapshot;
        bool updatedLatestRoundId;
        bool updatedLatestTimestamp;
        bool updatedTurbulenceData;
    }

    function updateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint16 lastCVIValue, uint16 currCVIValue) external returns (uint16 _updateTurbulenceIndicatorPercent);

    function setOracle(ICVIOracle cviOracle) external;

    function setTurbulenceUpdator(address newUpdator) external;

    function setDepositFee(uint16 newDepositFeePercentage) external;
    function setWithdrawFee(uint16 newWithdrawFeePercentage) external;
    function setOpenPositionFee(uint16 newOpenPositionFeePercentage) external;
    function setOpenPositionLPFee(uint16 newOpenPositionLPFeePercent) external;
    function setClosePositionFee(uint16 newClosePositionFeePercentage) external;
    function setClosePositionMaxFee(uint16 newClosePositionMaxFeePercentage) external;
    function setClosePositionFeeDecay(uint256 newClosePositionFeeDecayPeriod) external;
    
    function setOracleHeartbeatPeriod(uint256 newOracleHeartbeatPeriod) external;
    function setBuyingPremiumFeeMax(uint16 newBuyingPremiumFeeMaxPercentage) external;
    function setBuyingPremiumThreshold(uint16 newBuyingPremiumThreshold) external;
    function setCollateralToBuyingPremiumMapping(uint16[] calldata newCollateralToBuyingPremiumMapping) external;
    function setFundingFeeConstantRate(uint16 newfundingFeeConstantRate) external;
    function setTurbulenceStep(uint16 newTurbulenceStepPercentage) external;
    function setMaxTurbulenceFeePercentToTrim(uint16 newMaxTurbulenceFeePercentToTrim) external;
    function setTurbulenceDeviationThresholdPercent(uint16 newTurbulenceDeviationThresholdPercent) external;
    function setTurbulenceDeviationPercent(uint16 newTurbulenceDeviationPercentage) external;

    function calculateTurbulenceIndicatorPercent(uint256 totalHeartbeats, uint256 newRounds, uint16 _lastCVIValue, uint16 _currCVIValue) external view returns (uint16);

    function calculateBuyingPremiumFee(uint168 tokenAmount, uint8 leverage, uint256 collateralRatio, uint256 lastCollateralRatio) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);
    function calculateBuyingPremiumFeeWithTurbulence(uint168 tokenAmount, uint8 leverage, uint256 collateralRatio, uint256 lastCollateralRatio, uint16 _turbulenceIndicatorPercent) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);
    
    function calculateSingleUnitFundingFee(CVIValue[] memory cviValues) external view returns (uint256 fundingFee);
    function updateSnapshots(uint256 latestTimestamp, uint256 blockTimestampSnapshot, uint256 latestTimestampSnapshot, uint80 latestOracleRoundId) external view returns (SnapshotUpdate memory snapshotUpdate);

    function calculateClosePositionFeePercent(uint256 creationTimestamp, bool isNoLockPositionAddress) external view returns (uint16);
    function calculateWithdrawFeePercent(uint256 lastDepositTimestamp) external view returns (uint16);

    function depositFeePercent() external view returns (uint16);
    function withdrawFeePercent() external view returns (uint16);
    function openPositionFeePercent() external view returns (uint16);
    function closePositionFeePercent() external view returns (uint16);
    function openPositionLPFeePercent() external view returns (uint16);
    function buyingPremiumFeeMaxPercent() external view returns (uint16);

    function openPositionFees() external view returns (uint16 openPositionFeePercentResult, uint16 buyingPremiumFeeMaxPercentResult);

    function turbulenceIndicatorPercent() external view returns (uint16);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ICVIOracle {
    function getCVIRoundData(uint80 roundId) external view returns (uint16 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint16 cviValue, uint80 cviRoundId, uint256 cviTimestamp);

    function setDeviationCheck(bool newDeviationCheck) external;
    function setMaxDeviation(uint16 newMaxDeviation) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 100
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}