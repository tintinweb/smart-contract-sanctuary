/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Attendance{
    uint256[]rollNumber;

    function request(uint256 _rollNumber)public
    {
        rollNumber.push(_rollNumber);
    }

    function getRequests() public view returns(uint256[] memory)
    {
        return rollNumber;
    }
}