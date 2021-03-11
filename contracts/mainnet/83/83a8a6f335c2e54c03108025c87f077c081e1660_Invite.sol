/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// File: contracts/storage/InviteStorage.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library InviteStorage {

    bytes32 public constant sSlot = keccak256("InviteStorage.storage.location");

    struct Storage{
        address owner;
        uint256 lastId;
        mapping(uint256 => address)  indexs;
        mapping(address => address)  inviter;
        mapping(address => address[])  inviterList;
        mapping(address => bool)  whiteListed;
        mapping(address => uint256)  userIndex;
    }

    function load() internal pure returns (Storage storage s) {
        bytes32 loc = sSlot;
        assembly {
        s_slot := loc
        }
    }

}

// File: contracts/market/Invite.sol


pragma solidity ^0.6.12;



contract Invite {


    constructor(uint256 index)public{
        init(index);
    }
    modifier onlyOwner() {
        require(InviteStorage.load().owner == msg.sender, "Invite.onlyOwner: caller is not the owner");
        _;
    }

    function init(uint256 index)public{
        require(InviteStorage.load().owner==address(0),'Invite.init: already initialised');
        InviteStorage.load().owner=msg.sender;
        InviteStorage.load().lastId = index;
    }

    function owner()public view returns(address){
        return InviteStorage.load().owner;
    }

    function setWhiteList(address[] memory users) public onlyOwner{
        InviteStorage.Storage storage inviteData=InviteStorage.load();
        for(uint256 i=0;i<users.length;i++){
            address user=users[i];
            inviteData.whiteListed[user] = true;
            if(inviteData.userIndex[user] == 0){
                inviteData.userIndex[user] = inviteData.lastId;
                inviteData.indexs[inviteData.lastId] = user;
                inviteData.lastId = inviteData.lastId + 1;
            }
        }

    }

    function setInviteUser(address inviteUser) public{
        InviteStorage.Storage storage inviteData=InviteStorage.load();
        require(!inviteData.whiteListed[msg.sender], 'whiteList user cannot be invited');
        if(inviteData.userIndex[msg.sender] == 0){
            inviteData.userIndex[msg.sender] = inviteData.lastId;
            inviteData.indexs[inviteData.lastId] = msg.sender;
            inviteData.lastId = inviteData.lastId + 1;
        }

        if(inviteData.whiteListed[inviteUser] || inviteData.inviter[inviteUser] != address(0)){
            inviteData.inviter[msg.sender] = inviteUser;
            inviteData.inviterList[inviteUser].push(msg.sender);
        }
    }

    function getInviteCount(address user) external view returns (uint256) {
        return InviteStorage.load().inviterList[user].length;
    }

    function lastId()public view returns(uint256){
        return InviteStorage.load().lastId;
    }

    function indexs(uint256 id)public view returns(address){
        return InviteStorage.load().indexs[id];
    }

    function inviter(address user)public view returns(address){
        return InviteStorage.load().inviter[user];
    }

    function inviterList(address user)public view returns(address[] memory){
        return InviteStorage.load().inviterList[user];
    }

    function whiteListed(address user)public view returns(bool){
        return InviteStorage.load().whiteListed[user];
    }

    function userIndex(address user)public view returns(uint256){
        return InviteStorage.load().userIndex[user];
    }
}