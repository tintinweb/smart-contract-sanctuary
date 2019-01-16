pragma solidity ^0.4.24;

contract Simple{
    function transfer(address to, uint value) public payable returns (string)  {
        if(msg.sender.balance <= value ){
            return "Tai khoang khong du thuc hien giao dich";
        }
        else{
            to.transfer(value);
        }
        return "Giao dich thanh cong";
    }
}