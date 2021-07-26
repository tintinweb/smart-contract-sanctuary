/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function nonces(address owner) external view returns (uint);
}


contract MasterChef{
    struct UserInfo {
        uint256 amount; // 用户提供了多少LP令牌
        uint256 rewardDebt; // 奖励债务。见下文解释。
    }

    // 每个池的信息。
    struct PoolInfo {
        IERC20 lpToken; // LP令牌合同的地址。
        uint256 allocPoint; // 分配给该池的分配点数。使用它按块分发。
        uint256 lastRewardBlock; // 支持此分布发生的最后一个块号。
        uint256 accSushiPerShare; // 累计每股收益，乘以1e12。见下文
    }
    
    PoolInfo[] public poolInfo;
    // 持有LP令牌的每个用户的信息。
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
}

contract TestMa{
    address ma = 0x80C7DD17B01855a6D2347444a0FCC36136a314de;
    function get(uint256 pid, address user) public view returns(uint256 amount, uint256 rewardDebt) {
        ( amount, rewardDebt) = MasterChef(ma).userInfo(pid,user);
    }
    
    function getPid(uint256 len) public view returns(IERC20 lpToken,uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare) {
        (lpToken, allocPoint, lastRewardBlock, accSushiPerShare) = MasterChef(ma).poolInfo(len);
    }
    
    mapping(address => uint256) public pids;
    function setPid(uint256 len) public {
        for(uint256 i; i < len; i++) {
            IERC20 lpToken;
            (lpToken, , , ) = MasterChef(ma).poolInfo(len);
            pids[address(lpToken)] = i;
        }
    }
    
    function getPids(address pair) public view returns(uint256) {
        return pids[pair];
    }
}