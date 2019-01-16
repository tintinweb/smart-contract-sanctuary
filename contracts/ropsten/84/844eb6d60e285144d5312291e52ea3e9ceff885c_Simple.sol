pragma solidity ^0.4.24;

contract Simple{
    function transfer(address to) public payable returns (string)  {
        if(msg.sender.balance <= msg.value ){
            return "Tai khoang khong du thuc hien giao dich";
        }
        else{
            to.transfer(msg.value);
        }
        return "Giao dich thanh cong";
    }
}