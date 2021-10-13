// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//  _ __   ___  __ _ _ __ ______ _ _ __  
// | '_ \ / _ \/ _` | '__|_  / _` | '_ \ 
// | |_) |  __/ (_| | |   / / (_| | |_) |
// | .__/ \___|\__,_|_|  /___\__,_| .__/ 
// | |                            | |    
// |_|                            |_|    

// https://pearzap.com/

// The simple garden for partnership : Stake PEAR, earn 1 partner token

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract TheGardenLocked is Ownable {
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
        uint256 allocPoint;       // How many allocation points assigned to this pool. REWARDTOKENs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that REWARDTOKENs distribution occurs.
        uint256 accRewardTPerShare; // Accumulated REWARDTOKENs per share, times 1e30. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 bonusEndBlock; // The block number when REWARDTOKEN pool ends.
        //uint256 stakeUntil; // The timestamp until it's possible to make a deposit into the pool
        uint256 withdrawOnlyAfter; // The timestamp after it's possible to withdraw the stacked PEARs
    }

    // PEAR token
    IBEP20 public pear;
    IBEP20 public rewardToken;

    // REWARDTOKEN tokens created per block.
    uint256 public rewardPerBlock;
    
    // Deposit burn address
    address public burnAddress;
    // Deposit fee to burn
    uint16 public depositFeeToBurn;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // The block number when REWARDTOKEN pool starts.
    uint256 public startBlock;
    
    
    uint256 public constant hardCap = 500000000000000000000000; //hardcoded 500k in wei
    uint256 public receivedFund;
    uint256 public constant maxInvestment = 5000000000000000000000; //hardcode 5k in wei

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _pear,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        address _burnAddress,
        uint16 _depositFeeBP,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        //uint256 _stakeUntil,
        uint256 _withdrawOnlyAfter
    ) public {
        pear = _pear;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        burnAddress = _burnAddress;
        depositFeeToBurn = _depositFeeBP;
        startBlock = _startBlock;

        // Deposit fee limited to 10% No way for contract owner to set higher deposit fee
        require(depositFeeToBurn <= 1000, "contract: invalid deposit fee basis points");

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _pear,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accRewardTPerShare: 0,
            depositFeeBP: depositFeeToBurn,
            bonusEndBlock: _bonusEndBlock,
            //stakeUntil: _stakeUntil,
            withdrawOnlyAfter: _withdrawOnlyAfter
        }));

        totalAllocPoint = 1000;

    }

    function stopReward(uint256 _pid) public onlyOwner {
        poolInfo[_pid].bonusEndBlock = block.number;
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to, uint256 _pid) public view returns (uint256) {
        if (_to <= poolInfo[_pid].bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= poolInfo[_pid].bonusEndBlock) {
            return 0;
        } else {
            return poolInfo[_pid].bonusEndBlock.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTPerShare = pool.accRewardTPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number,0);
            uint256 rewardTReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRewardTPerShare = accRewardTPerShare.add(rewardTReward.mul(1e30).div(lpSupply));
        }
        return user.amount.mul(accRewardTPerShare).div(1e30).sub(user.rewardDebt);
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
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number,0);
        uint256 rewardTReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accRewardTPerShare = pool.accRewardTPerShare.add(rewardTReward.mul(1e30).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Stake PEAR tokens to TheGarden
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRewardTPerShare).div(1e30).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }

        // Add the possibility of deposit fees sent to burn address
        // Deposit asset is only possible before the max cap
        if(_amount > 0) {
            
         //check maximum cap      
        require((receivedFund + _amount) <= hardCap, "Max cap reached");    

        //check maximum investment        
        require((user.amount + _amount) <= maxInvestment, "Investment not in allowed range");       
            
            // Handle any token with transfer tax
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)).sub(balanceBefore);  
            
            receivedFund = receivedFund + _amount; 

            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(burnAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }        
        
        
        user.rewardDebt = user.amount.mul(pool.accRewardTPerShare).div(1e30);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw PEAR tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(block.timestamp > pool.withdrawOnlyAfter, "withdraw: asset locked, wait the end of the lock period");
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accRewardTPerShare).div(1e30).sub(user.rewardDebt);
        if(pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardTPerShare).div(1e30);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        require(block.timestamp > pool.withdrawOnlyAfter, "withdraw: asset locked, wait the end of the lock period");
        
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
    
    // Add a function to update rewardPerBlock. Can only be called by the owner.
    function updateRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        //Automatically updatePool 0
        updatePool(0);        
    } 
    
    // Add a function to update bonusEndBlock. Can only be called by the owner.
    function updateBonusEndBlock(uint256 _bonusEndBlock, uint256 _pid) public onlyOwner {
        poolInfo[_pid].bonusEndBlock = _bonusEndBlock;
    }   
    
    // Update the given pool's deposit fee. Can only be called by the owner.
    function updateDepositFeeBP(uint256 _pid, uint16 _depositFeeBP) public onlyOwner {
        require(_depositFeeBP <= 10000, "updateDepositFeeBP: invalid deposit fee basis points");
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        depositFeeToBurn = _depositFeeBP;
    } 
    
    // Add a function to update startBlock. Can only be called by the owner.
    function updateStartBlock(uint256 _startBlock) public onlyOwner {
        //Can only be updated if the original startBlock is not minted
        require(block.number <= poolInfo[0].lastRewardBlock, "updateStartBlock: startblock already minted");
        poolInfo[0].lastRewardBlock = _startBlock;
        startBlock = _startBlock;
    }    
    
    // View function to see if withdrawal is possible
    function canWithdraw() public view returns (bool) {
        PoolInfo storage pool = poolInfo[0];
        return block.timestamp > pool.withdrawOnlyAfter;
    }
    
    // Display user max available investment
    function remainingContribution(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 remaining = maxInvestment - user.amount;
        return remaining;
    }    
    
    // Display remaining until max cap available investment
    function remainingToHardCap() public view returns (uint256) {
        uint256 remaining = hardCap - receivedFund;
        return remaining;
    }       

}