/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.5.16;

/// @title Asset
/// @dev Store & retrieve value of a property

contract Asset {
    address public creatorAdmin;
    enum Status {NotExist, Pending, Approved, Rejected}
    enum Role {Visitor, User, Admin, SuperAdmin}

    // Struct to store all property related details
    struct PropertyDetail {
        Status status;
        uint256 value;
        address currOwner;
    }

    mapping(uint256 => PropertyDetail) public properties; // Stores all properties propId -> property Detail
    mapping(uint256 => address) public propOwnerChange; // Keeps track of property owner propId -> Owner Address
    mapping(address => Role) public userRoles; // Keeps track of user roles
    mapping(address => bool) public verifiedUsers; // Keeps track of verified user, userId -> verified (true / false)

    // Modifier to ensure only the property owner access
    // a specific property
    modifier onlyOwner(uint256 _propId) {
        require(properties[_propId].currOwner == msg.sender);
        _;
    }

    // Modifier to ensure only the verified user access
    // a specific property
    modifier verifiedUser(address _user) {
        require(verifiedUsers[_user]);
        _;
    }

    // Modifier to ensure only the verified admin access a function
    modifier verifiedAdmin() {
        require(
            userRoles[msg.sender] >= Role.Admin && verifiedUsers[msg.sender]
        );
        _;
    }

    // Modifier to ensure only the verified super admin admin access a function
    modifier verifiedSuperAdmin() {
        require(
            userRoles[msg.sender] == Role.SuperAdmin &&
                verifiedUsers[msg.sender]
        );
        _;
    }

    // Initializing the Contract.
    constructor() public {
        creatorAdmin = msg.sender;
        userRoles[creatorAdmin] = Role.SuperAdmin;
        verifiedUsers[creatorAdmin] = true;
    }

    /// @dev Function to create property
    /// @param _propId Identifier for property
    /// @param _value Property Price
    /// @param _owner Ownwe address property
    function createProperty(
        uint256 _propId,
        uint256 _value,
        address _owner
    ) external verifiedAdmin verifiedUser(_owner) returns (bool) {
        properties[_propId] = PropertyDetail(Status.Pending, _value, _owner);
        return true;
    }

    /// @dev Approve property
    /// @param _propId Identifier for property
    function approveProperty(uint256 _propId)
        external
        verifiedSuperAdmin
        returns (bool)
    {
        require(properties[_propId].currOwner != msg.sender);
        properties[_propId].status = Status.Approved;
        return true;
    }

    /// @dev Function to reject property
    /// @param _propId Identifier for property
    function rejectProperty(uint256 _propId)
        external
        verifiedSuperAdmin
        returns (bool)
    {
        require(properties[_propId].currOwner != msg.sender);
        properties[_propId].status = Status.Rejected;
        return true;
    }

    /// @dev Function to change property ownership
    /// @param _propId Identifier for property
    /// @param _newOwner new Owner address for property
    function changeOwnership(uint256 _propId, address _newOwner)
        external
        onlyOwner(_propId)
        verifiedUser(_newOwner)
        returns (bool)
    {
        require(properties[_propId].currOwner != _newOwner);
        require(propOwnerChange[_propId] == address(0));
        propOwnerChange[_propId] = _newOwner;
        return true;
    }

    /// @dev Function to approve change of ownership
    /// @param _propId Identifier for property
    function approveChangeOwnership(uint256 _propId)
        external
        verifiedSuperAdmin
        returns (bool)
    {
        require(propOwnerChange[_propId] != address(0));
        properties[_propId].currOwner = propOwnerChange[_propId];
        propOwnerChange[_propId] = address(0);
        return true;
    }

    /// @dev Function to change property value
    /// @param _propId Identifier for property
    /// @param _newValue New Property Price
    function changeValue(uint256 _propId, uint256 _newValue)
        external
        onlyOwner(_propId)
        returns (bool)
    {
        require(propOwnerChange[_propId] == address(0));
        properties[_propId].value = _newValue;
        return true;
    }

    /// @dev Function to create property
    /// @param _propId Identifier for property
    function getPropertyDetails(uint256 _propId)
        public
        view
        returns (
            Status,
            uint256,
            address
        )
    {
        return (
            properties[_propId].status,
            properties[_propId].value,
            properties[_propId].currOwner
        );
    }

    /// @dev Function to add a new user
    /// @param _newUser new user address
    function addNewUser(address _newUser)
        external
        verifiedAdmin
        returns (bool)
    {
        require(userRoles[_newUser] == Role.Visitor);
        require(verifiedUsers[_newUser] == false);
        userRoles[_newUser] = Role.User;
        return true;
    }

    /// @dev Function to add a new admin
    /// @param _newAdmin new admin user address
    function addNewAdmin(address _newAdmin)
        external
        verifiedSuperAdmin
        returns (bool)
    {
        require(userRoles[_newAdmin] == Role.Visitor);
        require(verifiedUsers[_newAdmin] == false);
        userRoles[_newAdmin] = Role.Admin;
        return true;
    }

    /// @dev Function to add a new admin
    /// @param _newSuperAdmin new super admin user address
    function addNewSuperAdmin(address _newSuperAdmin)
        external
        verifiedSuperAdmin
        returns (bool)
    {
        require(userRoles[_newSuperAdmin] == Role.Visitor);
        require(verifiedUsers[_newSuperAdmin] == false);
        userRoles[_newSuperAdmin] = Role.SuperAdmin;
        return true;
    }

    /// @dev Function to add a new admin
    /// @param _newUser user address to approve
    function approveUsers(address _newUser)
        external
        verifiedSuperAdmin
        returns (bool)
    {
        require(userRoles[_newUser] != Role.Visitor);
        verifiedUsers[_newUser] = true;
        return true;
    }
}