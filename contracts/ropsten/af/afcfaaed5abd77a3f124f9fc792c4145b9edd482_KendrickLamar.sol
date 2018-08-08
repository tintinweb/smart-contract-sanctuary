pragma solidity ^0.4.20;

contract KendrickLamar {
    /* This creates an array with all balances */
     string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping (address => uint256) public balanceOf;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken(
        uint256 initialSupply
        ) public {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
    }
    
    function FucksToken() public {
        symbol = "DAMN";
        name = "TopDawgEntertainment";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[0x5c7AD20DC173dFa74C18E892634E1CA27E8E472F] = _totalSupply;
    }
    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
    }
}