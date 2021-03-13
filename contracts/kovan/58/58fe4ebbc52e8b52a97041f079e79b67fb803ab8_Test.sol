/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity ^0.6.6;
contract Test {
 	function deposit() public payable {
        // nothing to do!
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }


	function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }

}