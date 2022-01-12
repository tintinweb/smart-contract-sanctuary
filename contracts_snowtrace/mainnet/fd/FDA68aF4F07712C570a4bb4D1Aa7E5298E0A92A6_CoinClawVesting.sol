// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./IERC20Vesting.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

interface Ownable{
	function owner() external view returns (address);
}

interface IERC20Decimals{
	function decimals() external view returns (uint8);
}


contract CoinClawVesting is IERC20, IERC20Vesting, ReentrancyGuard{
	// Date-related constants for sanity-checking dates to reject obvious erroneous inputs
	// and conversions from seconds to days and years that are more or less leap year-aware.
	// SECONDS_PER_DAY: 86400
	uint32 private constant TEN_YEARS_DAYS = 3652;																	/* Includes leap years (though it doesn't really matter) */
	uint32 private constant THOUSAND_YEARS_DAYS = 365243;														
	uint32 private constant JAN_1_2000_SECONDS = 946684800;													/* Saturday, January 1, 2000 0:00:00 (GMT) (see https://www.epochconverter.com/) */
	uint32 private constant JAN_1_2000_DAYS = JAN_1_2000_SECONDS / 86400;						/* 10957*/
	uint32 private constant JAN_1_3000_DAYS = JAN_1_2000_DAYS + THOUSAND_YEARS_DAYS;/* 376200*/

	/*
	 * Name of the vesting token
	 */
	string private _name;

	/*
	 * Ticker symbol of the vesting token
	 */
	string private _symbol;

	/*
	 * ERC20 Token contract
	 */
	address private _token;


	/*
	 * Grantors that are allowed for scheduling.
	 */
	mapping(address => bool) private _grantors;


	/*
	 * VestingID counter
	 */
	uint256 private _nextVestingID;

	/*
	 * Vesting schedules indexed with beneficiary wallets.
	 *	{beneficiary => {ID => Schedule}}
	 */
	mapping(address => mapping(uint256 => Schedule)) private _vesting;


	/*
	 * List of vesting IDs for a given beneficiary
	 *	{beneficiary => [ID]}
	 */
	mapping(address => uint256[]) private _vestingIDs;

	/*
	 * Number of total tokens waiting to be granted.
	 */
	uint256 private _pendingTotal;


	/*
	 * Number of tokens waiting to be granted by this vesting contract respect to each grantor
	 */
	mapping(address => uint256) private _pending;


	/*
	 * Number of tokens collected by beneficiaries
	 */
	mapping(uint256 => uint256) private _granted;


	/*
	 * Vesting Constructor
	 */
	constructor(address token, string memory vestingName, string memory vestingSymbol) {
		require(token != address(0), "Vesting: E00: token address cannot be zero.");
		_token  = token;
		_name   = vestingName;
		_symbol = vestingSymbol;
	}



	////////////////////////////////////////////////////////////////////////
	//                              VESTING                               //
	////////////////////////////////////////////////////////////////////////

	///////////////
	//  utility  //
	///////////////
	function _generateVestingID() private returns(uint256 ID){
		_nextVestingID = _nextVestingID + 1;
		return _nextVestingID;
	}

	function min(uint256 a, uint256 b) private pure returns(uint256){
		if(a < b){
			return a;
		}
		return b;
	}

	function _calculate_token_grant(Schedule storage vesting, uint256 effectiveDay) private view returns(uint256){
		// ensure that cliff duration is passed.
		if((vesting.start + vesting.cliff) > effectiveDay){
			return 0;
		}

		uint256 D = vesting.duration;																				// vesting timeframe
		uint256 C = D / vesting.interval;																		// Total number of releases
		uint256 N = vesting.amount / C;																			// Volume for each release
		uint256 P = effectiveDay - (vesting.start + vesting.cliff);				  // Elapsed days since start
		uint256 I = (P - P%vesting.interval) / vesting.interval;						// Number of releases after cliff
		uint256 V = I * N;																									// Total number of vested tokens

		// There is no tokens to release. Just return. 
		if(_granted[vesting.ID] >= V){
			return 0;
		}

		// clamp vested & remaining tokens 
		// to findout normalized volume of the grant
		uint256 L = vesting.amount - _granted[vesting.ID];		// Number of not collected tokens
		uint256 R = V - _granted[vesting.ID];								// Number of tokens that should be collected
		return min(L, R);
	}

	function _onPreTokenTransfer(address grantor, uint256 amount) internal returns(uint256){
		_pendingTotal = _pendingTotal - amount;
		_pending[grantor] = _pending[grantor] - amount;

		return amount;
	}

	function _collectTokens(Schedule storage vesting, uint256 amount) private returns(uint256){

		uint256 tobeTransfered = _calculate_token_grant(vesting, today());

		// clamp amount of tokens to be transfered.
		if(amount > 0 && tobeTransfered > amount){
			tobeTransfered = amount;
		}

		_onPreTokenTransfer(vesting.grantor, tobeTransfered);

		// set granted
		_granted[vesting.ID] = _granted[vesting.ID] + tobeTransfered;

		// ensure that total grant is less than total vesting amount
		require(vesting.amount >= _granted[vesting.ID], "Vesting: E01: Invalid transaction!");

		bool ok = IERC20(_token).transfer(vesting.beneficiary, tobeTransfered);
		if(ok == false){
			return 0;
		}

		return tobeTransfered;
	}

	function _refundTokens(address grantor, uint256 amount) internal returns (uint256){
		require(grantor != address(0), "Vesting: E02: Invalid vesting address.");

		if(amount == 0){
			return 0;
		}

		bool ok = IERC20(_token).transfer(grantor, amount);
		if( ok == false){
			return 0;
		}

		return _onPreTokenTransfer(grantor, amount);
	}

	function _refund(Schedule storage vesting) internal returns(uint256){
		return _refundTokens(vesting.grantor, vesting.amount - _granted[vesting.ID]);
	}

	function _addVestingSchedule(Schedule memory vesting) internal{
		require(_vestingIDs[vesting.beneficiary].length < 7, "Vesting: E03: Maximum limit for vesting schedules allowed per each beneficiary is reached.");

		_vesting[vesting.beneficiary][vesting.ID] = vesting;
		_vestingIDs[vesting.beneficiary].push(vesting.ID);

		/**
		 * Check if token contract has deposited enough balance for this vesting contract
		 */
		_pendingTotal             = _pendingTotal + vesting.amount;
		_pending[vesting.grantor] = _pending[vesting.grantor] + vesting.amount;
		require(IERC20(_token).balanceOf(address(this)) >= _pendingTotal, "Vesting: E04: Insufficent balance. Please deposit ERC20 tokens to vesting contract.");

		emit VestingScheduled(
			vesting.ID,
			vesting.grantor, 
			vesting.beneficiary,
			vesting.amount,
			vesting.start,
			vesting.cliff,
			vesting.duration,
			vesting.interval,
			vesting.revokable
		);
	}
	///////////////
	//  utility  //
	///////////////


	/**
	 * @dev return day number of the current day since EPOCH 
	 */
	function today() public view returns (uint32 dayNumber) {
		return uint32(block.timestamp / 86400);

	}
	/**
	* Returns owner of this vesting contract
	* Access: Anyone 
	*/
	function getNextVestingID() external view returns (uint256) {
		return _nextVestingID;
	}

	/*
	 * Allows a grantor to add vesting schedules
	 * Access: Token Owner
	 * Origin: Account
	 *
	 * @param grantor: Address of the grantor (wallet or contract).
	 */
	function allowGrantor(address grantor) external nonReentrant override returns(bool){
		require(msg.sender == Ownable(_token).owner(), "Vesting: E05: Authorization denied.");
		require(grantor != address(0), "Vesting: E06: Grantor address cannot be zero.");

		_grantors[grantor] = true;

		return true;
	}

	/*
	 * Disallows a grantor to add vesting schedules
	 * Access: Token Owner
	 * Origin: Account
	 *
	 * @param grantor: Address of the grantor (wallet or contract).
	 */
	function disallowGrantor(address grantor) external nonReentrant override returns(bool){
		require(msg.sender == Ownable(_token).owner(), "Vesting: E07: Authorization denied.");
		require(grantor != address(0), "Vesting: E08: Grantor address cannot be zero.");

		_grantors[grantor] = false;
		return true;
	}


	/**
	 * Get number of tokens waiting to be vested.
	 * Access: Grantor
	 */
	function getPending() public view override returns(uint256){
		return _pending[msg.sender];
	}

	/**
	 * Get number of free tokens available for scheduling
	 * Access: Grantor
	 */
	function getFreeTokens() external view override returns(uint256){
		require(_grantors[msg.sender] == true, "Vesting: E09: Authorization denied.");
		return IERC20(_token).balanceOf(address(this)) - _pendingTotal;
	}
	
	

	/*
	 * Returns vesting schedules and grant details for a given beneficiary.
	 * Access: Anyone
	 * Origin: Account, Contract
	 *
	 * @param beneficiary: Wallet address of the vested token collector.
	 * @param effectiveDay: A day that summary will be generated from that point of view.
	 */
	function getSummary(address beneficiary, uint32 effectiveDay) external view override returns(Summary[] memory){
		uint8 i = 0;
		uint256[] storage ids = _vestingIDs[beneficiary];

		Summary[] memory summary = new Summary[](ids.length);

		if(effectiveDay == 0){
			effectiveDay = today();
		}

		uint256 pending = 0;

		for (i = 0; i < ids.length; i++) {
			Schedule storage vesting = _vesting[beneficiary][ids[i]];

			if(vesting.status == Status.ACTIVE){
				pending = vesting.amount - _granted[ids[i]];
			}
			else{
				pending = 0;
			}

			summary[i] = Summary({
				schedule: vesting,
				granted:  _granted[ids[i]],
				pending:  pending,
				collect:  _calculate_token_grant(vesting, effectiveDay)
			});
		}

		return summary;
	}



	/*
	 * Setup vesting schedule for given ERC20 contract to grant tokens to given beneficiary. 
	 *	Note: Grantor should setup an allowance for this contract to be able to transfer tokens from his/her wallet.
	 * Access: Grantor
	 * Origin: Account, Contract
	 *
	 * @param beneficiary: Wallet address that tokens will be transfered to.
	 * @param amount: Total number of tokens to be vested in the future.
	 * @param start: Start day of the vesting schedule, in days since the UNIX epoch
	 *   (start of day). The startDay may be given as a date in the future or in the past, going as far
	 *   back as year 2000.
	 * @param duration: Duration of the vesting schedule, with respect to the grant start day, in days.
	 * @param cliff: Duration of the cliff, with respect to the vesting schedule start day, in days.
	 * @param interval: Number of days between any two collections.
	 * @param revokable: True if the schedule can be revoked (i.e. was a gift) or false if it cannot
	 *   be revoked (i.e. tokens were purchased).
	 */
	function schedule(
		address beneficiary,
		uint256 amount,
		uint32 start,
		uint32 cliff,
		uint32 duration,
		uint32 interval,
		bool revokable
	) external nonReentrant override returns(uint256 ID){
		require(beneficiary						!= address(0), "Vesting: E10: Beneficiary address cannot be zero.");
		require(_grantors[msg.sender]	== true,       "Vesting: E11: Authorization denied.");

		// Check for valid start day 
		require(start >= JAN_1_2000_DAYS && start < JAN_1_3000_DAYS, "Vesting: E12: Invalid start day");

		// validate vesting schedule timeframe 
		require(
			duration > 0 && duration <= TEN_YEARS_DAYS
			&& cliff >= 0
			&& interval >= 1
			&& interval <= duration,
			"Vesting: E13: Invalid vesting schedule"
		);

		// validate interval value
		require(
			duration % interval == 0,
			"Vesting: E14: Duration should be divisable by Interval."
		);

		// generate next vesting ID
		ID = _generateVestingID();

		_addVestingSchedule(Schedule(
			ID,
			msg.sender,
			beneficiary,
			amount,
			start,
			cliff,
			duration,
			interval,
			revokable,
			Status.ACTIVE
		));

		return ID;
	}

	/*
	 * Beneficiaries can collect pending tokens which are granted by transaction date.
	 * Access: Beneficiary
	 * Origin: Account, Contract
	 *
	 * @param ID: ID of the vesting schedule. 
	 */
	function collect(uint256 ID) external nonReentrant override returns(uint256){
		// validate there is a vesting schedule with given ID and that schedule belongs to the sender.
		Schedule storage vesting = _vesting[msg.sender][ID];
		require(vesting.ID == ID, "Vesting: E15: Authorization denied.");
		require(vesting.beneficiary == msg.sender, "Vesting: E16: Authorization denied.");

		// validate schedule status
		require(vesting.status == Status.ACTIVE, "Vesting: E17: Authorization denied.");

		// transfer tokens to beneficiary
		uint256 transfered = _collectTokens(vesting, 0);
		if(transfered == 0){
			return 0;
		}

		// emit event
		emit TokenCollected(vesting.beneficiary, vesting.ID, transfered);

		// set completed if all vested tokens are collected.
		if(_granted[vesting.ID] == vesting.amount){
			vesting.status = Status.DONE;
			emit VestingDone(vesting.beneficiary, vesting.ID);
		}

		return transfered;
	}

	/*
	 * Grantors can push tokens to beneficiaries.
	 * Access: Grantor
	 * Origin: Account, Contract
	 *
	 * @param beneficiary: Target wallet address that tokens will be pushed to.
	 * @param ID: ID of the vesting schedule. 
	 * @param amount: amount of tokens to release to beneficary wallet. (Used to clamp the vested tokens)
	 */
	function release(address beneficiary, uint256 ID, uint256 amount) external nonReentrant override returns(uint256){
		require(_grantors[msg.sender] == true, "Vesting: E18: Authorization denied.");

		// find the vesting schedule
		Schedule storage vesting = _vesting[beneficiary][ID];
		require(vesting.ID          == ID,            "Vesting: E19: Authorization denied.");
		require(vesting.status      == Status.ACTIVE, "Vesting: E20: Authorization denied.");
		require(vesting.grantor     == msg.sender,    "Vesting: E21: Authorization denied.");
		require(vesting.beneficiary == beneficiary,   "Vesting: E22: Authorization denied.");

		// transfer tokens to beneficiary
		uint256 transfered = _collectTokens(vesting, amount);
		if(transfered > 0){
			emit TokenReleased(msg.sender, vesting.beneficiary, vesting.ID, transfered);
		}

		return transfered;
	}

	/*
	 * Grantors can revoke vesting schedule if schedule is revokable.
	 * Access: Grantor
	 * Origin: Account, Contract
	 *
	 * @param beneficiary: Wallet address of the vested token collector.
	 * @param ID: ID of the vesting schedule. 
	 *	(Please note: Any beneficiary can have more than one vesting schedule for a given ERC20 token.) 
	 */
	function revoke(address beneficiary, uint256 ID) external override returns(uint256){
		require(beneficiary != address(0), "Vesting: E23: beneficiary address cannot be zero.");

		// findout vesting schedule to be revoked
		Schedule storage vesting = _vesting[beneficiary][ID];
		require(vesting.ID == ID, "Vesting: E24: Authorization denied.");
		require(vesting.status == Status.ACTIVE, "Vesting: E25: Authorization denied.");

		// authorize
		require(msg.sender == vesting.grantor, "Vesting: E26: Authorization denied.");


		// see if revokable
		if(vesting.revokable == false){
			return 0;
		}

		// Transfer any vested amount of non-transfered tokens to the beneficiary wallet.
		uint256 collected = _collectTokens(vesting, 0);

		// refund any remaining tokens back to grantor
		uint256 refunded = _refund(vesting);

		// set status
		vesting.status = Status.REVOKED;

		emit VestingRevoked(vesting.beneficiary, vesting.ID, refunded, collected);

		return collected;
	}

	/*
	 * Beneficiaries can abandon vesting schedule. Before abandoning all vested amount is released. 
	 * Access: Beneficiary
	 * Origin: Account
	 *
	 * @param ID: ID of the vesting schedule. 
	 *	(Please note: Any beneficiary can have more than one vesting schedule for a given ERC20 token.) 
	 */
	function abandon(uint256 ID) external nonReentrant override returns(uint256){
		require(tx.origin == msg.sender, "Vesting: E27: Only codeless beneficiaries can abondon vesting schedules.");

		// findout vesting schedule to be abandoned.
		Schedule storage vesting = _vesting[msg.sender][ID];
		require(vesting.ID == ID, "Vesting: E28: Authorization denied.");
		require(vesting.status == Status.ACTIVE, "Vesting: E28: Authorization denied.");

		// authorize
		require(msg.sender == vesting.beneficiary, "Vesting: E29: Authorization denied.");


		// Transfer any vested amount of non-transfered tokens to the beneficiary wallet.
		uint256 collected = _collectTokens(vesting, 0);

		// refund any remaining tokens back to grantor
		uint256 refunded = _refund(vesting);

		// set status
		vesting.status = Status.ABANDONDED;

		// emit event
		emit VestingAbandoned(vesting.beneficiary, vesting.ID, refunded, collected);

		return collected;
	}

	/*
	* Grantors can withdraw unscheduled amount of redundantly deposited balances.
	* Access: Grantor
	* @param amount: amount of tokens to transfer to grantor's address.
	*/
	//function disburse(uint256 amount) external nonReentrant returns(uint256){
	function disburse(uint256 amount) external override returns(uint256){
		require(_grantors[msg.sender] == true, "Vesting: E30: Authorization denied.");

		uint256 refundable = min(amount, IERC20(_token).balanceOf(address(this)) - _pendingTotal);

		IERC20(_token).transfer(msg.sender, refundable);

		emit TokenDisbursed(msg.sender, refundable);

		return refundable;
	}




	////////////////////////////////////////////////////////////////////////
	//                               ERC20                                //
	////////////////////////////////////////////////////////////////////////
	/*
	 * @dev Returns the name of the token.
	 */
	function name() external view returns (string memory) {
		return _name;
	}

	/*
	 * @dev Returns ticker symbol.
	 */
	function symbol() external view returns (string memory) {
		return _symbol;
	}

	/*
	 * @dev Returns denominance of the token
	 */
	function decimals() external view returns (uint8) {
		return IERC20Decimals(_token).decimals();
	}


	/**
	 * @dev Returns the amount of pending tokens within this vesting contract 
	 * WARNING: This has nothing to do with actual ERC20 token supply!!!
	 */
	function totalSupply() external view override returns (uint256){
		return _pending[msg.sender];
	}

	/**
	 * @dev Returns the amount of unvested tokens belong to one or more schedules for an account.
	 * WARNING: This has nothing to do with actual ERC20 balance!!!
	 */
	function balanceOf(address account) external view override returns (uint256){
		uint8 i = 0;
		uint256[] storage ids = _vestingIDs[account];

		uint256 balance = 0;
		for (i = 0; i < ids.length; i++) {
			balance = balance + _vesting[account][ids[i]].amount - _granted[ids[i]];
		}
		return balance;
	}

	/**
	 * @dev This is a vesting wallet. So manual transfers are prohibited.
	 */
	function transfer(address recipient, uint256 amount) external pure override returns (bool){
		require(false, "Vesting: E31: This is a vesting wallet and manual transfers are prohibited. Your tokens are transfered to your wallet automatically. Please use ERC20 token contract to transfer tokens.");
		require(recipient != address(0));
		require(amount!= 0);
		return false;
	}

	/**
	 * @dev This is a vesting wallet. Do not use this method to read allowance.
	 */
	function allowance(address owner, address spender) external pure override returns (uint256){
		require(false, "Vesting: E32: This is a vesting wallet. Please use ERC20 token contract to query allowance.");
		require(owner != address(0));
		require(spender!= address(0));
		return 0;
	}

	/**
	 * @dev This is a vesting wallet. So manual approve is prohibited.
	 */
	function approve(address spender, uint256 amount) external pure override returns (bool){
		require(false, "Vesting: E33: This is a vesting wallet and manual approvals are prohibited. Please use ERC20 token contract to approve allowance rates.");
		require(spender!= address(0));
		require(amount != 0);
		return false;
	}

	/**
	 * @dev This is a vesting wallet. So manual transfers are prohibited.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external pure override returns (bool){
		require(false, "Vesting: E34: This is a vesting wallet and manual transfers are prohibited. Your tokens are transfered to your wallet automatically. Please use ERC20 token contract to transfer tokens.");
		require(sender != address(0));
		require(recipient!= address(0));
		require(amount != 0);
		return false;
	}
}