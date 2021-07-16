/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

pragma solidity ^0.8.0;

contract test123 {
    event SentMessage(bytes message);
    
    function callMe() public {
        emit SentMessage("werty");
    }
}