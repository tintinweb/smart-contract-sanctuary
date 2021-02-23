/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

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

// File: contracts/interfaces/oracleProxyInterface.sol

pragma solidity 0.6.12;

interface oracleProxyInterface  {
	function getTokenPrice(uint256 tokenID) external view returns (uint256);

	function getOracleFeed(uint256 tokenID) external view returns (address, uint256);
	function setOracleFeed(uint256 tokenID, address feedAddr, uint256 decimals) external returns (bool);
}

// File: contracts/interfaces/liquidationManagerInterface.sol

pragma solidity 0.6.12;

interface liquidationManagerInterface  {
	function setCircuitBreaker(bool _emergency) external returns (bool);
	function partialLiquidation(address payable delinquentBorrower, uint256 targetHandler, uint256 liquidateAmount, uint256 receiveHandler) external returns (uint256);
	function checkLiquidation(address payable userAddr) external view returns (bool);
}

// File: contracts/interfaces/proxyContractInterface.sol

pragma solidity 0.6.12;

interface proxyContractInterface  {
	function handlerProxy(bytes memory data) external returns (bool, bytes memory);
	function handlerViewProxy(bytes memory data) external view returns (bool, bytes memory);
	function siProxy(bytes memory data) external returns (bool, bytes memory);
	function siViewProxy(bytes memory data) external view returns (bool, bytes memory);
}

// File: contracts/interfaces/tokenInterface.sol

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external ;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external view returns (bool);
    function transferFrom(address from, address to, uint256 value) external ;
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

// File: contracts/SafeMath.sol
// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol

pragma solidity ^0.6.12;

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

// File: contracts/marketManager/tokenManager.sol

pragma solidity 0.6.12;

/**
 * @title Bifi's marketManager contract
 * @notice Implement business logic and manage handlers
 * @author Bifi
 */
