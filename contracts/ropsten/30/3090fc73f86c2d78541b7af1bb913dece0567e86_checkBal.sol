pragma solidity ^0.4.24;

contract checkBal{
   mapping (address => uint256) balances;
    function balanceOf(address _owner)public constant returns (uint256 balance) {
        return _owner.balance;
    }
}