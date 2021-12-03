// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./IHelp.sol";

contract Referrals is Ownable {

    using SafeMath for uint256;

    struct MemberStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        uint256 referredUsers;
        uint256 time;
    }
    mapping(address => MemberStruct) public members; // Membership structure
    mapping(uint256 => address) public membersList; // Member listing by id
    mapping(uint256 => mapping(uint256 => address)) public memberChild; // List of referrals by user
    uint256 public lastMember; // ID of the last registered member
    
    // Only owner can register new users
    function addMember(address _member, address _parent) public onlyOwner {
        if (lastMember > 0) {
            require(members[_parent].isExist, "Sponsor not exist");
        }
        MemberStruct memory memberStruct;
        memberStruct = MemberStruct({
            isExist: true,
            id: lastMember,
            referrerID: members[_parent].id,
            referredUsers: 0,
            time: block.timestamp
        });
        members[_member] = memberStruct;
        membersList[lastMember] = _member;
        memberChild[members[_parent].id][members[_parent].referredUsers] = _member;
        members[_parent].referredUsers++;
        lastMember++;
        emit eventNewUser(msg.sender, _member, _parent);
    }

    // Returns the list of referrals
    function getListReferrals(address _member) public view returns (address[] memory){
        address[] memory referrals = new address[](members[_member].referredUsers);
        if(members[_member].referredUsers > 0){
            for (uint256 i = 0; i < members[_member].referredUsers; i++) {
                if(memberChild[members[_member].id][i] != address(0)){
                    referrals[i] = memberChild[members[_member].id][i];
                } else {
                    break;
                }
            }
        }
        return referrals;
    }

    // Returns the address of the sponsor of an account
    function getSponsor(address account) public view returns (address) {
        return membersList[members[account].referrerID];
    }

    // Check if an address is registered
    function isMember(address _user) public view returns (bool) {
        return members[_user].isExist;
    }    

    event eventNewUser(address _mod, address _member, address _parent);

}