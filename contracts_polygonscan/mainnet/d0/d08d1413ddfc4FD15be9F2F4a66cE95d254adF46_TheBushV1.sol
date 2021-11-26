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

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract TheBushV1 is Ownable {
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
        uint256 allocPoint;       // How many allocation points assigned to this pool. NALISs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that NALISs distribution occurs.
        uint256 accNalisPerShare; // Accumulated NALISs per share, times 1e12. See below.
        uint16 depositFeeBP;      // V1 Deposit fee in basis points
    }

    // The NALIS TOKEN!
    IBEP20 public nalis;
    IBEP20 public rewardToken;

    // NALIS tokens created per block.
    uint256 public rewardPerBlock;
    
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
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        address _burnAddress, // V1
        uint16 _depositFeeBP, // V1
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        nalis = _nalis;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        burnAddress = _burnAddress; // V1
        depositFeeToBurn = _depositFeeBP; // V1
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // V1 / Deposit fee limited to 10% No way for contract owner to set higher deposit fee
        require(depositFeeToBurn <= 1000, "contract: invalid deposit fee basis points");

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _nalis,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accNalisPerShare: 0,
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

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accNalisPerShare = pool.accNalisPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 nalisReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accNalisPerShare = accNalisPerShare.add(nalisReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accNalisPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 nalisReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accNalisPerShare = pool.accNalisPerShare.add(nalisReward.mul(1e12).div(lpSupply));
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
            uint256 pending = user.amount.mul(pool.accNalisPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        // V0
        //if(_amount > 0) {
        //    pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        //    user.amount = user.amount.add(_amount);
        //}
        // V1 Add the possibility of deposit fees sent to burn address
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
        
        
        user.rewardDebt = user.amount.mul(pool.accNalisPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw NALIS tokens from STAKING.
    function withdraw(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accNalisPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNalisPerShare).div(1e12);

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
    
    // V1 Add a function to update rewardPerBlock. Can only be called by the owner.
    function updateRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        rewardPerBlock = _rewardPerBlock;
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
    
    // Add a function to update startBlock. Can only be called by the owner.
    function updateStartBlock(uint256 _startBlock) public onlyOwner {
        //Can only be updated if the original startBlock is not minted
        require(block.number <= poolInfo[0].lastRewardBlock, "updateStartBlock: startblock already minted");
        poolInfo[0].lastRewardBlock = _startBlock;
        startBlock = _startBlock;
    }     

}