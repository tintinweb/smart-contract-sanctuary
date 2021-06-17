/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// File: contracts/interfaces/ILiquidationManager.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's liquidation manager interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface ILiquidationManager  {
	function setCircuitBreaker(bool _emergency) external returns (bool);
	function partialLiquidation(address payable delinquentBorrower, uint256 targetHandler, uint256 liquidateAmount, uint256 receiveHandler) external returns (uint256);
	function checkLiquidation(address payable userAddr) external view returns (bool);
}

// File: contracts/SafeMath.sol
pragma solidity ^0.6.12;

// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
// Subject to the MIT license.

/**
 * @title BiFi's safe-math Contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
library SafeMath {
  uint256 internal constant unifiedPoint = 10 ** 18;
	/******************** Safe Math********************/
	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		require(c >= a, "a");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _sub(a, b, "s");
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mul(a, b);
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(a, b, "d");
	}

	function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b <= a, errorMessage);
		return a - b;
	}

	function _mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		if (a == 0)
		{
			return 0;
		}

		uint256 c = a* b;
		require((c / a) == b, "m");
		return c;
	}

	function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b > 0, errorMessage);
		return a / b;
	}

	function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, unifiedPoint), b, "d");
	}

	function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, b), unifiedPoint, "m");
	}
}

// File: contracts/interfaces/IManagerDataStorage.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's manager data storage interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IManagerDataStorage  {
	function getGlobalRewardPerBlock() external view returns (uint256);
	function setGlobalRewardPerBlock(uint256 _globalRewardPerBlock) external returns (bool);

	function getGlobalRewardDecrement() external view returns (uint256);
	function setGlobalRewardDecrement(uint256 _globalRewardDecrement) external returns (bool);

	function getGlobalRewardTotalAmount() external view returns (uint256);
	function setGlobalRewardTotalAmount(uint256 _globalRewardTotalAmount) external returns (bool);

	function getAlphaRate() external view returns (uint256);
	function setAlphaRate(uint256 _alphaRate) external returns (bool);

	function getAlphaLastUpdated() external view returns (uint256);
	function setAlphaLastUpdated(uint256 _alphaLastUpdated) external returns (bool);

	function getRewardParamUpdateRewardPerBlock() external view returns (uint256);
	function setRewardParamUpdateRewardPerBlock(uint256 _rewardParamUpdateRewardPerBlock) external returns (bool);

	function getRewardParamUpdated() external view returns (uint256);
	function setRewardParamUpdated(uint256 _rewardParamUpdated) external returns (bool);

	function getInterestUpdateRewardPerblock() external view returns (uint256);
	function setInterestUpdateRewardPerblock(uint256 _interestUpdateRewardPerblock) external returns (bool);

	function getInterestRewardUpdated() external view returns (uint256);
	function setInterestRewardUpdated(uint256 _interestRewardLastUpdated) external returns (bool);

	function setTokenHandler(uint256 handlerID, address handlerAddr) external returns (bool);

	function getTokenHandlerInfo(uint256 handlerID) external view returns (bool, address);

	function getTokenHandlerID(uint256 index) external view returns (uint256);

	function getTokenHandlerAddr(uint256 handlerID) external view returns (address);
	function setTokenHandlerAddr(uint256 handlerID, address handlerAddr) external returns (bool);

	function getTokenHandlerExist(uint256 handlerID) external view returns (bool);
	function setTokenHandlerExist(uint256 handlerID, bool exist) external returns (bool);

	function getTokenHandlerSupport(uint256 handlerID) external view returns (bool);
	function setTokenHandlerSupport(uint256 handlerID, bool support) external returns (bool);

	function setLiquidationManagerAddr(address _liquidationManagerAddr) external returns (bool);
	function getLiquidationManagerAddr() external view returns (address);

	function setManagerAddr(address _managerAddr) external returns (bool);
}

