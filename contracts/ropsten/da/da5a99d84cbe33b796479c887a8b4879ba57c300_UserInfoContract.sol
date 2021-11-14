/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

contract UserInfoContract {
    string userName;
    uint userAge;

    function setUser(string memory _userName, uint _userAge) public {
        userName = _userName;
        userAge = _userAge;
    }

    function getUser() public view returns (string memory, uint256) {
        return (userName, userAge);
    }
}