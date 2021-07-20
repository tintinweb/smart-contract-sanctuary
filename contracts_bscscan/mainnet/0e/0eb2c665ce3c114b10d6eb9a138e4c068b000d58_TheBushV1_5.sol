// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | |  ___  ____   | || |     ____     | || |      __      | || |   _____      | || |      __      | |
// | | |_  ||_  _|  | || |   .'    `.   | || |     /  \     | || |  |_   _|     | || |     /  \     | |
// | |   | |_/ /    | || |  /  .--.  \  | || |    / /\ \    | || |    | |       | || |    / /\ \    | |
// | |   |  __'.    | || |  | |    | |  | || |   / ____ \   | || |    | |   _   | || |   / ____ \   | |
// | |  _| |  \ \_  | || |  \  `--'  /  | || | _/ /    \ \_ | || |   _| |__/ |  | || | _/ /    \ \_ | |
// | | |____||____| | || |   `.____.'   | || ||____|  |____|| || |  |________|  | || ||____|  |____|| |
// | |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
// '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

// based on PanCakeSwap SmartChef contract
// added functionnalities by the Koala's devs
//
// - possibility to update reward per block
// - possibility to update end bonus block
// - possibility to update and add deposit fees

// Bush V1_5 by Koala King
// managing double token reward distribution
// add possibility to update start bonus block
// nalis features

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract TheBushV1_5 is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebtTA; // Reward debt. See explanation below. V1_5
        uint256 rewardDebtTB; // Reward debt. See explanation below. V1_5
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPointTokenA;       // How many allocation points assigned to this pool. NALISs to distribute per block for token A V1_5 // TODO : Clean if not util
        uint256 allocPointTokenB;       // How many allocation points assigned to this pool. NALISs to distribute per block for token B V1_5
        uint256 lastRewardBlock;  // Last block number that NALISs distribution occurs.
        uint256 accRewardTAPerShare; // Accumulated TokenA rewards per share, times 1e12. See below. V1_5
        uint256 accRewardTBPerShare; // Accumulated TokenB rewards per share, times 1e12. See below. V1_5
        uint16 depositFeeBP;      // V1 Deposit fee in basis points
    }

    // The NALIS TOKEN!
    IBEP20 public nalis;
    // Reward tokens V1_5
    IBEP20 public rewardTokenA; // V1_5
    IBEP20 public rewardTokenB; // V1_5

    // Reward tokens distributed per block.
    uint256 public rewardPerBlockTA; // V1_5
    uint256 public rewardPerBlockTB; // V1_5
    
    // V1
    // Deposit burn address
    address public burnAddress;
    // V1
    // Deposit fee to burn
    uint16 public depositFeeToBurn;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // The block number when NALIS mining starts.
    uint256 public startBlock;
    // The block number when NALIS mining ends.
    uint256 public bonusEndBlock;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    constructor(
        IBEP20 _nalis,
        IBEP20 _rewardTokenA, // V1_5
        IBEP20 _rewardTokenB, // V1_5
        uint256 _rewardPerBlockTA, // V1_5
        uint256 _rewardPerBlockTB, // V1_5
        address _burnAddress, // V1
        uint16 _depositFeeBP, // V1
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        nalis = _nalis;
        rewardTokenA = _rewardTokenA;
        rewardTokenB = _rewardTokenB;        
        rewardPerBlockTA = _rewardPerBlockTA; // V1_5
        rewardPerBlockTB = _rewardPerBlockTB; // V1_5       
        burnAddress = _burnAddress; // V1
        depositFeeToBurn = _depositFeeBP; // V1
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // V1 / Deposit fee limited to 10% No way for contract owner to set higher deposit fee
        require(depositFeeToBurn <= 1000, "contract: invalid deposit fee basis points");

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _nalis,
            allocPointTokenA: 1000, // V1_5
            allocPointTokenB: 1000, // V1_5
            lastRewardBlock: startBlock,
            accRewardTAPerShare: 0, // V1_5
            accRewardTBPerShare: 0, // V1_5
            depositFeeBP: depositFeeToBurn // V1
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

    // View function to see pending Reward for token A on frontend. // V1_5
    function pendingRewardTA(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTAPerShare = pool.accRewardTAPerShare; // V1_5
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenAReward = multiplier.mul(rewardPerBlockTA).mul(pool.allocPointTokenA).div(totalAllocPoint); // V1_5
            accRewardTAPerShare = accRewardTAPerShare.add(tokenAReward.mul(1e12).div(lpSupply)); // V1_5
        }
        return user.amount.mul(accRewardTAPerShare).div(1e12).sub(user.rewardDebtTA);
    }

    // View function to see pending Reward for token A on frontend. // V1_5
    function pendingRewardTB(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTBPerShare = pool.accRewardTBPerShare; // V1_5
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenBReward = multiplier.mul(rewardPerBlockTB).mul(pool.allocPointTokenB).div(totalAllocPoint); // V1_5
            accRewardTBPerShare = accRewardTBPerShare.add(tokenBReward.mul(1e12).div(lpSupply)); // V1_5
        }
        return user.amount.mul(accRewardTBPerShare).div(1e12).sub(user.rewardDebtTB);
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
        
        uint256 tokenAReward = multiplier.mul(rewardPerBlockTA).mul(pool.allocPointTokenA).div(totalAllocPoint); // V1_5
        pool.accRewardTAPerShare = pool.accRewardTAPerShare.add(tokenAReward.mul(1e12).div(lpSupply)); // V1_5        
        uint256 tokenBReward = multiplier.mul(rewardPerBlockTB).mul(pool.allocPointTokenB).div(totalAllocPoint); // V1_5
        pool.accRewardTBPerShare = pool.accRewardTBPerShare.add(tokenBReward.mul(1e12).div(lpSupply)); // V1_5          

        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Stake NALIS tokens to TheBushV1
    function deposit(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        updatePool(0);
        if (user.amount > 0) {
            // V1_5
            uint256 pendingTA = user.amount.mul(pool.accRewardTAPerShare).div(1e12).sub(user.rewardDebtTA);
            if(pendingTA > 0) {
                rewardTokenA.safeTransfer(address(msg.sender), pendingTA);
            }
            // V1_5
            uint256 pendingTB = user.amount.mul(pool.accRewardTBPerShare).div(1e12).sub(user.rewardDebtTB);
            if(pendingTA > 0) {
                rewardTokenB.safeTransfer(address(msg.sender), pendingTB);
            }            
        }
        // V0
        //if(_amount > 0) {
        //    pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        //    user.amount = user.amount.add(_amount);
        //}
        // V1 Add the possibility of deposit fees sent to burn address
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(burnAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }        
        
        
        user.rewardDebtTA = user.amount.mul(pool.accRewardTAPerShare).div(1e12);
        user.rewardDebtTB = user.amount.mul(pool.accRewardTBPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw NALIS tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        // V1_5
        uint256 pendingTA = user.amount.mul(pool.accRewardTAPerShare).div(1e12).sub(user.rewardDebtTA);
        if(pendingTA > 0) {
            rewardTokenA.safeTransfer(address(msg.sender), pendingTA);
        }
        // V1_5
        uint256 pendingTB = user.amount.mul(pool.accRewardTBPerShare).div(1e12).sub(user.rewardDebtTB);
        if(pendingTA > 0) {
            rewardTokenB.safeTransfer(address(msg.sender), pendingTB);
        }  
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebtTA = user.amount.mul(pool.accRewardTAPerShare).div(1e12);
        user.rewardDebtTB = user.amount.mul(pool.accRewardTBPerShare).div(1e12);

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

    // Withdraw reward token A. EMERGENCY ONLY. V1_5
    function emergencyRewardWithdrawTA(uint256 _amount) public onlyOwner {
        require(_amount < rewardTokenA.balanceOf(address(this)), 'not enough token');
        rewardTokenA.safeTransfer(address(msg.sender), _amount);
    }
    
    // Withdraw reward token A. EMERGENCY ONLY. V1_5
    function emergencyRewardWithdrawTB(uint256 _amount) public onlyOwner {
        require(_amount < rewardTokenB.balanceOf(address(this)), 'not enough token');
        rewardTokenB.safeTransfer(address(msg.sender), _amount);
    }    
    
    // V1 Add a function to update rewardPerBlock. Can only be called by the owner.
    function updateRewardPerBlockTA(uint256 _rewardPerBlockTA) public onlyOwner {
        rewardPerBlockTA = _rewardPerBlockTA; // V1_5
        //Automatically updatePool 0
        updatePool(0);        
    } 
    
    // V1 Add a function to update rewardPerBlock. Can only be called by the owner.
    function updateRewardPerBlockTB(uint256 _rewardPerBlockTB) public onlyOwner {
        rewardPerBlockTB = _rewardPerBlockTB; // V1_5
        //Automatically updatePool 0
        updatePool(0);        
    }     
    
    // V1 Add a function to update bonusEndBlock. Can only be called by the owner.
    function updateBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        bonusEndBlock = _bonusEndBlock;
    }   
    
    // V1 Update the given pool's deposit fee. Can only be called by the owner.
    function updateDepositFeeBP(uint256 _pid, uint16 _depositFeeBP) public onlyOwner {
        require(_depositFeeBP <= 10000, "updateDepositFeeBP: invalid deposit fee basis points");
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        depositFeeToBurn = _depositFeeBP;
    }    

}