// File: contracts/interfaces/IOracleProxy.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's oracle proxy interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IOracleProxy  {
	function getTokenPrice(uint256 tokenID) external view returns (uint256);

	function getOracleFeed(uint256 tokenID) external view returns (address, uint256);
	function setOracleFeed(uint256 tokenID, address feedAddr, uint256 decimals, bool needPriceConvert, uint256 priceConvertID) external returns (bool);
}

// File: contracts/interfaces/IERC20.sol
// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
pragma solidity 0.6.12;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external ;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IObserver.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's Observer interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IObserver {
    function getAlphaBaseAsset() external view returns (uint256[] memory);
    function setChainGlobalRewardPerblock(uint256 _idx, uint256 globalRewardPerBlocks) external returns (bool);
    function updateChainMarketInfo(uint256 _idx, uint256 chainDeposit, uint256 chainBorrow) external returns (bool);
}

// File: contracts/interfaces/IProxy.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's proxy interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IProxy  {
	function handlerProxy(bytes memory data) external returns (bool, bytes memory);
	function handlerViewProxy(bytes memory data) external view returns (bool, bytes memory);
	function siProxy(bytes memory data) external returns (bool, bytes memory);
	function siViewProxy(bytes memory data) external view returns (bool, bytes memory);
}

// File: contracts/interfaces/IMarketHandler.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's market handler interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IMarketHandler  {
	function setCircuitBreaker(bool _emergency) external returns (bool);
	function setCircuitBreakWithOwner(bool _emergency) external returns (bool);

	function getTokenName() external view returns (string memory);

	function ownershipTransfer(address payable newOwner) external returns (bool);

	function deposit(uint256 unifiedTokenAmount, bool allFlag) external payable returns (bool);
	function withdraw(uint256 unifiedTokenAmount, bool allFlag) external returns (bool);
	function borrow(uint256 unifiedTokenAmount, bool allFlag) external returns (bool);
	function repay(uint256 unifiedTokenAmount, bool allFlag) external payable returns (bool);

	function executeFlashloan(
		address receiverAddress,
		uint256 amount
  ) external returns (bool);

	function depositFlashloanFee(
		uint256 amount
	) external returns (bool);

  function convertUnifiedToUnderlying(uint256 unifiedTokenAmount) external view returns (uint256);
	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 rewardHandlerID) external returns (uint256, uint256, uint256);
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 liquidationAmountWithReward, address payable liquidator) external returns (uint256);

	function getTokenHandlerLimit() external view returns (uint256, uint256);
  function getTokenHandlerBorrowLimit() external view returns (uint256);
	function getTokenHandlerMarginCallLimit() external view returns (uint256);
	function setTokenHandlerBorrowLimit(uint256 borrowLimit) external returns (bool);
	function setTokenHandlerMarginCallLimit(uint256 marginCallLimit) external returns (bool);

  function getTokenLiquidityAmountWithInterest(address payable userAddr) external view returns (uint256);

	function getUserAmountWithInterest(address payable userAddr) external view returns (uint256, uint256);
	function getUserAmount(address payable userAddr) external view returns (uint256, uint256);

	function getUserMaxBorrowAmount(address payable userAddr) external view returns (uint256);
	function getUserMaxWithdrawAmount(address payable userAddr) external view returns (uint256);
	function getUserMaxRepayAmount(address payable userAddr) external view returns (uint256);

	function checkFirstAction() external returns (bool);
	function applyInterest(address payable userAddr) external returns (uint256, uint256);

	function reserveDeposit(uint256 unifiedTokenAmount) external payable returns (bool);
	function reserveWithdraw(uint256 unifiedTokenAmount) external returns (bool);

	function withdrawFlashloanFee(uint256 unifiedTokenAmount) external returns (bool);

	function getDepositTotalAmount() external view returns (uint256);
	function getBorrowTotalAmount() external view returns (uint256);

	function getSIRandBIR() external view returns (uint256, uint256);

  function getERC20Addr() external view returns (address);
}

