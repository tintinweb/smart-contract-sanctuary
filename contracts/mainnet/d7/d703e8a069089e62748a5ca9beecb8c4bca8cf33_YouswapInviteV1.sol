/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.7.4;

library ErrorCode {

    string constant FORBIDDEN = 'YouSwap:FORBIDDEN';
    string constant IDENTICAL_ADDRESSES = 'YouSwap:IDENTICAL_ADDRESSES';
    string constant ZERO_ADDRESS = 'YouSwap:ZERO_ADDRESS';
    string constant INVALID_ADDRESSES = 'YouSwap:INVALID_ADDRESSES';
    string constant BALANCE_INSUFFICIENT = 'YouSwap:BALANCE_INSUFFICIENT';
    string constant REWARDTOTAL_LESS_THAN_REWARDPROVIDE = 'YouSwap:REWARDTOTAL_LESS_THAN_REWARDPROVIDE';
    string constant PARAMETER_TOO_LONG = 'YouSwap:PARAMETER_TOO_LONG';
    string constant REGISTERED = 'YouSwap:REGISTERED';

}

interface IYouswapInviteV1 {

    struct UserInfo {
        address up;//上级
        address[] down;//下级
        uint256 startBlock;//邀请块高
    }

    event InviteV1(address indexed owner, address indexed upper, uint256 indexed height);//被邀请人的地址，邀请人的地址，邀请块高

    function inviteLength() external view returns (uint256);//邀请人数

    function inviteUp1(address) external view returns (address);//上级邀请

    function inviteUp2(address) external view returns (address, address);//上级邀请

    function inviteDown1(address) external view returns (address[] memory);//下级邀请

    function inviteDown2(address) external view returns (address[] memory, address[] memory);//下级邀请

    function inviteDown2Count(address) external view returns (uint256, uint256);//下级邀请
    
    function register() external returns (bool);//注册邀请关系

    function invite(address) external returns (bool);//注册邀请关系
    
    function inviteBatch(address[] memory) external returns (uint, uint);//注册邀请关系，输入数量，成功数量

}

contract YouswapInviteV1 is IYouswapInviteV1 {

    address public constant zero = address(0);
    uint256 public startBlock;
    address[] public inviteUserInfoV1;
    mapping(address => UserInfo) public inviteUserInfoV2;

    constructor () {
        startBlock = block.number;
    }
    
    function inviteLength() override external view returns (uint256) {
        return inviteUserInfoV1.length;
    }

    function inviteUp1(address _address) override external view returns (address) {
        return inviteUserInfoV2[_address].up;
    }

    function inviteUp2(address _address) override external view returns (address, address) {
        address up1 = inviteUserInfoV2[_address].up;
        address up2 = address(0);
        if (address(0) != up1) {
            up2 = inviteUserInfoV2[up1].up;
        }

        return (up1, up2);
    }

    function inviteDown1(address _address) override external view returns (address[] memory) {
        return inviteUserInfoV2[_address].down;
    }

    function inviteDown2(address _address) override external view returns (address[] memory, address[] memory) {
        address[] memory invite1 = inviteUserInfoV2[_address].down;
        uint256 count = 0;
        uint256 len = invite1.length;
        for (uint256 i = 0; i < len; i++) {
            count += inviteUserInfoV2[invite1[i]].down.length;
        }
        address[] memory down;
        address[] memory invite2 = new address[](count);
        count = 0;
        for (uint256 i = 0; i < len; i++) {
            down = inviteUserInfoV2[invite1[i]].down;
            for (uint256 j = 0; j < down.length; j++) {
                invite2[count] = down[j];
                count++;
            }
        }
        
        return (invite1, invite2);
    }

    function inviteDown2Count(address _address) override external view returns (uint256, uint256) {
        address[] memory invite1 = inviteUserInfoV2[_address].down;
        uint256 invite2 = 0;
        uint256 len = invite1.length;
        for (uint256 i = 0; i < len; i++) {
            invite2 += inviteUserInfoV2[invite1[i]].down.length;
        }
        
        return (invite1.length, invite2);
    }

    function register() override external returns (bool) {
        UserInfo storage user = inviteUserInfoV2[tx.origin];
        require(0 == user.startBlock, ErrorCode.REGISTERED);
        user.up = zero;
        user.startBlock = block.number;
        inviteUserInfoV1.push(tx.origin);
        
        emit InviteV1(tx.origin, user.up, user.startBlock);
        
        return true;
    }

    function invite(address _address) override external returns (bool) {
        require(msg.sender != _address, ErrorCode.FORBIDDEN);
        UserInfo storage user = inviteUserInfoV2[msg.sender];
        require(0 == user.startBlock, ErrorCode.REGISTERED);
        UserInfo storage up = inviteUserInfoV2[_address];
        if (0 == up.startBlock) {
            user.up = zero;
        }else {
            user.up = _address;
            up.down.push(msg.sender);
        }
        user.startBlock = block.number;
        inviteUserInfoV1.push(msg.sender);
        
        emit InviteV1(msg.sender, user.up, user.startBlock);

        return true;
    }

    function inviteBatch(address[] memory _addresss) override external returns (uint, uint) {
        uint len = _addresss.length;
        require(len <= 100, ErrorCode.PARAMETER_TOO_LONG);
        UserInfo storage user = inviteUserInfoV2[msg.sender];
        if (0 == user.startBlock) {
            user.up = zero;
            user.startBlock = block.number;
            inviteUserInfoV1.push(msg.sender);
                        
            emit InviteV1(msg.sender, user.up, user.startBlock);
        }
        uint count = 0;
        for (uint i = 0; i < len; i++) {
            if ((address(0) != _addresss[i]) && (msg.sender != _addresss[i])) {
                UserInfo storage down = inviteUserInfoV2[_addresss[i]];
                if (0 == down.startBlock) {
                    down.up = msg.sender;
                    down.startBlock = block.number;
                    user.down.push(_addresss[i]);
                    inviteUserInfoV1.push(_addresss[i]);
                    count++;

                    emit InviteV1(_addresss[i], msg.sender, down.startBlock);
                }
            }
        }

        return (len, count);
    }

}