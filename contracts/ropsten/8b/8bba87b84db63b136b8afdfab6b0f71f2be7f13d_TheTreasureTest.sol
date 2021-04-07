/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: NONE
/**
 *  _____ _         _____                                  
 * |_   _| |__   __|_   _| __ ___  __ _ ___ _   _ _ __ ___ 
 *   | | | '_ \ / _ \| || '__/ _ \/ _` / __| | | | '__/ _ \
 *   | | | | | |  __/| || | |  __/ (_| \__ \ |_| | | |  __/
 *   |_| |_| |_|\___||_||_|  \___|\__,_|___/\__,_|_|  \___|
 *      
 *    $TRSR                             thetreasure.io
 *    
 *       developed by @deceloping for thetreasure.io
 *
 * !!!! WARRNING !!!! WARNING !!!! WARNING !!!! WARNING !!!! WARNING
 * This is a BETA version of the upcoming thetreasure.io contract.
 * IT WILL BE DEACTIVATED once TheTreasure starts.
 * DO NOT actively trade and/or hold this token other than for testing!!
 */
pragma solidity 0.8.3;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
	address public treasury;

	// @dev The contract/project owner and, if it's in change, the pending owner.
    address public owner;
	address public pendingOwner;

	// @dev The base price for both required paid fees and the prize
	uint public baseNumber;
	// @dev When `baseNumber` is being changed, that change can only
	// be confirmed 24 hours after `changeAnnounced`
	uint public changeAnnounced;
	uint public newBaseNumber;

	// @dev Participants, participation of an address and total count of participants
	// Note: Participants can exist multiple times
	mapping(uint => address) public participants;
	mapping(address => uint) public participatingCount;
	uint public totalParticipants;

	// @dev Saves winner and the win and updates total win and total win of an address each new draw.
	uint public rounds;
	mapping(uint => address) public roundWinner;
	mapping(uint => uint) public roundWin;
	uint public totalWon;
	mapping(address => uint) public totalWonAddress;

	// @dev Stores how much jackpot were won and who won how much.
	uint public jackpots;
	mapping(uint => address) jackpotWinner;
	mapping(uint => uint) jackpotWin;
	mapping(uint => uint) jackpotRound;
	uint public jackpot;

	// @dev Addresses can be excluded from winning.
	// Note: Those addresses will still pay the fee.
	mapping(address => bool) public isExcluded;
	mapping(uint => address) public toExclude;
	uint public toExcludeCount;
	uint public exclusionAnnounced;

	// @dev Amount of fees an address paid in total and temporary and ever collected fees.
	// Note: `feesPaidTemp` will be changed once it's >= `baseNumber`.
	mapping(address => uint) public feesPaid;
	mapping(address => uint) public feesPaidTemp;
	uint public feesPaidTotal;

	uint public _drawBlock;

	bytes32 private _drawHash;
	
	uint constant ONE_TOKEN = 10 ** 18;

	bool public stopped;

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
     * @dev Emitted when a draw is made and `receiver` won.
     */
    event Draw(address indexed receiver, uint amount);

	/**
     * @dev Emitted when `winner` won the jackpot of `amount`.
     */
    event Jackpot(address indexed winner, uint jackpot);
	
	/**
     * @dev Emitted when `winner` did win but not the jackpot of `amount`.
     */
    event NoJackpot(address indexed winner, uint jackpot);

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
     *
     * Note that `value` may be zero.
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
        require(msg.sender == owner, "BEP20: Only the owner can call this function.");
        _;
    }
    
    /**
     * @dev Only allows the owner or the pending owner to call the specific function.
     */
    modifier onlyOwnerOrPending {
        require(msg.sender == owner || msg.sender == pendingOwner,
			"BEP20: Only owner or pending owner can call this function."
		);
        _;
    }

	modifier onlyNotStopped {
        require(stopped == false);
        _;
    }
    
    
	/**
	 * @dev Initializes the contract and mints the total supply to `owner_`.
	 */
    constructor(address owner_) {

		// @dev Vault address - not controlled by anyone (yet).
        treasury = 0x1234567890000000000000000000000000000000;
        owner = owner_;

		// @dev Set the initial and total supply to 20,000 tokens.
		// No more tokens are mined and thus no mint() function exists in this contract.
		uint256 initialSupply = 20000 * 10 ** 18;
		_totalSupply = initialSupply;

		// @dev Transfer the `initialSupply` to the owner.
		_balances[owner_] = _balances[owner_] + initialSupply;
        emit Transfer(address(0), owner_, initialSupply);

		_name = "TRSR Beta Test";
        _symbol = "TRSRB";
        _decimals = 18;
        baseNumber = 20000000000000000;

		// @dev Exclude the factory, router and treasury addresses from winning.
		isExcluded[0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f] = true;
		emit Exclude(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
		
		isExcluded[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
		emit Exclude(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		isExcluded[0x1234567890000000000000000000000000000000] = true;
		emit Exclude(0x1234567890000000000000000000000000000000);
    }
    
    
	/**
     * @dev Runs a draw.
	 * The draw is only done atleast one block after the block it was defined to happen.
	 * This is an attempt to prevent as much prediction and therefore win possibilities as possible.
     */
    function _draw() internal {
		// @dev Do a draw when `_drawBlock` is not zero, the draw is not in the same block `_drawBlock` was set,
		// and the treasury has atleast a balance of `baseNumber` + `jackpot` tokens.
		if(_drawBlock != 0 && _drawBlock < block.number && _balances[treasury] >= baseNumber + jackpot) {
			_drawHash = keccak256(abi.encodePacked(_drawHash, blockhash(_drawBlock)));
			uint winNumber_ = uint(_drawHash) % (totalParticipants - 1);
			address winner = participants[winNumber_];

			// @dev Only pays to the winner if the winner is not excluded and is not the zero address.
			// If the winner is excluded, it does another draw attempt 2 blocks after.
			if(!isExcluded[winner] && winner != address(0)) {
				uint win_ = baseNumber / 2;
				uint otherHalf_ = baseNumber - win_;
				uint wonJackpot_ = uint(_drawHash) % 100;
				
				// @dev Lucky user won the jackpot.
				if(wonJackpot_ == 42) {
					win_ = jackpot + win_;
					jackpotWinner[jackpots] = winner;
					jackpotWin[jackpots] = win_;
					jackpotRound[jackpots] = rounds;
					emit Jackpot(winner, jackpot);
					jackpot = 0;
					jackpot = jackpot + otherHalf_;
				}
				else {
					jackpot = jackpot + otherHalf_;
					emit NoJackpot(winner, jackpot);
				}

				_balances[winner] = _balances[winner] + win_;
				_balances[treasury] = _balances[treasury] - win_;

				// @dev Updates the round, the win in that round and the winner address stats.
				roundWinner[rounds] = winner;
				roundWin[rounds] = win_;
				totalWon = totalWon + win_;
				totalWonAddress[winner] = totalWonAddress[winner] + win_;
				rounds++;

				// @dev Reset and update `_drawBlock` and `_drawHash`.
				_drawBlock = 0;
				_drawHash = keccak256(abi.encodePacked(
					_drawHash, _balances[treasury], msg.sender, _balances[winner], winner, totalParticipants
				));

				emit Transfer(treasury, winner, win_);
				emit Draw(winner, win_);
			}

			// @dev If winner is either excluded or the zero address,
			// attempt another draw in 5 blocks.
			else {
				_drawBlock = block.number + 4;
			}
		}

		// @dev Set a new draw in now + 100 (101. block) blocks if there are enough tokens in the treasury address
		// and if `_drawBlock` is 0 (meaning a draw took place).
		if(_balances[treasury] >= baseNumber && _drawBlock == 0) {
			_drawBlock = block.number + 100;
		}
    }

	/**
     * @dev Checks if `address_` should be (again) added as participant.
     */
	function _checkParticipant(address address_) internal {
		// @dev If address_ is already a participant but paid more than `baseNumber` token in fees,
		// add `address_` as participant again.
		if(feesPaidTemp[address_] >= baseNumber) {
			participants[totalParticipants] = address_;
			totalParticipants = totalParticipants + 1;
			feesPaidTemp[address_] = feesPaidTemp[address_] - baseNumber;
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

		// @dev If only `sender_` is excluded, pay fees in the name of `recipient_`.
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
    function _transfer(address sender_, address recipient_, uint256 amount_) onlyNotStopped internal {
        require(sender_ != address(0), "BEP20: Transfer from the zero address.");

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
        require(owner_ != address(0), "BEP20: Approve from the zero address.");
        require(spender_ != address(0), "BEP20: Approve to the zero address.");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }
    
	function stop() external onlyOwner {
		stopped = true;
	}

	/**
	 * @dev "Announces" a change of the base number.
	 * Is tied to a 24 hour cooldown to prevent changes in favor of the owner and to keep the decentralization.
	 * It is used to adjust the fee and required paid fee to the token's current situation.
	 * Note: Neither the changeAnnounced nor newBaseNumber are changed on a successful change
	 * to prevent hijacking pre-change.
	 */
	function changeBaseNumber(uint newBaseNumber_) external onlyOwner {
		// @dev Check if `changeAnnounced` was made more than or equal to 1 day ago
		require(changeAnnounced <= block.timestamp - 6 hours, "BEP20: Changing of base number not possible yet.");
        
		require(baseNumber != newBaseNumber_, "BEP20: Base number is already as requested.");
        
        // @dev Owner attempts to accept the announced change.
		if(newBaseNumber_ == newBaseNumber) {
			emit BaseChange(baseNumber, newBaseNumber);
			baseNumber = newBaseNumber;
		}
		
		// @dev Otherwise announces a `baseNumber`-change.
		else {
			emit BaseChangeAnnouncement(baseNumber, newBaseNumber_);
			changeAnnounced = block.timestamp;
			newBaseNumber = newBaseNumber_;
		}
	}

	/**
	 * @dev Excludes or announces an exclude of addresses from receiving rewards.
	 * These addresses still can pay as they wish and still pay fees,
	 * but simply won't receive any drawing winnings.
	 */
	function exclude(address[] memory excluded_) external onlyOwner {
		require(excluded_.length >= 1, "BEP20: `excluded_` should contain atleast 1 address.");
		
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
		if(toExcludeCount >= 1) {
			require(toExcludeCount >=1, "BEP20: Nothing to exclude.");
			// @dev Exclusion announcement has to be made more than 6 hours ago.
		    uint minTime_ = block.timestamp - 6 hours;
			require(exclusionAnnounced <= minTime_, "BEP20: Exclusion announcement less than 6 hours ago.");

			// @dev Exclude the addresses.
			for(uint i = 0; i < toExcludeCount; i++) {
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
	 * and not in this contract. This function only withdraws the own balance of a token.
	 * This function is callable by anyone, but transfers tokens to the owner.
     */
    function withdrawTokens(address token_, uint amount_) external {
		if(token_ == address(0)) {
			(bool success_, ) = payable(owner).call{value: address(this).balance}("");
			require(success_, "BEP20: Transfer failed.");
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
        require(newOwner != address(0), "BEP20: Owner can not be the zero address.");
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
        require(amount_ > 0, "BEP20: Amount should be more then zero.");
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public returns (bool) {
        require(amount_ > 0, "BEP20: Amount should be more then zero.");
        _transfer(sender_, recipient_, amount_);
        _approve(sender_, msg.sender,  allowance(sender_, msg.sender) - amount_);
        return true;
    }
}