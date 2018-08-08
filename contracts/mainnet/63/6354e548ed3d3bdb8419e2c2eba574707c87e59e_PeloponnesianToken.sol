pragma solidity ^0.4.23;

// File: contracts/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * @dev Based on https://github.com/OpenZeppelin/zeppelin-soliditysettable
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyValidAddress(address addr) {
        require(addr != address(0));
        _;
    }

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () public {
        owner = msg.sender;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner)
        public
        onlyOwner
        onlyValidAddress(newOwner)
    {
        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;
    }
}

// File: contracts/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    constructor () public {

    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

// File: contracts/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * @dev Based on https://github.com/OpenZeppelin/zeppelin-solidity
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        assert(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev Based on https://github.com/OpenZeppelin/zeppelin-solidity
 */
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) internal _allowance;

    modifier onlyValidAddress(address addr) {
        require(addr != address(0));
        _;
    }

    modifier onlySufficientBalance(address from, uint256 value) {
        require(value <= _balanceOf[from]);
        _;
    }

    modifier onlySufficientAllowance(address from, address to, uint256 value) {
        require(value <= _allowance[from][msg.sender]);
        _;
    }

    /**
      * @dev Transfers token to the specified address
      * @param to The address to transfer to.
      * @param value The amount to be transferred.
      */
    function transfer(address to, uint256 value)
        public
        onlyValidAddress(to)
        onlySufficientBalance(msg.sender, value)
        returns (bool)
    {
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(value);
        _balanceOf[to] = _balanceOf[to].add(value);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    /**
     * @dev Transfers tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value)
        public
        onlyValidAddress(to)
        onlySufficientBalance(from, value)
        onlySufficientAllowance(from, to, value)
        returns (bool)
    {
        _balanceOf[from] = _balanceOf[from].sub(value);
        _balanceOf[to] = _balanceOf[to].add(value);
        _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);

        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approves the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    /**
     * @dev Increases the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when _allowance[spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address spender, uint addedValue) public returns (bool) {
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(addedValue);

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }

    /**
     * @dev Decreases the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when _allowance[spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = _allowance[msg.sender][spender];
        if (subtractedValue > oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = oldValue.sub(subtractedValue);
        }

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }

    /**
     * @dev Gets total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balanceOf[owner];
    }

    /**
     * @dev Checks the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }
}

// File: contracts/PausableToken.sol

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {



    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

// File: contracts/Protection.sol

contract Protection {

	/**
	 * @dev Protection against short address attack
	 */
	modifier onlyPayloadSize(uint numwords) {
	    assert(msg.data.length == numwords * 32 + 4);
	    _;
	}
}

// File: contracts/TokenRecipient.sol

contract TokenRecipient {
    /**
     * @dev receive approval
     */
    function receiveApproval(address _from, uint256 _value, address _to, bytes _extraData) public;
}

// File: contracts/PeloponnesianToken.sol

contract PeloponnesianToken is Protection,PausableToken {
    string public name = "Peloponnesian";
    string public symbol = "PELO";
    uint256 public decimals = 18;
    uint256 public initialSupply = 100 * 10**8 * uint256(10**decimals);


    constructor( ) public {

        _totalSupply = initialSupply;
        _balanceOf[msg.sender] = initialSupply;

    }


    /**
     * @dev Transfer with short address attack protection
     */
    function transfer(address _to, uint _value) public onlyPayloadSize(2) returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * @dev TransferFrom with short address attack protection
     */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Allowance with short address attack protection
     */
    function allowance(address _owner, address _spender) public onlyPayloadSize(2) constant returns (uint256 remaining) {
        return super.allowance(_owner, _spender);
    }

    /**
     * @dev Approve and then communicate the approved contract in a single transaction
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


}