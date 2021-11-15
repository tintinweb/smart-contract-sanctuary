// SPDX-License-Identifier: MIT

// Dirty.Finance Staking Contract Version 1.0
// Stake your $dirty or LP tokens to receive Dirtycash rewards (XXXCASH)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./dirtycash.sol";

interface IDirtyNFT {
  function mint(address to, uint256 id) external;
  function getCreatorAddress(uint256 _nftid) external view returns (address);
  function getCreatorPrice(uint256 _nftid) external view returns (uint256);
  function getCreatorSplit(uint256 _nftid) external view returns (uint256);
  function getCreatorMintLimit(uint256 _nftid) external view returns (uint256);
  function getCreatorRedeemable(uint256 _nftid) external view returns (bool);
  function getCreatorPurchasable(uint256 _nftid) external view returns (bool);
  function getCreatorExists(uint256 _nftid) external view returns (bool);
  function mintedCountbyID(uint256 _id) external view returns (uint256);
}

// Allows another user(s) to change contract variables
contract Authorizable is Ownable {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[_msgSender()] || owner() == address(_msgSender()), "Sender is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        require(_toAdd != address(0), "Address is the zero address");
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != address(0), "Address is the zero address");
        require(_toRemove != address(_msgSender()), "Sender cannot remove themself");
        authorized[_toRemove] = false;
    }

}

