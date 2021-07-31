/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

/**
 *Submitted for verification at polygonscan.com on 2021-07-23
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: GPL-3.0-or-later

contract URL {

    string public url;
    string public title;

    function record (
       string memory Url,
       string memory Title
              ) public
   {
       url = Url;
       title = Title;
   }
}