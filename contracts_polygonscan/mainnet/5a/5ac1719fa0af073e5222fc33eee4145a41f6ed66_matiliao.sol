/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

pragma solidity ^0.7.0;

contract matiliao {
        
    function kill(address payable addr) public payable {
        selfdestruct(addr);
    }
}