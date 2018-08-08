pragma solidity ^0.4.11;

/**
 * @title Snow Coin
 * @author lan yuhang
 */

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
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
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


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

contract SNC is SafeMath, Pausable {

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    address public owner;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function SNC() public {
        totalSupply = (10**8) * (10**8);
        name = "Snow Coin";                                 // Set the name for display purposes
        symbol = "SNC";                                     // Set the symbol for display purposes
        decimals = 8;                                       // Amount of decimals for display purposes
        owner = msg.sender;
        balanceOf[owner] = totalSupply;                     // Give the creator all tokens
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);              // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);    // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);   // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                 // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                  // Notify anyone listening that this transfer took place
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        allowance[msg.sender][_spender] = _value;            // Set allowance
        emit Approval(msg.sender, _spender, _value);              // Raise Approval event
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(balanceOf[_from] >= _value);                  // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);   // Check for overflows
        require(_value <= allowance[_from][msg.sender]);      // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);    // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);        // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function totalSupply() constant public returns (uint256 Supply) {
        return totalSupply;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balanceOf[_owner];
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    function() public payable {
        revert();
    }
}