/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract newFaucet {
    receive() external payable {}
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function giveMeEth(address payable to, uint amount) public payable {
        require(amount <= 500000000000000000);
        bool result = to.send(amount);
        require(result);
    }
}