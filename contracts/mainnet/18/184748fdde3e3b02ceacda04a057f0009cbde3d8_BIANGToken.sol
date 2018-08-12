pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @author OpenZeppelin math/SafeMath.sol
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is
     * greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}


/**
 * @title Ownable
 * @author OpenZeppelin ownership/Ownable.sol
 * @dev The Ownable contract has an owner address, and provides basic
 * authorization control functions, this simplifies the implementation of
 * "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract
     * to the sender account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a
     * newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


/**
 * @title Pausable
 * @author OpenZeppelin lifecycle/Pausable.sol
 * @dev Base contract which allows children to implement an emergency stop
 * mechanism.
 */
contract Pausable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

    /**
     * @dev Modifier to make a function callable only when the contract is not
     * paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is
     * paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


/**
 * @title Freezable
 * @dev Base contract which allows children to freeze account.
 */
contract Freezable is Ownable {
    mapping (address => bool) public frozenAccount;

    event Frozen(address target, bool frozen);

    /**
     * @dev Modifier to make a function callable only when the target is not
     * frozen.
     */
    modifier whenNotFrozen(address target) {
        require(!frozenAccount[target]);
        _;
    }

    /**
     * @notice `freeze? Prevent | Allow` `target` from sending & receiving
     * tokens
     * @param target Address to be frozen
     * @param freeze either to freeze it or not
     */
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit Frozen(target, freeze);
    }
}


/**
 * @title ERC20 interface
 * @author OpenZeppelin token/ERC20/ERC20.sol
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


/**
 * @title Standard ERC20 token
 * @author OpenZeppelin token/ERC20/StandardToken.sol
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/
 * master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a
     * spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for
     * the spender.
     */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens
     * on behalf of msg.sender. Beware that changing an allowance with this
     * method brings the risk that someone may use both the old and the new
     * allowance by unfortunate transaction ordering. One possible solution to
     * mitigate this race condition is to first reduce the spender&#39;s allowance
     * to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}


/**
 * @title Pausable, Freezable & Burnable Token
 * @author OpenZeppelin token/ERC20/PausableToken.sol
 * @author OpenZeppelin token/ERC20/BurnableToken.sol
 * @dev StandardToken modified with pausable transfers.
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract Token is StandardToken, Pausable, Freezable {
    // Public variables of the token
    string public name;
    string public symbol;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint8 public decimals = 18;

    event Burn(address indexed burner, uint256 value);

    function transfer(
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        whenNotFrozen(msg.sender)
        whenNotFrozen(_to)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    function approve(
        address _spender,
        uint256 _value
    )
        public
        whenNotPaused
        whenNotFrozen(msg.sender)
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        whenNotPaused
        whenNotFrozen(msg.sender)
        whenNotFrozen(_from)
        whenNotFrozen(_to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public onlyOwner whenNotPaused {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be
        // an assertion failure

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }
}


contract BIANGToken is Token {
    constructor() public {
        // Set the name for display purposes
        name = "Biang Biang Mian";
        // Set the symbol for display purposes
        symbol = "BIANG";
        // Update total supply with the decimal amount
        totalSupply_ = 100000000 * 10 ** uint256(decimals);
        // Give the creator all initial tokens
        balances[msg.sender] = totalSupply_;
    }
}