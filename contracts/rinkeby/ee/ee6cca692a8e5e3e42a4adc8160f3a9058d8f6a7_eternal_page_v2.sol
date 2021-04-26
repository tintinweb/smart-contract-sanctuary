/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity ^0.6.12;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}


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
     * Returns a boolean value indicating whxdai the operation succeeded.
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
     * Returns a boolean value indicating whxdai the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/xdaieum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whxdai the operation succeeded.
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

// ================================================
//            MAIN ETERNAL PAGE CONTRACT
// ================================================
    
    
contract eternal_page_v2 {
               
    // ================================================
    //                  EVENTS
    // ================================================
    
    event _BlockPurchased(
                    uint indexed blockId,  
                    address author,  
                    string file_hash,
                    uint chunk_id,
                    uint256 xdai_value,
                    string  attachments,
                    string tags);
       
    event _BlockOnSale( uint indexed blockId,  
                    address author,  
                    uint256 xdai_value);
                    
    event _RewardPoolInitialization(uint256 user_staking_rewards_, uint256 owners_token_rewards);
    
    event _Stake(   address author,  
                    uint256 xdai_value);
                    
    event _UnStake( address author,  
                    uint256 xdai_value);
                    
    event _NewEpoch( uint epoch_id,
                    uint256 owners_token_rewards,
                    uint256 epoch_start_date);
                   
    event _TakeDown(address indexed author, uint blockId, string reason);
    event _moderatorsApprobationVote();
    event _moderatorsApprobationVoteClose();
    event _RewardsDistributed(uint256 user_xdai_rewards_);
    event _UserClaimedRewards(uint256 user_xdai_rewards_);

    event _ProposalCreated(uint indexed proposalID, uint voteEndDate, address indexed creator);
    event _Voted(uint indexed proposalID, uint numTokens, address indexed voter);
    event _ProposalClosed(uint indexed proposalID, bool decision);
    event _TokensRescued(uint indexed proposalID, address indexed voter);
    


    using SafeMath for uint256;
    using SafeMath for uint;
   
    // ================================================
    //                  ENUMS
    // ================================================
    
    enum BlockStatus{
        VALID,
        DELETED
    }
    
    enum ModeratorStatus{
        TBD,
        OK,
        SLASHED
    }
    
    enum ProposalStatus{
        VOTE,
        PASSED,
        DENIED,
        EXPIRED
    }
    
    // ================================================
    //                  STRUCTURES
    // ================================================
    
    struct Block {
        bool on;
        string image_hash;    
        uint chunk_id;                      
        BlockStatus status;
        address payable owner;                         
        uint256 xdai_value;
    }
    
    struct Moderator {  
        bool on;
        uint256 locked_rewards;     
        uint[] takedown_block_ids;                    
        ModeratorStatus status;  
        uint256 last_takedown_date;
        uint votes_ok;
        uint votes_slash;
    }
    
    struct Balances {
        uint256 available_xdai_balance;
        uint256 available_token_balance;
        uint256 staked_token_balance;
        uint stake_timestamp;
        uint last_collected_epoch;
        uint last_epoch_voted;
    }
   
    struct Proposal {
        address author;                       
        ProposalStatus status;
        uint[] params_;
        uint256[] proposed_values_;
        uint256 voteEndDate;
        uint256 votesFor;
        uint256 votesAgainst;        
        mapping(address => bool) didVote;
        address[] voters;
    }
    
    // ================================================
    //                  STATE VARIABLES
    // ================================================

    uint256 public constant BLOCK_COUNT = 48*32;
    
    // ************************  PARAMETERS *******************************************
    // @@dev	 MODERATION_MIN_STAKE minimum required token stake to moderate
    uint256 public MODERATION_MIN_STAKE =  1000 * (10**18); //1000 token
    uint256 public MODERATION_SLASHING_AMOUNT =  100 * (10**18); //100 token
    uint256 public MODERATION_APPROB_MIN_VOTE_COUNT =  100 * (10**18); //1000 tokens
    uint256 public MIN_STAKE_TO_START_PROPOSAL = 1000 * (10**18);
    uint256 public MIN_VOTE_TOTAL_AMOUNT =  1000 * (10**18); //10 000 tokens casted into the vote to pass
    uint256 public MIN_VOTE_STAKED_REQUIRED = 100 * (10**18);
    uint256 public MODERATION_POOL_CAP = 100 finney;
    uint256 public MODERATION_QUORUM_SLASHING = 60;
    uint256 public MODERATION_REWARD = 100 finney;
    uint256 public INITAL_BLOCK_PRICE = 10 finney; 
    uint256 public STANDARD_VOTE_DURATION = 120 seconds;
    uint256 public EPOCH_DURATION = 180 seconds;
    uint256 public REQUIRED_STAKE_DURATION = 155 seconds;
    uint256 public VOTE_QUORUM_TO_PASS_PERCENT = 60;
    uint256 public MIN_VOTE_STAKED_PERCENT = 20; //% of staked tokens that need to be casted to vote
    // @@dev	 BIDDING_PRICE_RATIO_PERCENT ratio (above >100) defining the minimum price for an already owned block, by default 120% previous price
    uint256 public BIDDING_PRICE_RATIO_PERCENT = 115; // MUST BE STRICLY > 100
    // @@dev	 GOVERNANCE_FUNDS_RECEIVER_ADDRESS address to send funds from governance funds, during adequate governance proposals
    address payable public GOVERNANCE_FUNDS_RECEIVER_ADDRESS;
    // ********************************************************************************
    
    //////////////////////////////////////////////////////////////////////////
    mapping(uint => Block) public Blocks; // maps proposalID to Proposal struct
    uint public used_block_count = 0;
    //////////////////////////////////////////////////////////////////////////
    uint public epoch = 0;
    uint public last_epoch_date = 0;
    uint256 public last_epoch_rewards = 0;
    uint256 public last_epoch_remaining_rewards_ = 0;
	
    uint last_collect_epoch = 0;
    uint256 last_collect_timestamp = 0;
    //////////////////////////////////////////////////////////////////////////
	
    uint256 public total_stake_count = 0;
    uint256 public last_epoch_total_stake_ = 0;
    //////////////////////////////////////////////////////////////////////////
	
    uint256 public owners_rewards_pool = 0;
    //////////////////////////////////////////////////////////////////////////
	
    address[] public  active_moderators_;
    mapping ( address => Moderator ) public moderators;
    uint256 public  moderation_governance_votes_amount = 0;
    bool public moderation_gov_vote_in_progress = false;
    //////////////////////////////////////////////////////////////////////////
	
    mapping ( address => Balances ) public balances; 
    address[] public stakeholders;
    //////////////////////////////////////////////////////////////////////////
	
    uint256 public current_xdai_balance = 0;
    uint256 public holders_xdai_balance = 0;
    uint256 public moderation_xdai_balance = 0;
    uint256 public governance_xdai_balance = 0;
    //////////////////////////////////////////////////////////////////////////
    
    mapping(uint => Proposal) public proposals; // maps proposalID to Proposal struct
    uint256 proposalNonce = 0;
    //////////////////////////////////////////////////////////////////////////
    address[] public proposed_xdai_funds_receiver;
    uint256 receiverNonce = 0;
    
    IERC20 token;
    //////////////////////////////////////////////////////////////////////////
   
    /**
    @dev Initializer. Can only be called once.
    */
    constructor() public {
        address tracker_0x_address = 0x8ac9fb89aD2B8b7eD3F397a895E046f57f282c24; //PIX Token address
        token = IERC20(tracker_0x_address);
       
        last_epoch_date = block.timestamp;
    }
    
    
    // ================================================
    //                  CORE METHODS
    // ================================================
    
    /**
    @dev Buy blocks identified by block_id_,  pointing to their image file_hash_, 
    *  each block is associated with a chunk_id_ (optional, set to zero if not used), block_paid_prices_ contains the prices that the sender is willing to pay for each block_id_
    *  attachments contains some string like a website, for advertisement, tags are for future usecases.
    * 
    *   @param block_id_                Array of blocks to buy
    *   @param file_hash_               image_file hash stored in decentralized storage (SWARM)
    *   @param chunk_id_                Array of the chunks identifier associated with each block identified in block_id_
    *   @param block_paid_prices_       Array of the prices to be paid for each block identified in block_id_
    *   @param attachments              string attachement, to include a website / URL with an image on the application (advertisement purposes, etc.)
    *   @param tags                     string intended to receive json-valid content, for future usecases
    */
    function Buy(uint[] memory  block_id_, string memory file_hash_, uint[] memory chunk_id_, uint[] memory block_paid_prices_, string memory attachments, string memory tags) payable public {
        // make sure the array lengths are all the same
        require(block_id_.length == chunk_id_.length && block_paid_prices_.length == chunk_id_.length, "block_id_, file_hash_, block_paid_prices_ arrays must be of same length");
        uint256 remaining_value = msg.value; // real value that will remain at the end of the iterations
        uint256 unspent_value = msg.value; // vvirtual alue that is used for each buy
        
        for (uint i = 0; i < block_id_.length; i++) {
            uint block_id = block_id_[i];
            require(block_id >= 0 && block_id < BLOCK_COUNT); // need valid block_id
            uint256 paid_price = block_paid_prices_[i] * 1 finney; // 1000 as input = 1 xDai
            require(remaining_value >= paid_price && unspent_value >= paid_price, "Must have enough value provided to cover all block_paid_prices");
            uint256 previous_price  = Blocks[block_id].xdai_value;
            if(Blocks[block_id].on){   // if block_id has previous owner
                require(paid_price >= previous_price.mul(BIDDING_PRICE_RATIO_PERCENT).div(100.0), "new paid xDai price must be >= previous price * PURCHASE_PRICE_RATIO/100");
                balances[Blocks[block_id].owner].available_xdai_balance += previous_price; //pay back previous block price to previous owner
                remaining_value = remaining_value.sub(previous_price);
            }else{ // if bloc never used
                previous_price = INITAL_BLOCK_PRICE; //previous price is the INITAL_BLOCK_PRICE when the block has never been bought before
                require(paid_price >= previous_price, "new paid xDai price must be >= INITAL_BLOCK_PRICE for free blocks"); // if first purchase for this block_id, min_price applies
                Blocks[block_id].on = true;
                used_block_count += 1;
            }
            unspent_value = unspent_value.sub(paid_price); //substract spent value
            
            Blocks[block_id].image_hash = file_hash_;    
            Blocks[block_id].chunk_id = chunk_id_[i];                      
            Blocks[block_id].status = BlockStatus.VALID;
            Blocks[block_id].owner = msg.sender;
            Blocks[block_id].xdai_value = paid_price;
            emit _BlockPurchased(block_id, msg.sender, file_hash_, chunk_id_[i], paid_price, attachments, tags);
        }
        
        current_xdai_balance +=  remaining_value;     // msg.value.sub(previous_price); //add extra balance
    }
    
    
    /**
    @dev Set the new price of a list of blocks, but the prices in xdai_sell_price_ can only be lower than the current xdai_price.
    *   The msg.sender must the owner of all blocks provided in block_id_
    *   @param block_id_            Array of blocks to update price
        @param xdai_sell_price_     Array of new prices for each block [Prices are provided is WITHOUT BIDDING_PRICE_RATIO_PERCENT INCLUDED]
    */
    function SetSell(uint[] memory block_id_, uint256[] memory xdai_sell_price_) public {
        require(block_id_.length == xdai_sell_price_.length, "block_id_, xdai_sell_price_ arrays must be of same length");
        for (uint i = 0; i < block_id_.length; i++) {
            uint block_id = block_id_[i];
            uint256 new_block_price = xdai_sell_price_[i] * 1 finney;
            require(Blocks[block_id].on && Blocks[block_id].owner == msg.sender, "block owner must be tx sender"); // tx sender must be owner of the block, to sell it
            require(new_block_price > 0 && new_block_price < Blocks[block_id].xdai_value, "new_block_price < current xdai_value"); // sell price must be lower than current xdai_value
           
            Blocks[block_id].xdai_value = new_block_price;
            emit _BlockOnSale(block_id, msg.sender, new_block_price);
        }
    }
    
    
    /**
     * @notice A method for a stakeholder to create a stake. This method update the stake timestamp of the user
     * @param _stake            The size of the stake to be created.
     */
    function Stake(uint256 _stake)
        public
    {
        // transfer the tokens from the sender to this contract
        require(token.transferFrom(msg.sender, address(this), _stake));
        if(balances[msg.sender].staked_token_balance == 0) addStakeholder(msg.sender);
        
        balances[msg.sender].staked_token_balance = balances[msg.sender].staked_token_balance.add(_stake);
        balances[msg.sender].stake_timestamp = block.timestamp;
        
        total_stake_count += _stake;
        emit _Stake( msg.sender, _stake);
    }
    
    
    /**
     * @notice A method for a stakeholder to create a stake.
     * @param _stake            The size of the stake to be created.
     */
    function StakeFromBalance(uint256 _stake)
        public
    {
        require(balances[msg.sender].available_token_balance >= _stake, "not enough available_token_balance to stake this amount");
        if(balances[msg.sender].staked_token_balance == 0) addStakeholder(msg.sender);
        
        balances[msg.sender].staked_token_balance = balances[msg.sender].staked_token_balance.add(_stake);
        balances[msg.sender].available_token_balance = balances[msg.sender].available_token_balance.sub(_stake);
        balances[msg.sender].stake_timestamp = block.timestamp;
        
        total_stake_count += _stake;
        emit _Stake( msg.sender, _stake);
    }


    /**
     * @notice A method for a stakeholder to Unstake
     * @param _stake            The size of the stake to be unstaked and sent back to the user.
     */
    function Unstake(uint256 _stake)
        public
    {
        require(moderators[msg.sender].on == false, "must not be a moderator for current epoch to unstake"); //must not be moderator for current period
        uint256 staked_amount = balances[msg.sender].staked_token_balance;
        require(staked_amount >= _stake, "not enough available_amount to unstake _stake");
        require(token.transfer(msg.sender, _stake));
        balances[msg.sender].staked_token_balance = balances[msg.sender].staked_token_balance.sub(_stake);
        
        if(balances[msg.sender].staked_token_balance == 0) removeStakeholder(msg.sender);
        total_stake_count -= _stake ;
        emit _UnStake( msg.sender, _stake);
    }
    
    /**
     * @notice A method for a stakeholder to Unstake
     * @param _stake            The size of the stake to be unstaked and sent back to the user's balance.
     */
    function UnstakeToBalance(uint256 _stake)
        public
    {
        require(moderators[msg.sender].on == false, "must not be a moderator for current epoch to unstake"); //must not be moderator for current period
        uint256 staked_amount = balances[msg.sender].staked_token_balance;
        require(staked_amount >= _stake, "not enough available_amount to unstake _stake");
        balances[msg.sender].staked_token_balance = balances[msg.sender].staked_token_balance.sub(_stake);
        balances[msg.sender].available_token_balance = balances[msg.sender].available_token_balance.add(_stake);
        
        if(balances[msg.sender].staked_token_balance == 0) removeStakeholder(msg.sender);
        total_stake_count -= _stake ;
        emit _UnStake( msg.sender, _stake);
    }
    
    /**
     * @notice Trigger the new epoch, redistribute current epoch xdai balance
     * calculate all rewards (staking, owners rewards, holders rewards) and distribute all owners staking rewards
     * rewards the user that trigger this function with TRIGGER_REWARD xDai
     */
    function TriggerNextEpochAndRewards() 
       public
    {
        require(block.timestamp >= last_epoch_date + EPOCH_DURATION, "too early to trigger : epoch not over");
        
        //--------  distribute current xdai balance
        last_epoch_rewards = last_epoch_remaining_rewards_ + current_xdai_balance.mul(90).div(100.0); //put the holders balance in the epoch rewards
        moderation_xdai_balance += current_xdai_balance.mul(5).div(100.0);
        uint256 surplus_mod = 0;
        if(moderation_xdai_balance > MODERATION_POOL_CAP) {
            surplus_mod = moderation_xdai_balance - MODERATION_POOL_CAP;
            moderation_xdai_balance = MODERATION_POOL_CAP;
        }
        governance_xdai_balance += surplus_mod + current_xdai_balance.mul(5).div(100.0);
        //--------  set new epoch variables holding the rewards of the epoch that just ended
        last_epoch_remaining_rewards_ = last_epoch_rewards;
        last_epoch_total_stake_ = total_stake_count;
        current_xdai_balance = 0; //reset holder balance for the new/current Epoch
        
        //--------  increment counter and start new epoch
        epoch = epoch + 1; // next epoch
        last_epoch_date = block.timestamp; // epoch start date
        
        //--------  distribute token rewards for all block owners at the end of the epoch
        uint256 total_token_rewards = 0;
        if (used_block_count>0){
            uint256 owners_token_rewards = (owners_rewards_pool*1/100).div(used_block_count);
            for (uint256 i = 0; i < BLOCK_COUNT; i += 1){
                if(Blocks[i].on){
                    address block_owner = Blocks[i].owner;
                    uint256 block_owner_token_rewards_ = owners_token_rewards; //divide rewards equally among all block owners
                    //-------- distribute token rewards
                    balances[block_owner].available_token_balance += block_owner_token_rewards_;
                    total_token_rewards += block_owner_token_rewards_;
                }
            }
            owners_rewards_pool = owners_rewards_pool.sub(total_token_rewards); //update block owners reward pool current amount
        }
        
        //--------  moderation governance votes : trigger a round of vote blocking rewards, to juge moderation work and fight againt abuses
        if(active_moderators_.length>0) moderation_gov_vote_in_progress = true; //if there has been any takedown, start moderation_approval_vote;
        emit _NewEpoch(epoch, total_token_rewards, last_epoch_date);
    }
    
    
    /**
     * @dev Distribute the rewards (staking rewards AND xDai rewards) to all the stakeholder who staked for the last epoch
     *      if user hasn't staked for at least EPOCH_DURATION, he can't be elligble for rewards.
     *      Remaining rewards that are not distributed are redistributed on the next epoch rewards
     */
    function DistributeRewards()
        public
    {
        require(moderation_gov_vote_in_progress == false, "moderation_gov_vote  in progress, no distribution possible until vote is over"); // can't distribute rewards before the end of the moderation approbation vote.
        require(last_collect_epoch < epoch && epoch >= 0, "already distributed for this epoch");
        
        // compute current staking reward amount for this epoch
        uint256 total_xdai_rewards = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            
            address sh = stakeholders[s];
            if( (block.timestamp).sub(balances[sh].stake_timestamp) >= REQUIRED_STAKE_DURATION){
                
                uint256 userStake = balances[sh].staked_token_balance;
                uint256 user_xdai_rewards_ = last_epoch_rewards.mul(userStake).div(last_epoch_total_stake_);
                balances[sh].last_collected_epoch = epoch;
                //-------- distribute xDai rewards
                balances[sh].available_xdai_balance += user_xdai_rewards_;
                last_epoch_remaining_rewards_ = last_epoch_remaining_rewards_.sub(user_xdai_rewards_);
                
                total_xdai_rewards += user_xdai_rewards_;
            }
        }
        
        last_collect_timestamp = block.timestamp;
        last_collect_epoch = epoch;
        emit  _RewardsDistributed(total_xdai_rewards);
    }
    
    
    /**
     * @dev Distribute the rewards (staking rewards AND xDai rewards) to all the stakeholder who staked for the last epoch
     *      if user hasn't staked for at least EPOCH_DURATION, he can't be elligble for rewards.
     *      Remaining rewards that are not distributed are redistributed on the next epoch rewards
     */
    function ClaimRewards()
        public
    {
        require(isStakeholder(msg.sender), "sender must be a stakeholder to claim any rewards");
        require(moderation_gov_vote_in_progress == false, "moderation_gov_vote  in progress, no distribution possible until vote is over");
        require((block.timestamp).sub(balances[msg.sender].stake_timestamp) >= REQUIRED_STAKE_DURATION, "sender must have staked long enough to claim rewards");
        require(balances[msg.sender].last_collected_epoch < epoch, "sender has already collected rewards for this epoch");
        require(balances[msg.sender].last_epoch_voted < epoch, "sender has voted");

        uint256 userStake = balances[msg.sender].staked_token_balance;
        uint256 user_xdai_rewards_ = last_epoch_rewards.mul(userStake).div(last_epoch_total_stake_);
        balances[msg.sender].last_collected_epoch = epoch;
        //-------- distribute xDai rewards
        balances[msg.sender].available_xdai_balance += user_xdai_rewards_;
        last_epoch_remaining_rewards_ = last_epoch_remaining_rewards_.sub(user_xdai_rewards_);
           
    
        last_collect_timestamp = block.timestamp;
        last_collect_epoch = epoch;
        emit _UserClaimedRewards(user_xdai_rewards_);
    }
    
    
    // ================================================
    //                  MODERATION METHODS
    // ================================================
    
    
    /**
     * @dev Takedown a block that break the rules of the platform, get a reward
     * @param block_id      ID of the block to takedown
     * @param reason        string to include the reason of the takedown
     */
    function TakeDown(uint block_id, string memory reason)
        public
    {
        require(balances[msg.sender].staked_token_balance >= MODERATION_MIN_STAKE && Blocks[block_id].on && Blocks[block_id].status != BlockStatus.DELETED, "not enough stake or invalid block_id for a takedown");
        Blocks[block_id].status = BlockStatus.DELETED;
        Blocks[block_id].image_hash = "deleted";
        Blocks[block_id].xdai_value = INITAL_BLOCK_PRICE; //reset block price
        Blocks[block_id].on = false;
        used_block_count -= 1;
        if(!moderators[msg.sender].on){ // first takedown during current epoch
            moderators[msg.sender].locked_rewards = MODERATION_REWARD;
            moderators[msg.sender].status = ModeratorStatus.OK;
            moderators[msg.sender].on = true;
            active_moderators_.push(msg.sender);
        }else{
            moderators[msg.sender].locked_rewards = moderators[msg.sender].locked_rewards + MODERATION_REWARD;
        }
        moderators[msg.sender].takedown_block_ids.push(block_id);
        moderators[msg.sender].last_takedown_date = block.timestamp;
        emit _TakeDown(msg.sender, block_id, reason);
    }
    
    /**
     * @dev Takedown multiple blocks
     * @param block_id_      IDs of the block to takedown
     * @param reason        strings to include the reasons of the takedown
     */
    function TakeDowns(uint[] memory block_id_, string memory reason)
        public
    {
        for (uint i = 0; i < block_id_.length; i++) {
            uint block_id = block_id_[i];
            require(balances[msg.sender].staked_token_balance >= MODERATION_MIN_STAKE && Blocks[block_id].on && Blocks[block_id].status != BlockStatus.DELETED);
            Blocks[block_id].status = BlockStatus.DELETED;
            Blocks[block_id].image_hash = "deleted";
            Blocks[block_id].xdai_value = INITAL_BLOCK_PRICE; //reset block price
            Blocks[block_id].on = false;
            used_block_count -= 1;
            if(!moderators[msg.sender].on){ // first takedown during current epoch
                moderators[msg.sender].locked_rewards = MODERATION_REWARD;
                moderators[msg.sender].status = ModeratorStatus.OK;
                moderators[msg.sender].on = true;
                active_moderators_.push(msg.sender);
            }else{
                moderators[msg.sender].locked_rewards = moderators[msg.sender].locked_rewards + MODERATION_REWARD;
            }
            moderators[msg.sender].takedown_block_ids.push(block_id);
            moderators[msg.sender].last_takedown_date = block.timestamp;
            emit _TakeDown(msg.sender, block_id, reason);
        }
    }
    
    
    /**
    @dev Vote in the current moderation approval vote, initated by/for the governance of the system
    @param decision_active_moderators_      Array of decisions, to approve (true) or punish (false) the moderator at a given index
    */
    function ModApprobationVote(bool[] memory  decision_active_moderators_) public {
        require(balances[msg.sender].last_epoch_voted<epoch, "already voted on moderators during this epoch");
        // make sure the array lengths are all the same
        require(active_moderators_.length == decision_active_moderators_.length, "active_moderators_ and decision_active_moderators_ arrays must be of same length");
        for (uint i = 0; i < active_moderators_.length; i++) {
            address a = active_moderators_[i];
            require(moderators[a].on,"provided address isn't an active moderator in the last epoch");
            if(decision_active_moderators_[i]){
                moderators[a].votes_ok = moderators[a].votes_ok + balances[msg.sender].staked_token_balance;
            }
            else{
                moderators[a].votes_slash = moderators[a].votes_slash + balances[msg.sender].staked_token_balance;
            }
            require(a != msg.sender); // moderators can't vote on themselves
        }
        balances[msg.sender].last_epoch_voted = balances[msg.sender].last_epoch_voted +1;
        moderation_governance_votes_amount = moderation_governance_votes_amount + balances[msg.sender].staked_token_balance;
        emit _moderatorsApprobationVote();
    }
    
    
    /**
    @dev Closes the current moderation approval vote, execute decisions for each moderator
    */
    function CloseModApprobationVote() public {
        // make sure the array lengths are all the same
        require(moderation_gov_vote_in_progress, "no moderation_gov_vote in progress");
        require(moderation_governance_votes_amount >= MODERATION_APPROB_MIN_VOTE_COUNT,"not enough vote (moderation_governance_votes_amount musst be >= MODERATION_APPROB_MIN_VOTE_COUNT)");
        
        for (uint i = 0; i < active_moderators_.length; i++) {
            address a = active_moderators_[i];
            if( moderators[a].votes_slash / (moderators[a].votes_ok+moderators[a].votes_slash) * 100 >= MODERATION_QUORUM_SLASHING ){ // if more than 70% votes in favor of slashing current moderator
                uint nb_takedowns = moderators[msg.sender].takedown_block_ids.length;
                uint256 slashed_token_amount = nb_takedowns*MODERATION_SLASHING_AMOUNT;
                if (balances[a].staked_token_balance < slashed_token_amount){
                    slashed_token_amount = balances[a].staked_token_balance; //max of his stake
                }
                total_stake_count -= slashed_token_amount;
                balances[a].staked_token_balance -= slashed_token_amount; // SLASHING
                owners_rewards_pool += slashed_token_amount;
                moderators[a].status = ModeratorStatus.SLASHED;
                delete moderators[a].takedown_block_ids;    
            }
            else{
                if(moderators[a].locked_rewards >= moderation_xdai_balance){
                    balances[a].available_token_balance = balances[a].available_token_balance + moderators[a].locked_rewards;
                    moderation_xdai_balance -= moderators[a].locked_rewards;
                }
                else{
                    balances[a].available_token_balance = balances[a].available_token_balance + moderation_xdai_balance;
                    moderation_xdai_balance = 0;
                }
            }
            moderators[a].on = false;
            moderators[a].votes_ok = 0;
            moderators[a].votes_slash = 0;
            moderators[a].locked_rewards = 0;    
        }
        
        delete active_moderators_;
        moderation_governance_votes_amount = 0;
        moderation_gov_vote_in_progress = false;
        emit _moderatorsApprobationVoteClose();
    }
   
    // ================================================
    //                  GOVERNANCE METHODS
    // ================================================

    /**
    @dev    Initiates a proposal to modify the system parameters, with configured parameters at proposalID emitted by ProposalCreated event
    @param params_                  Array of parameters index, like [0,3,7], to be modified in the proposal
    @param new_proposed_values_     arerray of proposed values for the parameters quoted in params_, make sure you are using the right unit as it depend on the parameter
    @return proposalID             ID of this new submitted proposal to the governance
    */
    function StartProposal(uint[] memory params_, uint256[] memory new_proposed_values_) public returns (uint proposalID) {
        require(balances[msg.sender].staked_token_balance >= MIN_STAKE_TO_START_PROPOSAL && ((block.timestamp).sub(balances[msg.sender].stake_timestamp) >= EPOCH_DURATION)
        , "need more staked tokens, or staked for longer than 1 epoch");
        require(params_.length == new_proposed_values_.length, "params_ and new_proposed_values_ arrays must have same length");
        require(new_proposed_values_.length>0, "proposal must no be empty");
        
        proposalNonce = proposalNonce + 1;
        
        uint voteEndDate = block.timestamp.add(STANDARD_VOTE_DURATION);
        
        proposals[proposalNonce] =  Proposal({
            status: ProposalStatus.VOTE,
            author: msg.sender,
            params_: params_,
            proposed_values_: new_proposed_values_,
            voteEndDate: voteEndDate,
            votesFor: 0,
            votesAgainst: 0,
            voters: new address[](0)
        });

        emit _ProposalCreated(proposalNonce, voteEndDate, msg.sender);
        return proposalNonce;
    }
    
    
    /**
    @dev    Propose a new receiving address for any transfer from the governance pool, that will be pushed in the proposed_xdai_funds_receiver array
    @param proposed_receiver        proposed address to send funds to, to finance decentralized storage, hosting, etc.
    @return receiverID             ID/index of this new receiver address in the public proposed_xdai_funds_receiver array
    */
    function ProposeFundsReceiver(address proposed_receiver) public  returns (uint receiverID) {
        require(balances[msg.sender].staked_token_balance >= MIN_STAKE_TO_START_PROPOSAL && (last_epoch_date.sub(balances[msg.sender].stake_timestamp) >= EPOCH_DURATION)
        , "need more staked tokens, or staked for longer than 1 epoch");
        require(proposed_receiver != address(0), "proposed_receiver must no be empty address");
        
        receiverNonce = receiverNonce + 1;
        proposed_xdai_funds_receiver.push(proposed_receiver);
        
        return receiverNonce;
    }
    
    
    /**
    @notice Commits vote on a given proposal
    @param decision             user decision (true or false), wether to accept or reject the proposal _proposalID
    */
    function VoteOnProposal(uint _proposalID, bool decision) public {
        require(votePeriodActive(_proposalID), "votePeriod is passed for _proposalID");
        require(_proposalID != 0,"_proposalID must be >0");
        require(proposals[_proposalID].didVote[msg.sender] == false, "sender has already voted on this proposal");
        // make sure msg.sender has enough voting rights & has staked long enough
        require(balances[msg.sender].staked_token_balance >= MIN_VOTE_STAKED_REQUIRED,"sender must have >= MIN_VOTE_STAKED_REQUIRED staked");      
        require((block.timestamp).sub(balances[msg.sender].stake_timestamp) >= EPOCH_DURATION ,"sender must have staked more than 1 epoch to be able to participate in governance votings");      

        // vote for or against
        if (decision == true) {
            proposals[_proposalID].votesFor += balances[msg.sender].staked_token_balance;
        } else {
            proposals[_proposalID].votesAgainst += balances[msg.sender].staked_token_balance;
        }

        if(proposals[_proposalID].didVote[msg.sender] == false){
            proposals[_proposalID].voters.push(msg.sender);
            proposals[_proposalID].didVote[msg.sender] = true;
        }
        emit _Voted(_proposalID, balances[msg.sender].staked_token_balance, msg.sender);
    }

    /**
    @notice  Commits votes on an array of proposals
    @param _proposalIDs         Array of integer identifiers associated with target proposals
    @param _decisions           Array of user decisions (true or false), wether to accept or reject the proposal _proposalID
    */
    function VoteOnProposals(uint[] calldata  _proposalIDs, bool[] memory _decisions) external {
        // make sure the array lengths are all the same
        require(_proposalIDs.length == _decisions.length, "input arrays must be same length");
        
        // loop through arrays, committing each individual vote values
        for (uint i = 0; i < _proposalIDs.length; i++) {
            VoteOnProposal(_proposalIDs[i], _decisions[i]);
        }
    }

    /**
    @notice Trigger the validation of a proposal; if the proposal has ended. 
    If the requirements are valid, params will be modified accordingly to the proposed values of the proposal
    @param _proposalID          Integer identifier associated with target proposal to validate, whether it's a passed or refused proposal
    */
    function ValidateProposal(uint _proposalID) public {
        require(proposalEnded(_proposalID),"proposal _proposalID hasn't ended yet");
        if( isPassed(_proposalID) ){ // execute proposal if accepted
            proposals[_proposalID].status = ProposalStatus.PASSED;
            uint[] memory params_index = proposals[_proposalID].params_;        
            uint256[] memory proposed_values = proposals[_proposalID].proposed_values_;
            for (uint i = 0; i < params_index.length; i++) {
                uint256 proposed_val = proposed_values[i];
                if(params_index[i] == 0){
                    if(proposed_val >=1000){        //  Id:0 = MODERATION_MIN_STAKE, unit is 10^15
                        MODERATION_MIN_STAKE = proposed_val * (10**15);
                    } 
                }
                if(params_index[i]==1){
                    if(proposed_val>=100){          //  Id:1 = MODERATION_SLASHING_AMOUNT, unit is 10^15
                        MODERATION_SLASHING_AMOUNT = proposed_val * (10**15);
                    } 
                }
                if(params_index[i]==2){
                    if(proposed_val >=1000){        //  Id:2 = MODERATION_APPROB_MIN_VOTE_COUNT, unit is 10^15
                        MODERATION_APPROB_MIN_VOTE_COUNT = proposed_val * (10**15);
                    } 
                }
                if(params_index[i]==3){
                    if(proposed_val >=100){         //  Id:3 = MIN_STAKE_TO_START_PROPOSAL, unit is 10^15
                        MIN_STAKE_TO_START_PROPOSAL = proposed_val * (10**15);
                    } 
                }
                if(params_index[i]==4){
                    if(proposed_val >=10000){       //  Id:4 = MIN_VOTE_TOTAL_AMOUNT, unit is 10^15
                        MIN_VOTE_TOTAL_AMOUNT = proposed_val * (10**15);
                    } 
                }
                if(params_index[i]==5){
                    if(proposed_val >=100){         //  Id:5 = MODERATION_POOL_CAP, unit is 10^15
                        MODERATION_POOL_CAP = proposed_val * (10**15);
                    }
                }
                if(params_index[i]==6){             //  Id:6 = MODERATION_REWARD, unit is 10^15
                    if(proposed_val >=0 && proposed_val<100 finney){
                        MODERATION_REWARD = proposed_val * (10**15);
                    } 
                }
                if(params_index[i]==7){             //  Id:7 = INITAL_BLOCK_PRICE, unit is 10^15
                    if(proposed_val >=5){
                        INITAL_BLOCK_PRICE = proposed_val * (10**15);
                    }
                }
                if(params_index[i]==8){             //  Id:8 = STANDARD_VOTE_DURATION, unit is 1
                    if(proposed_val>= 1 days){
                        STANDARD_VOTE_DURATION = proposed_val;
                    }
                }
                if(params_index[i]==9){             //  Id:9 = EPOCH_DURATION, unit is 1
                    if(proposed_val>=1 days && proposed_val<=14 days){
                        EPOCH_DURATION = proposed_val;
                    }
                }
                if(params_index[i]==10){             //  Id:10 = VOTE_QUORUM_TO_PASS_PERCENT, unit is 1
                    if(proposed_val>50 && proposed_val<=90){
                        VOTE_QUORUM_TO_PASS_PERCENT = proposed_val;
                    }
                }
                if(params_index[i]==11){             //  Id:11 = MIN_VOTE_STAKED_PERCENT, unit is 1
                    if(proposed_val>=5 && proposed_val<=90){
                        MIN_VOTE_STAKED_PERCENT = proposed_val;
                    } 
                }
                if(params_index[i]==12){             //  Id:12 = BIDDING_PRICE_RATIO_PERCENT, unit is 1
                    if(proposed_val>=100 && proposed_val<150){
                        BIDDING_PRICE_RATIO_PERCENT = proposed_val;
                    }
                }
                if(params_index[i]==13){             //  Id:13 = MODERATION_QUORUM_SLASHING, unit is 1 percent
                    if(proposed_val>=50 && proposed_val<=90){
                        MODERATION_QUORUM_SLASHING = proposed_val;
                    } 
                }
                if(params_index[i]==14){
                    if(proposed_val >=0 && proposed_val<=500){         //  Id:14 = MIN_VOTE_STAKED_REQUIRED, unit is 10^15
                        MIN_VOTE_STAKED_REQUIRED = proposed_val * (10**15);
                    }
                }
                if(params_index[i]==15){
                    if(proposed_val >= 1 days){         //  Id:15 = REQUIRED_STAKE_DURATION, unit is 1
                        REQUIRED_STAKE_DURATION = proposed_val;
                    }
                }
                //  Id:20 = SETUP NEW GOVERNANCE_FUNDS_RECEIVER_ADDRESS, unit an index (1)
                if(params_index[i]==20){            //      Setup new GOVERNANCE_FUNDS_RECEIVER_ADDRESS with an index in proposed_val
                    if(proposed_val>=0 && proposed_val<proposed_xdai_funds_receiver.length){
                        GOVERNANCE_FUNDS_RECEIVER_ADDRESS = payable(proposed_xdai_funds_receiver[proposed_val]);
                    } 
                }                                   //  Id:21 = TRANSFER TO SETUP GOVERNANCE_FUNDS_RECEIVER_ADDRESS, unit is 10^15
                if(params_index[i]==21){            //      Transfer proposed_val amount of xDai from governance_xdai_balance to GOVERNANCE_FUNDS_RECEIVER_ADDRESS
                    uint256 transfer_amount = proposed_val * (10**15);
                    if(governance_xdai_balance >= transfer_amount){
                        GOVERNANCE_FUNDS_RECEIVER_ADDRESS.transfer(transfer_amount);
                         governance_xdai_balance -= transfer_amount;
                    }
                }
                
            }
        }
        emit _ProposalClosed(_proposalID, isPassed(_proposalID));
    }

    /**
    @notice Determines if proposal has passed
    @dev Check if votesFor out of totalVotes exceeds votesQuorum
    @param _proposalID      Integer identifier associated with target proposal
    */
    function isPassed(uint _proposalID)  public view returns (bool passed) {
        Proposal memory proposal = proposals[_proposalID];
        uint256 token_vote_count = proposals[_proposalID].votesFor + proposals[_proposalID].votesAgainst;
        return  (((proposal.votesFor*100.0).div(proposal.votesFor + proposal.votesAgainst))  >= VOTE_QUORUM_TO_PASS_PERCENT)
                && (token_vote_count >= MIN_VOTE_TOTAL_AMOUNT) 
                && ((token_vote_count*100.0).div(total_stake_count)>= MIN_VOTE_STAKED_PERCENT);
    }
    
    
    /**
    @notice Determines if proposal is over
    @param _proposalID      Integer identifier associated with the target proposal
    @return ended           Boolean indication of whether proposaling period is over
    */
    function proposalEnded(uint _proposalID) public view returns (bool ended) {
        require(proposalExists(_proposalID),"_proposalID does not exist");
        return isExpired(proposals[_proposalID].voteEndDate);
    }

    /**
    @notice Checks if the voting period is still active for the specified proposal
    @dev Checks isExpired for the specified proposal's voteEndDate
    @param _proposalID      Integer identifier associated with target proposal
    @return active          Boolean indication of if voting is still open for target proposal
    */
    function votePeriodActive(uint _proposalID) public view returns (bool active) {
        require(proposalExists(_proposalID),"_proposalID does not exist");
        return !isExpired(proposals[_proposalID].voteEndDate);
    }

    /**
    @dev Checks if user has committed for specified proposal
    @param _voter           Address of user to check against
    @param _proposalID      Integer identifier associated with target proposal
    @return committed       Boolean indication of whether user has committed
    */
    function didVote(address _voter, uint _proposalID) public view returns (bool committed) {
        require(proposalExists(_proposalID),"_proposalID does not exist");
        return proposals[_proposalID].didVote[_voter];
    }

    /**
    @dev Checks if a proposal exists
    @param _proposalID      The proposalID whose existance is to be evaluated.
    @return exists          Boolean Indicates whether a proposal exists for the provided proposalID
    */
    function proposalExists(uint _proposalID) public view returns  (bool exists) {
        return (_proposalID != 0 && _proposalID <= proposalNonce);
    }
    
    // ================================================
    //                  FUNDS RELATED METHODS
    // ================================================

    /**
    @dev Deposit Tokens into available token balance
    @param tokens       amount of tokens to be transfered, to be called after approve() on the token contract
    */
    function DepositTokens(uint tokens) public {
        require(token.balanceOf(msg.sender) >= tokens, "token balance too low");
        // add the deposited tokens into existing balance 
        balances[msg.sender].available_token_balance += tokens;
        
        // transfer the tokens from the sender to this contract
        require(token.transferFrom(msg.sender, address(this), tokens), "token transfer failed");
    }
   
    /**
    @dev Deposit Tokens into the reward pool for the system. Used once at the beginning of the system by the developper team
    @param rewards_for_block_owners        amount of tokens to be transfered to the block-owners-rewards pool
    */
    function DepositRewardsPool(uint256 rewards_for_block_owners) external {
        require(token.balanceOf(msg.sender) >= rewards_for_block_owners, "token balance too low");
        // add the deposited tokens into existing balance 
        owners_rewards_pool += rewards_for_block_owners;
        // transfer the tokens from the sender to this contract
        require(token.transferFrom(msg.sender, address(this), rewards_for_block_owners), "token transfer failed");
    }
    
    /**
    @notice Withdraw _numTokens ERC20 tokens from the voting contract, revoking these voting rights
    @param _numTokens       The number of ERC20 tokens desired in exchange for voting rights
    */
    function WithdrawTokens(uint _numTokens) public{
        require(balances[msg.sender].available_token_balance >= _numTokens, "available_token_balance too low");
        balances[msg.sender].available_token_balance -= _numTokens;
        require(token.transfer(msg.sender, _numTokens), "token transfer failed");
    }
    
    /**
    @notice Withdraw _numTokens ERC20 tokens from the voting contract, revoking these voting rights
    @param _amount The number of ERC20 tokens desired in exchange for voting rights
    */
    function WithdrawxDai(uint _amount) public{
        require(balances[msg.sender].available_xdai_balance >= _amount, "available_xdai_balance too low");
        balances[msg.sender].available_xdai_balance -= _amount;
        msg.sender.transfer(_amount);
    }
    
    // ================================================
    //                  STAKEHOLDERS METHODS
    // ================================================

     /**
     * @notice A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function StakedAmountOf(address _stakeholder)
        internal
        view
        returns(uint256)
    {
        return balances[_stakeholder].staked_token_balance;
    }
    
    // ---------- STAKEHOLDERS ----------

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address  The address to verify.
     * @return bool, uint256    Boolean indicator if the address is currently a stakeholder, 
     *                          and if so its position in the stakeholders array.
     */
    function isStakeholderIndex(address _address)
        internal
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param _address  The address to verify.
     * @return bool     Boolean indicator wheter the adress is currently stakeholder
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return true;
        }
        return false;
    }
    /**
     * @notice A method to add a stakeholder.
     * @param _stakeholder  The stakeholder to add.
     */
    function addStakeholder(address _stakeholder)
        private
    {
        (bool _isStakeholder, ) = isStakeholderIndex(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
     * @notice A method to remove a stakeholder.
     * @param _stakeholder  The stakeholder to remove.
     */
    function removeStakeholder(address _stakeholder)
        private
    {
        (bool _isStakeholder, uint256 s) = isStakeholderIndex(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        } 
    }
    
    /**
    @dev Checks if an expiration date has been reached
    @param _terminationDate         Integer timestamp of date to compare current timestamp with
    @return expired                 Boolean indication of whether the terminationDate has passed
    */
    function isExpired(uint _terminationDate)  public view returns (bool expired) {
        return (block.timestamp > _terminationDate);
    }
    
    /**
    @dev Generates an identifier which associates a user and a proposal together
    @param _proposalID          Integer identifier associated with target proposal
    @return UUID                Hash which is unique & deterministic from _user and _proposalID
    */
    function attrUUID(address _user, uint _proposalID) internal pure returns (bytes32 UUID) {
        return keccak256(abi.encodePacked(_user, _proposalID));
    }
}