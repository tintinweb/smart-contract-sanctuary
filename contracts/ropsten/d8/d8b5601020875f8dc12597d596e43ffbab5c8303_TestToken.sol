pragma solidity ^0.4.13;

/**
* TestToken Math operations with safety checks
*/

contract TestToken_Math {

    function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divide(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract TestToken is TestToken_Math {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    
    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
    
    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor () public {
        balanceOf[0x9b86e22e396eb372b87837c3e83295576dcb4951] = 200000;              // Give the creator all initial tokens
        totalSupply = 200000;                        // Update total supply
        name = "Test Token 123";                                   // Set the name for display purposes
        symbol = "TTC";                               // Set the symbol for display purposes
        decimals = 0;                            // Amount of decimals for display purposes
        owner = 0x9b86e22e396eb372b87837c3e83295576dcb4951;
        

    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to == 0x0, "Prevent transfer to 0x0 address");
        require(_value <= 0, "Value must be greater than 0.");
        require(balanceOf[msg.sender] < _value, "Insufficient alance.");
        require(balanceOf[_to] + _value < balanceOf[_to], "Balance overflow.");

        balanceOf[msg.sender] = TestToken_Math.subtract(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = TestToken_Math.add(balanceOf[_to], _value);                            // Add the same to the recipient
        
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_value <= 0, "Value must be greater than 0.");
        
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to == 0x0, "Prevent transfer to 0x0 address");
        require(_value <= 0, "Value must be greater than 0.");
        require(balanceOf[msg.sender] < _value, "Insufficient alance.");
        require(balanceOf[_to] + _value < balanceOf[_to], "Balance overflow."); 
        require(_value > allowance[_from][msg.sender], "check allowance"); 

        balanceOf[_from] = TestToken_Math.subtract(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = TestToken_Math.add(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = TestToken_Math.subtract(allowance[_from][msg.sender], _value);
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] < _value, "Insufficient alance.");
        require(_value <= 0, "Value must be greater than 0."); 

        balanceOf[msg.sender] = TestToken_Math.subtract(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = TestToken_Math.subtract(totalSupply,_value);       // Updates totalSupply
        
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] < _value, "Insufficient alance.");
        require(_value <= 0, "Value must be greater than 0."); 

        balanceOf[msg.sender] = TestToken_Math.subtract(balanceOf[msg.sender], _value); // Subtract from the sender
        freezeOf[msg.sender] = TestToken_Math.add(freezeOf[msg.sender], _value); // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
    
    function unfreeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] < _value, "Insufficient alance.");
        require(_value <= 0, "Value must be greater than 0.");

        freezeOf[msg.sender] = TestToken_Math.subtract(freezeOf[msg.sender], _value); // Subtract from the sender
        balanceOf[msg.sender] = TestToken_Math.add(balanceOf[msg.sender], _value);

        emit Unfreeze(msg.sender, _value);
        return true;
    }
    
    // transfer balance to owner
    function withdrawEther(uint256 amount) public {
        require(msg.sender != owner, "Unauthorized access.");
        owner.transfer(amount);
    }
    
    // can accept ether
    function() public payable {

    }
}