/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

contract NestInfo36 {
    
    // Nest锁仓合约
    address public nestStaking = 0x5BC253b9fE40d92f8a01e62899A77ae124F68C5a;
    // Nest回售
    address public nestRedeeming = 0xf453E3c1733f4634210ce15cd2A4fAfb191c36A5;
    // 手续费账本
    address public nestLedger = 0x4397F20d20b5B89131b631c43AdE98Baf3A6dc9F;
    // 投票合约 
    address public nestVote = 0x6B9C63a52533CB9b653B468f72fD751E0f2bc181;
    // nest地址
    address public nest = 0x3145AF0F18759D7587F22278d965Cdf7e19d6437;
    // 价格数据合约
    address public nestPriceFacade = 0xCAc72395a6EaC6D0D06C8B303e26cC0Bfb5De33c;
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
    
    function setNestVote(address add) external onlyGovernance {
        require(add != address(0x0));
        nestVote = add;
    }
    
    function setNest(address add) external onlyGovernance {
        require(add != address(0x0));
        nest = add;
    }
    
    function setNestPriceFacade(address add) external onlyGovernance {
        require(add != address(0x0));
        nestPriceFacade = add;
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
    * @return tokenTotal token流通量
    * @return nestIn01 nest销毁额度
    */
    function getRedeemingInfo(address nToken, uint256 tokenAmount) external view returns(uint256 resolvableAmount, 
                                                                                         uint256 priceAmount, 
                                                                                         uint256 totalAmount,
                                                                                         uint256 tokenBalance, 
                                                                                         uint256 tokenAllow,
                                                                                         uint256 tokenTotal,
                                                                                         uint256 nestIn01,
                                                                                         uint256 fee) {
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
        if (nToken == nest) {
            tokenTotal = INestVote(nestVote).getNestCirculation();
        } else {
            tokenTotal = IERC20(nToken).totalSupply() - IERC20(nToken).balanceOf(address(nestLedger));
        }
        nestIn01 = IERC20(nest).balanceOf(address(0x0000000000000000000000000000000000000001));
        INestPriceFacade.Config memory info = INestPriceFacade(nestPriceFacade).getConfig();
        // fee = info.singleFee * 0.0001 ether;
        fee = uint256(info.singleFee) * 0.0001 ether;
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
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
    
}

interface INestRedeeming {
    function quotaOf(address ntokenAddress) external view returns (uint);
}

interface INestLedger {
    function totalRewards(address ntokenAddress) external view returns (uint);
}

interface INestVote {
    function getNestCirculation() external view returns (uint);
}

interface INestPriceFacade {
    
    /// @dev Price call entry configuration structure
    struct Config {

        // Single query fee（0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;

        // Double query fee（0.0001 ether, DIMI_ETHER). 100
        uint16 doubleFee;

        // The normal state flag of the call address. 0
        uint8 normalFlag;
    }
    function getConfig() external view returns (Config memory);
    
}