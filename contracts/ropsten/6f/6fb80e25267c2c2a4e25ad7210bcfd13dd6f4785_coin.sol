pragma solidity ^0.4.24;

contract coin {
    address owner;
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balances; 

    event Transfer(address indexed from, address indexed to, uint256 value);     
    
    constructor() public payable {
        owner = msg.sender;
        name = "Winnetou";                                   
        symbol = "wnto";         
        uint256 initialSupply = 10000;
        totalSupply = initialSupply * 10 ** uint256(decimals);  
        balances[msg.sender] = totalSupply;    
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // Check if the sender has enough
        require(balances[msg.sender] >= _value);
        // Subtract from the sender
        balances[msg.sender] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value); 
        return true;       
    }    
    

    function kill() public
    { 
        if (msg.sender == owner)
            selfdestruct(owner);
    } 
}