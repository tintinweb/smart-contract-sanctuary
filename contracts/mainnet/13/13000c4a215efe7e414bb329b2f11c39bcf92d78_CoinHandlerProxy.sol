/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

pragma solidity 0.6.12;
interface marketManagerInterface  {
	function setOracleProxy(address oracleProxyAddr) external returns (bool);

	function setBreakerTable(address _target, bool _status) external returns (bool);

	function getCircuitBreaker() external view returns (bool);

	function setCircuitBreaker(bool _emergency) external returns (bool);

	function getTokenHandlerInfo(uint256 handlerID) external view returns (bool, address, string memory);

	function handlerRegister(uint256 handlerID, address tokenHandlerAddr) external returns (bool);

	function applyInterestHandlers(address payable userAddr, uint256 callerID, bool allFlag) external returns (uint256, uint256, uint256);

	function liquidationApplyInterestHandlers(address payable userAddr, uint256 callerID) external returns (uint256, uint256, uint256, uint256, uint256);

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

	function rewardTransfer(uint256 _claimAmountSum) external returns (bool);

	function updateRewardParams(address payable userAddr) external returns (bool);

	function interestUpdateReward() external returns (bool);

	function getGlobalRewardInfo() external view returns (uint256, uint256, uint256);
}
interface interestModelInterface  {
	function getInterestAmount(address handlerDataStorageAddr, address payable userAddr, bool isView) external view returns (bool, uint256, uint256, bool, uint256, uint256);

	function viewInterestAmount(address handlerDataStorageAddr, address payable userAddr) external view returns (bool, uint256, uint256, bool, uint256, uint256);

	function getSIRandBIR(address handlerDataStorageAddr, uint256 depositTotalAmount, uint256 borrowTotalAmount) external view returns (uint256, uint256);
}
interface marketHandlerDataStorageInterface  {
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

	function addBorrowAmount(address payable userAddr, uint256 amount) external returns (bool);

	function subDepositAmount(address payable userAddr, uint256 amount) external returns (bool);

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

	function getLimit() external view returns (uint256, uint256);

	function getBorrowLimit() external view returns (uint256);

	function getMarginCallLimit() external view returns (uint256);

	function getMinimumInterestRate() external view returns (uint256);

	function getLiquiditySensitivity() external view returns (uint256);

	function setBorrowLimit(uint256 _borrowLimit) external returns (bool);

	function setMarginCallLimit(uint256 _marginCallLimit) external returns (bool);

	function setMinimumInterestRate(uint256 _minimumInterestRate) external returns (bool);

	function setLiquiditySensitivity(uint256 _liquiditySensitivity) external returns (bool);

	function getLimitOfAction() external view returns (uint256);

	function setLimitOfAction(uint256 limitOfAction) external returns (bool);

	function getLiquidityLimit() external view returns (uint256);

	function setLiquidityLimit(uint256 liquidityLimit) external returns (bool);
}
interface marketSIHandlerDataStorageInterface  {
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
contract proxy  {
	address payable owner;

	uint256 handlerID;

	string tokenName = "ether";

	uint256 constant unifiedPoint = 10 ** 18;

	marketManagerInterface marketManager;

	interestModelInterface interestModelInstance;

	marketHandlerDataStorageInterface handlerDataStorage;

	marketSIHandlerDataStorageInterface SIHandlerDataStorage;

	address public handler;

	address public SI;

	string DEPOSIT = "deposit(uint256,bool)";

	string REDEEM = "withdraw(uint256,bool)";

	string BORROW = "borrow(uint256,bool)";

	string REPAY = "repay(uint256,bool)";

	modifier onlyOwner {
		require(msg.sender == owner, "Ownable: caller is not the owner");
		_;
	}

	modifier onlyMarketManager {
		address msgSender = msg.sender;
		require((msgSender == address(marketManager)) || (msgSender == owner), "onlyMarketManager function");
		_;
	}

	constructor () public 
	{
		owner = msg.sender;
	}

	function ownershipTransfer(address _owner) onlyOwner external returns (bool)
	{
		owner = address(uint160(_owner));
		return true;
	}

	function initialize(uint256 _handlerID, address handlerAddr, address marketManagerAddr, address interestModelAddr, address marketDataStorageAddr, address siHandlerAddr, address SIHandlerDataStorageAddr) onlyOwner public returns (bool)
	{
		handlerID = _handlerID;
		handler = handlerAddr;
		SI = siHandlerAddr;
		marketManager = marketManagerInterface(marketManagerAddr);
		interestModelInstance = interestModelInterface(interestModelAddr);
		handlerDataStorage = marketHandlerDataStorageInterface(marketDataStorageAddr);
		SIHandlerDataStorage = marketSIHandlerDataStorageInterface(SIHandlerDataStorageAddr);
	}

	function setHandlerID(uint256 _handlerID) onlyOwner public returns (bool)
	{
		handlerID = _handlerID;
		return true;
	}

	function setHandlerAddr(address handlerAddr) onlyOwner public returns (bool)
	{
		handler = handlerAddr;
		return true;
	}

	function setSiHandlerAddr(address siHandlerAddr) onlyOwner public returns (bool)
	{
		SI = siHandlerAddr;
		return true;
	}

	function getHandlerID() public view returns (uint256)
	{
		return handlerID;
	}

	function getHandlerAddr() public view returns (address)
	{
		return handler;
	}

	function getSiHandlerAddr() public view returns (address)
	{
		return SI;
	}

	function migration(address payable target) onlyOwner public returns (bool)
	{
		target.transfer(address(this).balance);
	}

	fallback () external payable 
	{
		require(msg.value != 0, "DEPOSIT use unifiedTokenAmount");
	}

	function deposit(uint256 unifiedTokenAmount, bool flag) public payable returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(DEPOSIT, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	function withdraw(uint256 unifiedTokenAmount, bool flag) public returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(REDEEM, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	function borrow(uint256 unifiedTokenAmount, bool flag) public returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(BORROW, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	function repay(uint256 unifiedTokenAmount, bool flag) public payable returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(REPAY, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	function handlerProxy(bytes memory data) onlyMarketManager external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}

	function handlerViewProxy(bytes memory data) external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}

	function siProxy(bytes memory data) onlyMarketManager external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = SI.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}

	function siViewProxy(bytes memory data) external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = SI.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}
}
contract CoinHandlerProxy is proxy {
    constructor()
    proxy() public {}
}