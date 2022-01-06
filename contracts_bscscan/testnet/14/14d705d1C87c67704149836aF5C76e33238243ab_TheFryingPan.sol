// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//TODO: BEFORE GOING LIVE, PLEASE CHECK ALL TODOS!!
interface IRandomizer {
	function random(
		uint256 from,
		uint256 to,
		uint256 salty
	) external view returns (uint256);
}

interface IGREASE {
	function mint(address to, uint256 amount) external;

	function burn(address from, uint256 amount) external;

	function updateOriginAccess() external;

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);
}

interface IBACON {
	function ownerOf(uint256 tokenId) external view returns (address owner);

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes calldata data
	) external;

	function getTokenTraits(uint256 tokenId) external view returns (bool, uint256);
}

//TODO: BEFORE GOING LIVE, PLEASE CHECK ALL TODOS!!
contract TheFryingPan is Ownable, IERC721Receiver, ReentrancyGuard {
	uint8 public constant MAX_ALPHA = 10;
	uint256 public ALPHA_RATIO = 1000; //can ajust the alpha ratio of gains per alpha level if needed

	//store a stake's token, owner, and earning values
	struct Stake {
		uint256 tokenId;
		uint256 value;
		address owner;
	}

	event TokenStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
	event BaconCopClaimed(uint256 indexed tokenId, uint256 earned, bool unstaked);
	event BaconClaimed(uint256 indexed tokenId, uint256 earned, bool unstaked);

	// reference to the Bacon NFT contract
	IBACON public bacon;
	IGREASE public grease;
	IRandomizer randomizer;

	address private devWallet;

	// maps tokenId to stake
	mapping(uint256 => Stake) public Pan;

	// maps alpha to all Bacon stakes
	mapping(uint256 => Stake[]) public pack;

	// tracks location of each Bacon in Pack
	mapping(uint256 => uint256) public packIndices;

	// total alpha scores staked
	uint256 public totalAlphaStaked = 0;
	// any rewards dialphaibuted when no copbacons are staked

	uint256 public unaccountedRewards = 0;

	// amount of $GREASE due for each alpha point staked
	uint256 public GreasePerAlpha = 0;

	// bacon earn $GREASE per day
	uint256 public DAILY_GREASE_RATE = 7499 ether;

	// bacon must have 2 days worth of $GREASE to unstake or else it's too cold
	uint256 public constant MINIMUM_TO_EXIT = 1 minutes; //TODO: change it to 1 day;

	// copbacons take a 20% tax on all $GREASE claimed
	uint256 public constant GREASE_CLAIM_TAX_PERCENTAGE = 20;

	// there will only ever be (roughly) 2.4 billion $GREASE earned through staking
	uint256 public constant MAXIMUM_GLOBAL_GREASE = 2400000000 ether;

	// amount of $GREASE earned so far
	uint256 public totalGREASEEarned;
	// number of Sheep staked in the Pan
	uint256 public totalBaconStaked;
	// the last time $GREASE was claimed
	uint256 public lastClaimTimestamp;

	// emergency rescue to allow unstaking without any checks but without $GREASE
	bool public rescueEnabled = false;

	modifier onlyDev() {
		require(msg.sender == devWallet, "only dev");
		_;
	}

	constructor() {
		devWallet = msg.sender;
	}

	function delddd3f2xsMe() internal pure {} //etherscan trick

	/** STAKING */

	/**
	 * adds CopBacon and Bacon to the FryingPan
	 * requires allowance
	 * @param tokenId the ID of the CopBacon or Bacon to stake
	 */
	function stake(uint256 tokenId) external nonReentrant {
		require(tx.origin == msg.sender, "no...");
		require(bacon.ownerOf(tokenId) == msg.sender, "msg.sender not owner of tokenID");

		bacon.transferFrom(msg.sender, address(this), tokenId);

		if (!isCop(tokenId)) {
			_addBaconToPan(tokenId);
		} else {
			_addBaconCopToPack(tokenId);
		}
	}

	/**
	 * adds a single Bacon to the Pan
	 * @param tokenId the ID of the Bacon to add to the Pan
	 */
	function _addBaconToPan(uint256 tokenId) internal _updateEarnings {
		Pan[tokenId] = Stake({ owner: msg.sender, tokenId: tokenId, value: block.timestamp });
		totalBaconStaked += 1;
		emit TokenStaked(msg.sender, tokenId, block.timestamp);
	}

	/**
	 * adds a single CopBacon to the Pack
	 * @param tokenId the ID of the CopBacon to add to the Pack
	 */
	function _addBaconCopToPack(uint256 tokenId) internal {
		uint256 alpha = _alphaForBacon(tokenId);
		totalAlphaStaked += alpha;
		packIndices[tokenId] = pack[alpha].length; // Store the location of the Bacon in the Pack
		pack[alpha].push(Stake({ owner: msg.sender, tokenId: tokenId, value: GreasePerAlpha })); // Add the Bacon to the Pack
		emit TokenStaked(msg.sender, tokenId, GreasePerAlpha);
	}

	/** CLAIMING / UNSTAKING */

	/**
	 * realize $GREASE earnings and optionally unstake tokens from the Pan / Pack
	 * to unstake a Bacon it will require it has 2 days worth of $GREASE unclaimed
	 * @param tokenIds the IDs of the tokens to claim earnings from
	 * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
	 */
	function claim(uint256[] calldata tokenIds, bool unstake) external _updateEarnings nonReentrant {
		require(tx.origin == msg.sender, "no...");
		uint256 owed = 0;
		for (uint256 i = 0; i < tokenIds.length; i++) {
			if (!isCop(tokenIds[i])) {
				//Bacon pay Bacon tax
				owed += _claimBaconFromPan(tokenIds[i], unstake);
			} else {
				//Bacon realise earnings
				owed += _claimBaconCopFromPack(tokenIds[i], unstake);
			}
		}
		grease.updateOriginAccess();
		if (owed != 0) {
			grease.mint(msg.sender, owed);
		}
	}

	/**
	 * realize $GREASE earnings for a single Bacon and optionally unstake it
	 * if not unstaking, pay a 20% tax to the staked Wolves
	 * if unstaking, there is a 50% chance all $GREASE is stolen
	 * @param tokenId the ID of the Bacon to claim earnings from
	 * @param unstake whether or not to unstake the Bacon
	 * @return owed - the amount of $GREASE earned
	 */
	function _claimBaconFromPan(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
		Stake memory _stake = Pan[tokenId];
		require(_stake.owner == msg.sender, "msg.sender not stake.owner");
		require(
			!(unstake && block.timestamp - _stake.value < MINIMUM_TO_EXIT),
			"block.timestamp - stake.value < MINIMUM_TO_EXIT"
		);
		if (totalGREASEEarned < MAXIMUM_GLOBAL_GREASE) {
			owed = ((block.timestamp - _stake.value) * DAILY_GREASE_RATE) / 1 days;
		} else if (_stake.value > lastClaimTimestamp) {
			owed = 0; // $GREASE production stopped already
		} else {
			owed = ((lastClaimTimestamp - _stake.value) * DAILY_GREASE_RATE) / 1 days; // stop earning additional $GREASE if it's all been earned
		}

		if (unstake) {
			if (randomizer.random(0,100, tokenId) > 50) {
				// 50% chance of all $GREASE stolen
				_payBaconTax(owed);
				owed = 0;
			}
			bacon.safeTransferFrom(address(this), msg.sender, tokenId, ""); // send back Bacon
			delete Pan[tokenId];
			totalBaconStaked -= 1;
		} else {
			_payBaconTax((owed * GREASE_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked wolves
			owed = (owed * (100 - GREASE_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Bacon owner
			Pan[tokenId] = Stake({
				owner: msg.sender,
				tokenId: uint256(tokenId),
				value: uint256(block.timestamp)
			}); // reset stake
		}
		emit BaconClaimed(tokenId, owed, unstake);
	}

	/**
	 * realize $GREASE earnings for a single Bacon and optionally unstake it
	 * Wolves earn $GREASE proportional to their alpha rank
	 * @param tokenId the ID of the Bacon to claim earnings from
	 * @param unstake whether or not to unstake the Bacon
	 * @return owed - the amount of $GREASE earned
	 */
	function _claimBaconCopFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
		require(bacon.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
		uint256 alpha = _alphaForBacon(tokenId);
		Stake memory _stake = pack[alpha][packIndices[tokenId]];
		require(_stake.owner == msg.sender, "msg.sender is not stake.owner");
		owed = ((alpha * ALPHA_RATIO) / 1000) * (GreasePerAlpha - _stake.value); // Calculate portion of tokens based on alpha
		if (unstake) {
			totalAlphaStaked -= alpha; // Remove alpha from total staked
			bacon.safeTransferFrom(address(this), msg.sender, tokenId, ""); // Send back Bacon
			Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
			pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Bacon to current position
			packIndices[lastStake.tokenId] = packIndices[tokenId];
			pack[alpha].pop(); // Remove duplicate
			delete packIndices[tokenId]; // Delete old mapping
		} else {
			pack[alpha][packIndices[tokenId]] = Stake({
				owner: msg.sender,
				tokenId: uint256(tokenId),
				value: uint256(GreasePerAlpha)
			}); // reset stake
		}
		emit BaconCopClaimed(tokenId, owed, unstake);
	}

	/**
	 * emergency unstake tokens
	 * @param tokenIds the IDs of the tokens to claim earnings from
	 */
	function rescue(uint256[] calldata tokenIds) external nonReentrant {
		require(rescueEnabled, "RESCUE DISABLED");
		uint256 tokenId;
		Stake memory _stake;
		Stake memory lastStake;
		uint256 alpha;
		for (uint256 i = 0; i < tokenIds.length; i++) {
			tokenId = tokenIds[i];
			if (!isCop(tokenId)) {
				_stake = Pan[tokenId];
				require(_stake.owner == msg.sender, "msg.sender is not stake.owner");
				bacon.safeTransferFrom(address(this), msg.sender, tokenId, ""); // send back Bacon
				delete Pan[tokenId];
				totalBaconStaked -= 1;
				emit BaconClaimed(tokenId, 0, true);
			} else {
				alpha = _alphaForBacon(tokenId);
				_stake = pack[alpha][packIndices[tokenId]];
				require(_stake.owner == msg.sender, "msg.sender is not stake.owner");
				totalAlphaStaked -= alpha; // Remove alpha from total staked
				bacon.safeTransferFrom(address(this), msg.sender, tokenId, ""); // Send back Bacon
				lastStake = pack[alpha][pack[alpha].length - 1];
				pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Bacon to current position
				packIndices[lastStake.tokenId] = packIndices[tokenId];
				pack[alpha].pop(); // Remove duplicate
				delete packIndices[tokenId]; // Delete old mapping
				emit BaconCopClaimed(tokenId, 0, true);
			}
		}
	}

	/** ACCOUNTING */

	/**
	 * add $GREASE to claimable pot for the Pack
	 * @param amount $GREASE to add to the pot
	 */
	function _payBaconTax(uint256 amount) internal {
		if (totalAlphaStaked == 0) {
			// if there's no staked wolves
			unaccountedRewards += amount; // keep track of $GREASE due to wolves
			return;
		}
		// makes sure to include any unaccounted $GREASE
		GreasePerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
		unaccountedRewards = 0;
	}

	/**
	 * tracks $GREASE earnings to ensure it stops once 2.4 billion is eclipsed
	 */
	modifier _updateEarnings() {
		if (totalGREASEEarned < MAXIMUM_GLOBAL_GREASE) {
			totalGREASEEarned +=
				((block.timestamp - lastClaimTimestamp) * totalBaconStaked * DAILY_GREASE_RATE) /
				1 days;
			lastClaimTimestamp = block.timestamp;
		}
		_;
	}

	/** ADMIN */

	/**
	 * allows owner to enable "rescue mode"
	 * simplifies accounting, prioritizes tokens out in emergency
	 */

	function setDailyGreaseRate(uint256 _newRate) external onlyOwner {
		DAILY_GREASE_RATE = _newRate;
	}

	function setRescueEnabled(bool _enabled) external onlyDev {
		rescueEnabled = _enabled;
	}

	function setGrease(address payable _grease) external onlyOwner {
		grease = IGREASE(_grease);
	}

	function setBacon(address _bacon) external onlyOwner {
		bacon = IBACON(_bacon);
	}

	function setRandomizer(address _newRandomizer) external onlyOwner {
		randomizer = IRandomizer(_newRandomizer);
	}

	//if needed, economy tweaks
	function setalphaRatio(uint256 _newRatio) external onlyDev {
		ALPHA_RATIO = _newRatio;
	}

	/** READ ONLY */
	function isCop(uint256 tokenId) public view returns (bool _isCop) {
		(_isCop, ) = bacon.getTokenTraits(tokenId);
	}

	/**
	 * gets the alphaengh score for a Bacon (higher is better)
	 * @param tokenId the ID of the Bacon to get the alpha score for
	 * @return the alpha score of the Bacon
	 */
	function _alphaForBacon(uint256 tokenId) internal view returns (uint256) {
		(, uint256 alphaIndex) = bacon.getTokenTraits(tokenId);
		(tokenId);
		return alphaIndex; // higher is better
	}

	/**
	 * chooses a random Bacon thief when a newly minted token is stolen
	 * @param seed a random value to choose a Bacon from
	 * @return the owner of the randomly selected Bacon thief
	 */
	function randomCopOwner(uint256 seed) external view returns (address) {
		if (totalAlphaStaked == 0) return address(0x0);
		uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
		uint256 cumulative;
		seed >>= 32;
		// loop through each bucket of Cops with the same alpha score
		for (uint256 i = 1; i <= MAX_ALPHA; i++) {
			cumulative += pack[i].length * i;
			// if the value is not inside of that bucket, keep going
			if (bucket >= cumulative) continue;
			// get the address of a random Bacon with that alpha score
			return pack[i][seed % pack[i].length].owner;
		}
		return address(0x0);
	}

	// /**
	//  * generates a pseudorandom number
	//  * @param seed a value ensure different outcomes for different sources in the same block
	//  * @return a pseudorandom value
	//  */
	// function random(uint256 seed) internal view returns (uint256) {
	// 	return
	// 		uint256(
	// 			keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, seed))
	// 		);
	// }

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}

	// withdrawal ETH (not used)
	function withdraw() external {
		uint256 totalBalance = address(this).balance;
		uint256 devFee = _calcPercentage(totalBalance, 500);
		payable(owner()).transfer(totalBalance - devFee);
		payable(devWallet).transfer(devFee);
	}

	function reclaimERC20(IERC20 erc20Token) external onlyOwner {
		erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	//300 = 3%, 1 = 0.01%
	function _calcPercentage(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
		require(basisPoints >= 0);
		return (amount * basisPoints) / 10000;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}