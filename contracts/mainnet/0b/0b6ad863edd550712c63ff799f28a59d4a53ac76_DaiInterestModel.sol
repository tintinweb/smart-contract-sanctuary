/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// File: contracts/interfaces/interestModelInterface.sol

pragma solidity 0.6.12;

interface interestModelInterface {
	function getInterestAmount(address handlerDataStorageAddr, address payable userAddr, bool isView) external view returns (bool, uint256, uint256, bool, uint256, uint256);
	function viewInterestAmount(address handlerDataStorageAddr, address payable userAddr) external view returns (bool, uint256, uint256, bool, uint256, uint256);
	function getSIRandBIR(uint256 depositTotalAmount, uint256 borrowTotalAmount) external view returns (uint256, uint256);
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

// File: contracts/interestModel/interestModel.sol

pragma solidity 0.6.12;

 /**
  * @title Bifi interestModel Contract
  * @notice Contract for interestModel
  * @author Bifi
  */
contract interestModel is interestModelInterface, InterestErrors {
	using SafeMath for uint256;

	address owner;
	mapping(address => bool) public operators;

	uint256 constant blocksPerYear = 2102400;
	uint256 constant unifiedPoint = 10 ** 18;

	uint256 minRate;
	uint256 basicSensitivity;

	/* jump rate model prams */
	uint256 jumpPoint;
	uint256 jumpSensitivity;

	uint256 spreadRate;

	struct InterestUpdateModel {
		uint256 SIR;
		uint256 BIR;
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		uint256 userDepositAmount;
		uint256 userBorrowAmount;
		uint256 deltaDepositAmount;
		uint256 deltaBorrowAmount;
		uint256 globalDepositEXR;
		uint256 globalBorrowEXR;
		uint256 userDepositEXR;
		uint256 userBorrowEXR;
		uint256 actionDepositEXR;
		uint256 actionBorrowEXR;
		uint256 deltaDepositEXR;
		uint256 deltaBorrowEXR;
		bool depositNegativeFlag;
		bool borrowNegativeFlag;
	}

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlyOperator {
		address sender = msg.sender;
		require(operators[sender] || sender == owner, "Only Operators");
		_;
	}

	/**
	* @dev Construct a new interestModel contract
	* @param _minRate minimum interest rate
	* @param _jumpPoint Threshold of utilizationRate to which normal interest model
	* @param _basicSensitivity liquidity basicSensitivity
	* @param _jumpSensitivity The value used to calculate the BIR if the utilizationRate is greater than the jumpPoint.
	* @param _spreadRate spread rate
	*/
	constructor (uint256 _minRate, uint256 _jumpPoint, uint256 _basicSensitivity, uint256 _jumpSensitivity, uint256 _spreadRate) public
	{
		address sender = msg.sender;
		owner = sender;
		operators[owner] = true;

		minRate = _minRate;
		basicSensitivity = _basicSensitivity;

		jumpPoint = _jumpPoint;
		jumpSensitivity = _jumpSensitivity;

		spreadRate = _spreadRate;
	}

	/**
	* @dev Replace the owner of the handler
	* @param _owner the address of the new owner
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address payable _owner) onlyOwner external returns (bool)
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
	* @dev set Operator or not
	* @param _operator the address of the operator
	* @param flag operator permission
	* @return true (TODO: validate results)
	*/
	function setOperators(address payable _operator, bool flag) onlyOwner external returns (bool) {
		operators[_operator] = flag;
		return true;
	}

	/**
	 * @dev Calculates interest amount for a user
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param userAddr The address of user
	 * @param isView Select _view (before action) or _get (after action) function for calculation
	 * @return (bool, uint256, uint256, bool, uint256, uint256)
	 */
	function getInterestAmount(address handlerDataStorageAddr, address payable userAddr, bool isView) external view override returns (bool, uint256, uint256, bool, uint256, uint256)
	{
		if (isView)
		{
			return _viewInterestAmount(handlerDataStorageAddr, userAddr);
		}
		else
		{
			return _getInterestAmount(handlerDataStorageAddr, userAddr);
		}
	}

	/**
	 * @dev Calculates interest amount for a user (before user action)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param userAddr The address of user
	 * @return (bool, uint256, uint256, bool, uint256, uint256)
	 */
	function viewInterestAmount(address handlerDataStorageAddr, address payable userAddr) external view override returns (bool, uint256, uint256, bool, uint256, uint256)
	{
		return _viewInterestAmount(handlerDataStorageAddr, userAddr);
	}

	/**
	 * @dev Get Supply Interest Rate (SIR) and Borrow Interest Rate (BIR) (external)
	 * @param totalDepositAmount The amount of total deposit
	 * @param totalBorrowAmount The amount of total borrow
	 * @return (uint256, uin256)
	 */
	function getSIRandBIR(uint256 totalDepositAmount, uint256 totalBorrowAmount) external view override returns (uint256, uint256)
	{
		return _getSIRandBIR(totalDepositAmount, totalBorrowAmount);
	}

	/**
	 * @dev Calculates interest amount for a user (after user action)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param userAddr The address of user
	 * @return (bool, uint256, uint256, bool, uint256, uint256)
	 */
	function _getInterestAmount(address handlerDataStorageAddr, address payable userAddr) internal view returns (bool, uint256, uint256, bool, uint256, uint256)
	{
		marketHandlerDataStorageInterface handlerDataStorage = marketHandlerDataStorageInterface(handlerDataStorageAddr);
		uint256 delta = handlerDataStorage.getInactiveActionDelta();
		uint256 actionDepositEXR;
		uint256 actionBorrowEXR;
		(actionDepositEXR, actionBorrowEXR) = handlerDataStorage.getActionEXR();
		return _calcInterestAmount(handlerDataStorageAddr, userAddr, delta, actionDepositEXR, actionBorrowEXR);
	}

	/**
	 * @dev Calculates interest amount for a user (before user action)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param userAddr The address of user
	 * @return (bool, uint256, uint256, bool, uint256, uint256)
	 */
	function _viewInterestAmount(address handlerDataStorageAddr, address payable userAddr) internal view returns (bool, uint256, uint256, bool, uint256, uint256)
	{
		marketHandlerDataStorageInterface handlerDataStorage = marketHandlerDataStorageInterface(handlerDataStorageAddr);
		uint256 blockDelta = block.number.sub(handlerDataStorage.getLastUpdatedBlock());
		/* check action in block */
		uint256 globalDepositEXR;
		uint256 globalBorrowEXR;
		(globalDepositEXR, globalBorrowEXR) = handlerDataStorage.getGlobalEXR();
		return _calcInterestAmount(handlerDataStorageAddr, userAddr, blockDelta, globalDepositEXR, globalBorrowEXR);
	}

	/**
	 * @dev Calculate interest amount for a user with BIR and SIR (interal)
	 * @param handlerDataStorageAddr The address of handlerDataStorage contract
	 * @param userAddr The address of user
	 * @return (bool, uint256, uint256, bool, uint256, uint256)
	 */
	function _calcInterestAmount(address handlerDataStorageAddr, address payable userAddr, uint256 delta, uint256 actionDepositEXR, uint256 actionBorrowEXR) internal view returns (bool, uint256, uint256, bool, uint256, uint256)
	{
		InterestUpdateModel memory interestUpdateModel;
		marketHandlerDataStorageInterface handlerDataStorage = marketHandlerDataStorageInterface(handlerDataStorageAddr);
		(interestUpdateModel.depositTotalAmount, interestUpdateModel.borrowTotalAmount, interestUpdateModel.userDepositAmount, interestUpdateModel.userBorrowAmount) = handlerDataStorage.getAmount(userAddr);
		(interestUpdateModel.SIR, interestUpdateModel.BIR) = _getSIRandBIRonBlock(interestUpdateModel.depositTotalAmount, interestUpdateModel.borrowTotalAmount);
		(interestUpdateModel.userDepositEXR, interestUpdateModel.userBorrowEXR) = handlerDataStorage.getUserEXR(userAddr);

		/* deposit start */
		interestUpdateModel.globalDepositEXR = _getNewGlobalEXR(actionDepositEXR, interestUpdateModel.SIR, delta);
		(interestUpdateModel.depositNegativeFlag, interestUpdateModel.deltaDepositAmount) = _getDeltaAmount(interestUpdateModel.userDepositAmount, interestUpdateModel.globalDepositEXR, interestUpdateModel.userDepositEXR);
		/* deposit done */

		/* borrow start */
		interestUpdateModel.globalBorrowEXR = _getNewGlobalEXR(actionBorrowEXR, interestUpdateModel.BIR, delta);
		(interestUpdateModel.borrowNegativeFlag, interestUpdateModel.deltaBorrowAmount) = _getDeltaAmount(interestUpdateModel.userBorrowAmount, interestUpdateModel.globalBorrowEXR, interestUpdateModel.userBorrowEXR);
		/* borrow done */

		return (interestUpdateModel.depositNegativeFlag, interestUpdateModel.deltaDepositAmount, interestUpdateModel.globalDepositEXR, interestUpdateModel.borrowNegativeFlag, interestUpdateModel.deltaBorrowAmount, interestUpdateModel.globalBorrowEXR);
	}

	/**
	 * @dev Calculates the utilization rate of market
	 * @param depositTotalAmount The total amount of deposit
	 * @param borrowTotalAmount The total amount of borrow
	 * @return The utilitization rate of market
	 */
	function _getUtilizationRate(uint256 depositTotalAmount, uint256 borrowTotalAmount) internal pure returns (uint256)
	{
		if ((depositTotalAmount == 0) && (borrowTotalAmount == 0))
		{
			return 0;
		}

		return borrowTotalAmount.unifiedDiv(depositTotalAmount);
	}

	/**
	 * @dev Get SIR and BIR (internal)
	 * @param depositTotalAmount The amount of total deposit
	 * @param borrowTotalAmount The amount of total borrow
	 * @return (uint256, uin256)
	 */
	function _getSIRandBIR(uint256 depositTotalAmount, uint256 borrowTotalAmount) internal view returns (uint256, uint256)
	// TODO: update comment(jump rate)
	{
		/* UtilRate = TotalBorrow / (TotalDeposit + TotalBorrow) */
		uint256 utilRate = _getUtilizationRate(depositTotalAmount, borrowTotalAmount);
		uint256 BIR;
		uint256 _jmpPoint = jumpPoint;
		/* BIR = minimumRate + (UtilRate * liquiditySensitivity) */
		if(utilRate < _jmpPoint) {
			BIR = utilRate.unifiedMul(basicSensitivity).add(minRate);
		} else {
      /*
      Formula : BIR = minRate + jumpPoint * basicSensitivity + (utilRate - jumpPoint) * jumpSensitivity

			uint256 _baseBIR = _jmpPoint.unifiedMul(basicSensitivity);
			uint256 _jumpBIR = utilRate.sub(_jmpPoint).unifiedMul(jumpSensitivity);
			BIR = minRate.add(_baseBIR).add(_jumpBIR);
      */
      BIR = minRate
      .add( _jmpPoint.unifiedMul(basicSensitivity) )
      .add( utilRate.sub(_jmpPoint).unifiedMul(jumpSensitivity) );
		}

		/* SIR = UtilRate * BIR */
		uint256 SIR = utilRate.unifiedMul(BIR).unifiedMul(spreadRate);
		return (SIR, BIR);
	}

	/**
	 * @dev Get SIR and BIR per block (internal)
	 * @param depositTotalAmount The amount of total deposit
	 * @param borrowTotalAmount The amount of total borrow
	 * @return (uint256, uin256)
	 */
	function _getSIRandBIRonBlock(uint256 depositTotalAmount, uint256 borrowTotalAmount) internal view returns (uint256, uint256)
	{
		uint256 SIR;
		uint256 BIR;
		(SIR, BIR) = _getSIRandBIR(depositTotalAmount, borrowTotalAmount);
		return ( SIR.div(blocksPerYear), BIR.div(blocksPerYear) );
	}

	/**
	 * @dev Calculates the rate of globalEXR (for borrowEXR or depositEXR)
	 * @param actionEXR The rate of actionEXR
	 * @param interestRate The rate of interest
	 * @param delta The interval between user actions (in block)
	 * @return The amount of newGlobalEXR
	 */
	function _getNewGlobalEXR(uint256 actionEXR, uint256 interestRate, uint256 delta) internal pure returns (uint256)
	{
		return interestRate.mul(delta).add(unifiedPoint).unifiedMul(actionEXR);
	}

	/**
	 * @dev Calculates difference between globalEXR and userEXR
	 * @param unifiedAmount The unifiedAmount (for fixed decimal number)
	 * @param globalEXR The amount of globalEXR
	 * @param userEXR The amount of userEXR
	 * @return (bool, uint256)
	 */
	function _getDeltaAmount(uint256 unifiedAmount, uint256 globalEXR, uint256 userEXR) internal pure returns (bool, uint256)
	{
		uint256 deltaEXR;
		bool negativeFlag;
		uint256 deltaAmount;
		if (unifiedAmount != 0)
		{
			(negativeFlag, deltaEXR) = _getDeltaEXR(globalEXR, userEXR);
			deltaAmount = unifiedAmount.unifiedMul(deltaEXR);
		}

		return (negativeFlag, deltaAmount);
	}

	/**
	 * @dev Calculates the delta EXR between globalEXR and userEXR
	 * @param newGlobalEXR The new globalEXR
	 * @param lastUserEXR The last userEXR
	 * @return (bool, uint256)
	 */
	function _getDeltaEXR(uint256 newGlobalEXR, uint256 lastUserEXR) internal pure returns (bool, uint256)
	{
		uint256 EXR = newGlobalEXR.unifiedDiv(lastUserEXR);
		if (EXR >= unifiedPoint)
		{
			return ( false, EXR.sub(unifiedPoint) );
		}

		return ( true, unifiedPoint.sub(EXR) );
	}
	//TODO: Need comment
	function getMinRate() external view returns (uint256) {
		return minRate;
	}

	function setMinRate(uint256 _minRate) external onlyOperator returns (bool) {
		minRate = _minRate;
		return true;
	}

	function getBasicSensitivity() external view returns (uint256) {
		return basicSensitivity;
	}

	function setBasicSensitivity(uint256 _sensitivity) external onlyOperator returns (bool) {
		basicSensitivity = _sensitivity;
		return true;
	}

	function getJumpPoint() external view returns (uint256) {
		return jumpPoint;
	}

	function setJumpPoint(uint256 _jumpPoint) external onlyOperator returns (bool) {
		jumpPoint = _jumpPoint;
		return true;
	}

	function getJumpSensitivity() external view returns (uint256) {
		return jumpSensitivity;
	}

	function setJumpSensitivity(uint256 _sensitivity) external onlyOperator returns (bool) {
		jumpSensitivity = _sensitivity;
		return true;
	}

	function getSpreadRate() external view returns (uint256) {
		return spreadRate;
	}

	function setSpreadRate(uint256 _spreadRate) external onlyOperator returns (bool) {
		spreadRate = _spreadRate;
		return true;
	}
}

// File: contracts/truffleKit/InterestModel.sol

pragma solidity 0.6.12;

contract DaiInterestModel is interestModel {
    constructor(
        uint256 _minRate,
        uint256 _jumpPoint,
        uint256 _basicSensitivity,
        uint256 _jumpSensitivity,
        uint256 _spreadRate
    )
    interestModel(
        _minRate,
        _jumpPoint,
        _basicSensitivity,
        _jumpSensitivity,
        _spreadRate
    ) public {}
}