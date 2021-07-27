/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// Sources flattened with hardhat v2.4.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


// File @sygnum/solidity-base-contracts/contracts/role/interface/[email protected]

/**
 * @title ITraderOperators
 * @notice Interface for TraderOperators contract
 */

pragma solidity 0.5.12;

contract ITraderOperators {
    function isTrader(address _account) external view returns (bool);

    function addTrader(address _account) external;

    function removeTrader(address _account) external;
}


// File @sygnum/solidity-base-contracts/contracts/role/interface/[email protected]

/**
 * @title IBaseOperators
 * @notice Interface for BaseOperators contract
 */

pragma solidity 0.5.12;

interface IBaseOperators {
    function isOperator(address _account) external view returns (bool);

    function isAdmin(address _account) external view returns (bool);

    function isSystem(address _account) external view returns (bool);

    function isRelay(address _account) external view returns (bool);

    function isMultisig(address _contract) external view returns (bool);

    function confirmFor(address _address) external;

    function addOperator(address _account) external;

    function removeOperator(address _account) external;

    function addAdmin(address _account) external;

    function removeAdmin(address _account) external;

    function addSystem(address _account) external;

    function removeSystem(address _account) external;

    function addRelay(address _account) external;

    function removeRelay(address _account) external;

    function addOperatorAndAdmin(address _account) external;

    function removeOperatorAndAdmin(address _account) external;
}


// File @sygnum/solidity-base-contracts/contracts/helpers/[email protected]

pragma solidity 0.5.12;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Initializable: Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        // solhint-disable-next-line
        assembly {
            cs := extcodesize(address)
        }
        return cs == 0;
    }

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


// File @sygnum/solidity-base-contracts/contracts/role/base/[email protected]

/**
 * @title Operatorable
 * @author Team 3301 <[email protected]>
 * @dev Operatorable contract stores the BaseOperators contract address, and modifiers for
 *       contracts.
 */

pragma solidity 0.5.12;


