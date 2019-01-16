pragma solidity ^0.4.24;

contract Simple{
    address owner;
    mapping (address => uint) balance;

    function Simple() public{
        owner = msg.sender;
    }

    function transfer(address to, uint value) public payable returns (string)  {
        if(owner.balance <= value ){
            return "Tai khoang khong du thuc hien giao dich";
        }
        else{
            balance[owner] -= value;
            balance[to] += value;
        }
        return "Giao dich thanh cong";
    }
}