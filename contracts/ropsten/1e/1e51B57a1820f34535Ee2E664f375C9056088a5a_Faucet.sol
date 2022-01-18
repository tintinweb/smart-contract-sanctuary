/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: CC-BY-SA-4.0
pragma solidity >=0.7.0 <0.9.0;

contract Faucet {

    function withdraw(uint withdrawAmount) public {
        require(withdrawAmount < 1 ether);
        payable(msg.sender).transfer(withdrawAmount);
    }

    receive() external payable {}

    function close() public {
        selfdestruct(payable(msg.sender));
    }
}