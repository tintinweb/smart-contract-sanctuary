/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: contracts/ISygnumToken.sol

/**
 * @title ISygnumToken
 * @notice Interface for custom functionality.
 */

pragma solidity 0.5.12;


contract ISygnumToken is IERC20 {
    function block(address _account, uint256 _amount) external;

    function unblock(address _account, uint256 _amount) external;
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/math/Math.sol

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/role/interface/ITraderOperators.sol

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

// File: @sygnum/solidity-base-contracts/contracts/role/interface/IBaseOperators.sol

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

// File: @sygnum/solidity-base-contracts/contracts/helpers/Initializable.sol

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
    require(initializing || isConstructor() || !initialized, "Initializable: Contract instance has already been initialized");

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
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  function isInitialized() public view returns (bool) {
    return initialized;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @sygnum/solidity-base-contracts/contracts/role/base/Operatorable.sol

/**
 * @title Operatorable
 * @author Connor Howe <[email protected]>
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
        require(isOperator(msg.sender) || isRelay(msg.sender), "Operatorable: caller does not have the operator role nor relay");
        _;
    }

    /**
     * @dev Reverts if sender does not have relay or admin role associated.
     */
	modifier onlyAdminOrRelay() {
        require(isAdmin(msg.sender) || isRelay(msg.sender), "Operatorable: caller does not have the admin role nor relay");
        _;
    }

    /**
     * @dev Reverts if sender does not have the operator, or system, or relay role associated.
     */
	modifier onlyOperatorOrSystemOrRelay() {
        require(isOperator(msg.sender) || isSystem(msg.sender) || isRelay(msg.sender), "Operatorable: caller does not have the operator role nor system nor relay");
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
     * @dev The function should be called from new operators contract by admin to insure that operatorsPending address
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
    function getOperatorsContract() public view returns(address) {
        return address(operatorsInst);
    }

    /**
     * @return The pending address of the BaseOperators contract.
     */
    function getOperatorsPending() public view returns(address) {
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

// File: @sygnum/solidity-base-contracts/contracts/role/trader/TraderOperatorable.sol

/**
 * @title TraderOperatorable
 * @author Connor Howe <[email protected]>
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
        require(isOperator(msg.sender) || isTrader(msg.sender) || isSystem(msg.sender), "TraderOperatorable: caller is not trader or operator or system");
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
        require(_traderOperators != address(0), "TraderOperatorable: address of new traderOperators contract can not be zero");
        traderOperatorsPending = _traderOperators;
        emit TraderOperatorsContractPending(msg.sender, _traderOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to insure that traderOperatorsPending address
     *       is the real contract address.
     */
    function confirmTraderOperatorsContract() public {
        require(traderOperatorsPending != address(0), "TraderOperatorable: address of pending traderOperators contract can not be zero");
        require(msg.sender == traderOperatorsPending, "TraderOperatorable: should be called from new traderOperators contract");
        _setTraderOperatorsContract(traderOperatorsPending);
    }

    /**
     * @return The address of the TraderOperators contract.
     */
    function getTraderOperatorsContract() public view returns(address) {
        return address(traderOperatorsInst);
    }

    /**
     * @return The pending TraderOperators contract address
     */
    function getTraderOperatorsPending() public view returns(address) {
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
        require(_traderOperators != address(0), "TraderOperatorable: address of new traderOperators contract can not be zero");
        traderOperatorsInst = ITraderOperators(_traderOperators);
        emit TraderOperatorsContractChanged(msg.sender, _traderOperators);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/Pausable.sol

/**
 * @title Pausable
 * @author Connor Howe <[email protected]>
 * @dev Contract module which allows children to implement an emergency stop
 *      mechanism that can be triggered by an authorized account in the TraderOperatorable
 *      contract.
 */
pragma solidity 0.5.12;


contract Pausable is TraderOperatorable {
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    bool internal _paused;

    constructor () internal {
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
    function isPaused() public view returns(bool){
        return _paused;
    }

    /**
     * @return If child contract is not paused.
     */
    function isNotPaused() public view returns(bool){
        return !_paused;
    }
}

// File: @sygnum/solidity-base-contracts/contracts/libraries/Bytes32Set.sol

pragma solidity 0.5.12;

// SPDX-License-Identifier: Unlicensed
// https://github.com/rob-Hitchens/SetTypes/blob/master/contracts/Bytes32Set.sol

library Bytes32Set {
    
    struct Set {
        mapping(bytes32 => uint) keyPointers;
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
        uint last = count(self) - 1;
        uint rowToReplace = self.keyPointers[key];
        if(rowToReplace != last) {
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
    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }
    
    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check. 
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, bytes32 key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */    
    function keyAtIndex(Set storage self, uint index) internal view returns(bytes32) {
        return self.keyList[index];
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/TradingPairWhitelist.sol

/**
 * @title TradingPairWhitelist
 * @author Connor Howe <[email protected]>
 * @dev TradingPairWhitelist contract that allows particular trading pairs available within the DEX.  Whitelisting/unwhitelisting
 *       is controlled by operators in Operatorable contract which is initialized with the relevant BaseOperators address.
 */

pragma solidity 0.5.12;




contract TradingPairWhitelist is TraderOperatorable {
    using Bytes32Set for Bytes32Set.Set;

    Bytes32Set.Set internal pairs;
    mapping (bytes32 => Pair) public pair;
    mapping (address => mapping (address => bytes32)) pairIdentifier;

    struct Pair {
        bool paired;
        bool frozen;
        address buyToken;
        address sellToken;
    }

    event PairedTokens(bytes32 indexed pairID, address indexed buytoken, address indexed sellToken);
    event DepairedTokens(bytes32 indexed pairID, address indexed buytoken, address indexed sellToken);
    event FrozenPair(bytes32 indexed pairID);
    event UnFrozenPair(bytes32 indexed pairID);

    /**
     * @dev Reverts if _buyToken and _sellToken are not paired.
     * @param _buyToken buy token against sell token to determine if whitelisted pair or not.
     * @param _sellToken sell token against buy token to determine if whitelisted pair or not.
     */
    modifier onlyPaired(address _buyToken, address _sellToken) {
        require(isPaired(_buyToken, _sellToken), 'TradingPairWhitelist: pair is not whitelisted');
        _;
    }

    /**
     * @dev Reverts if _buyToken and _sellToken are frozen.
     * @param _buyToken buy token against sell token to determine if frozen pair or not.
     * @param _sellToken sell token against buy token to determine if frozen pair or not.
     */
    modifier whenNotFrozen(address _buyToken, address _sellToken) {
        require(!isFrozen(_buyToken, _sellToken), 'TradingPairWhitelist: pair is frozen');
        _;
    }

    /**
    * @dev Getter to determine if pairs are whitelisted.
    * @param _buyToken buy token against sell token to determine if whitelisted pair or not.
    * @param _sellToken sell token against buy token to determine if whitelisted pair or not.
    * @return bool is whitelisted pair.
    */
    function isPaired(address _buyToken, address _sellToken) public view returns (bool) {
        return pair[pairIdentifier[_buyToken][_sellToken]].paired;
    }

    /**
    * @dev Getter to determine if pairs are frozen.
    * @param _buyToken buy token against sell token to determine if frozen pair or not.
    * @param _sellToken sell token against buy token to determine if frozen pair or not.
    * @return bool is frozen pair.
    */
    function isFrozen(address _buyToken, address _sellToken) public view returns (bool) {
        return pair[pairIdentifier[_buyToken][_sellToken]].frozen;
    }

    /**
    * @dev Pair tokens to be available for trading on DEX.
    * @param _pairID pair identifier.
    * @param _buyToken buy token against sell token to whitelist.
    * @param _sellToken sell token against buy token to whitelist.
    */
    function pairTokens(bytes32 _pairID, address _buyToken, address _sellToken)
        public
        onlyOperator
    {
        _pairTokens(_pairID, _buyToken, _sellToken);
    }

    /**
    * @dev Depair tokens to be available for trading on DEX.
    * @param _pairID pair identifier.
    */
    function depairTokens(bytes32 _pairID)
        public
        onlyOperator
    {
        _depairTokens(_pairID);
    }

    /**
    * @dev Freeze pair trading on DEX.
    * @param _pairID pair identifier.
    */
    function freezePair(bytes32 _pairID)
        public
        onlyOperatorOrTraderOrSystem
    {
        _freezePair(_pairID);
    }

    /**
    * @dev Unfreeze pair trading on DEX.
    * @param _pairID pair identifier.
    */
    function unfreezePair(bytes32 _pairID)
        public
        onlyOperatorOrTraderOrSystem
    {
        _unfreezePair(_pairID);
    }

    /**
    * @dev Batch pair tokens.
    * @param _pairID array of pairID.
    * @param _buyToken address array of buyToken.
    * @param _sellToken address array of buyToken.
    */
    function batchPairTokens(bytes32[] memory _pairID, address[] memory _buyToken, address[] memory _sellToken)
        public
        onlyOperator
    {
        require(_pairID.length <= 256, 'TradingPairWhitelist: batch count is greater than 256');
        require(_pairID.length == _buyToken.length && _buyToken.length == _sellToken.length, 'TradingPairWhitelist: array lengths not equal');

        for (uint256 i = 0; i < _buyToken.length; i++) {
            _pairTokens(_pairID[i], _buyToken[i], _sellToken[i]);
        }
    }

    /**
    * @dev Batch depair tokens.
    * @param _pairID array of pairID.
    */
    function batchDepairTokens(bytes32[] memory _pairID)
        public
        onlyOperator
    {
        require(_pairID.length <= 256, 'TradingPairWhitelist: batch count is greater than 256');

        for (uint256 i = 0; i < _pairID.length; i++) {
            _depairTokens(_pairID[i]);
        }
    }

    /**
    * @dev Batch freeze tokens.
    * @param _pairID array of pairID.
    */
    function batchFreezeTokens(bytes32[] memory _pairID)
        public
        onlyOperatorOrTraderOrSystem
    {
        require(_pairID.length <= 256, 'TradingPairWhitelist: batch count is greater than 256');

        for (uint256 i = 0; i < _pairID.length; i++) {
            _freezePair(_pairID[i]);
        }
    }

    /**
    * @dev Batch unfreeze tokens.
    * @param _pairID array of pairID.
    */
    function batchUnfreezeTokens(bytes32[] memory _pairID)
        public
        onlyOperatorOrTraderOrSystem
    {
        require(_pairID.length <= 256, 'TradingPairWhitelist: batch count is greater than 256');

        for (uint256 i = 0; i < _pairID.length; i++) {
            _unfreezePair(_pairID[i]);
        }
    }

    /**
    * @return Amount of pairs.
    */
    function getPairCount() 
        public
        view
        returns(uint256)
    {
        return pairs.count();
    }

    /**
    * @return Key at index.
    */
    function getIdentifier(uint256 _index) 
        public
        view
        returns(bytes32)
    {
        return pairs.keyAtIndex(_index);
    }


    /** INTERNAL FUNCTIONS */
    function _pairTokens(bytes32 _pairID, address _buyToken, address _sellToken)
        internal
    {
        require(_buyToken != address(0) && _sellToken != address(0), 'TradingPairWhitelist: tokens cannot be empty');
        require(_buyToken != _sellToken, 'TradingPairWhitelist: buy and sell tokens cannot be the same');
        require(!isPaired(_buyToken, _sellToken), 'TradingPairWhitelist: tokens have already been paired');
        require(!pairs.exists(_pairID), 'TradingPairWhitelist: pair ID exists');

        pair[_pairID] = Pair({
            paired: true,
            frozen: false,
            buyToken: _buyToken,
            sellToken: _sellToken
        });

        pairs.insert(_pairID);
        pairIdentifier[_buyToken][_sellToken] = _pairID;
        emit PairedTokens(_pairID, _buyToken, _sellToken);
    }

    function _depairTokens(bytes32 _pairID)
        internal
    {
        require(pairs.exists(_pairID), 'TradingPairWhitelist: pair ID not does not exist');

        Pair memory p = pair[_pairID];

        delete pair[_pairID];
        pairs.remove(_pairID);
        delete pairIdentifier[p.buyToken][p.sellToken];
        emit DepairedTokens(_pairID, p.buyToken, p.sellToken);
    }

    function _freezePair(bytes32 _pairID)
        internal
    {
        require(pairs.exists(_pairID), 'TradingPairWhitelist: pair ID not does not exist');
        require(!pair[_pairID].frozen, 'TradingPairWhitelist: token pair is frozen');

        pair[_pairID].frozen = true;
        emit FrozenPair(_pairID);
    }

    function _unfreezePair(bytes32 _pairID)
        internal
    {
        require(pairs.exists(_pairID), 'TradingPairWhitelist: pair ID not does not exist');
        require(pair[_pairID].frozen, 'TradingPairWhitelist: token pair is not frozen');

        pair[_pairID].frozen = false;
        emit UnFrozenPair(_pairID);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/interface/IWhitelist.sol

pragma solidity 0.5.12;

/**
 * @title IWhitelist
 * @notice Interface for Whitelist contract
 */
contract IWhitelist {
    function isWhitelisted(address _account) external view returns (bool);
    function toggleWhitelist(address _account, bool _toggled) external;
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/instance/Whitelistable.sol

/**
 * @title Whitelistable
 * @author Connor Howe <[email protected]>
 * @dev Whitelistable contract stores the Whitelist contract address, and modifiers for
 *       contracts.
 */

pragma solidity 0.5.12;




contract Whitelistable is Initializable, Operatorable {
    IWhitelist internal whitelistInst;
    address private whitelistPending;

    event WhitelistContractChanged(address indexed caller, address indexed whitelistAddress);
    event WhitelistContractPending(address indexed caller, address indexed whitelistAddress);

    /**
     * @dev Reverts if _account is not whitelisted.
     * @param _account address to determine if whitelisted.
     */
    modifier whenWhitelisted(address _account) {
        require(isWhitelisted(_account), "Whitelistable: account is not whitelisted");
        _;
    }

    /**
     * @dev Initialization instead of constructor, called once. The setWhitelistContract function can be called only by Admin role with
     *       confirmation through the whitelist contract.
     * @param _whitelist Whitelist contract address.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators, address _whitelist) public initializer {
        _setOperatorsContract(_baseOperators);
        _setWhitelistContract(_whitelist);
    }

    /**
     * @dev Set the new the address of Whitelist contract, should be confirmed from whitelist contract by calling confirmFor(addr)
     *       where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *       broken and control of the contract can be lost in such case
     * @param _whitelist Whitelist contract address.
     */
    function setWhitelistContract(address _whitelist) public onlyAdmin {
        require(_whitelist != address(0), "Whitelistable: address of new whitelist contract can not be zero");
        whitelistPending = _whitelist;
        emit WhitelistContractPending(msg.sender, _whitelist);
    }

    /**
     * @dev The function should be called from new whitelist contract by admin to insure that whitelistPending address
     *       is the real contract address.
     */
    function confirmWhitelistContract() public {
        require(whitelistPending != address(0), "Whitelistable: address of new whitelist contract can not be zero");
        require(msg.sender == whitelistPending, "Whitelistable: should be called from new whitelist contract");
        _setWhitelistContract(whitelistPending);
    }

    /**
     * @return The address of the Whitelist contract.
     */
    function getWhitelistContract() public view returns(address) {
        return address(whitelistInst);
    }

    /**
     * @return The pending address of the Whitelist contract.
     */
    function getWhitelistPending() public view returns(address) {
        return whitelistPending;
    }

    /**
     * @return If '_account' is whitelisted.
     */
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelistInst.isWhitelisted(_account);
    }

    /** INTERNAL FUNCTIONS */
    function _setWhitelistContract(address _whitelist) internal {
        require(_whitelist != address(0), "Whitelistable: address of new whitelist contract cannot be zero");
        whitelistInst = IWhitelist(_whitelist);
        emit WhitelistContractChanged(msg.sender, _whitelist);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/interface/IWhitelistable.sol

pragma solidity 0.5.12;

/**
 * @title IWhitelistable
 * @notice Interface for whitelistable contract.
 */
contract IWhitelistable {
    function confirmWhitelistContract() external;
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/Whitelist.sol

/**
 * @title Whitelist
 * @author Connor Howe <[email protected]>
 * @dev Whitelist contract with whitelist/unwhitelist functionality for particular addresses.  Whitelisting/unwhitelisting
 *      is controlled by operators/system/relays in Operatorable contract.
 */

pragma solidity 0.5.12;



contract Whitelist is Operatorable {
    mapping(address => bool) public whitelisted;

    event WhitelistToggled(address indexed account, bool whitelisted);

    /**
     * @dev Reverts if _account is not whitelisted.
     * @param _account address to determine if whitelisted.
     */
    modifier whenWhitelisted(address _account) {
        require(isWhitelisted(_account), "Whitelist: account is not whitelisted");
        _;
    }

    /**
     * @dev Reverts if address is empty.
     * @param _address address to validate.
     */
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Whitelist: invalid address");
        _;
    }

    /**
     * @dev Getter to determine if address is whitelisted.
     * @param _account address to determine if whitelisted or not.
     * @return bool is whitelisted
     */
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelisted[_account];
    }

    /**
     * @dev Toggle whitelisted/unwhitelisted on _account address, with _toggled being true/false.
     * @param _account address to toggle.
     * @param _toggled whitelist/unwhitelist.
     */
    function toggleWhitelist(address _account, bool _toggled)
        public
        onlyValidAddress(_account)
        onlyOperatorOrSystemOrRelay
    {
        whitelisted[_account] = _toggled;
        emit WhitelistToggled(_account, whitelisted[_account]);
    }

    /**
     * @dev Batch whitelisted/unwhitelist multiple addresses, with _toggled being true/false.
     * @param _addresses address array.
     * @param _toggled whitelist/unwhitelist.
     */
    function batchToggleWhitelist(address[] memory _addresses, bool _toggled) public {
        require(_addresses.length <= 256, "Whitelist: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            toggleWhitelist(_addresses[i], _toggled);
        }
    }

    /**
     * @dev Confirms whitelist contract address once active.
     * @param _address Whitelistable contract addres.
     */
    function confirmFor(address _address) public onlyAdmin {
        require(_address != address(0), "Whitelist: address cannot be empty");
        IWhitelistable(_address).confirmWhitelistContract();
    }
}

// File: contracts/dex/Exchange.sol

/**
 * @title Exchange.
 * @author Team 3301 <[email protected]>
 * @dev Users can make/cancel an order and take one or multiple orders.
 */

pragma solidity ^0.5.12;








contract Exchange is Pausable, TradingPairWhitelist {
    using Bytes32Set for Bytes32Set.Set;
    using SafeMath for uint256;
    using Math for uint256;

    struct Order {
        address maker; // account of the order maker.
        address specificTaker; // address of a taker, if applies.
        bool isComplete; // false: partial order; true: complete order;
        ISygnumToken sellToken; // token that the order maker sells
        uint256 sellAmount; // total amount of token planned to be sold by the maker
        ISygnumToken buyToken; // token that the order maker buys
        uint256 buyAmount; // total amount of token planned to be bought by the maker
    }

    Bytes32Set.Set internal orders;
    mapping(bytes32 => Order) public order;

    event MadeOrder(
        bytes32 indexed orderID,
        ISygnumToken indexed sellToken,
        ISygnumToken indexed buyToken,
        address maker,
        address specificTaker,
        bool isComplete,
        uint256 sellAmount,
        uint256 buyAmount
    );

    event MadeOrderParticipants(bytes32 indexed orderID, address indexed maker, address indexed specificTaker);

    event TakenOrder(
        bytes32 indexed orderID,
        ISygnumToken indexed purchasedToken,
        ISygnumToken indexed paidToken,
        address maker,
        address taker,
        uint256 purchasedAmount,
        uint256 paidAmount // computed amount of tokens paid by the taker
    );

    event TakenOrderParticipants(bytes32 indexed orderID, address indexed maker, address indexed taker);

    event CancelledOrder(
        bytes32 indexed orderID,
        address killer,
        ISygnumToken indexed sellToken,
        ISygnumToken indexed buyToken
    );

    /**
     * @dev Reverts if length is not within range
     */
    modifier checkBatchLength(uint256 length) {
        require(length > 1, "Exchange: Fewer than two orders");
        require(length < 256, "Exchange: Too many orders");
        _;
    }

    /**
     * @dev Reverts if current block less than time-out block number
     */
    modifier checkTimeOut(uint256 timeOutBlockNumber) {
        require(block.number <= timeOutBlockNumber, "Exchange: timeout");
        _;
    }

    /**
     * @dev Take orders by their orderID.
     * @param orderIDs Array of order ids to be taken.
     * @param buyers Array of buyers.
     * @param quantity Array of quantity per purchase.
     * @param timeOutBlockNumber Time-out block number.
     */
    function takeOrders(
        bytes32[] calldata orderIDs,
        address[] calldata buyers,
        uint256[] calldata quantity,
        uint256 timeOutBlockNumber
    ) external whenNotPaused checkBatchLength(orderIDs.length) checkTimeOut(timeOutBlockNumber) {
        require(
            orderIDs.length == buyers.length && buyers.length == quantity.length,
            "Exchange: orders and buyers not equal"
        );

        for (uint256 i = 0; i < orderIDs.length; i = i + 1) {
            takeOrder(orderIDs[i], buyers[i], quantity[i], timeOutBlockNumber);
        }
    }

    /**
     * @dev Cancel orders by their orderID.
     * @param orderIDs Array of order ids to be taken.
     */
    function cancelOrders(bytes32[] calldata orderIDs) external checkBatchLength(orderIDs.length) {
        for (uint256 i = 0; i < orderIDs.length; i = i + 1) {
            cancelOrder(orderIDs[i]);
        }
    }

    /**
     * @dev Let investor make an order, providing the approval is done beforehand.
     * @param isComplete If this order can be filled partially (by default), or can only been taken as a whole.
     * @param sellToken Address of the token to be sold in this order.
     * @param sellAmount Total amount of token that is planned to be sold in this order.
     * @param buyToken Address of the token to be purchased in this order.
     * @param buyAmount Total amount of token planned to be bought by the maker
     * @param timeOutBlockNumber Time-out block number.
     */
    function makeOrder(
        bytes32 orderID,
        address specificTaker, // if no one, just pass address(0)
        address seller,
        bool isComplete,
        ISygnumToken sellToken,
        uint256 sellAmount,
        ISygnumToken buyToken,
        uint256 buyAmount,
        uint256 timeOutBlockNumber
    )
        public
        whenNotPaused
        checkTimeOut(timeOutBlockNumber)
        onlyPaired(address(buyToken), address(sellToken))
        whenNotFrozen(address(buyToken), address(sellToken))
    {
        address _seller = isTrader(msg.sender) ? seller : msg.sender;
        _makeOrder(orderID, specificTaker, _seller, isComplete, sellToken, sellAmount, buyToken, buyAmount);
    }

    /**
     * @dev Take an order by its orderID.
     * @param orderID Order ID.
     * @param quantity The amount of 'sellToken' that the taker wants to purchase.
     * @param timeOutBlockNumber Time-out block number.
     */
    function takeOrder(
        bytes32 orderID,
        address seller,
        uint256 quantity,
        uint256 timeOutBlockNumber
    ) public whenNotPaused checkTimeOut(timeOutBlockNumber) {
        address _buyer = isTrader(msg.sender) ? seller : msg.sender;
        _takeOrder(orderID, _buyer, quantity);
    }

    /**
     * @dev Cancel an order by its maker or a trader.
     * @param orderID Order ID.
     */
    function cancelOrder(bytes32 orderID) public {
        require(orders.exists(orderID), "Exchange: order ID does not exist");
        Order memory theOrder = order[orderID];
        require(
            isTrader(msg.sender) || (isNotPaused() && theOrder.maker == msg.sender),
            "Exchange: not eligible to cancel this order or the exchange is paused"
        );
        theOrder.sellToken.unblock(theOrder.maker, theOrder.sellAmount);
        orders.remove(orderID);
        delete order[orderID];
        emit CancelledOrder(orderID, msg.sender, theOrder.sellToken, theOrder.buyToken);
    }

    /**
     * @dev Internal take order
     * @param orderID Order ID.
     * @param buyer Address of a seller, if applies.
     * @param quantity Amount to purchase.
     */
    function _takeOrder(
        bytes32 orderID,
        address buyer,
        uint256 quantity
    ) private {
        require(orders.exists(orderID), "Exchange: order ID does not exist");
        require(buyer != address(0), "Exchange: buyer cannot be set to an empty address");
        require(quantity > 0, "Exchange: quantity cannot be zero");
        Order memory theOrder = order[orderID];
        require(
            theOrder.specificTaker == address(0) || theOrder.specificTaker == buyer,
            "Exchange: not specific taker"
        );
        require(!isFrozen(address(theOrder.buyToken), address(theOrder.sellToken)), "Exchange: tokens are frozen");
        uint256 spend = 0;
        uint256 receive = 0;
        if (quantity >= theOrder.sellAmount) {
            // take the entire order anyway
            spend = theOrder.buyAmount;
            receive = theOrder.sellAmount;
            orders.remove(orderID);
            delete order[orderID];
        } else {
            // check if partial order is possible or not.
            require(!theOrder.isComplete, "Cannot take a complete order partially");
            spend = quantity.mul(theOrder.buyAmount).div(theOrder.sellAmount);
            receive = quantity;
            order[orderID].sellAmount = theOrder.sellAmount.sub(receive);
            order[orderID].buyAmount = theOrder.buyAmount.sub(spend);
        }

        require(
            theOrder.buyToken.allowance(buyer, address(this)) >= spend,
            "Exchange: sender buy allowance is not sufficient"
        );
        theOrder.buyToken.transferFrom(buyer, theOrder.maker, spend);

        require(
            theOrder.sellToken.allowance(theOrder.maker, address(this)) >= receive,
            "Exchange: allowance is greater than receiving"
        );
        theOrder.sellToken.unblock(theOrder.maker, receive);
        theOrder.sellToken.transferFrom(theOrder.maker, buyer, receive);
        emit TakenOrder(orderID, theOrder.buyToken, theOrder.sellToken, theOrder.maker, buyer, spend, receive);
        emit TakenOrderParticipants(orderID, theOrder.maker, buyer);
    }

    /**
     * @dev Internal make order
     * @param orderID Order ID.
     * @param specificTaker Address of a taker, if applies.
     * @param isComplete If this order can be filled partially, or can only been taken as a whole.
     * @param sellToken Address of the token to be sold in this order.
     * @param sellAmount Total amount of token that is planned to be sold in this order.
     * @param buyToken Address of the token to be purchased in this order.
     * @param buyAmount Total amount of token planned to be bought by the maker.
     */
    function _makeOrder(
        bytes32 orderID,
        address specificTaker,
        address seller,
        bool isComplete,
        ISygnumToken sellToken,
        uint256 sellAmount,
        ISygnumToken buyToken,
        uint256 buyAmount
    ) private {
        require(!orders.exists(orderID), "Exchange: order id already exists");
        require(specificTaker != msg.sender, "Exchange: Cannot make an order for oneself");
        require(sellAmount > 0, "Exchange: sell amount cannot be empty");
        require(buyAmount > 0, "Exchange: buy amount cannot be empty");

        require(sellToken.balanceOf(seller) >= sellAmount, "Exchange: seller does not have enough balance");
        require(
            sellToken.allowance(seller, address(this)) >= sellAmount,
            "Exchange: sell amount is greater than allowance"
        );
        require(
            Whitelist(Whitelistable(address(buyToken)).getWhitelistContract()).isWhitelisted(seller),
            "Exchange: seller is not on buy token whitelist"
        );

        if (specificTaker != address(0)) {
            require(
                Whitelist(Whitelistable(address(sellToken)).getWhitelistContract()).isWhitelisted(specificTaker),
                "Exchange: specific taker is not on sell token whitelist"
            );
        }

        sellToken.block(seller, sellAmount);

        order[orderID] = Order({
            maker: seller,
            specificTaker: specificTaker,
            isComplete: isComplete,
            sellToken: sellToken,
            sellAmount: sellAmount,
            buyToken: buyToken,
            buyAmount: buyAmount
        });
        orders.insert(orderID);
        emit MadeOrder(orderID, sellToken, buyToken, seller, specificTaker, isComplete, sellAmount, buyAmount);
        emit MadeOrderParticipants(orderID, seller, specificTaker);
    }

    /**
     * @return Amount of orders.
     */
    function getOrderCount() public view returns (uint256) {
        return orders.count();
    }

    /**
     * @return Key at index.
     */
    function getIdentifier(uint256 _index) public view returns (bytes32) {
        return orders.keyAtIndex(_index);
    }
}