// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ICrowdSale.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


interface IOwnable{
	function owner() external view returns (address);
}

interface IERC20{
	/*
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC20Vesting {
	/*
	* Setup vesting schedule for given ERC20 contract to grant tokens to given beneficiary. 
	*	Note: Grantor should setup an allowance for this contract to be able to transfer tokens from his/her wallet.
	*/
	function schedule(
		address beneficiary,
		uint256 amount,
		uint32 start,
		uint32 cliff,
		uint32 duration,
		uint32 interval,
		bool revokable
	) external returns(uint256);

	/*
	 * Returns number of unschedules tokens.
	 */
	function getFreeTokens() external view returns(uint256);
	function getSender() external view returns(address);

	/*
	* Grantors can push tokens to beneficiaries.
	* Access: Grantor
	*/
	function release(address beneficiary, uint256 ID, uint256 amount) external view returns(uint256);

	/*
	* Token owners can revoke vesting schedule if schedule is revokable.
	* Access: Token Owner 
	*/
	function revoke(address beneficiary, uint256 ID) external returns(uint256);

	/*
	* Grantors can withdraw unscheduled amount of redundantly deposited balances from this vesting contract.
	* Access: Grantor
	*/
	function disburse(uint256 amount) external returns(uint256);
}

contract CrowdSale is ICrowdSale, Ownable, ReentrancyGuard{

	/*
	 * Total ether locked in the contract. (in wei)
	 *  - This value is incremented for each time when there is a Sale event 
	 *  - This value is decremented for each time when there is a Withdraw event 
	 */
	uint256 private _funds;

	/*
	 * Total erc20 tokens sold (in wei)
	 *  - This value is incremented for each time when there is a Sale event 
	 */
	uint256 private _sold;

	/*
	 * Used to inhibit contract utility until re-activation.
	 */
	bool private _paused;

	/*
	 * ERC20 Token contract
	 */
	address private _token;

	/*
	 * Vesting contract for given token
	 */
	IERC20Vesting private _vesting;

	/*
	 * Start date and time as UNIX epoch
	 */
	uint32 private _starts;

	/*
	 * End date and time as UNIX epoch
	 */
	uint32 private _ends;

	/*
	 * Price of "1*10*erc20Token.decimal()" tokens in wei 
	 */
	uint256 private _price;

	/*
	 * Maximum number of erc20 tokens that can be acquired in wei.
	 */
	uint256 private _limit;

	/*
	 * Number of tokens each account has purchased since start of the sales event. 
	 * This is useful for limiting max token capacity that one user can acquire.
	 * This won't be used if there is no limit.
	 */
	mapping(address => uint256) _capacity;

	/*
	 * Number of days that should pass after purchase day 
	 * so that vesting starts releasing tokens to the beneficiaries 
	 */
	uint32 private _cliff;


	/*
	 * Timeframe in days that all scheduled tokens will be granted within
	 */
	uint32 private _duration;

	/*
	 * Number of consecutive days that should pass for the next token release.
	 */
	uint32 private _interval;

	/*
	 * Vesting schedules are not revokable by default.
	 */
	bool private _revokable = false;


	constructor(address token, address vesting, uint32 starts, uint32 ends, uint256 price, 
							uint256 limit, uint32 cliff, uint32 duration, uint32 interval, bool revokable) {

		require(token   != address(0), "Vesting: E00: token address cannot be zero.");
		require(vesting != address(0), "Vesting: E01: vesting address cannot be zero.");

		_token     = token;
		_vesting   = IERC20Vesting(vesting);
		_starts    = starts;
		_ends      = ends;
		_price     = price;
		_cliff     = cliff;
		_duration  = duration;
		_interval  = interval;
		_revokable = revokable;

		setLimit(limit);
	}

	function getSold() external view override returns(uint256){
		return _sold;
	}

	function getFunds() external onlyOwner view override returns(uint256){
		return _funds;
	}

	/*
	 * Return start datetime as timestamp since UNIX EPOCH.
	 */
	function getStarts() external view override returns(uint32){
		return _starts;
	}

	/*
	 * Return end datetime as timestamp since UNIX EPOCH.
	 */
	function getEnds() external view override returns(uint32){
		return _ends;
	}

	/*
	 * Return unit price
	 */
	function getPrice() external view override returns(uint256){
		return _price;
	}

	/*
	 * Return max number of tokens is allowed to be purchased for each wallet.
	 */
	function getLimit() external view override returns(uint256){
		return _limit;
	}

	/*
	 * Returns amount of tokens acquired so far
	 */
	function getCapacity(address account) external view override returns(uint256){
		return _capacity[account];
	}

	/*
	 * Return vesting cliff in days 
	 */
	function getCliff() external view override returns(uint32){
		return _cliff;
	}

	/*
	 * Return vesting duration in days 
	 */
	function getDuration() external view override returns(uint32){
		return _duration;
	}

	/*
	 * Return vesting interval in days 
	 */
	function getInterval() external view override returns(uint32){
		return _interval;
	}

	/*
	 * Returns true if sales is revokable 
	 */
	function getRevokable() external view override returns(bool){
		return _revokable;
	}

	/*
	 * Sets start timestamp of the sales event (in UTC since Unix EPOCH)
	 * Access: Sales Owner
	 * Origin: Account, Contract
	 *
	 * @param starts: Unix timestamp
	 */
	function setStarts(uint32 starts) override external{
		require(msg.sender == owner(), "Sales: E02: Authorization denied.");
		require(starts < _ends, "Sales: E03: Invalid start date.");
		require(starts > block.timestamp, "Sales: E04: Invalid start date.");

		_starts = starts;
	}

	/*
	 * Sets end timestamp of the sales event (in UTC since Unix EPOCH)
	 * Access: Sales Owner
	 * Origin: Account, Contract
	 *
	 * @param ends: Unix timestamp
	 */
	function setEnds(uint32 ends) override external{
		require(msg.sender == owner(), "Sales: E05: Authorization denied.");
		require(ends > _starts, "Sales: E06: Invalid end date.");

		_ends = ends;
	}

	/*
	 * Amount of ERC20 tokens in wei that can be purchased in exchange to 1 wei.
	 * Access: Sales Owner
	 * Origin: Account, Contract
	 *
	 * @param price: price in wei 
	 */
	function setPrice(uint256 price) override external{
		require(msg.sender == owner(), "Sales: E07: Authorization denied.");

		emit PriceUpdate(msg.sender, _price, price);

		_price = price;
	}

	/*
	 * Setup maximum amount of tokens that can be acquired once a transaction
	 * Access: Sales Owner
	 * Origin: Account, Contract
	 *
	 * @param limit: max supply for each transaction 
	 */
	function setLimit(uint256 limit) override public{
		require(msg.sender == owner(), "Sales: E07: Authorization denied.");

		if(limit > 0){
			require(limit >= _price, "Sales: E15: Invalid capacity limit.");
		}

		emit LimitUpdate(msg.sender, _limit, limit);

		_limit = limit;
	}

	/*
	 * Get number of ERC20 tokens that can be purchased in exchange to given amonut of wei
	 * 
	 * Access: Sales Owner
	 * Origin: Account, Contract
	 *
	 * @param price: price in wei 
	 */
	function getOffer(uint256 amount) public view override returns(uint256){
		return amount * _price;
	}

	/*
	 * Used to inhibit contract utilities.
	 * Access: Owner
	 * 
	 * Origin: Account
	 */
	function inhibit() external onlyOwner override returns(bool){
		require(tx.origin == msg.sender, "Authorization denied.");
		if(_paused == false){
			_paused = true;
			emit Inhibition();
		}
		return _paused;
	}

	/*
	 * Used to activate contract utilities.
	 * Access: Owner
	 * 
	 * Origin: Account
	 */
	function activate() external onlyOwner override returns(bool){
		require(tx.origin == msg.sender, "Authorization denied.");
		if(_paused == true){
			_paused = false;
			emit Activation();
		}
		return _paused;
	}

	/*
	 * Used to read utilization status of the contract
	 */
	function isPaused() external view override returns(bool){
		return _paused;
	}

	function min(uint256 a, uint256 b) private pure returns(uint256){
		if(a < b){
			return a;
		}
		return b;
	}

	/*----------------------------------------- SALES ------------------------------------------*/
	/*
	 * Allows a buyer to purchase tokens and kickoff the vesting schedule.
	 * Amount of tokens to be vested is calculated in exchange with given amount of wei 
	 * Emits a Sale event
	 * 
	 * Access: Anyone
	 * Origin: Account, Contract
	 */
	function purchase() external nonReentrant payable override returns(uint256 vestingID){
		require(_paused == false, "Sales: E17: Sale event is inhibited temporarily.");

		require(msg.value > 0, "Sales: E08: Insufficent balance.");

		// check if sales event is active
		if(_starts > 0){
			require(block.timestamp >= _starts, "Sales: E09: Store is closed.");
		}
		if(_ends > 0){
			require(block.timestamp <= _ends, "Sales: E10: Store is closed.");
		}

		// check if buyer has reached the max limit
		if(_limit > 0){
			require(_capacity[msg.sender] < _limit, "Sales: E16: Purchase limit is reached. Thanks for your interest.");
		}

		// check if there is enough tokens for purchasing
		uint256 avail     = _vesting.getFreeTokens();
		uint256 requested = getOffer(msg.value);
		require(avail > 0, "Sales: E11: All tokens are sold.");

		uint256 tokens = requested;
		uint256 refund = 0;

		// clamp available token volume.
		if(requested > avail){
			tokens = avail;
			refund = (requested - avail) / _price;
		}

		// clamp allowed token volume.
		if(_limit > 0){
			uint256 allowed = min(tokens, _limit - _capacity[msg.sender]);
			refund += (tokens - allowed) / _price;
			tokens  = allowed;
		}
		_capacity[msg.sender] = _capacity[msg.sender] + tokens;

		uint32 tsStart = uint32(block.timestamp / 86400);

		// Schedule vesting process.
		vestingID = _vesting.schedule(
			msg.sender,				// beneficiary
			tokens,						// amount
			tsStart,					// start of the vesting 
			_cliff,						// cliff 
			_duration,				// duration 
			_interval,				// interval 
			_revokable				// revokable
		);

		// fund & refund
		uint256 funded;
		if(refund > 0){
			// Sales contract cannot afford to refund. Probably contract owner
			// withdrew funds before sales event is done.
			// So, just inform that sales event is done.
			require(_funds >= refund, 'Sales: E12: Please try again with lesser ether.');

			payable(msg.sender).transfer(refund);

			funded = msg.value - refund;
		}
		else{
			funded = msg.value;
		}
		_sold  = _sold + tokens;
		_funds = _funds + funded;

		emit Sale(msg.sender, tokens, refund);

		return vestingID;
	}

	/*
	 * Funds are transfered to the owner of this sales contract 
	 *
	 * Access: Owner
	 * Origin: Account
	 * @param amount: Amount of ethers to disburse from the contract
	 */
	function withdraw(uint256 amount) external nonReentrant onlyOwner override returns(uint256){
		require(amount > 0, "Sales: E13: Invalid amount.");
		require(_funds >= amount, "Sales: E14: Insufficent balance.");

		_funds = _funds - amount;

		payable(msg.sender).transfer(amount);

		emit Withdraw(msg.sender, amount);

		return amount;
	}

	/*
	 * Tokens are transfered to the owner of the token contract
	 *
	 * Access: SalesOwner
	 * Origin: Account
	 * @param amount: Amount of tokens to transfer from the contract
	 */
	function transfer(uint256 amount) external nonReentrant onlyOwner override returns(uint256){
		require(amount > 0, "Sales: E18: Invalid amount.");

		IERC20(_token).transfer(IOwnable(_token).owner(), amount);

		return amount;
	}



	function closeStore() external onlyOwner {
		selfdestruct(payable(owner()));
	}
	/*----------------------------------------- SALES ------------------------------------------*/


	/*---------------------------------------- VESTING -----------------------------------------*/
	/*
	* Sales contract can push vested tokens to beneficiary wallets.
	*/
	function release(address beneficiary, uint256 ID, uint256 amount) external onlyOwner view returns(uint256){
		return _vesting.release(beneficiary, ID, amount);
	}

	/*
	 * Sales contract can revoke revokable vesting process.
	 */
	function revoke(address beneficiary, uint256 ID) external onlyOwner returns(uint256){
		return _vesting.revoke(beneficiary, ID);
	}

	/*---------------------------------------- VESTING -----------------------------------------*/
}