/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

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
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts/ERC/ERC20Interface.sol

pragma solidity ^0.5.0;

/** ----------------------------------------------------------------------------
* @title ERC Token Standard #20 Interface
* https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
* ----------------------------------------------------------------------------
*/
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed tokenOwner, address indexed spender, uint value);
}

// File: contracts/libs/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/libs/Ownable.sol

pragma solidity ^0.5.0;

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic      authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: sender is not owner");
        _;
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Ownable: transfer to zero address");
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

// File: contracts/libs/AccessControl.sol

pragma solidity ^0.5.0;



contract AccessControl is Ownable {

    using Roles for Roles.Role;

    //Contract admins
    Roles.Role internal _admins;

    // Events
    event AddedAdmin(address _address);
    event DeletedAdmin(address _addess);

    function addAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0), "AccessControl: Invalid new admin address");
        _admins.add(newAdmin);
        emit AddedAdmin(newAdmin);
    }

    function deletedAdmin(address deleteAdmin) public onlyOwner {
        require(deleteAdmin != address(0), "AccessControl: Invalid new admin address");
        _admins.remove(deleteAdmin);
        emit DeletedAdmin(deleteAdmin);
    }
}

// File: contracts/ERC/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20 is ERC20Interface, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowed;

    uint256 internal _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= _allowed[from][msg.sender], "ERC20: account balance is lower than amount");
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(addedValue > 0, "ERC20: value must be bigger than zero");
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(subtractedValue > 0, "ERC20: value must be bigger than zero");
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
    * @dev Internal transfer, only can be called by this contract
    */
    function _transfer(address _from, address _to, uint256 value) internal {
        require(_from != address(0), "ERC20: transfer to the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(value > 0, "ERC20: value must be bigger than zero");
        require(value <= _balances[_from], "ERC20: balances from must be bigger than transfer amount");
        require(_balances[_to] < _balances[_to] + value, "ERC20: value must be bigger than zero");

        _balances[_from] = _balances[_from].sub(value);
        _balances[_to] = _balances[_to].add(value);
        emit Transfer(_from, _to, value);
    }

    /**
    * @dev Internal function, minting new tokens
    */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "ERC20: value must be bigger than zero");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        _allowed[account][account] = _balances[account];
        emit Transfer(address(0), account, amount);
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

// File: contracts/MainContract.sol

pragma solidity ^0.5.0;


/**
 * @title MainContract
 * @dev Base contract which using for initializing new contract
 */
contract MainContract is ERC20 {

    string private _name;

    string private _symbol;

    uint private _decimals;

    uint private _decimalsMultiplier;

    /**
     * @return get token name
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return get token symbol
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return get token decimals
     */
    function decimals() public view returns (uint) {
        return _decimals;
    }

    /**
     * @dev override base method transferFrom
     */
    function transferFrom(address _from, address _to, uint256 value) public returns (bool _success) {
        return super.transferFrom(_from, _to, value);
    }

    /**
     * @dev Override base method transfer
     */
    function transfer(address _to, uint256 value) public returns (bool _success) {
        return super.transfer(_to, value);
    }

    /**
     * @dev Override base method increaseAllowance
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    /**
    * @dev Override base method decreaseAllowance
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
    * @dev Override base method approve
    */
    function approve(address spender, uint256 value) public returns (bool) {
        return super.approve(spender, value);
    }

    /**
    * @dev Function whose calling on initialize contract
    */
    function init(string memory __name, string memory __symbol, uint __decimals, uint __totalSupply, address __owner) internal {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
        _decimalsMultiplier = 10 ** _decimals;
        uint256 generateTokens = __totalSupply * _decimalsMultiplier;
        _mint(__owner, generateTokens);
        approve(__owner, balanceOf(__owner));
        _transferOwnership(__owner);
    }

    function() external payable {
        revert();
    }
}

// File: contracts/BaniContract.sol

pragma solidity ^0.5.0;



contract BaniContract is MainContract, Initializable {

    constructor () public {initialize();}

    function initialize() public initializer {
        owner = 0x6CEE4f0558c668C063BB8221deaA5bc25468f8a0;
        init('BANI', 'BANI', 5, 7000000000, owner);
    }
}