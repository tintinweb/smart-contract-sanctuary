// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract PayableContract {

    uint256 private contractBalance = 0;
    uint256 public testNumber = 0;
    uint256 public validEth = 0.01 ether;

    function payEth() external payable {
        require(msg.value == validEth);
        contractBalance += msg.value;
    }

    function showBalance() external view returns (uint256) {
        return contractBalance;
    }

    function add() external returns (uint256) {
        testNumber += 1;
        return testNumber;
    }

    function withdraw() external {
        (bool sent, bytes memory data) = msg.sender.call{value: contractBalance}("");
        require(sent, "Failed to send Ether");
        contractBalance = 0;
    }
}