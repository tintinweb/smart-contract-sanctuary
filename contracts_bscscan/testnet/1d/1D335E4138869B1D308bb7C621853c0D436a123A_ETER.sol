/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: ContentCreator.sol


pragma solidity 0.8.0;

/**
 * @title ContentCreator mint
 * @dev Contains functionality to handle mint for content creators
 */
abstract contract ContentCreator {
    uint256 private constant MAX_CONTENT_CREATORS_SUPPLY =
        300000 * uint256(10)**18;
    uint256 private _totalContentCreatorMinted = 0;
    uint256 private constant MAX_DAILY_MINT = 3000 * uint256(10)**18;
    uint256 private _lastMintTime = 0;

    modifier notExceedContentCreatorSupply(uint256 _amount) {
        uint256 nextContentCreatorMinted = _totalContentCreatorMinted +
            _amount;
        require(nextContentCreatorMinted <= MAX_CONTENT_CREATORS_SUPPLY);
        _;
    }
	
    modifier mintDailyLimitContentCreators(uint256 _amount) {
        bool canMint = _lastMintTime == 0 ||
            block.timestamp > _lastMintTime + 1 days;

        require(canMint, "You can mint only once every day");
        require(_amount <= MAX_DAILY_MINT, "The amount exceed max daily mint");
        _;
    }

    /**
     * @dev increase total content creator minted amount and update lastMintTime
     */
    function increaseTotalContentCreatorMinted(uint256 _amount)
        internal
        notExceedContentCreatorSupply(_amount)
        mintDailyLimitContentCreators(_amount)
    {
        _totalContentCreatorMinted += _amount;
        _lastMintTime = block.timestamp;
    }

    function getTotalContentCreatorMinted() public view returns (uint256) {
        return _totalContentCreatorMinted;
    }
}

// File: Event.sol


pragma solidity 0.8.0;

/**
 * @title Event mint
 * @dev Contains functionality to handle mint for events in eterland game
 */
abstract contract Event {
    modifier notExceedEventSupply(uint256 _amount) {
        uint256 nextEventMinted = _totalEventSupplyMinted + _amount;
        require(nextEventMinted <= MAX_EVENTS_SUPPLY);
        _;
    }
    modifier mintDailyLimitEvent(uint256 _amount) {
        bool canMint = _lastMintTime == 0 ||
            block.timestamp > _lastMintTime + 1 days;

        require(canMint, "You can mint only once every day");
        require(_amount <= MAX_DAILY_MINT, "The amount exceed max daily mint");
        _;
    }

    uint256 private constant MAX_EVENTS_SUPPLY = 300000 * uint256(10)**18;
    uint256 private _totalEventSupplyMinted = 0;

	/**
 	* @dev max daily mint (1% of total events supply)
 	*/
    uint256 private constant MAX_DAILY_MINT = 3000 * uint256(10)**18;
    uint256 private _lastMintTime = 0;

	/**
 	* @dev increment event supply if not exceed allowed daily amount and max supply 
 	*/
    function _incrementEventSupply(uint256 _amount)
        internal
        mintDailyLimitEvent(_amount)
        notExceedEventSupply(_amount)
    {
        _totalEventSupplyMinted += _amount;
        _lastMintTime = block.timestamp;
    }

    function getTotalEventMinted() public view returns (uint256) {
        return _totalEventSupplyMinted;
    }
}

// File: Staking.sol


pragma solidity 0.8.0;
/**
 * @title Stacking mint
 * @dev Contains functionality to handle mint for stacking
 */
abstract contract Staking {
    uint256 private constant MAX_STAKING_SUPPLY = 1500000 * uint256(10)**18;
    uint256 private _totalStakingMinted = 0;
    uint256 private constant MAX_DAILY_MINT = 15000 * uint256(10)**18;
    uint256 private _lastMintTime = 0;
    modifier notExceedStakingSupply(uint256 _amount) {
        uint256 nextStakingMinted = _totalStakingMinted + _amount;
        require(nextStakingMinted <= MAX_STAKING_SUPPLY);
        _;
    }
    modifier mintDailyLimitStaking(uint256 _amount) {
        bool canMint = _lastMintTime == 0 ||
            block.timestamp > _lastMintTime + 1 days;

        require(canMint, "You can mint only once every day");
        require(_amount <= MAX_DAILY_MINT, "The amount exceed max daily mint");
        _;
    }


 	/**
 	* @dev increment staking supply if not exceed allowed daily amount and max supply 
 	*/
    function _increaseTotalStakingMinted(uint256 _amount)
        internal
        notExceedStakingSupply(_amount)
        mintDailyLimitStaking(_amount)
    {
        _totalStakingMinted += _amount;
        _lastMintTime = block.timestamp;
    }

    function getTotalStakingMinted() public view returns (uint256) {
        return _totalStakingMinted;
    }
}

