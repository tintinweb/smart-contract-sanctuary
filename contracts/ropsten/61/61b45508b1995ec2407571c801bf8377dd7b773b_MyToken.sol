pragma solidity ^0.4.24;

contract MyToken {
    mapping(address => uint) balances;
    function updateBalance(address someone, uint newValue) private {
        balances[someone] = newValue;
    }
    function increaseBalance(address someone) public {
        updateBalance(someone, balances[someone] + 1);
    }
    function queryBalance(address someone) public view returns (uint) {
        return balances[someone];
    }
}