/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

pragma solidity 0.8.6;

contract Test13 {
    
    address public txorigin;
    address public msgsender;
    
    constructor() {
        txorigin = tx.origin;
        msgsender = msg.sender;
    }
    
    function changeTxorigin() public {
        txorigin = tx.origin;
        msgsender = msg.sender;
    }
}