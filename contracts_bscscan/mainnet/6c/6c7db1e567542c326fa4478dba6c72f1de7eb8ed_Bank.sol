/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Bank {
    address public owner = msg.sender;

    address[] public members;

    constructor() {
        members.push(msg.sender);
    }

    modifier onlyAdmin {
        require(msg.sender == owner);
        _;
    }
    
    fallback() external payable {}

    receive() external payable {}

    function addMember(address addr) public onlyAdmin {
        members.push(addr);
    }

    function removeMember(address addr) public onlyAdmin {
        address[] memory newMembers = new address[](members.length-1);
        uint j = 0;
        for(uint i = 0; i < members.length; i++) {
            if(members[i] == addr) continue;
            newMembers[j] = members[i];
            j++;
        }
        members = newMembers;
    }

    function withdraw() public {
        uint count = members.length;
        uint256 value = address(this).balance;
        uint256 point = value / count;

        for(uint i = 0; i < count; i++) {
            value -= point;
            payable(members[i]).transfer(point);
        }

        if(count > 0 && value > 0) {
            payable(members[0]).transfer(value);
        }
    }
}