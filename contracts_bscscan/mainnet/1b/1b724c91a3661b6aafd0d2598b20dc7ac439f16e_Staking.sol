pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    event DepositLP(address indexed user, uint256 amount);
    event WithdrawLP(address indexed user, uint256 amount);

    struct UserInfo {
        uint256 btAmount; // bt staked
        uint256 beeAmount; // bee staked
        uint256 lpAmount; // bot staked
        uint256 usdtAmount; // usdt staked
        uint256 rewardDebtlp;
        uint256 rewardLp; // lp stake reward
        uint256 btLastRewardTime;
        uint256 beeLastRewardTime;
        uint256 rewardBt; // bt stake reward
        uint256 rewardBee; // bee stake reward
    }

    // user staking info
    mapping (address => UserInfo) public userInfo;

    // lp pool info
    uint256 public lpAccBotPerShare;
    uint256 public lpLastRewardTime;
    uint256 public lpRewardEndTime;
    uint256 public lpTotalReward; // current total reward
    uint256 public lpRewardCap = 14400 * (10 ** 18);
    uint256 public lpRewardBotPerSecond = 1851851851851851; // 160 * (10 **18) / (3600 * 24)
    uint256 private constant ACC_PRECISION = 1e12;

    // bt pool info
    uint256 public btRatio = 1000; // multiply 100
    uint256 public btStakeCap = 90000 * (10 ** 18);
    uint256 public btLastRewardTime;
    uint256 public btRewardEndTime;
    uint256 public btTotalReward; // current total reward
    uint256 public btRewardCap = 4500 * (10 ** 18);
    uint256 public btRewardBotPerSecond = 9645061728; // 10**18 / (60 * 24 * 3600) / 20
    uint256 public btLeftover = btStakeCap;

    // bee pool info
    uint256 public beeRatio = 20; // multiply 100
    uint256 public beeStakeCap = 9000000 * (10 **18);
    uint256 public beeLastRewardTime;
    uint256 public beeRewardEndTime;
    uint256 public beeTotalReward; // current total reward
    uint256 public beeRewardCap = 9000 * (10 ** 18);
    uint256 public beeRewardBotPerSecond = 192901234; // 10**18 / (60 * 24 * 3600) / 1000
    uint256 public beeLeftover = beeStakeCap;
    uint256 private constant PRECISION = 1e18;

    address public bt;
    address public bee;
    address public bot;
    address public usdt;
    address public lp;

    address public fixedWallet;
    address public rewardContract;

    uint256 public startTime;

    // stat
    uint256 public btTotalStaked;
    uint256 public beeTotalStaked;
    uint256 public lpTotalStaked;
    uint256 public usdtTotalStaked;

    // nodes info
    mapping(address => bool) public nodeMap;
    mapping(address => uint256) private nodePerformances; // usdt performance
    address[] nodes;

    bool public lpEnabled;

    constructor (address _bt, address _bee, address _bot, address _usdt, address _lp) public {
        // USDT: 0x55d398326f99059fF775485246999027B3197955
        bt = _bt;
        bee= _bee;
        bot = _bot;
        usdt = _usdt;
        lp = _lp;

        fixedWallet = msg.sender;
        rewardContract = msg.sender;
    }

    function setFixedWallet(address account) public onlyOwner {
        fixedWallet = account;
    }

    function setRewardContract(address account) public onlyOwner {
        rewardContract = account;
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;

        beeLastRewardTime = startTime;
        btLastRewardTime = startTime;
    }

    function setLpEnabled(bool flag) public onlyOwner {
        lpEnabled = flag;
    }

    function setBT(address _bt) public onlyOwner {
        bt = _bt;
    }

    function setBEE(address _bee) public onlyOwner {
        bee = _bee;
    }

    function setBOT(address _bot) public onlyOwner {
        bot = _bot;
    }

    function setUSDT(address _usdt) public onlyOwner {
        usdt = _usdt;
    }

    function setLP(address _lp) public onlyOwner {
        lp = _lp;
    }

    function addNodes(address[] memory accounts) public onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            address account = accounts[i];
            if (!nodeMap[account]) {
                nodes.push(account);
            }
            nodeMap[account] = true;
        }
    }

    function getAllNodes() public view returns (address[] memory) {
        return nodes;
    }

    function getNodePerformance(address node) public view returns (uint256) {
        return nodePerformances[node];
    }

    function getUsrStakingPower(address owner) public view returns (uint256 btPower, uint256 beePower, uint256 lpAmount) {
        uint256 btAmount = userInfo[owner].btAmount;
        uint256 usdtAmount = btAmount.mul(btRatio).div(100);
        btPower = btAmount.mul(100).add(usdtAmount);

        uint256 beeAmount = userInfo[owner].beeAmount;
        usdtAmount = beeAmount.mul(beeRatio).div(100);
        beePower =beeAmount.mul(2).add(usdtAmount);

        lpAmount = userInfo[owner].lpAmount;
    }

    function updateLpPool() public {
        if (block.timestamp <= lpLastRewardTime) {
            return;
        }
        uint256 lpSupply = IERC20(lp).balanceOf(address(this));
        if (lpSupply == 0) {
            lpLastRewardTime = block.timestamp;
            return;
        }
        uint256 secds = block.timestamp.sub(lpLastRewardTime);
        if (lpTotalReward < lpRewardCap) {
            uint256 botReward = secds.mul(lpRewardBotPerSecond);
            uint256 delta = lpRewardCap.sub(lpTotalReward);
            lpTotalReward = lpTotalReward.add(botReward);
            if (lpTotalReward >= lpRewardCap) {
                botReward = delta;
                lpTotalReward = lpRewardCap;
                lpRewardEndTime = block.timestamp;
            }
            lpAccBotPerShare = lpAccBotPerShare.add(botReward.mul(ACC_PRECISION).div(lpSupply));
        }
        lpLastRewardTime = block.timestamp;
    }

    function stakeBT(uint256 amount, address node) public nonReentrant {
        require(block.timestamp >= startTime, "not start");
        require(btRewardEndTime == 0, "stake time end");
        require(amount > 0, "amount not good");
        require(amount <= btLeftover, "no bt leftover");
        uint256 usdtAmount = amount.mul(btRatio).div(100);
        address sender = _msgSender();
        UserInfo storage user = userInfo[sender];
        updateBtPool();

        if (btRewardEndTime > 0) {
            // reward end
            return;
        }

        if (user.btLastRewardTime > 0) {
            // pending reward
            uint256 secds = block.timestamp.sub(user.btLastRewardTime);
            uint256 pending = secds.mul(btRewardBotPerSecond).mul(user.btAmount).div(PRECISION);
            if (pending > 0) {
                dispatchReward(sender, pending);
            }
        }

        uint256 btBalance = IERC20(bt).balanceOf(sender);
        require(btBalance >= amount, "bt balance not good");

        uint256 usdtBalance = IERC20(usdt).balanceOf(sender);
        require(usdtBalance >= usdtAmount, "usdt balance not good");

        // transfer BT
        TransferHelper.safeTransferFrom(bt, sender, fixedWallet, amount);
        // transfer USDT
        TransferHelper.safeTransferFrom(usdt, sender, fixedWallet, usdtAmount);

        // update user stake info
        user.btAmount = user.btAmount.add(amount);
        user.usdtAmount = user.usdtAmount.add(usdtAmount);
        user.btLastRewardTime = block.timestamp;

        // update btLeftover
        btLeftover = btLeftover.sub(amount);
        btTotalStaked = btTotalStaked.add(amount);
        usdtTotalStaked = usdtTotalStaked.add(usdtAmount);

        // node usdt performance
        nodePerformances[node] = nodePerformances[node].add(usdtAmount);
    }

    function updateBtPool() public {
        if (btTotalStaked > 0) {
            if (btRewardEndTime > 0) {
                return;
            }

            uint256 secds = block.timestamp.sub(btLastRewardTime);
            uint256 pending = secds.mul(btRewardBotPerSecond).mul(btTotalStaked).div(PRECISION);
            btTotalReward = btTotalReward.add(pending);
            if (btTotalReward >= btRewardCap) { // reward end
                // update btTotalReward and btRewardEndTime
                btTotalReward = btRewardCap;
                btRewardEndTime = block.timestamp;
            } else {
                btLastRewardTime = block.timestamp;
            }
        }
    }

    function updateBeePool() public {
        if (beeTotalStaked > 0) {
            if (beeRewardEndTime > 0) {
                return;
            }

            uint256 secds = block.timestamp.sub(beeLastRewardTime);
            uint256 pending = secds.mul(beeRewardBotPerSecond).mul(beeTotalStaked).div(PRECISION);
            beeTotalReward = beeTotalReward.add(pending);
            if (beeTotalReward >= beeRewardCap) { // reward end
                // update beeTotalReward and beeRewardEndTime
                beeTotalReward = beeRewardCap;
                beeRewardEndTime = block.timestamp;
            } else {
                beeLastRewardTime = block.timestamp;
            }
        }
    }

    function stakeBEE(uint256 amount, address node) public nonReentrant {
        require(block.timestamp >= startTime, "not start");
        require(beeRewardEndTime == 0, "stake time end");
        require(amount > 0, "amount not good");
        require(amount <= beeLeftover, "no bee leftover");
        uint256 usdtAmount = amount.mul(beeRatio).div(100);
        address sender = _msgSender();
        UserInfo storage user = userInfo[sender];
        updateBeePool();

        if (beeRewardEndTime > 0) {
            // reward end
            return;
        }

        if (user.beeLastRewardTime > 0) {
            // pending reward
            uint256 secds = block.timestamp.sub(user.beeLastRewardTime);
            uint256 pending = secds.mul(beeRewardBotPerSecond).mul(user.beeAmount).div(PRECISION);
            if (pending > 0) {
                dispatchReward(sender, pending);
            }
        }

        uint256 beeBalance = IERC20(bee).balanceOf(sender);
        require(beeBalance >= amount, "bee balance not good");

        uint256 usdtBalance = IERC20(usdt).balanceOf(sender);
        require(usdtBalance >= usdtAmount, "usdt balance not good");

        // transfer BEE
        TransferHelper.safeTransferFrom(bee, sender, fixedWallet, amount);
        // transfer USDT
        TransferHelper.safeTransferFrom(usdt, sender, fixedWallet, usdtAmount);

        // update user stake info
        user.beeAmount = user.beeAmount.add(amount);
        user.usdtAmount = user.usdtAmount.add(usdtAmount);
        user.beeLastRewardTime = block.timestamp;

        // update beeLeftover
        beeLeftover = beeLeftover.sub(amount);
        beeTotalStaked = beeTotalStaked.add(amount);
        usdtTotalStaked = usdtTotalStaked.add(usdtAmount);

        // node usdt performance
        nodePerformances[node] = nodePerformances[node].add(usdtAmount);
    }

    function stakeLP(uint256 amount) public nonReentrant {
        require(lpEnabled, "not start");
        require(amount > 0, "amount not good");

        address sender = _msgSender();
        UserInfo storage user = userInfo[sender];
        updateLpPool();
        if (user.lpAmount > 0) {
            uint256 pending = user.lpAmount.mul(lpAccBotPerShare).div(ACC_PRECISION).sub(user.rewardDebtlp);
            if(pending > 0) {
                dispatchReward(sender, pending);
            }
        }
        // transfer LP
        TransferHelper.safeTransferFrom(lp, sender, address(this), amount);

        user.lpAmount = user.lpAmount.add(amount);
        user.rewardDebtlp = user.lpAmount.mul(lpAccBotPerShare).div(ACC_PRECISION);

        lpTotalStaked = lpTotalStaked.add(amount);

        emit DepositLP(sender, amount);
    }

    function dispatchReward(address to, uint256 amount) internal {
        uint256 reward = amount.div(10);
        // transfer 1/10 of reward to reward contract
        safeBotTransfer(rewardContract, reward);

        // transfer 9/10 of reward to user
        amount = amount.sub(reward);
        safeBotTransfer(to, amount);
    }

    function safeBotTransfer(address to, uint256 amount) internal {
        uint256 botBal = IERC20(bot).balanceOf(address(this));
        if (amount > botBal) {
            TransferHelper.safeTransfer(bot, to, botBal);
        } else {
            TransferHelper.safeTransfer(bot, to, amount);
        }
    }

    function unstakeLP(uint256 amount) public {
        address sender = _msgSender();
        UserInfo storage user = userInfo[sender];
        require(user.lpAmount >= amount, "withdraw: amount not good");
        updateLpPool();
        uint256 pending = user.lpAmount.mul(lpAccBotPerShare).div(ACC_PRECISION).sub(user.rewardDebtlp);
        if(pending > 0) {
            dispatchReward(sender, pending);
        }
        if(amount > 0) {
            user.lpAmount = user.lpAmount.sub(amount);
            TransferHelper.safeTransfer(lp, address(sender), amount);
        }
        user.rewardDebtlp = user.lpAmount.mul(lpAccBotPerShare).div(ACC_PRECISION);

        lpTotalStaked = lpTotalStaked.sub(amount);

        emit WithdrawLP(sender, amount);
    }

    function pendingRewardBT(address owner) public view returns (uint256) {
        UserInfo storage user = userInfo[owner];
        if (user.btLastRewardTime > 0) {
            uint256 secds;
            if (btRewardEndTime > 0) {
                secds = btLastRewardTime.sub(user.btLastRewardTime);
            } else {
                secds = block.timestamp.sub(user.btLastRewardTime);
            }
            uint256 pending = secds.mul(btRewardBotPerSecond).mul(user.btAmount).div(PRECISION);
            return pending;
        }
        return 0;
    }

    function pendingRewardBEE(address owner) public view returns (uint256) {
        UserInfo storage user = userInfo[owner];
        if (user.beeLastRewardTime > 0) {
            uint256 secds;
            if (beeRewardEndTime > 0) {
                secds = beeLastRewardTime.sub(user.beeLastRewardTime);
            } else {
                secds = block.timestamp.sub(user.beeLastRewardTime);
            }
            uint256 pending = secds.mul(beeRewardBotPerSecond).mul(user.beeAmount).div(PRECISION);
            return pending;
        }
        return 0;
    }

    function pendingRewardLP(address owner) public view returns (uint256) {
        UserInfo memory user = userInfo[owner];

        if (block.timestamp <= lpLastRewardTime) {
            return 0;
        }

        uint256 lpSupply = IERC20(lp).balanceOf(address(this));
        if (lpSupply == 0) {
            return 0;
        }

        uint256 accBotPerShare = lpAccBotPerShare;
        uint256 totalReward = lpTotalReward;
        if (totalReward < lpRewardCap) {
            uint256 secds = block.timestamp.sub(lpLastRewardTime);
            uint256 botReward = secds.mul(lpRewardBotPerSecond);
            uint256 delta = lpRewardCap.sub(totalReward);
            totalReward = totalReward.add(botReward);
            if (totalReward >= lpRewardCap) {
                botReward = delta;
            }
            accBotPerShare = accBotPerShare.add(botReward.mul(ACC_PRECISION).div(lpSupply));
        }

        if (user.lpAmount > 0) {
            uint256 pending = user.lpAmount.mul(accBotPerShare).div(ACC_PRECISION).sub(user.rewardDebtlp);
            return pending;
        }

        return 0;
    }

    function pendingRewardAll(address owner) public view returns (uint256 btReward, uint256 beeReward, uint256 lpReward) {
        btReward = pendingRewardBT(owner);
        beeReward = pendingRewardBEE(owner);
        lpReward = pendingRewardLP(owner);
    }

    function withdrawRewardBT() public {
        address sender = _msgSender();
        UserInfo storage user = userInfo[sender];
        updateBtPool();

        uint256 secds;
        if (btRewardEndTime > 0) {
            secds = btLastRewardTime.sub(user.btLastRewardTime);
        } else {
            secds = block.timestamp.sub(user.btLastRewardTime);
        }

        uint256 pending = secds.mul(btRewardBotPerSecond).mul(user.btAmount).div(PRECISION);
        // transfer bot
        if(pending > 0) {
            dispatchReward(sender, pending);
        }

        // update btLastRewardTime
        user.btLastRewardTime = block.timestamp;
    }

    function withdrawRewardBEE() public {
        address sender = _msgSender();
        UserInfo storage user = userInfo[sender];
        updateBeePool();

        uint256 pending;
        if (beeRewardEndTime > 0) {
            // pending reward
            uint256 secds = beeLastRewardTime.sub(user.beeLastRewardTime);
            pending = secds.mul(beeRewardBotPerSecond).mul(user.beeAmount).div(PRECISION);
        } else {
            uint256 secds = block.timestamp.sub(user.beeLastRewardTime);
            pending = secds.mul(beeRewardBotPerSecond).mul(user.beeAmount).div(PRECISION);
        }

        // transfer bot
        if (pending > 0) {
            dispatchReward(sender, pending);
        }

        // update usr beeLastRewardTime
        user.beeLastRewardTime = block.timestamp;
    }

    function withdrawRewardLP() public {
        address sender = _msgSender();
        UserInfo storage user = userInfo[sender];
        updateLpPool();

        if (user.lpAmount > 0) {
            uint256 pending = user.lpAmount.mul(lpAccBotPerShare).div(ACC_PRECISION).sub(user.rewardDebtlp);
            if(pending > 0) {
                dispatchReward(sender, pending);
            }
        }
        user.rewardDebtlp = user.lpAmount.mul(lpAccBotPerShare).div(ACC_PRECISION);
    }

    function withdrawRewardAll() public {
        withdrawRewardBT();
        withdrawRewardBEE();
        withdrawRewardLP();
    }

    function totalStaked() public view returns (uint256 btStaked, uint256 beeStaked, uint256 usdtStaked, uint256 lpStaked) {
        btStaked = btTotalStaked;
        beeStaked = beeTotalStaked;
        usdtStaked = usdtTotalStaked;
        lpStaked = lpTotalStaked;
    }

    function isStakingEnd() public view returns (bool btEnd, bool beeEnd, bool lpEnd) {
        btEnd = isBtStakingEnd();
        beeEnd = isBeeStakingEnd();
        lpEnd = isLpStakingEnd();
    }

    function isBtStakingEnd() public view returns (bool) {
        return (btRewardEndTime > 0) || (btLeftover == 0);
    }

    function isBeeStakingEnd() public view returns (bool) {
        return (beeRewardEndTime > 0) || (beeLeftover == 0);
    }

    function isLpStakingEnd() public view returns (bool) {
        return lpRewardEndTime > 0;
    }

    function apyLP() public view returns (uint256) {
        uint256 lpStaked = IERC20(lp).balanceOf(address(this));
        uint256 lpTotalSupply = IERC20(lp).totalSupply();
        uint256 botBalanceOfLp = IERC20(bot).balanceOf(lp);
        uint256 botStaked = botBalanceOfLp.mul(lpStaked).div(lpTotalSupply);
        if (botStaked == 0) {
            return 0;
        }
        uint256 yearlyReward = lpRewardBotPerSecond.mul(3600).mul(24).mul(365);
        return yearlyReward.mul(100).div(botStaked);
    }

    function withdrawBOT(uint256 amount) public onlyOwner {
        TransferHelper.safeTransfer(bot, fixedWallet, amount);
    }

    function withdrawTRX(uint256 amount) public onlyOwner {
        msg.sender.transfer(amount);
    }
}