pragma solidity ^0.4.16;

contract MininumViableToken{
    
    string public constant name = &quot;test1&quot;;
    string public constant symbol =&quot;test&quot;;
    uint8 public constant decimals = 18;
    
    address creator = 0x6FdcF3b30abffc803476374f590ccf6c6ef12820;
    
    mapping (address => uint256) public balanceof;
    
    
    constructor () public{
        balanceof[msg.sender] = 3000000000;
    }
    
    function transfer(address _to, uint256 _value) public{
        require(_value <= balanceof[msg.sender]);
        require(balanceof[_to] + _value >= balanceof[_to]);
        
        balanceof[msg.sender] -= _value;
        balanceof[_to] += _value;
    }
    
    function kill() external{
        if(msg.sender == creator)
            selfdestruct(creator);
    }
}