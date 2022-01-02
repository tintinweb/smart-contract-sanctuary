/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

pragma solidity ^0.8.11;

// SPDX-License-Identifier: GPL-3.0-or-later

contract Apollo {
    address public owner;


 constructor() {
      owner = msg.sender;
   }


    function record (
       string memory name,
       string memory chain,
       string memory txid,
       string memory vout,
       string memory ipfs,
       uint256 amount,
       address payable hash
              ) public
   {

    address payable Hash = payable(hash);
    address payable Payment = payable(owner);

    Hash.transfer(0);
    Payment.transfer(amount);

    }

   function cashout (
      uint256 amount ) public
{
    address payable Payment = payable(owner);
       if(msg.sender == owner)
            Payment.transfer(amount);

}

    fallback () payable external {}
    receive () payable external {}

}