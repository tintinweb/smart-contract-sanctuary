pragma solidity ^0.4.18;

contract Token {

    mapping(address => uint) balances;
    uint public totalSupply;

    function transfer(address _to, uint _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        return true;
    }

    function destruct() public {
        require(balances[msg.sender] > 20);
        selfdestruct(msg.sender);
    }
    
    function() payable public {}
}