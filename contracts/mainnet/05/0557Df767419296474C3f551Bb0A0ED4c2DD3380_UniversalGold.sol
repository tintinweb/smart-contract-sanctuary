// File: openzeppelin-solidity/contracts/access/Roles.sol

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

// File: contracts/ProxyToken/ProxyTokenBurnerRole.sol

pragma solidity ^0.5.0;


contract ProxyTokenBurnerRole {
  using Roles for Roles.Role;

  event BurnerAdded(address indexed account);
  event BurnerRemoved(address indexed account);

  Roles.Role private burners;

  constructor() internal {
    _addBurner(msg.sender);
  }

  modifier onlyBurner() {
    require(isBurner(msg.sender), "Sender does not have a burner role");

    _;
  }

  function isBurner(address account) public view returns (bool) {
    return burners.has(account);
  }

  function addBurner(address account) public onlyBurner {
    _addBurner(account);
  }

  function renounceBurner() public {
    _removeBurner(msg.sender);
  }

  function _addBurner(address account) internal {
    burners.add(account);
    emit BurnerAdded(account);
  }

  function _removeBurner(address account) internal {
    burners.remove(account);
    emit BurnerRemoved(account);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
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

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
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
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
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
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
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
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

// File: contracts/ProxyToken/ProxyTokenBurnable.sol

pragma solidity ^0.5.0;



/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ProxyTokenBurnable is ERC20, ProxyTokenBurnerRole {
  mapping (address => mapping (address => uint256)) private _burnAllowed;

  event BurnApproval(address indexed owner, address indexed spender, uint256 value);

  /**
   * @dev Modifier to check if a burner can burn a specific amount of owner's tokens.
   * @param burner address The address which will burn the funds.
   * @param owner address The address which owns the funds.
   * @param amount uint256 The amount of tokens to burn.
   */

  modifier onlyWithBurnAllowance(address burner, address owner, uint256 amount) {
    if (burner != owner) {
      require(burnAllowance(owner, burner) >= amount, "Not enough burn allowance");
    }
    _;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to burn.
   * @param owner address The address which owns the funds.
   * @param burner address The address which will burn the funds.
   * @return A uint256 specifying the amount of tokens still available to burn.
   */
  function burnAllowance(address owner, address burner) public view returns (uint256) {
    return _burnAllowed[owner][burner];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a burner to burn.
   * @param burner The address which will burn the funds.
   * @param addedValue The increased amount of tokens to be burnt.
   */
  function increaseBurnAllowance(address burner, uint256 addedValue) public returns (bool) {
    require(burner != address(0), "Invalid burner address");

    _burnAllowed[msg.sender][burner] = _burnAllowed[msg.sender][burner].add(addedValue);

    emit BurnApproval(msg.sender, burner, _burnAllowed[msg.sender][burner]);

    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a burner to burn.
   * @param burner The address which will burn the funds.
   * @param subtractedValue The subtractedValue amount of tokens to be burnt.
   */
  function decreaseBurnAllowance(address burner, uint256 subtractedValue) public returns (bool) {
    require(burner != address(0), "Invalid burner address");

    _burnAllowed[msg.sender][burner] = _burnAllowed[msg.sender][burner].sub(subtractedValue);

    emit BurnApproval(msg.sender, burner, _burnAllowed[msg.sender][burner]);

    return true;
  }

  /**
   * @dev Function to burn tokens
   * @param amount The amount of tokens to burn.
   * @return A boolean that indicates if the operation was successful.
   */
  function burn(uint256 amount)
    public
    onlyBurner
  returns (bool) {
    _burn(msg.sender, amount);

    return true;
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param account address The address which you want to send tokens from
   * @param amount uint256 The amount of token to be burned
   */
  function burnFrom(address account, uint256 amount)
    public
    onlyBurner
    onlyWithBurnAllowance(msg.sender, account, amount)
  returns (bool) {
    _burnAllowed[account][msg.sender] = _burnAllowed[account][msg.sender].sub(amount);

    _burn(account, amount);

    emit BurnApproval(account, msg.sender, _burnAllowed[account][msg.sender]);

    return true;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


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

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;


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

pragma solidity ^0.5.0;



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

// File: contracts/ProxyToken/ProxyToken.sol

pragma solidity ^0.5.0;





/**
 * @title ProxyToken
 */
contract ProxyToken is ERC20, ERC20Detailed, ERC20Mintable, ProxyTokenBurnable {
  /**
  * @notice Constructor for the ProxyToken
  * @param owner owner of the initial proxy tokens
  * @param name name of the proxy token
  * @param symbol symbol of the proxy token
  * @param decimals divisibility of proxy token
  * @param initialProxySupply initial amount of proxy tokens
  */
  constructor(
    address owner,
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 initialProxySupply)
  public ERC20Detailed(name, symbol, decimals) {
    mint(owner, initialProxySupply * (10 ** uint256(decimals)));

    if (owner == msg.sender) {
      return;
    }

    addBurner(owner);
    addMinter(owner);
    renounceBurner();
    renounceMinter();
  }
}

// File: contracts/ProxyToken/instances/UniversalGold.sol

pragma solidity ^0.5.0;


/**
 * @title UniversalGold
 */
contract UniversalGold is ProxyToken {
  /**
  * @notice Constructor for the UniversalGold
  * @param owner owner of the initial proxy tokens
  */
  constructor(address owner) public ProxyToken(owner, "Universal Gold", "UPXAU", 5, 0) {} // solium-disable-line no-empty-blocks
}