/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: GPL-3.0-or-later

contract IPFS {

    string public url;
    address public owner;


 constructor() {
      owner = msg.sender;
   }

    function record (string memory Url) public
   {
       if(msg.sender == owner)
                          url = Url;
   }
}