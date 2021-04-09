// SPDX-License-Identifier: UNLICENSED
/*
 * https://cannappscorp.com/ -- Global Cannabis Applications Corporation (GCAC)
 *
 * Address: Suite 830, 1100 Melville Street, Vancouver, British Columbia, V6E 4A6 Canada
 * Email: [email protected]
 *
 * As at 31-March-2021, GCAC is a publicly traded company on the Canadian Stock Exchange.
 *
 * Official GCAC Listing
 * https://www.thecse.com/en/listings/technology/global-cannabis-applications-corp
 *
 * Official GCAC Regulatory Filings 
 * https://www.sedar.com/DisplayCompanyDocuments.do?lang=EN&issuerNo=00036309
 *
 * This is an ERC-20 smart contract for the GCAC token that will be used as one side
 * of a Uniswap liquidity pool trading pair. This GCAC token has the following properties:
 *
 * 1. The number of GCAC tokens from this contract that will be initially added to the 
 *    Uniswap liquidity pool shall be 100,000. The amount of WETH added to the other side of
 *    the initial Uniswap liquidity pool shall be 5.
 * 2. GCAC hereby commits to swap an amount of WETH currency with the Uniswap GCAC<>WETH 
 *    trading pair every 3 months for no fewer than 8 quarters, i.e., 2 years, commencing 
 *    for the quarterly report as filed by GCAC for the quarter ending 31-March-2021.
 * 3. The value of the WETH currency swapped by GCAC shall be equal to 1% of GCAC's official
 *    'revenue', as disclosed in each of its quarterly regulatory filings. Each WETH
 *    swap shall be performed no later than 10 working days after the regulatory filing is
 *    available on the System for Electronic Document Analysis and Retrieval (SEDAR). SEDAR 
 *    is a mandatory document filing system for Canadian public companies.
 * 4. GCAC tokens returned by Uniswap from the quarterly swap of WETH shall be burned 
 *    by this smart contract, thereby reducing GCAC token circulating supply over time.
 * 5. This contract shall not be allowed mint any new GCAC tokens, i.e., no dilution.
 * 6. GCAC, the company, shall initially hold 100,000 GCAC tokens on its corporate
 *    balance sheet, i.e., the GCAC treasury tokens.
 * 7. GCAC's treasury tokens may only ever be swapped for WETH in Uniswap and are prevented
 *    from being transferred out of this contract to another exchange or wallet, i.e., no rug-pull.
 * 8. GCAC hereby commits to notify the DeFi community of its intent to withdraw liquidity from 
 *    Uniswap at least 3 months in advance. This contact enforces the liquidity-time-lock.
 * 9. GCAC hereby commits to notify the DeFi community of its intent to swap GCAC treasury tokens 
 *    on Uniswap at least 3 months in advance. This contact enforces the treasury-time-lock.
 *
 *
 * https://abbey.ch/         -- Abbey Technology GmbH, Zug, Switzerland
 * 
 * ABBEY DEFI
 * ========== 
 * 1. Decentralized Finance 'DeFi' is designed to be globally inclusive. 
 * 2. Centralized finance is based around national stock markets that have high barriers to entry. 
 * 3. The Abbey DeFi methodology offers companies listed on national stock exchanges exposure to DeFi.
 *
 * Abbey is a Uniswap-based DeFi service provider that allows public companies to offer people a novel 
 * way to speculate on the success of their business in a decentralized manner.
 * 
 * The premise is both elegant and simple, the public company commits to a marketing spend equal to 1% 
 * of its quarterly sales revenue. And, since it’s a public company, the exact value of this 1% is 
 * published in their public accounts, as filed quarterly with a national securities regulator.
 * 
 * Using Abbey as a Uniswap DeFi marketing agency, the public company spends 1% of its quarterly cash 
 * sales revenue on one side of a bespoke Uniswap trading contract. The other side of the Uniswap trade 
 * is the public company’s proprietary token that’s representing 1% of its future sales revenue.
 * 
 * DeFi traders wishing to speculate on the revenue growth of the public company deposit crypto-USD 
 * in return for “PUBCO-1%” Uniswap tokens. The Uniswap Automated Market Maker ensures DeFi market 
 * liquidity and legitimate price discovery. The more USD that the company deposits over time, the 
 * higher the value of the PUBCO-1% token, as held by DeFi speculators.
 *
*/
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Global Cannabis Applications Corporation (GCAC) contract for Uniswap.
 * @author Abbey Technology GmbH
 * @notice Token contract for use with Uniswap.  Enforces restrictions outlined in the prospectus.
 */
