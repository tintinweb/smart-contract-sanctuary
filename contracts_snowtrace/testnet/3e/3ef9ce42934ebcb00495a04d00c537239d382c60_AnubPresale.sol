/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT
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

// File: AnubPresale.sol


pragma solidity ^0.8.0;


contract AnubPresale {

    uint constant MIM_units = 10 ** 18;
    uint constant ANB_units = 10 ** 18;

    uint public constant PRESALE_MAX_TOKEN = 50000 * ANB_units ;
    uint public constant DEFAULT_ANB_PRICE = 10 * MIM_units / ANB_units ;
    uint public constant MIN_PER_ACCOUNT = 25 * ANB_units;
    uint public constant MAX_PER_ACCOUNT = 490 * ANB_units;
    uint public constant GUARANTEED_PER_ACCOUNT = 50 * ANB_units;

    ERC20 MIM;

    mapping (address => bool) private whiteListedMap;

    address public owner;
    ERC20 public presale_token;
    uint public presale_sold;
    bool public presale_enable;
    bool public presale_claim_enable;

    struct Sold {
        uint256 guaranteedSold;
        uint256 totalSold;
    }

    mapping( address => Sold ) private soldListed;

    struct Claim {
        uint256 lastClaimed;
        uint256 amountClaimable;
        uint256 totalClaimed;
    }

    mapping( address => Claim ) private dailyClaimed;

    address[] private multisig_addresses;
    mapping( address => bool ) private multiSig;

    constructor() {
        //0x130966628846BFd36ff31a822705796e8cb8C18D
        MIM = ERC20(0xca05AD261B1E255346b51afebb98915F32121e30);
        owner = msg.sender;
    }

    /* Security */

    modifier isFromContract() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }

    /* Owner */

    modifier isOwner() {
      require(msg.sender == owner);
      _;
    }

    function setPresaleState(bool _state) isOwner external {
        presale_enable = _state;
    }

    function setPresaleClaimState(bool _state) isOwner external {
        presale_claim_enable = _state;
    }

    function setPresaleToken(address _address) isOwner external {
        presale_token = ERC20(_address);
    }

    /* Multisig */

    function setMultiSig(address[] memory _owners) isOwner external {
        multisig_addresses = _owners;
        for(uint256 i = 0; _owners.length > i; i++ ) {
            multiSig[_owners[i]] = false;
        }
    }
        
    function canSign(address signer) private view returns (bool) {
        for(uint256 i = 0; multisig_addresses.length > i; i++ ) {
            if(multisig_addresses[i] == signer) {
                return true;
            }
        }
        return false;
    }

    function setSign(address signer, bool state) isOwner external {
        require(canSign(signer), "Signer is not in the multisign");
        multiSig[signer] = state;
    }

    function isAllSign() public view returns (bool) {
        for(uint256 i = 0; multisig_addresses.length > i; i++ ) {
            if(!multiSig[multisig_addresses[i]]) {
                return false;
            }
        }
        return multisig_addresses.length > 0;
    }

    function transfer(address recipient, uint256 amountOut) isOwner public {
        require(isAllSign(), "Multi sign required");
        MIM.transfer(recipient, amountOut);
    }

    function currentSold() external view returns (uint256) {
        return MIM.balanceOf(address(this));
    }

    /* Whitelist */
    
    function isWhiteListed(address recipient) public view returns (bool) {
        return whiteListedMap[recipient];
    }

    function setWhiteListed(address[] memory addresses) isOwner public {
        // Initialized whiteListed
        for(uint256 i = 0; addresses.length > i; i++ ) {
            whiteListedMap[addresses[i]] = true;
            soldListed[addresses[i]].guaranteedSold = GUARANTEED_PER_ACCOUNT;
        }
        //Reserved guaranteed token
        presale_sold += addresses.length * GUARANTEED_PER_ACCOUNT;
    }

    /* Buyer */

    function maxBuyable(address buyer) external view returns (uint) {
        return MAX_PER_ACCOUNT - soldListed[buyer].totalSold;
    }

    function buyAnubToken(uint256 amountIn) external isFromContract {
        // All requirements
        require(presale_enable, "Presale disabled");
        require(isWhiteListed(msg.sender), "Not whitelised");
        require(MIM.balanceOf(msg.sender) >= amountIn * DEFAULT_ANB_PRICE, "MIM Balance insufficient");
        require(soldListed[msg.sender].guaranteedSold <= amountIn || presale_sold + amountIn <= PRESALE_MAX_TOKEN, "No more token available (limit reached)");
        require(amountIn >= MIN_PER_ACCOUNT, "Amount is not sufficient");
        require(amountIn + soldListed[msg.sender].totalSold <= MAX_PER_ACCOUNT, "Amount buyable reached");

        // //Adjust guaranteed token
        if(soldListed[msg.sender].guaranteedSold > 0) {
            // Not buying only the guaranteed token
            if(soldListed[msg.sender].guaranteedSold - amountIn < 0) {
                // Still have none guaranteed token available?
                if (presale_sold + amountIn > PRESALE_MAX_TOKEN) {
                    amountIn = PRESALE_MAX_TOKEN - presale_sold; // adjust to buy last token available
                }
                presale_sold += amountIn - soldListed[msg.sender].guaranteedSold ;
                soldListed[msg.sender].guaranteedSold = 0;
            } else {
                soldListed[msg.sender].guaranteedSold -= amountIn;
            }
        } else { // None guaranteed tokens
            presale_sold += amountIn;
        }

        // Requirements are respected we can procced to the transfer
        MIM.transferFrom(msg.sender, address(this), amountIn * DEFAULT_ANB_PRICE);
        soldListed[msg.sender].totalSold += amountIn;
    }

     function currentAnb(address buyer) external view returns (uint) {
        return soldListed[buyer].totalSold;
    }
    
    function claimAnubToken() external isFromContract {
        // All requirements
        require(presale_claim_enable, "Claim disabled");
        require(soldListed[msg.sender].totalSold < dailyClaimed[msg.sender].totalClaimed, "No tokens to claim");
        require(dailyClaimed[msg.sender].lastClaimed < block.timestamp, "Daily claimed already transfered");

        // First claim ever
        if(dailyClaimed[msg.sender].lastClaimed == 0) {
            dailyClaimed[msg.sender].amountClaimable = soldListed[msg.sender].totalSold * 36/100; //36% first claim
            dailyClaimed[msg.sender].lastClaimed = block.timestamp; // refer to this timestamp to claim again
        } else {
            dailyClaimed[msg.sender].amountClaimable = soldListed[msg.sender].totalSold * 16/100; //16% daily claim
        }

        uint amountOut = dailyClaimed[msg.sender].amountClaimable;

        // Adjust amountOut in case of last claim
        if(dailyClaimed[msg.sender].totalClaimed + amountOut > soldListed[msg.sender].totalSold) {
            amountOut = soldListed[msg.sender].totalSold - dailyClaimed[msg.sender].totalClaimed;
        }

        // Transfer ANB
        presale_token.transfer(msg.sender, amountOut);
        dailyClaimed[msg.sender].totalClaimed += amountOut;
        dailyClaimed[msg.sender].lastClaimed += 86400; // Wait 24h until next claim
    }
}