contract DirtyFarm is Ownable, Authorizable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DIRTYCASH tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDirtyPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDirtyPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. DIRTYCASH tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that DIRTYCASH tokens distribution occurs.
        uint256 accDirtyPerShare; // Accumulated DIRTYCASH tokens per share, times 1e12. See below.
        uint256 runningTotal; // Total accumulation of tokens (not including reflection, pertains to pool 1 ($Dirty))
    }

    DirtyCash public immutable dirtycash; // The DIRTYCASH ERC-20 Token.
    uint256 private dirtyPerBlock; // DIRTYCASH tokens distributed per block. Use getDirtyPerBlock() to get the updated reward.

    PoolInfo[] public poolInfo; // Info of each pool.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens.
    
    uint256 public totalAllocPoint; // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public startBlock; // The block number when DIRTYCASH token mining starts.

    uint256 public blockRewardUpdateCycle = 1 days; // The cycle in which the dirtyPerBlock gets updated.
    uint256 public blockRewardLastUpdateTime = block.timestamp; // The timestamp when the block dirtyPerBlock was last updated.
    uint256 public blocksPerDay = 5000; // The estimated number of mined blocks per day, lowered so rewards are halved to start.
    uint256 public blockRewardPercentage = 10; // The percentage used for dirtyPerBlock calculation.
    uint256 public unstakeTime = 60; // Time in seconds to wait for withdrawal default (86400).
    uint256 public poolReward = 1000000000000000000000; //starting basis for poolReward (default 1k).
    uint256 public conversionRate = 100000; //conversion rate of DIRTYCASH => $dirty (default 100k).
    bool public enableRewardWithdraw = false; //whether DIRTYCASH is withdrawable from this contract (default false).
    uint256 public minDirtyStake = 21000000000000000000000000; //min stake amount (default 21 million Dirty).
    uint256 public maxDirtyStake = 2100000000000000000000000000; //max stake amount (default 2.1 billion Dirty).
    uint256 public minLPStake = 1000000000000000000000; //min lp stake amount (default 1000 LP tokens).
    uint256 public maxLPStake = 10000000000000000000000; //max lp stake amount (default 10,000 LP tokens).
    uint256 public promoAmount = 200000000000000000000; //amount of DIRTYCASH to give to new stakers (default 200 DIRTYCASH).
    bool public promoActive = true; //whether the promotional amount of DIRTYCASH is given out to new stakers (default is True).
    uint256 public rewardSegment = poolReward.mul(100).div(200); //reward segment for dynamic staking.
    uint256 public ratio; //ratio of pool0 to pool1 for dynamic staking.
    uint256 public lpalloc = 60; //starting pool allocation for LP side.
    uint256 public stakealloc = 40; //starting pool allocation for Dirty side.
    uint256 public allocMultiplier = 5; //ratio * allocMultiplier to balance out the pools.
    bool public dynamicStakingActive = true; //whether the staking pool will auto-balance rewards or not.

    mapping(address => bool) public addedLpTokens; // Used for preventing LP tokens from being added twice in add().
    mapping(uint256 => mapping(address => uint256)) public unstakeTimer; // Used to track time since unstake requested.
    mapping(address => uint256) private userBalance; // Balance of DirtyCash for each user that survives staking/unstaking/redeeming.
    mapping(address => bool) private promoWallet; // Whether the wallet has received promotional DIRTYCASH.
    mapping(uint256 => uint256) public totalEarnedCreator; // Total amount of $dirty token spent to creator on a particular NFT.
    mapping(uint256 => uint256) public totalEarnedPool; // Total amount of $dirty token spent to pool on a particular NFT.
    mapping(uint256 => uint256) public totalEarnedBurn; // Total amount of $dirty token spent to burn on a particular NFT.
    mapping(uint256 =>mapping(address => bool)) public userStaked; // Denotes whether the user is currently staked or not.
    
    address public NFTAddress; //NFT contract address
    address public DirtyCashAddress; //DIRTYCASH contract address

    IERC20 dirtytoken = IERC20(0x62EcF49636F282313cda51E2e3cbF0E258e65356); //dirty token

    event Unstake(address indexed user, uint256 indexed pid);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    //event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawRewardsOnly(address indexed user, uint256 amount);

    constructor(
        DirtyCash _dirty,
        uint256 _startBlock
    ) {
        require(address(_dirty) != address(0), "DIRTYCASH address is invalid");
        //require(_startBlock >= block.number, "startBlock is before current block");

        dirtycash = _dirty;
        DirtyCashAddress = address(_dirty);
        startBlock = _startBlock;
    }

    modifier updateDirtyPerBlock() {
        (uint256 blockReward, bool update) = getDirtyPerBlock();
        if (update) {
            dirtyPerBlock = blockReward;
            blockRewardLastUpdateTime = block.timestamp;
        }
        _;
    }

    function getDirtyPerBlock() public view returns (uint256, bool) {
        if (block.number < startBlock) {
            return (0, false);
        }

        if (block.timestamp >= getDirtyPerBlockUpdateTime() || dirtyPerBlock == 0) {
            return (poolReward.mul(blockRewardPercentage).div(100).div(blocksPerDay), true);
        }

        return (dirtyPerBlock, false);
    }

    function getDirtyPerBlockUpdateTime() public view returns (uint256) {
        // if blockRewardUpdateCycle = 1 day then roundedUpdateTime = today's UTC midnight
        uint256 roundedUpdateTime = blockRewardLastUpdateTime - (blockRewardLastUpdateTime % blockRewardUpdateCycle);
        // if blockRewardUpdateCycle = 1 day then calculateRewardTime = tomorrow's UTC midnight
        uint256 calculateRewardTime = roundedUpdateTime + blockRewardUpdateCycle;
        return calculateRewardTime;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        require(address(_lpToken) != address(0), "LP token is invalid");
        require(!addedLpTokens[address(_lpToken)], "LP token is already added");

        require(_allocPoint >= 1 && _allocPoint <= 100, "_allocPoint is outside of range 1-100");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accDirtyPerShare : 0,
            runningTotal : 0 
        }));

        addedLpTokens[address(_lpToken)] = true;
    }

    // Update the given pool's DIRTYCASH token allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyAuthorized {
        require(_allocPoint >= 1 && _allocPoint <= 100, "_allocPoint is outside of range 1-100");

        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update the given pool's DIRTYCASH token allocation point when pool.
    function adjustPools(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) internal {
        require(_allocPoint >= 1 && _allocPoint <= 100, "_allocPoint is outside of range 1-100");

        if (_withUpdate) {
            updatePool(_pid);
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // View function to see pending DIRTYCASH tokens on frontend.
    function pendingRewards(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDirtyPerShare = pool.accDirtyPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = block.number.sub(pool.lastRewardBlock);
            (uint256 blockReward, ) = getDirtyPerBlock();
            uint256 dirtyReward = multiplier.mul(blockReward).mul(pool.allocPoint).div(totalAllocPoint);
            accDirtyPerShare = accDirtyPerShare.add(dirtyReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accDirtyPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public onlyAuthorized {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date when lpSupply changes
    // For every deposit/withdraw pool recalculates accumulated token value
    function updatePool(uint256 _pid) public updateDirtyPerBlock {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.runningTotal; //pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number.sub(pool.lastRewardBlock);
        uint256 dirtyReward = multiplier.mul(dirtyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        // no minting is required, the contract should have DIRTYCASH token balance pre-allocated
        // accumulated DIRTYCASH per share is stored multiplied by 10^12 to allow small 'fractional' values
        pool.accDirtyPerShare = pool.accDirtyPerShare.add(dirtyReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function updatePoolReward(uint256 _amount) public onlyAuthorized {
        poolReward = _amount;
    }

    // Deposit LP tokens/$Dirty to DirtyFarming for DIRTYCASH token allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        updatePool(_pid);

        if (_amount > 0) {

            if(user.amount > 0) { //if user has already deposited, secure rewards before reconfiguring rewardDebt
                uint256 tempRewards = pendingRewards(_pid, _msgSender());
                userBalance[_msgSender()] = userBalance[_msgSender()].add(tempRewards);
            }
            
            if (_pid != 0) { //$Dirty tokens
                if(user.amount == 0) { //we only want the minimum to apply on first deposit, not subsequent ones
                require(_amount >= minDirtyStake, "You cannot stake less than the minimum required $Dirty");
                }
                require(_amount.add(user.amount) <= maxDirtyStake, "You cannot stake more than the maximum $Dirty");
                pool.runningTotal = pool.runningTotal.add(_amount);
                user.amount = user.amount.add(_amount);  
                pool.lpToken.safeTransferFrom(address(_msgSender()), address(this), _amount);
                //function to update all totals here

                
            } else { //LP tokens
                if(user.amount == 0) { //we only want the minimum to apply on first deposit, not subsequent ones
                require(_amount >= minLPStake, "You cannot stake less than the minimum LP Tokens");
                }
                require(_amount.add(user.amount) <= maxLPStake, "You cannot stake more than the maximum LP Tokens");
                pool.runningTotal = pool.runningTotal.add(_amount);
                user.amount = user.amount.add(_amount);
                pool.lpToken.safeTransferFrom(address(_msgSender()), address(this), _amount);
            }
            
        
            unstakeTimer[_pid][_msgSender()] = 9999999999;
            userStaked[_pid][_msgSender()] = true;

            if (!promoWallet[_msgSender()] && promoActive) {
                userBalance[_msgSender()] = promoAmount; //give 200 promo DIRTYCASH
                promoWallet[_msgSender()] = true;
            }

            if (dynamicStakingActive) {
                updateVariablePoolReward();
            }
            
            user.rewardDebt = user.amount.mul(pool.accDirtyPerShare).div(1e12);
            emit Deposit(_msgSender(), _pid, _amount);

        }
    }

    function setUnstakeTime(uint256 _time) external onlyAuthorized {

        require(_time >= 0 || _time <= 172800, "Time should be between 0 and 2 days (in seconds)");
        unstakeTime = _time;
    }

    //Call unstake to start countdown
    function unstake(uint256 _pid) public {
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(user.amount > 0, "You have no amount to unstake");

        unstakeTimer[_pid][_msgSender()] = block.timestamp.add(unstakeTime);
        userStaked[_pid][_msgSender()] = false;
        

    }

    //Get time remaining until able to withdraw tokens
    function timeToUnstake(uint256 _pid, address _user) external view returns (uint256)  {

        if (unstakeTimer[_pid][_user] > block.timestamp) {
            return unstakeTimer[_pid][_user].sub(block.timestamp);
        } else {
            return 0;
        }
    }


    // Withdraw LP tokens from DirtyFarming
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        uint256 userAmount = user.amount;
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(user.amount >= _amount, "Withdraw amount is greater than user amount");
        require(block.timestamp > unstakeTimer[_pid][_msgSender()], "Unstaking wait period has not expired");

        updatePool(_pid);

        if (_amount > 0) {

            if (_pid != 0) { //$Dirty tokens
                
                uint256 lpSupply = pool.lpToken.balanceOf(address(this)); //get total amount of tokens
                uint256 totalRewards = lpSupply.sub(pool.runningTotal); //get difference between contract address amount and ledger amount
                if (totalRewards == 0) { //no rewards, just return 100% to the user

                    uint256 tempRewards = pendingRewards(_pid, _msgSender());
                    userBalance[_msgSender()] = userBalance[_msgSender()].add(tempRewards);

                    pool.runningTotal = pool.runningTotal.sub(_amount);
                    pool.lpToken.safeTransfer(address(_msgSender()), _amount);
                    user.amount = user.amount.sub(_amount);
                    emit Withdraw(_msgSender(), _pid, _amount);
                    
                } 
                if (totalRewards > 0) { //include reflection

                    uint256 tempRewards = pendingRewards(_pid, _msgSender());
                    userBalance[_msgSender()] = userBalance[_msgSender()].add(tempRewards);

                    uint256 percentRewards = _amount.mul(100).div(pool.runningTotal); //get % of share out of 100
                    uint256 reflectAmount = percentRewards.mul(totalRewards).div(100); //get % of reflect amount

                    pool.runningTotal = pool.runningTotal.sub(_amount);
                    user.amount = user.amount.sub(_amount);
                    _amount = _amount.mul(99).div(100).add(reflectAmount);
                    pool.lpToken.safeTransfer(address(_msgSender()), _amount);
                    emit Withdraw(_msgSender(), _pid, _amount);
                }               

            } else {


                uint256 tempRewards = pendingRewards(_pid, _msgSender());
                
                userBalance[_msgSender()] = userBalance[_msgSender()].add(tempRewards);
                user.amount = user.amount.sub(_amount);
                pool.runningTotal = pool.runningTotal.sub(_amount);
                pool.lpToken.safeTransfer(address(_msgSender()), _amount);
                emit Withdraw(_msgSender(), _pid, _amount);
            }
            

            if (dynamicStakingActive) {
                    updateVariablePoolReward();
            }

            if (userAmount == _amount) { //user is retrieving entire balance, set rewardDebt to zero
                user.rewardDebt = 0;
            } else {
                user.rewardDebt = user.amount.mul(pool.accDirtyPerShare).div(1e12); 
            }

        }
        
                        
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    /*function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        pool.lpToken.safeTransfer(address(_msgSender()), _amount);
        emit EmergencyWithdraw(_msgSender(), _pid, _amount);

        
    }*/

    // Safe DIRTYCASH token transfer function, just in case if
    // rounding error causes pool to not have enough DIRTYCASH tokens
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 balance = dirtycash.balanceOf(address(this));
        uint256 amount = _amount > balance ? balance : _amount;
        dirtycash.transfer(_to, amount);
    }

    function setBlockRewardUpdateCycle(uint256 _blockRewardUpdateCycle) external onlyAuthorized {
        require(_blockRewardUpdateCycle > 0, "Value is zero");
        blockRewardUpdateCycle = _blockRewardUpdateCycle;
    }

    // Just in case an adjustment is needed since mined blocks per day
    // changes constantly depending on the network
    function setBlocksPerDay(uint256 _blocksPerDay) external onlyAuthorized {
        require(_blocksPerDay >= 1 && _blocksPerDay <= 14000, "Value is outside of range 1-14000");
        blocksPerDay = _blocksPerDay;
    }

    function setBlockRewardPercentage(uint256 _blockRewardPercentage) external onlyAuthorized {
        require(_blockRewardPercentage >= 1 && _blockRewardPercentage <= 5, "Value is outside of range 1-5");
        blockRewardPercentage = _blockRewardPercentage;
    }

    // This will allow to rescue ETH sent by mistake directly to the contract
    function rescueETHFromContract() external onlyAuthorized {
        address payable _owner = payable(_msgSender());
        _owner.transfer(address(this).balance);
    }

    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyAuthorized {
       /* require(_tokenAddr != address(this), "Cannot transfer out native token");
        require(_tokenAddr != address(0x63B75801aa9776A0340f65af6654eC53167f0778), "Cannot transfer out LP token");
        require(_tokenAddr != address(0x62EcF49636F282313cda51E2e3cbF0E258e65356), "Cannot transfer out $Dirty token");*/
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    //returns total stake amount (LP, Dirty token) and address of that token respectively
    function getTotalStake(uint256 _pid, address _user) external view returns (uint256, IERC20) { 
         PoolInfo storage pool = poolInfo[_pid];
         UserInfo storage user = userInfo[_pid][_user];

        return (user.amount, pool.lpToken);
    }

    //gets the full ledger of deposits into each pool
    function getRunningDepositTotal(uint256 _pid) external view returns (uint256) { 
         PoolInfo storage pool = poolInfo[_pid];

        return (pool.runningTotal);
    }

    //gets the total of all pending rewards from each pool
    function getTotalPendingRewards(address _user) public view returns (uint256) { 
        uint256 value1 = pendingRewards(0, _user);
        uint256 value2 = pendingRewards(1, _user);

        return value1.add(value2);
    }

    //gets the total amount of rewards secured (not pending)
    function getAccruedRewards(address _user) external view returns (uint256) { 
        return userBalance[_user];
    }

    //gets the total of pending + secured rewards
    function getTotalRewards(address _user) external view returns (uint256) { 
        uint256 value1 = getTotalPendingRewards(_user);
        uint256 value2 = userBalance[_user];

        return value1.add(value2);
    }

    //moves all pending rewards into the accrued array
    function redeemTotalRewards(address _user) internal { 

        uint256 pool0 = 0;

        PoolInfo storage pool = poolInfo[pool0];
        UserInfo storage user = userInfo[pool0][_user];

        updatePool(pool0);
        
        uint256 value0 = pendingRewards(pool0, _user);
        
        userBalance[_user] = userBalance[_user].add(value0);

        user.rewardDebt = user.amount.mul(pool.accDirtyPerShare).div(1e12); 

        uint256 pool1 = 1; 
        
        pool = poolInfo[pool1];
        user = userInfo[pool1][_user];

        updatePool(pool1);

        uint256 value1 = pendingRewards(pool1, _user);
        
        userBalance[_user] = userBalance[_user].add(value1);

        user.rewardDebt = user.amount.mul(pool.accDirtyPerShare).div(1e12); 
    }

    //whether to allow the DirtyCash token to actually be withdrawn, of just leave it virtual (default)
    function enableRewardWithdrawals(bool _status) public onlyAuthorized {
        enableRewardWithdraw = _status;
    }

    //view state of reward withdrawals (true/false)
    function rewardWithdrawalStatus() external view returns (bool) {
        return enableRewardWithdraw;
    }

    //withdraw DirtyCash
    function withdrawRewardsOnly() public nonReentrant {

        require(enableRewardWithdraw, "DIRTYCASH withdrawals are not enabled");

        IERC20 rewardtoken = IERC20(DirtyCashAddress); //DIRTYCASH

        redeemTotalRewards(_msgSender());

        uint256 pending = userBalance[_msgSender()];
        if (pending > 0) {
            require(rewardtoken.balanceOf(address(this)) > pending, "DIRTYCASH token balance of this contract is insufficient");
            userBalance[_msgSender()] = 0;
            safeTokenTransfer(_msgSender(), pending);
        }
        
        emit WithdrawRewardsOnly(_msgSender(), pending);
    }

    // Set NFT contract address
     function setNFTAddress(address _address) external onlyAuthorized {
        NFTAddress = _address;
    }

    // Set DIRTYCASH contract address
     function setDirtyCashAddress(address _address) external onlyAuthorized {
        DirtyCashAddress = _address;
    }

    //redeem the NFT with DIRTYCASH only
    function redeem(uint256 _nftid) public nonReentrant {
    
        uint256 creatorPrice = IDirtyNFT(NFTAddress).getCreatorPrice(_nftid);
        bool creatorRedeemable = IDirtyNFT(NFTAddress).getCreatorRedeemable(_nftid);
        uint256 creatorMinted = IDirtyNFT(NFTAddress).mintedCountbyID(_nftid);
        uint256 creatorMintLimit = IDirtyNFT(NFTAddress).getCreatorMintLimit(_nftid);
    
        require(creatorRedeemable, "This NFT is not redeemable with DirtyCash");
        require(creatorMinted < creatorMintLimit, "This NFT has reached its mint limit");

        uint256 price = creatorPrice;

        require(price > 0, "NFT not found");

        redeemTotalRewards(_msgSender());

        if (userBalance[_msgSender()] < price) {
            
            IERC20 rewardtoken = IERC20(0xB02658F05315A7bE78486A53ca618c1bBBFeC61a); //DIRTYCASH
            require(rewardtoken.balanceOf(_msgSender()) >= price, "You do not have the required tokens for purchase"); 
            IDirtyNFT(NFTAddress).mint(_msgSender(), _nftid);
            IERC20(rewardtoken).transferFrom(_msgSender(), address(this), price);

        } else {

            require(userBalance[_msgSender()] >= price, "Not enough DirtyCash to redeem");
            IDirtyNFT(NFTAddress).mint(_msgSender(), _nftid);
            userBalance[_msgSender()] = userBalance[_msgSender()].sub(price);

        }

    }

    //set the conversion rate between DIRTYCASH and the $dirty token
    function setConverstionRate(uint256 _rate) public onlyAuthorized {
        conversionRate = _rate;
    }

    // users can also purchase the NFT with $dirty token and the proceeds can be split between the NFT influencer/artist and the staking pool
    function purchase(uint256 _nftid) public nonReentrant {
        
        address creatorAddress = IDirtyNFT(NFTAddress).getCreatorAddress(_nftid);
        uint256 creatorPrice = IDirtyNFT(NFTAddress).getCreatorPrice(_nftid);
        uint256 creatorSplit = IDirtyNFT(NFTAddress).getCreatorSplit(_nftid);
        uint256 creatorMinted = IDirtyNFT(NFTAddress).mintedCountbyID(_nftid);
        uint256 creatorMintLimit = IDirtyNFT(NFTAddress).getCreatorMintLimit(_nftid);
        bool creatorPurchasable = IDirtyNFT(NFTAddress).getCreatorPurchasable(_nftid);
        bool creatorExists = IDirtyNFT(NFTAddress).getCreatorExists(_nftid);

        uint256 price = creatorPrice;
        price = price.mul(conversionRate);

        require(creatorPurchasable, "This NFT is not purchasable with Dirty tokens");
        require(creatorMinted < creatorMintLimit, "This NFT has reached its mint limit");
        require(dirtytoken.balanceOf(_msgSender()) >= price, "You do not have the required tokens for purchase"); 
        IDirtyNFT(NFTAddress).mint(_msgSender(), _nftid);

        distributeDirty(_nftid, creatorAddress, price, creatorSplit, creatorExists);

        
    }

    function distributeDirty(uint256 _nftid, address _creator, uint256 _price, uint256 _creatorSplit, bool _creatorExists) internal {
        if (_creatorExists) { 
            uint256 creatorShare;
            uint256 remainingShare;
            uint256 burnShare;
            uint256 poolShare;
            creatorShare = _price.mul(_creatorSplit).div(100);
            remainingShare = _price.sub(creatorShare);           

            IERC20(dirtytoken).transferFrom(_msgSender(), address(this), _price);

            if (creatorShare > 0) {

                totalEarnedCreator[_nftid] = totalEarnedCreator[_nftid].add(creatorShare);
                IERC20(dirtytoken).safeTransfer(address(_creator), creatorShare);                
                
            }

            if (remainingShare > 0) {
                burnShare = remainingShare.mul(50).div(100);
                poolShare = remainingShare.mul(50).div(100);

                totalEarnedPool[_nftid] = totalEarnedPool[_nftid].add(poolShare);
                IERC20(dirtytoken).safeTransfer(address(0x000000000000000000000000000000000000dEaD), burnShare);
                totalEarnedBurn[_nftid] = totalEarnedBurn[_nftid].add(burnShare);
            }

        } else {
            IERC20(dirtytoken).transferFrom(_msgSender(), address(this), _price.mul(50).div(100));
            totalEarnedPool[_nftid] = totalEarnedPool[_nftid].add(_price.mul(50).div(100));

            IERC20(dirtytoken).transferFrom(_msgSender(), address(0x000000000000000000000000000000000000dEaD), _price.mul(50).div(100));
            totalEarnedBurn[_nftid] = totalEarnedBurn[_nftid].add(_price.mul(50).div(100));
        }
    }

    // We can give the artists/influencers a DirtyCash balance so they can redeem their own NFTs
    function setDirtyCashBalance(address _address, uint256 _amount) public onlyAuthorized {
        userBalance[_address] = _amount;
    }

    function reduceDirtyCashBalance(address _address, uint256 _amount) public onlyAuthorized {
        userBalance[_address] = userBalance[_address].sub(_amount);
    }

    function increaseDirtyCashBalance(address _address, uint256 _amount) public onlyAuthorized {
        userBalance[_address] = userBalance[_address].add(_amount);
    }

    // Get rate of DirtyCash/$Dirty conversion
    function getConversionRate() external view returns (uint256) {
        return conversionRate;
    }

    // Get price of NFT in $dirty based on DirtyCash _price
    function getConversionPrice(uint256 _price) external view returns (uint256) {
        uint256 newprice = _price.mul(conversionRate);
        return newprice;
    }

    // Get price of NFT in $dirty based on NFT
    function getConversionNFTPrice(uint256 _nftid) external view returns (uint256) {
        uint256 nftprice = IDirtyNFT(NFTAddress).getCreatorPrice(_nftid);
        uint256 newprice = nftprice.mul(conversionRate);
        return newprice;
    }

    // Get the holder rewards of users staked $dirty if they were to withdraw
    function getHolderRewards(address _address) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[1];
        UserInfo storage user = userInfo[1][_address];

        uint256 _amount = user.amount;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this)); //get total amount of tokens
        uint256 totalRewards = lpSupply.sub(pool.runningTotal); //get difference between contract address amount and ledger amount
        
         if (totalRewards > 0) { //include reflection
            uint256 percentRewards = _amount.mul(100).div(pool.runningTotal); //get % of share out of 100
            uint256 reflectAmount = percentRewards.mul(totalRewards).div(100); //get % of reflect amount

            return _amount.add(reflectAmount); //add pool rewards to users original staked amount

         } else {

             return 0;

         }

    }

    // Sets min/max staking amounts for Dirty token
    function setDirtyStakingMinMax(uint256 _min, uint256 _max) external onlyAuthorized {

        require(_min < _max, "The maximum staking amount is less than the minimum");
        require(_min > 0, "The minimum amount cannot be zero");

        minDirtyStake = _min;
        maxDirtyStake = _max;
    }

    // Sets min/max amounts for LP staking
    function setLPStakingMinMax(uint256 _min, uint256 _max) external onlyAuthorized {

        require(_min < _max, "The maximum staking amount is less than the minimum");
        require(_min > 0, "The minimum amount cannot be zero");

        minLPStake = _min;
        maxLPStake = _max;
    }

    // Lets user move their pending rewards to accrued/escrow balance
    function moveRewardsToEscrow(address _address) external {

        require(_address == _msgSender() || authorized[_msgSender()], "Sender is not wallet owner or authorized");

        UserInfo storage user0 = userInfo[0][_msgSender()];
        uint256 userAmount = user0.amount;

        UserInfo storage user1 = userInfo[1][_msgSender()];
        userAmount = userAmount.add(user1.amount);

        if (userAmount == 0) {
            return;
        } else {
            redeemTotalRewards(_msgSender());
        }       
    }

    // Sets true/false for the DIRTYCASH promo for new stakers
    function setPromoStatus(bool _status) external onlyAuthorized {
        promoActive = _status;
    }

    function setDynamicStakingEnabled(bool _status) external onlyAuthorized {
        dynamicStakingActive = _status;
    }

    // Sets the allocation multiplier
    function setAllocMultiplier(uint256 _newAllocMul) external onlyAuthorized {

        require(_newAllocMul >= 1 && _newAllocMul <= 100, "_allocPoint is outside of range 1-100");

        allocMultiplier = _newAllocMul;
    }

    function setAllocations(uint256 _lpalloc, uint256 _stakealloc) external onlyAuthorized {

        require(_lpalloc >= 1 && _lpalloc <= 100, "lpalloc is outside of range 1-100");
        require(_stakealloc >= 1 && _stakealloc <= 100, "stakealloc is outside of range 1-100");
        require(_stakealloc.add(_lpalloc) == 100, "amounts should add up to 100");

        lpalloc = _lpalloc;
        stakealloc = _stakealloc;
    }

    // Changes poolReward dynamically based on how many Dirty tokens + LP Tokens are staked to keep rewards consistent
    function updateVariablePoolReward() private {

        PoolInfo storage pool0 = poolInfo[0];
        uint256 runningTotal0 = pool0.runningTotal;
        uint256 lpratio;

        PoolInfo storage pool1 = poolInfo[1];
        uint256 runningTotal1 = pool1.runningTotal;
        uint256 stakeratio;

        uint256 multiplier;
        uint256 ratioMultiplier;
        uint256 newLPAlloc;
        uint256 newStakeAlloc;

        if (runningTotal0 >= maxLPStake) {
            lpratio = SafeMath.div(runningTotal0, maxLPStake, "lpratio >= maxLPStake divison error");
        } else {
            lpratio = SafeMath.div(maxLPStake, maxLPStake, "lpratio maxLPStake / maxLPStake division error");
        }

        if (runningTotal1 >= maxDirtyStake) {
             stakeratio = SafeMath.div(runningTotal1, maxDirtyStake, "stakeratio >= maxDirtyStake division error"); 
        } else {
            stakeratio = SafeMath.div(maxDirtyStake, maxDirtyStake, "stakeratio maxDirtyStake / maxDirtyStake division error");
        }   

        multiplier = SafeMath.add(lpratio, stakeratio);
        
        poolReward = SafeMath.mul(rewardSegment, multiplier);

        if (stakeratio == lpratio) { //ratio of pool rewards should remain the same (65 lp, 35 stake)
            adjustPools(0, lpalloc, true);
            adjustPools(1, stakealloc, true);
        }

        if (stakeratio > lpratio) {
            ratio = SafeMath.div(stakeratio, lpratio, "stakeratio > lpratio division error");
            
             ratioMultiplier = ratio.mul(allocMultiplier);

             if (ratioMultiplier < lpalloc) {
                newLPAlloc = lpalloc.sub(ratioMultiplier);
             } else {
                 newLPAlloc = 5;
             }

             newStakeAlloc = stakealloc.add(ratioMultiplier);

             if (newStakeAlloc > 95) {
                 newStakeAlloc = 95;
             }

             adjustPools(0, newLPAlloc, true);
             adjustPools(1, newStakeAlloc, true);

        }

        if (lpratio > stakeratio) {
            ratio = SafeMath.div(lpratio, stakeratio,  "lpratio > stakeratio division error");

            ratioMultiplier = ratio.mul(allocMultiplier);

            if (ratioMultiplier < stakealloc) {
                newStakeAlloc = stakealloc.sub(ratioMultiplier);
            } else {
                 newStakeAlloc = 5;
            }

             newLPAlloc = lpalloc.add(ratioMultiplier);

            if (newLPAlloc > 95) {
                 newLPAlloc = 95;
            }

             adjustPools(0, newLPAlloc, true);
             adjustPools(1, newStakeAlloc, true);
        }


    }


    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title  
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 * Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.1/contracts/examples/SimpleToken.sol
 */
contract DirtyCash is ERC20 {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    address owner = payable(address(msg.sender));

    modifier onlyOwner() {
        require(msg.sender == owner);
    _;
    }

    // This will allow to rescue ETH sent by mistake directly to the contract
    function rescueETHFromContract() external onlyOwner {
        address payable _owner = payable(_msgSender());
        _owner.transfer(address(this).balance);
    }

    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function transferERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        require(_tokenAddr != address(this), "Cannot transfer out native token");
        IERC20(_tokenAddr).transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

