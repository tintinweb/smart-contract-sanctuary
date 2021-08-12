// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//  _ __   ___  __ _ _ __ ______ _ _ __  
// | '_ \ / _ \/ _` | '__|_  / _` | '_ \ 
// | |_) |  __/ (_| | |   / / (_| | |_) |
// | .__/ \___|\__,_|_|  /___\__,_| .__/ 
// | |                            | |    
// |_|                            |_|    

// https://pearzap.com/

// The garden : Stake 1 token, earn 2 tokens

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract TheGarden is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebtTA; // Reward debt. See explanation below.  
        uint256 rewardDebtTB; // Reward debt. See explanation below.  
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPointTokenA;       // How many allocation points assigned to this pool. PEARs to distribute per block for token A  
        uint256 allocPointTokenB;       // How many allocation points assigned to this pool. PEARs to distribute per block for token B  
        uint256 lastRewardBlock;  // Last block number that PEARs distribution occurs.
        uint256 accRewardTAPerShare; // Accumulated TokenA rewards per share, times 1e30. See below.  
        uint256 accRewardTBPerShare; // Accumulated TokenB rewards per share, times 1e30. See below.  
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 bonusEndBlock; // The block number when REWARDTOKEN pool ends.
    }

    // PEAR token
    IBEP20 public pear;
    // Reward tokens 
    IBEP20 public rewardTokenA; 
    IBEP20 public rewardTokenB;

    // Reward tokens distributed per block.
    uint256 public rewardPerBlockTA;
    uint256 public rewardPerBlockTB;
    
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
    // The block number when PEAR mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _pear,
        IBEP20 _rewardTokenA,
        IBEP20 _rewardTokenB,
        uint256 _rewardPerBlockTA,
        uint256 _rewardPerBlockTB,
        address _burnAddress,
        uint16 _depositFeeBP,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        pear = _pear;
        rewardTokenA = _rewardTokenA;
        rewardTokenB = _rewardTokenB;        
        rewardPerBlockTA = _rewardPerBlockTA;
        rewardPerBlockTB = _rewardPerBlockTB;
        burnAddress = _burnAddress;
        depositFeeToBurn = _depositFeeBP;
        startBlock = _startBlock;

        // Deposit fee limited to 10% No way for contract owner to set higher deposit fee
        require(depositFeeToBurn <= 1000, "contract: invalid deposit fee basis points");

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _pear,
            allocPointTokenA: 1000,
            allocPointTokenB: 1000,
            lastRewardBlock: startBlock,
            accRewardTAPerShare: 0,
            accRewardTBPerShare: 0,
            depositFeeBP: depositFeeToBurn,
            bonusEndBlock: _bonusEndBlock
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

    // View function to see pending Reward for token A on frontend.
    function pendingRewardTA(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTAPerShare = pool.accRewardTAPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number,0);
            uint256 tokenAReward = multiplier.mul(rewardPerBlockTA).mul(pool.allocPointTokenA).div(totalAllocPoint);
            accRewardTAPerShare = accRewardTAPerShare.add(tokenAReward.mul(1e30).div(lpSupply));
        }
        return user.amount.mul(accRewardTAPerShare).div(1e30).sub(user.rewardDebtTA);
    }

    // View function to see pending Reward for token A on frontend.
    function pendingRewardTB(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTBPerShare = pool.accRewardTBPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number,0);
            uint256 tokenBReward = multiplier.mul(rewardPerBlockTB).mul(pool.allocPointTokenB).div(totalAllocPoint);
            accRewardTBPerShare = accRewardTBPerShare.add(tokenBReward.mul(1e30).div(lpSupply));
        }
        return user.amount.mul(accRewardTBPerShare).div(1e30).sub(user.rewardDebtTB);
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
        
        uint256 tokenAReward = multiplier.mul(rewardPerBlockTA).mul(pool.allocPointTokenA).div(totalAllocPoint);
        pool.accRewardTAPerShare = pool.accRewardTAPerShare.add(tokenAReward.mul(1e30).div(lpSupply));      
        uint256 tokenBReward = multiplier.mul(rewardPerBlockTB).mul(pool.allocPointTokenB).div(totalAllocPoint);
        pool.accRewardTBPerShare = pool.accRewardTBPerShare.add(tokenBReward.mul(1e30).div(lpSupply));        

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
            uint256 pendingTA = user.amount.mul(pool.accRewardTAPerShare).div(1e30).sub(user.rewardDebtTA);
            if(pendingTA > 0) {
                rewardTokenA.safeTransfer(address(msg.sender), pendingTA);
            }
            uint256 pendingTB = user.amount.mul(pool.accRewardTBPerShare).div(1e30).sub(user.rewardDebtTB);
            if(pendingTA > 0) {
                rewardTokenB.safeTransfer(address(msg.sender), pendingTB);
            }            
        }
        // Add the possibility of deposit fees sent to burn address
        if(_amount > 0) {

            // Handle any token with transfer tax
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)).sub(balanceBefore);

            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(burnAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }   
        
        user.rewardDebtTA = user.amount.mul(pool.accRewardTAPerShare).div(1e30);
        user.rewardDebtTB = user.amount.mul(pool.accRewardTBPerShare).div(1e30);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw PEAR tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pendingTA = user.amount.mul(pool.accRewardTAPerShare).div(1e30).sub(user.rewardDebtTA);
        if(pendingTA > 0) {
            rewardTokenA.safeTransfer(address(msg.sender), pendingTA);
        }
        uint256 pendingTB = user.amount.mul(pool.accRewardTBPerShare).div(1e30).sub(user.rewardDebtTB);
        if(pendingTA > 0) {
            rewardTokenB.safeTransfer(address(msg.sender), pendingTB);
        }  
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebtTA = user.amount.mul(pool.accRewardTAPerShare).div(1e30);
        user.rewardDebtTB = user.amount.mul(pool.accRewardTBPerShare).div(1e30);

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.rewardDebtTA = 0;
        user.rewardDebtTB = 0;        
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward token A. EMERGENCY ONLY.
    function emergencyRewardWithdrawTA(uint256 _amount) public onlyOwner {
        require(_amount < rewardTokenA.balanceOf(address(this)), 'not enough token');
        rewardTokenA.safeTransfer(address(msg.sender), _amount);
    }
    
    // Withdraw reward token A. EMERGENCY ONLY.
    function emergencyRewardWithdrawTB(uint256 _amount) public onlyOwner {
        require(_amount < rewardTokenB.balanceOf(address(this)), 'not enough token');
        rewardTokenB.safeTransfer(address(msg.sender), _amount);
    }    
    
    // Add a function to update rewardPerBlock. Can only be called by the owner.
    function updateRewardPerBlockTA(uint256 _rewardPerBlockTA) public onlyOwner {
        rewardPerBlockTA = _rewardPerBlockTA;
        //Automatically updatePool 0
        updatePool(0);        
    } 
    
    // Add a function to update rewardPerBlock. Can only be called by the owner.
    function updateRewardPerBlockTB(uint256 _rewardPerBlockTB) public onlyOwner {
        rewardPerBlockTB = _rewardPerBlockTB;
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

}