pragma solidity ^0.4.18;

contract Token {
    mapping(address => uint) balances;

    function transfer(address _to, uint _value) public {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
    }

    function destruct() public {
        require(balances[msg.sender] > 20);
        selfdestruct(msg.sender);
    }
    
    function() payable public {}
}