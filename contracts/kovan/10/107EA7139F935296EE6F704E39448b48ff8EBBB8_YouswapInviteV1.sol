/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// File: contracts/interface/IYouswapInviteV1.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

interface IYouswapInviteV1 {

    struct UserInfo {
        address upper;//上级
        address[] lowers;//下级
        uint256 startBlock;//邀请块高
    }

    event InviteV1(address indexed owner, address indexed upper, uint256 indexed height);//被邀请人的地址，邀请人的地址，邀请块高

    function inviteCount() external view returns (uint256);//邀请人数

    function inviteUpper1(address) external view returns (address);//上级邀请

    function inviteUpper2(address) external view returns (address, address);//上级邀请

    function inviteLower1(address) external view returns (address[] memory);//下级邀请

    function inviteLower2(address) external view returns (address[] memory, address[] memory);//下级邀请

    function inviteLower2Count(address) external view returns (uint256, uint256);//下级邀请
    
    function register() external returns (bool);//注册邀请关系

    function acceptInvitation(address) external returns (bool);//注册邀请关系
    
    // function inviteBatch(address[] memory) external returns (uint, uint);//注册邀请关系：输入数量，成功数量
}

// File: contracts/utils/constant.sol


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
    string constant MINING_NOT_STARTED = 'YouSwap:MINING_NOT_STARTED';
    string constant END_OF_MINING = 'YouSwap:END_OF_MINING';
    string constant POOL_NOT_EXIST_OR_END_OF_MINING = 'YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING';
    
}

library DefaultSettings {
    uint256 constant BENEFIT_RATE_MIN = 0; // 0% 平台抽成最小比例, 10: 0.1%, 100: 1%, 1000: 10%, 10000: 100%
    uint256 constant BENEFIT_RATE_MAX = 10000; //100% 平台抽成最大比例
    uint256 constant TEN_THOUSAND = 10000; //100% 平台抽成最大比例
    uint256 constant EACH_FACTORY_POOL_MAX = 10000; //每个矿池合约创建合约上限
    uint256 constant CHANGE_RATE_MAX = 30; //调整区块发放数量幅度单次最大30%
    uint256 constant DAY_INTERVAL_MIN = 7; //调整单个区块奖励数量频率
    uint256 constant SECONDS_PER_DAY = 86400; //每天秒数
    uint256 constant REWARD_TOKENTYPE_MAX = 10; //奖励币种最大数量
}

// File: contracts/implement/YouswapInviteV1.sol


pragma solidity 0.7.4;



contract YouswapInviteV1 is IYouswapInviteV1 {
    address public constant ZERO = address(0);
    uint256 public startBlock;
    address[] public inviteUserInfoV1;
    mapping(address => UserInfo) public inviteUserInfoV2;

    constructor() {
        startBlock = block.number;
    }

    function inviteCount() external view override returns (uint256) {
        return inviteUserInfoV1.length;
    }

    function inviteUpper1(address _owner) external view override returns (address) {
        return inviteUserInfoV2[_owner].upper;
    }

    function inviteUpper2(address _owner) external view override returns (address, address) {
        address upper1 = inviteUserInfoV2[_owner].upper;
        address upper2 = address(0);
        if (address(0) != upper1) {
            upper2 = inviteUserInfoV2[upper1].upper;
        }

        return (upper1, upper2);
    }

    function inviteLower1(address _owner) external view override returns (address[] memory) {
        return inviteUserInfoV2[_owner].lowers;
    }

    function inviteLower2(address _owner) external view override returns (address[] memory, address[] memory) {
        address[] memory lowers1 = inviteUserInfoV2[_owner].lowers;
        uint256 count = 0;
        uint256 lowers1Len = lowers1.length;
        for (uint256 i = 0; i < lowers1Len; i++) {
            count += inviteUserInfoV2[lowers1[i]].lowers.length;
        }
        address[] memory lowers;
        address[] memory lowers2 = new address[](count);
        count = 0;
        for (uint256 i = 0; i < lowers1Len; i++) {
            lowers = inviteUserInfoV2[lowers1[i]].lowers;
            for (uint256 j = 0; j < lowers.length; j++) {
                lowers2[count] = lowers[j];
                count++;
            }
        }

        return (lowers1, lowers2);
    }

    function inviteLower2Count(address _owner) external view override returns (uint256, uint256) {
        address[] memory lowers1 = inviteUserInfoV2[_owner].lowers;
        uint256 lowers2Len = 0;
        uint256 len = lowers1.length;
        for (uint256 i = 0; i < len; i++) {
            lowers2Len += inviteUserInfoV2[lowers1[i]].lowers.length;
        }

        return (lowers1.length, lowers2Len);
    }

    function register() external override returns (bool) {
        UserInfo storage user = inviteUserInfoV2[tx.origin];
        require(0 == user.startBlock, ErrorCode.REGISTERED);
        user.upper = ZERO;
        user.startBlock = block.number;
        inviteUserInfoV1.push(tx.origin);

        emit InviteV1(tx.origin, user.upper, user.startBlock);

        return true;
    }

    function acceptInvitation(address _inviter) external override returns (bool) {
        require(msg.sender != _inviter, ErrorCode.FORBIDDEN);
        UserInfo storage user = inviteUserInfoV2[msg.sender];
        require(0 == user.startBlock, ErrorCode.REGISTERED);
        UserInfo storage upper = inviteUserInfoV2[_inviter];
        if (0 == upper.startBlock) {
            upper.upper = ZERO;
            upper.startBlock = block.number;
            inviteUserInfoV1.push(_inviter);

            emit InviteV1(_inviter, upper.upper, upper.startBlock);
        }
        user.upper = _inviter;
        upper.lowers.push(msg.sender);
        user.startBlock = block.number;
        inviteUserInfoV1.push(msg.sender);

        emit InviteV1(msg.sender, user.upper, user.startBlock);

        return true;
    }

    // function inviteBatch(address[] memory _invitees) external override returns (uint256, uint256) {
    //     uint256 len = _invitees.length;
    //     require(len <= 100, ErrorCode.PARAMETER_TOO_LONG);
    //     UserInfo storage user = inviteUserInfoV2[msg.sender];
    //     if (0 == user.startBlock) {
    //         user.upper = ZERO;
    //         user.startBlock = block.number;
    //         inviteUserInfoV1.push(msg.sender);

    //         emit InviteV1(msg.sender, user.upper, user.startBlock);
    //     }
    //     uint256 count = 0;
    //     for (uint256 i = 0; i < len; i++) {
    //         if ((address(0) != _invitees[i]) && (msg.sender != _invitees[i])) {
    //             UserInfo storage lower = inviteUserInfoV2[_invitees[i]];
    //             if (0 == lower.startBlock) {
    //                 lower.upper = msg.sender;
    //                 lower.startBlock = block.number;
    //                 user.lowers.push(_invitees[i]);
    //                 inviteUserInfoV1.push(_invitees[i]);
    //                 count++;

    //                 emit InviteV1(_invitees[i], msg.sender, lower.startBlock);
    //             }
    //         }
    //     }

    //     return (len, count);
    // }
}