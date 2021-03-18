pragma solidity 0.6.6;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

interface MiningToken is IERC20 {
    function mint(address to, uint256 amount)  external;
    function transferOwnership(address newOwner) external;
}

contract MiningContract is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 miningTokenPledgeAmount; // How many Mining tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardToClaim; // when deposit or withdraw, update pending reward  to rewartToClaim.
    }

    struct PoolInfo {
        IERC20  lpToken;            // Address of   LP token.
        uint256 miningTokenRatioNumerator;   //   miningTokenRatioDenominator is 1e18
        uint256 allocPoint;         // How many allocation points assigned to this pool. mining token  distribute per block.
        uint256 lastRewardBlock;    // Last block number that mining token distribution occurs.
        uint256 accPerShare;        // Accumulated mining token per share, times 1e12. See below.
    }

    IERC20 public miningToken; // The mining token TOKEN

    uint256 public phase1StartBlockNumber;
    uint256 public phase1EndBlockNumber;
    uint256 public phase1TokenPerBlock;


    PoolInfo[] public poolInfo; // Info of each pool.
    mapping (uint256 => mapping (address => UserInfo)) private userInfo; // Info of each user that stakes LP tokens.
    uint256 public totalAllocPoint = 0;  // Total allocation poitns. Must be the sum of all allocation points in all pools.
    bool public enableClaim = false;  // claim switch

    event Claim(address indexed user, uint256  pid, uint256 amount);
    event Deposit(address indexed user, uint256  pid, uint256 amount);
    event Withdraw(address indexed user, uint256  pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256  pid, uint256 amount);

    constructor(address _mining_token, uint256 _mining_start_block) public {
        miningToken = IERC20(_mining_token);
        //  15 sec per block in eth chain , （ 60/15 ) * 60 * 24 =  5760
        uint256 blockCountPerDay = 5760;
        uint256 blockCountOf14day = blockCountPerDay.mul(14);
        phase1StartBlockNumber = _mining_start_block;
        phase1EndBlockNumber = phase1StartBlockNumber.add(blockCountOf14day);
        uint256 phase1TokenMountPerDay = 400000 * 1e17; // 86.1 per day
        phase1TokenPerBlock = phase1TokenMountPerDay.div(blockCountPerDay) ;
    }


    function updateClaimSwitch(bool _enableClaim) public onlyOwner {
       enableClaim = _enableClaim;
    }

    function getUserInfo(uint256 _pid, address _user) public view returns (
        uint256 _amount, uint256 _miningTokenPledgeAmount,uint256 _rewardDebt,uint256 _rewardToClaim) {
        require(_pid < poolInfo.length, "invalid _pid");
        UserInfo memory info = userInfo[_pid][_user];
        _amount = info.amount;
        _miningTokenPledgeAmount = info.miningTokenPledgeAmount;
        _rewardDebt = info.rewardDebt;
        _rewardToClaim = info.rewardToClaim;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, address _lpToken,uint256 _miningTokenRatioNumerator, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > phase1StartBlockNumber ? block.number : phase1StartBlockNumber;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: IERC20(_lpToken),
            miningTokenRatioNumerator: _miningTokenRatioNumerator,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPerShare: 0
        }));
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        require(_pid < poolInfo.length, "invalid _pid");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function getCurrentRewardsPerBlock() public view returns (uint256) {
        return getMultiplier(block.number - 1, block.number);
    }

    // Return reward  over the given _from to _to block. Suppose it doesn't span two adjacent mining block number
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        require(_to > _from, "_to should greater than  _from ");
        if(_from < phase1StartBlockNumber && phase1StartBlockNumber < _to   && _to < phase1EndBlockNumber) {
            return _to.sub(phase1StartBlockNumber).mul(phase1TokenPerBlock);
        }
        if (phase1StartBlockNumber <= _from  && _from < phase1EndBlockNumber && _to <= phase1EndBlockNumber) {
            return _to.sub(_from).mul(phase1TokenPerBlock);
        }
		return 0;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        require(_pid < poolInfo.length, "invalid _pid");
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
        uint256 reward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);