contract etherManager is marketManagerInterface, ManagerErrors {
	using SafeMath for uint256;
	address public owner;

	bool public emergency = false;

	managerDataStorageInterface internal dataStorageInstance;

	oracleProxyInterface internal oracleProxy;

	/* feat: manager reward token instance*/
	IERC20 internal rewardErc20Instance;

	string internal constant updateRewardLane = "updateRewardLane(address)";

	mapping(address => Breaker) internal breakerTable;

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

	struct HandlerInfo {
		bool support;
		address addr;

		proxyContractInterface tokenHandler;
		bytes data;
	}

	uint256 public tokenHandlerLength;

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlyHandler(uint256 handlerID) {
		_isHandler(handlerID);
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

	/**
	* @dev Constructor for marketManager
	* @param managerDataStorageAddr The address of the manager storage contract
	* @param oracleProxyAddr The address of oracle proxy contract (e.g., price feeds)
	* @param breaker The address of default circuit breaker
	* @param erc20Addr The address of reward token (ERC-20)
	*/
	constructor (address managerDataStorageAddr, address oracleProxyAddr, address breaker, address erc20Addr) public
	{
		owner = msg.sender;
		dataStorageInstance = managerDataStorageInterface(managerDataStorageAddr);
		oracleProxy = oracleProxyInterface(oracleProxyAddr);
		rewardErc20Instance = IERC20(erc20Addr);
		breakerTable[owner].auth = true;
		breakerTable[breaker].auth = true;
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
	* @dev Set the address of oracleProxy contract
	* @param oracleProxyAddr The address of oracleProxy contract
	* @return true (TODO: validate results)
	*/
	function setOracleProxy(address oracleProxyAddr) onlyOwner external override returns (bool)
	{
		oracleProxy = oracleProxyInterface(oracleProxyAddr);
		return true;
	}

	/**
	* @dev Set the address of BiFi reward token contract
	* @param erc20Addr The address of BiFi reward token contract
	* @return true (TODO: validate results)
	*/
	function setRewardErc20(address erc20Addr) onlyOwner public returns (bool)
	{
		rewardErc20Instance = IERC20(erc20Addr);
		return true;
	}

	/**
	* @dev Authorize admin user for circuitBreaker
	* @param _target The address of the circuitBreaker admin user.
	* @param _status The boolean status of circuitBreaker (on/off)
	* @return true (TODO: validate results)
	*/
	function setBreakerTable(address _target, bool _status) onlyOwner external override returns (bool)
	{
		breakerTable[_target].auth = _status;
		return true;
	}

	/**
	* @dev Set circuitBreak to freeze/unfreeze all handlers
	* @param _emergency The boolean status of circuitBreaker (on/off)
	* @return true (TODO: validate results)
	*/
	function setCircuitBreaker(bool _emergency) onlyBreaker external override returns (bool)
	{
		bytes memory data;

		for (uint256 handlerID = 0; handlerID < tokenHandlerLength; handlerID++)
		{
			address tokenHandlerAddr = dataStorageInstance.getTokenHandlerAddr(handlerID);
			proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);

			// use delegate call via handler proxy
			// for token handlers
			bytes memory callData = abi.encodeWithSignature("setCircuitBreaker(bool)", _emergency);

			tokenHandler.handlerProxy(callData);
			tokenHandler.siProxy(callData);
		}

		address liquidationManagerAddr = dataStorageInstance.getLiquidationManagerAddr();
		liquidationManagerInterface liquidationManager = liquidationManagerInterface(liquidationManagerAddr);
		liquidationManager.setCircuitBreaker(_emergency);
		emergency = _emergency;
		return true;
	}

	/**
	* @dev Get the circuitBreak status
	* @return The circuitBreak status
	*/
	function getCircuitBreaker() external view override returns (bool)
	{
		return emergency;
	}

	/**
	* @dev Get information for a handler
	* @param handlerID Handler ID
	* @return (success or failure, handler address, handler name)
	*/
	function getTokenHandlerInfo(uint256 handlerID) external view override returns (bool, address, string memory)
	{
		bool support;
		address tokenHandlerAddr;
		string memory tokenName;
		if (dataStorageInstance.getTokenHandlerSupport(handlerID))
		{
			tokenHandlerAddr = dataStorageInstance.getTokenHandlerAddr(handlerID);
			proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
			bytes memory data;
			(, data) = tokenHandler.handlerViewProxy(abi.encodeWithSignature("getTokenName()"));
			tokenName = abi.decode(data, (string));
			support = true;
		}

		return (support, tokenHandlerAddr, tokenName);
	}

	/**
	* @dev Register a handler
	* @param handlerID Handler ID and address
	* @param tokenHandlerAddr The handler address
	* @return true (TODO: validate results)
	*/
	function handlerRegister(uint256 handlerID, address tokenHandlerAddr) onlyOwner external override returns (bool)
	{
		return _handlerRegister(handlerID, tokenHandlerAddr);
	}

	/**
	* @dev Set a liquidation manager contract
	* @param liquidationManagetAddr The address of liquidiation manager
	* @return true (TODO: validate results)
	*/
	function setLiquidationManager(address liquidationManagetAddr) onlyOwner external override returns (bool)
	{
		dataStorageInstance.setLiquidationManagerAddr(liquidationManagetAddr);
		return true;
	}

	/**
	* @dev Update the (SI) rewards for a user
	* @param userAddr The address of the user
	* @param callerID The handler ID
	* @return true (TODO: validate results)
	*/
	function rewardUpdateOfInAction(address payable userAddr, uint256 callerID) external override returns (bool)
	{
		HandlerInfo memory handlerInfo;
		(handlerInfo.support, handlerInfo.addr) = dataStorageInstance.getTokenHandlerInfo(callerID);
		if (handlerInfo.support)
		{
			proxyContractInterface tokenHandler;
			tokenHandler = proxyContractInterface(handlerInfo.addr);
			tokenHandler.siProxy(abi.encodeWithSignature(updateRewardLane, userAddr));
		}

		return true;
	}

	/**
	* @dev Update interest of a user for a handler (internal)
	* @param userAddr The user address
	* @param callerID The handler ID
	* @param allFlag Flag for the full calculation mode (calculting for all handlers)
	* @return (uint256, uint256, uint256, uint256, uint256, uint256)
	*/
	function applyInterestHandlers(address payable userAddr, uint256 callerID, bool allFlag) external override returns (uint256, uint256, uint256, uint256, uint256, uint256)
	{
		UserAssetsInfo memory userAssetsInfo;
		HandlerInfo memory handlerInfo;
		oracleProxyInterface _oracleProxy = oracleProxy;
		managerDataStorageInterface _dataStorage = dataStorageInstance;

		/* From all handlers, get the token price, margin call limit, borrow limit */
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			(handlerInfo.support, handlerInfo.addr) = _dataStorage.getTokenHandlerInfo(handlerID);
			if (handlerInfo.support)
			{
				handlerInfo.tokenHandler = proxyContractInterface(handlerInfo.addr);

				/* If the full-calculation mode is not set, work on the given handler only */
				if ((handlerID == callerID) || allFlag)
				{
					handlerInfo.tokenHandler.siProxy( abi.encodeWithSignature("updateRewardLane(address)", userAddr) );
					(, handlerInfo.data) = handlerInfo.tokenHandler.handlerProxy( abi.encodeWithSignature("applyInterest(address)", userAddr) );

					(userAssetsInfo.depositAmount, userAssetsInfo.borrowAmount) = abi.decode(handlerInfo.data, (uint256, uint256));
				}
				else
				{
					/* Get the deposit and borrow amount for the user */
					(, handlerInfo.data) = handlerInfo.tokenHandler.handlerViewProxy( abi.encodeWithSignature("getUserAmount(address)", userAddr) );
					(userAssetsInfo.depositAmount, userAssetsInfo.borrowAmount) = abi.decode(handlerInfo.data, (uint256, uint256));
				}

				(, handlerInfo.data) = handlerInfo.tokenHandler.handlerViewProxy( abi.encodeWithSignature("getTokenHandlerLimit()") );
				(userAssetsInfo.borrowLimit, userAssetsInfo.marginCallLimit) = abi.decode(handlerInfo.data, (uint256, uint256));

				/* Get the token price */
				if (handlerID == callerID)
				{
					userAssetsInfo.price = _oracleProxy.getTokenPrice(handlerID);
					userAssetsInfo.callerPrice = userAssetsInfo.price;
					userAssetsInfo.callerBorrowLimit = userAssetsInfo.borrowLimit;
				}

				/* If the user has no balance, the token handler can be ignored.*/
				if ((userAssetsInfo.depositAmount > 0) || (userAssetsInfo.borrowAmount > 0))
				{
					if (handlerID != callerID)
					{
						userAssetsInfo.price = _oracleProxy.getTokenPrice(handlerID);
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
	function interestUpdateReward() external override returns (bool)
	{
		uint256 thisBlock = block.number;
		uint256 interestRewardUpdated = dataStorageInstance.getInterestRewardUpdated();
		uint256 delta = thisBlock - interestRewardUpdated;
		if (delta == 0)
		{
			return false;
		}

		dataStorageInstance.setInterestRewardUpdated(thisBlock);
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
			bytes memory data;
			(, data) = tokenHandler.handlerProxy(abi.encodeWithSignature("checkFirstAction()"));
		}

		uint256 globalRewardPerBlock = dataStorageInstance.getInterestUpdateRewardPerblock();
		uint256 rewardAmount = delta.mul(globalRewardPerBlock);

		/* transfer reward tokens */
		return _rewardTransfer(msg.sender, rewardAmount);
	}

	/**
	* @dev (Update operation) update the rewards parameters.
	* @param userAddr The address of operator
	* @return Whether or not the operation succeed
	*/
	function updateRewardParams(address payable userAddr) external override returns (bool)
	{
		if (_determineRewardParams(userAddr))
		{
			return _calcRewardParams(userAddr);
		}

		return false;
	}

	/**
	* @dev Claim all rewards for the user
	* @param userAddr The user address
	* @return true (TODO: validate results)
	*/
	function rewardClaimAll(address payable userAddr) external override returns (bool)
	{
		uint256 handlerID;
		uint256 claimAmountSum;
		bytes memory data;
		for (handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
			(, data) = tokenHandler.siProxy(abi.encodeWithSignature(updateRewardLane, userAddr));

			/* Claim reward for a token handler */
			(, data) = tokenHandler.siProxy(abi.encodeWithSignature("claimRewardAmountUser(address)", userAddr));
			claimAmountSum = claimAmountSum.add(abi.decode(data, (uint256)));
		}

		return _rewardTransfer(userAddr, claimAmountSum);
	}

	/**
	* @dev Transfer reward tokens to owner (for administration)
	* @param _amount The amount of the reward token
	* @return true (TODO: validate results)
	*/
	function ownerRewardTransfer(uint256 _amount) onlyOwner external override returns (bool)
	{
		return _rewardTransfer(address(uint160(owner)), _amount);
	}

	/**
	* @dev Transfer reward tokens to a user
	* @param userAddr The address of recipient
	* @param _amount The amount of the reward token
	* @return true (TODO: validate results)
	*/
	function _rewardTransfer(address payable userAddr, uint256 _amount) internal returns (bool)
	{
		uint256 beforeBalance = rewardErc20Instance.balanceOf(userAddr);
		rewardErc20Instance.transfer(userAddr, _amount);
		uint256 afterBalance = rewardErc20Instance.balanceOf(userAddr);
		require(_amount == afterBalance.sub(beforeBalance), REWARD_TRANSFER);
		return true;
	}

	/**
	* @dev (Update operation) update the rewards parameters (by using alpha- and
	  beta-score).
	* @param userAddr The address of the operator
	* @return Whether or not this process succeed
	*/
	function _determineRewardParams(address payable userAddr) internal returns (bool)
	{
		uint256 thisBlockNum = block.number;
		managerDataStorageInterface _dataStorageInstance = dataStorageInstance;
		/* The inactive period (delta) since the last action happens */
		uint256 delta = thisBlockNum - _dataStorageInstance.getRewardParamUpdated();
		_dataStorageInstance.setRewardParamUpdated(thisBlockNum);
		if (delta == 0)
		{
			return false;
		}

		/* Rewards assigned for a block */
		uint256 globalRewardPerBlock = _dataStorageInstance.getGlobalRewardPerBlock();
		/* Rewards decrement for a block. (Rewards per block monotonically decreases) */
		uint256 globalRewardDecrement = _dataStorageInstance.getGlobalRewardDecrement();
		/* Total amount of rewards */
		uint256 globalRewardTotalAmount = _dataStorageInstance.getGlobalRewardTotalAmount();

		/* Remaining periods for reward distribution */
		uint256 remainingPeriod = globalRewardPerBlock.unifiedDiv(globalRewardDecrement);

		if (remainingPeriod >= delta.mul(SafeMath.unifiedPoint))
		{
			remainingPeriod = remainingPeriod.sub(delta.mul(SafeMath.unifiedPoint));
		}
		else
		{
			return _epilogueOfDetermineRewardParams(_dataStorageInstance, userAddr, delta, 0, globalRewardDecrement, 0);
		}

		if (globalRewardTotalAmount >= globalRewardPerBlock.mul(delta))
		{
			globalRewardTotalAmount = globalRewardTotalAmount - globalRewardPerBlock.mul(delta);
		}
		else
		{
			return _epilogueOfDetermineRewardParams(_dataStorageInstance, userAddr, delta, 0, globalRewardDecrement, 0);
		}

		globalRewardPerBlock = globalRewardTotalAmount.mul(2).unifiedDiv(remainingPeriod.add(SafeMath.unifiedPoint));
		/* To incentivze the update operation, the operator get paid with the
		reward token */
		return _epilogueOfDetermineRewardParams(_dataStorageInstance, userAddr, delta, globalRewardPerBlock, globalRewardDecrement, globalRewardTotalAmount);
	}

	/**
	* @dev Epilogue of _determineRewardParams for code-size savings
	* @param _dataStorageInstance interface of Manager Data Storage
	* @param userAddr User Address for Reward token transfer
	* @param _delta The inactive period (delta) since the last action happens
	* @param _globalRewardPerBlock Reward per block
	* @param _globalRewardDecrement Rewards decrement for a block
	* @param _globalRewardTotalAmount Total amount of rewards
	* @return true (TODO: validate results)
	*/
	function _epilogueOfDetermineRewardParams(
		managerDataStorageInterface _dataStorageInstance,
		address payable userAddr,
		uint256 _delta,
		uint256 _globalRewardPerBlock,
		uint256 _globalRewardDecrement,
		uint256 _globalRewardTotalAmount
	) internal returns (bool) {
		_updateDeterminedRewardModelParam(_globalRewardPerBlock, _globalRewardDecrement, _globalRewardTotalAmount);
		uint256 rewardAmount = _delta.mul(_dataStorageInstance.getRewardParamUpdateRewardPerBlock());
		/* To incentivze the update operation, the operator get paid with the
		reward token */
		_rewardTransfer(userAddr, rewardAmount);
		return true;
	}
	/**
	* @dev Set the reward model parameters
	* @param _rewardPerBlock Reward per block
	* @param _dcrement Rewards decrement for a block
	* @param _total Total amount of rewards
	* @return true (TODO: validate results)
	*/
	function _updateDeterminedRewardModelParam(uint256 _rewardPerBlock, uint256 _dcrement, uint256 _total) internal returns (bool)
	{
		dataStorageInstance.setGlobalRewardPerBlock(_rewardPerBlock);
		dataStorageInstance.setGlobalRewardDecrement(_dcrement);
		dataStorageInstance.setGlobalRewardTotalAmount(_total);
		return true;
	}

	/**
	* @dev Update rewards paramters of token handlers.
	* @param userAddr The address of operator
	* @return true (TODO: validate results)
	*/
	function _calcRewardParams(address payable userAddr) internal returns (bool)
	{
		uint256 handlerLength = tokenHandlerLength;
		bytes memory data;
		uint256[] memory handlerAlphaRateBaseAsset = new uint256[](handlerLength);
		uint256 handlerID;
		uint256 alphaRateBaseGlobalAssetSum;
		for (handlerID; handlerID < handlerLength; handlerID++)
		{
			handlerAlphaRateBaseAsset[handlerID] = _getAlphaBaseAsset(handlerID);
			alphaRateBaseGlobalAssetSum = alphaRateBaseGlobalAssetSum.add(handlerAlphaRateBaseAsset[handlerID]);
		}

		handlerID = 0;
		for (handlerID; handlerID < handlerLength; handlerID++)
		{
			proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
			(, data) = tokenHandler.siProxy(abi.encodeWithSignature(updateRewardLane, userAddr));

			/* Update reward parameter for the token handler */
			data = abi.encodeWithSignature("updateRewardPerBlockLogic(uint256)",
							dataStorageInstance.getGlobalRewardPerBlock()
							.unifiedMul(
								handlerAlphaRateBaseAsset[handlerID]
								.unifiedDiv(alphaRateBaseGlobalAssetSum)
								)
							);
			(, data) = tokenHandler.siProxy(data);
		}

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
		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(_handlerID));
		(, data) = tokenHandler.handlerViewProxy(abi.encodeWithSignature("getDepositTotalAmount()"));
		uint256 _depositAmount = abi.decode(data, (uint256));

		(, data) = tokenHandler.handlerViewProxy(abi.encodeWithSignature("getBorrowTotalAmount()"));
		uint256 _borrowAmount = abi.decode(data, (uint256));

		uint256 _alpha = dataStorageInstance.getAlphaRate();
		uint256 _price = _getTokenHandlerPrice(_handlerID);
		return _calcAlphaBaseAmount(_alpha, _depositAmount, _borrowAmount).unifiedMul(_price);
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
	* @dev Get the token price of the handler
	* @param handlerID The handler ID
	* @return The token price of the handler
	*/
	function getTokenHandlerPrice(uint256 handlerID) external view override returns (uint256)
	{
		return _getTokenHandlerPrice(handlerID);
	}

	/**
	* @dev Get the margin call limit of the handler (external)
	* @param handlerID The handler ID
	* @return The margin call limit
	*/
	function getTokenHandlerMarginCallLimit(uint256 handlerID) external view override returns (uint256)
	{
		return _getTokenHandlerMarginCallLimit(handlerID);
	}

	/**
	* @dev Get the margin call limit of the handler (internal)
	* @param handlerID The handler ID
	* @return The margin call limit
	*/
	function _getTokenHandlerMarginCallLimit(uint256 handlerID) internal view returns (uint256)
	{
		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
		bytes memory data;
		(, data) = tokenHandler.handlerViewProxy(abi.encodeWithSignature("getTokenHandlerMarginCallLimit()"));
		return abi.decode(data, (uint256));
	}

	/**
	* @dev Get the borrow limit of the handler (external)
	* @param handlerID The handler ID
	* @return The borrow limit
	*/
	function getTokenHandlerBorrowLimit(uint256 handlerID) external view override returns (uint256)
	{
		return _getTokenHandlerBorrowLimit(handlerID);
	}

	/**
	* @dev Get the borrow limit of the handler (internal)
	* @param handlerID The handler ID
	* @return The borrow limit
	*/
	function _getTokenHandlerBorrowLimit(uint256 handlerID) internal view returns (uint256)
	{
		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));

		bytes memory data;
		(, data) = tokenHandler.handlerViewProxy(abi.encodeWithSignature("getTokenHandlerBorrowLimit()"));
		return abi.decode(data, (uint256));
	}

	/**
	* @dev Get the handler status of whether the handler is supported or not.
	* @param handlerID The handler ID
	* @return Whether the handler is supported or not
	*/
	function getTokenHandlerSupport(uint256 handlerID) external view override returns (bool)
	{
		return dataStorageInstance.getTokenHandlerSupport(handlerID);
	}

	/**
	* @dev Set the length of the handler list
	* @param _tokenHandlerLength The length of the handler list
	* @return true (TODO: validate results)
	*/
	function setTokenHandlersLength(uint256 _tokenHandlerLength) onlyOwner external override returns (bool)
	{
		tokenHandlerLength = _tokenHandlerLength;
		return true;
	}

	/**
	* @dev Get the length of the handler list
	* @return the length of the handler list
	*/
	function getTokenHandlersLength() external view override returns (uint256)
	{
		return tokenHandlerLength;
	}

	/**
	* @dev Get the handler ID at the index in the handler list
	* @param index The index of the handler list (array)
	* @return The handler ID
	*/
	function getTokenHandlerID(uint256 index) external view override returns (uint256)
	{
		return dataStorageInstance.getTokenHandlerID(index);
	}

	/**
	* @dev Get the amount of token that the user can borrow more
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The amount of token that user can borrow more
	*/
	function getUserExtraLiquidityAmount(address payable userAddr, uint256 handlerID) external view override returns (uint256)
	{
		uint256 depositCredit;
		uint256 borrowCredit;
		(depositCredit, borrowCredit) = _getUserTotalIntraCreditAsset(userAddr);
		if (depositCredit == 0)
		{
			return 0;
		}

		if (depositCredit > borrowCredit)
		{
			return depositCredit.sub(borrowCredit).unifiedDiv(_getTokenHandlerPrice(handlerID));
		}
		else
		{
			return 0;
		}

	}

	/**
	* @dev Get the deposit and borrow amount of the user with interest added
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The deposit and borrow amount of the user with interest
	*/
	/* about user market Information function*/
	function getUserIntraHandlerAssetWithInterest(address payable userAddr, uint256 handlerID) external view override returns (uint256, uint256)
	{
		return _getUserIntraHandlerAssetWithInterest(userAddr, handlerID);
	}

	/**
	* @dev Get the depositTotalCredit and borrowTotalCredit
	* @param userAddr The address of the user
	* @return depositTotalCredit The amount that users can borrow (i.e. deposit * borrowLimit)
	* @return borrowTotalCredit The sum of borrow amount for all handlers
	*/
	function getUserTotalIntraCreditAsset(address payable userAddr) external view override returns (uint256, uint256)
	{
		return _getUserTotalIntraCreditAsset(userAddr);
	}

	/**
	* @dev Get the borrow and margin call limits of the user for all handlers
	* @param userAddr The address of the user
	* @return userTotalBorrowLimitAsset the sum of borrow limit for all handlers
	* @return userTotalMarginCallLimitAsset the sume of margin call limit for handlers
	*/
	function getUserLimitIntraAsset(address payable userAddr) external view override returns (uint256, uint256)
	{
		uint256 userTotalBorrowLimitAsset;
		uint256 userTotalMarginCallLimitAsset;
		(userTotalBorrowLimitAsset, userTotalMarginCallLimitAsset) = _getUserLimitIntraAsset(userAddr);
		return (userTotalBorrowLimitAsset, userTotalMarginCallLimitAsset);
	}


	/**
	* @dev Get the maximum allowed amount to borrow of the user from the given handler
	* @param userAddr The address of the user
	* @param callerID The target handler to borrow
	* @return extraCollateralAmount The maximum allowed amount to borrow from
	  the handler.
	*/
	function getUserCollateralizableAmount(address payable userAddr, uint256 callerID) external view override returns (uint256)
	{
		uint256 userTotalBorrowAsset;
		uint256 depositAssetBorrowLimitSum;
		uint256 depositHandlerAsset;
		uint256 borrowHandlerAsset;
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			if (dataStorageInstance.getTokenHandlerSupport(handlerID))
			{

				(depositHandlerAsset, borrowHandlerAsset) = _getUserIntraHandlerAssetWithInterest(userAddr, handlerID);
				userTotalBorrowAsset = userTotalBorrowAsset.add(borrowHandlerAsset);
				depositAssetBorrowLimitSum = depositAssetBorrowLimitSum
												.add(
													depositHandlerAsset
													.unifiedMul( _getTokenHandlerBorrowLimit(handlerID) )
												);
			}
		}

		if (depositAssetBorrowLimitSum > userTotalBorrowAsset)
		{
			return depositAssetBorrowLimitSum
					.sub(userTotalBorrowAsset)
					.unifiedDiv( _getTokenHandlerBorrowLimit(callerID) )
					.unifiedDiv( _getTokenHandlerPrice(callerID) );
		}
		return 0;
	}

	/**
	* @dev Partial liquidation for a user
	* @param delinquentBorrower The address of the liquidation target
	* @param liquidateAmount The amount to liquidate
	* @param liquidator The address of the liquidator (liquidation operator)
	* @param liquidateHandlerID The hander ID of the liquidating asset
	* @param rewardHandlerID The handler ID of the reward token for the liquidator
	* @return (uint256, uint256, uint256)
	*/
	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 liquidateHandlerID, uint256 rewardHandlerID) onlyLiquidationManager external override returns (uint256, uint256, uint256)
	{
		address tokenHandlerAddr = dataStorageInstance.getTokenHandlerAddr(liquidateHandlerID);
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		bytes memory data;

		data = abi.encodeWithSignature("partialLiquidationUser(address,uint256,address,uint256)", delinquentBorrower, liquidateAmount, liquidator, rewardHandlerID);
		(, data) = tokenHandler.handlerProxy(data);

		return abi.decode(data, (uint256, uint256, uint256));
	}

	/**
	* @dev Get the maximum liquidation reward by checking sufficient reward
	  amount for the liquidator.
	* @param delinquentBorrower The address of the liquidation target
	* @param liquidateHandlerID The hander ID of the liquidating asset
	* @param liquidateAmount The amount to liquidate
	* @param rewardHandlerID The handler ID of the reward token for the liquidator
	* @param rewardRatio delinquentBorrowAsset / delinquentDepositAsset
	* @return The maximum reward token amount for the liquidator
	*/
	function getMaxLiquidationReward(address payable delinquentBorrower, uint256 liquidateHandlerID, uint256 liquidateAmount, uint256 rewardHandlerID, uint256 rewardRatio) external view override returns (uint256)
	{
		uint256 liquidatePrice = _getTokenHandlerPrice(liquidateHandlerID);
		uint256 rewardPrice = _getTokenHandlerPrice(rewardHandlerID);
		uint256 delinquentBorrowerRewardDeposit;
		(delinquentBorrowerRewardDeposit, ) = _getHandlerAmount(delinquentBorrower, rewardHandlerID);
		uint256 rewardAsset = delinquentBorrowerRewardDeposit.unifiedMul(rewardPrice).unifiedMul(rewardRatio);
		if (liquidateAmount.unifiedMul(liquidatePrice) > rewardAsset)
		{
			return rewardAsset.unifiedDiv(liquidatePrice);
		}
		else
		{
			return liquidateAmount;
		}

	}

	/**
	* @dev Reward the liquidator
	* @param delinquentBorrower The address of the liquidation target
	* @param rewardAmount The amount of reward token
	* @param liquidator The address of the liquidator (liquidation operator)
	* @param handlerID The handler ID of the reward token for the liquidator
	* @return The amount of reward token
	*/
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 rewardAmount, address payable liquidator, uint256 handlerID) onlyLiquidationManager external override returns (uint256)
	{
		address tokenHandlerAddr = dataStorageInstance.getTokenHandlerAddr(handlerID);
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		bytes memory data;
		data = abi.encodeWithSignature("partialLiquidationUserReward(address,uint256,address)", delinquentBorrower, rewardAmount, liquidator);
		(, data) = tokenHandler.handlerProxy(data);

		return abi.decode(data, (uint256));
	}

	/**
	* @dev Get the deposit and borrow amount of the user for the handler (internal)
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The deposit and borrow amount
	*/
	function _getHandlerAmount(address payable userAddr, uint256 handlerID) internal view returns (uint256, uint256)
	{
		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
		bytes memory data;
		(, data) = tokenHandler.handlerViewProxy(abi.encodeWithSignature("getUserAmount(address)", userAddr));
		return abi.decode(data, (uint256, uint256));
	}

	/**
	* @dev Set the support stauts for the handler
	* @param handlerID the handler ID
	* @param support the support status (boolean)
	* @return true (TODO: validate results)
	*/
	function setHandlerSupport(uint256 handlerID, bool support) onlyOwner public returns (bool)
	{
		require(!dataStorageInstance.getTokenHandlerExist(handlerID), UNSUPPORTED_TOKEN);
		/* activate or inactivate anyway*/
		dataStorageInstance.setTokenHandlerSupport(handlerID, support);
		return true;
	}

	/**
	* @dev Get owner's address of the manager contract
	* @return The address of owner
	*/
	function getOwner() public view returns (address)
	{
		return owner;
	}

	/**
	* @dev Register a handler
	* @param handlerID The handler ID
	* @param handlerAddr The handler address
	* @return true (TODO: validate results)
	*/
	function _handlerRegister(uint256 handlerID, address handlerAddr) internal returns (bool)
	{
		dataStorageInstance.setTokenHandler(handlerID, handlerAddr);
		tokenHandlerLength = tokenHandlerLength + 1;
		return true;
	}

	/**
	* @dev Get the deposit and borrow amount of the user with interest added
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The deposit and borrow amount of the user with interest
	*/
	function _getUserIntraHandlerAssetWithInterest(address payable userAddr, uint256 handlerID) internal view returns (uint256, uint256)
	{
		uint256 price = _getTokenHandlerPrice(handlerID);
		proxyContractInterface tokenHandler = proxyContractInterface(dataStorageInstance.getTokenHandlerAddr(handlerID));
		uint256 depositAmount;
		uint256 borrowAmount;

		bytes memory data;
		(, data) = tokenHandler.handlerViewProxy(abi.encodeWithSignature("getUserAmountWithInterest(address)", userAddr));
		(depositAmount, borrowAmount) = abi.decode(data, (uint256, uint256));

		uint256 depositAsset = depositAmount.unifiedMul(price);
		uint256 borrowAsset = borrowAmount.unifiedMul(price);
		return (depositAsset, borrowAsset);
	}

	/**
	* @dev Get the borrow and margin call limits of the user for all handlers (internal)
	* @param userAddr The address of the user
	* @return userTotalBorrowLimitAsset the sum of borrow limit for all handlers
	* @return userTotalMarginCallLimitAsset the sume of margin call limit for handlers
	*/
	function _getUserLimitIntraAsset(address payable userAddr) internal view returns (uint256, uint256)
	{
		uint256 userTotalBorrowLimitAsset;
		uint256 userTotalMarginCallLimitAsset;
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			if (dataStorageInstance.getTokenHandlerSupport(handlerID))
			{
				uint256 depositHandlerAsset;
				uint256 borrowHandlerAsset;
				(depositHandlerAsset, borrowHandlerAsset) = _getUserIntraHandlerAssetWithInterest(userAddr, handlerID);
				uint256 borrowLimit = _getTokenHandlerBorrowLimit(handlerID);
				uint256 marginCallLimit = _getTokenHandlerMarginCallLimit(handlerID);
				uint256 userBorrowLimitAsset = depositHandlerAsset.unifiedMul(borrowLimit);
				uint256 userMarginCallLimitAsset = depositHandlerAsset.unifiedMul(marginCallLimit);
				userTotalBorrowLimitAsset = userTotalBorrowLimitAsset.add(userBorrowLimitAsset);
				userTotalMarginCallLimitAsset = userTotalMarginCallLimitAsset.add(userMarginCallLimitAsset);
			}
			else
			{
				continue;
			}

		}

		return (userTotalBorrowLimitAsset, userTotalMarginCallLimitAsset);
	}

	/**
	* @dev Get the depositTotalCredit and borrowTotalCredit
	* @param userAddr The address of the user
	* @return depositTotalCredit The amount that users can borrow (i.e. deposit * borrowLimit)
	* @return borrowTotalCredit The sum of borrow amount for all handlers
	*/
	function _getUserTotalIntraCreditAsset(address payable userAddr) internal view returns (uint256, uint256)
	{
		uint256 depositTotalCredit;
		uint256 borrowTotalCredit;
		for (uint256 handlerID; handlerID < tokenHandlerLength; handlerID++)
		{
			if (dataStorageInstance.getTokenHandlerSupport(handlerID))
			{
				uint256 depositHandlerAsset;
				uint256 borrowHandlerAsset;
				(depositHandlerAsset, borrowHandlerAsset) = _getUserIntraHandlerAssetWithInterest(userAddr, handlerID);
				uint256 borrowLimit = _getTokenHandlerBorrowLimit(handlerID);
				uint256 depositHandlerCredit = depositHandlerAsset.unifiedMul(borrowLimit);
				depositTotalCredit = depositTotalCredit.add(depositHandlerCredit);
				borrowTotalCredit = borrowTotalCredit.add(borrowHandlerAsset);
			}
			else
			{
				continue;
			}

		}

		return (depositTotalCredit, borrowTotalCredit);
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
	* @dev Get the address of reward token
	* @return The address of reward token
	*/
	function getRewardErc20() public view returns (address)
	{
		return address(rewardErc20Instance);
	}

	/**
	* @dev Get the reward parameters
	* @return (uint256,uint256,uint256) rewardPerBlock, rewardDecrement, rewardTotalAmount
	*/
	function getGlobalRewardInfo() external view override returns (uint256, uint256, uint256)
	{
		managerDataStorageInterface _dataStorage = dataStorageInstance;
		return (_dataStorage.getGlobalRewardPerBlock(), _dataStorage.getGlobalRewardDecrement(), _dataStorage.getGlobalRewardTotalAmount());
	}
}