//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;


// based on PanCakeSwap SmartChef contract
// added functionnalities
// - correct accounting for StakeTokens with transfertax
// - possibility to update reward per block
// - possibility to update end bonus block
// - possibility to update and add deposit fees

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract EarningPool is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. STAKETOKENs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that STAKETOKENs distribution occurs.
        uint256 accStakeTokenPerShare; // Accumulated STAKETOKENs per share, times 1e12. See below.
        uint16 depositFee;      //  Deposit fee in basis points
    }

    // The STAKETOKEN TOKEN!
    IBEP20 public stakeToken;
    IBEP20 public rewardToken;

    // STAKETOKEN tokens created per block.
    uint256 public rewardPerBlock;
    
    // Deposit Fee address
    address public feeAddress = 0x45472B519de9Ac90A09BF51d9E161B8C6476361D;

    // Deposit fee to fee Address
    uint16 public depositFeetoFee = 200;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    
    // The block number when STAKETOKEN mining starts.
    uint256 public startBlock;
    
    // The block number when STAKETOKEN mining ends.
    uint256 public bonusEndBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _stakeToken,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint16 _depositFee,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        depositFeetoFee = _depositFee;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        //  Deposit fee limited to capped to max 5%.
        require(depositFeetoFee <= 500, "contract: invalid deposit fee basis points");

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _stakeToken,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accStakeTokenPerShare: 0,
            depositFee: depositFeetoFee
        }));

        totalAllocPoint = 1000;

    }

    function stopReward() public onlyOwner {
        bonusEndBlock = block.number;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accStakeTokenPerShare = pool.accStakeTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 stakeTokenReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accStakeTokenPerShare = accStakeTokenPerShare.add(stakeTokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accStakeTokenPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 stakeTokenReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accStakeTokenPerShare = pool.accStakeTokenPerShare.add(stakeTokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Stake STAKETOKEN
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        updatePool(0);
        
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accStakeTokenPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }

        //  Add the possibility of deposit fees sent to fee address
        if(_amount > 0) {

            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            _amount = _after.sub(before); // correct calculation for StakeToken with Transfertax

            if(pool.depositFee > 0){
                uint256 depositFeeAmount = _amount.mul(pool.depositFee).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFeeAmount);
                user.amount = user.amount.add(_amount).sub(depositFeeAmount);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }        
        
        
        user.rewardDebt = user.amount.mul(pool.accStakeTokenPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw STAKETOKEN tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accStakeTokenPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accStakeTokenPerShare).div(1e12);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(_amount < rewardToken.balanceOf(address(this)), 'not enough token');
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }
    
    //  Add a function to update rewardPerBlock. Can only be called by the owner.
    function updateRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        updatePool(0);        
    } 
    
    //  Add a function to update bonusEndBlock. Can only be called by the owner.
    function updateBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        bonusEndBlock = _bonusEndBlock;
    }   
    
    //  Update the given pool's deposit fee. Can only be called by the owner.
    function updateDepositFee(uint256 _pid, uint16 _depositFee) public onlyOwner {
        require(_depositFee <= 500, "updateDepositFee: invalid deposit fee");
        poolInfo[_pid].depositFee = _depositFee;
        depositFeetoFee = _depositFee;
    }    

}