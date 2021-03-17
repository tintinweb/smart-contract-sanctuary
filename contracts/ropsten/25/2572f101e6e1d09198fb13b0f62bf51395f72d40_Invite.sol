/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;

interface IInvite {
    struct UserInfo {
        address upper;//上级
        address[] lowers;//下级
        uint256 startBlock;//邀请块高
    }
}

contract Invite is IInvite {
    
    mapping(address => UserInfo) public inviteUserInfo;
    uint256 public number;
    address public addressThis;
    address public addressThis2;
    address public addressThis3;
    address public addressReuse;
    address public addressReuse2;
    address public addressReuse3;
    
    constructor() {
        number = block.number;
    }

    function thisCost() external {
        address a = address(this);
        addressThis = a;
        addressThis2 = a;
        addressThis3 = a;
    }

    function reuseCost() external {
        address temp = address(this);
                
        addressReuse = address(this);
        addressReuse2 = address(this);
        addressReuse3 = address(this);
    }

    function reuseCost2() external {
        addressReuse = address(this);
        addressReuse2 = address(this);
        addressReuse3 = address(this);
    }

    function inviteUpperRead(address _owner) external view returns (address, address) {
        address upper1 = inviteUserInfo[_owner].upper;
        address upper2 = address(0);
        if (address(0) != upper1) {
            upper2 = inviteUserInfo[upper1].upper;
        }

        return (upper1, upper2);
    }

    function inviteUpperWrite(address _owner) external returns (address, address) {
        address upper1 = inviteUserInfo[_owner].upper;
        if (address(0) == upper1) {
            inviteUserInfo[_owner].startBlock = block.number;
        }

        address upper2 = address(0);
        if (address(0) != upper1) {
            upper2 = inviteUserInfo[upper1].upper;
        }

        return (upper1, upper2);
    }

    function inviteUpperWrite2(address _owner) external returns (address, address) {
        address upper1 = inviteUserInfo[_owner].upper;
        if (address(0) == upper1) {
           inviteUserInfo[_owner].startBlock = block.number;
        }

        address upper2 = address(0);
        if (address(0) != upper1) {
            upper2 = inviteUserInfo[upper1].upper;
            if (address(0) == upper2) {
               inviteUserInfo[upper1].startBlock = block.number;
            }
        }

        return (upper1, upper2);
    }


}