// File: Moderator.sol


pragma solidity 0.8.0;
/**
 * @title Moderator mint
 * @dev Contains functionality to handle mint for Moderators
 */
abstract contract Moderator {
    uint256 private constant MAX_MOD_SUPPLY = 30000 * uint256(10)**18;
    uint256 private constant MAX_DAILY_MINT = 300 * uint256(10)**18;
    uint256 private _totalModeratorMinted = 0;
    uint256 private _lastMintTime = 0;
    modifier notExceedModeratorSupply(uint256 _amount) {
        uint256 nextModeratorMinted = _totalModeratorMinted + _amount;
        require(nextModeratorMinted <= MAX_MOD_SUPPLY);
        _;
    }
    
    modifier mintDailyLimitModerator(uint256 _amount) {
        bool canMint = _lastMintTime == 0 ||
            block.timestamp > _lastMintTime + 1 days;

        require(canMint, "You can mint only once every day");
        require(_amount <= MAX_DAILY_MINT, "The amount exceed max daily mint");
        _;
    }

 	/**
 	* @dev increment moderator supply if not exceed allowed daily amount and max supply 
 	*/
    function _incrementModeratorSupply(uint256 _amount) 
    mintDailyLimitModerator(_amount)
    notExceedModeratorSupply(_amount)
    internal 
    {
        _totalModeratorMinted += _amount;
        _lastMintTime = block.timestamp;
    }

    function getTotalModeratorMinted() public view returns(uint256){
        return _totalModeratorMinted;
    }


  
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: ExtendedAccessControl.sol


pragma solidity ^0.8.0;



/**
 * @title ExtendedAccessControl
 * @dev This is a extension from openzeppelin AccessControl that allow to require determinated number of admin votes to assign or revoke roles
 */
abstract contract ExtendedAccessControl is AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _emergencyRecoverIds;

    /**
		@dev set required number of votes to assign or revoke role
	**/
    constructor(uint8 requiredVotes) {
        _requiredVotes = requiredVotes;
    }

    uint8 private _requiredVotes;
    /**
		@dev stores  approvals for specific address and role
	**/
    mapping(address => mapping(bytes32 => mapping(address => bool)))
        private _roleApprovalVotation;

    /**
		@dev stores address of administrators that voted to assign a role to a specific address
	**/
    mapping(address => mapping(bytes32 => address[]))
        private _rolesApprovalVotes;

    /**
		@dev stores votes to revoke specific role for an addres
	**/
    mapping(address => mapping(bytes32 => mapping(address => bool)))
        private _roleRevokeVotation;

    /**
		@dev stores address of admnistrators that voted to revoke a role to a specific address
	**/
    mapping(address => mapping(bytes32 => address[])) private _rolesRevokeVotes;

    /**

	*/

    event emergencyRecover(
        uint256 _id,
        uint256 _timestamp,
        bool _isDenied,
        bool _isCompleted,
        uint8 _votes
    );

    struct EmergencyRecoverRequest {
        address _beneficiary;
        uint256 _timestamp;
        bool _isDenied;
        bool _isCompleted;
        uint8 _votes;
    }

    uint256 private constant REQUIRED_EMERGENCY_TIME = 60 days;

    mapping(uint256 => EmergencyRecoverRequest) private _recoverRequest;
    mapping(uint256 => mapping(address => bool)) private _addressVotation;

    function createEmergencyRecover(address _beneficiary)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_beneficiary != address(0));
        require(_beneficiary != _msgSender());

        _emergencyRecoverIds.increment();

        uint256 id = _emergencyRecoverIds.current();

        _recoverRequest[id] = EmergencyRecoverRequest(
            _beneficiary,
            block.timestamp,
            false,
            false,
            1
        );
        _addressVotation[id][_msgSender()] = true;

        emit emergencyRecover(
            id,
            _recoverRequest[id]._timestamp,
            false,
            false,
            1
        );
    }

    function changeEmergencyRecoverStatus(uint256 id, bool isRevokeRequest )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _recoverRequest[id]._beneficiary != address(0),
            "doesn't exist"
        );
        require(_addressVotation[id][_msgSender()] == false, "already voted");
        require(_recoverRequest[id]._isDenied == false, "is denied");
        require(_recoverRequest[id]._isCompleted == false, "already completed");

        if (isRevokeRequest) {
            _recoverRequest[id]._isDenied = true;
        } else {
            _addressVotation[id][_msgSender()] = true;
            _recoverRequest[id]._votes++;
        }

        emit emergencyRecover(
            id,
            _recoverRequest[id]._timestamp,
            _recoverRequest[id]._isDenied,
            _recoverRequest[id]._isCompleted,
            _recoverRequest[id]._votes
        );
    }

    function applyEmergencyRecover(uint256 id)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _recoverRequest[id]._beneficiary != address(0),
            "doesn't exist"
        );
        require(_recoverRequest[id]._isDenied == false, "is denied");
        require(_recoverRequest[id]._isCompleted == false, "already completed");
        require(_recoverRequest[id]._votes > 0, "invalid request");
        uint256 elapsedTime = block.timestamp - _recoverRequest[id]._timestamp;
        uint256 decreaseTime = (15 days * _recoverRequest[id]._votes);
        uint256 requiredElapsedTime = 0;

        if (decreaseTime < REQUIRED_EMERGENCY_TIME) {
            requiredElapsedTime = REQUIRED_EMERGENCY_TIME - decreaseTime;
        }

        require(elapsedTime >= requiredElapsedTime, "can't apply yet");

        _recoverRequest[id]._isCompleted = true;

        super.grantRole(DEFAULT_ADMIN_ROLE, _recoverRequest[id]._beneficiary);

        emit emergencyRecover(
            id,
            _recoverRequest[id]._timestamp,
            _recoverRequest[id]._isDenied,
            _recoverRequest[id]._isCompleted,
            _recoverRequest[id]._votes
        );
    }

    /**
		@dev update votation to revoke role and if the number of votes are greater than the required votes revoke role 
	**/
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRoleVote(account, role);

        if (_rolesRevokeVotes[account][role].length >= _requiredVotes) {
            super.revokeRole(role, account);
            _restoreVotation(account, role);
        }
    }

    /**
		@dev update votation to assign a role to an address and if the votes are greater than required votes assign role
	**/
    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        _approveRoleVote(account, role);

        if (_rolesApprovalVotes[account][role].length >= _requiredVotes) {
            super.grantRole(role, account);
            _restoreVotation(account, role);
        }
    }

    /**
		@dev update votation to assign a role
	**/
    function _approveRoleVote(address _address, bytes32 _role)
        private
        returns (bool)
    {
        require(_address != address(0));
        require(
            !_roleApprovalVotation[_address][_role][_msgSender()],
            "You can vote only one time"
        );

        _roleApprovalVotation[_address][_role][_msgSender()] = true;
        _rolesApprovalVotes[_address][_role].push(_msgSender());

        return true;
    }

    /**
		@dev update votation to revoke a role
	**/
    function _revokeRoleVote(address _address, bytes32 _role)
        private
        returns (bool)
    {
        require(_address != address(0));
        require(
            !_roleRevokeVotation[_address][_role][_msgSender()],
            "You can vote only one time"
        );

        _roleRevokeVotation[_address][_role][_msgSender()] = true;
        _rolesRevokeVotes[_address][_role].push(_msgSender());

        return true;
    }

    /**
		@dev reset votation for specific address and role
	**/
    function _restoreVotation(address _address, bytes32 _role) private {
        for (
            uint256 i = 0;
            i < _rolesRevokeVotes[_address][_role].length;
            i++
        ) {
            delete _roleRevokeVotation[_address][_role][
                _rolesRevokeVotes[_address][_role][i]
            ];
        }
        delete _rolesRevokeVotes[_address][_role];

        for (
            uint256 i = 0;
            i < _rolesApprovalVotes[_address][_role].length;
            i++
        ) {
            delete _roleApprovalVotation[_address][_role][
                _rolesApprovalVotes[_address][_role][i]
            ];
        }
        delete _rolesApprovalVotes[_address][_role];
    }
}

