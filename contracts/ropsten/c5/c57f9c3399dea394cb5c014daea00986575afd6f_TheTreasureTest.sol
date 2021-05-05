/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: NONE
pragma solidity 0.8.4;
 
/**
 *               _____ _         _____                                                
 *              |_   _| |__   __|_   _| __ ___  __ _ ___ _   _ _ __ ___               
 *                | | | '_ \ / _ \| || '__/ _ \/ _` / __| | | | '__/ _ \              
 *                | | | | | |  __/| || | |  __/ (_| \__ \ |_| | | |  __/              
 *                |_| |_| |_|\___||_||_|  \___|\__,_|___/\__,_|_|  \___|              
 *                                                                                    
 *                                                                                    
 *                  $TRSR                             thetreasure.io                  
 *                    developed by @deceloping for thetreasure.io                     
 *                                                                                    
 *                    TRSR is a BEP-20 token, an experimental coin                    
 *            with a new and innovative concept of DeFI yield generation.             
 *                    Please set slippage tolerance at least to 5%                    
 *                when you buy or sell on PancakeSwap (after listing).                
 *                      If it still doesn't work in some cases,                       
 *                          please use an even higher value.                          
 *                    developed by @deceloping for thetreasure.io                     
 *
 */



/**
 * @dev Limited interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


/**
 * @dev The main contract - the magic happens here.
 */
