/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract second {
    uint storedData;

    function set(uint x) public {
     
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}

// avatar: "https://s.gravatar.com/avatar/55863b60cf85c3f56222a8acd6ad513a?d=mm"
// createdAt: "2021-09-02T15:22:56.000Z"
// email: "[email protected]"
// name: "Muzammil"
// role: "student"
// userId: "62990995"