// File: EterAccessControl.sol


pragma solidity 0.8.0;


/**
 * @title EterAccessControl
 * @dev This contract defines all roles and modifiers for Eter token authorization
 */
abstract contract EterAccessControl is ExtendedAccessControl {
    
	constructor(uint8 requiredVotes) 
	ExtendedAccessControl(requiredVotes){

	}
	
	bytes32 private constant ECOSYSTEM_MINTER_ROLE =
        keccak256("ECOSYSTEM_MINTER_ROLE");
    bytes32 private constant LIQUIDITY_MINTER_ROLE =
        keccak256("LIQUIDITY_MINTER_ROLE");
    bytes32 private constant MOD_MINTER_ROLE = keccak256("MOD_MINTER_ROLE");
    bytes32 private constant STAKING_MINTER_ROLE =
        keccak256("STAKING_MINTER_ROLE");
    bytes32 private constant EVENTS_MINTER_ROLE =
        keccak256("EVENTS_MINTER_ROLE");
    bytes32 private constant CONTENT_CREATORS_MINTER_ROLE =
        keccak256("CONTENT_CREATORS_MINTER_ROLE");
    bytes32 private constant BURN_ROLE = 
		keccak256("BURN_ROLE");

   



    modifier hasBurnRole() {
        require(
            hasRole(BURN_ROLE, msg.sender),
            "Only the burn role can perform this action"
        );
        _;
    }

    modifier hasEcosystemMinterRole() {
        require(
            hasRole(ECOSYSTEM_MINTER_ROLE, msg.sender),
            "Caller is not ecosystem minter"
        );
        _;
    }
    modifier hasLiquidityMinterRole() {
        require(
            hasRole(LIQUIDITY_MINTER_ROLE, msg.sender),
            "Caller is not liquidity minter"
        );
        _;
    }
    modifier hasModeratorRole() {
        require(
            hasRole(MOD_MINTER_ROLE, msg.sender),
            "Caller is not moderator"
        );
        _;
    }
    modifier hasStakingRole() {
        require(
            hasRole(STAKING_MINTER_ROLE, msg.sender),
            "Caller is not staking"
        );
        _;
    }
    modifier hasEventMinterRole() {
        require(hasRole(EVENTS_MINTER_ROLE, msg.sender), "Caller is not event");
        _;
    }
    modifier hasContentCreatorRole() {
        require(
            hasRole(CONTENT_CREATORS_MINTER_ROLE, msg.sender),
            "Caller is not content creator"
        );
        _;
    }

	/**
		@dev return all available roles
	**/
    function getRoles()
        public
        pure
        returns (
            bytes32 EcosystemMinter,
            bytes32 LiquidityMinter,
            bytes32 ModMinter,
            bytes32 StakingMinter,
            bytes32 EventsMinter,
            bytes32 ContentCreatorsMinter,
            bytes32 BurnRole
        )
    {
        EcosystemMinter = ECOSYSTEM_MINTER_ROLE;
        LiquidityMinter = LIQUIDITY_MINTER_ROLE;
        ModMinter = MOD_MINTER_ROLE;
        StakingMinter = STAKING_MINTER_ROLE;
        EventsMinter = EVENTS_MINTER_ROLE;
        ContentCreatorsMinter = CONTENT_CREATORS_MINTER_ROLE;
        BurnRole = BURN_ROLE;
    }

 
}

