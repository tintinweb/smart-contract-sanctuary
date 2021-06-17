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

// File: contracts/marketManager/ManagerSlotSetter.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title BiFi's ManagetSlotSetter contract
 * @notice Manager Slot Storage setter logics
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract ManagerSlotSetter is ManagerSlot {
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

	function setOperator(address payable adminAddr, bool flag) onlyOwner external returns (bool) {
		operators[adminAddr] = flag;
		return flag;
	}

	/**
	* @dev Set the address of oracleProxy contract
	* @param oracleProxyAddr The address of oracleProxy contract
	* @return true (TODO: validate results)
	*/
	function setOracleProxy(address oracleProxyAddr) onlyOwner external returns (bool)
	{
		oracleProxy = IOracleProxy(oracleProxyAddr);
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
	function setBreakerTable(address _target, bool _status) onlyOwner external returns (bool)
	{
		breakerTable[_target].auth = _status;
		return true;
	}

	/**
	* @dev Set circuitBreak to freeze/unfreeze all handlers
	* @param _emergency The boolean status of circuitBreaker (on/off)
	* @return true (TODO: validate results)
	*/
	function setCircuitBreaker(bool _emergency) onlyBreaker external returns (bool)
	{
		for (uint256 handlerID = 0; handlerID < tokenHandlerLength; handlerID++)
		{
			IProxy tokenHandler = IProxy(dataStorageInstance.getTokenHandlerAddr(handlerID));

			// use delegate call via handler proxy
			// for token handlers
			bytes memory callData = abi.encodeWithSelector(
				IMarketHandler
				.setCircuitBreaker.selector,
				_emergency
			);

			tokenHandler.handlerProxy(callData);
			tokenHandler.siProxy(callData);
		}

		ILiquidationManager liquidationManager = ILiquidationManager(dataStorageInstance.getLiquidationManagerAddr());
		liquidationManager.setCircuitBreaker(_emergency);
		emergency = _emergency;
		return true;
	}

  /**
	* @dev Register a handler
	* @param handlerID Handler ID and address
	* @param tokenHandlerAddr The handler address
  * @param discountBase The minimum amount hold to get a flashloan fee discount
	* @return true (TODO: validate results)
	*/
	function handlerRegister(uint256 handlerID, address tokenHandlerAddr, uint256 flashFeeRate, uint256 discountBase) onlyOwner external returns (bool)
	{
		dataStorageInstance.setTokenHandler(handlerID, tokenHandlerAddr);
		handlerFlashloan[handlerID].flashFeeRate = flashFeeRate;
    handlerFlashloan[handlerID].discountBase = discountBase;

		tokenHandlerLength = tokenHandlerLength + 1;
		return true;
	}

	/**
	* @dev Set a liquidation manager contract
	* @param liquidationManagerAddr The address of liquidiation manager
	* @return true (TODO: validate results)
	*/
	function setLiquidationManager(address liquidationManagerAddr) onlyOwner external returns (bool)
	{
		dataStorageInstance.setLiquidationManagerAddr(liquidationManagerAddr);
		return true;
	}

  /**
	* @dev Set the support stauts for the handler
	* @param handlerID the handler ID
	* @param support the support status (boolean)
	* @return true (TODO: validate results)
	*/
	function setHandlerSupport(uint256 handlerID, bool support) onlyOwner external returns (bool)
	{
		require(!dataStorageInstance.getTokenHandlerExist(handlerID), UNSUPPORTED_TOKEN);
		/* activate or inactivate anyway*/
		dataStorageInstance.setTokenHandlerSupport(handlerID, support);
		return true;
	}

  function setSlotSetterAddr(address _slotSetterAddr) onlyOwner external returns (bool)
  {
    slotSetterAddr = _slotSetterAddr;
    return true;
  }

  function sethandlerManagerAddr(address _handlerManagerAddr) onlyOwner external returns (bool)
  {
    handlerManagerAddr = _handlerManagerAddr;
    return true;
  }

  function setFlashloanAddr(address _flashloanAddr) onlyOwner external returns (bool)
  {
    flashloanAddr = _flashloanAddr;
    return true;
  }

  function setPositionStorageAddr(address _positionStorageAddr) onlyOwner external returns (bool) {
    positionStorageAddr = _positionStorageAddr;
    return true;
  }

  function setNFTAddr(address _nftAddr) onlyOwner external returns (bool) {
    nftAddr = _nftAddr;
    return true;
  }

  function setFlashloanFee(uint256 handlerID, uint256 flashFeeRate) onlyOwner external returns (bool) {
    handlerFlashloan[handlerID].flashFeeRate = flashFeeRate;
    return true;
  }

  function setDiscountBase(uint256 handlerID, uint256 feeBase) onlyOwner external returns (bool) {
    handlerFlashloan[handlerID].discountBase = feeBase;
  }
}