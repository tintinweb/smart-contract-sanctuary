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

// File: contracts/interfaces/interestModelInterface.sol

pragma solidity 0.6.12;

interface interestModelInterface {
	function getInterestAmount(address handlerDataStorageAddr, address payable userAddr, bool isView) external view returns (bool, uint256, uint256, bool, uint256, uint256);
	function viewInterestAmount(address handlerDataStorageAddr, address payable userAddr) external view returns (bool, uint256, uint256, bool, uint256, uint256);
	function getSIRandBIR(address handlerDataStorageAddr, uint256 depositTotalAmount, uint256 borrowTotalAmount) external view returns (uint256, uint256);
}

// File: contracts/interfaces/marketHandlerDataStorageInterface.sol

pragma solidity 0.6.12;

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

// File: contracts/interfaces/marketSIHandlerDataStorageInterface.sol

pragma solidity 0.6.12;

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

// File: contracts/reqTokenProxy.sol

pragma solidity 0.6.12;

/**
 * @title Bifi user request proxy (ERC-20 token)
 * @notice access logic contracts via delegate calls.
 * @author Bifi
 */
contract tokenProxy is RequestProxyErrors {
	address payable owner;

	uint256 handlerID;

	string tokenName;

	uint256 constant unifiedPoint = 10 ** 18;

	uint256 unifiedTokenDecimal = 10 ** 18;

	uint256 underlyingTokenDecimal;

	marketManagerInterface marketManager;

	interestModelInterface interestModelInstance;

	marketHandlerDataStorageInterface handlerDataStorage;

	marketSIHandlerDataStorageInterface SIHandlerDataStorage;

	IERC20 erc20Instance;

	address public handler;

	address public SI;

	string DEPOSIT = "deposit(uint256,bool)";

	string REDEEM = "withdraw(uint256,bool)";

	string BORROW = "borrow(uint256,bool)";

	string REPAY = "repay(uint256,bool)";

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlyMarketManager {
		address msgSender = msg.sender;
		require((msgSender == address(marketManager)) || (msgSender == owner), ONLY_MANAGER);
		_;
	}

	/**
	* @dev Construct a new TokenProxy which uses tokenHandlerLogic
	*/
	constructor () public
	{
		owner = msg.sender;
	}

	/**
	* @dev Replace the owner of the handler
	* @param _owner the address of the new owner
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address _owner) onlyOwner external returns (bool)
	{
		owner = address(uint160(_owner));
		return true;
	}

	/**
	* @dev Initialize the contract
	* @param _handlerID ID of handler
	* @param marketManagerAddr The address of market manager
	* @param interestModelAddr The address of handler interest model contract address
	* @param marketDataStorageAddr The address of handler data storage
	* @param erc20Addr The address of target ERC-20 token (underlying asset)
	* @param _tokenName The name of target ERC-20 token
	* @param siHandlerAddr The address of service incentive contract
	* @param SIHandlerDataStorageAddr The address of service incentive data storage
	*/
	function initialize(uint256 _handlerID, address handlerAddr, address marketManagerAddr, address interestModelAddr, address marketDataStorageAddr, address erc20Addr, string memory _tokenName, address siHandlerAddr, address SIHandlerDataStorageAddr) onlyOwner public returns (bool)
	{
		handlerID = _handlerID;
		handler = handlerAddr;
		marketManager = marketManagerInterface(marketManagerAddr);
		interestModelInstance = interestModelInterface(interestModelAddr);
		handlerDataStorage = marketHandlerDataStorageInterface(marketDataStorageAddr);
		erc20Instance = IERC20(erc20Addr);
		tokenName = _tokenName;
		SI = siHandlerAddr;
		SIHandlerDataStorage = marketSIHandlerDataStorageInterface(SIHandlerDataStorageAddr);
	}

	/**
	* @dev Set ID of handler
	* @param _handlerID The id of handler
	* @return true (TODO: validate results)
	*/
	function setHandlerID(uint256 _handlerID) onlyOwner public returns (bool)
	{
		handlerID = _handlerID;
		return true;
	}

	/**
	* @dev Set the address of handler
	* @param handlerAddr The address of handler
	* @return true (TODO: validate results)
	*/
	function setHandlerAddr(address handlerAddr) onlyOwner public returns (bool)
	{
		handler = handlerAddr;
		return true;
	}

	/**
	* @dev Set the address of service incentive contract
	* @param siHandlerAddr The address of service incentive contract
	* @return true (TODO: validate results)
	*/
	function setSiHandlerAddr(address siHandlerAddr) onlyOwner public returns (bool)
	{
		SI = siHandlerAddr;
		return true;
	}

	/**
	* @dev Get ID of handler
	* @return The connected handler ID
	*/
	function getHandlerID() public view returns (uint256)
	{
		return handlerID;
	}

	/**
	* @dev Get the address of handler
	* @return The handler address
	*/
	function getHandlerAddr() public view returns (address)
	{
		return handler;
	}

	/**
	* @dev Get address of service incentive contract
	* @return The service incentive contract address
	*/
	function getSiHandlerAddr() public view returns (address)
	{
		return SI;
	}

	/**
	* @dev Move assets to sender for the migration event
	*/
	function migration(address target) onlyOwner public returns (bool)
	{
		uint256 balance = erc20Instance.balanceOf(address(this));
		erc20Instance.transfer(target, balance);
	}

	/**
	* @dev Forward the deposit request for deposit to the handler logic contract.
	* @param unifiedTokenAmount The amount of coins to deposit
	* @param flag Flag for the full calcuation mode
	* @return whether the deposit has been made successfully or not.
	*/
	function deposit(uint256 unifiedTokenAmount, bool flag) public payable returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(DEPOSIT, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	/**
	* @dev Forward the withdraw request for withdraw to the handler logic contract.
	* @param unifiedTokenAmount The amount of coins to withdraw
	* @param flag Flag for the full calcuation mode
	* @return whether the withdraw has been made successfully or not.
	*/
	function withdraw(uint256 unifiedTokenAmount, bool flag) public returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(REDEEM, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	/**
	* @dev Forward the borrow request for borrow to the handler logic contract.
	* @param unifiedTokenAmount The amount of coins to borrow
	* @param flag Flag for the full calcuation mode
	* @return whether the borrow has been made successfully or not.
	*/
	function borrow(uint256 unifiedTokenAmount, bool flag) public returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(BORROW, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	/**
	* @dev Forward the repay request for repay to the handler logic contract.
	* @param unifiedTokenAmount The amount of coins to repay
	* @param flag Flag for the full calcuation mode
	* @return whether the repay has been made successfully or not.
	*/
	function repay(uint256 unifiedTokenAmount, bool flag) public payable returns (bool)
	{
		bool result;
		bytes memory returnData;
		bytes memory data = abi.encodeWithSignature(REPAY, unifiedTokenAmount, flag);
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return result;
	}

	/**
	* @dev Call other functions in handler logic contract.
	* @param data The encoded value of the function and argument
	* @return The result of the call
	*/
	function handlerProxy(bytes memory data) onlyMarketManager external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}

	/**
	* @dev Call other view functions in handler logic contract.
	* (delegatecall does not work for view functions)
	* @param data The encoded value of the function and argument
	* @return The result of the call
	*/
	function handlerViewProxy(bytes memory data) external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = handler.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}

	/**
	* @dev Call other functions in service incentive logic contract.
	* @param data The encoded value of the function and argument
	* @return The result of the call
	*/
	function siProxy(bytes memory data) onlyMarketManager external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = SI.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}

	/**
	* @dev Call other view functions in service incentive logic contract.
	* (delegatecall does not work for view functions)
	* @param data The encoded value of the function and argument
	* @return The result of the call
	*/
	function siViewProxy(bytes memory data) external returns (bool, bytes memory)
	{
		bool result;
		bytes memory returnData;
		(result, returnData) = SI.delegatecall(data);
		require(result, string(returnData));
		return (result, returnData);
	}
}