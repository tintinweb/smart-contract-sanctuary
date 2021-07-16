// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./RainbowToken.sol";
import "./RNBORewardToken.sol";
// MasterChef is the master of Fish. He can make Fish and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Fish is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 lastDepositTimestamp;
        uint256 userWeight;
        //
        // We do some fancy math here. Basically, any point in time, the amount of FISHes
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accFishPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accFishPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. FISHes to distribute per block.
        uint256 lastRewardBlock;  // Last block number that FISHes distribution occurs.
        uint256 accRNBOPerShare;   // Accumulated FISHes per share, times 1e18. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 totalWeight;
    }

    // The FISH TOKEN!
    RainbowToken public RNBO;
    StakedRNBO public stkRNBO;
    address public devAddress;
    address public feeAddress;
    uint256 private withdrawFee24Hr = 200;
    uint256 private withdrawFee72Hr = 100;
    uint256 private withdrawFeeDefault = 50;

    // FISH tokens created per block.
    uint256 public rnboPerBlock = 4;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when RNBO mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event SetVaultAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 fishPerBlock);
    event FeeUpdate(address indexed user,uint256 withdrawFee24Hr,uint256 withdrawFee72Hr,uint256 withdrawFeeDefault);
    event Debug(address indexed user,string valuetype,uint256 value);

    constructor(
        RainbowToken _RNBO,
        StakedRNBO _stkRNBO,
        uint256 _startBlock,
        address _devAddress,
        address _feeAddress
    ) public {
        RNBO = _RNBO;
        stkRNBO = _stkRNBO;
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
        require(_depositFeeBP <= 100, "Error::DepositFees:Max Deposit Fee is 100 Basis Point");
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRNBOPerShare: 0,
            depositFeeBP: _depositFeeBP,
            totalWeight:0
        }));
    }

    // Update the given pool's FISH allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP) external onlyOwner {
        require(_depositFeeBP <= 100, "Error::DepositFees:Max Deposit Fee is 100 Basis Point");
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending FISHes on frontend.
    function pendingRNBO(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRNBOPerShare = pool.accRNBOPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 v_totalWeight = pool.totalWeight;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 RNBOReward = multiplier.mul(rnboPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRNBOPerShare = accRNBOPerShare.add(RNBOReward.mul(1e18).div(v_totalWeight));
        }
        return user.amount.mul(accRNBOPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
    function userPoolWeight(uint256 _pid) public view returns (uint256) {
        uint256 v_userWeight = userInfo[_pid][msg.sender].userWeight;
        uint256 v_amount = userInfo[_pid][msg.sender].amount;
        return v_userWeight.div(v_amount);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        emit Debug(msg.sender,"lpsupply",lpSupply);
        uint256 v_totalWeight = pool.totalWeight;
        emit Debug(msg.sender,"v_totalWeight",v_totalWeight);
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        emit Debug(msg.sender,"multiplier",multiplier);
        uint256 RNBOReward = multiplier.mul(rnboPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        emit Debug(msg.sender,"RNBOReward",RNBOReward);
        RNBO.mint(devAddress, RNBOReward.div(20));
        RNBO.mint(address(this), RNBOReward);
        pool.accRNBOPerShare = pool.accRNBOPerShare.add(RNBOReward.mul(10**18).div(v_totalWeight));
        emit Debug(msg.sender,"pool.accRNBOPerShare ",pool.accRNBOPerShare);
        pool.lastRewardBlock = block.number;
    }
    
    // Deposit LP tokens to MasterChef for FISH allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.userWeight.mul(pool.accRNBOPerShare).div(1e18).sub(user.rewardDebt);
            emit Debug(msg.sender,"pending",pending);
            if (pending > 0) {
                safeRNBOTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (pool.depositFeeBP > 0 && startBlock <= block.number) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accRNBOPerShare).div(1e18);
        user.lastDepositTimestamp = block.timestamp;
        if(pool.totalWeight > 0) {
            pool.totalWeight = pool.totalWeight.sub(user.userWeight);
            emit Debug(msg.sender,"user.userWeight ",user.userWeight);
            emit Debug(msg.sender,"pool.totalWeight ",pool.totalWeight);
        }
        if (pool.lpToken ==  RNBO){
            stkRNBO.mint(msg.sender,_amount);
        }
        uint256 v_newuserWeight = stkRNBO.balanceOf(msg.sender).div(stkRNBO.totalSupply());
        emit Debug(msg.sender,"v_newuserWeight",v_newuserWeight);
        user.userWeight = user.amount.mul(1+v_newuserWeight);
        emit Debug(msg.sender,"user.userWeight ",user.userWeight);
        pool.totalWeight = pool.totalWeight.add(user.userWeight);
        emit Debug(msg.sender,"pool.totalWeight ",pool.totalWeight);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "Error::withdraw: Withdrawing more than balance");
        updatePool(_pid);
        uint256 withdrawFee = withdrawFeeDefault;
        if (block.timestamp < user.lastDepositTimestamp + 24 hours) {
            withdrawFee = withdrawFee24Hr;
        }
        else if (block.timestamp < user.lastDepositTimestamp + 72 hours ) {
            withdrawFee = withdrawFee72Hr;
        }
        uint256 pending = user.userWeight.mul(pool.accRNBOPerShare).div(1e18).sub(user.rewardDebt);
        if (pending > 0) {
            safeRNBOTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            uint256 fees = user.amount.mul(withdrawFee).div(10000);
            uint256 withdrawAmt = user.amount.sub(fees);
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), withdrawAmt);
            pool.lpToken.safeTransfer(address(feeAddress),fees);
        }
        user.rewardDebt = user.amount.mul(pool.accRNBOPerShare).div(1e18);
        require(user.userWeight > 0 && pool.totalWeight > 0 , "ERROR:RNBOWeight:System Malfunction, withdrawing more than staked");
        pool.totalWeight = pool.totalWeight.sub(user.userWeight);
        if (pool.lpToken ==  RNBO){
            stkRNBO.burn(msg.sender,_amount);
        }
        uint256 v_newuserWeight = stkRNBO.balanceOf(msg.sender).div(stkRNBO.totalSupply());
        user.userWeight = user.amount.mul(1+v_newuserWeight);
        pool.totalWeight = pool.totalWeight.add(user.userWeight);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe fish transfer function, just in case if rounding error causes pool to not have enough FISH.
    function safeRNBOTransfer(address _to, uint256 _amount) internal {
        uint256 RNBOBal = RNBO.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > RNBOBal) {
            transferSuccess = RNBO.transfer(_to, RNBOBal);
        } else {
            transferSuccess = RNBO.transfer(_to, _amount);
        }
        require(transferSuccess, "safeRNBOTransfer: Transfer failed");
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0),"Error::AddressChange:Dev Address cannot be 0");
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }

    function setWithdrawFees(uint256 _withdrawFee24Hrs,uint256 _withdrawFee72Hrs,uint256 _withdrawFeeDefault) external onlyOwner {
        require(_withdrawFee24Hrs < 400 && _withdrawFee72Hrs < 200 && _withdrawFeeDefault < 100, "Error::Fees:Withdraw Fee Above Hard Limits");
        withdrawFee24Hr = _withdrawFee24Hrs;
        withdrawFee72Hr = _withdrawFee72Hrs;
        withdrawFeeDefault = _withdrawFeeDefault;
        emit FeeUpdate(msg.sender,_withdrawFee24Hrs,_withdrawFee72Hrs,_withdrawFeeDefault);
    }


    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0),"Error::AddressChange:Fee Address cannot be 0");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function updateEmissionRate(uint256 _rnboPerBlock) external onlyOwner {
        massUpdatePools();
        require(rnboPerBlock > _rnboPerBlock,"Error:Emmission: New Emission Rate need to be lower than existing");
        rnboPerBlock = _rnboPerBlock;
        emit UpdateEmissionRate(msg.sender, _rnboPerBlock);
    }

    // Only update before start of farm
    function updateStartBlock(uint256 _startBlock) external onlyOwner {
	    require(startBlock > block.number, "Farm already started");
        startBlock = _startBlock;
    }
}