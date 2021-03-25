/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

contract NestInfo36 {
    
    // Nest锁仓合约
    address public nestStaking;
    // Nest回售
    address public nestRedeeming;
    // 手续费账本
    address public nestLedger;
    
    // 管理员
    address public governance;
    
    constructor() public{
        governance = msg.sender;
    }
    
    //---------modifier---------
    
    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }
    
    //---------governance-------
    
    function setNestStaking(address add) external onlyGovernance {
        require(add != address(0x0));
        nestStaking = add;
    }
    
    function setNestRedeeming(address add) external onlyGovernance {
        require(add != address(0x0));
        nestRedeeming = add;
    }
    
    function setNestLedger(address add) external onlyGovernance {
        require(add != address(0x0));
        nestLedger = add;
    }
    
    //---------view-------------
    
    /**
    * @dev 收益页面信息
    * @param nToken 查询的ntoken或nest地址
    * @return accountStaked 账户锁仓量
    * @return accountEarned 账户可领取收益
    */
    function getStakingInfo(address nToken) external view returns (uint256 accountStaked, uint256 accountEarned) {
        INestStaking C_NestStake = INestStaking(address(nestStaking));
        accountStaked = C_NestStake.stakedBalanceOf(nToken, address(msg.sender));
        accountEarned = C_NestStake.earned(nToken, address(msg.sender));
    }
    
    /**
    * @dev 回售页面信息
    * @param nToken 查询的ntoken或nest地址
    * @param tokenAmount 价值 1 ETH 的 ntoken 数量
    * @return resolvableAmount 可回购数量
    * @return priceAmount 当前价格
    * @return totalAmount 已锁定总量 
    * @return tokenBalance token余额
    * @return tokenAllow token授权额度
    */
    function getRedeemingInfo(address nToken, uint256 tokenAmount) external view returns(uint256 resolvableAmount, 
                                                                                         uint256 priceAmount, 
                                                                                         uint256 totalAmount,
                                                                                         uint256 tokenBalance, 
                                                                                         uint256 tokenAllow) {
        uint256 ethBalance = INestLedger(address(nestLedger)).totalRewards(nToken);
        uint256 ethResolvable = tokenAmount * ethBalance / uint256(1 ether);
        uint256 realResolvable = INestRedeeming(nestRedeeming).quotaOf(nToken);
        if (ethResolvable < realResolvable) {
            resolvableAmount = ethResolvable;
        } else {
            resolvableAmount = realResolvable;
        }
        priceAmount = tokenAmount;
        totalAmount = IERC20(nToken).balanceOf(address(nestRedeeming));                                                                                     
        tokenBalance = IERC20(nToken).balanceOf(address(msg.sender));
        tokenAllow = IERC20(nToken).allowance(address(msg.sender), address(nestRedeeming));
    }
    
    /**
    * @dev token余额授权信息
    * @param token 查询的token
    * @param to 授权目标
    * @return balanceAmount 钱包余额
    * @return allowAmount 授权额度
    */
    function balanceAndAllow(address token, address to) external view returns(uint256 balanceAmount, uint256 allowAmount) {
        balanceAmount = IERC20(address(token)).balanceOf(address(msg.sender));
        allowAmount = IERC20(address(token)).allowance(address(msg.sender), address(to));
    }
    
}


interface INestStaking {

    function totalStaked(address ntoken) external view returns (uint256);

    function stakedBalanceOf(address ntoken, address account) external view returns (uint256);
    
    function totalRewards(address ntoken) external view returns (uint256);
    
    function earned(address ntoken, address account) external view returns (uint256);
}

interface IERC20 {

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
    
}

interface INestRedeeming {
    function quotaOf(address ntokenAddress) external view returns (uint);
}

interface INestLedger {
    function totalRewards(address ntokenAddress) external view returns (uint);
}