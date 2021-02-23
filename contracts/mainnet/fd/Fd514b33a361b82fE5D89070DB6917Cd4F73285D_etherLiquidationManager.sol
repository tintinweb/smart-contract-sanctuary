/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// File: contracts/interfaces/marketManagerInterface.sol

pragma solidity 0.6.12;

interface marketManagerInterface  {
	function setBreakerTable(address _target, bool _status) external returns (bool);

	function getCircuitBreaker() external view returns (bool);
	function setCircuitBreaker(bool _emergency) external returns (bool);

	function getTokenHandlerInfo(uint256 handlerID) external view returns (bool, address, string memory);

	function handlerRegister(uint256 handlerID, address tokenHandlerAddr) external returns (bool);

	function applyInterestHandlers(address payable userAddr, uint256 callerID, bool allFlag) external returns (uint256, uint256, uint256, uint256, uint256, uint256);

	function getTokenHandlerPrice(uint256 handlerID) external view returns (uint256);
	function getTokenHandlerBorrowLimit(uint256 handlerID) external view returns (uint256);
	function getTokenHandlerSupport(uint256 handlerID) external view returns (bool);

	function getTokenHandlersLength() external view returns (uint256);
	function setTokenHandlersLength(uint256 _tokenHandlerLength) external returns (bool);

	function getTokenHandlerID(uint256 index) external view returns (uint256);
	function getTokenHandlerMarginCallLimit(uint256 handlerID) external view returns (uint256);

	function getUserIntraHandlerAssetWithInterest(address payable userAddr, uint256 handlerID) external view returns (uint256, uint256);

	function getUserTotalIntraCreditAsset(address payable userAddr) external view returns (uint256, uint256);

	function getUserLimitIntraAsset(address payable userAddr) external view returns (uint256, uint256);

	function getUserCollateralizableAmount(address payable userAddr, uint256 handlerID) external view returns (uint256);

	function getUserExtraLiquidityAmount(address payable userAddr, uint256 handlerID) external view returns (uint256);
	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 liquidateHandlerID, uint256 rewardHandlerID) external returns (uint256, uint256, uint256);

	function getMaxLiquidationReward(address payable delinquentBorrower, uint256 liquidateHandlerID, uint256 liquidateAmount, uint256 rewardHandlerID, uint256 rewardRatio) external view returns (uint256);
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 rewardAmount, address payable liquidator, uint256 handlerID) external returns (uint256);

	function setLiquidationManager(address liquidationManagerAddr) external returns (bool);

	function rewardClaimAll(address payable userAddr) external returns (bool);

	function updateRewardParams(address payable userAddr) external returns (bool);
	function interestUpdateReward() external returns (bool);
	function getGlobalRewardInfo() external view returns (uint256, uint256, uint256);

	function setOracleProxy(address oracleProxyAddr) external returns (bool);

	function rewardUpdateOfInAction(address payable userAddr, uint256 callerID) external returns (bool);
	function ownerRewardTransfer(uint256 _amount) external returns (bool);
}

// File: contracts/interfaces/managerDataStorageInterface.sol

pragma solidity 0.6.12;

interface managerDataStorageInterface  {
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

// File: contracts/interfaces/marketHandlerInterface.sol

pragma solidity 0.6.12;

interface marketHandlerInterface  {
	function setCircuitBreaker(bool _emergency) external returns (bool);
	function setCircuitBreakWithOwner(bool _emergency) external returns (bool);

	function getTokenName() external view returns (string memory);

	function ownershipTransfer(address payable newOwner) external returns (bool);

