// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../utils/Initializable.sol";

contract Invitation is Initializable {
    event Invite(address indexed user, address indexed upper, uint256 time);

    struct UserInvitation {
        address upper; //上级
        address[] lowers; //下级
        uint256 startTime; //邀请时间
    }

    uint256 public startTime;
    mapping(address => UserInvitation) public userInvitations;
    uint256 public totalRegisterCount = 0;

    function initialize() public initializer {
        startTime = block.timestamp;
    }

    function register() external returns (bool) {
        UserInvitation storage user = userInvitations[msg.sender];
        require(0 == user.startTime, "REGISTERED");

        user.upper = address(0);
        user.startTime = block.timestamp;
        totalRegisterCount++;

        emit Invite(msg.sender, user.upper, user.startTime);

        return true;
    }

    function acceptInvitation(address inviter) external returns (bool) {
        require(msg.sender != inviter, "FORBIDDEN");
        UserInvitation storage sender = userInvitations[msg.sender];

        // ensure not registered
        require(0 == sender.startTime, "REGISTERED");
        UserInvitation storage upper = userInvitations[inviter];
        
        require(upper.startTime != 0, "INVITER_NOT_EXIST!");

        sender.upper = inviter;
        upper.lowers.push(msg.sender);
        sender.startTime = block.timestamp;
        totalRegisterCount++;

        emit Invite(msg.sender, sender.upper, sender.startTime);

        return true;
    }

    function getUpper1(address user) external view returns (address) {
        return userInvitations[user].upper;
    }

    function getUpper2(address user) external view returns (address, address) {
        address upper1 = userInvitations[user].upper;
        address upper2 = address(0);
        if (address(0) != upper1) {
            upper2 = userInvitations[upper1].upper;
        }

        return (upper1, upper2);
    }

    function getLowers1(address user) external view returns (address[] memory) {
        return userInvitations[user].lowers;
    }

    function getLowers2(address user) external view returns (address[] memory, address[] memory) {
        address[] memory lowers1 = userInvitations[user].lowers;
        uint256 count = 0;
        uint256 lowers1Len = lowers1.length;
        // get the  total count;
        for (uint256 i = 0; i < lowers1Len; i++) {
            count += userInvitations[lowers1[i]].lowers.length;
        }
        address[] memory lowers;
        address[] memory lowers2 = new address[](count);
        count = 0;
        for (uint256 i = 0; i < lowers1Len; i++) {
            lowers = userInvitations[lowers1[i]].lowers;
            for (uint256 j = 0; j < lowers.length; j++) {
                lowers2[count] = lowers[j];
                count++;
            }
        }

        return (lowers1, lowers2);
    }

    function getLowers2Count(address user) external view returns (uint256, uint256) {
        address[] memory lowers1 = userInvitations[user].lowers;
        uint256 lowers2Len = 0;
        uint256 len = lowers1.length;
        for (uint256 i = 0; i < len; i++) {
            lowers2Len += userInvitations[lowers1[i]].lowers.length;
        }

        return (lowers1.length, lowers2Len);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}