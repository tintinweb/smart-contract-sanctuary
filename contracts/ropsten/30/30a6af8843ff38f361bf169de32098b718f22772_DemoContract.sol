pragma solidity ^0.4.24;

contract DemoContract {
    address owner ;
    uint cons = 1;
    mapping (address => uint) balance;

    function DemoContract() public {
        owner = msg.sender;
    }
    
    function transfer(address to, uint value) public payable returns (string){
        if(balance[owner] > value && value == cons * 1 / 10){
            balance[owner] -= value;
            balance[to] += value;
            return "Chuyen tien thanh cong";
        }
        return "Chuyen tien khong thanh cong";
        
    }
     
}