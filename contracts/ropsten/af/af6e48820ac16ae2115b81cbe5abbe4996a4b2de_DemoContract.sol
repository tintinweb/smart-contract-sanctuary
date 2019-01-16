pragma solidity ^0.4.24;

contract DemoContract {
    address owner ;
    mapping (address => uint) balance;

    function DemoContract() public {
        owner = msg.sender;
    }
    
    function transfer(address to, uint value) public payable {
        require(balance[owner] > value);
        balance[owner] -= value;
        balance[to] += value;
    }
     
}