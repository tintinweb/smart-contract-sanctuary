/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

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

// File: contracts/interfaces/IMarketHandlerDataStorage.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's market handler data storage interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IMarketHandlerDataStorage  {
	function setCircuitBreaker(bool _emergency) external returns (bool);

	function setNewCustomer(address payable userAddr) external returns (bool);

	function getUserAccessed(address payable userAddr) external view returns (bool);
	function setUserAccessed(address payable userAddr, bool _accessed) external returns (bool);

	function getReservedAddr() external view returns (address payable);
	function setReservedAddr(address payable reservedAddress) external returns (bool);

	function getReservedAmount() external view returns (int256);
	function addReservedAmount(uint256 amount) external returns (int256);
	function subReservedAmount(uint256 amount) external returns (int256);
	function updateSignedReservedAmount(int256 amount) external returns (int256);

	function setTokenHandler(address _marketHandlerAddr, address _interestModelAddr) external returns (bool);
	function setCoinHandler(address _marketHandlerAddr, address _interestModelAddr) external returns (bool);

	function getDepositTotalAmount() external view returns (uint256);
	function addDepositTotalAmount(uint256 amount) external returns (uint256);
	function subDepositTotalAmount(uint256 amount) external returns (uint256);

	function getBorrowTotalAmount() external view returns (uint256);
	function addBorrowTotalAmount(uint256 amount) external returns (uint256);
	function subBorrowTotalAmount(uint256 amount) external returns (uint256);

	function getUserIntraDepositAmount(address payable userAddr) external view returns (uint256);
	function addUserIntraDepositAmount(address payable userAddr, uint256 amount) external returns (uint256);
	function subUserIntraDepositAmount(address payable userAddr, uint256 amount) external returns (uint256);

	function getUserIntraBorrowAmount(address payable userAddr) external view returns (uint256);
	function addUserIntraBorrowAmount(address payable userAddr, uint256 amount) external returns (uint256);
	function subUserIntraBorrowAmount(address payable userAddr, uint256 amount) external returns (uint256);

	function addDepositAmount(address payable userAddr, uint256 amount) external returns (bool);
	function subDepositAmount(address payable userAddr, uint256 amount) external returns (bool);

	function addBorrowAmount(address payable userAddr, uint256 amount) external returns (bool);
	function subBorrowAmount(address payable userAddr, uint256 amount) external returns (bool);

	function getUserAmount(address payable userAddr) external view returns (uint256, uint256);
	function getHandlerAmount() external view returns (uint256, uint256);

	function getAmount(address payable userAddr) external view returns (uint256, uint256, uint256, uint256);
	function setAmount(address payable userAddr, uint256 depositTotalAmount, uint256 borrowTotalAmount, uint256 depositAmount, uint256 borrowAmount) external returns (uint256);

	function setBlocks(uint256 lastUpdatedBlock, uint256 inactiveActionDelta) external returns (bool);

	function getLastUpdatedBlock() external view returns (uint256);
	function setLastUpdatedBlock(uint256 _lastUpdatedBlock) external returns (bool);

	function getInactiveActionDelta() external view returns (uint256);
	function setInactiveActionDelta(uint256 inactiveActionDelta) external returns (bool);

	function syncActionEXR() external returns (bool);

	function getActionEXR() external view returns (uint256, uint256);
	function setActionEXR(uint256 actionDepositExRate, uint256 actionBorrowExRate) external returns (bool);

	function getGlobalDepositEXR() external view returns (uint256);
	function getGlobalBorrowEXR() external view returns (uint256);

	function setEXR(address payable userAddr, uint256 globalDepositEXR, uint256 globalBorrowEXR) external returns (bool);

	function getUserEXR(address payable userAddr) external view returns (uint256, uint256);
	function setUserEXR(address payable userAddr, uint256 depositEXR, uint256 borrowEXR) external returns (bool);

	function getGlobalEXR() external view returns (uint256, uint256);

	function getMarketHandlerAddr() external view returns (address);
	function setMarketHandlerAddr(address marketHandlerAddr) external returns (bool);

	function getInterestModelAddr() external view returns (address);
	function setInterestModelAddr(address interestModelAddr) external returns (bool);


	function getMinimumInterestRate() external view returns (uint256);
	function setMinimumInterestRate(uint256 _minimumInterestRate) external returns (bool);

	function getLiquiditySensitivity() external view returns (uint256);
	function setLiquiditySensitivity(uint256 _liquiditySensitivity) external returns (bool);

	function getLimit() external view returns (uint256, uint256);

	function getBorrowLimit() external view returns (uint256);
	function setBorrowLimit(uint256 _borrowLimit) external returns (bool);

	function getMarginCallLimit() external view returns (uint256);
	function setMarginCallLimit(uint256 _marginCallLimit) external returns (bool);

	function getLimitOfAction() external view returns (uint256);
	function setLimitOfAction(uint256 limitOfAction) external returns (bool);

	function getLiquidityLimit() external view returns (uint256);
	function setLiquidityLimit(uint256 liquidityLimit) external returns (bool);
}

// File: contracts/interfaces/IMarketManager.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's market manager interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IMarketManager  {
	function setBreakerTable(address _target, bool _status) external returns (bool);

	function getCircuitBreaker() external view returns (bool);
	function setCircuitBreaker(bool _emergency) external returns (bool);

	function getTokenHandlerInfo(uint256 handlerID) external view returns (bool, address, string memory);

	function handlerRegister(uint256 handlerID, address tokenHandlerAddr, uint256 flashFeeRate) external returns (bool);

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

	function rewardClaimAll(address payable userAddr) external returns (uint256);

	function updateRewardParams(address payable userAddr) external returns (bool);
	function interestUpdateReward() external returns (bool);
	function getGlobalRewardInfo() external view returns (uint256, uint256, uint256);

	function setOracleProxy(address oracleProxyAddr) external returns (bool);

	function rewardUpdateOfInAction(address payable userAddr, uint256 callerID) external returns (bool);
	function ownerRewardTransfer(uint256 _amount) external returns (bool);
 	function getFeeTotal(uint256 handlerID) external returns (uint256);
  function getFeeFromArguments(uint256 handlerID, uint256 amount, uint256 bifiAmount) external returns (uint256);
}

