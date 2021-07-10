// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./BEP20.sol";

// MasterChef is the master of WWP. He can make WWP and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once WWP is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of WWPs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accWWPPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accWWPPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. WWPs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that WWPs distribution occurs.
        uint256 accWWPPerShare;   // Accumulated WWPs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The WWP TOKEN!
    BEP20 public wwp;
    // Dev address.
    address public devaddr;
    // WWP tokens created per block.
    uint256 public wwpPerBlock;
    // Bonus muliplier for early wwp makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when WWP mining starts.
    uint256 public startBlock;
    uint256 public wwpRewardBalance;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        BEP20 _wwp,
        address _devaddr,
        address _feeAddress,
        uint256 _wwpPerBlock,
        uint256 _startBlock
    ) public {
        wwp = _wwp;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        wwpPerBlock = _wwpPerBlock;
        startBlock = _startBlock;
        wwpRewardBalance = 0;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accWWPPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's PolynxPerBlock allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending PolynxPerBlocks on frontend.
    function pendingWWP(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accWWPPerShare = pool.accWWPPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 wwpReward = multiplier.mul(wwpPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accWWPPerShare = accWWPPerShare.add(wwpReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accWWPPerShare).div(1e12).sub(user.rewardDebt);
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
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 wwpReward = multiplier.mul(wwpPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        wwp.transfer(devaddr, wwpReward.div(10));
        wwpRewardBalance = wwpRewardBalance.add(wwpReward);
        pool.accWWPPerShare = pool.accWWPPerShare.add(wwpReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for PolynxPerBlock allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accWWPPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeWWPTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accWWPPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accWWPPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeWWPTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accWWPPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function getWWPBalance() public view returns (uint256) {
        return wwp.balanceOf(address(this));
    }

    function getWWPRewardBalance() public view returns (uint256) {
        return wwpRewardBalance;
    }

    function approveWWPToOwner(address _spender, uint256 _amount) public onlyOwner returns(bool){
        wwp.approve(_spender, _amount);
        return true;
    }
    
    function withdrawWWPToOwner(uint256 _amount) public onlyOwner {
        uint256 wwpBal = wwp.balanceOf(address(this));
        if (_amount > wwpBal) {
            wwp.transfer(address(msg.sender), wwpBal);
        } else {
            wwp.transfer(address(msg.sender), _amount);
        }
    }

    // Safe wwp transfer function, just in case if rounding error causes pool to not have enough PolynxPerBlocks.
    function safeWWPTransfer(address _to, uint256 _amount) internal {
        uint256 wwpBal = wwp.balanceOf(address(this));
        require(wwpBal >= wwpRewardBalance, "token: insufficient");
        
        if (_amount > wwpRewardBalance) {
            wwp.transfer(_to, wwpRewardBalance);
            wwpRewardBalance = 0;
        } else {
            wwp.transfer(_to, _amount);
            wwpRewardBalance = wwpRewardBalance.sub(_amount);
        }
    }

    function setStartBlcok(uint256 _block) public onlyOwner {
        require(_block > block.number, "setStartBlcok: invalid");
        startBlock = _block;
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public{
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _wwpPerBlock) public onlyOwner {
        massUpdatePools();
        wwpPerBlock = _wwpPerBlock;
    }
}