	function deposit(uint256 unifiedTokenAmount, bool allFlag) external payable returns (bool);
	function withdraw(uint256 unifiedTokenAmount, bool allFlag) external returns (bool);
	function borrow(uint256 unifiedTokenAmount, bool allFlag) external returns (bool);
	function repay(uint256 unifiedTokenAmount, bool allFlag) external payable returns (bool);

	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 rewardHandlerID) external returns (uint256, uint256, uint256);
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 liquidationAmountWithReward, address payable liquidator) external returns (uint256);

	function getTokenHandlerLimit() external view returns (uint256, uint256);
    function getTokenHandlerBorrowLimit() external view returns (uint256);
	function getTokenHandlerMarginCallLimit() external view returns (uint256);
	function setTokenHandlerBorrowLimit(uint256 borrowLimit) external returns (bool);
	function setTokenHandlerMarginCallLimit(uint256 marginCallLimit) external returns (bool);

	function getUserAmountWithInterest(address payable userAddr) external view returns (uint256, uint256);
	function getUserAmount(address payable userAddr) external view returns (uint256, uint256);

	function getUserMaxBorrowAmount(address payable userAddr) external view returns (uint256);
	function getUserMaxWithdrawAmount(address payable userAddr) external view returns (uint256);
	function getUserMaxRepayAmount(address payable userAddr) external view returns (uint256);

	function checkFirstAction() external returns (bool);
	function applyInterest(address payable userAddr) external returns (uint256, uint256);

	function reserveDeposit(uint256 unifiedTokenAmount) external payable returns (bool);
	function reserveWithdraw(uint256 unifiedTokenAmount) external returns (bool);

	function getDepositTotalAmount() external view returns (uint256);
	function getBorrowTotalAmount() external view returns (uint256);

	function getSIRandBIR() external view returns (uint256, uint256);
}

// File: contracts/interfaces/liquidationManagerInterface.sol

pragma solidity 0.6.12;

