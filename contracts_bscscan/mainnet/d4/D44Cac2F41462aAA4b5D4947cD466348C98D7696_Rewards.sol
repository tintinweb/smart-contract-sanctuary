// SPDX-License-Identifier: Unlicensed

import "./AccessControl.sol";


pragma solidity >=0.8.10;

contract Rewards is Context, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant READ_ROLE = keccak256("READ_ROLE");

    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(READ_ROLE, msg.sender);
    }

    function addAdmin(address newAdmin) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not ADMIN");
        
        _setupRole(ADMIN_ROLE, newAdmin);
    }

    function addReader(address reader) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not ADMIN");
        
        _setupRole(READ_ROLE, reader);
    }

    function getAwardMultiplier(uint256 rand) external view returns(uint256) {
        require(hasRole(READ_ROLE, msg.sender), "Caller is not READER");

        if (rand <= 710000) return 0;
        else if (rand <= 782500) return 50000;
        else if (rand <= 898500) return 100000;
        else if (rand <= 950700) return 150000;
        else if (rand <= 985500) return 250000;
        else if (rand <= 994316) return 500000;
        else if (rand <= 997506) return 1000000;
        else if (rand <= 998811) return 2000000;
        else if (rand <= 999710) return 4000000;
        else if (rand <= 999855) return 10000000;
        else if (rand <= 999971) return 15000000;
        else if (rand <= 999997) return 25000000;
        else if (rand <= 1000000) return 50000000;
        else return 0;
    }
}