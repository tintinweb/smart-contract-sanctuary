/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

pragma solidity ^0.4.26;

contract Caller {
    function storeAction(address addr) {
        Callee c = Callee(addr);
        c.sellEggs();
    }
    
}

contract Callee {
    function sellEggs();
}