// File: contracts/interfaces/IServiceIncentive.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's si interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IServiceIncentive  {
	function setCircuitBreakWithOwner(bool emergency) external returns (bool);
	function setCircuitBreaker(bool emergency) external returns (bool);

	function updateRewardPerBlockLogic(uint256 _rewardPerBlock) external returns (bool);
	function updateRewardLane(address payable userAddr) external returns (bool);

	function getBetaRateBaseTotalAmount() external view returns (uint256);
	function getBetaRateBaseUserAmount(address payable userAddr) external view returns (uint256);

	function getMarketRewardInfo() external view returns (uint256, uint256, uint256);

	function getUserRewardInfo(address payable userAddr) external view returns (uint256, uint256, uint256);

	function claimRewardAmountUser(address payable userAddr) external returns (uint256);
}

// File: contracts/Errors.sol
pragma solidity 0.6.12;

contract Modifier {
    string internal constant ONLY_OWNER = "O";
    string internal constant ONLY_MANAGER = "M";
    string internal constant CIRCUIT_BREAKER = "emergency";
}

contract ManagerModifier is Modifier {
    string internal constant ONLY_HANDLER = "H";
    string internal constant ONLY_LIQUIDATION_MANAGER = "LM";
    string internal constant ONLY_BREAKER = "B";
}

contract HandlerDataStorageModifier is Modifier {
    string internal constant ONLY_BIFI_CONTRACT = "BF";
}

contract SIDataStorageModifier is Modifier {
    string internal constant ONLY_SI_HANDLER = "SI";
}

contract HandlerErrors is Modifier {
    string internal constant USE_VAULE = "use value";
    string internal constant USE_ARG = "use arg";
    string internal constant EXCEED_LIMIT = "exceed limit";
    string internal constant NO_LIQUIDATION = "no liquidation";
    string internal constant NO_LIQUIDATION_REWARD = "no enough reward";
    string internal constant NO_EFFECTIVE_BALANCE = "not enough balance";
    string internal constant TRANSFER = "err transfer";
}

contract SIErrors is Modifier { }

contract InterestErrors is Modifier { }

contract LiquidationManagerErrors is Modifier {
    string internal constant NO_DELINQUENT = "not delinquent";
}

contract ManagerErrors is ManagerModifier {
    string internal constant REWARD_TRANSFER = "RT";
    string internal constant UNSUPPORTED_TOKEN = "UT";
}

contract OracleProxyErrors is Modifier {
    string internal constant ZERO_PRICE = "price zero";
}

contract RequestProxyErrors is Modifier { }

contract ManagerDataStorageErrors is ManagerModifier {
    string internal constant NULL_ADDRESS = "err addr null";
}

