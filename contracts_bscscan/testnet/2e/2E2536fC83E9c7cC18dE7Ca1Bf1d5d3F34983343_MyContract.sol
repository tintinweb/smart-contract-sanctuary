/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

pragma solidity ^0.5.11;

contract MyContract{

    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }

    function contribute(uint256 amount) payable public {
        require(msg.value == amount);
        // nothing else to do!
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}