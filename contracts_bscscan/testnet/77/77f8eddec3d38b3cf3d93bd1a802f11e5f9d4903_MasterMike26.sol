// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

/*
 * 1Tronicswap Main Staking 
 */
import './SafeMath.sol';
import './IBEP20.sol';
import './SafeBEP20.sol';
import './Ownable.sol';
import './e1TronicSwap.sol';
import './ReentrancyGuard.sol';







// import "@nomiclabs/buidler/console.sol";

// MasterMike26 is the master of e1trc 
// He can make e1trc and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once e1trc is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.

contract MasterMike26 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of e1trcs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.acce1trcPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `acce1trcPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. e1trcs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that e1trcs distribution occurs.
        uint256 acce1trcPerShare; // Accumulated e1trcs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 totalLp;            // Total Token in Pool
    }

    // The e1TronicSwapToken TOKEN!
    e1TronicSwapToken public e1TRC;

    //On Distribution Dev address.
    address public devaddr;
    // Deposit Fee address
    address public feeAddress;
    //On Distribution Marketing Address
    address public marktAddress;
    //On Distribution Staff team Address
    address public staffAddress; 
    // e1trc tokens created per block.
    uint256 public e1trcPerBlock;
    // Bonus muliplier for early e1trc makers.
    uint256 public BONUS_MULTIPLIER = 1;

    
    // 10% for Marketing on distribution
    uint16 public constant blockMktFee = 1000;

    // 4% for staff on distribution
    uint16 public constant blockStaffFee = 400;

    // 1% for development on distribution
    uint16 public constant blockDevFee = 100;

    uint256 currentDevFee = 0;
    uint256 currentStaffFee = 0;
    uint256 currentMarketingFee = 0;


    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when e1trc mining starts.
    uint256 public startBlock;
    // Total e1trc in e1trc Pools (can be multiple pools)
    uint256 public totale1trcInPools = 0;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);

    constructor(
        e1TronicSwapToken _e1trc,
        address _devaddr,
        address _feeAddress,
        address _marktAddress,
        address _staffAddress,
        uint256 _e1trcPerBlock,
        uint256 _startBlock,
        uint256 _multiplier

    ) public {
        e1TRC = _e1trc;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        marktAddress = _marktAddress;
        staffAddress = _staffAddress;
        e1trcPerBlock = _e1trcPerBlock;
        startBlock = _startBlock;
        BONUS_MULTIPLIER = _multiplier;

        totalAllocPoint = 0;

    }

    modifier validatePool(uint256 _pid) {
        require(_pid < poolInfo.length, "validatePool: pool exists?");
        _;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Detects whether the given pool already exists
    function checkPoolDuplicate(IBEP20 _lpToken) public view {
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; _pid++) {
            require(poolInfo[_pid].lpToken != _lpToken, "add: existing pool");
        }
    }

    fallback() external payable {
        // custom function code
    }

    receive() external payable {
        // custom function code
    }


    //actual e1trc left in MasterMike26 can be used in rewards, must excluding all in e1trc pools
    //this function is for safety check 
    function remainRewards() public view returns (uint256) {
        return e1TRC.balanceOf(address(this)).sub(totale1trcInPools);
    }

    //All e1trcs that are not in pools or MasterMike26 reward stack
    function getCirculatingSupply() external view returns(uint256) {
        uint256 tSupply = e1TRC.totalSupply();
        uint256 e1trcBalance = e1TRC.balanceOf(address(this));

        return tSupply.sub(e1trcBalance);    
    }


     // Add a new lp to the pool. Can only be called by the owner.
    // Can add multiple pool with same lp token without messing up rewards, because each pool's balance is tracked using its own totalLp
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
       require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        acce1trcPerShare: 0,
        depositFeeBP: _depositFeeBP,
        totalLp : 0
        }));
    }

    // Update the given pool's e1trc allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
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

    // View function to see pending e1trcs on frontend.
    function pendinge1trc(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 acce1trcPerShare = pool.acce1trcPerShare;
        //uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 lpSupply = pool.totalLp;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 e1trcReward = multiplier.mul(e1trcPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            uint256 totalRewardFees = e1trcReward.mul(1500).div(10000);
            uint256 e1trcRewardUsers = e1trcReward.sub(totalRewardFees);

            uint256 totalminted = e1TRC.totalMinted();
             
        if(totalminted >= 159000000000000000000000000){
         
            acce1trcPerShare = acce1trcPerShare;

            }else{
                acce1trcPerShare = acce1trcPerShare.add(e1trcRewardUsers.mul(1e12).div(lpSupply));
            }

        }
  
         return user.amount.mul(acce1trcPerShare).div(1e12).sub(user.rewardDebt);

    }

        // View function to see all locked e1trcs on frontend.
        function lockede1trc() external view returns (uint256) {
            return totale1trcInPools;
        }

    // Update reward variables for all pools. Be careful of gas spending! 

    function massUpdatePools() public {
       
        uint256 length = poolInfo.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
         
    }
 
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
       
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.totalLp == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 e1trcReward = multiplier.mul(e1trcPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
    
        uint256 totalRewardFees = e1trcReward.mul(1500).div(10000);

        //Total - 15% fees
        uint256 e1trcRewardUsers = e1trcReward.sub(totalRewardFees);
       
        uint256 totalminted = e1TRC.totalMinted();
       
        if(totalminted >= 159000000000000000000000000){
         
            if(currentDevFee > 0 || currentStaffFee > 0 || currentMarketingFee > 0){

             safee1trcTransfer(devaddr,currentDevFee);
             safee1trcTransfer(staffAddress,currentStaffFee);
             safee1trcTransfer(marktAddress,currentMarketingFee);

            }
  
            pool.acce1trcPerShare = pool.acce1trcPerShare;

            currentDevFee = 0;
            currentMarketingFee = 0;
            currentStaffFee = 0;

        }else{
             
             e1TRC.mint(address(this),e1trcReward);

                if(currentDevFee > 1100000000000000000000){
                
                    safee1trcTransfer(devaddr,currentDevFee);
                    currentDevFee = 0;

                } else if(currentStaffFee > 1100000000000000000000){
                    
                    safee1trcTransfer(staffAddress,currentStaffFee);
                    currentStaffFee = 0;

                } else if(currentMarketingFee > 2000000000000000000000){
                    
                    safee1trcTransfer(marktAddress,currentMarketingFee);
                    currentMarketingFee = 0;

                }

             }

            //1% dev fee
            currentDevFee = currentDevFee.add(e1trcReward.mul(blockDevFee).div(10000));

            //4% staff fee
            currentStaffFee = currentStaffFee.add(e1trcReward.mul(blockStaffFee).div(10000));
            
            //10% marketing fee
            currentMarketingFee = currentMarketingFee.add(e1trcReward.div(10));
 
            pool.acce1trcPerShare = pool.acce1trcPerShare.add(e1trcRewardUsers.mul(1e12).div(pool.totalLp));
            pool.lastRewardBlock = block.number;

   }         
        

    // Deposit LP tokens to MasterMike26 for e1trc allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
       // require(block.number >= startBlock, "MasterMike26:: Can not deposit before farm start");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
       

        updatePool(_pid);      
        

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.acce1trcPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                uint256 currentRewardBalance = remainRewards();
                if(currentRewardBalance > 0) {
                    if(pending > currentRewardBalance) {
                        safee1trcTransfer(msg.sender, currentRewardBalance);
                    } else {
                        safee1trcTransfer(msg.sender, pending);
                    }
                }
            }
        }
        
        if (_amount > 0) {
            //Security Check in Tokens with Tax Fees
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));

            _amount = afterDeposit.sub(beforeDeposit);

            if (pool.depositFeeBP > 0) {

                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);

                if (address(pool.lpToken) == address(e1TRC)) {
                    totale1trcInPools = totale1trcInPools.add(_amount).sub(depositFee);   
                } 

                pool.lpToken.safeTransfer(feeAddress, depositFee);

                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.totalLp = pool.totalLp.add(_amount).sub(depositFee);

            } else {
                user.amount = user.amount.add(_amount);
                pool.totalLp = pool.totalLp.add(_amount);

                if (address(pool.lpToken) == address(e1TRC)) {
                    totale1trcInPools = totale1trcInPools.add(_amount);
                }
                                
           }
        }

        user.rewardDebt = user.amount.mul(pool.acce1trcPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterMike26.
    function withdraw(uint256 _pid, uint256 _amount) public validatePool(_pid) nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        //this will make sure that user can only withdraw from his pool
        //cannot withdraw more than pool's balance and from MasterMike26's token
        require(pool.totalLp >= _amount, "Withdraw: Pool total LP not enough");


        updatePool(_pid);      
        

        uint256 pending = user.amount.mul(pool.acce1trcPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                uint256 currentRewardBalance = remainRewards();
                //additional checkings
                if(currentRewardBalance > 0) {
                    if(pending > currentRewardBalance) {
                        safee1trcTransfer(msg.sender, currentRewardBalance);
                    } else {
                        safee1trcTransfer(msg.sender, pending);
                    }
                }
            }
            
        if(_amount > 0) {
                
             if (address(pool.lpToken) == address(e1TRC)) {
      
                 uint256 e1trcBal = e1TRC.balanceOf(address(this));

                 require(_amount <= e1trcBal,'withdraw: not good');    

                if(_amount >= totale1trcInPools){
                    totale1trcInPools = 0;
                }else{
                    require(totale1trcInPools >= _amount,'amount bigger than pool wut?');
                    totale1trcInPools = totale1trcInPools.sub(_amount);
                }  

                pool.lpToken.safeTransfer(address(msg.sender), _amount);
                
            } else {
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
            }
        }
        
        user.amount = user.amount.sub(_amount);
        pool.totalLp = pool.totalLp.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.acce1trcPerShare).div(1e12);
        
        emit Withdraw(msg.sender, _pid, _amount);

    }


    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        require(pool.totalLp >= amount, "EmergencyWithdraw: Pool total LP not enough");

        if (address(pool.lpToken) == address(e1TRC)) {
          
            uint256 e1trcBal = e1TRC.balanceOf(address(this));

            require(amount <= e1trcBal,'withdraw: not good'); 

            if(amount >= totale1trcInPools){
                totale1trcInPools = 0;
            }else{
                require(totale1trcInPools >= amount,'amount bigger than pool wut?');
                totale1trcInPools = totale1trcInPools.sub(amount);
            }  

            pool.lpToken.safeTransfer(address(msg.sender), amount);

        }else{ 
            pool.lpToken.safeTransfer(address(msg.sender), amount);
        }

        user.amount = 0;
        user.rewardDebt = 0;
        pool.totalLp = pool.totalLp.sub(amount);

        emit EmergencyWithdraw(msg.sender, _pid, amount);

    }

    function getPoolInfo(uint256 _pid) public view
    returns(address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 acce1trcPerShare, uint16 depositFeeBP, uint256 totalLp) {
        return (address(poolInfo[_pid].lpToken),
             poolInfo[_pid].allocPoint,
             poolInfo[_pid].lastRewardBlock,
             poolInfo[_pid].acce1trcPerShare,
             poolInfo[_pid].depositFeeBP,
             poolInfo[_pid].totalLp);
    }

    // Safe e1trc transfer function, just in case if rounding error causes pool to not have enough e1trcs.
    function safee1trcTransfer(address _to, uint256 _amount) internal {
        if(e1TRC.balanceOf(address(this)) > totale1trcInPools){
            //e1trcBal = total e1trc in MasterMike26 - total e1trc in e1trc pools, this will make sure that MasterMike26 never transfer rewards from deposited e1trc pools
            uint256 e1trcBal = e1TRC.balanceOf(address(this)).sub(totale1trcInPools);
            if (_amount >= e1trcBal) {
                e1TRC.transfer(_to, e1trcBal);
            } else if (_amount > 0) {
                e1TRC.transfer(_to, _amount);
            }
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

     //update address that receive deposit fee in pools
     function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _e1trcPerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, e1trcPerBlock, _e1trcPerBlock);
        e1trcPerBlock = _e1trcPerBlock;
    }

}