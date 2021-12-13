// MinimalSwap: Masterchef

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";

import "./MinimalToken.sol";

contract Masterchef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of MINIMAL
        // entitled to a user but is pending to be distributed is:
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        // The pool's `accMinimalPerShare` (and `lastRewardBlock`) gets updated.
        // User receives the pending reward sent to his/her address.
        // User's `amount` gets updated.
        // User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;             // Address of LP token contract
        uint256 allocPoint;         // How many allocation points assigned to this pool. MINIMAL to distribute per block
        uint256 lastRewardBlock;    // Last block number that MINIMAL distribution occurs
        uint256 accMinimalPerShare; // Accumulated MINIMAL per share, times 1e12. See below
        uint16 depositFeeBP;        // Deposit fee in basis points
    }

    // The MINIMAL TOKEN!
    MinimalToken public minimal;
    // Dev address
    address public devaddr;
    // MINIMAL tokens created per block
    uint256 public minimalPerBlock;
    // Bonus muliplier for early minimal makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when MINIMAL mining starts
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateStartBlock(uint256 oldStartBlock, uint256 newStartBlock);

    constructor(
        MinimalToken _minimal,
        address _devaddr,
        address _feeAddress,
        uint256 _minimalPerBlock,
        uint256 _startBlock
    ) public {
        minimal = _minimal;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        minimalPerBlock = _minimalPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner
    // Do not add the same LP token more than once. Rewards will be messed up
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 400, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accMinimalPerShare: 0,
            depositFeeBP: _depositFeeBP
            }));
    }

    // Update the given pool's MINIMAL allocation point and deposit fee. Can only be called by the owner
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 400, "set: invalid deposit fee basis points");
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

    // View function to see pending MINIMAL on frontend
    function pendingMinimal(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMinimalPerShare = pool.accMinimalPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 minimalReward = multiplier.mul(minimalPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accMinimalPerShare = accMinimalPerShare.add(minimalReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accMinimalPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending
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
        uint256 minimalReward = multiplier.mul(minimalPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        minimal.mint(devaddr, minimalReward.div(10));
        minimal.mint(address(this), minimalReward);
        pool.accMinimalPerShare = pool.accMinimalPerShare.add(minimalReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for MINIMAL allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMinimalPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeMinimalTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            _amount = _after.sub(before);

            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accMinimalPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accMinimalPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeMinimalTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMinimalPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY!
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe MINIMAL transfer function, just in case if rounding error causes pool to not have enough MINIMAL
    function safeMinimalTransfer(address _to, uint256 _amount) internal {
        uint256 minimalBal = minimal.balanceOf(address(this));
        if (_amount > minimalBal) {
            minimal.transfer(_to, minimalBal);
        } else {
            minimal.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev
    function setDevAddress(address _devaddr) public {
        require(msg.sender == _devaddr, "setDevAddress: FORBIDDEN");
        require(_devaddr != address(0), "setDevAddress: ZERO");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    //MINIMAL has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all
    function updateEmissionRate(uint256 _minimalPerBlock) public onlyOwner {
        massUpdatePools();
        minimalPerBlock = _minimalPerBlock;
    }

    // Update startBlock by the owner (added this to ensure that dev can delay startBlock due to the congestion in BSC). Only used if required!
    function updateStartBlock(uint256 _startBlock) public onlyOwner {   
        require(startBlock > block.number, 'updateStartBlock: farm already started');
        require(_startBlock > block.number, 'updateStartBlock: new start time must be future time');

        uint256 _previousStartBlock = startBlock;

        startBlock = _startBlock;
        for (uint i=0; i < poolInfo.length; i++) {
            poolInfo[i].lastRewardBlock = startBlock;
            emit UpdateStartBlock(_previousStartBlock, _startBlock);
        }
    }
}