//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

contract Admin {

    // Listing all admins
    address [] public admins;

    // Modifier for easier checking if user is admin
    mapping(address => bool) public isAdmin;

    // Modifier restricting access to only admin
    modifier onlyAdmin {
        require(isAdmin[msg.sender], "Only admin can call.");
        _;
    }

    // Constructor to set initial admins during deployment
    constructor (address [] memory _admins) public {
        for(uint i = 0; i < _admins.length; i++) {
            admins.push(_admins[i]);
            isAdmin[_admins[i]] = true;
        }
    }

    function addAdmin(
        address _adminAddress
    )
    external
    onlyAdmin
    {
        // Can't add 0x address as an admin
        require(_adminAddress != address(0x0), "[RBAC] : Admin must be != than 0x0 address");
        // Can't add existing admin
        require(!isAdmin[_adminAddress], "[RBAC] : Admin already exists.");
        // Add admin to array of admins
        admins.push(_adminAddress);
        // Set mapping
        isAdmin[_adminAddress] = true;
    }

    function removeAdmin(
        address _adminAddress
    )
    external
    onlyAdmin
    {
        // Admin has to exist
        require(isAdmin[_adminAddress]);
        require(admins.length > 1, "Can not remove all admins since contract becomes unusable.");
        uint i = 0;

        while(admins[i] != _adminAddress) {
            if(i == admins.length) {
                revert("Passed admin address does not exist");
            }
            i++;
        }

        // Copy the last admin position to the current index
        admins[i] = admins[admins.length-1];

        isAdmin[_adminAddress] = false;

        // Remove the last admin, since it's double present
        admins.pop();
    }

    // Fetch all admins
    function getAllAdmins()
    external
    view
    returns (address [] memory)
    {
        return admins;
    }

}