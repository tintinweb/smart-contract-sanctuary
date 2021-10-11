// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./RainbowToken.sol";
import "./RNBZ.sol";

// MasterChef is the master of RNBO. He can make RNBO and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once RNBO is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract RNBOExclusiveMC is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 lastDepositTimestamp;
        uint256 lastHarvestTimestamp;
        uint256 lastWithdrawTimestamp;
        uint256 lastActualDepositTimestamp;
        //
        // We do some fancy math here. Basically, any point in time, the amount of RNBO
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRNBOPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRNBOPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. RNBO to distribute per block.
        uint256 lastRewardBlock;  // Last block number that RNBO distribution occurs.
        uint256 accRNBOPerShare;   // Accumulated RNBO per share, times 1e18. See below.
        uint256 poolWithdrawFee;
    }

    RainbowToken public RNBO;

    RNBZ public rnbzToken;

    address public devAddress;

    address public feeAddress;

    uint256 public rnboPerBlock = 3*(10**18);
    uint256 public boosterRnboPerBlock = 1*(10**18);

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    uint256 public maxWithdrawFee = 500;
    
    uint256 public minRNBZRequired = 1000*(10**18);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 rnboPerBlock);

    constructor(
        RainbowToken _RNBO,
        RNBZ _rnbzToken,
        uint256 _startBlock,
        address _devAddress,
        address _feeAddress
    ) public {
        RNBO = _RNBO;
        rnbzToken = _rnbzToken;
        if (_startBlock == 0){
            startBlock = block.number;
        }
        else{
            startBlock = _startBlock;
        }
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
    
    function setMaxWithdrawFee(uint256 _fee) public onlyOwner returns (bool){
        require(_fee <= 500 ,"ERROR:Fee:Withdarw Fee cannot be higher than 2%");
        maxWithdrawFee = _fee;
        return true;
    }

    function setMinRNBZHolding(uint256 _minRNBZ) public onlyOwner returns (bool){
        require(_minRNBZ > 1*(10**18), "ERR::MinRNBZ:Min RNBZ Req should be greater than 1 RNBZ");
        minRNBZRequired = _minRNBZ;
        return true;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken,uint256 _poolWithdrawFee) external onlyOwner nonDuplicated(_lpToken) {
        require(poolExistence[_lpToken] == false, "ERR::Pool:Pool Exist");
        require(_poolWithdrawFee < 500, "ERR:Fees:Max Fee 1%");
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRNBOPerShare: 0,
            poolWithdrawFee:_poolWithdrawFee
        }));
    }

    // Update the given pool's RNBO allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _poolWithdrawFee) external onlyOwner {
        require(_poolWithdrawFee < 100, "ERR:Fees:Max Fee 1%");
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].poolWithdrawFee = _poolWithdrawFee;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function pendingRNBO(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRNBOPerShare = pool.accRNBOPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 RNBOReward = multiplier.mul(rnboPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRNBOPerShare = accRNBOPerShare.add(RNBOReward.mul(1e18).div(lpSupply));
        }
        return user.amount.mul(accRNBOPerShare).div(1e18).sub(user.rewardDebt);
    }
    
    function hasBalanceStaked(address _user) internal view returns (bool) {
        bool balanceStaked = false;
        for(uint i=1;i <  poolInfo.length;i++)
        {
            UserInfo storage usr = userInfo[i][_user];
            if(usr.amount > 0){
                balanceStaked = true;
                break;
            }
        }
        return balanceStaked;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
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
        uint256 RNBOReward = multiplier.mul(rnboPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 BoosterRNBOReward = multiplier.mul(boosterRnboPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        RNBO.mint(devAddress, RNBOReward.div(20));
        RNBO.mint(address(this), RNBOReward);
        RNBO.mint(address(this), BoosterRNBOReward);

        pool.accRNBOPerShare = pool.accRNBOPerShare.add(RNBOReward.mul(1e18).div(lpSupply));

        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        UserInfo storage rnbzuser = userInfo[0][msg.sender];
        require((rnbzuser.amount >= minRNBZRequired ||_pid == 0) && _amount > 0, "ERR::MinReq:Not meeting minimum RNBZ staking requirement to enter pools");
        uint256 _depositamount = 0 ;
        updatePool(_pid);
        uint256 rewardBoost = getBoostRewardRate(msg.sender,_pid);
        if (user.amount > 0) {
            user.lastHarvestTimestamp = block.timestamp;
            uint256 pending = user.amount.mul(pool.accRNBOPerShare).div(1e18).sub(user.rewardDebt);
            if (pending > 0) {
                if(rnbzuser.amount > minRNBZRequired){
                safeRNBOTransfer(msg.sender, pending.add(pending.mul(rewardBoost).div(100)));
                }
                else{
                safeRNBOTransfer(address(feeAddress), pending); //if user does not hold min required RNBZ then whole rewards will be sent to fees address
                }
            }
        }
        if (_amount > 0) {
            uint256 _amountbefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 _amountafter = pool.lpToken.balanceOf(address(this));
            _depositamount = _amountafter.sub(_amountbefore);
            bool resetDepositTimeStamp = false;
            if(_amount.mul(10) >= user.amount || ((block.timestamp - user.lastActualDepositTimestamp)/60/60) < 12){ //if new deposit is higher tha 10% of total amount them reset deposit timestamp
                resetDepositTimeStamp= true;
            }
            user.amount = user.amount.add(_depositamount);
            if(resetDepositTimeStamp){
            user.lastDepositTimestamp = block.timestamp;
            }
            user.lastActualDepositTimestamp = block.timestamp;
        }
        user.rewardDebt = user.amount.mul(pool.accRNBOPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function getActualWithdrawFeeRate(address _user,uint256 _pid) public view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 poolWithdrawFee = pool.poolWithdrawFee; 
		uint256 actualWithdrawFeeRate = poolWithdrawFee; 
        uint256 v_feesbp = 0;
		if(maxWithdrawFee < poolWithdrawFee ) {
			actualWithdrawFeeRate = maxWithdrawFee; 
		}

		uint256 daysfromlastdeposit = ((((block.timestamp - user.lastDepositTimestamp)/60)/60)/24);
		if(actualWithdrawFeeRate > 0)
		{
		if(daysfromlastdeposit < 2){
			v_feesbp = actualWithdrawFeeRate.mul(110).div(100);     //10% penalty if withdraw within 1st week
		}
		else if(daysfromlastdeposit < 7){
			v_feesbp = actualWithdrawFeeRate;
		}
		else if(daysfromlastdeposit < 14){
		    if(actualWithdrawFeeRate > 150){
			v_feesbp = actualWithdrawFeeRate.sub(100); //reduce withdrawal fee by 100 basis point (1%) after 7 days
		    }
		    else{
			v_feesbp = 50;
		    }
		}
		else if(daysfromlastdeposit < 21){
		    if(actualWithdrawFeeRate > 250){
			v_feesbp = actualWithdrawFeeRate.sub(200); //reduce withdrawal fee by 200 basis point (2%) after 14 days
		    }
		    else{
			v_feesbp = 50;
		    }
		}
		else if(daysfromlastdeposit < 28){
		    if(actualWithdrawFeeRate > 350){
			v_feesbp = actualWithdrawFeeRate.sub(300); //reduce withdrawal fee by 300 basis point (3%) after 7 days
		    }
		    else{
			v_feesbp = 50;
		    }
		}
		else{
			v_feesbp = 50; //falt 0.5 withdraw fees if withdran after 5 weeks
		}
		}
		else{
		    v_feesbp = actualWithdrawFeeRate;
		}
        return v_feesbp;
    }

    function getBoostRewardRate(address _user,uint256 _pid) public view returns (uint256){
        UserInfo storage user = userInfo[_pid][_user];
        uint256 timeFromLastHarvest = ((((block.timestamp - user.lastHarvestTimestamp)/60)/60)/24);
        uint256 timeFromLastWithdraw = ((((block.timestamp - user.lastWithdrawTimestamp)/60)/60)/24);
        uint256 timeToConsiderForBoost = 0;
        if(timeFromLastHarvest < timeFromLastWithdraw){
            timeToConsiderForBoost = timeFromLastHarvest;
        }
        else{
            timeToConsiderForBoost = timeFromLastWithdraw;
        }
        if(timeToConsiderForBoost > 7){
            timeToConsiderForBoost = timeToConsiderForBoost - 7; //boost starts after first week
            if(timeToConsiderForBoost > 100){
                timeToConsiderForBoost = 100;
            }
        }
        else{
            timeToConsiderForBoost = 0;
        }
        return timeToConsiderForBoost;
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "Error::withdraw: Withdrawing more than balance");
        require(_amount > 0, "Error::withdraw: Withdrawing Nothing");
        uint256 withdrawAmt = _amount;
        if(_pid == 0){
            if(hasBalanceStaked(msg.sender)){
                if(user.amount.sub(_amount) < minRNBZRequired){
                    withdrawAmt = user.amount.sub(minRNBZRequired);
                }
            }
        }
        UserInfo storage rnbzuser = userInfo[0][msg.sender];
        uint256 v_fees = 0;
        uint256 v_feerate = 0;

        updatePool(_pid);

        uint256 rewardBoost = getBoostRewardRate(msg.sender,_pid);
        uint256 pending = user.amount.mul(pool.accRNBOPerShare).div(1e18).sub(user.rewardDebt);

        if (pending > 0) {
            if(rnbzuser.amount > minRNBZRequired)
            {
            safeRNBOTransfer(msg.sender, pending.add(pending.mul(rewardBoost).div(100)));
            }
            else{
            safeRNBOTransfer(address(feeAddress), pending); //if user does not hold min required RNBZ then whole rewards will be sent to fees address
            }
        }
        if (_amount > 0) {
            uint256 v_feesbp = 0;
            if(rnbzuser.amount > minRNBZRequired){
            v_feesbp = getActualWithdrawFeeRate(msg.sender,_pid);
            }
            else{
                v_feesbp = 1000;    //if user does not hold min required RNBZ then flat 10% fees will be applied
            }
            v_fees = withdrawAmt.mul(v_feesbp).div(10000);
            user.amount = user.amount.sub(withdrawAmt);
            uint256 v_withdrawAmount = withdrawAmt.sub(v_fees);
            pool.lpToken.safeTransfer(address(msg.sender),v_withdrawAmount);
            pool.lpToken.safeTransfer(address(feeAddress),v_fees);
        }
        user.lastHarvestTimestamp = block.timestamp;
        user.lastWithdrawTimestamp = block.timestamp;
        user.rewardDebt = user.amount.mul(pool.accRNBOPerShare).div(1e18);

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

    // Safe rnbo transfer function, just in case if rounding error causes pool to not have enough RNBO.
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

    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0),"Error::AddressChange:Fee Address cannot be 0");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function updateEmissionRate(uint256 _rnboPerBlock) external onlyOwner {
        massUpdatePools();
        require(rnboPerBlock > _rnboPerBlock*(10**18),"Error:Emmission: New Emission Rate need to be lower than existing");
        rnboPerBlock = _rnboPerBlock*(1e18);
        emit UpdateEmissionRate(msg.sender, _rnboPerBlock);
    }

    // Only update before start of farm
    function updateStartBlock(uint256 _startBlock) external onlyOwner {
	    require(startBlock > block.number, "Farm already started");
        startBlock = _startBlock;
    }
}