//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DrainFunds {

    receive() external payable {}

    function withdraw(uint _amt) external payable {
        payable(msg.sender).transfer(_amt);
    }

    function balance() external view returns(uint) {
        return address(this).balance;
    }
}