// File: contracts/interfaces/IInterestModel.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's interest model interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IInterestModel {
	function getInterestAmount(address handlerDataStorageAddr, address payable userAddr, bool isView) external view returns (bool, uint256, uint256, bool, uint256, uint256);
	function viewInterestAmount(address handlerDataStorageAddr, address payable userAddr) external view returns (bool, uint256, uint256, bool, uint256, uint256);
	function getSIRandBIR(uint256 depositTotalAmount, uint256 borrowTotalAmount) external view returns (uint256, uint256);
}

// File: contracts/interfaces/IMarketSIHandlerDataStorage.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's market si handler data storage interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IMarketSIHandlerDataStorage  {
	function setCircuitBreaker(bool _emergency) external returns (bool);

	function updateRewardPerBlockStorage(uint256 _rewardPerBlock) external returns (bool);

	function getRewardInfo(address userAddr) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

	function getMarketRewardInfo() external view returns (uint256, uint256, uint256);
	function setMarketRewardInfo(uint256 _rewardLane, uint256 _rewardLaneUpdateAt, uint256 _rewardPerBlock) external returns (bool);

	function getUserRewardInfo(address userAddr) external view returns (uint256, uint256, uint256);
	function setUserRewardInfo(address userAddr, uint256 _rewardLane, uint256 _rewardLaneUpdateAt, uint256 _rewardAmount) external returns (bool);

	function getBetaRate() external view returns (uint256);
	function setBetaRate(uint256 _betaRate) external returns (bool);
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

// File: contracts/interfaces/IFlashloanReceiver.sol
pragma solidity 0.6.12;

interface IFlashloanReceiver {
    function executeOperation(
      address reserve,
      uint256 amount,
      uint256 fee,
      bytes calldata params
    ) external returns (bool);
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
        context = block.number;

        // block timestamp chain
        // context = block.timestamp;
    }
}

