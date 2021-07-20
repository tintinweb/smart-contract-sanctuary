/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity ^0.4.26;

contract Faucet{
    function withdraw(uint withdraw_amount) public payable{
        require(withdraw_amount<=1000000000000000000);
        msg.sender.transfer(withdraw_amount);
        //msg.sender合约调用者的地址 
    }
    function () public payable{}
}