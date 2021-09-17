/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

contract whoIsSender {
    
    function who () public view returns (address txOrigin, address msgSender) {
        txOrigin = tx.origin;
        msgSender = msg.sender;
    }
}