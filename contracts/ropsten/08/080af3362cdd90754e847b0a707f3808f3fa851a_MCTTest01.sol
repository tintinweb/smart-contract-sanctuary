pragma solidity ^0.4.24;

// File: openzeppelin-solidity-2.0.0/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: openzeppelin-solidity-2.0.0/contracts/access/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

// File: openzeppelin-solidity-2.0.0/contracts/access/roles/PauserRole.sol

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

// File: openzeppelin-solidity-2.0.0/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

  /**
   * @return true if the contract is paused, false otherwise.
   */
  function paused() public view returns(bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

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

// File: contracts/ERC223Token.sol

/**
* Contract that will work with ERC-223 tokens.
*/
interface IERC223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

interface ITokenRecipient {
    function receiveApproval(address from, uint256 value, bytes data) external;
}

/**
 * Reference implementation of the ERC-223 standard token.
 */
contract ERC223Token is Pausable {
    using SafeMath for uint256;

    string  public name;
    string  public symbol;
    uint256 public decimals;
    uint256 _totalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping (address => uint256)) private _allowed;

    // ERC-20
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string tokenName, string tokenSymbol, uint256 decimalUnits, uint256 initialSupply) public {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        _totalSupply = initialSupply * 10 ** uint256(decimalUnits);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function() public payable {revert();} // does not accept money

    // ERC-20
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // ERC-20
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    // ERC-20
    function allowance(address owner, address spender) public whenNotPaused view returns (uint256 remaining) {
        return _allowed[owner][spender];
    }

    // ERC-20
    function approve(address spender, uint256 value) public whenNotPaused returns (bool success) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    // ERC-20
    function transfer(address to, uint256 value) public returns (bool success) {
        bytes memory empty;
        _transfer(msg.sender, to, value, empty);

        return true;
    }

    // ERC-20
    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool success) {
        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        bytes memory empty;
        _transfer(from, to, value, empty);

        return true;
    }

    // recommended fix for known attack on any ERC20
    function safeApprove(address _spender, uint256 _currentValue, uint256 _value) public whenNotPaused returns (bool success) {
        // If current allowance for _spender is equal to _currentValue, then
        // overwrite it with _value and return true, otherwise return false.
        if (_allowed[msg.sender][_spender] == _currentValue)
            return approve(_spender, _value);

        return false;
    }

    // Ethereum Token
    function approveAndCall(address spender, uint256 value, bytes context) public whenNotPaused returns (bool success) {
        if (approve(spender, value)) {
            ITokenRecipient recip = ITokenRecipient(spender);
            recip.receiveApproval(msg.sender, value, context);
            return true;
        }
        return false;
    }

    // Ethereum Token
    function burn(uint256 value) public returns (bool success) {
        require(_balances[msg.sender] >= value);
        
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _totalSupply = _totalSupply.sub(value);

        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    // Ethereum Token
    function burnFrom(address from, uint256 value) public whenNotPaused returns (bool success) {
        require(_balances[from] >= value);
        require(value <= _allowed[from][msg.sender]);

        _balances[from] = _balances[from].sub(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _totalSupply = _totalSupply.sub(value);

        emit Transfer(from, address(0), value);
        return true;
    }

    // ERC-223 Transfer and invoke specified callback
    function transfer(address to, uint value, bytes data, string custom_fallback) public whenNotPaused returns (bool success) {
        _transfer(msg.sender, to, value, data);

        if (isContract(to)) {
            IERC223ReceivingContract rx = IERC223ReceivingContract(to);
            require(address(rx).call.value(0)(bytes4(keccak256(custom_fallback)), msg.sender, value, data));
        }

        return true;
    }

    // ERC-223 Transfer to a contract or externally-owned account
    function transfer(address to, uint value, bytes data) public whenNotPaused returns (bool success) {
        if (isContract(to)) {
            return transferToContract(to, value, data);
        }

        _transfer(msg.sender, to, value, data);
        return true;
    }

    // ERC-223 Transfer to contract and invoke tokenFallback() method
    function transferToContract(address to, uint value, bytes data) private returns (bool success) {
        _transfer(msg.sender, to, value, data);

        IERC223ReceivingContract rx = IERC223ReceivingContract(to);
        rx.tokenFallback(msg.sender, value, data);

        return true;
    }

    // ERC-223 fetch contract size (must be nonzero to be a contract)
    function isContract(address _addr) private constant returns (bool) {
        uint length;
        assembly {length := extcodesize(_addr)}
        return (length > 0);
    }

    function _transfer(address from, address to, uint value, bytes data) internal {
        require(to != 0x0);
        require(_balances[from] >= value);
        require(_balances[to] + value > _balances[to]);

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        bytes memory empty;
        empty = data;
        emit Transfer(from, to, value);
        // emit Transfer(from, to, value, data);
    }
}

// File: contracts/MCTTest01.sol

contract MCTTest01 is ERC223Token, Ownable {
    using SafeMath for uint256;

    uint256 public _firstInstallmentTime;
    uint256 public _installmentPeriod;
    uint256 public _numInstallments;
    uint256 public _installmentAmount;

    //============== MCASH TOKEN ===================//
    constructor(uint256 firstInstallmentTime, uint256 installmentPeriod, uint256 numInstallments, uint256 installmentAmount)
        ERC223Token("MCTTest01", "MCT01", 18, 0) public {
        _firstInstallmentTime = firstInstallmentTime;
        _installmentPeriod = installmentPeriod;
        _numInstallments = numInstallments;
        _installmentAmount = installmentAmount;
    }

    function mint(address to, uint256 value) public onlyOwner returns (bool success) {
        require(to != 0);
        require(now >= _firstInstallmentTime);

        uint256 passedNumInstallments = 1 + (now - _firstInstallmentTime) / _installmentPeriod;
        if (passedNumInstallments > _numInstallments) passedNumInstallments = _numInstallments;

        uint256 newTotalSupply = _totalSupply.add(value);
        require(newTotalSupply <= _installmentAmount.mul(passedNumInstallments));

        _totalSupply = newTotalSupply;
        _balances[to] = _balances[to].add(value);
        emit Transfer(address(0), to, value);

        return true;
    }
}