// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
 * ApeSwapFinance 
 * App:             https://block-mine.com
 * Medium:          https://medium.com/@block_mine   
 * Twitter:         https://twitter.com/block_mine 
 * Telegram:        https://t.me/lock_mine
 * Announcements:   https://t.me/block_mine_news
 * GitHub:          https://github.com/blockmine
 */

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/TransferHelper.sol';

import "./token/GoldNuggetToken.sol";
import "./helper/BlockmineToken.sol";
import "./helper/RefinerToken.sol";
import "./SheriffMaster.sol";
import "./SustainabilityContract.sol";


// The RefinementMaster is the master of Refinement. He refines tokens to even better one.
// Refined tokens are burned forever. Refinement tokens are limited depending on their worth
// a certain amount of refinement tokens is needed. 
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once NUGGET is sufficiently
// distributed and the community can show to govern itself.
//
contract RefinementMasterGoldbar is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeBEP20 for RefinerToken;
    using SafeBEP20 for GoldNuggetToken;
    using SafeBEP20 for BlockmineToken;
    
    // Info of each user.
    struct UserInfo {
        uint256 amount;            // How many LP tokens the user has provided.
        uint256 rewardDebt;        // Reward debt. See explanation below.
        uint256 rewardClaim;       // User claim wrt all locked LPs (what is still to be claimed by the user, but locked at the current point). See explanation below.
        uint256 burnDebtPLP;       // at some point user may wanna cash out. The burn debt per lp defines how much is do be burned
        uint256 lockedAt;          // block locked at 
        //
        // We do some fancy math here. Basically, any point in time, the amount of NUGGETs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRefTPerShare) - user.rewardDebt // same formula as in SheriffMaster for refinement, just payout differs from SheriffMaster
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRefTPerShare` (and `lastComputationBlock`) gets updated.
        //   2. User's `amount` gets updated.
        //   3. User's `rewardDebt` gets updated. If user puts in funds later, he will have a certain reward debt.
        //   4. User's `rewardClaim` gets updated. This is necessary since user cannot cash out before LPs are unlocked. 
        //   5. User's `burnDebtPLP` gets updated. This is necessary since user cannot cash out before LPs are unlocked. 
        
        //
        //  Note: We introduce a special nugget pool here that does not create nuggets but converts them to gold bars. 
        //  Nuggets are partially burned in the unsteaking process.
    }
    
    

    // Info of each pool.
    struct PoolInfo {
        RefinerToken refinementToken;       // Address of refinement token that is converted (all new tokens are stored there during refinement process).
        uint256 lastComputationBlock; // Last block number that TOKEN commputation occurs.
        uint256 accRefTPerShare;      // Accumulated TOKENs per share, times 1e12. See below.uint256 block_start;
        uint32 blocks_locked;        // how long must funds be locked before they can be cashed out? (i.e. how long does refinement take=)
        uint256 burnedNuggets;
        
    }
    

    // The NUGGET TOKEN!
    GoldNuggetToken public nugget;
    // The initial RefinerToken TOKEN to create a limited amount of new gold bars (owned by Refinement Master)!
    RefinerToken public nugget_refinement;
    // Burn TOKEN
    BlockmineToken public burnToken;
    uint256 DECIMALS_SHARE_REWARD = 1e12;
    uint256 DECIMAL_BURN_DEBT = 1e36;
    uint32 MAX_PERCENT = 1e4; // for avoiding errors while programming, never use magic numbers :)
    // Treasury address.
    address public treasuryaddr;
    // Mine Master
    SheriffMaster private sheriff_master;
    // sustainability contract.
    SustainabilityContract public sustainabilityContract;

    // Info of each refinement pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    //uint256 public totalAllocPoint = 0;
    // The block number when TOKEN refinement starts.
    uint256 public startBlock;

    event EmitDeposit(address indexed user, uint256 indexed pid, uint256 amount);
    event EmitWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmitEmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmitSet(uint256 pid,  uint32 blocks_locked);
    event EmitAdd(address token, uint32 blocks_locked);
    event EmitDev(address _new);
    event EmitTres(address _new);
    event EmitSus(address _new);
    event EmitSusChangeSuspended();

    constructor(
        GoldNuggetToken _nugget,
        RefinerToken _nugget_refinement,
        BlockmineToken _burnToken,
        address _treasuryaddr,
        //address _feecontract,
        uint256 _startBlock,
        SustainabilityContract _sustainabilityContract
    ) public {
        nugget = _nugget;
        nugget_refinement = _nugget_refinement;
        burnToken = _burnToken;
        
        treasuryaddr = _treasuryaddr;
        //feecontract = _feecontract;
        startBlock = _startBlock;
        sustainabilityContract = _sustainabilityContract;

        // staking pool
        poolInfo.push(PoolInfo({
            refinementToken: _nugget_refinement,
            blocks_locked: 28800 * 30, // 30 days lock
            lastComputationBlock: startBlock,
            accRefTPerShare: 0,
            burnedNuggets: 0
        }));
    }
    
    fallback() external payable{
    }
    
    receive() external payable{
    }

    // validate if pool already exists (taken from apeswap.finance)
    modifier validatePool(uint256 _pid) {
        require(_pid < poolInfo.length, "validatePool: pool exists?");
        _;
    }
    
    function burnedNuggets() external view returns (uint256 _burned) {
        for (uint256 i = 0; i < poolInfo.length; i++){
            _burned = _burned.add(poolInfo[i].burnedNuggets);
        }
    }
    
    function setMaster(SheriffMaster _sheriff_master) external onlyOwner {
        sheriff_master = _sheriff_master;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Detects whether the given pool already exists
    function checkPoolDuplicate(IBEP20 _refinementToken) public view {
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; _pid++) {
            require(poolInfo[_pid].refinementToken != _refinementToken, "add: existing pool");
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(RefinerToken _refToken,  uint32 _blocks_locked) public onlyOwner {
        // check lp token exist -> revert if you try to add same lp token twice
        checkPoolDuplicate(_refToken);
        uint256 lastComputationBlock = block.number > startBlock ? block.number : startBlock;
        //totalAllocPoint = totalAllocPoint.add(_allocPoint);
        // add pool info
        poolInfo.push(PoolInfo({
            refinementToken: _refToken, // the lp token
            blocks_locked: _blocks_locked, //allocation points for new farm. 
            lastComputationBlock: lastComputationBlock, // last block that got rewarded
            accRefTPerShare: 0,
            burnedNuggets: 0
        }));
        emit EmitAdd(address(_refToken), _blocks_locked);
    }

    // Update the given pool's NUGGET allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint32 _blocks_locked) public onlyOwner {
        // 0 - 30 days always possible (for gold coins and bitbars lock > 90d cannot be increased)
        require(_blocks_locked <= 90 * 28800 || _blocks_locked < poolInfo[_pid].blocks_locked, "set: invalid block locked.");
        poolInfo[_pid].blocks_locked = _blocks_locked;
        emit EmitSet(_pid, _blocks_locked);
    }


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from); //.mul(BONUS_MULTIPLIER);
    }

    // View function to see pending NUGGETs on frontend for given pool _pid)
    function pendingCake(uint256 _pid, address _user) public view returns (uint256) {
        // get pool info in storage
        PoolInfo storage pool = poolInfo[_pid];
        // get user info in storage
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRefTPerShare = pool.accRefTPerShare;
        uint256 lpSupply = pool.refinementToken.balanceOfRefinableTokens();
        if (block.number > pool.lastComputationBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastComputationBlock, block.number);
            uint256 tokenReward = multiplier.mul(pool.refinementToken.getTokensPerBlock());//.mul(pool.allocPoint).div(totalAllocPoint);
            accRefTPerShare = accRefTPerShare.add(tokenReward.mul(97).div(100).mul(DECIMALS_SHARE_REWARD).div(lpSupply));
        }
        // acc - debt + claims = pending rewards overall
        return user.amount.mul(accRefTPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt).add(user.rewardClaim);
    }
    
    function getBurnDebt(uint256 _pid, address _user) external view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        if (user.amount == 0)
            return 0;
        // pending nuggets (without reward claim since burn debt already considered that debt)
        uint256 pending = pendingCake(_pid, _user).sub(user.rewardClaim);
        // debt multiplier
        uint256 debt_multiplier = pool.refinementToken.getBurnMultiplier();
        // compute percentage burn
        uint256 max_supply = pool.refinementToken.getMaxSupply();
        // current burn debt of user 
        uint256 burnDebtPLP =  user.burnDebtPLP;//.div(max_supply);
        // updateded burn debt per lp including pending
        burnDebtPLP = burnDebtPLP.add(pending.mul(DECIMAL_BURN_DEBT).div(max_supply).mul(debt_multiplier));
        // compute overal burn debt 
        uint256 burnDebt =  burnDebtPLP.mul(user.amount).div(DECIMAL_BURN_DEBT);
        return burnDebt;
    }
    
    function blocksToUnlock(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo storage pool = poolInfo[_pid];
        uint256 _block_required = user.lockedAt.add(pool.blocks_locked);
        if (_block_required <= block.number)
            return 0;
        else
            return _block_required.sub(block.number);
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePool(_pid){
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastComputationBlock) {
            return;
        }
        uint256 lpSupply = pool.refinementToken.balanceOfRefinableTokens();
        if (lpSupply == 0) {
            pool.lastComputationBlock = block.number;
            return;
        }
        uint256 token_per_block = pool.refinementToken.getTokensPerBlock();
        uint256 multiplier = getMultiplier(pool.lastComputationBlock, block.number);
        uint256 tokenReward = multiplier.mul(token_per_block);
        // mint tokens and store
        pool.refinementToken.delegate_mint(address(pool.refinementToken), tokenReward);
        // compute accRefTPerShare (97% -> 3% is fee, paid out once unlocked)
        pool.accRefTPerShare = pool.accRefTPerShare.add(tokenReward.mul(97).div(100).mul(DECIMALS_SHARE_REWARD).div(lpSupply));
        pool.lastComputationBlock = block.number;
    }
    
    function getBurnTokenDebt(uint256 _pid, address _user) view external returns (uint256) {
        return _getBurnTokenDebt(pendingCake(_pid, _user));
    }
    
    function _getBurnTokenDebt(uint256 _reward) pure internal returns (uint256) {
        return _reward.mul(10);
    }

    // Stake NUGGET tokens to Refinement Master
    function enterStaking(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            // get pending refined tokens
            uint256 pending = user.amount.mul(pool.accRefTPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt);
            if(pending > 0) {
                // set burn debt of user based on new rewards (every lp has a burn debt that is to be paid when unstaking based on the earned gold bars)
                // burn multiplier doubles every year (as minting is halfed every year) -> 50% of used nuggets are burned every year
                uint256 debt_multiplier = pool.refinementToken.getBurnMultiplier();
                // get token max supply
                uint256 max_supply = pool.refinementToken.getMaxSupply();
                // compute new burn debt per lp in percent (times 1e48) based on given rewards 
                user.burnDebtPLP = user.burnDebtPLP.add(pending.mul(DECIMAL_BURN_DEBT).div(max_supply).mul(debt_multiplier));
                // check if lps are locked (if so, no collect is possible)
                if (blocksToUnlock(_pid, msg.sender) > 0){
                    // update rewardClaim: claim + pending
                    user.rewardClaim = user.rewardClaim.add(pending);
                }
                else{ // unlocked -> collect
                    // get pending + rewardClaim
                    pending = pending.add(user.rewardClaim);
                    // update rewardClaim: claim + pending - pending_withdraw
                    user.rewardClaim = 0;
                    // 3% of refined tokens go to treasury (pending is defined as 97%)
                    uint256 fee_tres = pending.mul(100).div(97).mul(300).div(MAX_PERCENT); // 3% overall
                    // compute 97% + 3% burn token debt
                    uint256 tokenDebt = _getBurnTokenDebt(pending.add(fee_tres));
                    // transfer burn token debt (100%)
                    burnToken.safeTransferFrom(address(msg.sender), address(this), tokenDebt);
                    // transfer fee (3%)
                    safeRefinedTokenTransfer(pool, treasuryaddr, fee_tres);
                    // rest goes to miner (97%)
                    safeRefinedTokenTransfer(pool, msg.sender, pending);
                }
            }
        }
        if(_amount > 0) {
            uint256 amount_old = user.amount; // neded for avg lock computation
            // if _amount > 0 transfer that amount to the address of the corresponding refinement token
            nugget.safeTransferFrom(address(msg.sender), address(pool.refinementToken), _amount);
            // burnDebtLps is recomputed including the new amount. What basically happens here is that the reward debt of user.amount is distributed to (user.amount + amount),
            // thus the overall reward debt stays the same. This ensures that (later staked) LPS are not charged with the previous rewards by distributing the debt to the new lps,
            // which lowers the debts of the previous lps
            user.burnDebtPLP = user.burnDebtPLP.mul(user.amount).div(user.amount.add(_amount));
            user.amount = user.amount.add(_amount);
            // set new locked amount based on average locking window
            uint256 lockedFor = blocksToUnlock(_pid, msg.sender);
            // avg lockedFor: (lockedFor * amount_old + blocks_locked * _amount) / user.amount
            lockedFor = lockedFor.mul(amount_old).add(pool.blocks_locked.mul(_amount)).div(user.amount);
            // set new locked at 
            user.lockedAt = block.number.sub(pool.blocks_locked.sub(lockedFor));
            pool.refinementToken.mint(msg.sender, _amount);
        }
        // set reward debt
        user.rewardDebt = user.amount.mul(pool.accRefTPerShare).div(DECIMALS_SHARE_REWARD);
        emit EmitDeposit(msg.sender, _pid, _amount);
    }

    // Withdraw NUGGET tokens from STAKING. Bound to Freezer contract
    function leaveStaking(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "Withdraw: Hm I am not sure you have that amount in the pool.");
        require(blocksToUnlock(_pid, msg.sender) == 0, "Dammit, LPs are still locked/You cannot withdraw yet.");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRefTPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt);
        if(pending > 0) {
            // set burn debt of user based on new rewards (every lp has a burn debt that is to be paid when unstaking based on the earned gold bars)
            // burn multiplier doubles every year (as minting is halfed every year) -> 50% of used nuggets are burned every year
            uint256 debt_multiplier = pool.refinementToken.getBurnMultiplier();
            // get token max supply
            uint256 max_supply = pool.refinementToken.getMaxSupply();
            // burn debt percentage of nuggets depending on refined gold bars: 
            user.burnDebtPLP = user.burnDebtPLP.add(pending.mul(DECIMAL_BURN_DEBT).div(max_supply).mul(debt_multiplier));
            // get pending + rewardClaim
            pending = pending.add(user.rewardClaim);
            // update rewardClaim: claim + pending - pending_withdraw
            user.rewardClaim = 0;
            // 3% of refined tokens go to treasury (pending is defined as 97%)
            uint256 fee_tres = pending.mul(100).div(97).mul(300).div(MAX_PERCENT); // 3% overall
            // compute 97% + 3% burn token debt
            uint256 tokenDebt = _getBurnTokenDebt(pending.add(fee_tres));
            // transfer burn token debt (100%)
            burnToken.safeTransferFrom(address(msg.sender), address(this), tokenDebt);
            // transfer fee (3%)
            safeRefinedTokenTransfer(pool, treasuryaddr, fee_tres);
            // rest goes to miner
            safeRefinedTokenTransfer(pool, msg.sender, pending);
        }
        
        if(_amount > 0) {
            // burn debt for nuggets based on burnDeptPLP (no update needed on burn dept here since it is in percent): 
            uint256 burn =  user.burnDebtPLP.mul(_amount).div(DECIMAL_BURN_DEBT);
            // compute burn value (percentage of amount * burnDebt/maxSupply)
            // setting new amount
            user.amount = user.amount.sub(_amount);
            // burn refinement token when unstaking
            pool.refinementToken.burn(msg.sender, _amount);
            // send nuggets to 0-address to burn the nuggets forever * evil laugh here * 
            
            // sending rest nuggets (reducing burn) back to wallet sender (we consider the debt as paid ;))
            // transfer nuggets to here before adding to sus contract/burning for security reasons
            safeNuggetTransfer(pool, address(this), burn.mul(2));
            // burn nuggets
            nugget.transfer(address(0x000000000000000000000000000000000000dEaD), burn);
            // sending same amount to sustainability contract
            pool.burnedNuggets = pool.burnedNuggets.add(burn); // 1 x burn
            depositSustainableFunds(burn); // 2 x burn
            safeNuggetTransfer(pool, msg.sender, _amount.sub(burn.mul(2)));
        }
        user.rewardDebt = user.amount.mul(pool.accRefTPerShare).div(DECIMALS_SHARE_REWARD);
        emit EmitWithdraw(msg.sender, _pid, _amount);
    }
    
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        // get user information
        UserInfo storage user = userInfo[_pid][msg.sender];
        // burn stake mine lp tokens when withdrawing (before tokens are transferred to avoid reentrancy)
        // check locked timer
        require(blocksToUnlock(_pid, msg.sender) == 0, "Dammit, LPs are still locked/You cannot withdraw yet.");
        uint256 _amount = user.amount;
		// burn debt for nuggets based on burnDeptPLP (no update needed on burn dept here since it is in percent): 
        uint256 burn =  user.burnDebtPLP.mul(_amount).div(DECIMAL_BURN_DEBT);//.div(max_supply);
        // setting new amount and resetting all variables
        user.amount = 0; 
        user.rewardDebt = 0; 
        user.rewardClaim = 0;
        user.burnDebtPLP = 0;
        // burn refinement token when unstaking
        pool.refinementToken.burn(msg.sender, _amount);
        // sending rest nuggets (reducing burn) back to wallet sender (we consider the debt as paid ;))
        // transfer nuggets to here before adding to sus contract/burning for security reasons
        safeNuggetTransfer(pool, address(this), burn.mul(2));
        // send nuggets to dead-address to burn the nuggets forever * evil laugh here * 
        nugget.transfer(address(0x000000000000000000000000000000000000dEaD), burn);
        // sending same amount to sustainability contract
        pool.burnedNuggets = pool.burnedNuggets.add(burn); // 1 x burn
        depositSustainableFunds(burn); // 2 x burn
        safeNuggetTransfer(pool, msg.sender, _amount.sub(burn.mul(2)));
        // emit event
        emit EmitEmergencyWithdraw(msg.sender, _pid, _amount);
    }
    
    // Safe nugget transfer function, just in case if rounding error causes pool to not have enough NUGGETs.
    function safeNuggetTransfer(PoolInfo memory _pool, address _to, uint256 _amount) internal {
        // return nuggets from corresponding refinement token
        _pool.refinementToken.safeRefinableTokenTransfer(_to, _amount);
    }

    // Safe refined token transfer function, just in case if rounding error causes pool to not have enough NUGGETs.
    function safeRefinedTokenTransfer(PoolInfo memory _pool, address _to, uint256 _amount) internal {
        // return nuggets from corresponding refinement token
        _pool.refinementToken.safeTokenTransfer(_to, _amount);
    }
    
    function depositSustainableFunds(uint256 _amount) internal {
        // send nuggets to sustainabilityContract
        uint256 tokenBal = nugget.balanceOf(address(this));
        if (_amount > tokenBal) {
            // safetey case if safeNuggetTransfer has sent less nuggets for some reason
            nugget.transfer(address(sustainabilityContract), tokenBal);
        } else {
            nugget.transfer(address(sustainabilityContract), _amount);
        }
    }

    // Update treasury address by the previous dev.
    function tres(address _treasuryaddr) public {
        require(msg.sender == treasuryaddr, "treasury: wut?");
        treasuryaddr = _treasuryaddr;
        emit EmitTres(_treasuryaddr);
    }
    
    // security feature to deactivate the change of sustainability contract later on
    bool allowSusChange = true;

    // Update sustainability contract. Old funds are locked in the old contract for security reasons
    function setSustainabilitContract(SustainabilityContract _sustainabilityContract) public onlyOwner {
        require(allowSusChange, "sus contract: wait, you cannot do that anymore to me");
        require (_sustainabilityContract.owner() == address(sheriff_master), "sus contract: you cannot add a sustainability contract that is not owned by the master");
        // set new contract
        sustainabilityContract = _sustainabilityContract;
        emit EmitSus(address(_sustainabilityContract));
    }
    
    function suspendSusChange() external onlyOwner() {
        allowSusChange = false;
        emit EmitSusChangeSuspended();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
 * ApeSwapFinance 
 * App:             https://block-mine.com
 * Medium:          https://medium.com/@block_mine   
 * Twitter:         https://twitter.com/block_mine 
 * Telegram:        https://t.me/lock_mine
 * Announcements:   https://t.me/block_mine_news
 * GitHub:          https://github.com/blockmine
 */

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';

import "./token/GoldNuggetToken.sol";
import "./helper/StakeMineToken.sol";
import "./SustainabilityContract.sol";

//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once NUGGET is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract SheriffMaster is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lockedAt; // block locked at 
        bool read_lock; // security to prevent forever-locked funds if two requests arrive at the same time
        //
        // We do some fancy math here. Basically, any point in time, the amount of NUGGETs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accNuggetsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accNuggetsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        
        //
        //  Note: We introduce a special nugget pool here that does not create nuggets but converts them to gold bars. 
        //  Nuggets are partially burned in the unsteaking process.
    }
    

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. NUGGETs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that NUGGETs distribution occurs.
        uint256 accNuggetsPerShare;  // Accumulated NUGGETs per share, times 1e12. See below.
        uint32 blocks_locked;     // lock counter in blocks
        uint16 depositFeeBP;      // some pools need deposit fees in order to allow for sustainable liquidty mining
    }
    

    // The NUGGET TOKEN!
    GoldNuggetToken nugget;
    // The STAKE TOKEN (currently only used for reward distribution since staking pool does not exist in Blockmine)!
    StakeMineToken stake_token;
    uint256 public BONUS_MULTIPLIER = 1;
    uint32 MAX_PERCENT = 1e4; // for avoiding errors while programming, never use magic numbers :)
    uint256 DECIMALS = 1e18;
    uint256 DECIMALS_SHARE_REWARD = 1e12;
    // Treasury address.
    address public treasuryaddr;
    // sustainability contract.
    SustainabilityContract public sustainabilityContract;
    // NUGGET tokens created per block.
    uint256 public nuggetPerBlock = 1 * DECIMALS; // in 1e18 number due to decimal numbers

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint; // in 1e3
    // The block number when NUGGET mining starts.
    uint256 public startBlock; // in 1e0
    uint256 public withdrawFee = 3;

    event EmitDeposit(address indexed user, uint256 indexed pid, uint256 amount);
    event EmitWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmitEmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmitSet(uint256 pid, uint256 allocPoint, uint32 blocks_locked, uint16 depositFeeBP);
    event EmitAdd(address token, uint256 allocPoint, uint32 blocks_locked, uint16 depositFeeBP);
    event EmitTres(address _new);
    event EmitSus(address _new);
    event EmitSusChangeSuspended();
    event EmitSetFee(uint256 _fee);

    constructor(
        GoldNuggetToken _nugget,
        StakeMineToken _stake_token,
        address _treasuryaddr,
        SustainabilityContract _sustainabilityContract,
        uint256 _startBlock
    ) public {
        nugget = _nugget;
        stake_token = _stake_token;
        treasuryaddr = _treasuryaddr;
        // safe contract for sustainable liqudity mining, owned by the mine master
        sustainabilityContract = _sustainabilityContract;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _nugget,
            allocPoint:1000,
            lastRewardBlock: startBlock,
            accNuggetsPerShare: 0,
            blocks_locked: 0,
            depositFeeBP: 0
        }));

        totalAllocPoint = 1000;

    }
    
    fallback() external payable{
    }
    
    receive() external payable{
    }

    // validate if pool already exists (taken from apeswap.finance)
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

    // Detects whether the given pool already exists (thank you to apeswap.finance for providing that function)
    function checkPoolDuplicate(IBEP20 _lpToken) public view {
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; _pid++) {
            require(poolInfo[_pid].lpToken != _lpToken, "add: existing pool");
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // It will be automatically checked if pool is duplicate
    // Deposit Fee: 100% = 10,000 (max fee 10% = factor 1000) // blocks_locked measured in blocks
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint32 _blocks_locked, uint16 _depositFeeBP) public onlyOwner {
        require(_depositFeeBP <= MAX_PERCENT.div(10), "add: invalid deposit fee basis points"); // max 100%
        require(_blocks_locked <= 30 * 28800, "add: invalid block locked. Max allowed is 30 days in blocks");
        // check lp token exist -> revert if you try to add same lp token twice
        checkPoolDuplicate(_lpToken);
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        // add pool info
        poolInfo.push(PoolInfo({
            lpToken: _lpToken, // the lp token
            allocPoint: _allocPoint, //allocation points for new farm. 
            lastRewardBlock: lastRewardBlock, // last block that got rewarded
            accNuggetsPerShare: 0, 
            blocks_locked: _blocks_locked,
            depositFeeBP: _depositFeeBP
        }));
        updateStakingPool();
        emit EmitAdd(address(_lpToken), _allocPoint, _blocks_locked, _depositFeeBP);
    }

    // Update the given pool's NUGGET allocation point. Can only be called by the owner.
    // Deposit Fee: 100% = 10,000 (max fee 10% = factor 1000 as anti whale feature option) // blocks_locked measured in blocks
    function set(uint256 _pid, uint256 _allocPoint, uint32 _blocks_locked, uint16 _depositFeeBP) public onlyOwner {
        require(_depositFeeBP <= MAX_PERCENT.div(10), "set: invalid deposit fee basis points");
        require(_blocks_locked <= 30 * 28800, "set: invalid block locked. Max allowed is 30 days in blocks");
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        // update values
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].blocks_locked = _blocks_locked;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
        emit EmitSet(_pid, _allocPoint, _blocks_locked, _depositFeeBP);
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        // won't update unless allocation points of pool > 0 
        if (points != 0 && poolInfo[0].allocPoint != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }
    
    function mintingInfo() external view returns(uint256) {
        // sus reward per block
         uint256 sustainability_reward = sustainabilityContract.do_smart(1);
         // sus >= nuggetPerBlock * MULTIPLIER?
        if (sustainability_reward >= nuggetPerBlock.mul(BONUS_MULTIPLIER)){
            return 0;
        }
        else{
            return nuggetPerBlock.mul(BONUS_MULTIPLIER).sub(sustainability_reward);
        }
    }

    // View function to see pending NUGGETs on frontend for given pool _pid)
    function pendingCake(uint256 _pid, address _user) external view returns (uint256) {
        // get pool info in storage
        PoolInfo storage pool = poolInfo[_pid];
        // get user info in storage
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNuggetsPerShare = pool.accNuggetsPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            // nuggets per block * 90% 
            uint256 nuggetReward = multiplier.mul(nuggetPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            uint256 sustainability_reward = sustainabilityContract.do_smart(multiplier).mul(pool.allocPoint).div(totalAllocPoint);
            if (sustainability_reward >= nuggetReward){
                // special case: more rewards than base block reward
                // set updated remaining nuggetReward
                nuggetReward = sustainability_reward;
            }
            accNuggetsPerShare = accNuggetsPerShare.add(nuggetReward.mul(90).div(100).mul(DECIMALS_SHARE_REWARD).div(lpSupply));
        }
        return user.amount.mul(accNuggetsPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt);
    }
    
    function blocksToUnlock(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo storage pool = poolInfo[_pid];
        uint256 _block_required = user.lockedAt.add(pool.blocks_locked);
        if (_block_required <= block.number)
            return 0;
        else
            return _block_required.sub(block.number);
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePool(_pid){
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
        // base nugget reward
        uint256 nuggetReward = multiplier.mul(nuggetPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
         uint256 fee_tres;
        // get sustainability score based on pool allocation points and passed blocks
		// get sus reward for all passed blocks based on allocation points
        uint256 sustainability_reward = sustainabilityContract.do_smart(block.number.sub(pool.lastRewardBlock)).mul(pool.allocPoint).div(totalAllocPoint);
        if (sustainability_reward >= nuggetReward){
            // case 1: nothing to mint
            // 10% of nuggets go to treasury address (overall 10%)
            fee_tres = sustainability_reward.mul(10).div(100);
            // set updated remaining nuggetReward
            nuggetReward = sustainability_reward.sub(fee_tres);
            sustainabilityContract.safeNuggetTransfer(treasuryaddr, fee_tres);
            // send nuggetReward from sustainability contract to stakeminetoken
            sustainabilityContract.safeNuggetTransfer(address(stake_token), nuggetReward);
        }
        else{
            // case 2: nuggets are to be mint
            // 8% of nuggets go to developer address and 2% treasury (overall 10%)
            fee_tres = nuggetReward.mul(10).div(100); 
            // the following steps are the optimal number to trasnfer
            // 1) transfer the sustainable reward to stake mine token
            if(sustainability_reward > 0)
                sustainabilityContract.safeNuggetTransfer(address(stake_token), sustainability_reward);
            // 2) mint the difference to stake mine token
            nugget.mint(address(stake_token), nuggetReward.sub(sustainability_reward));
            // 3) transfer fee from stake mine token to treasury
            stake_token.safeTokenTransfer(treasuryaddr, fee_tres);
            // 4) nugget reward is deducted by fee
            nuggetReward = nuggetReward.sub(fee_tres);
        }
        // set new distribution per LP
        pool.accNuggetsPerShare = pool.accNuggetsPerShare.add(nuggetReward.mul(DECIMALS_SHARE_REWARD).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Mine Master for NUGGET allocation.
    function deposit(uint256 _pid, uint256 _amount) public validatePool(_pid){
        require (_pid != 0, 'deposit NUGGET by staking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.read_lock == false, "withraw: Dammit, there was a read lock on your account due to a previous process.");
        user.read_lock = true;
        updatePool(_pid);
        if (user.amount > 0) {
            // transfer pending nuts to user since reward debts are updated below
            uint256 pending = user.amount.mul(pool.accNuggetsPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt);
            if(pending > 0) {
                safeNuggetTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 amount_fee;
            uint256 amount_old = user.amount; // neded for avg lock computation
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                // depositFeeBP is factor 10000 (MAX_PERCENT) overall
                amount_fee = _amount.mul(pool.depositFeeBP).div(MAX_PERCENT);
                // of fees: 8% (overall 0.08 * depositFeeBP) -> treasury
                uint256 tres_fee = amount_fee.mul(8).div(100); // 
                // transfer amount_fee to sustainability contract
                depositSustainableFunds(pool.lpToken, amount_fee.sub(tres_fee));
                // transfer fees to corresponding addresses
                pool.lpToken.safeTransfer(treasuryaddr, tres_fee);
                // store user LPs
                user.amount = user.amount.add(_amount).sub(amount_fee);
            }else{
                // no fees, no prob :)
                user.amount = user.amount.add(_amount);
            }
            // set new locked amount based on average locking window
            uint256 lockedFor = blocksToUnlock(_pid, msg.sender);
            // avg lockedFor: (lockedFor * amount_old + blocks_locked * (_amount - amount_fee)) / user.amount
            lockedFor = lockedFor.mul(amount_old).add(pool.blocks_locked.mul(_amount.sub(amount_fee))).div(user.amount);
            // set new locked at 
            user.lockedAt = block.number.sub(pool.blocks_locked.sub(lockedFor));
        }
        // user reward debt since there are already many nuts that had been produced before :)
        user.rewardDebt = user.amount.mul(pool.accNuggetsPerShare).div(DECIMALS_SHARE_REWARD);
        user.read_lock = false;
        emit EmitDeposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public validatePool(_pid){
        require (_pid != 0, 'withdraw NUGGET by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.read_lock == false, "withraw: Dammit, there was a read lock on your account due to a previous process.");
        user.read_lock = true;
        require(user.amount >= _amount, "withdraw: Hm I am not sure you have that amount in the mine.");
        // check locked timer
        require(blocksToUnlock(_pid, msg.sender) == 0, "Dammit, LPs are still locked/You cannot withdraw yet.");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accNuggetsPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt);
        if(pending > 0) {
            safeNuggetTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            // reduce amount before transferring
            user.amount = user.amount.sub(_amount);
            // withdraw penalty of 3 % which is used to pay back to holders :) seems fair to us, does it? 
            uint256 amount_fee = _amount.mul(withdrawFee).div(100);
            // of fees: 8% (overall 0.08 * depositFeeBP) -> treasury
            uint256 tres_fee = amount_fee.mul(8).div(100); // 
            // transfer amount_fee to sustainability contract
			if(amount_fee > 0){
                depositSustainableFunds(pool.lpToken, amount_fee.sub(tres_fee));
                // transfer fees to corresponding addresses
                pool.lpToken.safeTransfer(treasuryaddr, tres_fee);
			}
            // transfer token minues penalty fee
            pool.lpToken.safeTransfer(address(msg.sender), _amount.sub(amount_fee));
        }
        // update reward debts
        user.rewardDebt = user.amount.mul(pool.accNuggetsPerShare).div(DECIMALS_SHARE_REWARD);
        // remove read lock
        user.read_lock = false;
        emit EmitWithdraw(msg.sender, _pid, _amount);
    }

    // Stake NUGGET tokens to Mine Master
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.read_lock == false, "withraw: Dammit, there was a read lock on your account due to a previous process.");
        user.read_lock = true; 
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accNuggetsPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt);
            if(pending > 0) {
                safeNuggetTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 amount_old = user.amount; // needed for avg lock computation
            user.amount = user.amount.add(_amount);
            // set vault information to lock fees for a the pre-defined amount of blockstart
            // set new locked amount based on average locking window
            uint256 lockedFor = blocksToUnlock(0, msg.sender);
            // avg lockedFor: (lockedFor * amount_old + blocks_locked * (_amount - amount_fee)) / user.amount
            lockedFor = lockedFor.mul(amount_old).add(pool.blocks_locked.mul(_amount)).div(user.amount);
            // set new locked at
            user.lockedAt = block.number.sub(pool.blocks_locked.sub(lockedFor));
            // send stake data to msg.sender
            stake_token.mint(msg.sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNuggetsPerShare).div(DECIMALS_SHARE_REWARD);
        user.read_lock = false; 
        emit EmitDeposit(msg.sender, 0, _amount);
    }

    // Withdraw NUGGET tokens from STAKING. Bound to Freezer contract
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.read_lock == false, "Dammit, there was a read lock on your account due to a previous process.");
        user.read_lock = true; 
        require(user.amount >= _amount, "withdraw: not good");
        // check locked timer
        require(blocksToUnlock(0, msg.sender) == 0, "Dammit, LPs are still locked/You cannot withdraw yet.");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accNuggetsPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt);
        if(pending > 0) {
            safeNuggetTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            // burn stake token when unstaking
            stake_token.burn(msg.sender, _amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNuggetsPerShare).div(DECIMALS_SHARE_REWARD);
        user.read_lock = false; 
        emit EmitWithdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    // Bound to locked time
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        // get user information
        UserInfo storage user = userInfo[_pid][msg.sender];
        // burn stake mine lp tokens when withdrawing (before tokens are transferred to avoid reentrancy)
        // check locked timer
        require(blocksToUnlock(_pid, msg.sender) == 0, "Dammit, LPs are still locked/You cannot withdraw yet.");
        uint256 _amount = user.amount;
        // update amount/reward before transferring data
        if (_pid == 0){
			user.amount = 0;
		    user.rewardDebt = 0;
            stake_token.burn(msg.sender, _amount);
			// transfer token minues penalty fee
			pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
		else{
			// withdraw penalty of 3 % which is used to pay back to holders :) seems fair to us, does it? 
			// penalty fee needs to be applied here as well as otherwise this function could be exploited to avoid fees
			uint256 amount_fee = _amount.mul(withdrawFee).div(100);
            // of fees: 8% (overall 0.08 * depositFeeBP) -> treasury
            uint256 tres_fee = amount_fee.mul(8).div(100); // 
            // reset values
			user.amount = 0;
		    user.rewardDebt = 0;
			// transfer amount_fee to sustainability contract
			if(amount_fee > 0){
    			depositSustainableFunds(pool.lpToken, amount_fee.sub(tres_fee));
                // transfer fees to corresponding addresses
    			pool.lpToken.safeTransfer(treasuryaddr, tres_fee);
			}
			// transfer token minues penalty fee
			pool.lpToken.safeTransfer(address(msg.sender), _amount.sub(amount_fee));
		}
        // emit event
        emit EmitEmergencyWithdraw(msg.sender, _pid, _amount);
    }

    function getPoolInfo(uint256 _pid) public view
        returns(address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accNuggetsPerShare,  uint32 blocks_locked, uint16 depositFeeBP ){
            return (address(poolInfo[_pid].lpToken),
                poolInfo[_pid].allocPoint,
                poolInfo[_pid].lastRewardBlock,
                poolInfo[_pid].accNuggetsPerShare,
                poolInfo[_pid].blocks_locked,
                poolInfo[_pid].depositFeeBP);  
    }    
    
    function depositSustainableFunds(IBEP20 _token, uint256 _amount) internal {
        // we use the withdrawal pattern here, thus, we need to approve sustainabilityContract for 'amount'
        _token.approve(address(sustainabilityContract), _amount);
        sustainabilityContract.addFunds(address(_token), _amount, true, true);
    }

    // Safe nugget transfer function, just in case if rounding error causes pool to not have enough NUGGETs.
    function safeNuggetTransfer(address _to, uint256 _amount) internal {
        stake_token.safeTokenTransfer(_to, _amount);
    }

    // Update treasury address by the previous dev.
    function tres(address _treasuryaddr) public {
        require(msg.sender == treasuryaddr, "treasury: wut?");
        treasuryaddr = _treasuryaddr;
        emit EmitTres(_treasuryaddr);
    }
    
    // security feature to deactivate the change of sustainability contract later on
    bool public allowSusChange = true;

    // Update sustainability contract. Old funds are locked in the old contract for security reasons
    function setSustainabilitContract(SustainabilityContract _sustainabilityContract) public onlyOwner {
        require(allowSusChange, "sus contract: wait, you cannot do that anymore to me");
        require (_sustainabilityContract.owner() == address(this), "You cannot add a sustainability contract that is not owned by the master");
        // funds are not transferred from old contract for security reasons. they are basically lost. 
        // renounce ownership
        sustainabilityContract.renounceOwnership();
        // set new contract
        sustainabilityContract = _sustainabilityContract;
        emit EmitSus(address(_sustainabilityContract));
    }
    
    function suspendSusChange() external onlyOwner() {
        allowSusChange = false;
        emit EmitSusChangeSuspended();
    }
    
    function setFee(uint256 _withdrawFee) external onlyOwner() {
        require(_withdrawFee <= 5, "setFee: invalid withdraw fee");
        withdrawFee = _withdrawFee;
        emit EmitSetFee(_withdrawFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './helper/OwnableSecure.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import "./external/interfaces/IBlockminePair.sol";
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/TransferHelper.sol';
import './external/interfaces/IBLockmineRouter02.sol';

contract SustainabilityContract  is OwnableSecure {
    using SafeMath for uint32;
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    struct Optimizer {
        uint256 block;
        Action action;
    }
    
    uint16 public percent_burn = 3333;
    uint32 public sustainability_window;
    uint32 public action_interval;
    uint32 public optimizeExecutor;
    uint256 public block_start;
    uint256 public block_smart_action;
    uint256 public funds_per_block; // per block
    uint256 public remaining_funds_interval;
    uint256 public burned_nuggets;
    address public admin;
    IBLockmineRouter02 public router; 
    address public NUGGET;
    address public WBNB;
    bool public allowRouterChange = true;
    
    event EmitAdmin(address admin);
    event EmitRouter(address router);
    event EmitUpdate(uint256 _percent, uint256 sustainability_window, uint256 action_interval);
    event EmitPermission(address eligable, bool _eligable);
    event EmitRouterChangeSuspended();
    
    // gas optimizer per user
    enum Action { DoRemove, DoSwap1, DoSwap2 }
    mapping(address => Optimizer) optimizer;
    mapping (address => bool) public permission;
    
    
    constructor(IBLockmineRouter02 _router, address _nuggets, address _wbnb, uint32 _action_interval, uint32 _optimizeExecutor, uint32 _sustainability_window, address _admin) public{
        router = _router; 
        NUGGET = _nuggets;
        WBNB = _wbnb;
        sustainability_window = _sustainability_window;
        action_interval = _action_interval;
        block_start = block.number;
        block_smart_action = block.number.add(action_interval); // next smart action
        optimizeExecutor = _optimizeExecutor;
        funds_per_block = 0;
        burned_nuggets = 0;
        admin = _admin;
        // admin may add some nuggets once in a while instead of directly burning :)
        permission[admin] = true;
    }
    
    fallback() external payable{
    }
    
    receive() external payable{
    }

    /**
     * @notice Checks if the msg.sender is the admin address
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "admin: wut?");
        _;
    }
    
    // the refinment master as well as multiple games must be granted burn rights over $Nuggets
    modifier hasPermission(){
        require(permission[msg.sender], "No permission to add funds.");
        _;
    }

    /**
     * @notice Sets admin address
     * @dev Only callable by the contract owner.
     */
    function setAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "Cannot be zero address");
        // swap eligiblity
        permission[admin] = false;
        permission[_admin] = true;
        admin = _admin;
        emit EmitAdmin(_admin);
    }
    
    /**
     * @notice Sets router
     * @dev Necessary to link to own dex router later on
     */
    function setRouter(IBLockmineRouter02 _router) external onlyAdmin {
        require(allowRouterChange, "router: wait, you cannot do that anymore to me");
        require (address(_router) != address(0), "router: wut are you doing?");
        router = _router;
        emit EmitRouter(address(_router));
    }
    
    function suspendRouterChange() external onlyAdmin() {
        allowRouterChange = false;
        emit EmitRouterChangeSuspended();
    }
    
    function update(uint16 _percent, uint32 _sustainability_window, uint32 _action_interval, uint32 _optimizeExecutor) external onlyAdmin {
        require(_percent <= 10000, '_percent: invalid percent basis points');
        require(_sustainability_window > 0, '_sustainability_window: invalid value for _sustainability_window');
        require(_action_interval > 0, '_action_interval: invalid value for _action_interval');
        percent_burn = _percent;
        action_interval = _action_interval;
        sustainability_window = _sustainability_window;
        optimizeExecutor = _optimizeExecutor;
        emit EmitUpdate(_percent, _sustainability_window, _action_interval);
    }   
    
    // Potentiallly anyone could send funds to the contract... but since we know there are bad peeps out there...
    // ... we secure the contract by permission... 
    function setPermission(address _eligable, bool _enable) public onlyAdmin{
        require (_eligable != address(0), "eligable: wut are you doing?");
        permission[_eligable] = _enable;
        emit EmitPermission(_eligable, _enable);
    }  
    
    function burnedNuggets() view external returns(uint256) {
        return burned_nuggets;
    }
    
    // a function that truly does smart :)
    // based on the sustainability interval, the smart fct computes the current funds_per_block (per block)
    function do_smart(uint256 _blocks) external view returns(uint256)  {
        if (block.number >= block_start.add(sustainability_window)){
            // safety case
            if (remaining_funds_interval < funds_per_block.mul(_blocks)){
                return remaining_funds_interval;
            }
            // return computed funds per block (re-computed every intervall defined in block_smart_action)
            return funds_per_block.mul(_blocks);
        }
        return 0;
    }
    
    // function that handles fund adding to the sustainability contract
    function addFunds(address _fund,  uint256 _amount, bool _is_lp, bool optimize) external hasPermission returns(bool) {
        require (_amount > 0, "Sus Contract - You cannot add an amount == 0");
        require (_fund != address(0), "Zero address does not have any funds you can use here.");
        // transfer tokens to contract from sender (needs to have approval first)
        IBEP20(_fund).safeTransferFrom(msg.sender, address(this), _amount);
        // some one needs to the smart actions in this contract... since we do not wanna make the 
        // do_smart fuction a transaction, we need to do it here
        if (block.number >= block_smart_action){
            // set new smart block action (also important for the sliding window since the window is moved in 1-day steps)
            block_smart_action = block_smart_action.add(action_interval);
            // compute newly added nugget amount in contract
            uint256 added_ammount = IBEP20(NUGGET).balanceOf(address(this)).sub(remaining_funds_interval); // get added amount of Nugget funds
            // compute burn amount
            uint256 _burn = added_ammount.mul(percent_burn).div(10000);
            // burn nuggets (33.33%) - distribute nuggets (66.67%) ===> I LIKE! :D
            IBEP20(NUGGET).transfer(address(0x000000000000000000000000000000000000dEaD), _burn);
            // update statistics for frontend view
            burned_nuggets = burned_nuggets.add(_burn);
            // set funds per interval (funds without burning amount)
            remaining_funds_interval = IBEP20(NUGGET).balanceOf(address(this));
            // set funds per block (we do not need to consider if sustainability_interval is reached for the first time since it is not used before anyway)
            // re-compute sustainability window
            funds_per_block = remaining_funds_interval.div(sustainability_window);
            // do not execute any further action
            if (optimize)
                return true;
        }
        
        /// Since gas costs are higher with this contract than usual deposit/withdraw actions
        /// and we aim at optimizing the protocol for long term investors
        /// we added this optimizer which executes every function just once a day
        /// thus at most of the times no one has to pay the extra gas fees, but three times a day, someone does. 
        /// If that is the case... you can send us tnx and will be compensated with nuggets if you want to (gas > 400k) :)
        if (optimizer[_fund].block <= block.number || !optimize){
            // only executed if no smart action was executed to safe gas costs per single user
            if (_is_lp){
                IBlockminePair _pair = IBlockminePair(_fund);
                
                // only supports automatic nugget/wbnb swaps
                if (_pair.token0() != NUGGET && _pair.token1() != NUGGET &&  _pair.token0() != WBNB && _pair.token1() != WBNB)
                    return true;
                    
                if(optimize){
                    // optimized mode
                    if(optimizer[_fund].action == Action.DoRemove){
                        do_remove(_fund, _pair);
                    }
                    else if (optimizer[_fund].action == Action.DoSwap1){
                        do_swap_1(_fund, _pair);
                    }
                    else if (optimizer[_fund].action == Action.DoSwap2){
                        do_swap_2(_fund, _pair);
                    }
                }
                else{
                    // non-optimized
                    do_remove(_fund, _pair);
                    do_swap_1(_fund, _pair);
                    do_swap_2(_fund, _pair);
                }
                  
            }else{
                // transfer to bnb instead of nuggets - ensure that token is wbnb tradable!
                address[] memory path = new address[](2);
                path[0] = address(_fund);
                path[1] = WBNB;
                // we do not wanna swap bnb to bnb
                
                if (path[0] != path[1]){
                    _swap(_fund, path, _amount);
                    optimizer[_fund].action = Action.DoRemove;
                    // set next optimizer
                    optimizer[_fund].block = block.number.add(optimizeExecutor);
                }
            }
        }
        return true;
    }
    
    function do_remove(address _fund, IBlockminePair _pair) internal{
        // get available lp tokens (also from previous cycles)
        uint256 available = IBEP20(_fund).balanceOf(address(this));
        // approve router to transfer (only) amount 'available' of token _pair
        TransferHelper.safeApprove(_fund, address(router), available);
        router.removeLiquidity(_pair.token0(), _pair.token1(), available, 0, 0, address(this), block.timestamp.add(86400));
        //);
        optimizer[_fund].action = Action.DoSwap1;
    }
    
    function do_swap_1(address _fund, IBlockminePair _pair) internal{
        // swap to Nugget since sustainability contract needs one single currency to work properly
        uint256 balance0 = IBEP20(_pair.token0()).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = _pair.token0();
        path[1] = NUGGET;
        // no nuggets within _pair -> swap to wbnb instead (will be swapped to nugget at a later time)
        if (_pair.token0() != NUGGET && _pair.token1() != NUGGET)
            path[1] = WBNB;
        // we do not wanna swap nugget to nugget/wbnb to wbnb
        if(path[0] != path[1] && balance0 > 0){
			_swap(_pair.token0(), path, balance0);
        }
        // switch to next swap action
        optimizer[_fund].action = Action.DoSwap2;
    }
    
    function do_swap_2(address _fund, IBlockminePair _pair) internal{
        uint256 balance1 = IBEP20(_pair.token1()).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = _pair.token1();
        path[1] = NUGGET;
        // no nuggets within _pair -> swap to wbnb (will be swapped to nugget at a later time)
        if (_pair.token0() != NUGGET && _pair.token1() != NUGGET)
            path[1] = WBNB;
        // we do not wanna swap nugget to nugget/wbnb to wbnb
        if(path[0] != path[1] && balance1 > 0){
            _swap(_pair.token1(), path, balance1);
        }
        optimizer[_fund].action = Action.DoRemove;
        // set next optimizer
        optimizer[_fund].block = block.number.add(optimizeExecutor);
    }

    
    function _swap(address token, address[] memory path, uint256 amount) internal{
        // approve router to transfer balance0 of token0
        TransferHelper.safeApprove(token, address(router), amount);
        router.swapExactTokensForTokens(
            amount,
            0, // amountOutMin: we can skip computing this number because the math is tested
            path,
            address(this),
            block.timestamp.add(86400)
        );
    }
    
    
    // Safe token transfer function, just in case if rounding error causes pool to not have enough $Nuggets.
    function safeNuggetTransfer(address _to, uint256 _amount) external onlyOwner {
        if (_amount > remaining_funds_interval) {
            // set _amount to remaining funds (secured by do_smart)
            _amount = remaining_funds_interval;
        }
        remaining_funds_interval = remaining_funds_interval.sub(_amount);
        // send _amount
        IBEP20(NUGGET).transfer(_to, _amount);
    }
    
    function getNextsmartAction() external view returns (uint256){
        if (block_smart_action > block.number){
            return block_smart_action.sub(block.number);
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IBLockmineRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import './IBLockmineRouter01.sol';

interface IBLockmineRouter02 is IBLockmineRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    
    /**
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    */
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IBlockminePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import '@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol';
import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import '@pancakeswap/pancake-swap-lib/contracts/utils/Address.sol';

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20Delegate is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    
    /* - Extra Events - */
    /**
     * @notice Tokens minted event
     */
    event EmitMint(address to, uint256 amount);
    event EmitBurn(address from, uint256 amount);
    

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        _moveDelegates(_delegates[sender], _delegates[recipient], amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
    
    


    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);
    
    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "CAKE::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "CAKE::delegateBySig: invalid nonce");
        require(now <= expiry, "CAKE::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "CAKE::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying CAKEs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "CAKE::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/IBlockmineToken.sol";
import "./BEP20Delegate.sol";

// Blockmine token with Governance.
contract BlockmineToken is BEP20Delegate, IBlockmineToken {

    // initiate blockmine token and respective BEP20Delegate token
    constructor(string memory name, string memory symbol) internal BEP20Delegate(name, symbol) {
    }
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (Mine Master).
    function  mint(address _to, uint256 _amount) public override onlyOwner{
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
        emit EmitMint(_to, _amount);
    }
    
    /// @notice Burns `_amount` token from `_from`. Must only be called by the owner (Mine Master).
    function burn(address _from, uint256 _amount) public override onlyOwner{
        _burn(_from, _amount);
        _moveDelegates(_delegates[_from], address(0), _amount);
        emit EmitBurn(_from, _amount);
    }

    
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '@pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol';

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
contract OwnableSecure is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Deactivated for security reasons
     */
    function renounceOwnership() public onlyOwner {
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol";
import "./StakeMineToken.sol";


/// RefinementToken are a special case of stake token. 
// They serve as staking proof and hold the refined token
contract RefinerToken is StakeMineToken {
    
    IBlockmineToken public token_refinable;
    uint16 burning_ratio; // max 10,000 (100,00%) in 1e4
    uint256 start_block; // in 1e0
    uint256 block_per_day = 28800;
    uint256 halfing_round = 365;
    uint256 block_per_year; // in 1e0
    uint256 max_supply; // in 1e18
    uint32 MAX_PERCENT = 1e4; // for avoiding errors while programming, never use magic numbers :)
    uint256 public tokensPerBlock;
    
    constructor(
        IBlockmineToken _token_refinable,
        IBlockmineToken _token_refined,
        uint256 _startblock,
        uint256 _initial_distribution,
        uint256 _max_supply,
        string memory name, 
        string memory symbol
    ) public StakeMineToken(_token_refined, name, symbol){ // stake mine token stores the mined token, thus _token_refined
        // refinement_ratio defines how many tokens are needed to create one new (refined) BlockmineToken
        // depending on user's earned refinement tokens, a certain amount of the underlying token is burned
        token_refinable = _token_refinable;
        start_block = _startblock;
        max_supply = _max_supply;
        block_per_year = block_per_day.mul(halfing_round);
        // compute rewards / block for this token based on geometric series (sum_k=1,n (1/2^k -> 1) * tokens_to_mine
        uint256 tokens_to_mine = max_supply.sub(_initial_distribution);
        tokensPerBlock = tokens_to_mine.div(2).div(block_per_year);
    }
    
    function getTokensPerBlock() external view returns(uint256) {
        return _getHalfing(tokensPerBlock);
    }
    
    // get number of refined tokens for this address (can also be seen on the token's contract itself)
    // these are the tokens '_token_refinable' that are converted into '_token_refined'
    function balanceOfRefinableTokens() public view returns (uint256) {
        return token_refinable.balanceOf(address(this));
    }
    
    // get number of refined tokens for this address 
    function balanceOfRefinedTokens() public view returns (uint256) {
        return token.balanceOf(address(this));
    }    
    
    // Safe refined token transfer function, just in case if rounding error causes pool to not have enough refined TOKENS.
    function safeRefinableTokenTransfer(address _to, uint256 _amount) public onlyOwner {
        uint256 tokenBal = token_refinable.balanceOf(address(this));
        if (_amount > tokenBal) {
            token_refinable.transfer(_to, tokenBal);
        } else {
            token_refinable.transfer(_to, _amount);
        }
    }
    
    function getMaxSupply() external view returns (uint256) {
        return max_supply;
    }
    
    function getBY() external view returns (uint256) {
        return block_per_year;
    }
    
    function getS() external view returns (uint256) {
        return start_block;
    }
    
    function getB() external view returns (uint256) {
        return block.number;
    }
    
    
    function getBurnMultiplier() external view returns (uint256) {
        return 2 ** block.number.sub(start_block).div(block_per_year); //block.sub(start_block).div(block_per_year) + 1;
    }
    
    function _getHalfing(uint256 _amount) internal view returns (uint256) {
        // halfing occurs block-dependant after 1 year, 2 years and so on
        // blocks/day = 24 * 60 * 60 / 3 = 28800
        if (start_block > block.number){
            return 0; // obviously no halfing :)
        }
        // current active block counter
        uint256 block_counter = block.number.sub(start_block);
        // compute correct halfing 
        if (block_counter <= block_per_year){
            // no halfing
            return _amount;
        }
        // continues halfing over time 
        uint256 i = block_counter.div(block_per_year);
        return _amount.div(2**(i));
    }
    
    //@dev Creates `_amount` token to `_to`. Must only be called by the owner (Refinement Master).
    //The refiner token is owned by the master.
    //The refiner token is the owner of the refined token
    function delegate_mint(address _to, uint256 _amount) public onlyOwner {
        // owner of the refinement token can mint the token that is the result of the refinement
        // since the refined token is owned by the refinement master, no one else can mint the tokens as delegate
        // therefore delegate mint makes perfectly sense here. 
        token.mint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interfaces/IBlockmineToken.sol";
import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/BEP20.sol';

contract StakeMineToken is BEP20 {
    
    // The Blockmine TOKEN!
    IBlockmineToken public token;

    
    
    /* - Extra Events - */
    /**
     * @notice Tokens minted event
     */
    event EmitMint(address to, uint256 amount);
    event EmitBurn(address from, uint256 amount);

    constructor(
        IBlockmineToken _token,
        string memory name, 
        string memory symbol
    ) public BEP20(name, symbol){
        token = _token;
    }
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (Mine Master).
     function  mint(address _to, uint256 _amount) public onlyOwner{
        _mint(_to, _amount);
        emit EmitMint(_to, _amount);
    }
    
    /// @notice Burns `_amount` token from `_from`. Must only be called by the owner (Mine Master).
    function burn(address _from, uint256 _amount) public onlyOwner{
        _burn(_from, _amount);
        emit EmitBurn(_from, _amount);
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough TOKENS.
    function safeTokenTransfer(address _to, uint256 _amount) public onlyOwner {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

// Blockmine token with Governance.
interface IBlockmineToken is IBEP20{
    
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (Mine Master).
    function mint(address _to, uint256 _amount) external;
    
    /// @notice Burns `_amount` token from `_from`. Must only be called by the owner (Mine Master).
    function burn(address _from, uint256 _amount) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../helper/BlockmineToken.sol";

// NuggetToken with Governance.
contract GoldNuggetToken is BlockmineToken('Gold Nugget', 'GOLD NUGGET') {
    
    
    
    constructor() public {
        mint(10000 * 10 ** 18);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import '../GSN/Context.sol';

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import '../../access/Ownable.sol';
import '../../GSN/Context.sol';
import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.6.0;

import './IBEP20.sol';
import '../../math/SafeMath.sol';
import '../../utils/Address.sol';

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

