/**
 *Submitted for verification at polygonscan.com on 2021-07-20
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: GPL-3.0-or-later

contract URL {

    string public url;
    address public index;
 
    function record (
       string memory Url,
       address payable Index
              ) public
   {
       url = Url;
       index = Index;
       uint256 amount = 37137;
       
       Index.transfer(amount);
    }
}