/**
 *Submitted for verification at Etherscan.io on 2021-02-28
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// File: RoyaltyAllowance.sol

contract RoyaltyAllowance {

    mapping(address => uint256) allowance;
    mapping(address => bool) validUser;
    address[] members;
    uint256[] shares;

    constructor() public {
        validUser[msg.sender] = true;
    }

    modifier teamMember {
        require(validUser[msg.sender] == true);
        _;
    }

    receive() external payable {

        for(uint i = 0; i < members.length; i++) {
            allowance[members[i]] += (msg.value * shares[i]) / 100;
        }

    }

    function addTeamMember(address member, uint256 share) external teamMember {
        validUser[member] = true;
        members.push(member);
        shares.push(share);

        uint256 total;
        for(uint i = 0; i < shares.length; i++) {
            total += shares[i];
        }
        require(total <= 100, "Total shares already equal 100!");
    }

    function removeTeamMember(address member) external teamMember {
        uint index;
        for(uint i = 0; i < members.length; i++) {
            if(members[i] == msg.sender) {
                index = i;
            }
        }

        delete members[index];
        delete shares[index];

    }

    function changeMemberShare(address member, uint256 share) external teamMember {
        uint256 index;
        for(uint i = 0; i < members.length; i++) {
            if(members[i] == msg.sender) {
                shares[index] = share;
                break;
            }
        }

        uint256 total;
        for(uint i = 0; i < shares.length; i++) {
            total += shares[i];
        }
        require(total <= 100, "Total shares already equal 100!");
    }

    function claimRoyalties() external payable teamMember {
        require(allowance[msg.sender] > 0, "You have no royalties to claim");
        payable(msg.sender).transfer(allowance[msg.sender]);
    }

}