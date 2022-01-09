/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-08
*/

pragma solidity ^0.5.11;

contract Working2{
    uint public balanceReceived;

    function receiveMoney() public payable{
        balanceReceived += msg.value;
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function withdrawMoney() public{
        address payable to = msg.sender;
        to.transfer(this.getBalance());

    }
    function withdrawMoneyTo(address payable _to) public{
        _to.transfer(this.getBalance());
    }
}