contract Operatorable is Initializable {
    IBaseOperators internal operatorsInst;
    address private operatorsPending;

    event OperatorsContractChanged(address indexed caller, address indexed operatorsAddress);
    event OperatorsContractPending(address indexed caller, address indexed operatorsAddress);

    /**
     * @dev Reverts if sender does not have operator role associated.
     */
    modifier onlyOperator() {
        require(isOperator(msg.sender), "Operatorable: caller does not have the operator role");
        _;
    }

    /**
     * @dev Reverts if sender does not have admin role associated.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Operatorable: caller does not have the admin role");
        _;
    }

    /**
     * @dev Reverts if sender does not have system role associated.
     */
    modifier onlySystem() {
        require(isSystem(msg.sender), "Operatorable: caller does not have the system role");
        _;
    }

    /**
     * @dev Reverts if sender does not have multisig privileges.
     */
    modifier onlyMultisig() {
        require(isMultisig(msg.sender), "Operatorable: caller does not have multisig role");
        _;
    }

    /**
     * @dev Reverts if sender does not have admin or system role associated.
     */
    modifier onlyAdminOrSystem() {
        require(isAdminOrSystem(msg.sender), "Operatorable: caller does not have the admin role nor system");
        _;
    }

    /**
     * @dev Reverts if sender does not have operator or system role associated.
     */
    modifier onlyOperatorOrSystem() {
        require(isOperatorOrSystem(msg.sender), "Operatorable: caller does not have the operator role nor system");
        _;
    }

    /**
     * @dev Reverts if sender does not have the relay role associated.
     */
    modifier onlyRelay() {
        require(isRelay(msg.sender), "Operatorable: caller does not have relay role associated");
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or operator role associated.
     */
    modifier onlyOperatorOrRelay() {
        require(
            isOperator(msg.sender) || isRelay(msg.sender),
            "Operatorable: caller does not have the operator role nor relay"
        );
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or admin role associated.
     */
    modifier onlyAdminOrRelay() {
        require(
            isAdmin(msg.sender) || isRelay(msg.sender),
            "Operatorable: caller does not have the admin role nor relay"
        );
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or system, or relay role associated.
     */
    modifier onlyOperatorOrSystemOrRelay() {
        require(
            isOperator(msg.sender) || isSystem(msg.sender) || isRelay(msg.sender),
            "Operatorable: caller does not have the operator role nor system nor relay"
        );
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setOperatorsContract function can be called only by Admin role with
     *       confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators) public initializer {
        _setOperatorsContract(_baseOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     *       where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *       broken and control of the contract can be lost in such case
     * @param _baseOperators BaseOperators contract address.
     */
    function setOperatorsContract(address _baseOperators) public onlyAdmin {
        require(_baseOperators != address(0), "Operatorable: address of new operators contract can not be zero");
        operatorsPending = _baseOperators;
        emit OperatorsContractPending(msg.sender, _baseOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to ensure that operatorsPending address
     *       is the real contract address.
     */
    function confirmOperatorsContract() public {
        require(operatorsPending != address(0), "Operatorable: address of new operators contract can not be zero");
        require(msg.sender == operatorsPending, "Operatorable: should be called from new operators contract");
        _setOperatorsContract(operatorsPending);
    }

    /**
     * @return The address of the BaseOperators contract.
     */
    function getOperatorsContract() public view returns (address) {
        return address(operatorsInst);
    }

    /**
     * @return The pending address of the BaseOperators contract.
     */
    function getOperatorsPending() public view returns (address) {
        return operatorsPending;
    }

    /**
     * @return If '_account' has operator privileges.
     */
    function isOperator(address _account) public view returns (bool) {
        return operatorsInst.isOperator(_account);
    }

    /**
     * @return If '_account' has admin privileges.
     */
    function isAdmin(address _account) public view returns (bool) {
        return operatorsInst.isAdmin(_account);
    }

    /**
     * @return If '_account' has system privileges.
     */
    function isSystem(address _account) public view returns (bool) {
        return operatorsInst.isSystem(_account);
    }

    /**
     * @return If '_account' has relay privileges.
     */
    function isRelay(address _account) public view returns (bool) {
        return operatorsInst.isRelay(_account);
    }

    /**
     * @return If '_contract' has multisig privileges.
     */
    function isMultisig(address _contract) public view returns (bool) {
        return operatorsInst.isMultisig(_contract);
    }

    /**
     * @return If '_account' has admin or system privileges.
     */
    function isAdminOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isAdmin(_account) || operatorsInst.isSystem(_account));
    }

    /**
     * @return If '_account' has operator or system privileges.
     */
    function isOperatorOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isOperator(_account) || operatorsInst.isSystem(_account));
    }

    /** INTERNAL FUNCTIONS */
    function _setOperatorsContract(address _baseOperators) internal {
        require(_baseOperators != address(0), "Operatorable: address of new operators contract cannot be zero");
        operatorsInst = IBaseOperators(_baseOperators);
        emit OperatorsContractChanged(msg.sender, _baseOperators);
    }
}


// File @sygnum/solidity-base-contracts/contracts/role/trader/[email protected]

/**
 * @title TraderOperatorable
 * @author Team 3301 <[email protected]>
 * @dev TraderOperatorable contract stores TraderOperators contract address, and modifiers for
 *      contracts.
 */

pragma solidity 0.5.12;



contract TraderOperatorable is Operatorable {
    ITraderOperators internal traderOperatorsInst;
    address private traderOperatorsPending;

    event TraderOperatorsContractChanged(address indexed caller, address indexed traderOperatorsAddress);
    event TraderOperatorsContractPending(address indexed caller, address indexed traderOperatorsAddress);

    /**
     * @dev Reverts if sender does not have the trader role associated.
     */
    modifier onlyTrader() {
        require(isTrader(msg.sender), "TraderOperatorable: caller is not trader");
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator or trader role associated.
     */
    modifier onlyOperatorOrTraderOrSystem() {
        require(
            isOperator(msg.sender) || isTrader(msg.sender) || isSystem(msg.sender),
            "TraderOperatorable: caller is not trader or operator or system"
        );
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setTradersOperatorsContract function can be called only by Admin role with
     * confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     * @param _traderOperators TraderOperators contract address.
     */
    function initialize(address _baseOperators, address _traderOperators) public initializer {
        super.initialize(_baseOperators);
        _setTraderOperatorsContract(_traderOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     * where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     * broken and control of the contract can be lost in such case
     * @param _traderOperators TradeOperators contract address.
     */
    function setTraderOperatorsContract(address _traderOperators) public onlyAdmin {
        require(
            _traderOperators != address(0),
            "TraderOperatorable: address of new traderOperators contract can not be zero"
        );
        traderOperatorsPending = _traderOperators;
        emit TraderOperatorsContractPending(msg.sender, _traderOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to insure that traderOperatorsPending address
     *       is the real contract address.
     */
    function confirmTraderOperatorsContract() public {
        require(
            traderOperatorsPending != address(0),
            "TraderOperatorable: address of pending traderOperators contract can not be zero"
        );
        require(
            msg.sender == traderOperatorsPending,
            "TraderOperatorable: should be called from new traderOperators contract"
        );
        _setTraderOperatorsContract(traderOperatorsPending);
    }

    /**
     * @return The address of the TraderOperators contract.
     */
    function getTraderOperatorsContract() public view returns (address) {
        return address(traderOperatorsInst);
    }

    /**
     * @return The pending TraderOperators contract address
     */
    function getTraderOperatorsPending() public view returns (address) {
        return traderOperatorsPending;
    }

    /**
     * @return If '_account' has trader privileges.
     */
    function isTrader(address _account) public view returns (bool) {
        return traderOperatorsInst.isTrader(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setTraderOperatorsContract(address _traderOperators) internal {
        require(
            _traderOperators != address(0),
            "TraderOperatorable: address of new traderOperators contract can not be zero"
        );
        traderOperatorsInst = ITraderOperators(_traderOperators);
        emit TraderOperatorsContractChanged(msg.sender, _traderOperators);
    }
}


// File @sygnum/solidity-base-contracts/contracts/helpers/[email protected]

/**
 * @title Pausable
 * @author Team 3301 <[email protected]>
 * @dev Contract module which allows children to implement an emergency stop
 *      mechanism that can be triggered by an authorized account in the TraderOperatorable
 *      contract.
 */
pragma solidity 0.5.12;

contract Pausable is TraderOperatorable {
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    bool internal _paused;

    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by operator to pause child contract. The contract
     *      must not already be paused.
     */
    function pause() public onlyOperatorOrTraderOrSystem whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /** @dev Called by operator to pause child contract. The contract
     *       must already be paused.
     */
    function unpause() public onlyOperatorOrTraderOrSystem whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @return If child contract is already paused or not.
     */
    function isPaused() public view returns (bool) {
        return _paused;
    }

    /**
     * @return If child contract is not paused.
     */
    function isNotPaused() public view returns (bool) {
        return !_paused;
    }
}


// File @sygnum/solidity-base-contracts/contracts/role/interface/[email protected]

/**
 * @title IRaiseOperators
 * @notice Interface for RaiseOperators contract
 */

pragma solidity 0.5.12;

contract IRaiseOperators {
    function isInvestor(address _account) external view returns (bool);

    function isIssuer(address _account) external view returns (bool);

    function addInvestor(address _account) external;

    function removeInvestor(address _account) external;

    function addIssuer(address _account) external;

    function removeIssuer(address _account) external;
}


// File @sygnum/solidity-base-contracts/contracts/role/raise/[email protected]

/**
 * @title RaiseOperatorable
 * @author Team 3301 <[email protected]>
 * @dev RaiseOperatorable contract stores RaiseOperators contract address, and modifiers for
 *      contracts.
 */

pragma solidity 0.5.12;



contract RaiseOperatorable is Operatorable {
    IRaiseOperators internal raiseOperatorsInst;
    address private raiseOperatorsPending;

    event RaiseOperatorsContractChanged(address indexed caller, address indexed raiseOperatorsAddress);
    event RaiseOperatorsContractPending(address indexed caller, address indexed raiseOperatorsAddress);

    /**
     * @dev Reverts if sender does not have the investor role associated.
     */
    modifier onlyInvestor() {
        require(isInvestor(msg.sender), "RaiseOperatorable: caller is not investor");
        _;
    }

    /**
     * @dev Reverts if sender does not have the issuer role associated.
     */
    modifier onlyIssuer() {
        require(isIssuer(msg.sender), "RaiseOperatorable: caller is not issuer");
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setOperatorsContract function can be called only by Admin role with
     * confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators, address _raiseOperators) public initializer {
        super.initialize(_baseOperators);
        _setRaiseOperatorsContract(_raiseOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     * where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *broken and control of the contract can be lost in such case
     * @param _raiseOperators RaiseOperators contract address.
     */
    function setRaiseOperatorsContract(address _raiseOperators) public onlyAdmin {
        require(
            _raiseOperators != address(0),
            "RaiseOperatorable: address of new raiseOperators contract can not be zero"
        );
        raiseOperatorsPending = _raiseOperators;
        emit RaiseOperatorsContractPending(msg.sender, _raiseOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to insure that operatorsPending address
     *       is the real contract address.
     */
    function confirmRaiseOperatorsContract() public {
        require(
            raiseOperatorsPending != address(0),
            "RaiseOperatorable: address of pending raiseOperators contract can not be zero"
        );
        require(
            msg.sender == raiseOperatorsPending,
            "RaiseOperatorable: should be called from new raiseOperators contract"
        );
        _setRaiseOperatorsContract(raiseOperatorsPending);
    }

    /**
     * @return The address of the RaiseOperators contract.
     */
    function getRaiseOperatorsContract() public view returns (address) {
        return address(raiseOperatorsInst);
    }

    /**
     * @return The pending RaiseOperators contract address
     */
    function getRaiseOperatorsPending() public view returns (address) {
        return raiseOperatorsPending;
    }

    /**
     * @return If '_account' has investor privileges.
     */
    function isInvestor(address _account) public view returns (bool) {
        return raiseOperatorsInst.isInvestor(_account);
    }

    /**
     * @return If '_account' has issuer privileges.
     */
    function isIssuer(address _account) public view returns (bool) {
        return raiseOperatorsInst.isIssuer(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setRaiseOperatorsContract(address _raiseOperators) internal {
        require(
            _raiseOperators != address(0),
            "RaiseOperatorable: address of new raiseOperators contract can not be zero"
        );
        raiseOperatorsInst = IRaiseOperators(_raiseOperators);
        emit RaiseOperatorsContractChanged(msg.sender, _raiseOperators);
    }
}


// File @openzeppelin/contracts/math/[email protected]

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/raise/CappedRaise.sol

/**
 * @title CappedRaise
 * @author Team 3301 <[email protected]>
 * @dev Stores, and modified amount of shares that have been sold.  This also implements total amount available to be sold limitations.
 */

pragma solidity 0.5.12;

contract CappedRaise {
    using SafeMath for uint256;

    uint256 private minCap;
    uint256 private maxCap;
    uint256 private sold;
    address[] private receivers;

    mapping(address => uint256) private shares;

    /**
     * @dev Sets the minimum and maximum cap for the capital raise.
     * @param _minCap uint256 minimum cap.
     * @param _maxCap uint256 maximum cap.
     */
    function _setCap(uint256 _minCap, uint256 _maxCap) internal {
        require(_minCap > 0, "CappedRaise: minimum cap must exceed zero");
        require(_maxCap > _minCap, "CappedRaise: maximum cap must exceed minimum cap");
        minCap = _minCap;
        maxCap = _maxCap;
    }

    /**
     * @dev updates the total that the capital raise has sold and the relevant user shares balance.
     * @param _receiver address Receiving address.
     * @param _shares uint256 Amount of shares.
     */
    function _updateSold(address _receiver, uint256 _shares) internal {
        shares[_receiver] = shares[_receiver].add(_shares);
        sold = sold.add(_shares);

        receivers.push(_receiver);
    }

    /**
     * @return the max cap of the raise.
     */
    function getMaxCap() public view returns (uint256) {
        return maxCap;
    }

    /**
     * @return the min cap of the raise.
     */
    function getMinCap() public view returns (uint256) {
        return minCap;
    }

    /**
     * @return the sold amount of the raise.
     */
    function getSold() public view returns (uint256) {
        return sold;
    }

    /**
     * @return the length of receivers.
     */
    function getReceiversLength() public view returns (uint256) {
        return receivers.length;
    }

    /**
     * @param _index uint256 index of the receiver.
     * @return receiver address at index.
     */
    function getReceiver(uint256 _index) public view returns (address) {
        return receivers[_index];
    }

    /**
     * @dev returns sub-array of receivers for a given range of indices
     * @param _start uint256 start index
     * @param _end uint256 end index
     * @return address[] sub-array of receivers' addresses
     */
    function getReceiversBatch(uint256 _start, uint256 _end) public view returns (address[] memory) {
        require(_start < _end, "CappedRaise: Wrong receivers array indices");
        require(_end.sub(_start) <= 256, "CappedRaise: Greater than block limit");
        address[] memory _receivers = new address[](_end.sub(_start));
        for (uint256 _i = 0; _i < _end.sub(_start); _i++) {
            _receivers[_i] = _i.add(_start) < receivers.length ? receivers[_i.add(_start)] : address(0);
        }
        return _receivers;
    }

    /**
     * @return the available shares of raise (shares that are not sold yet).
     */
    function getAvailableShares() public view returns (uint256) {
        return maxCap.sub(sold);
    }

    /**
     * @param _receiver address Receiving address.
     * @return the receiver's shares.
     */
    function getShares(address _receiver) public view returns (uint256) {
        return shares[_receiver];
    }

    /**
     * @dev Checks whether the max cap has been reached.
     * @return Whether the max cap has been reached.
     */
    function maxCapReached() public view returns (bool) {
        return sold >= maxCap;
    }

    /**
     * @dev Checks whether the max cap has been reached with a new investment.
     * @param _newInvestment uint256 containing the new proposed investment.
     * @return Whether the max cap would be reached with the new investment.
     */
    function maxCapWouldBeReached(uint256 _newInvestment) public view returns (bool) {
        return sold.add(_newInvestment) > maxCap;
    }

    /**
     * @dev Checks whether the min cap has been reached.
     * @return Whether the min cap has been reached.
     */
    function minCapReached() public view returns (bool) {
        return sold >= minCap;
    }
}


// File contracts/raise/TimedRaise.sol

/**
 * @title TimedRaise
 * @author Team 3301 <[email protected]>
 * @dev This contract implements time limitations upon contributions.
 */

pragma solidity 0.5.12;

contract TimedRaise {
    using SafeMath for uint256;

    uint256 private openingTime;
    uint256 private closingTime;

    /**
     * @dev Reverts if not in raise time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedRaise: not open");
        _;
    }

    /**
     * @dev Reverts if not after raise time range.
     */
    modifier onlyWhenClosed {
        require(hasClosed(), "TimedRaise: not closed");
        _;
    }

    /**
     * @dev sets raise opening and closing times.
     * @param _openingTime uint256 Opening time for raise.
     * @param _closingTime uint256 Closing time for raise.
     */
    function _setTime(uint256 _openingTime, uint256 _closingTime) internal {
        // solhint-disable-next-line not-rely-on-time
        require(_openingTime >= block.timestamp, "TimedRaise: opening time is before current time");
        require(_closingTime > _openingTime, "TimedRaise: opening time is not before closing time");

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
     * @return the raise opening time.
     */
    function getOpening() public view returns (uint256) {
        return openingTime;
    }

    /**
     * @return the raise closing time.
     */
    function getClosing() public view returns (uint256) {
        return closingTime;
    }

    /**
     * @dev Checks whether the raise is still open.
     * @return true if the raise is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return now >= openingTime && now <= closingTime;
    }

    /**
     * @dev Checks whether the period in which the raise is open has already elapsed.
     * @return Whether raise period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return now > closingTime;
    }
}


// File contracts/libraries/Bytes32Set.sol

pragma solidity 0.5.12;

// SPDX-License-Identifier: Unlicensed
// https://github.com/rob-Hitchens/SetTypes/blob/master/contracts/Bytes32Set.sol

library Bytes32Set {
    struct Set {
        mapping(bytes32 => uint256) keyPointers;
        bytes32[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, bytes32 key) internal {
        require(!exists(self, key), "Bytes32Set: key already exists in the set.");
        self.keyPointers[key] = self.keyList.length;
        self.keyList.push(key);
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, bytes32 key) internal {
        require(exists(self, key), "Bytes32Set: key does not exist in the set.");
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            bytes32 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) internal view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, bytes32 key) internal view returns (bool) {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index) internal view returns (bytes32) {
        return self.keyList[index];
    }
}


// File contracts/raise/Raise.sol

/**
 * @title Raise
 * @author Team 3301 <[email protected]>
 * @dev The Raise contract acts as an escrow for subscriptions, and issuer payments.
 *       This contract also has a cap upon how much can be purchased, and time boundaries implemented.
 *       Contract is spawned from RaiseFactory.
 */

pragma solidity 0.5.12;





contract Raise is RaiseOperatorable, CappedRaise, TimedRaise, Pausable {
    using SafeMath for uint256;
    using Bytes32Set for Bytes32Set.Set;

    IERC20 public dchf;
    address public issuer;
    uint256 public price;
    uint256 public minSubscription;
    uint256 public totalPendingDeposits;
    uint256 public totalDeclinedDeposits;
    uint256 public totalAcceptedDeposits;
    uint256 public decimals;
    bool public issuerPaid;

    mapping(bytes32 => Subscription) public subscription;
    mapping(bool => Bytes32Set.Set) internal subscriptions;
    mapping(address => mapping(bool => Bytes32Set.Set)) internal investor;

    Stage public stage;
    enum Stage {Created, RepayAll, IssuerAccepted, OperatorAccepted, Closed}

    struct Subscription {
        address investor;
        uint256 shares;
        uint256 cost;
    }

    uint16 internal constant BATCH_LIMIT = 256;

    event SubscriptionProposal(address indexed issuer, address indexed investor, bytes32 subID);
    event SubscriptionAccepted(address indexed payee, bytes32 subID, uint256 shares, uint256 cost);
    event SubscriptionDeclined(address indexed payee, bytes32 subID, uint256 cost);
    event RaiseClosed(address indexed issuer, bool accepted);
    event OperatorRaiseFinalization(address indexed issuer, bool accepted);
    event IssuerPaid(address indexed issuer, uint256 amount);
    event OperatorClosed(address indexed operator);
    event UnsuccessfulRaise(address indexed issuer);
    event ReleasedPending(address indexed investor, uint256 amount);
    event ReleasedEmergency(address indexed investor, uint256 amount);

    /**
     * @dev Reverts if caller is not the issuer.
     */
    modifier onlyIssuer() {
        require(msg.sender == issuer, "Raise: caller not issuer");
        _;
    }

    /**
     * @dev Reverts if the current stage is not the specified stage.
     */
    modifier onlyAtStage(Stage _stage) {
        require(stage == _stage, "Raise: not at correct stage");
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once to initialize all the necessary values.
     * @param _dchf DCHF proxy contract address.
     * @param _issuer Address of capital raise issuer.
     * @param _min Minimum amount required in DCHF for the capital raise.
     * @param _max Maximum amount required in DCHF for the capital raise.
     * @param _price DCHF price per share.
     * @param _minSubscription Minimum amount in DCHF that is required for a subscription.
     * @param _open Opening time in unix epoch time.
     * @param _close Closing time in unix epoch time.
     * @param _baseOperators BaseOperators contract address.
     * @param _raiseOperators RaiseOperators contract address.
     */
    function initialize(
        IERC20 _dchf,
        address _issuer,
        uint256 _min,
        uint256 _max,
        uint256 _price,
        uint256 _minSubscription,
        uint256 _decimals,
        uint256 _open,
        uint256 _close,
        address _baseOperators,
        address _raiseOperators
    ) public initializer {
        dchf = _dchf;
        price = _price;
        issuer = _issuer;
        _setCap(_min, _max);
        _setTime(_open, _close);
        minSubscription = _minSubscription;
        RaiseOperatorable.initialize(_baseOperators, _raiseOperators);
        decimals = _decimals;
    }

    /**
     * @dev Investor can subscribe to the capital raise with the unique subscription hash.
     * @param _subID Subscription unique identifier
     * @param _shares Amount of shares to purchase.
     */
    function subscribe(bytes32 _subID, uint256 _shares)
        public
        whenNotPaused
        onlyInvestor
        onlyAtStage(Stage.Created)
        onlyWhileOpen
    {
        require(_shares <= getAvailableShares(), "Raise: above available");

        uint256 cost = _shares.mul(price);

        require(cost >= minSubscription, "Raise: below minimum subscription");
        require(cost <= dchf.allowance(msg.sender, address(this)), "Raise: above allowance");

        dchf.transferFrom(msg.sender, address(this), cost);
        totalPendingDeposits = totalPendingDeposits.add(cost);

        investor[msg.sender][false].insert(_subID);
        subscriptions[false].insert(_subID);
        subscription[_subID] = Subscription({investor: msg.sender, shares: _shares, cost: cost});

        emit SubscriptionProposal(issuer, msg.sender, _subID);
    }

    /**
     * @dev Issuer accept or decline subscription.
     * @param _subID Subscription unique identifier
     * @param _accept Whether acceptance or not.
     */
    function issuerSubscription(bytes32 _subID, bool _accept)
        public
        whenNotPaused
        onlyIssuer
        onlyAtStage(Stage.Created)
    {
        require(subscriptions[false].exists(_subID), "Raise: subscription does not exist");
        require(!maxCapReached(), "Raise: max sold already met");

        Subscription memory sub = subscription[_subID];
        require(!maxCapWouldBeReached(sub.shares) || !_accept, "Raise: subscription would exceed max sold");
        totalPendingDeposits = totalPendingDeposits.sub(sub.cost);

        if (!_accept || getAvailableShares() < sub.shares) {
            subscriptions[false].remove(_subID);
            investor[sub.investor][false].remove(_subID);
            totalDeclinedDeposits = totalDeclinedDeposits.add(sub.cost);
            delete subscription[_subID];
            dchf.transfer(sub.investor, sub.cost);
            emit SubscriptionDeclined(sub.investor, _subID, sub.cost);
            return;
        }

        subscriptions[false].remove(_subID);
        subscriptions[true].insert(_subID);
        investor[sub.investor][false].remove(_subID);
        investor[sub.investor][true].insert(_subID);
        _updateSold(sub.investor, sub.shares);
        // no reentrancy possibility here, only transferring to dchf, not arbitrary address
        // solhint-disable-next-line reentrancy
        totalAcceptedDeposits = totalAcceptedDeposits.add(sub.cost);
        emit SubscriptionAccepted(sub.investor, _subID, sub.shares, sub.cost);
    }

    /**
     * @dev Issuer closes the capital raise.
     * @param _accept Whether acceptance or not of the capital raise.
     */
    function issuerClose(bool _accept) public whenNotPaused onlyIssuer onlyAtStage(Stage.Created) {
        if (!minCapReached() && hasClosed()) {
            stage = Stage.RepayAll;
            emit UnsuccessfulRaise(msg.sender);
        } else if ((minCapReached() && hasClosed()) || maxCapReached()) {
            stage = _accept ? Stage.IssuerAccepted : Stage.RepayAll;
            emit RaiseClosed(msg.sender, _accept);
        }
    }

    /**
     * @dev Operator finalize capital raise after issuer has accepted.
     * @param _accept Whether acceptance or not of the capital raise.
     */
    function operatorFinalize(bool _accept) public whenNotPaused onlyOperator {
        if (_accept) {
            require(stage == Stage.IssuerAccepted, "Raise: incorrect stage");
            stage = Stage.OperatorAccepted;
        } else {
            require(stage != Stage.OperatorAccepted && stage != Stage.Closed, "Raise: incorrect stage");
            stage = Stage.RepayAll;
        }
        emit OperatorRaiseFinalization(msg.sender, _accept);
    }

    /**
     * @dev Release DCHF obtained to issuer.
     */
    function releaseToIssuer() public whenNotPaused onlyOperatorOrSystem onlyAtStage(Stage.OperatorAccepted) {
        require(!issuerPaid, "Raise: issuer already paid");
        issuerPaid = true;

        dchf.transfer(issuer, totalAcceptedDeposits);

        emit IssuerPaid(issuer, totalAcceptedDeposits);
    }

    /**
     * @dev Release pending DCHF subscriptions.
     * @param _investors Array of investors to release pending subscriptions for.
     */
    function batchReleasePending(address[] memory _investors) public whenNotPaused onlyOperatorOrSystem {
        require(_investors.length <= BATCH_LIMIT, "Raise: batch count is greater than BATCH_LIMIT");
        require(stage != Stage.Created, "Raise: not at correct stage");
        for (uint256 i = 0; i < _investors.length; i++) {
            address user = _investors[i];
            uint256 amount = _clearInvestorFunds(user, false);
            dchf.transfer(user, amount);
            emit ReleasedPending(user, amount);
        }
    }

    /**
     * @dev Close the capital raise after either pending participants have been paid back, or all participants have been repaid.
     */
    function close() public whenNotPaused onlyOperatorOrSystem onlyWhenClosed {
        require(stage == Stage.OperatorAccepted || stage == Stage.RepayAll, "Raise: not at correct stage");
        require(subscriptions[false].count() == 0, "Raise: pending not emptied");

        if (stage == Stage.OperatorAccepted) require(issuerPaid, "Raise: issuer not been paid");

        if (stage == Stage.RepayAll) require(subscriptions[true].count() == 0, "Raise: not emptied");

        stage = Stage.Closed;
        emit OperatorClosed(msg.sender);
    }

    /**
     * @dev Pay pending and accepted DCHF back to investors.
     * @param _investors Array of investors to repay.
     */
    function releaseAllFunds(address[] memory _investors) public onlyOperatorOrSystem {
        require(Pausable.isPaused() || stage == Stage.RepayAll, "Raise: not at correct stage");

        for (uint256 i = 0; i < _investors.length; i++) {
            address user = _investors[i];
            uint256 amount = _clearInvestorFunds(user, false).add(_clearInvestorFunds(user, true));
            if (amount > 0) {
                dchf.transfer(user, amount);
                emit ReleasedEmergency(user, amount);
            }
        }
    }

    /**
     * @param _accept Pending or accepted.
     * @return Amount of pending/accepted subscriptions.
     */
    function getSubscriptionTypeLength(bool _accept) public view returns (uint256) {
        return (subscriptions[_accept].count());
    }

    /**
     * @param _investor address of investor.
     * @param _accept pending or accepted.
     * @return Subscription IDs per investor for pending or accepted subscriptions.
     */
    function getSubIDs(address _investor, bool _accept) public view returns (bytes32[] memory) {
        bytes32[] memory subIDs = new bytes32[](investor[_investor][_accept].count());
        for (uint256 i = 0; i < investor[_investor][_accept].count(); i++) {
            subIDs[i] = investor[_investor][_accept].keyAtIndex(i);
        }
        return subIDs;
    }

    /**
     * @param _investor address of investor.
     * @param _accept pending or accepted.
     * @return Deposit per investor for pending or accepted subscriptions.
     */
    function getDeposits(address _investor, bool _accept) public view returns (uint256 deposit) {
        bytes32[] memory subIDs = getSubIDs(_investor, _accept);

        for (uint256 i = 0; i < subIDs.length; i++) {
            bytes32 subID = subIDs[i];

            deposit = deposit.add(subscription[subID].cost);
        }
        return deposit;
    }

    function _clearInvestorFunds(address _user, bool _approved) internal returns (uint256) {
        uint256 amount;
        while (investor[_user][_approved].count() != 0) {
            bytes32 subID = investor[_user][_approved].keyAtIndex(0);
            Subscription memory sub = subscription[subID];
            amount = amount.add(sub.cost);
            subscriptions[_approved].remove(subID);
            investor[_user][_approved].remove(subID);
            delete subscription[subID];
        }
        return amount;
    }
}