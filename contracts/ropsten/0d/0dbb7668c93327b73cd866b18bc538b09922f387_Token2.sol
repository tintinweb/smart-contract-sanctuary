pragma solidity ^0.4.18;

contract Token2 {

    mapping(address => uint) balances;

    function transfer(uint _value) public {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
    }
 
    function destruct() public {
        require(balances[msg.sender] > 0);
        selfdestruct(msg.sender);
    }
    
    function() payable public {}
}