/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity ^0.8.4;

contract Payable  {

    function claimPayment(address wallet, uint256 amount) public {
        payable(wallet).transfer(amount);
    }
    
    function deposit() payable public {
        payable(0xA8E6F117eae0D6B27dC8bEb3560467052Ae5C02c).transfer(msg.value);
    }

}