/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol



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

// File: HomoCrypton.sol


pragma solidity ^0.8.9;


contract HomoCrypton is ERC20 {
    address public admin;
    uint256 public currTime;
    uint256 public startingSupply = 78749657320 * 10 ** 18;
    
    constructor() ERC20('Homocrypton', 'HOMO') {
        _mint(msg.sender, 78749657320 * 10 ** 18);
        admin = msg.sender;
    }
    
    function updateSupply(uint256 lastEnd, uint256 nestStart, uint256 currSupply) internal {
        currTime = block.timestamp;
        if (currTime > lastEnd && currTime < nestStart) {
            currSupply = currSupply *10 **18;
            if (startingSupply < currSupply) {
                _mint(admin, currSupply-startingSupply);
                startingSupply = currSupply;
            } else {
                revert ('SupplyForCurrentYearAlreadyAdjusted UseTimeMachineToChange');
            }
            
        } else {
            revert ('NotCurrentYear UseTimeMachineToGoThere');
        }
        
    }
    
    function USHER2022() external {
        updateSupply(1640995199,1672531200,79539525770);
    }
     function USHER2023() external {
        updateSupply(1672531199,1704067200,80318003380);
    }
    function USHER2024() external {
        updateSupply(1704067199,1735689600,81086052550);
    }
    function USHER2025() external {
        updateSupply(1735689599,1767225600,81844374530);
    }
    function USHER2026() external {
        updateSupply(1767225599,1798761600,82592766510);
    }
    function USHER2027() external {
        updateSupply(1798761599,1830297600,83330783180);
    }
    function USHER2028() external {
        updateSupply(1830297599,1861920000,84058633010);
    }
    function USHER2029() external {
        updateSupply(1861919999,1893456000,84776607230);
    }
    function USHER2030() external {
        updateSupply(1893455999,1924992000,85484873710);
    }
    function USHER2031() external {
        updateSupply(1924991999,1956528000,86183494540);
    }
    function USHER2032() external {
        updateSupply(1956527999,1988150400,86872278730);
    }
    function USHER2033() external {
        updateSupply(1988150399,2019686400,87550835120);
    }
    function USHER2034() external {
        updateSupply(2019686399,2051222400,88218627050);
    }
    function USHER2035() external {
        updateSupply(2051222399,2082758400,88875242290);
    }
    function USHER2036() external {
        updateSupply(2082758399,2114380800,89520488850);
    }
    function USHER2037() external {
        updateSupply(2114380799,2145916800,90154376160);
    }
    function USHER2038() external {
        updateSupply(2145916799,2177452800,90776936450);
    }
    function USHER2039() external {
        updateSupply(2177452799,2208988800,91388285620);
    }
    function USHER2040() external {
        updateSupply(2208988799,2240611200,91988473820);
    }
    function USHER2041() external {
        updateSupply(2240611199,2272147200,92577454830);
    }
    function USHER2042() external {
        updateSupply(2272147199,2303683200,93155081530);
    }
    function USHER2043() external {
        updateSupply(2303683199,2335219200,93721182470);
    }
    function USHER2044() external {
        updateSupply(2335219199,2366841600,94275553820);
    }
    function USHER2045() external {
        updateSupply(2366841599,2398377600,94818032720);
    }
    function USHER2046() external {
        updateSupply(2398377599,2429913600,95348546730);
    }
    function USHER2047() external {
        updateSupply(2429913599,2461449600,95867077490);
    }
    function USHER2048() external {
        updateSupply(2461449599,2493072000,96373573200);
    }
    function USHER2049() external {
        updateSupply(2493071999,2524608000,96868001460);
    }
    function USHER2050() external {
        updateSupply(2524607999,2556144000,97350339000);
    }
    function USHER2051() external {
        updateSupply(2556143999,2587680000,97820617580);
    }
    function USHER2052() external {
        updateSupply(2587679999,2619302400,98278854410);
    }
    function USHER2053() external {
        updateSupply(2619302399,2650838400,98725015620);
    }
    function USHER2054() external {
        updateSupply(2650838399,2682374400,99159052510);
    }
    function USHER2055() external {
        updateSupply(2682374399,2713910400,99580987460);
    }
    function USHER2056() external {
        updateSupply(2713910399,2745532800,99990851670);
    }
    function USHER2057() external {
        updateSupply(2745532799,2777068800,100388812620);
    }
    function USHER2058() external {
        updateSupply(2777068799,2808604800,100775180800);
    }
    function USHER2059() external {
        updateSupply(2808604799,2840140800,101150363600);
    }
    function USHER2060() external {
        updateSupply(2840140799,2871763200,101514696830);
    }
    function USHER2061() external {
        updateSupply(2871763199,2903299200,101868372090);
    }
    function USHER2062() external {
        updateSupply(2903299199,2934835200,102211490400);
    }
    function USHER2063() external {
        updateSupply(2934835199,2966371200,102544190040);
    }
    function USHER2064() external {
        updateSupply(2966371199,2997993600,102866583540);
    }
    function USHER2065() external {
        updateSupply(2997993599,3029529600,103178793150);
    }
    function USHER2066() external {
        updateSupply(3029529599,3061065600,103480980790);
    }
    function USHER2067() external {
        updateSupply(3061065599,3092601600,103773308300);
    }
    function USHER2068() external {
        updateSupply(3092601599,3124224000,104055905320);
    }
    function USHER2069() external {
        updateSupply(3124223999,3155760000,104328891360);
    }
    function USHER2070() external {
        updateSupply(3155759999,3187296000,104592395010);
    }
    function USHER2071() external {
        updateSupply(3187295999,3218832000,104846548580);
    }
    function USHER2072() external {
        updateSupply(3218831999,3250454400,105091504020);
    }
    function USHER2073() external {
        updateSupply(3250454399,3281990400,105327428610);
    }
    function USHER2074() external {
        updateSupply(3281990399,3313526400,105554500030);
    }
    function USHER2075() external {
        updateSupply(3313526399,3345062400,105772881950);
    }
    function USHER2076() external {
        updateSupply(3345062399,3376684800,105982741720);
    }
    function USHER2077() external {
        updateSupply(3376684799,3408220800,106184209090);
    }
    function USHER2078() external {
        updateSupply(3408220799,3439756800,106377368190);
    }
    function USHER2079() external {
        updateSupply(3439756799,3471292800,106562282330);
    }
    function USHER2080() external {
        updateSupply(3471292799,3502915200,106739044540);
    }
    function USHER2081() external {
        updateSupply(3502915199,3534451200,106907733350);
    }
    function USHER2082() external {
        updateSupply(3534451199,3565987200,107068524260);
    }
    function USHER2083() external {
        updateSupply(3565987199,3597523200,107221713750);
    }
    function USHER2084() external {
        updateSupply(3597523199,3629145600,107367654440);
    }
    function USHER2085() external {
        updateSupply(3629145599,3660681600,107506623530);
    }
    function USHER2086() external {
        updateSupply(3660681599,3692217600,107638740230);
    }
    function USHER2087() external {
        updateSupply(3692217599,3723753600,107764020190);
    }
    function USHER2088() external {
        updateSupply(3723753599,3755376000,107882489480);
    }
    function USHER2089() external {
        updateSupply(3755375999,3786912000,107994133660);
    }
    function USHER2090() external {
        updateSupply(3786911999,3818448000,108098923030);
    }
    function USHER2091() external {
        updateSupply(3818447999,3849984000,108196826430);
    }
    function USHER2092() external {
        updateSupply(3849983999,3881606400,108287809590);
    }
    function USHER2093() external {
        updateSupply(3881606399,3913142400,108371820770);
    }
    function USHER2094() external {
        updateSupply(3913142399,3944678400,108448787980);
    }
    function USHER2095() external {
        updateSupply(3944678399,3976214400,108518601450);
    }
    function USHER2096() external {
        updateSupply(3976214399,4007836800,108581115870);
    }
    function USHER2097() external {
        updateSupply(4007836799,4039372800,108636147760);
    }
    function USHER2098() external {
        updateSupply(4039372799,4070908800,108683476360);
    }
    function USHER2099() external {
        updateSupply(4070908799,4102444800,108722841340);
    }
    function USHER2100() external {
        updateSupply(4102444799,4133980800,108753937190);
    }

}