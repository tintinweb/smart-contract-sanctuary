/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

pragma solidity ^0.8.1;

contract SendMoneyExample {
    uint public balanceReceived;

    function receiveMoney() public payable {
        require(msg.value > 0);
        balanceReceived += msg.value;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance / (10**18);
    }


}