/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// File: contracts/Whitelist.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

contract Whitelist {
    uint256 groupId;
    address public whiteListManager;
    struct WhitelistGroup {
        mapping(address => bool) members;
        mapping(address => bool) whitelistGroupAdmin;
        bool created;
    }
    mapping(uint256 => WhitelistGroup) private whitelistGroups;
    event GroupCreated(address, uint256);

    constructor() public {
        whiteListManager = msg.sender;
    }

    modifier onlyWhitelistManager {
        require(
            msg.sender == whiteListManager,
            "Only Whitelist manager can call this function."
        );
        _;
    }

    /// @dev Function to change the whitelist manager of Yieldster.
    /// @param _manager Address of the new manager.
    function changeManager(address _manager) public onlyWhitelistManager {
        whiteListManager = _manager;
    }

    /// @dev Function that returns if a whitelist group is exist.
    /// @param _groupId Group Id of the whitelist group.
    function _isGroup(uint256 _groupId) private view returns (bool) {
        return whitelistGroups[_groupId].created;
    }

    /// @dev Function that returns if the msg.sender is the whitelist group admin.
    /// @param _groupId Group Id of the whitelist group.
    function _isGroupAdmin(uint256 _groupId) public view returns (bool) {
        return whitelistGroups[_groupId].whitelistGroupAdmin[msg.sender];
    }

    /// @dev Function to create a new whitelist group.
    /// @param _whitelistGroupAdmin Address of the whitelist group admin.
    function createGroup(address _whitelistGroupAdmin)
        public
        returns (uint256)
    {
        groupId += 1;
        require(!whitelistGroups[groupId].created, "Group already exists");
        WhitelistGroup memory newGroup = WhitelistGroup({created: true});
        whitelistGroups[groupId] = newGroup;
        whitelistGroups[groupId].members[_whitelistGroupAdmin] = true;
        whitelistGroups[groupId].whitelistGroupAdmin[
            _whitelistGroupAdmin
        ] = true;
        whitelistGroups[groupId].members[msg.sender] = true;
        emit GroupCreated(msg.sender, groupId);
        return groupId;
    }

    /// @dev Function to delete a whitelist group.
    /// @param _groupId Group Id of the whitelist group.
    function deleteGroup(uint256 _groupId) public {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(
            _isGroupAdmin(_groupId),
            "Only Whitelist Group admin is permitted for this operation"
        );
        delete whitelistGroups[_groupId];
    }

    /// @dev Function to add members to a whitelist group.
    /// @param _groupId Group Id of the whitelist group.
    /// @param _memberAddress List of address to be added to the whitelist group.
    function addMembersToGroup(
        uint256 _groupId,
        address[] memory _memberAddress
    ) public {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(
            _isGroupAdmin(_groupId),
            "Only goup admin is permitted for this operation"
        );

        for (uint256 i = 0; i < _memberAddress.length; i++) {
            whitelistGroups[_groupId].members[_memberAddress[i]] = true;
        }
    }

    /// @dev Function to remove members from a whitelist group.
    /// @param _groupId Group Id of the whitelist group.
    /// @param _memberAddress List of address to be removed from the whitelist group.
    function removeMembersFromGroup(
        uint256 _groupId,
        address[] memory _memberAddress
    ) public {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(
            _isGroupAdmin(_groupId),
            "Only Whitelist Group admin is permitted for this operation"
        );

        for (uint256 i = 0; i < _memberAddress.length; i++) {
            whitelistGroups[_groupId].members[_memberAddress[i]] = false;
        }
    }

    /// @dev Function to check if an address is a whitelisted address.
    /// @param _groupId Group Id of the whitelist group.
    /// @param _memberAddress Address to check.
    function isMember(uint256 _groupId, address _memberAddress)
        public
        view
        returns (bool)
    {
        require(_isGroup(_groupId), "Group doesn't exist!");
        return whitelistGroups[_groupId].members[_memberAddress];
    }

    // /// @dev Function that returns the address of the whitelist group admin.
    // /// @param _groupId Group Id of the whitelist group.
    // function getWhitelistAdmin(uint256 _groupId) public view returns (address) {
    //     require(_isGroup(_groupId), "Group doesn't exist!");
    //     return whitelistGroups[_groupId].whitelistGroupAdmin;
    // }

    /// @dev Function to add the whitelist admin of a group.
    /// @param _groupId Group Id of the whitelist group.
    /// @param _whitelistGroupAdmin Address of the new whitelist admin.
    function addWhitelistAdmin(uint256 _groupId, address _whitelistGroupAdmin)
        public
    {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(
            _isGroupAdmin(_groupId),
            "Only existing whitelist admin can perform this operation"
        );
        whitelistGroups[_groupId].whitelistGroupAdmin[
            _whitelistGroupAdmin
        ] = true;
    }

    function removeWhitelistAdmin(
        uint256 _groupId,
        address _whitelistGroupAdmin
    ) public {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(_whitelistGroupAdmin != msg.sender, "Cannot remove yourself");
        require(
            _isGroupAdmin(_groupId),
            "Only existing whitelist admin can perform this operation"
        );
        delete whitelistGroups[_groupId].whitelistGroupAdmin[
            _whitelistGroupAdmin
        ];
    }
}