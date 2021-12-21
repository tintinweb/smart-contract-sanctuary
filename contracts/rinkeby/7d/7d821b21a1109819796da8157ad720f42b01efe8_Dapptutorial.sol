/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Dapptutorial.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.6 <0.9.0;

////// src/Dapptutorial.sol
/* pragma solidity ^0.8.6; */

contract Dapptutorial {
    receive() external payable {
    }

    function withdraw(uint password) public {
        require(password == 42, "Access denied!");
        payable(msg.sender).transfer(address(this).balance);
    }
}