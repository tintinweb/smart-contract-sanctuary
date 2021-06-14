/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity ^0.4.22;

contract RichestGame {
    address public richest;
    uint mostSent;
    
    constructor() public {
        richest = msg.sender;
        mostSent = msg.value;
    }
    
    function becomeRichest() public {
        if (msg.value > mostSent) {
            richest.transfer(msg.value);
            richest = msg.sender;
            mostSent = msg.value;
        }
    }
}