//        miningToken.mint(address(this), reward);
//        miningToken.mint(devAddr, reward.div(10));
        pool.accPerShare = pool.accPerShare.add(reward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function getMiningTokenAmountByRatio(uint256 _lpAmount, uint256  _miningTokenRatioNumerator) public pure returns (uint256) {
        return _lpAmount.mul(_miningTokenRatioNumerator).div(1e18);  // miningTokenRatioDenominator is 1e18
    }

    function getPendingAmount(uint256 _pid, address _user) public view returns (uint256) {
        require(_pid < poolInfo.length, "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPerShare = pool.accPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(pool.allocPoint).div(totalAllocPoint);
            accPerShare = accPerShare.add(reward.mul(1e12).div(lpSupply));
        }
        uint256 pending =  user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
        uint256 totalPendingAmount =  user.rewardToClaim.add(pending);
        return totalPendingAmount; 
    }

    function getAllPendingAmount(address _user) external view returns (uint256) {
        uint256 length = poolInfo.length;
        uint256 allAmount = 0;
        for (uint256 pid = 0; pid < length; ++pid) {
            allAmount =  allAmount.add(getPendingAmount(pid,_user));
        }
        return allAmount;
    }

    function claimAll() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
                if(getPendingAmount(pid, msg.sender) > 0 ) {
                   claim(pid);
            }
        }
    }

    function claim(uint256 _pid) public {  
        require(_pid < poolInfo.length, "invalid _pid");
        require(enableClaim, "could not claim now");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
            user.rewardToClaim = user.rewardToClaim.add(pending);
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        safeMiningTokenTransfer(msg.sender, user.rewardToClaim);
        emit Claim(msg.sender, _pid, user.rewardToClaim );
        user.rewardToClaim = 0;
    }

    // Deposit LP tokens to Mining for token allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        require(_pid < poolInfo.length, "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
            user.rewardToClaim = user.rewardToClaim.add(pending);
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        if(_amount > 0) { // for gas saving
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
//            if(pool.miningTokenRatioNumerator > 0) {
//                uint256 miningTokenAmount  =  getMiningTokenAmountByRatio(_amount, pool.miningTokenRatioNumerator);
//                miningToken.safeTransferFrom(msg.sender,address(this), miningTokenAmount);
//                user.miningTokenPledgeAmount = user.miningTokenPledgeAmount.add(miningTokenAmount);
//            }
            user.amount = user.amount.add(_amount);
            emit Deposit(msg.sender, _pid, _amount);
        }
    }

    // Withdraw LP tokens from Mining.
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(_pid < poolInfo.length, "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: user.amount is not enough");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
        user.rewardToClaim = user.rewardToClaim.add(pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
//        if(pool.miningTokenRatioNumerator > 0) {
//            uint256 miningTokenAmount  =  getMiningTokenAmountByRatio(_amount, pool.miningTokenRatioNumerator);
//            require(user.miningTokenPledgeAmount >= miningTokenAmount, "withdraw: user.miningTokenPledgeAmount is not enough");
//            safeMiningTokenTransfer(msg.sender, miningTokenAmount);
//            user.miningTokenPledgeAmount = user.miningTokenPledgeAmount.sub(miningTokenAmount);
//        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        require(_pid < poolInfo.length, "invalid _pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        if(user.miningTokenPledgeAmount > 0){
            safeMiningTokenTransfer(msg.sender, user.miningTokenPledgeAmount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.miningTokenPledgeAmount = 0;
        user.rewardDebt = 0;
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough mining token.
    function safeMiningTokenTransfer(address _to, uint256 _amount) internal {
        uint256 bal = miningToken.balanceOf(address(this));
        require(bal >= _amount, "MiningContract' balance is not enough.");
        miningToken.safeTransfer(_to, _amount);
    }

}