interface liquidationManagerInterface  {
	function setCircuitBreaker(bool _emergency) external returns (bool);
	function partialLiquidation(address payable delinquentBorrower, uint256 targetHandler, uint256 liquidateAmount, uint256 receiveHandler) external returns (uint256);
	function checkLiquidation(address payable userAddr) external view returns (bool);
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

// File: contracts/marketManager/liquidationManager.sol

pragma solidity 0.6.12;

/**
 * @title BiFi Liquidation Manager Contract
 *
 * @author BiFi
 */
contract etherLiquidationManager is liquidationManagerInterface, LiquidationManagerErrors {
	event CircuitBreaked(bool breaked, uint256 blockNumber);

	address payable owner;

	bool emergency = false;

	uint256 constant unifiedPoint = 10 ** 18;

	marketManagerInterface public marketManager;

	struct LiquidationModel {
		uint256 delinquentDepositAsset;
		uint256 delinquentBorrowAsset;
		uint256 liquidatePrice;
		uint256 receivePrice;
		uint256 liquidateAmount;
		uint256 liquidateAsset;
		uint256 rewardAsset;
		uint256 rewardAmount;
	}

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlyManager {
		address msgSender = msg.sender;
		require((msgSender == address(marketManager)) || (msgSender == owner), ONLY_MANAGER);
		_;
	}

	modifier circuitBreaker {
		address msgSender = msg.sender;
		require((!emergency) || (msgSender == owner), CIRCUIT_BREAKER);
		_;
	}

	/**
	* @dev Construct a new liquidationManager
	* @param marketManagerAddr The address of marketManager contract
	*/
	constructor (address marketManagerAddr) public
	{
		owner = msg.sender;
		marketManager = marketManagerInterface(marketManagerAddr);
	}

	/**
	* @dev Set new market manager address
	* @param marketManagerAddr The address of marketManager contract
	* @return true (TODO: validate results)
	*/
	function setMarketManagerAddr(address marketManagerAddr) external onlyOwner returns (bool) {
		marketManager = marketManagerInterface(marketManagerAddr);
		return true;
	}

	/**
	* @dev Transfer ownership
	* @param _owner the address of the new owner
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address payable _owner) onlyOwner public returns (bool)
	{
		owner = _owner;
		return true;
	}

	/**
	* @dev Get the address of owner
	* @return the address of owner
	*/
	function getOwner() public view returns (address)
	{
		return owner;
	}

	/**
	* @dev Set circuitBreak to freeze/unfreeze all handlers by marketManager
	* @param _emergency The status of circuitBreak
	* @return true (TODO: validate results)
	*/
	function setCircuitBreaker(bool _emergency) onlyManager external override returns (bool)
	{
		emergency = _emergency;
		emit CircuitBreaked(_emergency, block.number);
		return true;
	}

	/**
	* @dev Liquidate asset of the user in default (or margin call) status
	* @param delinquentBorrower the liquidation target
	* @param targetHandler The hander ID of the liquidating asset (the
	  liquidator repay the tokens of the targetHandler instead)
	* @param liquidateAmount The amount to liquidate
	* @param receiveHandler The handler ID of the reward token for the liquidator
	* @return The amount of reward token
	*/
	function partialLiquidation(address payable delinquentBorrower, uint256 targetHandler, uint256 liquidateAmount, uint256 receiveHandler) circuitBreaker external override returns (uint256)
	{
		/* msg.sender is liquidator */
		address payable liquidator = msg.sender;
		LiquidationModel memory vars;
		/* Check whether the user is in liquidation.*/
		if (_checkLiquidation(delinquentBorrower) == false)
		{
			revert(NO_DELINQUENT);
		}

		/* Liquidate */
		(vars.liquidateAmount, vars.delinquentDepositAsset, vars.delinquentBorrowAsset) = marketManager.partialLiquidationUser(delinquentBorrower, liquidateAmount, liquidator, targetHandler, receiveHandler);

		/* Compute the price of the liquidated tokens */
		vars.liquidatePrice = marketManager.getTokenHandlerPrice(targetHandler);
		vars.liquidateAsset = unifiedMul(vars.liquidateAmount, vars.liquidatePrice);

		/* Calculates the number of tokens to receive as rewards. */
		vars.rewardAsset = unifiedDiv(unifiedMul(vars.liquidateAsset, vars.delinquentDepositAsset), vars.delinquentBorrowAsset);
		vars.receivePrice = marketManager.getTokenHandlerPrice(receiveHandler);
		vars.rewardAmount = unifiedDiv(vars.rewardAsset, vars.receivePrice);

		/* Receive reward */
		return marketManager.partialLiquidationUserReward(delinquentBorrower, vars.rewardAmount, liquidator, receiveHandler);
	}

	/**
	* @dev Checks the given user is eligible for delinquentBorrower (external)
	* @param userAddr The address of user
	* @return Eligibility as delinquentBorrower
	*/
	function checkLiquidation(address payable userAddr) external view override returns (bool)
	{
		return _checkLiquidation(userAddr);
	}

	/**
	* @dev Checks the given user is eligible for delinquentBorrower (internal)
	* @param userAddr The address of user
	* @return Eligibility as delinquentBorrower
	*/
	function _checkLiquidation(address payable userAddr) internal view returns (bool)
	{
		uint256 userBorrowAssetSum;
		uint256 liquidationLimitAssetSum;
		uint256 tokenListLength = marketManager.getTokenHandlersLength();
		for (uint256 handlerID = 0; handlerID < tokenListLength; handlerID++)
		{
			if (marketManager.getTokenHandlerSupport(handlerID))
			{
				/* Get the deposit and borrow amount including interest */
				uint256 depositAsset;
				uint256 borrowAsset;
				(depositAsset, borrowAsset) = marketManager.getUserIntraHandlerAssetWithInterest(userAddr, handlerID);


				/* Compute the liquidation limit and the sum of borrow of the
				user */
				uint256 marginCallLimit = marketManager.getTokenHandlerMarginCallLimit(handlerID);
				liquidationLimitAssetSum = add(liquidationLimitAssetSum, unifiedMul(depositAsset, marginCallLimit));
				userBorrowAssetSum = add(userBorrowAssetSum, borrowAsset);
			}

		}

		/* If the borrowed amount exceeds the liquidation limit, the user is a delinquent borrower. */
		if (liquidationLimitAssetSum <= userBorrowAssetSum)
		{
			return true;
			/* Margin call */
		}

		return false;
	}

	/* ******************* Safe Math ******************* */
	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		require(c >= a, "add overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _sub(a, b, "sub overflow");
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mul(a, b);
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(a, b, "div by zero");
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mod(a, b, "mod by zero");
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

		uint256 c = a * b;
		require((c / a) == b, "mul overflow");
		return c;
	}

	function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b > 0, errorMessage);
		return a / b;
	}

	function _mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b != 0, errorMessage);
		return a % b;
	}

	function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, unifiedPoint), b, "unified div by zero");
	}

	function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, b), unifiedPoint, "unified mul by zero");
	}
}