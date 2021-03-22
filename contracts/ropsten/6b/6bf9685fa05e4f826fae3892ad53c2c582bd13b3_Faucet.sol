/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity >=0.7.0 <0.8.0;
contract Faucet{
    function withdraw(uint withdraw_amount) public{
        require(withdraw_amount<=100000000000000000);
        msg.sender.transfer(withdraw_amount);
    }
    
     fallback () payable external {}
     receive () payable external {}

}