/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

pragma solidity 0.8.4;

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


/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}



contract CoinversationToken is ERC20Capped {
    uint256 public immutable startReleaseBlock;   // the block num when initial distribution start. e.g. 2011.11.8
    uint256 public constant MONTH = 195622; // 30 * 24 * 60 * 60 / 13.25

    mapping(address => uint256) public locks12;
    mapping(address => uint256) public lastUnlockEra12;

    mapping(address => uint256) public locks24;
    mapping(address => uint256) public lastUnlockEra24;
    mapping(address => uint256) public addressStartReleaseBlock;
    address public constant DEV_ACCOUNT = 0x2326eAb2a83bbe25dE8B9D0A8cB6dc63Dae6BaF9;
    bool public isDevInitialFundMinted = false;

    constructor(uint256 _startReleaseBlock)
        ERC20("Coinversation Token", "CTO")
        ERC20Capped(100000000 * (10 ** decimals()))
    {
        //13566600
        startReleaseBlock = _startReleaseBlock;

        //for initial release
        ERC20._mint(0xDAc57a2C77a64AEFC171339F2891871d9A298EC5, 3604834 * 10 ** decimals());

        //investors' funds locks up in 12 MONTHs
        locks12[0x707E4A05B3dDC2049387BF7B7CFe82D6F09e986e] = 7107144 * (10 ** (decimals() - 1));
        locks12[0x316D0e55B47ad86443b25EAa088e203482645046] = 425000 * (10 ** decimals());
        locks12[0xA7060deA79008DEf99508F50DaBDCDe7293c1D8A] = 349225 * (10 ** decimals());
        locks12[0xC286Bc3F74fAce4387959665aF71253461c28d34] = 2125000 * (10 ** decimals());

        locks12[0x3C68319b15Bc0145ce111636f6d8043ACF4D59f6] = 228572 * (10 ** decimals());
        locks12[0x175dd00579DF16669fC993F8AFA4EE8AA962865A] = 228572 * (10 ** decimals());
        locks12[0x729Ea64B1393eD633C069aF04b45e1212905b4A9] = 120000 * (10 ** decimals());
        locks12[0x2C9bC9793AD5c24feD22654Ee13F287329668B55] = 571432 * (10 ** (decimals() - 1));
        locks12[0x2295b2e2F0C8CF5e4E9c2cae33ad4F4cCbc95fD5] = 857144 * (10 ** (decimals() - 1));

        locks12[0xB7d41bb3863E403c29Fe4CA85D31206b6b507630] = 187500 * (10 ** decimals());
        locks12[0x6D9e32012eC93EBb858F9103B9F7f52eBAb6299F] = 262500 * (10 ** decimals());
        locks12[0x97CA08d4CA2015545eeb81ca71d1Ac719Fe4A8F6] = 93750 * (10 ** decimals());
        locks12[0x968dF8FBF4d7c6C46282a46C5DA7d514b23a98fa] = 562500 * (10 ** decimals());

        locks12[0x16f9cEB2D822ee203a304635d12897dBD2cEeB75] = 93750 * (10 ** decimals());
        locks12[0xe32341a633FA57CA963D2F2dc78D31D76ee258B7] = 65625 * (10 ** decimals());
        locks12[0xE88540354a9565300D2E7109d7737508F4155A4d] = 56250 * (10 ** decimals());
        locks12[0x570DaFD281d70d8d69D19c5A004b0FC3fF52Fd0b] = 56250 * (10 ** decimals());
        locks12[0x9D400eb10623d34CCEc7aaa9FC347921866B9c86] = 75000 * (10 ** decimals());

        locks12[0xb87230a8169366051b1732DfB4687F2A041564cf] = 211425 * (10 ** (decimals() - 1));
        locks12[0x67c069523115A6ffE9192F85426cF79f8b4ba7a5] = 2586225 * (10 ** (decimals() - 2));
        locks12[0x8786CB3682Cb347AE1226b5A15E991339A877Dfb] = 2586225 * (10 ** (decimals() - 2));

        //Project Development Fund locks up in 24 MONTHs
        locks24[0x9C94F95fBa7aDcf936043b817817e18fcb611857] = 12750000 * (10 ** decimals());
        addressStartReleaseBlock[0x9C94F95fBa7aDcf936043b817817e18fcb611857] = _startReleaseBlock;

        //Dev Group Fund locks up in 24 MONTHs and the initial release needs to be delayed by one more MONTH
        locks24[DEV_ACCOUNT] = 13500000 * (10 ** decimals());
        addressStartReleaseBlock[DEV_ACCOUNT] = _startReleaseBlock + MONTH;
    }

    function nextUnlockBlock12(address _account) public view returns (uint) {
        if(locks12[_account] > 0){
            return 0;
        }else{
            return startReleaseBlock + ((lastUnlockEra12[_account] + 1) * MONTH);
        }
    }

    function canUnlockAmount12(address _account) public view returns (uint256, uint) {
        uint startBlock = startReleaseBlock;
        uint lastEra = lastUnlockEra12[_account];
        // When block number less than nextReleaseBlock, no CTO can be unlocked
        if (block.number < (startBlock + ((lastEra + 1) * MONTH))) {
            return (0, 0);
        }
        // When block number more than endReleaseBlock12, all locked CTO can be unlocked
        else if (block.number >= (startBlock + (12 * MONTH))) {
            return (locks12[_account], 12 - lastEra);
        }
        // When block number is more than nextReleaseBlock but less than endReleaseBlock12,
        // some CTO can be released
        else {
            uint eras = (block.number - (startBlock + (lastEra * MONTH))) / MONTH;
            return (locks12[_account] / (12 - lastEra) * eras, eras);
        }
    }

    function canUnlockAmount24(uint _specificStartReleaseBlock, address _account) public view returns (uint256, uint) {
        uint startBlock = _specificStartReleaseBlock;
        uint lastEra = lastUnlockEra24[_account];
        // When block number less than nextReleaseBlock, no CTO can be unlocked
        if (block.number < (startBlock + ((lastEra + 1) * MONTH))) {
            return (0, 0);
        }
        // When block number more than endReleaseBlock24, all locked CTO can be unlocked
        else if (block.number >= (startBlock + (24 * MONTH))) {
            return (locks24[_account], 24 - lastEra);
        }
        // When block number is more than nextReleaseBlock but less than endReleaseBlock24,
        // some CTO can be released
        else {
            uint eras = (block.number - (startBlock + (lastEra * MONTH))) / MONTH;
            return (locks24[_account] / (24 - lastEra) * eras, eras);
        }
    }


    function unlock12() public {
        (uint256 amount, uint eras) = canUnlockAmount12(msg.sender);
        require(amount > 0, "none unlocked CTO");

        _mint(msg.sender, amount);

        locks12[msg.sender] = locks12[msg.sender] - amount;
        lastUnlockEra12[msg.sender] = lastUnlockEra12[msg.sender] + eras;
    }

    function unlock24() public {
        (uint256 amount, uint eras) = canUnlockAmount24(addressStartReleaseBlock[msg.sender], msg.sender);
        require(amount > 0, "none unlocked CTO");

        _mint(msg.sender, amount);

        locks24[msg.sender] = locks24[msg.sender] - amount;
        lastUnlockEra24[msg.sender] = lastUnlockEra24[msg.sender] + eras;
    }

    function mintDevInitialFund() public {
        require(!isDevInitialFundMinted, "already minted");
        require(block.number > addressStartReleaseBlock[DEV_ACCOUNT], "time is not up yet");

        _mint(DEV_ACCOUNT, 1500000 * 10 ** decimals());
        isDevInitialFundMinted = true;
    }
}