// File: contracts/marketManager/ManagerSlot.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's Slot contract
 * @notice Manager Slot Definitions & Allocations
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract ManagerSlot is ManagerErrors {
	using SafeMath for uint256;

	address public owner;
	mapping(address => bool) operators;
	mapping(address => Breaker) internal breakerTable;

	bool public emergency = false;

	IManagerDataStorage internal dataStorageInstance;
	IOracleProxy internal oracleProxy;

	/* feat: manager reward token instance*/
	IERC20 internal rewardErc20Instance;

	IObserver public Observer;

	address public slotSetterAddr;
	address public handlerManagerAddr;
	address public flashloanAddr;

  // BiFi-X
  address public positionStorageAddr;
  address public nftAddr;

	uint256 public tokenHandlerLength;

  struct FeeRateParams {
    uint256 unifiedPoint;
    uint256 minimum;
    uint256 slope;
    uint256 discountRate;
  }

  struct HandlerFlashloan {
      uint256 flashFeeRate;
      uint256 discountBase;
      uint256 feeTotal;
  }

  mapping(uint256 => HandlerFlashloan) public handlerFlashloan;

	struct UserAssetsInfo {
		uint256 depositAssetSum;
		uint256 borrowAssetSum;
		uint256 marginCallLimitSum;
		uint256 depositAssetBorrowLimitSum;
		uint256 depositAsset;
		uint256 borrowAsset;
		uint256 price;
		uint256 callerPrice;
		uint256 depositAmount;
		uint256 borrowAmount;
		uint256 borrowLimit;
		uint256 marginCallLimit;
		uint256 callerBorrowLimit;
		uint256 userBorrowableAsset;
		uint256 withdrawableAsset;
	}

	struct Breaker {
		bool auth;
		bool tried;
	}

	struct ContractInfo {
		bool support;
		address addr;
    address tokenAddr;

    uint256 expectedBalance;
    uint256 afterBalance;

		IProxy tokenHandler;
		bytes data;

		IMarketHandler handlerFunction;
		IServiceIncentive siFunction;

		IOracleProxy oracleProxy;
		IManagerDataStorage managerDataStorage;
	}

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlyHandler(uint256 handlerID) {
		_isHandler(handlerID);
		_;
	}

	modifier onlyOperators {
		address payable sender = msg.sender;
		require(operators[sender] || sender == owner);
		_;
	}

	function _isHandler(uint256 handlerID) internal view {
		address msgSender = msg.sender;
		require((msgSender == dataStorageInstance.getTokenHandlerAddr(handlerID)) || (msgSender == owner), ONLY_HANDLER);
	}

	modifier onlyLiquidationManager {
		_isLiquidationManager();
		_;
	}

	function _isLiquidationManager() internal view {
		address msgSender = msg.sender;
		require((msgSender == dataStorageInstance.getLiquidationManagerAddr()) || (msgSender == owner), ONLY_LIQUIDATION_MANAGER);
	}

	modifier circuitBreaker {
		_isCircuitBreak();
		_;
	}

	function _isCircuitBreak() internal view {
		require((!emergency) || (msg.sender == owner), CIRCUIT_BREAKER);
	}

	modifier onlyBreaker {
		_isBreaker();
		_;
	}

	function _isBreaker() internal view {
		require(breakerTable[msg.sender].auth, ONLY_BREAKER);
	}
}

// File: contracts/context/BlockContext.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's BlockContext contract
 * @notice BiFi getter Contract for Block Context Information
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract BlockContext {
    function _blockContext() internal view returns(uint256 context) {
        // block number chain
        // context = block.number;

        // block timestamp chain
        context = block.timestamp;
    }
}

