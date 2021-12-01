//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DrainFunds {

    receive() external payable {}

    function withdraw() external payable {
        payable(msg.sender).transfer(address(this).balance);
    }

    function balance() external view returns(uint) {
        return address(this).balance;
    }
}