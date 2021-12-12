/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEX{
	function sellTokens(address tokenseller, uint256 amount) external payable;
}

/**
* @notice This is a development token that we use to learn how to code solidity 
* and what BEP-20 interface requires
*/
contract MYTK1 is IERC20{
	/* Ownable */
	// _owner is the owner of the Token
    address private _owner;

    /**
    * Event OwnershipTransferred is used to log that a ownership change of the token has occured
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * Modifier
    * We create our own function modifier called onlyOwner, it will Require the current owner to be 
    * the same as msg.sender
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: only owner can call this function");
        // This _; is not a TYPO, It is important for the compiler;
        _;
    }

    /**
    * @notice owner() returns the currently assigned owner of the Token
    * 
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
    * @notice transferOwnership will assign the {newOwner} as owner
    *
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    /**
    * @notice _transferOwnership will assign the {newOwner} as owner
    *
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
	/* Ownable */
	
	/* Stakeable */
	/**
     * @notice
     * A stake struct is used to represent the way we store stakes, 
     * A Stake will contain the users address, the amount staked and a timestamp, 
     * Since which is when the stake was made
     */
    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
        // This claimable field is new and used to tell how big of a reward is currently available
        uint256 claimable;
    }
    /**
    * @notice Stakeholder is a staker that has active stakes
     */
    struct Stakeholder{
        address user;
        Stake[] address_stakes;
    }
	
     /**
     * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */ 
     struct StakingSummary{
         uint256 total_amount;
         Stake[] stakes;
     }

    /**
    * @notice 
    *   This is a array where we store all Stakes that are performed on the Contract
    *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
    */
    Stakeholder[] internal stakeholders;
    /**
    * @notice 
    * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;
    /**
    * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
     event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    /**
     * @notice
      rewardPerHour is 2500 because it is used to represent 0.0004, since we only use integer numbers
      This will give users 0.04% reward for each staked token / H
	  that makes it 350% APR
     */
    uint256 internal rewardPerHour = 2500;

    /**
    * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256){
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex; 
    }

    /**
    * @notice
    * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    * StakeID 
    */
    function _stake(uint256 _amount) internal{
        // Simple check so that user does not stake 0 
        require(_amount > 0, "Cannot stake nothing");

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
	        // push a newly created Stake with the current block timestamp.
			stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp,0));
        }else{
			/* WildCat - 2021-12-07 */
			/* Modded Stakes Allow only 1 stake index */
			/* If user already has stake then calculate stake reward, 
			* add (new stake amount + reward) to existing stake amount */
			Stake memory current_stake = stakeholders[index].address_stakes[0];
			uint256 reward = calculateStakeReward(current_stake);
			_amount = _amount + current_stake.amount + reward;
			stakeholders[index].address_stakes[0].amount = _amount;
			// Reset timer of stake
			stakeholders[index].address_stakes[0].since = block.timestamp;
			/* Modded Stakes Allow only 1 stake index */
		}
		
        // Emit an event that the stake has occured
        emit Staked(msg.sender, _amount, index,timestamp);
    }

    /**
      * @notice
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
	  * maximum unclaimed stake rewards limited to 50% of total stake amount
     */
      function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
          // First calculate how long the stake has been active
          // Use current seconds since epoch - the seconds since epoch the stake was made
          // The output will be duration in SECONDS ,
          // We will reward the user 0.04% per Hour So thats 0.04% per 3600 seconds
          // the alghoritm is  seconds = block.timestamp - stake seconds (block.timestap - _stake.since)
          // hours = Seconds / 3600 (seconds /3600) 3600 is an variable in Solidity names hours
          // we then multiply each token by the hours staked , then divide by the rewardPerHour rate 
          uint256 reward = (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / rewardPerHour;
		  
		  /* limit max unclaimed stake amount to 50% of total stakes */
		  /* This is done to prevent stake reward getting accumulated forever */
		  if( reward > (_current_stake.amount / 2) ){ reward = (_current_stake.amount / 2); }
		  
		  return reward;
      }

    /**
     * @notice
     * withdrawStake takes no arguments and will return all staked amount + unclaimed rewards
     * Will return the amount to MINT onto the account
     * Will also calculateStakeReward and reset timer
    */
	function _withdrawStake() internal returns(uint256){
		// Grab user_index which is the index to use to grab the Stake[]
		uint256 user_index = stakes[msg.sender];
		Stake memory current_stake = stakeholders[user_index].address_stakes[0];
		require(current_stake.amount > 0, "Staking: Cannot withdraw more than you have staked");

		// Calculate available Reward first before we start modifying data
		uint256 reward = calculateStakeReward(current_stake);
		// Remove by subtracting the money unstaked
		uint256 amount = current_stake.amount;
		uint256 newBal = _balances[msg.sender] + amount + reward;
		require( newBal <= maxAddressBalance(msg.sender), "Maximum wallet balance limit reached");
		require( _totalSupply + newBal <= _SupplyLimit, "Maximum supply limit reached");

		current_stake.amount = current_stake.amount - amount;
		// If stake is empty, 0, then remove it from the array of stakes
		if(current_stake.amount == 0){
			delete stakeholders[user_index].address_stakes[0];
		}else {
			// If not empty then replace the value of it
			stakeholders[user_index].address_stakes[0].amount = current_stake.amount;
			// Reset timer of stake
			stakeholders[user_index].address_stakes[0].since = block.timestamp;    
		}

		return amount+reward;
	}

	/**
	 * @notice
	 * _claimStakeReward used to claim stake rewads for current user
	 */
	function _claimStakeReward() internal returns(uint256){
		uint256 user_index = stakes[msg.sender];
		Stake memory current_stake = stakeholders[user_index].address_stakes[0];
		require(current_stake.amount > 0, "Staking: No stakes found");
		uint256 reward = calculateStakeReward(current_stake);
		
		uint256 newBal = _balances[msg.sender] + reward;
		require( newBal <= maxAddressBalance(msg.sender), "Maximum wallet balance limit reached");
		require( _totalSupply + newBal <= _SupplyLimit, "Maximum supply limit reached");
		
		if(current_stake.amount == 0){
			delete stakeholders[user_index].address_stakes[0];
		}else {
			stakeholders[user_index].address_stakes[0].amount = current_stake.amount;
			stakeholders[user_index].address_stakes[0].since = block.timestamp;    
		}
		return reward;
	}
	
     /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function hasStake(address _staker) public view returns(StakingSummary memory){
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount; 
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }
       // Assign calculate amount to summary
       summary.total_amount = totalStakeAmount;
        return summary;
    }
	/* Stakeable */
	
	/* BonusStakeable */
	struct BonusStake{
		address user;
		uint256 amount;
		uint256 since;
		uint256 claimable;
	}

	struct BonusStakeholder{
		address user;
		BonusStake[] address_stakes;
	}

	struct BonusStakingSummary{
		uint256 total_amount;
		BonusStake[] bonusstakes;
	}
	BonusStakeholder[] internal bonusstakeholders;

	mapping(address => uint256) internal bonusstakes;

	event BonusStaked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

	uint256 internal rewardBonusPerHour = 2500;

	function _addBonusStakeholder(address staker) internal returns (uint256){
		bonusstakeholders.push();
		uint256 userIndex = bonusstakeholders.length - 1;
		bonusstakeholders[userIndex].user = staker;
		bonusstakes[staker] = userIndex;
		return userIndex; 
	}

	function _bonusstake(address bonusstaker, uint256 _amount) internal{
		require(_amount > 0, "Cannot stake nothing");
		uint256 index = bonusstakes[bonusstaker];
		uint256 timestamp = block.timestamp;
		if(index == 0){
			index = _addBonusStakeholder(bonusstaker);
			bonusstakeholders[index].address_stakes.push(BonusStake(bonusstaker, _amount, timestamp,0));
		}else{
			BonusStake memory current_stake = bonusstakeholders[index].address_stakes[0];
			uint256 reward = calculateBonusStakeReward(current_stake);
			_amount = _amount + current_stake.amount + reward;
			bonusstakeholders[index].address_stakes[0].amount = _amount;
			// Reset timer of stake
			bonusstakeholders[index].address_stakes[0].since = block.timestamp;
		}
		
		emit BonusStaked(msg.sender, _amount, index,timestamp);
	}

	function calculateBonusStakeReward(BonusStake memory _current_stake) internal view returns(uint256){
		uint256 reward = (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / rewardBonusPerHour;
		if( reward > (_current_stake.amount / 2) ){ reward = (_current_stake.amount / 2); }
		return reward;
	}

	function _claimBonusStakeReward() internal returns(uint256){
		uint256 user_index = bonusstakes[msg.sender];
		BonusStake memory current_stake = bonusstakeholders[user_index].address_stakes[0];
		require(current_stake.amount >= 0, "BonusStaking: No Bonus stakes found");
		uint256 reward = calculateBonusStakeReward(current_stake);
		
		uint256 newBal = _balances[msg.sender] + reward;
		require( newBal <= maxAddressBalance(msg.sender), "Maximum wallet balance limit reached");
		require( _totalSupply + newBal <= _SupplyLimit, "Maximum supply limit reached");
		
		if(current_stake.amount == 0){
			delete bonusstakeholders[user_index].address_stakes[0];
		}else {
			bonusstakeholders[user_index].address_stakes[0].amount = current_stake.amount;
			bonusstakeholders[user_index].address_stakes[0].since = block.timestamp;    
		}
		return reward;
	}
	
	function hasBonusStake(address _staker) public view returns(BonusStakingSummary memory){
		uint256 totalStakeAmount; 
		BonusStakingSummary memory summary = BonusStakingSummary(0, bonusstakeholders[bonusstakes[_staker]].address_stakes);
		for (uint256 s = 0; s < summary.bonusstakes.length; s += 1){
			uint256 availableReward = calculateBonusStakeReward(summary.bonusstakes[s]);
			summary.bonusstakes[s].claimable = availableReward;
			totalStakeAmount = totalStakeAmount+summary.bonusstakes[s].amount;
		}
		summary.total_amount = totalStakeAmount;
		return summary;
	}
	/* BonusStakeable */
	
	/**
	* @notice Our Tokens required variables that are needed to operate everything
	*/
	uint private _totalSupply;
	uint private _minSupply;

	/* Will try to maintain this _SupplyLimit with burns */
	uint private _SupplyLimit;
	
	uint8 private _decimals;
	string private _symbol;
	string private _name;

	/**
	* @notice _balances is a mapping that contains a address as KEY 
	* and the balance of the address as the value
	*/
	mapping (address => uint256) private _balances;

	/* Keep track of addresses that recieve bonus */
	mapping (address => uint256) private _firstBuyBonus;
	/* Contract Start time */
	uint256 startdate = block.timestamp;
	/* ico period - 30 days from token launch */
	uint256 private _icoperiod = 30*24*60*60;
	/* End date for presale bonus */
	uint256 enddate = startdate + _icoperiod;
	
	/* Development Fund */
	address private _devFund = 0xEa19d7F16f85e963721816383484b8DFd9c4F834;
	
	/* Charity Fund Address */
	address private _charityFund = 0x4F8E8E9fF55971794Eb1EB9941c5d196C248fdfb;
	
	event DistrubuteCharityStakeRewads(uint256 timestamp, uint256 value);
	
	/* Charity fund amount will be put into Bonus staking forever */
	/* Each month the stake rewards will be distributed among registered NGOs */
	uint256 _charityFundAmount;
	address[] private _ngos;
	
	
	/* custom Token Manager contact address */
	address private _tokenManager;

	/**
	* @notice _allowances is used to manage and control allownace
	* An allowance is the right to use another accounts balance, or part of it
	*/
	mapping (address => mapping (address => uint256)) private _allowances;

	/**
	* @notice constructor will be triggered when we create the Smart contract
	* _name = name of the token
	* _short_symbol = Short Symbol name for the token
	* token_decimals = The decimal precision of the Token, defaults 18
	* _totalSupply is how much Tokens there are totally 
	*/
	constructor(){
		_name = "MTK6";
		_symbol = "MTK6";
		_decimals = 18;

		/* Initial Supply 100 Million */
		_totalSupply = 100000000 * 10 ** _decimals;
		_minSupply = _totalSupply;

		/* 100 Billion Max Supply LIMIT */
		_SupplyLimit = 100000000000 * 10 ** _decimals;
		
		// Add all the tokens created to the creator of the token
		_balances[msg.sender] = _totalSupply;

		_owner = msg.sender;
		
		/* Ownable */
		_owner = msg.sender;
		emit OwnershipTransferred(address(0), _owner);
		/* Ownable */

		/* Stakeable */
		// This push is needed so we avoid index 0 causing bug of index-1
		stakeholders.push();
		/* Stakeable */

		/* BonusStakeable */
		bonusstakeholders.push();
		/* BonusStakeable */
		
		/* Charity Fund 1 Million */
		_charityFundAmount = 1000000 * 10 ** _decimals;
		_bonusstake(_charityFund, _charityFundAmount);
		
		_ngos.push(address(0));
		
		// Emit an Transfer event to notify the blockchain that an Transfer has occured
		emit Transfer(address(0), msg.sender, _totalSupply);
	}
	
	/* Get ICO Dates */
	function getIcoStartDate() external view returns (uint256){
		return startdate;
	}
	
	function getIcoEndDate() external view returns (uint256){
		return enddate;
	}
	
	/**
	* @notice decimals will return the number of decimal precision the Token is deployed with
	*/
	function decimals() external view returns (uint8) {
		return _decimals;
	}
	/**
	* @notice symbol will return the Token's symbol 
	*/
	function symbol() external view returns (string memory){
		return _symbol;
	}
	/**
	* @notice name will return the Token's symbol 
	*/
	function name() external view returns (string memory){
		return _name;
	}
	/**
	* @notice totalSupply will return the tokens total supply of tokens
	*/
	function totalSupply() external override view returns (uint256){
		return _totalSupply;
	}
	/**
	* @notice balanceOf will return the account balance for the given account
	*/
	function balanceOf(address account) external override view returns (uint256) {
		return _balances[account];
	}
	
	event Mint(address indexed from, address indexed to, uint256 value);
	/**
	* @notice _mint will create tokens on the address inputted and then increase the total supply
	*
	* It will also emit an Transfer event, with sender set to zero address (adress(0))
	* 
	* Requires that the address that is recieveing the tokens is not zero address
	*/
	function _mint(address account, uint256 amount) internal {
		require(account != address(0), "Cannot mint to zero address");

		require(_totalSupply <= _SupplyLimit, "Max supply limt reached");
		
		require( _balances[account] + amount <= maxAddressBalance(account), "Address not allowed to hold more than 1% of total supply");
		
		// Increase total supply
		_totalSupply = _totalSupply + (amount);
		// Add amount to the account balance using the balance mapping
		_balances[account] = _balances[account] + amount;
		// Emit our event to log the action
		emit Mint(address(0), account, amount);
	}
	
	event Burn(address indexed from, address indexed to, uint256 value);
	/**
	* @notice _burn will destroy tokens from an address inputted and then decrease total supply
	* An Transfer event will emit with receiever set to zero address
	* 
	* Requires 
	* - Account cannot be zero
	* - Account balance has to be bigger or equal to amount
	*/
	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "Cannot burn from zero address");
		require(_balances[account] >= amount, "Cannot burn more than the account owns");
		require( (_totalSupply - amount) >= _minSupply, "Minimum supply limit reached");
		
		// Remove the amount from the account balance
		_balances[account] = _balances[account] - amount;
		// Decrease totalSupply
		_totalSupply = _totalSupply - amount;
		
		// Emit event, use zero address as reciever
		emit Burn(account, address(0), amount);
	}
	
	/**
	* @notice burn is used to destroy tokens on an address
	* 
	* See {_burn}
	* Requires
	*   - msg.sender must be the token owner
	*
	*/
	function burn(address account, uint256 amount) public onlyOwner returns(bool) {
		_burn(account, amount);
		return true;
	}
	
	/**
	* @notice mint is used to create tokens and assign them to msg.sender
	* 
	* See {_mint}
	* Requires
	*   - msg.sender must be the token owner
	*
	*/
	function mint(address account, uint256 amount) public onlyOwner returns(bool){
		_mint(account, amount);
		return true;
	}
	
	/**
	* @notice transfer is used to transfer funds from the sender to the recipient
	* This function is only callable from outside the contract. For internal usage see 
	* _transfer
	*
	* Requires
	* - Caller cannot be zero
	* - Caller must have a balance = or bigger than amount
	*
	*/
	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}
	
	/* Rescue wrong recieved funds */
	receive () external payable {
		payable(_owner).transfer(msg.value);
	}
	
	/* Useful in case wrong tokens are recieved */
	function retrieveTokens(address _token, address recipient, uint256 amount) public onlyOwner {
		_retrieveTokens(_token, recipient, amount);
	}
	
	function _retrieveTokens(address _token, address recipient, uint256 amount) internal {
		require(amount > 0, "amount should be greater than zero");
		IERC20 erctoken = IERC20(_token);
		erctoken.transfer(recipient, amount);
	}
	/* Rescue wrong recieved funds */

	/**
	* @notice _transfer is used for internal transfers
	* Auto Burn 2% added - Will burn 2% from senders balance on each transaction
	* Dev Fund - 1% From sender balance will be transferred to Dev Funds
	* Events
	* - Transfer
	* 
	* Requires
	*  - Sender cannot be zero
	*  - recipient cannot be zero 
	*  - sender balance most be = or bigger than amount
	*/
	function _transfer(address sender, address recipient, uint256 amount) internal {
		require(sender != address(0), "Transfer from zero address");
		require(recipient != address(0), "Transfer to zero address");
		
		require( _balances[recipient] + amount <= maxAddressBalance(recipient), "Address not allowed to hold more than 1% of total supply");
		/*
		require(_balances[sender] >= amount, "Cant transfer more than your account holds");

		_balances[sender] = _balances[sender] - amount;
		_balances[recipient] = _balances[recipient] + amount;
		*/
		/* 2% burn */
		uint256 burnAmt = (amount / 100) * 2;
		
		/* Prevent total supply going too low */
		if( (_totalSupply - burnAmt) < _minSupply ){
			if( _totalSupply > _minSupply){
				burnAmt = _totalSupply - _minSupply;
			}else{
				burnAmt = 0;
			}
		}
		/* 1% Dev Fund */
		uint256 devFund = (amount / 100) * 1;
		
		if( sender == _owner){
			devFund = 0;
			burnAmt = 0;
		}
		require( _balances[sender] >= (burnAmt + devFund + amount), "Cannot send and burn more than the account owns");

		// Remove the amount from the account balance
		_balances[sender] = _balances[sender] - (burnAmt + devFund + amount);
		
		_balances[recipient] = _balances[recipient] + amount;
		_balances[_devFund] = _balances[_devFund] + devFund;
		
		if( (_firstBuyBonus[recipient]) == 0 && !(sender == _owner) ){
			if( enddate > block.timestamp ){
				/* Set first transaction bonus and put that amount to stake forever */
				/* Bonus will be given only if buying from ICO Manager */
				if( _tokenManager != address(0x0) ){
					if( (sender == _tokenManager) || (sender == _owner) ){
						_firstBuyBonus[recipient] = amount;
						_bonusstake(recipient, amount);
					}
				}
			}
		}
		
		/* Check if user selling token on DEX */
		if( _tokenManager != address(0x0) ){
			/* check if tokens sent to DEX */
			if( recipient == _tokenManager ){
				IDEX dex = IDEX(_tokenManager);
				dex.sellTokens(sender, amount);
			}
		}
		if( burnAmt > 0){
			_burn(sender, burnAmt);
		}
		emit Transfer(sender, recipient, amount);
	}
	
	/**
	* @notice allowance is used view how much allowance an spender has
	*/
	function allowance(address owner1, address spender) external override view returns(uint256){
		return _allowances[owner1][spender];
	}
	
	/**
	* @notice approve will use the senders address and allow the spender to use X amount of tokens on his behalf
	*/
	function approve(address spender, uint256 amount) external override returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	/**
	* @notice _approve is used to add a new Spender to a Owners account
	* 
	* Events
	*   - {Approval}
	* 
	* Requires
	*   - owner and spender cannot be zero address
	*/
	function _approve(address owner1, address spender, uint256 amount) internal {
		require(owner1 != address(0), "Approve cannot be done from zero address");
		require(spender != address(0), "Approve cannot be to zero address");
		// Set the allowance of the spender address at the Owner mapping over accounts to the amount
		_allowances[owner1][spender] = amount;

		emit Approval(owner1,spender,amount);
	}

	/**
	* @notice transferFrom is uesd to transfer Tokens from a Accounts allowance
	* Spender address should be the token holder
	*
	* Requires
	*   - The caller must have a allowance = or bigger than the amount spending
	*/
	function transferFrom(address spender, address recipient, uint256 amount) external override returns(bool){
		require( _balances[recipient] + amount <= maxAddressBalance(recipient), "Address not allowed to hold more than 1% of total supply");
		
		// Make sure spender is allowed the amount 
		require(_allowances[spender][msg.sender] >= amount, "You cannot spend that much on this account");
		// Transfer first
		_transfer(spender, recipient, amount);
		// Reduce current allowance so a user cannot respend
		_approve(spender, msg.sender, _allowances[spender][msg.sender] - amount);
		return true;
	}
	
	/**
	* @notice increaseAllowance
	* Adds allowance to a account from the function caller address
	*/
	function increaseAllowance(address spender, uint256 amount) public returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender]+amount);
		return true;
	}
	
	/**
	* @notice decreaseAllowance
	* Decrease the allowance on the account inputted from the caller address
	*/
	function decreaseAllowance(address spender, uint256 amount) public returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender]-amount);
		return true;
	}

	/**
	* Add functionality like burn to the _stake afunction
	*
	*/
	function stake(uint256 _amount) public {
		_addStake(_amount);
	}
	
	function _addStake(uint256 _amount) internal {
		// Make sure staker actually is good for it
		require(_amount <= _balances[msg.sender], "Cannot stake more than you own");

		require( (_totalSupply - _amount) >= _minSupply, "Minimum Supply level reached.");

		_stake(_amount);
		// Burn the amount of tokens on the sender
		_burn(msg.sender, _amount);
	}

	/**
	* @notice withdrawStake is used to withdraw stakes from the account holder
	*/
	function withdrawStake() public {
		/* amount_to_mint will be total staked amount + unclaimed rewards */
		uint256 amount_to_mint = _withdrawStake();
		// Return staked tokens to user
		_mint(msg.sender, amount_to_mint);
	}

	function withdrawStakeReward() public {
		uint256 amount_to_mint = _claimStakeReward();
		// Return staked tokens from bonus to user
		_mint(msg.sender, amount_to_mint);
	}

	function withdrawBonusStakeReward() public {
		uint256 amount_to_mint = _claimBonusStakeReward();
		// Return staked tokens from bonus to user
		_mint(msg.sender, amount_to_mint);
	}
	
	/*Change devFund Address */
	function setdevFundAaddress(address newDF) public onlyOwner{
		_devFund = newDF;
	}
	
	/*Change Charity Fund Address */
	function setCharityFundAaddress(address newCF) public onlyOwner{
		_charityFund = newCF;
	}
	
	/* SEt Token Maanager Contract Address */
	function setManagerAaddress(address newDEX) public onlyOwner{
		_tokenManager = newDEX;
	}
	/* SEt Token Maanager Contract Address */
	
	function maxAddressBalance(address account) public view returns(uint256){
		/* Restrict maximum Address balance to 1% of total supply */
		if( (account == _owner) || (account == _tokenManager) || (account == _devFund) ){
			return _SupplyLimit;
		}
		return ( _totalSupply / 100 );
	}
	
	/* Charity Manage */
	function addngo(address daddr) public onlyOwner{
		_ngos.push(daddr);
	}
	
    function getNGO(uint256 ngoid) public view returns (address){
		require( ngoid > 0, "That id doesnot exist" );
        return _ngos[ngoid];
    }
	
    function getNGOlist() public view returns (address[] memory){
        return _ngos;
    }
	
	function distributeCharityStakeRewards() public onlyOwner{
		_distributeCharityStakeRewards();
	}
	
	function _distributeCharityStakeRewards() internal{
		uint256 user_index = bonusstakes[_charityFund];
		BonusStake memory current_stake = bonusstakeholders[user_index].address_stakes[0];
		require(current_stake.amount >= 0, "BonusStaking: No Bonus stakes found");
		uint256 reward = calculateBonusStakeReward(current_stake);
		if(reward > 1000){
			bonusstakeholders[user_index].address_stakes[0].amount = current_stake.amount;
			bonusstakeholders[user_index].address_stakes[0].since = block.timestamp;    
			_mint(msg.sender, reward);
			
			uint256 ct = _ngos.length - 1;
			uint256 amt = 0;
			if(ct>0){
				uint256 amountPerNgo = reward / ct;
				for(uint256 i=1;i<ct;i++){
					_balances[_charityFund] -= amountPerNgo;
					_balances[_ngos[i]] += amountPerNgo;
					amt += amountPerNgo;
				}
				
				emit DistrubuteCharityStakeRewads(block.timestamp, amt);
			}
		}
	}
	/* Charity Manage */
}