// File: contracts/marketHandler/CoinHandler.sol
pragma solidity 0.6.12;

 /**
  * @title BiFi's CoinHandler logic contract for native conis
  * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract CoinHandler is IMarketHandler, HandlerErrors, BlockContext {
	event MarketIn(address userAddr);

	event Deposit(address depositor, uint256 depositAmount, uint256 handlerID);
	event Withdraw(address redeemer, uint256 redeemAmount, uint256 handlerID);
	event Borrow(address borrower, uint256 borrowAmount, uint256 handlerID);
	event Repay(address repayer, uint256 repayAmount, uint256 handlerID);

	event ReserveDeposit(uint256 reserveDepositAmount, uint256 handlerID);
	event ReserveWithdraw(uint256 reserveWithdrawAmount, uint256 handlerID);

	event FlashloanFeeWithdraw(uint256 flashloanFeeWithdrawAmount, uint256 handlerID);

	event OwnershipTransferred(address owner, address newOwner);

	event CircuitBreaked(bool breaked, uint256 blockNumber, uint256 handlerID);

	address payable owner;
	uint256 handlerID;
	string tokenName = "ether";

	uint256 constant unifiedPoint = 10 ** 18;

	IMarketManager marketManager;
	IInterestModel interestModelInstance;
	IMarketHandlerDataStorage handlerDataStorage;
	IMarketSIHandlerDataStorage SIHandlerDataStorage;

	struct ProxyInfo {
		bool result;
		bytes returnData;
		bytes data;
		bytes proxyData;
	}

	modifier onlyMarketManager {
		address msgSender = msg.sender;
		require((msgSender == address(marketManager)) || (msgSender == owner), ONLY_MANAGER);
		_;
	}

	modifier onlyOwner {
		require(msg.sender == address(owner), ONLY_OWNER);
		_;
	}

	/**
	* @dev Set circuitBreak to freeze all of handlers by owner
	* @param _emergency Boolean state of the circuit break.
	* @return true (TODO: validate results)
	*/
	function setCircuitBreakWithOwner(bool _emergency) onlyOwner external override returns (bool)
	{
		handlerDataStorage.setCircuitBreaker(_emergency);

		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Set circuitBreak which freeze all of handlers by marketManager
	* @param _emergency Boolean state of the circuit break.
	* @return true (TODO: validate results)
	*/
	function setCircuitBreaker(bool _emergency) onlyMarketManager external override returns (bool)
	{
		handlerDataStorage.setCircuitBreaker(_emergency);

		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Get the token name (unused in CoinHandler)
	* @return The token name
	*/
	function getTokenName() external view override returns (string memory)
	{
		return tokenName;
	}

	/**
	* @dev Change the owner of the handler
	* @param newOwner the address of the owner to be replaced
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address payable newOwner) onlyOwner external override returns (bool)
	{
		owner = newOwner;

		emit OwnershipTransferred(owner, newOwner);
		return true;
	}

	/**
	* @dev Deposit assets to the reserve of the handler.
	* @param unifiedTokenAmount The amount of token to deposit
	* @return true (TODO: validate results)
	*/
	function reserveDeposit(uint256 unifiedTokenAmount) external payable override returns (bool)
	{
		require(unifiedTokenAmount == 0, USE_VAULE);
		unifiedTokenAmount = msg.value;

		handlerDataStorage.addReservedAmount(unifiedTokenAmount);
		handlerDataStorage.addDepositTotalAmount(unifiedTokenAmount);

		emit ReserveDeposit(unifiedTokenAmount, handlerID);
		return true;
	}

	/**
	* @dev Withdraw assets from the reserve of the handler.
	* @param unifiedTokenAmount The amount of token to withdraw
	* @return true (TODO: validate results)
	*/
	function reserveWithdraw(uint256 unifiedTokenAmount) onlyOwner external override returns (bool)
	{
		address payable reserveAddr = handlerDataStorage.getReservedAddr();

		handlerDataStorage.subReservedAmount(unifiedTokenAmount);
		handlerDataStorage.subDepositTotalAmount(unifiedTokenAmount);

		_transfer(reserveAddr, unifiedTokenAmount);

		emit ReserveWithdraw(unifiedTokenAmount, handlerID);
		return true;
	}

	function withdrawFlashloanFee(uint256 unifiedTokenAmount) onlyMarketManager external override returns (bool) {
		address payable reserveAddr = handlerDataStorage.getReservedAddr();

		handlerDataStorage.subReservedAmount(unifiedTokenAmount);
		handlerDataStorage.subDepositTotalAmount(unifiedTokenAmount);

		_transfer(reserveAddr, unifiedTokenAmount);

		emit FlashloanFeeWithdraw(unifiedTokenAmount, handlerID);
		return true;
	}

	/**
	* @dev Deposit action
	* @param unifiedTokenAmount The deposit amount (must be zero, msg.value is used)
	* @param flag Flag for the full calcuation mode
	* @return true (TODO: validate results)
	*/
	function deposit(uint256 unifiedTokenAmount, bool flag) external payable override returns (bool)
	{
		require(unifiedTokenAmount == 0, USE_VAULE);
		unifiedTokenAmount = msg.value;
		address payable userAddr = msg.sender;
		uint256 _handlerID = handlerID;

		if(flag) {
			// flag is true, update interest, reward all handlers
			marketManager.applyInterestHandlers(userAddr, _handlerID, flag);
		} else {
			marketManager.rewardUpdateOfInAction(userAddr, _handlerID);
			_applyInterest(userAddr);
		}

		handlerDataStorage.addDepositAmount(userAddr, unifiedTokenAmount);

		emit Deposit(userAddr, unifiedTokenAmount, _handlerID);
		return true;
	}

	/**
	* @dev Withdraw action
	* @param unifiedTokenAmount The withdraw amount
	* @param flag Flag for the full calcuation mode
	* @return true (TODO: validate results)
	*/
	function withdraw(uint256 unifiedTokenAmount, bool flag) external override returns (bool)
	{
		address payable userAddr = msg.sender;
		uint256 _handlerID = handlerID;

		uint256 userLiquidityAmount;
		uint256 userCollateralizableAmount;
		uint256 price;
		(userLiquidityAmount, userCollateralizableAmount, , , , price) = marketManager.applyInterestHandlers(userAddr, _handlerID, flag);

		uint256 adjustedAmount = _getUserActionMaxWithdrawAmount(userAddr, unifiedTokenAmount, userCollateralizableAmount);
		require(unifiedMul(adjustedAmount, price) <= handlerDataStorage.getLimitOfAction(), EXCEED_LIMIT);

		handlerDataStorage.subDepositAmount(userAddr, adjustedAmount);

		_transfer(userAddr, adjustedAmount);

		emit Withdraw(userAddr, adjustedAmount, _handlerID);
		return true;
	}

	/**
	* @dev Borrow action
	* @param unifiedTokenAmount The borrow amount
	* @param flag Flag for the full calcuation mode
	* @return true (TODO: validate results)
	*/
	function borrow(uint256 unifiedTokenAmount, bool flag) external override returns (bool)
	{
		address payable userAddr = msg.sender;
		uint256 _handlerID = handlerID;

		uint256 userLiquidityAmount;
		uint256 userCollateralizableAmount;
		uint256 price;
		(userLiquidityAmount, userCollateralizableAmount, , , , price) = marketManager.applyInterestHandlers(userAddr, _handlerID, flag);

		uint256 adjustedAmount = _getUserActionMaxBorrowAmount(unifiedTokenAmount, userLiquidityAmount);
		require(unifiedMul(adjustedAmount, price) <= handlerDataStorage.getLimitOfAction(), EXCEED_LIMIT);

		handlerDataStorage.addBorrowAmount(userAddr, adjustedAmount);

		_transfer(userAddr, adjustedAmount);

		emit Borrow(userAddr, adjustedAmount, _handlerID);
		return true;
	}

	/**
	* @dev Repay action
	* @param unifiedTokenAmount The repay amount (must be zero, msg.value is used)
	* @param flag Flag for the full calcuation mode
	* @return true (TODO: validate results)
	*/
	function repay(uint256 unifiedTokenAmount, bool flag) external payable override returns (bool)
	{
		require(unifiedTokenAmount == 0, USE_VAULE);
		unifiedTokenAmount = msg.value;
		address payable userAddr = msg.sender;
		uint256 _handlerID = handlerID;

		if(flag) {
			// flag is true, update interest, reward all handlers
			marketManager.applyInterestHandlers(userAddr, _handlerID, flag);
		} else {
			marketManager.rewardUpdateOfInAction(userAddr, _handlerID);
			_applyInterest(userAddr);
		}

		uint256 overRepayAmount;
		uint256 userBorrowAmount = handlerDataStorage.getUserIntraBorrowAmount(userAddr);

		if (userBorrowAmount < unifiedTokenAmount)
		{
			overRepayAmount = sub(unifiedTokenAmount, userBorrowAmount);
			unifiedTokenAmount = userBorrowAmount;
		}

		handlerDataStorage.subBorrowAmount(userAddr, unifiedTokenAmount);
		if (overRepayAmount > 0)
		{
			_transfer(userAddr, overRepayAmount);
		}

		emit Repay(userAddr, unifiedTokenAmount, _handlerID);
		return true;
	}

	function executeFlashloan(
		address receiverAddress,
		uint256 amount
    ) external onlyMarketManager override returns (bool) {
		_transfer(payable(receiverAddress), amount);

    	return true;
	}

	function depositFlashloanFee(
		uint256 amount
	) external onlyMarketManager override returns (bool) {
		handlerDataStorage.addReservedAmount(amount);
		handlerDataStorage.addDepositTotalAmount(amount);

		emit ReserveDeposit(amount, handlerID);

		return true;
	}


	/**
	* @dev liquidate delinquentBorrower's partial(or can total) asset
	* @param delinquentBorrower The user addresss of liquidation target
	* @param liquidateAmount The amount of liquidator request
	* @param liquidator The address of a user executing liquidate
	* @param rewardHandlerID The handler id of delinquentBorrower's collateral for receive
	* @return (liquidateAmount, delinquentDepositAsset, delinquentBorrowAsset), result of liquidate
	*/
	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 rewardHandlerID) onlyMarketManager external override returns (uint256, uint256, uint256)
	{
		uint256 tmp;
		uint256 delinquentMarginCallDeposit;
		uint256 delinquentDepositAsset;
		uint256 delinquentBorrowAsset;
		uint256 liquidatorLiquidityAmount;

		/* apply interest for sync "latest" asset for delinquentBorrower and liquidator */
		(, , delinquentMarginCallDeposit, delinquentDepositAsset, delinquentBorrowAsset, ) = marketManager.applyInterestHandlers(delinquentBorrower, handlerID, false);
		(, liquidatorLiquidityAmount, , , , ) = marketManager.applyInterestHandlers(liquidator, handlerID, false);

		/* check delinquentBorrower liquidatable */
		require(delinquentMarginCallDeposit <= delinquentBorrowAsset, NO_LIQUIDATION);

		/* The maximum allowed amount for liquidateAmount */
		tmp = handlerDataStorage.getUserIntraDepositAmount(liquidator);
		if (tmp <= liquidateAmount)
		{
			liquidateAmount = tmp;
		}

		tmp = handlerDataStorage.getUserIntraBorrowAmount(delinquentBorrower);
		if (tmp <= liquidateAmount)
		{
			liquidateAmount = tmp;
		}

		/* get maximum "receive handler" amount by liquidate amount */
		liquidateAmount = marketManager.getMaxLiquidationReward(delinquentBorrower, handlerID, liquidateAmount, rewardHandlerID, unifiedDiv(delinquentBorrowAsset, delinquentDepositAsset));

		/* check liquidator has enough amount for liquidation */
		require(liquidatorLiquidityAmount > liquidateAmount, NO_EFFECTIVE_BALANCE);

		/* update storage for liquidate*/
		handlerDataStorage.subDepositAmount(liquidator, liquidateAmount);

		handlerDataStorage.subBorrowAmount(delinquentBorrower, liquidateAmount);

		return (liquidateAmount, delinquentDepositAsset, delinquentBorrowAsset);
	}

	/**
	* @dev liquidator receive delinquentBorrower's collateral after liquidate delinquentBorrower's asset
	* @param delinquentBorrower The user addresss of liquidation target
	* @param liquidationAmountWithReward The amount of liquidator receiving delinquentBorrower's collateral
	* @param liquidator The address of a user executing liquidate
	* @return The amount of token transfered(in storage)
	*/
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 liquidationAmountWithReward, address payable liquidator) onlyMarketManager external override returns (uint256)
	{
		marketManager.rewardUpdateOfInAction(delinquentBorrower, handlerID);
		_applyInterest(delinquentBorrower);
		/* check delinquentBorrower's collateral enough */
		uint256 collateralAmount = handlerDataStorage.getUserIntraDepositAmount(delinquentBorrower);
		require(collateralAmount >= liquidationAmountWithReward, NO_LIQUIDATION_REWARD);

		/* collateral transfer */
		handlerDataStorage.subDepositAmount(delinquentBorrower, liquidationAmountWithReward);

		_transfer(liquidator, liquidationAmountWithReward);

		return liquidationAmountWithReward;
	}

	/**
	* @dev Get borrowLimit and marginCallLimit
	* @return borrowLimit and marginCallLimit
	*/
	function getTokenHandlerLimit() external view override returns (uint256, uint256)
	{
		return handlerDataStorage.getLimit();
	}

	/**
	* @dev Set the borrow limit of the handler
	* @param borrowLimit The borrow limit
	* @return true (TODO: validate results)
	*/
	function setTokenHandlerBorrowLimit(uint256 borrowLimit) onlyOwner external override returns (bool)
	{
		handlerDataStorage.setBorrowLimit(borrowLimit);
		return true;
	}

	/**
	* @dev Set the liquidation limit of the handler
	* @param marginCallLimit The liquidation limit
	* @return true (TODO: validate results)
	*/
	function setTokenHandlerMarginCallLimit(uint256 marginCallLimit) onlyOwner external override returns (bool)
	{
		handlerDataStorage.setMarginCallLimit(marginCallLimit);
		return true;
	}

	/**
	* @dev Get the liquidation limit of handler
	* @return The liquidation limit
	*/
	function getTokenHandlerMarginCallLimit() external view override returns (uint256)
	{
		return handlerDataStorage.getMarginCallLimit();
	}

	/**
	* @dev Get the borrow limit of the handler
	* @return The borrow limit
	*/
	function getTokenHandlerBorrowLimit() external view override returns (uint256)
	{
		return handlerDataStorage.getBorrowLimit();
	}

	/**
	* @dev Get the maximum allowed amount for borrow for a user (external, view)
	* @param userAddr The user address
	* @return The maximum allowed amount for borrow
	*/
	function getUserMaxBorrowAmount(address payable userAddr) external view override returns (uint256)
	{
		return _getUserMaxBorrowAmount(userAddr);
	}

  /**
	* @dev Get (total deposit - total borrow) of the handler including interest
	* @param userAddr The user address(for wrapping function, unused)
	* @return (total deposit - total borrow) of the handler including interest
	*/
	function getTokenLiquidityAmountWithInterest(address payable userAddr) external view override returns (uint256)
  {
    return _getTokenLiquidityAmountWithInterest(userAddr);
  }

	/**
	* @dev Get the maximum allowed amount for borrow for a user (interal)
	* @param userAddr The user address
	* @return The maximum allowed amount for borrow
	*/
	function _getUserMaxBorrowAmount(address payable userAddr) internal view returns (uint256)
	{
		/* Prevent Action: over "Token Liquidity" amount*/
		uint256 handlerLiquidityAmount = _getTokenLiquidityLimitAmountWithInterest(userAddr);
		/* Prevent Action: over "CREDIT" amount */
		uint256 userLiquidityAmount = marketManager.getUserExtraLiquidityAmount(userAddr, handlerID);
		uint256 minAmount = userLiquidityAmount;
		if (handlerLiquidityAmount < minAmount)
		{
			minAmount = handlerLiquidityAmount;
		}

		return minAmount;
	}

	/**
	* @dev Get the maximum allowed amount for borrow by user liqudity amount and handler total balance.
	* @param requestedAmount The reqeusted amount for borrow
	* @param userLiquidityAmount The maximum borrow amount by unused collateral.
	* @return The maximum allowed amount for borrow
	*/
	function _getUserActionMaxBorrowAmount(uint256 requestedAmount, uint256 userLiquidityAmount) internal view returns (uint256)
	{
		/* Prevent Action: over "Token Liquidity" amount*/
		uint256 handlerLiquidityAmount = _getTokenLiquidityLimitAmount();
		/* select minimum of handlerLiqudity and user liquidity */
		uint256 minAmount = requestedAmount;
		if (minAmount > handlerLiquidityAmount)
		{
			minAmount = handlerLiquidityAmount;
		}

		if (minAmount > userLiquidityAmount)
		{
			minAmount = userLiquidityAmount;
		}

		return minAmount;
	}

	/**
	* @dev Get the maximum allowd amount for withdraw for a user
	* @param userAddr The user address
	* @return The maximum allowed amount for withdraw
	*/
	function getUserMaxWithdrawAmount(address payable userAddr) external view override returns (uint256)
	{
		return _getUserMaxWithdrawAmount(userAddr);
	}

	/**
	* @dev Get SIR and BIR
	* @return SIR and BIR (tuple)
	*/
	function getSIRandBIR() external view override returns (uint256, uint256)
	{
		uint256 totalDepositAmount = handlerDataStorage.getDepositTotalAmount();
		uint256 totalBorrowAmount = handlerDataStorage.getBorrowTotalAmount();

		return interestModelInstance.getSIRandBIR(totalDepositAmount, totalBorrowAmount);
	}

	/**
	* @dev Get the maximum allowd amount for withdraw for a user
	* @param userAddr The user address
	* @return The maximum allowed amount for withdraw
	*/
	function _getUserMaxWithdrawAmount(address payable userAddr) internal view returns (uint256)
	{
		uint256 depositAmountWithInterest;
		uint256 borrowAmountWithInterest;
		(depositAmountWithInterest, borrowAmountWithInterest) = _getUserAmountWithInterest(userAddr);

		uint256 handlerLiquidityAmount = _getTokenLiquidityAmountWithInterest(userAddr);

		uint256 userLiquidityAmount = marketManager.getUserCollateralizableAmount(userAddr, handlerID);

		/* Prevent Action: over "DEPOSIT" amount */
		uint256 minAmount = depositAmountWithInterest;

		/* Prevent Action: over "CREDIT" amount */
		if (minAmount > userLiquidityAmount)
		{
			minAmount = userLiquidityAmount;
		}

		if (minAmount > handlerLiquidityAmount)
		{
			minAmount = handlerLiquidityAmount;
		}

		return minAmount;
	}

	/**
	* @dev Get the maximum allowd amount for withdraw for a user
	* @param userAddr The user address
	* @param requestedAmount The reqested amount of token to withdraw
	* @param collateralableAmount The amount of unused collateral.
	* @return The maximum allowd amount for withdraw
	*/
	function _getUserActionMaxWithdrawAmount(address payable userAddr, uint256 requestedAmount, uint256 collateralableAmount) internal view returns (uint256)
	{
		uint256 depositAmount = handlerDataStorage.getUserIntraDepositAmount(userAddr);

		uint256 handlerLiquidityAmount = _getTokenLiquidityAmount();

		/* the minimum of request, deposit, collateral and collateralable*/
		uint256 minAmount = depositAmount;
		if (minAmount > requestedAmount)
		{
			minAmount = requestedAmount;
		}

		if (minAmount > collateralableAmount)
		{
			minAmount = collateralableAmount;
		}

		if (minAmount > handlerLiquidityAmount)
		{
			minAmount = handlerLiquidityAmount;
		}

		return minAmount;
	}

	/**
	* @dev Get the maximum amount for repay
	* @param userAddr The user address
	* @return The maximum amount for repay
	*/
	function getUserMaxRepayAmount(address payable userAddr) external view override returns (uint256)
	{
		uint256 depositAmountWithInterest;
		uint256 borrowAmountWithInterest;
		(depositAmountWithInterest, borrowAmountWithInterest) = _getUserAmountWithInterest(userAddr);

		return borrowAmountWithInterest;
	}

	/**
	* @dev Update (apply) interest entry point (external)
	* @param userAddr The user address
	* @return "latest" (userDepositAmount, userBorrowAmount)
	*/
	function applyInterest(address payable userAddr) external override returns (uint256, uint256)
	{
		return _applyInterest(userAddr);
	}

	/**
	* @dev Update (apply) interest entry point (internal)
	* @param userAddr The user address
	* @return "latest" (userDepositAmount, userBorrowAmount)
	*/
	function _applyInterest(address payable userAddr) internal returns (uint256, uint256)
	{
		_checkNewCustomer(userAddr);
		_checkFirstAction();
		return _updateInterestAmount(userAddr);
	}

	/**
	* @dev Check whether a given userAddr is a new user or not
	* @param userAddr The user address
	* @return true if the user is a new user; false otherwise.
	*/
	function _checkNewCustomer(address payable userAddr) internal returns (bool)
	{
		IMarketHandlerDataStorage _handlerDataStorage = handlerDataStorage;
		if (_handlerDataStorage.getUserAccessed(userAddr))
		{
			return false;
		}
		/* hotfix */
		_handlerDataStorage.setUserAccessed(userAddr, true);

		(uint256 gDEXR, uint256 gBEXR) = _handlerDataStorage.getGlobalEXR();
		_handlerDataStorage.setUserEXR(userAddr, gDEXR, gBEXR);
		return true;
	}

  	/**
	* @dev Get the address of the token that the handler is dealing with
	* (CoinHandler don't deal with tokens in coin handlers)
	* @return The address of the token
	*/
	function getERC20Addr() external override view returns (address)
	{
		return address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
	}

	/**
	* @dev Get the amount of deposit and borrow of the user
	* @param userAddr The user address
	* @return (depositAmount, borrowAmount)
	*/
	function getUserAmount(address payable userAddr) external view override returns (uint256, uint256)
	{
		uint256 depositAmount = handlerDataStorage.getUserIntraDepositAmount(userAddr);
		uint256 borrowAmount = handlerDataStorage.getUserIntraBorrowAmount(userAddr);

		return (depositAmount, borrowAmount);
	}

	/**
	* @dev Get the amount of user deposit
	* @param userAddr The user address
	* @return the amount of user deposit
	*/
	function getUserIntraDepositAmount(address payable userAddr) external view returns (uint256)
	{
		return handlerDataStorage.getUserIntraDepositAmount(userAddr);
	}

	/**
	* @dev Get the amount of user borrow
	* @param userAddr The user address
	* @return the amount of user borrow
	*/
	function getUserIntraBorrowAmount(address payable userAddr) external view returns (uint256)
	{
		return handlerDataStorage.getUserIntraBorrowAmount(userAddr);
	}

	/**
	* @dev Get the amount of the total deposit of the handler
	* @return the amount of the total deposit of the handler
	*/
	function getDepositTotalAmount() external view override returns (uint256)
	{
		return handlerDataStorage.getDepositTotalAmount();
	}

	/**
	* @dev Get the amount of total borrow of the handler
	* @return the amount of total borrow of the handler
	*/
	function getBorrowTotalAmount() external view override returns (uint256)
	{
		return handlerDataStorage.getBorrowTotalAmount();
	}

	/**
	* @dev Get the amount of deposit and borrow of user including interest
	* @param userAddr The user address
	* @return (userDepositAmount, userBorrowAmount)
	*/
	function getUserAmountWithInterest(address payable userAddr) external view override returns (uint256, uint256)
	{
		return _getUserAmountWithInterest(userAddr);
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
	* @dev Internal function to transfer asset to the user
	* @param userAddr The user address
	* @param unifiedTokenAmount The amount of coin to send
	* @return true (TODO: validate results)
	*/
	function _transfer(address payable userAddr, uint256 unifiedTokenAmount) internal returns (bool)
	{
		userAddr.transfer(unifiedTokenAmount);
		return true;
	}

	/**
	* @dev Get (total deposit - total borrow) of the handler
	* @return (total deposit - total borrow) of the handler
	*/
	function _getTokenLiquidityAmount() internal view returns (uint256)
	{
		IMarketHandlerDataStorage _handlerDataStorage = handlerDataStorage;
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = _handlerDataStorage.getHandlerAmount();

		if (depositTotalAmount == 0)
		{
			return 0;
		}

		if (depositTotalAmount < borrowTotalAmount)
		{
			return 0;
		}

		return sub(depositTotalAmount, borrowTotalAmount);
	}

	/**
	* @dev Get (total deposit * liquidity limit - total borrow) of the handler
	* @return (total deposit * liquidity limit - total borrow) of the handler
	*/
	function _getTokenLiquidityLimitAmount() internal view returns (uint256)
	{
		IMarketHandlerDataStorage _handlerDataStorage = handlerDataStorage;
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = _handlerDataStorage.getHandlerAmount();

		if (depositTotalAmount == 0)
		{
			return 0;
		}

		uint256 liquidityDeposit = unifiedMul(depositTotalAmount, _handlerDataStorage.getLiquidityLimit());
		if (liquidityDeposit < borrowTotalAmount)
		{
			return 0;
		}

		return sub(liquidityDeposit, borrowTotalAmount);
	}

	/**
	* @dev Get (total deposit - total borrow) of the handler including interest
	* @param userAddr The user address(for wrapping function, unused)
	* @return (total deposit - total borrow) of the handler including interest
	*/
	function _getTokenLiquidityAmountWithInterest(address payable userAddr) internal view returns (uint256)
	{
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = _getTotalAmountWithInterest(userAddr);

		if (depositTotalAmount == 0)
		{
			return 0;
		}

		if (depositTotalAmount < borrowTotalAmount)
		{
			return 0;
		}

		return sub(depositTotalAmount, borrowTotalAmount);
	}
	/**
	* @dev Get (total deposit * liquidity limit - total borrow) of the handler including interest
	* @param userAddr The user address(for wrapping function, unused)
	* @return (total deposit * liquidity limit - total borrow) of the handler including interest
	*/
	function _getTokenLiquidityLimitAmountWithInterest(address payable userAddr) internal view returns (uint256)
	{
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = _getTotalAmountWithInterest(userAddr);

		if (depositTotalAmount == 0)
		{
			return 0;
		}

		uint256 liquidityDeposit = unifiedMul(depositTotalAmount, handlerDataStorage.getLiquidityLimit());

		if (liquidityDeposit < borrowTotalAmount)
		{
			return 0;
		}

		return sub(liquidityDeposit, borrowTotalAmount);
	}

	/**
	* @dev Check first action of user in the This Block (external)
	* @return true for first action
	*/
	function checkFirstAction() onlyMarketManager external override returns (bool)
	{
		return _checkFirstAction();
	}

  /**
	* @dev Convert amount of handler's unified decimals to amount of token's underlying decimals
	* @param unifiedTokenAmount The amount of unified decimals
	* @return (underlyingTokenAmount)
	*/
  function convertUnifiedToUnderlying(uint256 unifiedTokenAmount) external override view returns (uint256) {
		return unifiedTokenAmount;
	}

	/**
	* @dev Check first action of user in the This Block (internal)
	* @return true for first action
	*/
	function _checkFirstAction() internal returns (bool)
	{
		IMarketHandlerDataStorage _handlerDataStorage = handlerDataStorage;

		uint256 lastUpdatedBlock = _handlerDataStorage.getLastUpdatedBlock();
		uint256 currentBlockNumber = _blockContext();
		uint256 blockDelta = sub(currentBlockNumber, lastUpdatedBlock);

		if (blockDelta > 0)
		{
			// first action in this block
			_handlerDataStorage.setBlocks(currentBlockNumber, blockDelta);
			_handlerDataStorage.syncActionEXR();
			return true;
		}

		return false;
	}

	/**
	* @dev calculate (apply) interest (internal) and call storage update function
	* @param userAddr The user address
	* @return "latest" (userDepositAmount, userBorrowAmount)
	*/
	function _updateInterestAmount(address payable userAddr) internal returns (uint256, uint256)
	{
		bool depositNegativeFlag;
		uint256 deltaDepositAmount;
		uint256 globalDepositEXR;

		bool borrowNegativeFlag;
		uint256 deltaBorrowAmount;
		uint256 globalBorrowEXR;
		/* calculate interest amount and params by call Interest Model */
		(depositNegativeFlag, deltaDepositAmount, globalDepositEXR, borrowNegativeFlag, deltaBorrowAmount, globalBorrowEXR) = interestModelInstance.getInterestAmount(address(handlerDataStorage), userAddr, false);

		/* update new global EXR to user EXR*/
		handlerDataStorage.setEXR(userAddr, globalDepositEXR, globalBorrowEXR);

		/* call storage update function for update "latest" interest information  */
		return _setAmountReflectInterest(userAddr, depositNegativeFlag, deltaDepositAmount, borrowNegativeFlag, deltaBorrowAmount);
	}

	/**
	* @dev Apply the user's interest
	* @param userAddr The user address
	* @param depositNegativeFlag the sign of deltaDepositAmount (true for negative)
	* @param deltaDepositAmount The delta amount of deposit
	* @param borrowNegativeFlag the sign of deltaBorrowAmount (true for negative)
	* @param deltaBorrowAmount The delta amount of borrow
	* @return "latest" (userDepositAmount, userBorrowAmount)
	*/
	function _setAmountReflectInterest(address payable userAddr, bool depositNegativeFlag, uint256 deltaDepositAmount, bool borrowNegativeFlag, uint256 deltaBorrowAmount) internal returns (uint256, uint256)
	{
		uint256 depositTotalAmount;
		uint256 userDepositAmount;
		uint256 borrowTotalAmount;
		uint256 userBorrowAmount;
		/* call _getAmountWithInterest for adding user storage amount and interest delta amount (deposit and borrow)*/
		(depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount) = _getAmountWithInterest(userAddr, depositNegativeFlag, deltaDepositAmount, borrowNegativeFlag, deltaBorrowAmount);

		/* update user amount in storage*/
		handlerDataStorage.setAmount(userAddr, depositTotalAmount, borrowTotalAmount, userDepositAmount, userBorrowAmount);

		/* update "spread between deposits and borrows" */
		_updateReservedAmount(depositNegativeFlag, deltaDepositAmount, borrowNegativeFlag, deltaBorrowAmount);

		return (userDepositAmount, userBorrowAmount);
	}

	/**
	* @dev Get the "latest" user amount of deposit and borrow including interest (internal, view)
	* @param userAddr The user address
	* @return "latest" (userDepositAmount, userBorrowAmount)
	*/
	function _getUserAmountWithInterest(address payable userAddr) internal view returns (uint256, uint256)
	{
		uint256 depositTotalAmount;
		uint256 userDepositAmount;
		uint256 borrowTotalAmount;
		uint256 userBorrowAmount;
		(depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount) = _calcAmountWithInterest(userAddr);

		return (userDepositAmount, userBorrowAmount);
	}

	/**
	* @dev Get the "latest" handler amount of deposit and borrow including interest (internal, view)
	* @param userAddr The user address
	* @return "latest" (depositTotalAmount, borrowTotalAmount)
	*/
	function _getTotalAmountWithInterest(address payable userAddr) internal view returns (uint256, uint256)
	{
		uint256 depositTotalAmount;
		uint256 userDepositAmount;
		uint256 borrowTotalAmount;
		uint256 userBorrowAmount;
		(depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount) = _calcAmountWithInterest(userAddr);

		return (depositTotalAmount, borrowTotalAmount);
	}

	/**
	* @dev The deposit and borrow amount with interest for the user
	* @param userAddr The user address
	* @return "latest" (depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount)
	*/
	function _calcAmountWithInterest(address payable userAddr) internal view returns (uint256, uint256, uint256, uint256)
	{
		bool depositNegativeFlag;
		uint256 deltaDepositAmount;
		uint256 globalDepositEXR;

		bool borrowNegativeFlag;
		uint256 deltaBorrowAmount;
		uint256 globalBorrowEXR;
		/* calculate interest "delta" amount and params by call Interest Model */
		(depositNegativeFlag, deltaDepositAmount, globalDepositEXR, borrowNegativeFlag, deltaBorrowAmount, globalBorrowEXR) = interestModelInstance.getInterestAmount(address(handlerDataStorage), userAddr, true);

		/* call _getAmountWithInterest for adding user storage amount and interest delta amount (deposit and borrow)*/
		return _getAmountWithInterest(userAddr, depositNegativeFlag, deltaDepositAmount, borrowNegativeFlag, deltaBorrowAmount);
	}

	/**
	* @dev Calculate "latest" amount with interest for the block delta
	* @param userAddr The user address
	* @param depositNegativeFlag the sign of deltaDepositAmount (true for negative)
	* @param deltaDepositAmount The delta amount of deposit
	* @param borrowNegativeFlag the sign of deltaBorrowAmount (true for negative)
	* @param deltaBorrowAmount The delta amount of borrow
	* @return "latest" (depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount)
	*/
	function _getAmountWithInterest(address payable userAddr, bool depositNegativeFlag, uint256 deltaDepositAmount, bool borrowNegativeFlag, uint256 deltaBorrowAmount) internal view returns (uint256, uint256, uint256, uint256)
	{
		uint256 depositTotalAmount;
		uint256 userDepositAmount;
		uint256 borrowTotalAmount;
		uint256 userBorrowAmount;
		(depositTotalAmount, borrowTotalAmount, userDepositAmount, userBorrowAmount) = handlerDataStorage.getAmount(userAddr);

		if (depositNegativeFlag)
		{
			depositTotalAmount = sub(depositTotalAmount, deltaDepositAmount);
			userDepositAmount = sub(userDepositAmount, deltaDepositAmount);
		}
		else
		{
			depositTotalAmount = add(depositTotalAmount, deltaDepositAmount);
			userDepositAmount = add(userDepositAmount, deltaDepositAmount);
		}

		if (borrowNegativeFlag)
		{
			borrowTotalAmount = sub(borrowTotalAmount, deltaBorrowAmount);
			userBorrowAmount = sub(userBorrowAmount, deltaBorrowAmount);
		}
		else
		{
			borrowTotalAmount = add(borrowTotalAmount, deltaBorrowAmount);
			userBorrowAmount = add(userBorrowAmount, deltaBorrowAmount);
		}

		return (depositTotalAmount, userDepositAmount, borrowTotalAmount, userBorrowAmount);
	}

	/**
	* @dev Update the amount of the reserve
	* @param depositNegativeFlag the sign of deltaDepositAmount (true for negative)
	* @param deltaDepositAmount The delta amount of deposit
	* @param borrowNegativeFlag the sign of deltaBorrowAmount (true for negative)
	* @param deltaBorrowAmount The delta amount of borrow
	* @return true (TODO: validate results)
	*/
	function _updateReservedAmount(bool depositNegativeFlag, uint256 deltaDepositAmount, bool borrowNegativeFlag, uint256 deltaBorrowAmount) internal returns (bool)
	{
		int256 signedDeltaDepositAmount = int(deltaDepositAmount);
		int256 signedDeltaBorrowAmount = int(deltaBorrowAmount);
		if (depositNegativeFlag)
		{
			signedDeltaDepositAmount = signedDeltaDepositAmount * (-1);
		}

		if (borrowNegativeFlag)
		{
			signedDeltaBorrowAmount = signedDeltaBorrowAmount * (-1);
		}

		/* signedDeltaReservedAmount is singed amount */
		int256 signedDeltaReservedAmount = signedSub(signedDeltaBorrowAmount, signedDeltaDepositAmount);
		handlerDataStorage.updateSignedReservedAmount(signedDeltaReservedAmount);
		return true;
	}

	/**
	* @dev Set the address of the marketManager contract
	* @param marketManagerAddr The address of the marketManager contract
	* @return true (TODO: validate results)
	*/
	function setMarketManager(address marketManagerAddr) onlyOwner public returns (bool)
	{
		marketManager = IMarketManager(marketManagerAddr);
		return true;
	}

	/**
	* @dev Set the address of the InterestModel contract
	* @param interestModelAddr The address of the InterestModel contract
	* @return true (TODO: validate results)
	*/
	function setInterestModel(address interestModelAddr) onlyOwner public returns (bool)
	{
		interestModelInstance = IInterestModel(interestModelAddr);
		return true;
	}

	/**
	* @dev Set the address of the marketDataStorage contract
	* @param marketDataStorageAddr The address of the marketDataStorage contract
	* @return true (TODO: validate results)
	*/
	function setHandlerDataStorage(address marketDataStorageAddr) onlyOwner public returns (bool)
	{
		handlerDataStorage = IMarketHandlerDataStorage(marketDataStorageAddr);
		return true;
	}

	/**
	* @dev Set the address of the siHandlerDataStorage contract
	* @param SIHandlerDataStorageAddr The address of the siHandlerDataStorage contract
	* @return true (TODO: validate results)
	*/
	function setSiHandlerDataStorage(address SIHandlerDataStorageAddr) onlyOwner public returns (bool)
	{
		SIHandlerDataStorage = IMarketSIHandlerDataStorage(SIHandlerDataStorageAddr);
		return true;
	}

	/**
	* @dev Get the address of the siHandlerDataStorage contract
	* @return The address of the siHandlerDataStorage contract
	*/
	function getSiHandlerDataStorage() public view returns (address)
	{
		return address(SIHandlerDataStorage);
	}

	/**
	* @dev Get the address of the marketManager contract
	* @return The address of the marketManager contract
	*/
	function getMarketManagerAddr() public view returns (address)
	{
		return address(marketManager);
	}

	/**
	* @dev Get the address of the InterestModel contract
	* @return The address of the InterestModel contract
	*/
	function getInterestModelAddr() public view returns (address)
	{
		return address(interestModelInstance);
	}

	/**
	* @dev Get the address of handler's dataStroage
	* @return the address of handler's dataStroage
	*/
	function getHandlerDataStorageAddr() public view returns (address)
	{
		return address(handlerDataStorage);
	}

	/**
	* @dev Get the outgoing limit of tokens
	* @return The outgoing limit of tokens
	*/
	function getLimitOfAction() external view returns (uint256)
	{
		return handlerDataStorage.getLimitOfAction();
	}



	/* ******************* Safe Math ******************* */
  // from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
  // Subject to the MIT license.
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

	function signedAdd(int256 a, int256 b) internal pure returns (int256)
	{
		int256 c = a + b;
		require(((b >= 0) && (c >= a)) || ((b < 0) && (c < a)), "SignedSafeMath: addition overflow");
		return c;
	}

	function signedSub(int256 a, int256 b) internal pure returns (int256)
	{
		int256 c = a - b;
		require(((b >= 0) && (c <= a)) || ((b < 0) && (c > a)), "SignedSafeMath: subtraction overflow");
		return c;
	}
}