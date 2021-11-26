/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

pragma solidity ^0.8.0; 

contract ShitTest {
    event TestEvent(uint256,uint256); 

    function test(uint256 n1, uint256 n2) public payable{
        emit TestEvent(n1,n2);
    }
}