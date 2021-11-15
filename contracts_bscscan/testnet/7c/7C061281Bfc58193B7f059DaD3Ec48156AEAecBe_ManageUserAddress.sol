// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.12;
contract ManageUserAddress {
    mapping(address => bytes32) private listUsers;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant NORMAL = keccak256("NORMAL");

    constructor() public {
        listUsers[msg.sender] = SUPER_ADMIN_ROLE;
    }

    function getRole(address user) public view returns (bytes32) {
        if (listUsers[user] != SUPER_ADMIN_ROLE && listUsers[user] != ADMIN_ROLE) {
            return NORMAL;
        }
        return listUsers[user];
    }

    function addAdmin(address user) public {
        require(listUsers[msg.sender] == SUPER_ADMIN_ROLE, "NO PERMISSION");
        bytes32 _role = getRole(user);
        require(_role != SUPER_ADMIN_ROLE && _role != ADMIN_ROLE, "CAN NOT SET USER TO ADMIN");
        listUsers[user] = ADMIN_ROLE;
    }

    function removeAdmin(address user) public {
        require(listUsers[msg.sender] == SUPER_ADMIN_ROLE, "NO PERMISSION");
        bytes32 _role = getRole(user);
        require(_role == ADMIN_ROLE, "USER IS NOT ADMIN");
        listUsers[user] = NORMAL;
    }

    function transferSuperAdmin(address user) public {
        require(listUsers[msg.sender] == SUPER_ADMIN_ROLE, "NO PERMISSION");
        listUsers[user] = SUPER_ADMIN_ROLE;
        listUsers[msg.sender] = NORMAL;
    }
}

