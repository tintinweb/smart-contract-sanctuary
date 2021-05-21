/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity ^0.8.4;

contract Payable  {

    function claimPayment(address wallet, uint256 amount) public {
        payable(wallet).transfer(amount);
    }

}