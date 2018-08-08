pragma solidity ^0.4.21;

/**
 * Math operations with safety checks
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
        assert(c>=a && c>=b);
        return c;
   }
}


contract BTBToken is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    bool public isContractFrozen;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping (address => uint256) public freezeOf;

    mapping (address => string) public btbAddressMapping;


    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* This notifies clients about the contract frozen */
    event Freeze(address indexed from, string content);

    /* This notifies clients about the contract unfrozen */
    event Unfreeze(address indexed from, string content);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function BTBToken() public {
        totalSupply = 10*10**26;                        // Update total supply
        balanceOf[msg.sender] = totalSupply;              // Give the creator all initial tokens
        name = "BiTBrothers";                                   // Set the name for display purposes
        symbol = "BTB";                               // Set the symbol for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
        owner = msg.sender;
        isContractFrozen = false;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) external returns (bool success) {
        assert(!isContractFrozen);
        assert(_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        assert(_value > 0);
        assert(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        assert(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) external returns (bool success) {
        assert(!isContractFrozen);
        assert(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        assert(!isContractFrozen);
        assert(_to != 0x0);                                // Prevent transfer to 0x0 address. Use burn() instead
        assert(_value > 0);
        assert(balanceOf[_from] >= _value);                 // Check if the sender has enough
        assert(balanceOf[_to] + _value >= balanceOf[_to]);  // Check for overflows
        assert(_value <= allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) external returns (bool success) {
        assert(!isContractFrozen);
        assert(msg.sender == owner);
        assert(balanceOf[msg.sender] >= _value);            // Check if the sender has enough
        assert(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
	
    function freeze() external returns (bool success) {
        assert(msg.sender == owner);
        assert(!isContractFrozen);
        isContractFrozen = true;
        emit Freeze(msg.sender, "contract is frozen");
        return true;
    }
	
    function unfreeze() external returns (bool success) {
        assert(msg.sender == owner);
        assert(isContractFrozen);
        isContractFrozen = false;
        emit Unfreeze(msg.sender, "contract is unfrozen");
        return true;
    }

    function setBTBAddress(string btbAddress) external returns (bool success) {
        assert(!isContractFrozen);
        btbAddressMapping[msg.sender] = btbAddress;
        return true;
    }
    // transfer balance to owner
    function withdrawEther(uint256 amount) external {
        assert(msg.sender == owner);
        owner.transfer(amount);
    }
	
    // can accept ether
    function() public payable {
    }
}