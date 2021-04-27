/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.3;

contract NestInfo36 {
    
    // Nest锁仓合约
    address public nestStaking = 0xaA7A74a46EFE0C58FBfDf5c43Da30216a8aa84eC;
    // Nest回售
    address public nestRedeeming = 0xF48D58649dDb13E6e29e03059Ea518741169ceC8;
    // 手续费账本
    address public nestLedger = 0x34B931C7e5Dc45dDc9098A1f588A0EA0dA45025D;
    // 投票合约 
    address public nestVote = 0xDa52f53a5bE4cb876DE79DcfF16F34B95e2D38e9;
    // nest地址
    address public nest = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
    // 价格数据合约
    address public nestPriceFacade = 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A;
    // 管理员
    address public governance;
    
    // Proposal
    struct DataView {

        // Index of proposal
        uint index;
        
        // The immutable field and the variable field are stored separately
        /* ========== Immutable field ========== */

        // The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
        address contractAddress;

        // Voting start time
        uint48 startTime;

        // Voting stop time
        uint48 stopTime;

        // Proposer
        address proposer;

        // Staked nest amount
        uint96 staked;

        /* ========== Mutable field ========== */

        // Gained value
        // The maximum value of uint96 can be expressed as 79228162514264337593543950335, which is more than the total 
        // number of nest 10000000000 ether. Therefore, uint96 can be used to express the total number of votes
        uint96 gainValue;

        // The state of this proposal
        uint32 state;  // 0: proposed | 1: accepted | 2: cancelled

        // The executor of this proposal
        address executor;

        // The execution time (if any, such as block number or time stamp) is placed in the contract and is limited by the contract itself

        // Circulation of nest
        uint96 nestCirculation;
    }
    
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
        totalAmount = IERC20(nToken).balanceOf(address(nestLedger));                                                                                     
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
    
    
    function list(uint offset, uint count, uint order) public view returns (DataView[] memory) {
        INestVote.ProposalView[] memory data = INestVote(nestVote).list(offset, count, order);
        DataView[] memory returnData = new DataView[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            INestVote.ProposalView memory vote = data[i];
            DataView memory info = DataView(vote.index, vote.contractAddress, vote.startTime, vote.stopTime, vote.proposer, vote.staked, vote.gainValue, vote.state, vote.executor, vote.nestCirculation);
            returnData[i] = info;
        }
        return returnData;
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
    // Proposal
    struct ProposalView {

        // Index of proposal
        uint index;
        
        // The immutable field and the variable field are stored separately
        /* ========== Immutable field ========== */

        // Brief of this proposal
        string brief;

        // The contract address which will be executed when the proposal is approved. (Must implemented IVotePropose)
        address contractAddress;

        // Voting start time
        uint48 startTime;

        // Voting stop time
        uint48 stopTime;

        // Proposer
        address proposer;

        // Staked nest amount
        uint96 staked;

        /* ========== Mutable field ========== */

        // Gained value
        // The maximum value of uint96 can be expressed as 79228162514264337593543950335, which is more than the total 
        // number of nest 10000000000 ether. Therefore, uint96 can be used to express the total number of votes
        uint96 gainValue;

        // The state of this proposal
        uint32 state;  // 0: proposed | 1: accepted | 2: cancelled

        // The executor of this proposal
        address executor;

        // The execution time (if any, such as block number or time stamp) is placed in the contract and is limited by the contract itself

        // Circulation of nest
        uint96 nestCirculation;
    }
    function getNestCirculation() external view returns (uint);
    function list(uint offset, uint count, uint order) external view returns (ProposalView[] memory);
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