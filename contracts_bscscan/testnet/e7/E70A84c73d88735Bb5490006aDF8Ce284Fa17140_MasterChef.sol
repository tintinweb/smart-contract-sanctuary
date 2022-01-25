// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./DataStorage.sol";
import "./Events.sol";
import "./IBEP20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";


// MasterChef is the master of Cake. He can make Cake and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CAKE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is
    Ownable,
    ReentrancyGuard,
    Pausable,
    DataStorage,
    Events
{
    using SafeMath for uint256;
    constructor(IBEP20 _cake, uint256 _cakePerBlock) public {
        cake = _cake;
        cakePerBlock = _cakePerBlock;
        // staking pool
        poolInfo.push(
            PoolInfo({
                lpToken: _cake,
                allocPoint: 240000*10**18,
                lastRewardBlock: block.number,
                accCakePerShare: 0,
                startBlock: block.number,
                endBlock: block.number.add(uint256(86400).mul(60))
            })
        );
        poolInfo.push(
            PoolInfo({
                lpToken: _cake,
                allocPoint: 300000*10**18,
                lastRewardBlock: block.number,
                accCakePerShare: 0,
                startBlock: block.number,
                endBlock: block.number.add(uint256(86400).mul(60))
            })
        );

        poolInfo.push(
            PoolInfo({
                lpToken: _cake,
                allocPoint: 300000*10**18,
                lastRewardBlock: block.number,
                accCakePerShare: 0,
                startBlock: block.number,
                endBlock: block.number.add(uint256(86400).mul(60))
            })
        );

        totalAllocPoint = 840000*10**18;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        bool _withUpdate,
        uint256 _startBlock,
        uint256 _endBlock
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: block.number,
                accCakePerShare: 0,
                startBlock: _startBlock,
                endBlock: _endBlock
            })
        );
    }

    // Update the given pool's CAKE allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(
                _allocPoint
            );
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCakePerShare = pool.accCakePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 cakeReward = multiplier
                .mul(cakePerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accCakePerShare = accCakePerShare.add(
                cakeReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accCakePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cakeReward = multiplier
            .mul(cakePerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accCakePerShare = pool.accCakePerShare.add(
            cakeReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) public whenNotPaused nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        require(block.number >= pool.startBlock, "pool not start");
        require(block.number <= pool.endBlock, "pool was stop");
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accCakePerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (pending > 0) {
                uint256 feeWithdraw = pending.mul(WIHDRAW_FEE).div(
                    PERCENTS_DIVIDER
                );
                safeCakeTransfer(msg.sender, pending.sub(feeWithdraw));
                cake.transfer(msg.sender, feeWithdraw);
                emit FeePayed(msg.sender, feeWithdraw);
            }
        }
        if (_amount > 0) {
            pool.lpToken.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid) public whenNotPaused nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            uint256 feeWithdraw = pending.mul(WIHDRAW_FEE).div(
                PERCENTS_DIVIDER
            );
            safeCakeTransfer(msg.sender, pending.sub(feeWithdraw));
            cake.transfer(msg.sender, feeWithdraw);
            emit FeePayed(msg.sender, feeWithdraw);
        }
        user.rewardDebt = user.amount.mul(pool.accCakePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, pending);
    }

    // Leave STAKING.
    function leaveStaking(uint256 _pid) public whenNotPaused nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "withdraw: not good");
        uint256 _amount = user.amount;
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCakePerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            uint256 feeWithdraw = pending.mul(UNSTAKE_FEE).div(
                PERCENTS_DIVIDER
            );
            safeCakeTransfer(msg.sender, pending.sub(feeWithdraw));
            cake.transfer(msg.sender, feeWithdraw);
            emit FeePayed(msg.sender, feeWithdraw);
        }
        if (_amount > 0) {
            pool.lpToken.transfer(address(msg.sender), user.amount);
            user.amount = 0;
        }
        user.rewardDebt = 0;

        emit LeaveStaking(msg.sender, _pid, pending);
    }

    // Safe cake transfer function, just in case if rounding error causes pool to not have enough CAKEs.
    function safeCakeTransfer(address _to, uint256 _amount) internal {
        cake.transfer(_to, _amount);
    }

    function setUnStakeFee(uint256 _fee) external onlyOwner {
        UNSTAKE_FEE = _fee;
    }

    function setWithdrawFee(uint256 _fee) external onlyOwner {
        WIHDRAW_FEE = _fee;
    }

    function setCommissionsWallet(address payable _addr) external onlyOwner {
        commissionWallet = _addr;
    }

    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) external onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IBEP20(coinAddress).transfer(to, value);
    }
}