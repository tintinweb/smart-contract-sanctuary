/**
 *Submitted for verification at polygonscan.com on 2021-08-17
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

/*
Join us at PolyCrystal.Finance!
█▀▀█ █▀▀█ █░░ █░░█ █▀▀ █▀▀█ █░░█ █▀▀ ▀▀█▀▀ █▀▀█ █░░ 
█░░█ █░░█ █░░ █▄▄█ █░░ █▄▄▀ █▄▄█ ▀▀█ ░░█░░ █▄▄█ █░░ 
█▀▀▀ ▀▀▀▀ ▀▀▀ ▄▄▄█ ▀▀▀ ▀░▀▀ ▄▄▄█ ▀▀▀ ░░▀░░ ▀░░▀ ▀▀▀
*/
/*
This contract provides a basic and secure form of access control. There are three forms of access granted here:

Admins have full access to everything, including adding and removing other admins.

Users have lesser access.

Approved contracts have access for certain functions, but only if an admin/user originated the transaction.
This allows, for example, multiple pool factories to write to a centralized log

WARNING: Approved contracts must derive from CrystalClearCaller and be linked, or otherwise have sufficient access control.
This is to prevent hypothetical malicious code in untrusted contracts such as tokens

*/
contract CrystalClearControl {
    
    mapping (address => bool) public isAdmin;
    mapping (address => bool) public isUser;
    mapping (address => bool) public isApprovedContract; 
    
    // for functions that must be called directly by an admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Admin access not authorized");
        _;
    }
    /*
    // for functions that must be called directly by a user or admin
    modifier onlyUser() {
        require(isUser[msg.sender], "User access not authorized");
        _;
    }
    
    //admins can write directly, or via pre-approved contracts
    modifier adminAccess() {
        require(isAdmin[msg.sender] || (isAdmin[tx.origin] && isApprovedContract[msg.sender]), "Admin write access not authorized");
        _;
    }
    
    //users can write directly, or via pre-approved contracts
    modifier usersAccess() {
        require(isUser[msg.sender] || (isUser[tx.origin] && isApprovedContract[msg.sender]), "User write access not authorized");
        _;
    }
    */
    
    function setAdmin(address user, bool adminStatus) external onlyAdmin {
        require(isAdmin[user] != adminStatus, "already set");
        isAdmin[user] = adminStatus;
        if (adminStatus = true) {
            isUser[user] = true;
            emit SetUser(user, true);
        }
        emit SetAdmin(user, adminStatus);
    }
    function setUser(address user, bool userStatus) external onlyAdmin {
        require(isUser[user] != userStatus, "already set");
        require(!isAdmin[user] || userStatus == false, "admin must have user status");
        
        emit SetUser(user, userStatus);
    }
    
    function setApprovedContract(address _contract, bool approvedStatus) external onlyAdmin {
        require(address(CrystalClearCaller(_contract).crystalClearControl()) == address(this), "Contract is not a connected CCC");
        isApprovedContract[_contract] = approvedStatus;
        emit SetApproved(_contract, approvedStatus);
    }
    //DON'T USE UNLESS YOU KNOW WHAT YOU'RE DOING
    function setApprovedContract(address _contract, bool approvedStatus, bool dangerousOverride) external onlyAdmin {
        require(dangerousOverride, "override must be true, maybe you should reconsider?");
        isApprovedContract[_contract] = approvedStatus;
        emit SetApproved(_contract, approvedStatus);
    }
    
    event SetAdmin(address user, bool status);
    event SetUser(address user, bool status);
    event SetApproved(address _contract, bool status);
    
    constructor() {
        isAdmin[msg.sender] = true;
        emit SetAdmin(msg.sender, true);
    }
    
}

//Use in contracts that will call home for authorization, allowing access control to be centralized
abstract contract CrystalClearCaller {
    
    CrystalClearControl immutable public crystalClearControl;
    
    constructor(address control) {
        crystalClearControl = CrystalClearControl(control);
    }
    
    // for functions that must be called directly by an admin
    modifier onlyAdmin() {
        require(crystalClearControl.isAdmin(msg.sender), "Admin access not authorized");
        _;
    }
    // for functions that must be called directly by a user or admin
    modifier onlyUser() {
        require(crystalClearControl.isUser(msg.sender), "User access not authorized");
        _;
    }
    
    //admins can write directly, or via pre-approved contracts
    modifier adminAccess() {
        require(crystalClearControl.isAdmin(msg.sender) || (crystalClearControl.isAdmin(tx.origin) && crystalClearControl.isApprovedContract(msg.sender)), "Admin write access not authorized");
        _;
    }
    
    //users can write directly, or via pre-approved contracts
    modifier usersAccess() {
        require(crystalClearControl.isUser(msg.sender) || (crystalClearControl.isUser(tx.origin) && crystalClearControl.isApprovedContract(msg.sender)), "User write access not authorized");
        _;
    }
}