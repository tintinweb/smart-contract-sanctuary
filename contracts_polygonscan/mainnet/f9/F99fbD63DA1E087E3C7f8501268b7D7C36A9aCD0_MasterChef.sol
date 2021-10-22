// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ReentrancyGuard.sol";

import "./Ownable.sol";

import "./SafeMath.sol";

import "./SafeERC20.sol";

import "./DiamondToken.sol";

import "./IReferral.sol";

// MasterChef is the master of Diamond. He can make Diamond and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Diamond is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
// European boys play fair, don't worry.

contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of IRIS
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accIrisPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accIrisPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. IRISes to distribute per block.
        uint256 lastRewardBlock;  // Last block number that IRISes distribution occurs.
        uint256 accIrisPerShare;   // Accumulated IRISes per share, times 1e18. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
	uint256 lpSupply; 
    }

    // The DIAMOND TOKEN!
    DiamondToken public iris;
    address public devAddress;
    address public feeAddress;
    uint256 constant max_iris_supply = 1000000 ether;

    // IRIS tokens created per block.
    uint256 public irisPerBlock = 0.4 ether;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when IRIS mining starts.
    uint256 public startBlock;

    // Iris referral contract address.
    IReferral public referral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 200;
    // Max referral commission rate: 5%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 500;
    uint256 public constant MAXIMUM_EMISSION_RATE = 1 ether;

    bool updateReferralAddress = false;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetReferralAddress(address indexed user, IReferral indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 irisPerBlock);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event PoolAdd(address indexed user, IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint16 depositFeeBP);
    event PoolSet(address indexed user, IERC20 lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint16 depositFeeBP);
    event SetReferralCommissionRate(address indexed user, uint16 referralCommmissionRate);
    event UpdateStartBlock(address indexed user, uint256 startBlock);
    constructor(
        DiamondToken _iris,
        uint256 _startBlock,
        address _devAddress,
        address _feeAddress
        
    ) public {
        iris = _iris;
        startBlock = _startBlock;

        devAddress = _devAddress;
        feeAddress = _feeAddress;
        
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP) external onlyOwner nonDuplicated(_lpToken) {
	_lpToken.balanceOf(address(this));
        require(_depositFeeBP <= 500, "add: invalid deposit fee basis points");
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accIrisPerShare: 0,
            depositFeeBP: _depositFeeBP,
	    lpSupply: 0
        }));
	emit PoolAdd(msg.sender, _lpToken, _allocPoint,lastRewardBlock,_depositFeeBP);
    }

    // Update the given pool's IRIS allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP) external onlyOwner {
        require(_depositFeeBP <= 500, "set: invalid deposit fee basis points");
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
	emit PoolSet(msg.sender, poolInfo[_pid].lpToken, _allocPoint,poolInfo[_pid].lastRewardBlock,_depositFeeBP);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (iris.totalSupply() >= max_iris_supply) return 0;
 
        return _to.sub(_from);
    }

    // View function to see pending DIAMONDs on frontend.
    function pendingIris(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accIrisPerShare = pool.accIrisPerShare;
        if (block.number > pool.lastRewardBlock && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 irisReward = multiplier.mul(irisPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accIrisPerShare = accIrisPerShare.add(irisReward.mul(1e18).div(pool.lpSupply));
        }
        return user.amount.mul(accIrisPerShare).div(1e18).sub(user.rewardDebt);
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
        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 irisReward = multiplier.mul(irisPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
	if(iris.totalSupply().add(irisReward.mul(105).div(100)) <= max_iris_supply){
	  iris.mint(devAddress, irisReward.div(100));
	  iris.mint(address(this), irisReward);
	}else if(iris.totalSupply() < max_iris_supply){
	  iris.mint(address(this), max_iris_supply.sub(iris.totalSupply()));
	}
        pool.accIrisPerShare = pool.accIrisPerShare.add(irisReward.mul(1e18).div(pool.lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for DIAMOND allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) nonReentrant external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(referral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            referral.recordReferral(msg.sender, _referrer);
        }
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accIrisPerShare).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                safeIrisTransfer(msg.sender, pending);
                payReferralCommission(msg.sender, pending);
            }
        }
        if (_amount > 0) {
	    uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
	    _amount = pool.lpToken.balanceOf(address(this)).sub(balanceBefore);
	    require(_amount > 0, "we dont accept deposits of 0");
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
		pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
		pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accIrisPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) nonReentrant external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accIrisPerShare).div(1e18).sub(user.rewardDebt);
        if (pending > 0) {
            safeIrisTransfer(msg.sender, pending);
            payReferralCommission(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
	    pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accIrisPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) nonReentrant external{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
	pool.lpSupply = pool.lpSupply.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe DIAMOND transfer function, just in case if rounding error causes pool to not have enough DIAMOND.
    function safeIrisTransfer(address _to, uint256 _amount) internal {
        uint256 irisBal = iris.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > irisBal) {
            transferSuccess = iris.transfer(_to, irisBal);
        } else {
            transferSuccess = iris.transfer(_to, _amount);
        }
        require(transferSuccess, "safeIrisTransfer: Transfer failed");
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) external onlyOwner {
	require(_devAddress != address(0), "!nonzero");
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
	require(_feeAddress != address(0), "!nonzero");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function updateEmissionRate(uint256 _irisPerBlock) external onlyOwner {
        require(_irisPerBlock <= MAXIMUM_EMISSION_RATE, "Too High");
        massUpdatePools();
        irisPerBlock = _irisPerBlock;
        emit UpdateEmissionRate(msg.sender, _irisPerBlock);
    }

    // Update the referral contract address by the owner
    function setReferralAddress(IReferral _referral) external onlyOwner {
	require(updateReferralAddress == false, "The Referral contract address is changed already");
        referral = _referral;
	updateReferralAddress = true;
        emit SetReferralAddress(msg.sender, _referral);
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) external onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
	emit SetReferralCommissionRate(msg.sender, _referralCommissionRate);
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(referral) != address(0) && referralCommissionRate > 0) {
            address referrer = referral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
		if(iris.totalSupply().add(commissionAmount) <= max_iris_supply){
		  iris.mint(referrer, commissionAmount);
		}else if(iris.totalSupply() < max_iris_supply) {
		  iris.mint(address(this), max_iris_supply.sub(iris.totalSupply()));
		}
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    // Only update before start of farm
    function updateStartBlock(uint256 _startBlock) onlyOwner external{
	require(startBlock > block.number, "Farm already started");
	uint256 length = poolInfo.length;
	for(uint256 pid = 0; pid < length; ++pid){
		PoolInfo storage pool = poolInfo[pid];
		pool.lastRewardBlock = _startBlock;
	}
        startBlock = _startBlock;
	emit UpdateStartBlock(msg.sender, _startBlock);
    }
}