/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

/**
 *Submitted for verification at Etherscan.io on 2019-04-22
*/

pragma solidity ^0.5.2;

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
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
     * @dev Transfer token to a specified address
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
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

// File: contracts/ERC1132/IERC1132.sol

/**
 * @title ERC1132 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1132
 */
interface IERC1132 {
  /**
   * @dev Records data of all the tokens Locked
   */
  event Locked(
    address indexed _of,
    bytes32 indexed _reason,
    uint256 _amount,
    uint256 _validity
  );

  /**
   * @dev Records data of all the tokens unlocked
   */
  event Unlocked(
    address indexed _of,
    bytes32 indexed _reason,
    uint256 _amount
  );
  
  /**
   * @dev Locks a specified amount of tokens against an address,
   *   for a specified reason and time
   * @param _reason The reason to lock tokens
   * @param _amount Number of tokens to be locked
   * @param _time Lock time in seconds
   */
  function lock(bytes32 _reason, uint256 _amount, uint256 _time)
    external returns (bool);
 
  /**
   * @dev Returns tokens locked for a specified address for a
   *   specified reason
   *
   * @param _of The address whose tokens are locked
   * @param _reason The reason to query the lock tokens for
   */
  function tokensLocked(address _of, bytes32 _reason)
    external view returns (uint256 amount);
  
  /**
   * @dev Returns tokens locked for a specified address for a
   *   specified reason at a specific time
   *
   * @param _of The address whose tokens are locked
   * @param _reason The reason to query the lock tokens for
   * @param _time The timestamp to query the lock tokens for
   */
  function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
    external view returns (uint256 amount);
  
  /**
   * @dev Returns total tokens held by an address (locked + transferable)
   * @param _of The address to query the total balance of
   */
  function totalBalanceOf(address _of)
    external view returns (uint256 amount);
  
  /**
   * @dev Extends lock for a specified reason and time
   * @param _reason The reason to lock tokens
   * @param _time Lock extension time in seconds
   */
  function extendLock(bytes32 _reason, uint256 _time)
    external returns (bool);
  
  /**
   * @dev Increase number of tokens locked for a specified reason
   * @param _reason The reason to lock tokens
   * @param _amount Number of tokens to be increased
   */
  function increaseLockAmount(bytes32 _reason, uint256 _amount)
    external returns (bool);

  /**
   * @dev Returns unlockable tokens for a specified address for a specified reason
   * @param _of The address to query the the unlockable token count of
   * @param _reason The reason to query the unlockable tokens for
   */
  function tokensUnlockable(address _of, bytes32 _reason)
    external view returns (uint256 amount);
 
  /**
   * @dev Unlocks the unlockable tokens of a specified address
   * @param _of Address of user, claiming back unlockable tokens
   */
  function unlock(address _of)
    external returns (uint256 unlockableTokens);

  /**
   * @dev Gets the unlockable tokens of a specified address
   * @param _of The address to query the the unlockable token count of
   */
  function getUnlockableTokens(address _of)
    external view returns (uint256 unlockableTokens);

}

// File: contracts/ERC1132/ERC1132.sol

/**
 * @title Standard ERC1132 implementation
 * @dev See https://github.com/OpenZeppelin/openzeppelin-solidity/pull/1298
 */
