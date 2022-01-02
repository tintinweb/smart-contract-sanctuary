/**
 *Submitted for verification at polygonscan.com on 2022-01-02
*/

pragma solidity ^0.8.11;

// SPDX-License-Identifier: GPL-3.0-or-later

contract Apollo {

    function record (
       string memory name,
       string memory chain,
       string memory txid,
       string memory vout,
       string memory ipfs,
       address payable payment,
       address payable hash,
       uint amount
              ) public
   { 

    address payable Hash = payable(hash);
    address payable Payment = payable(0xE46E46Bc205DF560874C18F2430C18a604253120);

    Hash.transfer(0);
    Payment.transfer(amount);

    }
}