contract GCACToken is ERC20 {

    enum TokenType { Unknown, GCAC, LiquidityPool }

    /**
     * @notice The details of a future company cashout.
     */
    struct Notice {
        // The maximum number of tokens proposed for sale.
        uint256 amount;

        // The date after which company tokens can be swapped.
        uint256 releaseDate;

        // Whether the notice given is for this contract's tokens (GCAC) or the
        // liquidity pool tokens created by Uniswap where fees are periodically
        // cashed in.
        TokenType tokenType;
    }

    // Event fired when a restricted wallet gives notice of a potential future trade.
    event NoticeGiven(address indexed who, uint256 amount, uint256 releaseDate, TokenType tokenType);

    /**
     * @notice Notice must be given to the public before treasury tokens can be swapped.
     */
    Notice public noticeTreasury;

    /**
     * @notice Notice must be given to the public before Liquidity Tokens can be removed from the pool.
     */
    Notice public noticeLiquidity;

    /**
    * @notice The account that created this contract, also functions as the liquidity provider.
    */
    address public owner;

    /**
     * @notice Holder of the company's 50% share of all Uniswap tokens.  Can only interact with the
     * Uniswap pair/router, is forbidden from trading tokens elsewhere.
     */
    address public treasury;

    /**
     * @notice The account that performs the 1% of sales buyback of tokens, all bought tokens are burned.
     * @dev They cannot be autoburned during transfer as the Uniswap client prevents the transaction.
     */
    address public buyback;

    /**
     * @notice The address of the Uniswap router, the liquidity provider and treasury can only interact with this
     * address.  This prevents trading outside of Uniswap for these accounts.
     */
    address public router;

    /**
     * @notice The address of the Uniswap Pair/ERC20 contract holding the Liquidity Pool tokens.
     */
    address public pairAddress;

    /**
     * @notice Restrict functionaly to the contract owner.
     */
    modifier onlyOwner {
        require(_msgSender() == owner, "You are not Owner.");
        _;
    }

    /**
     * @notice Restrict functionaly to the buyback account.
     */
    modifier onlyBuyback {
        require(_msgSender() == buyback, "You are not Buyback.");
        _;
    }

    constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20(name, symbol) {
        owner = _msgSender();
        _mint(_msgSender(), initialSupply);
    }

    /**
     * Set the account that burns GCAC tokens periodically.
     */
    function setBuyback(address who) public onlyOwner {
        require(buyback == address(0), "The Buyback address can only be set once.");
        buyback = who;
    }

    /**
     * Set the address of the account holding GCAC tokens on behalf of the company.
     */
    function setTreasury(address who) public onlyOwner {
        require(treasury == address(0), "The Treasury address can only be set once.");
        treasury = who;
    }

    /**
     * Set the address of the Uniswap router, only this address is allowed to move Treasury tokens.
     */
    function setRouter(address who) public onlyOwner {
        require(router == address(0), "The Router address can only be set once.");
        router = who;
    }

    /**
     * Set the address of the Uniswap Pair/Pool contract.
     */
    function setPairAddress(address who) public onlyOwner {
        require(pairAddress == address(0), "The Pair address can only be set once.");
        pairAddress = who;
    }

    /**
     * @notice Treasury and Liquidity tokens must give advanced notice to the public before they can
     * be used.  The token type is determined by the address giving notice.
     *
     * @param who The address giving notice of a sale in the future.
     * @param amount The maximum number of tokens (in wei).
     * @param numSeconds The number of seconds the tokens cannot be sold for.
     */
    function giveNotice(address who, uint256 amount, uint256 numSeconds) public onlyOwner {
        require(pairAddress != address(0), "The Uniswap Pair contract address must be set.");
        require(who == treasury || who == address(this), "Only Treasury and Liquidity must give notice.");

        uint256 when = block.timestamp + (numSeconds * 1 seconds);

        TokenType tokenType;

        if(who == treasury) {
            require(noticeTreasury.releaseDate == 0 || block.timestamp >= noticeTreasury.releaseDate, "Cannot overwrite an active existing notice.");
            require(amount <= balanceOf(who), "Can't give notice for more GCAC tokens than owned.");
            tokenType = TokenType.GCAC;
            noticeTreasury = Notice(amount, when, tokenType);
        }
        else {
            require(noticeLiquidity.releaseDate == 0 || block.timestamp >= noticeLiquidity.releaseDate, "Cannot overwrite an active existing notice.");
            ERC20 pair = ERC20(pairAddress);
            require(amount <= pair.balanceOf(who), "Can't give notice for more Liquidity Tokens than owned.");
            tokenType = TokenType.LiquidityPool;
            noticeLiquidity = Notice(amount, when, tokenType);
        }

        emit NoticeGiven(who, amount, when, tokenType);
    }

    /**
     * @notice Enforce rules around the company accounts:
     * - Liquidity Pool Creator (owner) can never receive tokens back from Uniswap.
     * - Treasury can only send tokens to Uniswap.
     * - Tokens bought back by the company are immediateley burned.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(recipient != owner, "Liquidity Pool Creator cannot receive tokens.");
        require(sender != buyback, "Buyback cannot transfer tokens, it can only burn.");
        if(sender == treasury) {
            require(_msgSender() == router, "Treasury account tokens can only be moved by the Uniswap Router.");
            require(noticeTreasury.releaseDate != 0 && block.timestamp >= noticeTreasury.releaseDate, "Notice period has not been set or has not expired.");
            require(amount <= noticeTreasury.amount, "Treasury can't transfer more tokens than given notice for.");
            require(noticeTreasury.tokenType == TokenType.GCAC, "The notice given for this user is the wrong token type.");

            // Clear the remaining notice balance, this prevents giving notice on all tokens and
            // trickling them out.
            noticeTreasury = Notice(0, 0, TokenType.Unknown);
        }

        super._transfer(sender, recipient, amount);
    }

    /**
     * @notice Periodically draw down any fee entitlement from the Liquidity Pool after giving notice.
     * @param to The account to send the tokens to.
     * @param amount The number of tokens, in wei.
     */
    function transferLiquidityTokens(address to, uint256 amount) public onlyOwner {
        require(pairAddress != address(0), "The Uniswap Pair contract address must be set.");

        require(noticeLiquidity.releaseDate != 0 && block.timestamp >= noticeLiquidity.releaseDate, "Notice period has not been set or has not expired.");
        require(amount <= noticeLiquidity.amount, "Insufficient Liquidity Token balance.");
        require(noticeLiquidity.tokenType == TokenType.LiquidityPool, "The notice given for this user is the wrong token type.");

        ERC20 pair = ERC20(pairAddress);
        pair.transfer(to, amount);

        // Clear the notice even if only partially used.
        noticeLiquidity = Notice(0, 0, TokenType.Unknown);
    }

    /**
     * @notice The buyback account periodically buys tokens and then burns them to reduce the
     * total supply pushing up the price of the remaining tokens.
     */
    function burn() public onlyBuyback {
        _burn(buyback, balanceOf(buyback));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}