contract ERC1132 is ERC20,  IERC1132 {
  /**
   * @dev Error messages for require statements
   */
  string internal constant ALREADY_LOCKED = "Tokens already locked";
  string internal constant NOT_LOCKED = "No tokens locked";
  string internal constant AMOUNT_ZERO = "Amount can not be 0";

  /**
   * @dev Reasons why a user's tokens have been locked
   */
  mapping(address => bytes32[]) public lockReason;

  /**
   * @dev locked token structure
   */
  struct LockToken {
    uint256 amount;
    uint256 validity;
    bool claimed;
  }

  /**
   * @dev Holds number & validity of tokens locked for a given reason for
   *   a specified address
   */
  mapping(address => mapping(bytes32 => LockToken)) public locked;

  /**
   * @dev Locks a specified amount of tokens against an address,
   *   for a specified reason and time
   * @param _reason The reason to lock tokens
   * @param _amount Number of tokens to be locked
   * @param _time Lock time in seconds
   */
  function lock(bytes32 _reason, uint256 _amount, uint256 _time)
    public
    returns (bool)
  {
    // solium-disable-next-line security/no-block-members
    uint256 validUntil = now.add(_time); //solhint-disable-line

    // If tokens are already locked, then functions extendLock or
    // increaseLockAmount should be used to make any changes
    require(tokensLocked(msg.sender, _reason) == 0, ALREADY_LOCKED);
    require(_amount != 0, AMOUNT_ZERO);

    if (locked[msg.sender][_reason].amount == 0)
      lockReason[msg.sender].push(_reason);

    transfer(address(this), _amount);

    locked[msg.sender][_reason] = LockToken(_amount, validUntil, false);

    emit Locked(
      msg.sender,
      _reason, 
      _amount, 
      validUntil
    );
    return true;
  }
  
  /**
   * @dev Transfers and Locks a specified amount of tokens,
   *   for a specified reason and time
   * @param _to adress to which tokens are to be transfered
   * @param _reason The reason to lock tokens
   * @param _amount Number of tokens to be transfered and locked
   * @param _time Lock time in seconds
   */
  function transferWithLock(
    address _to, 
    bytes32 _reason, 
    uint256 _amount, 
    uint256 _time
  )
    public
    returns (bool)
  {
    // solium-disable-next-line security/no-block-members
    uint256 validUntil = now.add(_time); //solhint-disable-line

    require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
    require(_amount != 0, AMOUNT_ZERO);

    if (locked[_to][_reason].amount == 0)
      lockReason[_to].push(_reason);

    transfer(address(this), _amount);

    locked[_to][_reason] = LockToken(_amount, validUntil, false);
    
    emit Locked(
      _to, 
      _reason, 
      _amount, 
      validUntil
    );
    return true;
  }

  /**
   * @dev Returns tokens locked for a specified address for a
   *   specified reason
   *
   * @param _of The address whose tokens are locked
   * @param _reason The reason to query the lock tokens for
   */
  function tokensLocked(address _of, bytes32 _reason)
    public
    view
    returns (uint256 amount)
  {
    if (!locked[_of][_reason].claimed)
      amount = locked[_of][_reason].amount;
  }
  
  /**
   * @dev Returns tokens locked for a specified address for a
   *   specified reason at a specific time
   *
   * @param _of The address whose tokens are locked
   * @param _reason The reason to query the lock tokens for
   * @param _time The timestamp to query the lock tokens for
   */
  function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
    public
    view
    returns (uint256 amount)
  {
    if (locked[_of][_reason].validity > _time)
      amount = locked[_of][_reason].amount;
  }

  /**
   * @dev Returns total tokens held by an address (locked + transferable)
   * @param _of The address to query the total balance of
   */
  function totalBalanceOf(address _of)
    public
    view
    returns (uint256 amount)
  {
    amount = balanceOf(_of);

    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      amount = amount.add(tokensLocked(_of, lockReason[_of][i]));
    }  
  }  
  
  /**
   * @dev Extends lock for a specified reason and time
   * @param _reason The reason to lock tokens
   * @param _time Lock extension time in seconds
   */
  function extendLock(bytes32 _reason, uint256 _time)
    public
    returns (bool)
  {
    require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);

    locked[msg.sender][_reason].validity += _time;

    emit Locked(
      msg.sender, _reason, 
      locked[msg.sender][_reason].amount, 
      locked[msg.sender][_reason].validity
    );
    return true;
  }
  
  /**
   * @dev Increase number of tokens locked for a specified reason
   * @param _reason The reason to lock tokens
   * @param _amount Number of tokens to be increased
   */
  function increaseLockAmount(bytes32 _reason, uint256 _amount)
    public
    returns (bool)
  {
    require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
    transfer(address(this), _amount);

    locked[msg.sender][_reason].amount += _amount;

    emit Locked(
      msg.sender, _reason, 
      locked[msg.sender][_reason].amount,
      locked[msg.sender][_reason].validity
    );
    return true;
  }

  /**
   * @dev Returns unlockable tokens for a specified address for a specified reason
   * @param _of The address to query the the unlockable token count of
   * @param _reason The reason to query the unlockable tokens for
   */
  function tokensUnlockable(address _of, bytes32 _reason)
    public
    view
    returns (uint256 amount)
  {
    // solium-disable-next-line security/no-block-members
    if (locked[_of][_reason].validity <= now && 
      !locked[_of][_reason].claimed) 
      amount = locked[_of][_reason].amount;
  }

  /**
   * @dev Unlocks the unlockable tokens of a specified address
   * @param _of Address of user, claiming back unlockable tokens
   */
  function unlock(address _of)
    public
    returns (uint256 unlockableTokens)
  {
    uint256 lockedTokens;

    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
      if (lockedTokens > 0) {
        unlockableTokens = unlockableTokens.add(lockedTokens);
        locked[_of][lockReason[_of][i]].claimed = true;
        emit Unlocked(_of, lockReason[_of][i], lockedTokens);
      }
    } 

    if (unlockableTokens > 0)
      this.transfer(_of, unlockableTokens);
  }

  /**
   * @dev Gets the unlockable tokens of a specified address
   * @param _of The address to query the the unlockable token count of
   */
  function getUnlockableTokens(address _of)
    public
    view
    returns (uint256 unlockableTokens)
  {
    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      unlockableTokens = unlockableTokens.add(
        tokensUnlockable(_of, lockReason[_of][i])
      );
    } 
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

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
     * @dev remove an account's access to this role
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
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {
    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The account whose tokens will be burned.
     * @param value uint256 The amount of token to be burned.
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

// File: contracts/Mytoken.sol

contract Mytoken is ERC1132, ERC20Detailed, ERC20Mintable, ERC20Burnable {
  string public constant NAME = "Reborn Dollar";
  string public constant SYMBOL = "REBD";
  uint8 public constant DECIMALS = 18;

  uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(DECIMALS));

  constructor()
    ERC20Burnable()
    ERC20Mintable()
    ERC20Detailed(NAME, SYMBOL, DECIMALS)
    ERC20()
    public
  {
    _mint(msg.sender, INITIAL_SUPPLY);
  }
}