contract TheTreasureTest {

	// @dev ERC20 standard variables.
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


	// @dev The treasury address holding all the fees. Not controlled by this project.
	address private treasury;

	// @dev The contract/project owner and, if it's in change, the pending owner.
    address public owner;
	address public pendingOwner;

	// @dev The base price for both required paid fees for an entry and the prize.
	uint private baseNumber;
	// @dev When `baseNumber` is being changed, that change can only
	// be confirmed 24 hours after `baseNumberchangeAnnounced`.
	uint private baseNumberChangeAnnounced;
	uint private newBaseNumber;

	// @dev The blocktime between two lottery rounds in blocks.
	uint private blocktime;
	// @dev When `blocktime` is being changed, that change can only
	// be confirmed 24 hours after `blocktimeChangeAnnounced`.
	uint private blocktimeChangeAnnounced;
	uint private newBlocktime;

	// @dev Participants, participation of an address and total count of participants.
	// Participants can exist multiple times (similar to having tickets).
	mapping(uint => address) private participants;
	mapping(address => uint) private participatingCount;
	uint private totalParticipants;

	// @dev Saves the winner, the win, a bool if a lottery was won
	// and updates total win and total win of an address each new draw.
	uint private rounds;
	mapping(uint => address) private roundWinner;
	mapping(uint => uint) private roundWin;
	mapping(uint => bool) private isJackpot;
	uint private totalWon;
	mapping(address => uint) private totalWonAddress;

	// @dev Stores how much jackpot were won in a jackpot round.
	uint private jackpots;
	mapping(uint => address) private jackpotWinner;
	mapping(uint => uint) private jackpotWin;
	mapping(uint => uint) private jackpotRound;
	uint private jackpot;


	// @dev Addresses excluded from winning and paying fees.
	// Depending on the situation fees still are paid but by the address interacted with.
	mapping(address => bool) public isExcluded;
	mapping(uint => address) public toExclude;
	uint public toExcludeCount;
	uint public exclusionAnnounced;

	// @dev Amount of fees an address paid in total and temporary and ever collected fees.
	// `feesPaidTemp` will be changed once it's >= `baseNumber` and give an entry.
	mapping(address => uint) private feesPaid;
	mapping(address => uint) private feesPaidTemp;
	uint private feesPaidTotal;

	uint private _drawBlock;

	bytes32 private _drawHash;
	
	uint constant ONE_TOKEN = 10 ** 18;

    /**
     * @dev Emitted when an ownership change took place.
     */
	event OwnerChange(address indexed oldOwner, address indexed newOwner);

	/**
	 * @dev Emitted when `baseNumber` was successfully changed.
	 */
	event BaseChange(uint oldBaseNumber, uint newBaseNumber);

	/**
	 * @dev Emitted when `baseNumber` was announced to be changed.
	 */
	event BaseChangeAnnouncement(uint oldBaseNumber, uint newBaseNumber);

	/**
	 * @dev Emitted when `blocktime` was successfully changed.
	 */
	event BlocktimeChange(uint oldBlocktime, uint newBlocktime);

	/**
	 * @dev Emitted when `blocktime` was announced to be changed.
	 */
	event BlocktimeChangeAnnouncement(uint oldBlocktime, uint newBlocktime);

	/**
     * @dev Emitted when a draw is made and `receiver` won.
     */
    event Draw(address indexed receiver, uint amount);

	/**
     * @dev Emitted when `winner` won the jackpot of `amount`.
     */
    event Jackpot(address indexed winner, uint jackpot);

	/**
     * @dev Emitted when `excluded` was excluded from receiving rewards and paying fees.
     */
    event Exclude(address indexed excluded);
	
	/**
     * @dev Emitted when `excluded` is about to be excluded.
     */
    event ToExclude(address indexed excluded);
	
	/**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

	/**
     * @dev Emitted when `feeAmount` fees are paid (to `treasury`).
     */
    event TransferFees(address indexed from, uint256 feeAmount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);


	/**
     * @dev Only allows the owner to call the specific function.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "TheTreasure: Only the owner can call this function.");
        _;
    }
    
    /**
     * @dev Only allows the owner or the pending owner to call the specific function.
     */
    modifier onlyOwnerOrPending {
        require(msg.sender == owner || msg.sender == pendingOwner,
			"TheTreasure: Only the owner or pending owner can call this function."
		);
        _;
    }


	/**
	 * @dev Initializes the contract and mints the total supply to `owner_`.
	 */
    constructor() {

		// @dev Vault address - not controlled by anyone (yet).
        treasury = 0x7770000000000000000000000000000000000000;

		// @dev Project Owner address.
        owner = 0xaA2fcED70c5B8Ba28fbF8917248ae6b28f01590A;

		// @dev Set the initial and total supply to 20,000 tokens.
		// No more tokens are mined and thus no mint() function exists in this contract.
		_totalSupply = 10730 * 10 ** 18;

		// @dev Transfer the `_totalSupply` to the owner.
		_balances[owner] = _balances[owner] + _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);

		_name = "TheTreasure.io";
        _symbol = "TRSR";
        _decimals = 18;
        baseNumber = 20000000000000000; // 0.02 token
		blocktime = 20; // ~ Every minute

		// @dev Exclude the owner, Pancake Router (v2) and treasury addresses from winning and paying fees.
		// Makes sure that the users receive the tickets when interacting with those addresses.
		isExcluded[0xaA2fcED70c5B8Ba28fbF8917248ae6b28f01590A] = true;
		emit Exclude(0xaA2fcED70c5B8Ba28fbF8917248ae6b28f01590A);

		isExcluded[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
		emit Exclude(0x10ED43C718714eb63d5aA57B78B54704E256024E);

		isExcluded[0x7770000000000000000000000000000000000000] = true;
		emit Exclude(0x7770000000000000000000000000000000000000);
    }
    
    
	/**
     * @dev Runs a draw.
	 * The draw is only done atleast one block after the block it was defined to happen.
	 * This is an attempt to prevent as much prediction and therefore win possibilities as possible.
     */
	function _draw() internal {
		// @dev Do a draw when `_drawBlock` is not zero, the draw is not in the same block `_drawBlock` was set,
		// and the treasury has atleast a balance of `baseNumber` + `jackpot` tokens.
		address treasury_ = treasury;
		uint treasuryBalance_ = _balances[treasury_];
		uint drawBlock_ = _drawBlock;
		uint baseNumber_ = baseNumber;

		if(drawBlock_ != 0 && drawBlock_ < block.number && treasuryBalance_ >= baseNumber_ + jackpot) {
			_drawHash = keccak256(abi.encodePacked(_drawHash, blockhash(drawBlock_)));
			uint winNumber_ = uint(_drawHash) % (totalParticipants - 1);
			address winner_ = participants[winNumber_];

			// @dev Only pays to the winner if the winner is not excluded and is not the zero address.
			// If the winner is excluded, it does another draw attempt 2 blocks after.
			if(!isExcluded[winner_] && winner_ != address(0)) {
				uint win_ = baseNumber_ / 2;
				uint otherHalf_ = baseNumber_ - win_;
				uint wonJackpot_ = uint(_drawHash) % 100;
				
				// @dev 5% chance of winning the jackpot
				if(wonJackpot_ >= 42 && wonJackpot_ < 47) {
					win_ = jackpot + win_;
					jackpotWinner[jackpots] = winner_;
					jackpotWin[jackpots] = win_;
					jackpotRound[jackpots] = rounds;
					emit Jackpot(winner_, jackpot);
					jackpot = 0;
					jackpot = jackpot + otherHalf_;
					isJackpot[rounds] = true;
				}
				else {
					jackpot = jackpot + otherHalf_;
				}

				_balances[winner_] = _balances[winner_] + win_;
				_balances[treasury_] = treasuryBalance_ - win_;

				// @dev Updates the round, the win in that round and the winner address stats.
				roundWinner[rounds] = winner_;
				roundWin[rounds] = win_;
				totalWon = totalWon + win_;
				totalWonAddress[winner_] = totalWonAddress[winner_] + win_;
				rounds++;

				// @dev Reset and update `_drawBlock` and `_drawHash`.
				// Note: _drawBlock is set to 0 to ensure that a next round is only
				// started when the treasury has enough tokens. See the last if in this function.
				_drawBlock = 0;
				_drawHash = keccak256(abi.encodePacked(
					_drawHash, _balances[treasury_], msg.sender, _balances[winner_], winner_, totalParticipants
				));

				emit Transfer(treasury_, winner_, win_);
				emit Draw(winner_, win_);
			}

			// @dev If winner is either excluded or the zero address,
			// attempt another draw in 5 blocks.
			else {
				_drawBlock = block.number + 4;
			}
		}

		// @dev Set a new draw in now + blocktime + 1 blocks if there are enough tokens in the treasury address
		// and if `_drawBlock` is 0 (meaning a draw took place).
		if(_balances[treasury_] >= baseNumber_ && _drawBlock == 0) {
			_drawBlock = block.number + blocktime + 1;
		}
    }

	/**
     * @dev Checks if `address_` should be (again) added as participant.
	 * Deducts the fees from `feesPaidTemp` and adds fees to the total stats.
	 * Gives the user another entry/ticket.
     */
	function _checkParticipant(address address_) internal {
		// @dev If `address_` is already a participant but paid more than `baseNumber` token in fees,
		// `address_` will be added as participant again.
		uint baseNumber_ = baseNumber;
		if(feesPaidTemp[address_] >= baseNumber_) {
			participants[totalParticipants] = address_;
			totalParticipants = totalParticipants + 1;
			feesPaidTemp[address_] -= baseNumber_;
			participatingCount[address_]++;
		}
	}

	/**
     * @dev Check function that a) pays fees, b) checks via {_checkParticipant} if
	 * `sender_` or `recipient_` should be added as
	 * as a participants and c) checks if a draw should happen.
	 * Returns `amount_` minus fees (the amount that will be sent to `recipient_`).
     */
	function _check(address sender_, address recipient_, uint256 amount_) internal returns(uint newAmount_) {
		// @dev Calculate the fees (2%) only if `amount_` is bigger than or equal to 100.
		uint fee_;
		bool payFee_ = true;
		// @dev The address that pays the fees - either `sender_` or `recipient_`.
		address payer_ = sender_;

		// @dev If both, `sender_` and `recipient_` are excluded, no fees are paid.
		if(isExcluded[sender_] && isExcluded[recipient_]) {
			payFee_ = false;
		}

		// @dev If only `sender_` is excluded, `recipient_` is the payer of the fees.
		// This ensures that if a user interacts i.e. with the Pancake Router,
		// the user still gets the entries even the router send the tokens.
		else if(isExcluded[sender_]) {
			payer_ = recipient_;
		}

		// @dev Pay fees if set.
		if(amount_ >= 100 && payFee_) {
			fee_ = amount_ * 2 / 100;
			amount_ = amount_ - fee_;

			// @dev Add `fee_` to the treasury balance and update the fees that `payer_` paid and total fees.
			_balances[treasury] = _balances[treasury] + fee_;
			feesPaid[payer_] = feesPaid[payer_] + fee_;
			feesPaidTemp[payer_] = feesPaidTemp[payer_] + fee_;
			feesPaidTotal = feesPaidTotal + fee_;

			// @dev Emit a {Transfer} and {TransferFees} event.
			emit Transfer(payer_, treasury, fee_);
			emit TransferFees(payer_, fee_);

			if(!isExcluded[sender_]) {
				// @dev Checks if `sender_` should be added as participant again.
				_checkParticipant(sender_);
			}

			if(!isExcluded[recipient_]) {
				// @dev Checks if `recipient_` should be added as participant again.
				_checkParticipant(recipient_);
			}

			// @dev Checks if a draw should be done and, if yes, creates a new draw.
			_draw();
		}

		return amount_;
    }

    /**
     * @dev Moves `amount_` tokens from `sender_` to `recipient_`,
	 * while `recipient_` receives `amount_` minus fee.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender_` cannot be the zero address.
     * - `sender_` must have a balance of at least `amount_`.
     */
    function _transfer(address sender_, address recipient_, uint256 amount_) internal {
        require(sender_ != address(0), "TheTreasure: Transfer from the zero address.");

		_balances[sender_] = _balances[sender_] - amount_;

		_drawHash = keccak256(abi.encodePacked(_drawHash, sender_, recipient_, amount_, msg.sender));

		// Calls {_check} and adjusts `amount_` to `amount_` minus a 2% fee.
        amount_ = _check(sender_, recipient_,amount_);

        _balances[recipient_] = _balances[recipient_] + amount_;

		// @dev Emits a transfer event with `amount_` minus the fee, since thats what `recipient_` receives.
        emit Transfer(sender_, recipient_, amount_);
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
	function _approve(address owner_, address spender_, uint256 amount_) internal {
        require(owner_ != address(0), "TheTreasure: Approve from the zero address.");
        require(spender_ != address(0), "TheTreasure: Approve to the zero address.");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

	/**
	 * @dev Allows the owner to change the base number.
	 * Is tied to a 24 hour cooldown to prevent changes in favor of the owner and to keep the decentralization.
	 * It is used to adjust the fee and required paid fee to the token's current situation.
	 * Note: Neither `baseNumberChangeAnnounced` nor `newBaseNumber` are changed on a successful change
	 * to prevent hijacking post-change.
	 */
	function changeBaseNumber(uint newBaseNumber_) external onlyOwner {
		// @dev Check if `changeAnnounced` was made more than or equal to 6 hours ago.
        require(baseNumberChangeAnnounced <= block.timestamp - 6 hours, "TheTreasure: Changing of base number not possible yet.");
        
		require(baseNumber != newBaseNumber_, "TheTreasure: Base number is already as requested.");
        
        // @dev Owner attempts to accept the announced change.
		if(newBaseNumber_ == newBaseNumber) {
			emit BaseChange(baseNumber, newBaseNumber);
			baseNumber = newBaseNumber;
		}
		
		// @dev Otherwise announces a `baseNumber`-change.
		else {
			emit BaseChangeAnnouncement(baseNumber, newBaseNumber_);
			baseNumberChangeAnnounced = block.timestamp;
			newBaseNumber = newBaseNumber_;
		}
	}

	/**
	 * @dev Allows the owner to change the blocktime which is the number of blocks the next lottery round starts.
	 * Is tied to a 24 hour cooldown to prevent changes in favor of the owner and to keep the decentralization.
	 * Note: Neither `blocktimeChangeAnnounced` nor `newBlocktime` are changed on a successful change
	 * to prevent hijacking ppost-change.
	 */
	function changeBlocktime(uint newBlocktime_) external onlyOwner {
		// @dev Check if `blocktimeChangeAnnounced` was made more than or equal to 6 hours ago.
        require(blocktimeChangeAnnounced <= block.timestamp - 6 hours, "TheTreasure: Changing of blocktime not possible yet.");
        
		require(blocktime != newBlocktime_, "TheTreasure: Base number is already as requested.");
        
        // @dev Owner attempts to accept the announced change.
		if(newBlocktime_ == newBlocktime) {
			emit BlocktimeChange(blocktime, newBlocktime);
			blocktime = newBlocktime_;
		}
		
		// @dev Otherwise announces a `blocktime`-change.
		else {
			emit BlocktimeChangeAnnouncement(blocktime, newBlocktime_);
			blocktimeChangeAnnounced = block.timestamp;
			newBlocktime = newBlocktime_;
		}
	}

	/**
	 * @dev Excludes or announces an exclude of addresses from receiving rewards.
	 * These addresses still can pay as they wish and still pay fees,
	 * but simply won't receive any drawing winnings.
	 */
	function exclude(address[] memory excluded_) external onlyOwner {
		require(excluded_.length >= 1, "TheTreasure: `excluded_` should contain atleast 1 address.");
		uint toExcludeCount_ = toExcludeCount;

		// @dev Allow the first exclusion request to be done instantly.
		// `exclusionAnnounced` is only zero after deployment and before the first exclusion.
		if(exclusionAnnounced == 0) {
			for(uint i = 0; i < excluded_.length; i++) {
				isExcluded[excluded_[i]] = true;
				emit Exclude(excluded_[i]);
			}
			exclusionAnnounced = block.timestamp;
		}

		// @dev Check if `toExcludeCount`is >= 1 which means that the owner confirms the exclusion of addresses.
		else if(toExcludeCount_ >= 1) {
			// @dev Exclusion announcement has to be made more than 6 hours ago.
			uint minTime_ = block.timestamp - 6 hours;
			require(exclusionAnnounced <= minTime_, "TheTreasure: Exclusion announcement less than 6 hours ago.");

			// @dev Exclude the addresses.
			for(uint i = 0; i < toExcludeCount_; i++) {
				isExcluded[toExclude[i]] = true;
				emit Exclude(toExclude[i]);
			}

			// @dev Sets `toExcludeCount` to zero to start over next time.
			toExcludeCount = 0;
		}

		// @dev Otherwise create a new exclusion request.
		else {
			exclusionAnnounced = block.timestamp;
			for(uint i = 0; i < excluded_.length; i++) {
				toExclude[i] = excluded_[i];
				toExcludeCount++;
				emit ToExclude(excluded_[i]);
			}
		}
	}

	/**
     * @dev Withdraws tokens and BNB locked in this contract.
	 * Important Notice: This does not access any tokens of any user.
	 * At no time should there be any tokens in this contract, not even TRSR.
	 * The treasury tokens are held in the non-accessible treasury address (see {treasury})
	 * and not in this contract. This function only withdraws the own balance of a token
	 * that most likely was accidentally sent into this contract.
     */
    function withdrawTokens(address token_, uint amount_) external onlyOwner {
		if(token_ == address(0)) {
			(bool success_, ) = payable(owner).call{value: address(this).balance}("");
			require(success_, "TheTreasure: Transfer failed.");
		}
		else {
			uint tokenBalance_ = IERC20(token_).balanceOf(address(this));
			if(amount_ != 0) {
				IERC20(token_).transfer(owner, amount_);
			}
			else {
				IERC20(token_).transfer(owner, tokenBalance_);
			}
		}
    }

	/**
	 * @dev Sets a new pending owner that can accept the ownership of this contract.
	 */
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "TheTreasure: Owner can not be the zero address.");
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pending owner to accept the ownership.
     * This makes sure that an ownership is not accidentally transferred to a non-controlled wallet.
     * Additionally, if the current owner calls this function, the pending owner is set to zero.
     */
	function acceptOwnership() external onlyOwnerOrPending {
	    if(msg.sender == pendingOwner) {
	        address oldOwner = owner;
    		owner = pendingOwner;
    		pendingOwner = address(0);
    		emit OwnerChange(oldOwner, owner);
	    }
	    else if(msg.sender == owner) {
    		pendingOwner = address(0);
	    }
	}

	/**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account_) public view returns (uint256) {
        return _balances[account_];
    }

    function allowance(address owner_, address spender_) public view returns (uint256) {
        return _allowances[owner_][spender_];
    }

	/**
	 * @dev Returns the treasury address and it's balance.
	 * @param treasury_ Address of fees collected for draw. Probably not owned by anyone as of time of deployment.
	 * @param treasuryBalance_ Token balance of the treasury address.
	 */
	function getTreasury() external view returns(address treasury_, uint treasuryBalance_) {
		return(treasury, balanceOf(treasury));
	}

	/**
	 * @dev Returns some stats of TheTreasure.io.
	 * @param jackpot_ Current jackpot.
	 * @param totalWon_ Total amount paid out to winners (including jackpots).
	 * @param totalParticipants_ The total amount of participants/tickets.
	 * @param feesPaidTotal_ Amount of fees paid in total.
	 */
	function getStats() external view returns(uint jackpot_, uint totalWon_, uint totalParticipants_, uint feesPaidTotal_) {
		return(jackpot, totalWon, totalParticipants, feesPaidTotal);
	}

	/**
	 * @dev Returns jackpot stats.
	 * @param jackpotWinner_ Address that won the jackpot.
	 * @param jackpotWin_ Amount of tokens that were won.
	 * @param jackpotRound_ The round the jackpot was won in.
	 */
	function getJackpot(uint id_) external view returns(address jackpotWinner_, uint jackpotWin_, uint jackpotRound_) {
		return(jackpotWinner[id_], jackpotWin[id_], jackpotRound[id_]);
	}

	/**
	 * @dev Returns round stats of round `id_`.
	 * @param roundWinner_ The address that won in the round.
	 * @param roundWin_ The amount of tokens that the address won in the round (including, if won, jackpot).
	 * @param isJackpot_ True if a jackpot was paid in this round, false if not.
	 */
	function getRound(uint id_) external view returns(address roundWinner_, uint roundWin_, bool isJackpot_) {
		return(roundWinner[id_], roundWin[id_], isJackpot[id_]);
	}

	/**
	 * @dev Returns the base number, the change announcement timestamp and the new base number.
	 * @param baseNumber_ The base number is the possible direct win (50%) and the lottery allocation (50%) amount.
	 * @param changeAnnounced_ The timestamp a base number change was initiated (not finished).
	 * @param newBaseNumber_ The new base number. Does not change. Look out for {BaseChangeAnnouncement}-events.
	 */
	function getBaseData() external view returns(uint baseNumber_, uint changeAnnounced_, uint newBaseNumber_) {
		return(baseNumber, baseNumberChangeAnnounced, newBaseNumber);
	}

	/**
	 * @dev Returns the blocktime, the change announcement timestamp and the new blocktime.
	 * @param blocktime_ The amount of blocks between two lottery draws.
	 * @param blocktimeChangeAnnounced_ The timestamp a blocktime change was initiated (not finished).
	 * @param newBlocktime_ The new blocktime. Does not change. Look out for {BlocktimeChangeAnnouncement}-events.
	 */
	function getBlocktimeData() external view returns(uint blocktime_, uint blocktimeChangeAnnounced_, uint newBlocktime_) {
		return(blocktime, blocktimeChangeAnnounced, newBlocktime);
	}
    
	/**
	 * @dev Returns participant data of the participant address with ID `id_`.
	 * @param id_ The ID to get the address from.
	 * @param participant_ The address to get the data from.
	 * @param participantCount_ The amount of times a participant participates, basically the tickets.
	 * @param feesPaid_ The amount of fees that `participant_` paid.
	 * @param totalWon_ The amount that the participant ever won.
	 */
	function getParticipantById(uint id_) external view returns(address participant_, uint participantCount_, uint feesPaid_, uint totalWon_) {
		participant_ = participants[id_];
		return(participants[id_], participatingCount[participant_], feesPaid[participant_], totalWonAddress[participant_]);
	}

	/**
	 * @dev Returns participant data of the participant address `participant_`.
	 * @param participant_ The address to get the data from.
	 * @param participantCount_ The amount of times a participant participates, basically the tickets.
	 * @param feesPaid_ The amount of fees that `participant_` paid.
	 * @param totalWon_ The amount that the participant ever won.
	 */
	function getParticipantByAddress(address participant_) external view returns(uint participantCount_, uint feesPaid_, uint totalWon_) {
		return(participatingCount[participant_], feesPaid[participant_], totalWonAddress[participant_]);
	}

    /**
     * @dev Approves `spender_` to spend up to `amount_` tokens of msg.sender.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender_, uint256 amount_) public returns (bool) {
        _approve(msg.sender, spender_, amount_);
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function transfer(address recipient_, uint256 amount_) public returns (bool) {
        require(amount_ > 0, "TheTreasure: Amount should be more then zero.");
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public returns (bool) {
        require(amount_ > 0, "TheTreasure: Amount should be more then zero.");
        _transfer(sender_, recipient_, amount_);
        _approve(sender_, msg.sender,  allowance(sender_, msg.sender) - amount_);
        return true;
    }
}