/**
 *Submitted for verification at Etherscan.io on 2021-06-18
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

// File: contracts/interfaces/IManagerSlotSetter.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's Manager Context Setter interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IManagerSlotSetter  {
  function ownershipTransfer(address payable _owner) external returns (bool);
  function setOperator(address payable adminAddr, bool flag) external returns (bool);
  function setOracleProxy(address oracleProxyAddr) external returns (bool);
  function setRewardErc20(address erc20Addr) external returns (bool);
  function setBreakerTable(address _target, bool _status) external returns (bool);
  function setCircuitBreaker(bool _emergency) external returns (bool);
  function handlerRegister(uint256 handlerID, address tokenHandlerAddr, uint256 flashFeeRate, uint256 discountBase) external returns (bool);
  function setLiquidationManager(address liquidationManagerAddr) external returns (bool);
  function setHandlerSupport(uint256 handlerID, bool support) external returns (bool);
  function setPositionStorageAddr(address _positionStorageAddr) external returns (bool);
  function setNFTAddr(address _nftAddr) external returns (bool);
  function setDiscountBase(uint256 handlerID, uint256 feeBase) external returns (bool);
  function setFlashloanAddr(address _flashloanAddr) external returns (bool);
  function sethandlerManagerAddr(address _handlerManagerAddr) external returns (bool);
  function setSlotSetterAddr(address _slotSetterAddr) external returns (bool);
  function setFlashloanFee(uint256 handlerID, uint256 flashFeeRate) external returns (bool);
}

// File: contracts/interfaces/IHandlerManager.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's Manager Interest interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IHandlerManager  {
  function applyInterestHandlers(address payable userAddr, uint256 callerID, bool allFlag) external returns (uint256, uint256, uint256, uint256, uint256, uint256);
  function interestUpdateReward() external returns (bool);
  function updateRewardParams(address payable userAddr) external returns (bool);
  function rewardClaimAll(address payable userAddr) external returns (uint256);
  function claimHandlerReward(uint256 handlerID, address payable userAddr) external returns (uint256);
  function ownerRewardTransfer(uint256 _amount) external returns (bool);
}

// File: contracts/interfaces/IManagerFlashloan.sol
pragma solidity 0.6.12;

interface IManagerFlashloan {
  function withdrawFlashloanFee(uint256 handlerID) external returns (bool);

  function flashloan(
    uint256 handlerID,
    address receiverAddress,
    uint256 amount,
    bytes calldata params
  ) external returns (bool);

  function getFee(uint256 handlerID, uint256 amount) external view returns (uint256);

  function getFeeTotal(uint256 handlerID) external view returns (uint256);

  function getFeeFromArguments(uint256 handlerID, uint256 amount, uint256 bifiAmo) external view returns (uint256);
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

// File: contracts/marketManager/TokenManager.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title BiFi's marketManager contract
 * @notice Implement business logic and manage handlers
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract TokenManager is ManagerSlot {

	/**
	* @dev Constructor for marketManager
	* @param managerDataStorageAddr The address of the manager storage contract
	* @param oracleProxyAddr The address of oracle proxy contract (e.g., price feeds)
	* @param breaker The address of default circuit breaker
	* @param erc20Addr The address of reward token (ERC-20)
	*/
	constructor (address managerDataStorageAddr, address oracleProxyAddr, address _slotSetterAddr, address _handlerManagerAddr, address _flashloanAddr, address breaker, address erc20Addr) public
	{
		owner = msg.sender;
		dataStorageInstance = IManagerDataStorage(managerDataStorageAddr);
		oracleProxy = IOracleProxy(oracleProxyAddr);
		rewardErc20Instance = IERC20(erc20Addr);

		slotSetterAddr = _slotSetterAddr;
		handlerManagerAddr = _handlerManagerAddr;
		flashloanAddr = _flashloanAddr;

		breakerTable[owner].auth = true;
		breakerTable[breaker].auth = true;
	}

	/**
	* @dev Transfer ownership
	* @param _owner the address of the new owner
	* @return result the setter call in contextSetter contract
	*/
	function ownershipTransfer(address payable _owner) onlyOwner public returns (bool result) {
    bytes memory callData = abi.encodeWithSelector(
				IManagerSlotSetter
				.ownershipTransfer.selector,
				_owner
			);

    (result, ) = slotSetterAddr.delegatecall(callData);
    assert(result);
	}

	function setOperator(address payable adminAddr, bool flag) onlyOwner external returns (bool result) {
		bytes memory callData = abi.encodeWithSelector(
				IManagerSlotSetter
				.setOperator.selector,
				adminAddr, flag
			);

		(result, ) = slotSetterAddr.delegatecall(callData);
    assert(result);
	}

	/**
	* @dev Set the address of OracleProxy contract
	* @param oracleProxyAddr The address of OracleProxy contract
	* @return result the setter call in contextSetter contract
	*/
	function setOracleProxy(address oracleProxyAddr) onlyOwner external returns (bool result) {
    bytes memory callData = abi.encodeWithSelector(
				IManagerSlotSetter
				.setOracleProxy.selector,
				oracleProxyAddr
			);

		(result, ) = slotSetterAddr.delegatecall(callData);
    assert(result);
	}

	/**
	* @dev Set the address of BiFi reward token contract
	* @param erc20Addr The address of BiFi reward token contract
	* @return result the setter call in contextSetter contract
	*/
	function setRewardErc20(address erc20Addr) onlyOwner public returns (bool result) {
    bytes memory callData = abi.encodeWithSelector(
				IManagerSlotSetter
				.setRewardErc20.selector,
				erc20Addr
			);

		(result, ) = slotSetterAddr.delegatecall(callData);
    assert(result);
	}

	/**
	* @dev Authorize admin user for circuitBreaker
	* @param _target The address of the circuitBreaker admin user.
	* @param _status The boolean status of circuitBreaker (on/off)
	* @return result the setter call in contextSetter contract
	*/
	function setBreakerTable(address _target, bool _status) onlyOwner external returns (bool result) {
    bytes memory callData = abi.encodeWithSelector(
				IManagerSlotSetter
				.setBreakerTable.selector,
				_target, _status
			);

		(result, ) = slotSetterAddr.delegatecall(callData);
    assert(result);
	}

	/**
	* @dev Set circuitBreak to freeze/unfreeze all handlers
	* @param _emergency The boolean status of circuitBreaker (on/off)
	* @return result the setter call in contextSetter contract
	*/
	function setCircuitBreaker(bool _emergency) onlyBreaker external returns (bool result) {
		bytes memory callData = abi.encodeWithSelector(
				IManagerSlotSetter
				.setCircuitBreaker.selector,
				_emergency
			);

		(result, ) = slotSetterAddr.delegatecall(callData);
    assert(result);
	}

	function setSlotSetterAddr(address _slotSetterAddr) onlyOwner external returns (bool result) {
			bytes memory callData = abi.encodeWithSelector(
					IManagerSlotSetter.setSlotSetterAddr.selector,
					_slotSetterAddr
				);

			(result, ) = slotSetterAddr.delegatecall(callData);
		assert(result);
	}

	function sethandlerManagerAddr(address _handlerManagerAddr) onlyOwner external returns (bool result) {
			bytes memory callData = abi.encodeWithSelector(
					IManagerSlotSetter.sethandlerManagerAddr.selector,
					_handlerManagerAddr
				);

			(result, ) = slotSetterAddr.delegatecall(callData);
		assert(result);
	}

	function setFlashloanAddr(address _flashloanAddr) onlyOwner external returns (bool result) {
			bytes memory callData = abi.encodeWithSelector(
					IManagerSlotSetter.setFlashloanAddr.selector,
					_flashloanAddr
				);

			(result, ) = slotSetterAddr.delegatecall(callData);
		assert(result);
	}

	function setPositionStorageAddr(address _positionStorageAddr) onlyOwner external returns (bool result) {
			bytes memory callData = abi.encodeWithSelector(
					IManagerSlotSetter.setPositionStorageAddr.selector,
					_positionStorageAddr
				);

			(result, ) = slotSetterAddr.delegatecall(callData);
		assert(result);
	}

	function setNFTAddr(address _nftAddr) onlyOwner external returns (bool result) {
			bytes memory callData = abi.encodeWithSelector(
					IManagerSlotSetter.setNFTAddr.selector,
					_nftAddr
				);

			(result, ) = slotSetterAddr.delegatecall(callData);
		assert(result);
	}

	function setFlashloanFee(uint256 handlerID, uint256 flashFeeRate) onlyOwner external returns (bool result) {
			bytes memory callData = abi.encodeWithSelector(
					IManagerSlotSetter
					.setFlashloanFee.selector,
					handlerID,
			    	flashFeeRate
				);

			(result, ) = slotSetterAddr.delegatecall(callData);
		assert(result);
	}

	function setDiscountBase(uint256 handlerID, uint256 feeBase) onlyOwner external returns (bool result) {
			bytes memory callData = abi.encodeWithSelector(
					IManagerSlotSetter
					.setDiscountBase.selector,
					handlerID,
			    feeBase
				);

			(result, ) = slotSetterAddr.delegatecall(callData);
		assert(result);
	}

	/**
	* @dev Get the circuitBreak status
	* @return The circuitBreak status
	*/
	function getCircuitBreaker() external view returns (bool)
	{
		return emergency;
	}

	/**
	* @dev Get information for a handler
	* @param handlerID Handler ID
	* @return (success or failure, handler address, handler name)
	*/
	function getTokenHandlerInfo(uint256 handlerID) external view returns (bool, address, string memory)
	{
		bool support;
		address tokenHandlerAddr;
		string memory tokenName;
		if (dataStorageInstance.getTokenHandlerSupport(handlerID))
		{
			tokenHandlerAddr = dataStorageInstance.getTokenHandlerAddr(handlerID);
			IProxy TokenHandler = IProxy(tokenHandlerAddr);
			bytes memory data;
			(, data) = TokenHandler.handlerViewProxy(
				abi.encodeWithSelector(
					IMarketHandler
					.getTokenName.selector
				)
			);
			tokenName = abi.decode(data, (string));
			support = true;
		}

		return (support, tokenHandlerAddr, tokenName);
	}

	/**
	* @dev Register a handler
	* @param handlerID Handler ID and address
	* @param tokenHandlerAddr The handler address
	* @return result the setter call in contextSetter contract
	*/
	function handlerRegister(uint256 handlerID, address tokenHandlerAddr, uint256 flashFeeRate, uint256 discountBase) onlyOwner external returns (bool result) {
		bytes memory callData = abi.encodeWithSelector(
					IManagerSlotSetter
					.handlerRegister.selector,
					handlerID, tokenHandlerAddr, flashFeeRate, discountBase
				);

			(result, ) = slotSetterAddr.delegatecall(callData);
		assert(result);
	}
	/**
	* @dev Set a liquidation manager contract
	* @param liquidationManagerAddr The address of liquidiation manager
	* @return result the setter call in contextSetter contract
	*/
	function setLiquidationManager(address liquidationManagerAddr) onlyOwner external returns (bool result) {
    bytes memory callData = abi.encodeWithSelector(
				IManagerSlotSetter
				.setLiquidationManager.selector,
				liquidationManagerAddr
			);

		(result, ) = slotSetterAddr.delegatecall(callData);
    assert(result);
	}

	/**
	* @dev Update the (SI) rewards for a user
	* @param userAddr The address of the user
	* @param callerID The handler ID
	* @return true (TODO: validate results)
	*/
	function rewardUpdateOfInAction(address payable userAddr, uint256 callerID) external returns (bool)
	{
		ContractInfo memory handlerInfo;
		(handlerInfo.support, handlerInfo.addr) = dataStorageInstance.getTokenHandlerInfo(callerID);
		if (handlerInfo.support)
		{
			IProxy TokenHandler;
			TokenHandler = IProxy(handlerInfo.addr);
			TokenHandler.siProxy(
				abi.encodeWithSelector(
					IServiceIncentive
					.updateRewardLane.selector,
					userAddr
				)
			);
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
	function applyInterestHandlers(address payable userAddr, uint256 callerID, bool allFlag) external returns (uint256, uint256, uint256, uint256, uint256, uint256) {
    bytes memory callData = abi.encodeWithSelector(
				IHandlerManager
				.applyInterestHandlers.selector,
				userAddr, callerID, allFlag
			);

		(bool result, bytes memory returnData) = handlerManagerAddr.delegatecall(callData);
    assert(result);

    return abi.decode(returnData, (uint256, uint256, uint256, uint256, uint256, uint256));
  }

	/**
	* @dev Reward the user (msg.sender) with the reward token after calculating interest.
	* @return result the interestUpdateReward call in ManagerInterest contract
	*/
	function interestUpdateReward() external returns (bool result) {
		bytes memory callData = abi.encodeWithSelector(
				IHandlerManager
				.interestUpdateReward.selector
			);

		(result, ) = handlerManagerAddr.delegatecall(callData);
    	assert(result);
	}

	/**
	* @dev (Update operation) update the rewards parameters.
	* @param userAddr The address of operator
	* @return result the updateRewardParams call in ManagerInterest contract
	*/
	function updateRewardParams(address payable userAddr) onlyOperators external returns (bool result) {
		bytes memory callData = abi.encodeWithSelector(
				IHandlerManager
				.updateRewardParams.selector,
        userAddr
			);

		(result, ) = handlerManagerAddr.delegatecall(callData);
    assert(result);
	}

	/**
	* @dev Claim all rewards for the user
	* @param userAddr The user address
	* @return true (TODO: validate results)
	*/
	function rewardClaimAll(address payable userAddr) external returns (uint256)
	{
    bytes memory callData = abi.encodeWithSelector(
				IHandlerManager
				.rewardClaimAll.selector,
        userAddr
			);

		(bool result, bytes memory returnData) = handlerManagerAddr.delegatecall(callData);
    assert(result);

    return abi.decode(returnData, (uint256));
	}

	/**
	* @dev Claim handler rewards for the user
	* @param handlerID The ID of claim reward handler
	* @param userAddr The user address
	* @return true (TODO: validate results)
	*/
	function claimHandlerReward(uint256 handlerID, address payable userAddr) external returns (uint256) {
		bytes memory callData = abi.encodeWithSelector(
				IHandlerManager
				.claimHandlerReward.selector,
        handlerID, userAddr
			);

		(bool result, bytes memory returnData) = handlerManagerAddr.delegatecall(callData);
    assert(result);

    return abi.decode(returnData, (uint256));
	}

	/**
	* @dev Transfer reward tokens to owner (for administration)
	* @param _amount The amount of the reward token
	* @return result (TODO: validate results)
	*/
	function ownerRewardTransfer(uint256 _amount) onlyOwner external returns (bool result)
	{
		bytes memory callData = abi.encodeWithSelector(
				IHandlerManager
				.ownerRewardTransfer.selector,
        _amount
			);

		(result, ) = handlerManagerAddr.delegatecall(callData);
    assert(result);
	}


	/**
	* @dev Get the token price of the handler
	* @param handlerID The handler ID
	* @return The token price of the handler
	*/
	function getTokenHandlerPrice(uint256 handlerID) external view returns (uint256)
	{
		return _getTokenHandlerPrice(handlerID);
	}

	/**
	* @dev Get the margin call limit of the handler (external)
	* @param handlerID The handler ID
	* @return The margin call limit
	*/
	function getTokenHandlerMarginCallLimit(uint256 handlerID) external view returns (uint256)
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
		IProxy TokenHandler = IProxy(dataStorageInstance.getTokenHandlerAddr(handlerID));
		bytes memory data;
		(, data) = TokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				IMarketHandler
				.getTokenHandlerMarginCallLimit.selector
			)
		);
		return abi.decode(data, (uint256));
	}

	/**
	* @dev Get the borrow limit of the handler (external)
	* @param handlerID The handler ID
	* @return The borrow limit
	*/
	function getTokenHandlerBorrowLimit(uint256 handlerID) external view returns (uint256)
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
		IProxy TokenHandler = IProxy(dataStorageInstance.getTokenHandlerAddr(handlerID));

		bytes memory data;
		(, data) = TokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				IMarketHandler
				.getTokenHandlerBorrowLimit.selector
			)
		);
		return abi.decode(data, (uint256));
	}

	/**
	* @dev Get the handler status of whether the handler is supported or not.
	* @param handlerID The handler ID
	* @return Whether the handler is supported or not
	*/
	function getTokenHandlerSupport(uint256 handlerID) external view returns (bool)
	{
		return dataStorageInstance.getTokenHandlerSupport(handlerID);
	}

	/**
	* @dev Set the length of the handler list
	* @param _tokenHandlerLength The length of the handler list
	* @return true (TODO: validate results)
	*/
	function setTokenHandlersLength(uint256 _tokenHandlerLength) onlyOwner external returns (bool)
	{
		tokenHandlerLength = _tokenHandlerLength;
		return true;
	}

	/**
	* @dev Get the length of the handler list
	* @return the length of the handler list
	*/
	function getTokenHandlersLength() external view returns (uint256)
	{
		return tokenHandlerLength;
	}

	/**
	* @dev Get the handler ID at the index in the handler list
	* @param index The index of the handler list (array)
	* @return The handler ID
	*/
	function getTokenHandlerID(uint256 index) external view returns (uint256)
	{
		return dataStorageInstance.getTokenHandlerID(index);
	}

	/**
	* @dev Get the amount of token that the user can borrow more
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The amount of token that user can borrow more
	*/
	function getUserExtraLiquidityAmount(address payable userAddr, uint256 handlerID) external view returns (uint256)
	{
		return _getUserExtraLiquidityAmount(userAddr, handlerID);
	}

	/**
	* @dev Get the deposit and borrow amount of the user with interest added
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The deposit and borrow amount of the user with interest
	*/
	/* about user market Information function*/
	function getUserIntraHandlerAssetWithInterest(address payable userAddr, uint256 handlerID) external view returns (uint256, uint256)
	{
		return _getUserIntraHandlerAssetWithInterest(userAddr, handlerID);
	}

	/**
	* @dev Get the depositTotalCredit and borrowTotalCredit
	* @param userAddr The address of the user
	* @return depositTotalCredit The amount that users can borrow (i.e. deposit * borrowLimit)
	* @return borrowTotalCredit The sum of borrow amount for all handlers
	*/
	function getUserTotalIntraCreditAsset(address payable userAddr) external view returns (uint256, uint256)
	{
		return _getUserTotalIntraCreditAsset(userAddr);
	}

	/**
	* @dev Get the borrow and margin call limits of the user for all handlers
	* @param userAddr The address of the user
	* @return userTotalBorrowLimitAsset the sum of borrow limit for all handlers
	* @return userTotalMarginCallLimitAsset the sume of margin call limit for handlers
	*/
	function getUserLimitIntraAsset(address payable userAddr) external view returns (uint256, uint256)
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
	* @dev Get the maximum allowed amount to borrow of the user from the given handler
	* @param userAddr The address of the user
	* @param callerID The target handler to borrow
	* @return extraCollateralAmount The maximum allowed amount to borrow from
	  the handler.
	*/
	function getUserCollateralizableAmount(address payable userAddr, uint256 callerID) external view returns (uint256)
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
	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 liquidateHandlerID, uint256 rewardHandlerID) onlyLiquidationManager external returns (uint256, uint256, uint256)
	{
		address tokenHandlerAddr = dataStorageInstance.getTokenHandlerAddr(liquidateHandlerID);
		IProxy TokenHandler = IProxy(tokenHandlerAddr);
		bytes memory data;

		data = abi.encodeWithSelector(
			IMarketHandler
			.partialLiquidationUser.selector,

			delinquentBorrower,
			liquidateAmount,
			liquidator,
			rewardHandlerID
		);
		(, data) = TokenHandler.handlerProxy(data);

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
	function getMaxLiquidationReward(address payable delinquentBorrower, uint256 liquidateHandlerID, uint256 liquidateAmount, uint256 rewardHandlerID, uint256 rewardRatio) external view returns (uint256)
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
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 rewardAmount, address payable liquidator, uint256 handlerID) onlyLiquidationManager external returns (uint256)
	{
		address tokenHandlerAddr = dataStorageInstance.getTokenHandlerAddr(handlerID);
		IProxy TokenHandler = IProxy(tokenHandlerAddr);
		bytes memory data;
		data = abi.encodeWithSelector(
			IMarketHandler
			.partialLiquidationUserReward.selector,

			delinquentBorrower,
			rewardAmount,
			liquidator
		);
		(, data) = TokenHandler.handlerProxy(data);

		return abi.decode(data, (uint256));
	}

	/**
    * @dev Execute flashloan contract with delegatecall
    * @param handlerID The ID of the token handler to borrow.
    * @param receiverAddress The address of receive callback contract
    * @param amount The amount of borrow through flashloan
    * @param params The encode metadata of user
    * @return Whether or not succeed
    */
 	function flashloan(
      uint256 handlerID,
      address receiverAddress,
      uint256 amount,
      bytes calldata params
    ) external returns (bool) {
      bytes memory callData = abi.encodeWithSelector(
				IManagerFlashloan
				.flashloan.selector,
				handlerID, receiverAddress, amount, params
			);

      (bool result, bytes memory returnData) = flashloanAddr.delegatecall(callData);
      assert(result);

      return abi.decode(returnData, (bool));
    }

	/**
	* @dev Call flashloan logic contract with delegatecall
    * @param handlerID The ID of handler with accumulated flashloan fee
    * @return The amount of fee accumlated to handler
    */
 	function getFeeTotal(uint256 handlerID) external returns (uint256)
	{
		bytes memory callData = abi.encodeWithSelector(
				IManagerFlashloan
				.getFeeTotal.selector,
				handlerID
			);

		(bool result, bytes memory returnData) = flashloanAddr.delegatecall(callData);
		assert(result);

		return abi.decode(returnData, (uint256));
    }

	/**
    * @dev Withdraw accumulated flashloan fee with delegatecall
    * @param handlerID The ID of handler with accumulated flashloan fee
    * @return Whether or not succeed
    */
	function withdrawFlashloanFee(
      uint256 handlerID
    ) external onlyOwner returns (bool) {
    	bytes memory callData = abi.encodeWithSelector(
				IManagerFlashloan
				.withdrawFlashloanFee.selector,
				handlerID
			);

		(bool result, bytes memory returnData) = flashloanAddr.delegatecall(callData);
		assert(result);

		return abi.decode(returnData, (bool));
    }

  /**
    * @dev Get flashloan fee for flashloan amount before make product(BiFi-X)
    * @param handlerID The ID of handler with accumulated flashloan fee
    * @param amount The amount of flashloan amount
    * @param bifiAmount The amount of Bifi amount
    * @return The amount of fee for flashloan amount
    */
  function getFeeFromArguments(
      uint256 handlerID,
      uint256 amount,
      uint256 bifiAmount
    ) external returns (uint256) {
      bytes memory callData = abi.encodeWithSelector(
				IManagerFlashloan
				.getFeeFromArguments.selector,
				handlerID, amount, bifiAmount
			);

      (bool result, bytes memory returnData) = flashloanAddr.delegatecall(callData);
      assert(result);

      return abi.decode(returnData, (uint256));
    }

	/**
	* @dev Get the deposit and borrow amount of the user for the handler (internal)
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The deposit and borrow amount
	*/
	function _getHandlerAmount(address payable userAddr, uint256 handlerID) internal view returns (uint256, uint256)
	{
		IProxy TokenHandler = IProxy(dataStorageInstance.getTokenHandlerAddr(handlerID));
		bytes memory data;
		(, data) = TokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				IMarketHandler
				.getUserAmount.selector,
				userAddr
			)
		);
		return abi.decode(data, (uint256, uint256));
	}

  	/**
	* @dev Get the deposit and borrow amount with interest of the user for the handler (internal)
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The deposit and borrow amount with interest
	*/
	function _getHandlerAmountWithAmount(address payable userAddr, uint256 handlerID) internal view returns (uint256, uint256)
	{
		IProxy TokenHandler = IProxy(dataStorageInstance.getTokenHandlerAddr(handlerID));
		bytes memory data;
		(, data) = TokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				IMarketHandler
				.getUserAmountWithInterest.selector,
				userAddr
			)
		);
		return abi.decode(data, (uint256, uint256));
	}

	/**
	* @dev Set the support stauts for the handler
	* @param handlerID the handler ID
	* @param support the support status (boolean)
	* @return result the setter call in contextSetter contract
	*/
	function setHandlerSupport(uint256 handlerID, bool support) onlyOwner public returns (bool result) {
		bytes memory callData = abi.encodeWithSelector(
				IManagerSlotSetter
				.setHandlerSupport.selector,
				handlerID, support
			);

		(result, ) = slotSetterAddr.delegatecall(callData);
    assert(result);
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
	* @dev Get the deposit and borrow amount of the user with interest added
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The deposit and borrow amount of the user with interest
	*/
	function _getUserIntraHandlerAssetWithInterest(address payable userAddr, uint256 handlerID) internal view returns (uint256, uint256)
	{
		uint256 price = _getTokenHandlerPrice(handlerID);
		IProxy TokenHandler = IProxy(dataStorageInstance.getTokenHandlerAddr(handlerID));
		uint256 depositAmount;
		uint256 borrowAmount;

		bytes memory data;
		(, data) = TokenHandler.handlerViewProxy(
			abi.encodeWithSelector(
				IMarketHandler.getUserAmountWithInterest.selector,
				userAddr
			)
		);
		(depositAmount, borrowAmount) = abi.decode(data, (uint256, uint256));

		uint256 depositAsset = depositAmount.unifiedMul(price);
		uint256 borrowAsset = borrowAmount.unifiedMul(price);
		return (depositAsset, borrowAsset);
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
	* @dev Get the amount of token that the user can borrow more
	* @param userAddr The address of user
	* @param handlerID The handler ID
	* @return The amount of token that user can borrow more
	*/
  	function _getUserExtraLiquidityAmount(address payable userAddr, uint256 handlerID) internal view returns (uint256) {
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

	function getFeePercent(uint256 handlerID) external view returns (uint256)
	{
	return handlerFlashloan[handlerID].flashFeeRate;
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
	function getGlobalRewardInfo() external view returns (uint256, uint256, uint256)
	{
		IManagerDataStorage _dataStorage = dataStorageInstance;
		return (_dataStorage.getGlobalRewardPerBlock(), _dataStorage.getGlobalRewardDecrement(), _dataStorage.getGlobalRewardTotalAmount());
	}

	function setObserverAddr(address observerAddr) onlyOwner external returns (bool) {
		Observer = IObserver( observerAddr );
	}

	/**
	* @dev fallback function where handler can receive native coin
	*/
	fallback () external payable
	{

	}
}