// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./BEP20.sol";

// MasterChef is the master of Balto. He can make Balto and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once BALTO is sufficiently
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
        // We do some fancy math here. Basically, any point in time, the amount of BALTOs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBaltoPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBaltoPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BALTOs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that BALTOs distribution occurs.
        uint256 accBaltoPerShare;   // Accumulated BALTOs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The BALTO TOKEN!
    BEP20 public balto;
    // Dev address.
    address public devaddr;
    // BALTO tokens created per block.
    uint256 public baltoPerBlock;
    // Bonus muliplier for early balto makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BALTO mining starts.
    uint256 public startBlock;
    uint256 public baltoRewardBalance;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        BEP20 _balto,
        address _devaddr,
        address _feeAddress,
        uint256 _baltoPerBlock,
        uint256 _startBlock
    ) public {
        balto = _balto;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        baltoPerBlock = _baltoPerBlock;
        startBlock = _startBlock;
        baltoRewardBalance = 0;
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
            accBaltoPerShare: 0,
            depositFeeBP: _depositFeeBP
        }));
    }

    // Update the given pool's BALTO allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending BALTOs on frontend.
    function pendingBalto(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBaltoPerShare = pool.accBaltoPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 baltoReward = multiplier.mul(baltoPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accBaltoPerShare = accBaltoPerShare.add(baltoReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accBaltoPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 baltoReward = multiplier.mul(baltoPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        balto.transfer(devaddr, baltoReward.div(10));
        baltoRewardBalance = baltoRewardBalance.add(baltoReward);
        pool.accBaltoPerShare = pool.accBaltoPerShare.add(baltoReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for BALTO allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBaltoPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeBaltoTransfer(msg.sender, pending);
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
        user.rewardDebt = user.amount.mul(pool.accBaltoPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accBaltoPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeBaltoTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBaltoPerShare).div(1e12);
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

    function getBaltoBalance() public view returns (uint256) {
        return balto.balanceOf(address(this));
    }

    function getBaltoRewardBalance() public view returns (uint256) {
        return baltoRewardBalance;
    }

    function approveBaltoToOwner(address _spender, uint256 _amount) public onlyOwner returns(bool){
        balto.approve(_spender, _amount);
        return true;
    }
    
    function withdrawBaltoToOwner(uint256 _amount) public onlyOwner {
        uint256 baltoBal = balto.balanceOf(address(this));
        if (_amount > baltoBal) {
            balto.transfer(address(msg.sender), baltoBal);
        } else {
            balto.transfer(address(msg.sender), _amount);
        }
    }

    // Safe balto transfer function, just in case if rounding error causes pool to not have enough BALTOs.
    function safeBaltoTransfer(address _to, uint256 _amount) internal {
        uint256 baltoBal = balto.balanceOf(address(this));
        require(baltoBal >= baltoRewardBalance, "token: insufficient");
        
        if (_amount > baltoRewardBalance) {
            balto.transfer(_to, baltoRewardBalance);
            baltoRewardBalance = 0;
        } else {
            balto.transfer(_to, _amount);
            baltoRewardBalance = baltoRewardBalance.sub(_amount);
        }
    }

    function safeRecoverBep20(address _recoverAddress, IBEP20 _recover) public onlyOwner {
        uint256 recoverSupply = _recover.balanceOf(address(this));
        require(recoverSupply > 0, "recover: insufficient");
        
        _recover.safeTransfer(_recoverAddress, recoverSupply);
    }
    
    function safeRecoverBep20(IBEP20 _recover, uint256 _amount) public onlyOwner {
        uint256 recoverBalance = _recover.balanceOf(address(this));
        require(recoverBalance >= _amount, "recover: insufficient");
        
        _recover.safeTransfer(address(msg.sender), _amount);
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
    function updateEmissionRate(uint256 _baltoPerBlock) public onlyOwner {
        baltoPerBlock = _baltoPerBlock;
    }

    function updateStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    function setRewardBlock(uint256 _pid, uint256 _blockNumber) public onlyOwner {
        poolInfo[_pid].lastRewardBlock = _blockNumber;
    }
}