// File: Token.sol


pragma solidity 0.8.0;







contract ETER is
    ERC20,
    EterAccessControl,
    ContentCreator,
    Moderator,
    Staking,
    Event
{
    modifier notExceedMaximumSupply(uint256 _amount) {
        uint256 nextSupply = totalMinted + _amount;
        require(
            nextSupply < MAX_SUPPLY,
            "The transaction exceed maximum supply"
        );
        _;
    }

  //s
   
    uint256 public constant MAX_SUPPLY = 30000000 ether;
    
	uint256 public totalMinted = 0;
    uint256 private constant MAX_TEAM_SUPPLY = 2670000 ether;

    uint256 private constant MAX_PRIVATE_SALE_SELL = 1200000 ether;

    uint256 private constant MAX_ECOSYSTEM_SUPPLY = 18000000 ether;
	uint256 private constant MAX_LIQUIDITY_SUPPLY = 6000000 ether;
    uint256 public totalBurn = 0;

   	/*
		set all team members as administrators and mint private sell and team supply 
		team supply will have a vesting for 3 years
    */
    constructor(address CTO, address CEO, address INV1, address INV2) ERC20("Eterland","ETER")  EterAccessControl(4){

		uint256 initialMint = MAX_TEAM_SUPPLY + MAX_PRIVATE_SALE_SELL + MAX_ECOSYSTEM_SUPPLY + MAX_LIQUIDITY_SUPPLY;
        //Mint team supply
        _mint(msg.sender,initialMint);
		totalMinted += initialMint;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, CEO);
        _setupRole(DEFAULT_ADMIN_ROLE, CTO);
		_setupRole(DEFAULT_ADMIN_ROLE, INV1);
		_setupRole(DEFAULT_ADMIN_ROLE, INV2);
    }
	
	/**
     * @dev create amount of new tokens for the message sender from the 
	 moderator tokens

	 	Requirements:
		- the caller must have the `MOD_MINTER_ROLE`.
		- the amount must be less or equal than the MAX_DAILY_MINT for moderators 
		- the amount must be less or equal than MAX_SUPPLY
     */
    function mintModerator(uint256 _amount)
        public
        hasModeratorRole
        notExceedMaximumSupply(_amount)
    {
        require(msg.sender != address(0), "cannot mint to the zero address");
        _incrementModeratorSupply(_amount);
        _mint(msg.sender, _amount);
        totalMinted += _amount;
    }

	/**
     * @dev create amount of new tokens for the message sender from the 
	 staking tokens

	 	Requirements:
		- the caller must have the `STAKING_MINTER_ROLE`.
		- the amount must be less or equal than the MAX_DAILY_MINT for staking 
		- the amount must be less or equal than MAX_SUPPLY
     */
    function mintStaking(uint256 _amount)
        public
        hasStakingRole
        notExceedMaximumSupply(_amount)
    {
        require(msg.sender != address(0), "cannot mint to the zero address");
        _increaseTotalStakingMinted(_amount);
        _mint(msg.sender, _amount);
        totalMinted += _amount;
    }

	/**
     * @dev create amount of new tokens for the message sender from the 
	 event tokens

	 	Requirements:
		- the caller must have the `EVENTS_MINTER_ROLE`.
		- the amount must be less or equal than the MAX_DAILY_MINT for events 
		- the amount must be less or equal than MAX_SUPPLY
     */
    function mintEvent(uint256 _amount)
        public
        hasEventMinterRole
        notExceedMaximumSupply(_amount)
    {
        require(msg.sender != address(0), "cannot mint to the zero address");
        _incrementEventSupply(_amount);
        _mint(msg.sender, _amount);
		totalMinted += _amount;
    }

	/**
     * @dev create amount of new tokens for the message sender from the 
	 content creator tokens

	 	Requirements:
		- the caller must have the `CONTENT_CREATORS_MINTER_ROLE`.
		- the amount must be less or equal than the MAX_DAILY_MINT for content creators 
		- the amount must be less or equal than MAX_SUPPLY
     */
    function mintContentCreator(uint256 _amount)
        public
        hasContentCreatorRole
        notExceedMaximumSupply(_amount)
    {
        require(msg.sender != address(0), "cannot mint to the zero address");
        increaseTotalContentCreatorMinted(_amount);
        _mint(msg.sender, _amount);
        totalMinted += _amount;
    }

	/**
     * @dev	burn amount of tokens from the message sender

	 	Requirements:
		- the caller must have the `BURN_ROLE`.
     */
    function burn(uint256 _amount) public hasBurnRole {
		
        _burn(msg.sender, _amount);
        totalBurn += _amount;
        
    }

	function _beforeTokenTransfer(address from,address  to,uint256 amount) 
	internal view override {
	   // if some user transfer his tokens to this contract will loss the funds so we prevent
	   require( to != address(this) );
	}
    
}