// File: contracts/marketManager/HandlerManager.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title BiFi's HandlerManager contract
 * @notice BiFi Market Manager Business Logics(Interest, Incentive)
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract HandlerManager is ManagerSlot, BlockContext {

	event HandlerRewardUpdate(uint256 handlerID, uint256 alphaBaseAsset, uint256 rewardPerBlocks);
	event ChainRewardUpdate(uint256 chainID, uint256 alphaBaseAsset, uint256 rewardPerBlocks);

  /**
	* @dev Update interest of a user for a handler (internal)
	* @param userAddr The user address
	* @param callerID The handler ID
	* @param allFlag Flag for the full calculation mode (calculting for all handlers)
	* @return (uint256, uint256, uint256, uint256, uint256, uint256)
	*/
	function applyInterestHandlers(address payable userAddr, uint256 callerID, bool allFlag) external returns (uint256, uint256, uint256, uint256, uint256, uint256)
	{
		UserAssetsInfo memory userAssetsInfo;
		ContractInfo memory handlerInfo;
		handlerInfo.oracleProxy = oracleProxy;
		handlerInfo.managerDataStorage = dataStorageInstance;

		/* From all handlers, get the token price, margin call limit, borrow limit */
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			(handlerInfo.support, handlerInfo.addr) = handlerInfo.managerDataStorage.getTokenHandlerInfo(handlerID);
			if (handlerInfo.support)
			{
				handlerInfo.tokenHandler = IProxy(handlerInfo.addr);

				/* If the full-calculation mode is not set, work on the given handler only */
				if ((handlerID == callerID) || allFlag)
				{
					handlerInfo.tokenHandler.siProxy(
						abi.encodeWithSelector(
							handlerInfo.siFunction
							.updateRewardLane.selector,
							userAddr
						)
					);
					(, handlerInfo.data) = handlerInfo.tokenHandler.handlerProxy(
						abi.encodeWithSelector(
							handlerInfo.handlerFunction
							.applyInterest.selector,
							userAddr
						)
					);

					(userAssetsInfo.depositAmount, userAssetsInfo.borrowAmount) = abi.decode(handlerInfo.data, (uint256, uint256));
				}
				else
				{
					/* Get the deposit and borrow amount for the user */
					(, handlerInfo.data) = handlerInfo.tokenHandler.handlerViewProxy(
						abi.encodeWithSelector(
							handlerInfo.handlerFunction
							.getUserAmount.selector,
							userAddr
						)
					);
					(userAssetsInfo.depositAmount, userAssetsInfo.borrowAmount) = abi.decode(handlerInfo.data, (uint256, uint256));
				}

				(, handlerInfo.data) = handlerInfo.tokenHandler.handlerViewProxy(
					abi.encodeWithSelector(
						handlerInfo.handlerFunction
						.getTokenHandlerLimit.selector
					)
				);
				(userAssetsInfo.borrowLimit, userAssetsInfo.marginCallLimit) = abi.decode(handlerInfo.data, (uint256, uint256));

				/* Get the token price */
				if (handlerID == callerID)
				{
					userAssetsInfo.price = handlerInfo.oracleProxy.getTokenPrice(handlerID);
					userAssetsInfo.callerPrice = userAssetsInfo.price;
					userAssetsInfo.callerBorrowLimit = userAssetsInfo.borrowLimit;
				}

				/* If the user has no balance, the token handler can be ignored.*/
				if ((userAssetsInfo.depositAmount > 0) || (userAssetsInfo.borrowAmount > 0))
				{
					if (handlerID != callerID)
					{
						userAssetsInfo.price = handlerInfo.oracleProxy.getTokenPrice(handlerID);
					}

					/* Compute the deposit parameters */
					if (userAssetsInfo.depositAmount > 0)
					{
						userAssetsInfo.depositAsset = userAssetsInfo.depositAmount.unifiedMul(userAssetsInfo.price);
						userAssetsInfo.depositAssetBorrowLimitSum = userAssetsInfo.depositAssetBorrowLimitSum.add(userAssetsInfo.depositAsset.unifiedMul(userAssetsInfo.borrowLimit));
						userAssetsInfo.marginCallLimitSum = userAssetsInfo.marginCallLimitSum.add(userAssetsInfo.depositAsset.unifiedMul(userAssetsInfo.marginCallLimit));
						userAssetsInfo.depositAssetSum = userAssetsInfo.depositAssetSum.add(userAssetsInfo.depositAsset);
					}

					/* Compute the borrow parameters */
					if (userAssetsInfo.borrowAmount > 0)
					{
						userAssetsInfo.borrowAsset = userAssetsInfo.borrowAmount.unifiedMul(userAssetsInfo.price);
						userAssetsInfo.borrowAssetSum = userAssetsInfo.borrowAssetSum.add(userAssetsInfo.borrowAsset);
					}
				}
			}
		}

		if (userAssetsInfo.depositAssetBorrowLimitSum > userAssetsInfo.borrowAssetSum)
		{
			/* Set the amount that the user can borrow from the borrow limit and previous borrows. */
			userAssetsInfo.userBorrowableAsset = userAssetsInfo.depositAssetBorrowLimitSum.sub(userAssetsInfo.borrowAssetSum);

			/* Set the allowed amount that the user can withdraw based on the user borrow */
			userAssetsInfo.withdrawableAsset = userAssetsInfo.depositAssetBorrowLimitSum.sub(userAssetsInfo.borrowAssetSum).unifiedDiv(userAssetsInfo.callerBorrowLimit);
		}

		/* Return the calculated parameters */
		return (userAssetsInfo.userBorrowableAsset.unifiedDiv(userAssetsInfo.callerPrice), userAssetsInfo.withdrawableAsset.unifiedDiv(userAssetsInfo.callerPrice), userAssetsInfo.marginCallLimitSum, userAssetsInfo.depositAssetSum, userAssetsInfo.borrowAssetSum, userAssetsInfo.callerPrice);
	}

	/**
	* @dev Reward the user (msg.sender) with the reward token after calculating interest.
	* @return true (TODO: validate results)
	*/
	function interestUpdateReward() external returns (bool)
	{
		uint256 thisBlock = _blockContext();
		uint256 interestRewardUpdated = dataStorageInstance.getInterestRewardUpdated();
		uint256 delta = thisBlock - interestRewardUpdated;
		if (delta == 0)
		{
			return false;
		}

		dataStorageInstance.setInterestRewardUpdated(thisBlock);
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			IProxy tokenHandler = IProxy(dataStorageInstance.getTokenHandlerAddr(handlerID));
			bytes memory data;
			(, data) = tokenHandler.handlerProxy(
				abi.encodeWithSelector(
					IMarketHandler
					.checkFirstAction.selector
				)
			);
		}

		/* transfer reward tokens */
		return _rewardTransfer(msg.sender, delta.mul(dataStorageInstance.getInterestUpdateRewardPerblock()));
	}

 /**
	* @dev (Update operation) update the rewards parameters.
	* @param userAddr The address of operator
	* @return Whether or not the operation succeed
	*/
	function updateRewardParams(address payable userAddr) onlyOperators external returns (bool)
	{
		if (_determineRewardParams(userAddr))
		{
			return _calcRewardParams(userAddr);
		}

		return false;
	}

  /**
	* @dev (Update operation) update the rewards parameters (by using alpha- and beta-score).
	* @param userAddr The address of the operator
	* @return Whether or not this process succeed
	*/
	function _determineRewardParams(address payable userAddr) internal returns (bool)
	{
		uint256 thisBlockNum = _blockContext();
		IManagerDataStorage _dataStorage = dataStorageInstance;
		/* The inactive period (delta) since the last action happens */
		uint256 delta = thisBlockNum - _dataStorage.getRewardParamUpdated();
		_dataStorage.setRewardParamUpdated(thisBlockNum);
		if (delta == 0)
		{
			return false;
		}

		/* Rewards assigned for a block */
		uint256 globalRewardPerBlock = _dataStorage.getGlobalRewardPerBlock();
		/* Rewards decrement for a block. (Rewards per block monotonically decreases) */
		uint256 globalRewardDecrement = _dataStorage.getGlobalRewardDecrement();
		/* Total amount of rewards */
		uint256 globalRewardTotalAmount = _dataStorage.getGlobalRewardTotalAmount();

		/* Remaining periods for reward distribution */
		uint256 remainingPeriod = globalRewardPerBlock.unifiedDiv(globalRewardDecrement);

		if (remainingPeriod >= delta.mul(SafeMath.unifiedPoint))
		{
			remainingPeriod = remainingPeriod.sub(delta.mul(SafeMath.unifiedPoint));
		}
		else
		{
			return _epilogueOfDetermineRewardParams(_dataStorage, userAddr, delta, 0, globalRewardDecrement, 0);
		}

		if (globalRewardTotalAmount >= globalRewardPerBlock.mul(delta))
		{
			globalRewardTotalAmount = globalRewardTotalAmount - globalRewardPerBlock.mul(delta);
		}
		else
		{
			return _epilogueOfDetermineRewardParams(_dataStorage, userAddr, delta, 0, globalRewardDecrement, 0);
		}

		globalRewardPerBlock = globalRewardTotalAmount.mul(2).unifiedDiv(remainingPeriod.add(SafeMath.unifiedPoint));
		/* To incentivze the update operation, the operator get paid with the
		reward token */
		return _epilogueOfDetermineRewardParams(_dataStorage, userAddr, delta, globalRewardPerBlock, globalRewardDecrement, globalRewardTotalAmount);
	}

  /**
	* @dev Update rewards paramters of token handlers.
	* @param userAddr The address of operator
	* @return true
	*/
	function _calcRewardParams(address payable userAddr) internal returns (bool)
	{
		uint256 handlerLength = tokenHandlerLength;
		bytes memory data;
		uint256[] memory handlerAlphaRateBaseAsset = new uint256[](handlerLength);
		uint256[] memory chainAlphaRateBaseAsset;
		uint256 handlerID;
		uint256 alphaRateBaseGlobalAssetSum;
		for (handlerID; handlerID < handlerLength; handlerID++)
		{
			handlerAlphaRateBaseAsset[handlerID] = _getAlphaBaseAsset(handlerID);
			alphaRateBaseGlobalAssetSum = alphaRateBaseGlobalAssetSum.add(handlerAlphaRateBaseAsset[handlerID]);
		}

		chainAlphaRateBaseAsset = Observer.getAlphaBaseAsset();
		handlerID = 0;
		for (;handlerID < chainAlphaRateBaseAsset.length; handlerID++) {
			alphaRateBaseGlobalAssetSum = alphaRateBaseGlobalAssetSum.add(chainAlphaRateBaseAsset[handlerID]);
		}

		handlerID = 0;
		uint256 globalRewardPerBlocks = dataStorageInstance.getGlobalRewardPerBlock();

		for (handlerID; handlerID < handlerLength; handlerID++)
		{
			IProxy tokenHandler = IProxy(dataStorageInstance.getTokenHandlerAddr(handlerID));
			(, data) = tokenHandler.siProxy(
				abi.encodeWithSelector(
					IServiceIncentive
					.updateRewardLane.selector,
					userAddr
				)
			);

			/* Update reward parameter for the token handler */
			uint256 rewardPerBlocks = globalRewardPerBlocks
								.unifiedMul(
								handlerAlphaRateBaseAsset[handlerID]
								.unifiedDiv(alphaRateBaseGlobalAssetSum)
								);
			data = abi.encodeWithSelector(
				IServiceIncentive.updateRewardPerBlockLogic.selector,
				rewardPerBlocks
			);
			(, data) = tokenHandler.siProxy(data);

			emit HandlerRewardUpdate(handlerID, handlerAlphaRateBaseAsset[handlerID], rewardPerBlocks);
		}

		handlerID = 0;
		for (;handlerID < chainAlphaRateBaseAsset.length; handlerID++) {
			uint256 rewardPerBlocks = chainAlphaRateBaseAsset[handlerID]
										.unifiedDiv(alphaRateBaseGlobalAssetSum)
										.unifiedMul(globalRewardPerBlocks);

			Observer.setChainGlobalRewardPerblock(
				handlerID,
				rewardPerBlocks
			);
			emit ChainRewardUpdate(handlerID, chainAlphaRateBaseAsset[handlerID], rewardPerBlocks);
		}

		return true;
	}

  /**
	* @dev Epilogue of _determineRewardParams for code-size savings
	* @param _dataStorage interface of Manager Data Storage
	* @param userAddr User Address for Reward token transfer
	* @param _delta The inactive period (delta) since the last action happens
	* @param _globalRewardPerBlock Reward per block
	* @param _globalRewardDecrement Rewards decrement for a block
	* @param _globalRewardTotalAmount Total amount of rewards
	* @return true
	*/
	function _epilogueOfDetermineRewardParams(
		IManagerDataStorage _dataStorage,
		address payable userAddr,
		uint256 _delta,
		uint256 _globalRewardPerBlock,
		uint256 _globalRewardDecrement,
		uint256 _globalRewardTotalAmount
	) internal returns (bool) {
		// Set the reward model parameters
		_dataStorage.setGlobalRewardPerBlock(_globalRewardPerBlock);
		_dataStorage.setGlobalRewardDecrement(_globalRewardDecrement);
		_dataStorage.setGlobalRewardTotalAmount(_globalRewardTotalAmount);

		uint256 rewardAmount = _delta.mul(_dataStorage.getRewardParamUpdateRewardPerBlock());
		/* To incentivze the update operation, the operator get paid with the
		reward token */
		_rewardTransfer(userAddr, rewardAmount);
		return true;
	}

  /**
	* @dev Calculate the alpha-score for the handler (in USD price)
	* @param _handlerID The handler ID
	* @return The alpha-score of the handler
	*/
	function _getAlphaBaseAsset(uint256 _handlerID) internal view returns (uint256)
	{
		bytes memory data;
		IProxy tokenHandler = IProxy(dataStorageInstance.getTokenHandlerAddr(_handlerID));

    	// TODO merge call
		(, data) = tokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				IMarketHandler
				.getDepositTotalAmount.selector
			)
		);
		uint256 _depositAmount = abi.decode(data, (uint256));

		(, data) = tokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				IMarketHandler
				.getBorrowTotalAmount.selector
			)
		);
		uint256 _borrowAmount = abi.decode(data, (uint256));

		return _calcAlphaBaseAmount(
              dataStorageInstance.getAlphaRate(),
              _depositAmount,
              _borrowAmount
            )
            .unifiedMul(_getTokenHandlerPrice(_handlerID));
	}

	/**
	* @dev Calculate the alpha-score for the handler (in token amount)
	* @param _alpha The alpha parameter
	* @param _depositAmount The total amount of deposit
	* @param _borrowAmount The total amount of borrow
	* @return The alpha-score of the handler (in token amount)
	*/
	function _calcAlphaBaseAmount(uint256 _alpha, uint256 _depositAmount, uint256 _borrowAmount) internal pure returns (uint256)
	{
		return _depositAmount.unifiedMul(_alpha).add(_borrowAmount.unifiedMul(SafeMath.unifiedPoint.sub(_alpha)));
	}

  /**
	* @dev Get the token price for the handler
	* @param handlerID The handler id
	* @return The token price of the handler
	*/
	function _getTokenHandlerPrice(uint256 handlerID) internal view returns (uint256)
	{
		return (oracleProxy.getTokenPrice(handlerID));
	}


	/**
	* @dev Claim all rewards for the user
	* @param userAddr The user address
	* @return true (TODO: validate results)
	*/
	function rewardClaimAll(address payable userAddr) external returns (uint256)
	{
		uint256 handlerID;
		uint256 claimAmountSum;
		for (handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			claimAmountSum = claimAmountSum.add(_claimHandlerRewardAmount(handlerID, userAddr));
		}
		require(_rewardTransfer(userAddr, claimAmountSum));
		return claimAmountSum;
	}


	function claimHandlerReward(uint256 handlerID, address payable userAddr) external returns (uint256) {
		uint256 amount = _claimHandlerRewardAmount(handlerID, userAddr);

		require(_rewardTransfer(userAddr, amount));

		return amount;
	}


	function _claimHandlerRewardAmount(uint256 handlerID, address payable userAddr) internal returns (uint256) {
		bytes memory data;

		IProxy tokenHandler = IProxy(dataStorageInstance.getTokenHandlerAddr(handlerID));
		tokenHandler.siProxy(
			abi.encodeWithSelector(
				IServiceIncentive
				.updateRewardLane.selector,
				userAddr
			)
		);

		/* Claim reward for a token handler */
		(, data) = tokenHandler.siProxy(
			abi.encodeWithSelector(
				IServiceIncentive.claimRewardAmountUser.selector,
				userAddr
			)
		);
		return abi.decode(data, (uint256));
	}

	/**
	* @dev Transfer reward tokens to owner (for administration)
	* @param _amount The amount of the reward token
	* @return true
	*/
	function ownerRewardTransfer(uint256 _amount) onlyOwner external returns (bool)
	{
		return _rewardTransfer(address(uint160(owner)), _amount);
	}

  /**
	* @dev Transfer reward tokens to a user
	* @param userAddr The address of recipient
	* @param _amount The amount of the reward token
	* @return true
	*/
	function _rewardTransfer(address payable userAddr, uint256 _amount) internal returns (bool)
	{
		IERC20 _rewardERC20 = rewardErc20Instance;

		if(address(_rewardERC20) != address(0x0)) {
			uint256 beforeBalance = _rewardERC20.balanceOf(userAddr);
			_rewardERC20.transfer(userAddr, _amount);
			require(_amount == _rewardERC20.balanceOf(userAddr).sub(beforeBalance), REWARD_TRANSFER);
			return true;
		}
	}
}