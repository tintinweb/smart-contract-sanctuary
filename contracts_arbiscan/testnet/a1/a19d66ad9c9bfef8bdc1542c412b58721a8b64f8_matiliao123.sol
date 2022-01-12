/**
 *Submitted for verification at arbiscan.io on 2022-01-11
*/

pragma solidity ^0.7.0;

contract matiliao123 {

    function kill(address payable addr) public payable {
        selfdestruct(addr);
    }

   receive() external payable {

    }
}