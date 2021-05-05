/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// Dependency file: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// Dependency file: @openzeppelin/contracts/security/Pausable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/security/ReentrancyGuard.sol


// pragma solidity ^0.8.0;

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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


// Dependency file: @openzeppelin/contracts/token/ERC20/ERC20.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/Context.sol";

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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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


// Dependency file: contracts/token/ZilliosToken.sol


// pragma solidity 0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

contract ZilliosToken is ERC20, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable() {}

    modifier canMint() {
        require(!mintingFinished, "ERC20: Minting is finished");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyOwner canMint returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function finishMinting() external onlyOwner returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function burn(uint256 _unsoldTokens) external onlyOwner returns (bool) {
        _burn(msg.sender, _unsoldTokens);
        return true;
    }
}


// Dependency file: contracts/base/Crowdsale.sol


// pragma solidity 0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "contracts/token/ZilliosToken.sol";

contract Crowdsale is Ownable, Pausable, ReentrancyGuard {
    ZilliosToken internal token;
    address internal wallet;
    uint256 public rate; //for rate use in wei, for example, rate 1 is 1**10^18, 1.5 - 1.5*10^18
    uint256 internal weiRaised;
    uint256 public ICOstartTime;
    uint256 public ICOEndTime;
    uint256 public totalSupply = 1000000000 * (1 ether);

    // SUPPLIES :: START
    uint256 public publicSupply = 400000000 * (1 ether);
    uint256 public teamFounderSupply = 250000000 * (1 ether);
    uint256 public companyVestingSupply = 250000000 * (1 ether);
    uint256 public advisorSupply = 30000000 * (1 ether);
    uint256 public bountySupply = 10000000 * (1 ether);
    uint256 public rewardsSupply = 60000000 * (1 ether);
    // SUPPLIES :: END
    uint256 public teamFounderTimeLock;
    uint256 public companyVestingTimeLock;
    uint256 public advisorTimeLock;
    uint256 internal founderCounter = 0;
    uint256 internal advisorCounter = 0;
    uint256 internal companyCounter = 0;
    bool public checkBurnTokens;
    bool public checkAlocatedBurn;

    // ETH RATES again USD

    uint256 public WEI_500_USD;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event WEIPriceSET(uint256 _wei_500_usd);

    event RateChanged(uint256 newRate);

    constructor(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        ZilliosToken _token
    ) Pausable() Ownable() ReentrancyGuard() {
        require(_startTime >= block.timestamp, "ZilliosCrowdsale: start time is before current time");
        require(_endTime >= _startTime, "ZilliosCrowdsale: start time is not before end time");
        require(_rate > 0, "ZilliosCrowdsale: rate is 0");
        require(_wallet != address(0x0), "ZilliosCrowdsale: wallet is the zero address");
        require(address(_token) != address(0x0), "ZilliosCrowdsale: token is the zero address");

        ICOstartTime = _startTime;
        ICOEndTime = _endTime;
        rate = _rate;
        wallet = _wallet;

        teamFounderTimeLock = ICOEndTime + (730 days);
        companyVestingTimeLock = ICOEndTime + (730 days);
        advisorTimeLock = ICOEndTime + (365 days);

        checkBurnTokens = false;
        checkAlocatedBurn = false;

        token = _token;
    }

    function getTokenAmount(uint256 weiAmount) internal returns (uint256) {
        uint256 tokens;

        if (WEI_500_USD > 0) {
            if (weiAmount >= WEI_500_USD) {
                // wei amount > 500 USD worth WEI

                tokens = tokens + (weiAmount * rate) / 10**18;
                tokens = tokens + ((tokens * 20) / 100); // 20% bonus
            } else if ((weiAmount < WEI_500_USD) && (weiAmount >= ((WEI_500_USD * 100) / 25) / 10)) {
                // wei amount >= 200 and < 500 USD worth WEI

                tokens = tokens + (weiAmount * rate) / 10**18;
                tokens = tokens + ((tokens * 15) / 100); // 15% bonus
            } else if ((weiAmount < ((WEI_500_USD * 100) / 25) / 10) && (weiAmount >= (WEI_500_USD / 5))) {
                // wei amount < 200 USD && >= 100 USD worth WEI

                tokens = tokens + (weiAmount * rate) / 10**18;
                tokens = tokens + ((tokens * 10) / 100); // 10% bonus
            } else if ((weiAmount < (WEI_500_USD / 5)) && (weiAmount >= (WEI_500_USD / 20))) {
                // wei amount < 100 USD && >= 25 USD worth WEI

                tokens = tokens + (weiAmount * rate) / 10**18;
                tokens = tokens + ((tokens * 5) / 100); // 5% bonus
            } else {
                tokens = tokens + (weiAmount * rate) / 10**18;
            }
        } else {
            tokens = tokens + ((weiAmount * rate)) / 10**18;
        }

        publicSupply = publicSupply - tokens;
        return tokens;
    }

    function buyTokens(address beneficiary) public payable virtual nonReentrant whenNotPaused {
        require(beneficiary != address(0x0), "ZilliosCrowdsale: beneficiary is the zero address");
        require(validPurchase(), "ZilliosCrowdsale: purchase is not valid");
        uint256 weiAmount = msg.value;

        uint256 tokens = 0;

        tokens = getTokenAmount(weiAmount);

        forwardFunds();

        weiRaised = weiRaised + weiAmount;
        token.mint(beneficiary, tokens);

        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);
    }

    function setWEIPrice(uint256 _wei_500_usd) external onlyOwner {
        WEI_500_USD = _wei_500_usd;

        emit WEIPriceSET(WEI_500_USD);
    }

    function changeRate(uint256 _newRate) external onlyOwner {
        rate = _newRate;

        emit RateChanged(rate);
    }

    function forwardFunds() internal virtual {
        payable(wallet).transfer(msg.value);
    }

    function validPurchase() internal view virtual returns (bool) {
        bool withinPeriod = block.timestamp >= ICOstartTime && block.timestamp <= ICOEndTime;
        bool nonZeroPurchase = true;

        return withinPeriod && nonZeroPurchase && msg.value != 0;
    }

    function hasEnded() public view virtual returns (bool) {
        return block.timestamp > ICOEndTime;
    }

    function getTokenAddress() public view onlyOwner returns (address) {
        return address(token);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}


// Dependency file: contracts/distribution/RefundVault.sol


// pragma solidity 0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract RefundVault is Ownable {
    enum State {Active, Refunding, Closed}
    mapping(address => uint256) public deposited;
    address public wallet;
    State public state;
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    constructor(address _wallet) {
        require(_wallet != address(0x0));
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) external payable onlyOwner {
        require(state == State.Active);
        deposited[investor] = deposited[investor] + msg.value;
    }

    function close() external onlyOwner {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        payable(wallet).transfer(address(this).balance);
    }

    function enableRefunds() external onlyOwner {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function refund(address investor) external {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        payable(investor).transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}


// Dependency file: contracts/distribution/Allocations.sol


// pragma solidity 0.8.0;

// import "contracts/base/Crowdsale.sol";

contract Allocations is Crowdsale {
    struct Bounty {
        uint256 amount;
        uint256 lockTime;
    }

    mapping(address => Bounty) public bounties;

    constructor(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        ZilliosToken _token
    ) Crowdsale(_startTime, _endTime, _rate, _wallet, _token) {}

    function bountyDrop(address[] memory recipients, uint256[] memory values) public onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            values[i] = values[i];
            require(bountySupply >= values[i]);
            bountySupply = bountySupply - values[i];

            bounties[recipients[i]].amount = bounties[recipients[i]].amount + values[i];
            bounties[recipients[i]].lockTime = block.timestamp + 4 weeks;
        }
    }

    function withdrawBounty() external {
        Bounty memory sender_bounty = bounties[msg.sender];

        require(sender_bounty.lockTime < block.timestamp, "ZilliosToken: Vesting period of 4 weeks has not ended.");
        require(sender_bounty.amount > 0, "ZilliosToken: No bounty found.");

        uint256 bounty_amount = sender_bounty.amount;
        delete bounties[msg.sender];

        token.mint(msg.sender, bounty_amount);
    }

    function grantAdvisorToken(address beneficiary) external onlyOwner {
        require((advisorCounter < 6) && (advisorTimeLock < block.timestamp), "ZilliosCrowdsale: cliff period is not ended");
        advisorTimeLock = advisorTimeLock + 30 days;
        token.mint(beneficiary, advisorSupply / 6);
        advisorCounter = advisorCounter + 1;
    }

    function grantTeamFounderToken(address teamfounderAddress) external onlyOwner {
        require((founderCounter < 6) && (teamFounderTimeLock < block.timestamp), "ZilliosCrowdsale: cliff period is not ended");
        teamFounderTimeLock = teamFounderTimeLock + 30 days;
        token.mint(teamfounderAddress, teamFounderSupply / 6);
        founderCounter = founderCounter + 1;
    }

    function grantCompanyToken(address companyAddress) public onlyOwner {
        require((companyCounter < 12) && (companyVestingTimeLock < block.timestamp), "ZilliosCrowdsale: cliff period is not ended");
        companyVestingTimeLock = companyVestingTimeLock + 30 days;
        token.mint(companyAddress, companyVestingSupply / 12);
        companyCounter = companyCounter + 1;
    }

    function transferRewardsFunds(address[] memory recipients, uint256[] memory values) public onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            values[i] = values[i];
            require(rewardsSupply >= values[i]);
            rewardsSupply = rewardsSupply - values[i];
            token.mint(recipients[i], values[i]);
        }
    }

    function transferFunds(address[] memory recipients, uint256[] memory values) public onlyOwner {
        require(!checkBurnTokens);
        for (uint256 i = 0; i < recipients.length; i++) {
            values[i] = values[i];
            require(publicSupply >= values[i]);
            publicSupply = publicSupply - values[i];
            token.mint(recipients[i], values[i]);
        }
    }

    function burnToken() external onlyOwner returns (bool) {
        require(hasEnded());
        require(!checkBurnTokens);
        token.burn(publicSupply);
        totalSupply = totalSupply - publicSupply;
        publicSupply = 0;
        checkBurnTokens = true;
        return true;
    }

    function allocatedTokenBurn() external onlyOwner returns (bool) {
        require(!checkAlocatedBurn);
        require(hasEnded());
        token.burn(advisorSupply);
        token.burn(bountySupply);
        totalSupply = totalSupply - advisorSupply;
        totalSupply = totalSupply - bountySupply;
        advisorSupply = 0;
        bountySupply = 0;

        checkAlocatedBurn = true;
        return true;
    }
}


// Dependency file: contracts/distribution/FinalizableCrowdsale.sol


// pragma solidity 0.8.0;

// import "contracts/distribution/Allocations.sol";

contract FinalizableCrowdsale is Allocations {
    bool isFinalized = false;
    event Finalized();

    constructor(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        ZilliosToken _token
    ) Allocations(_startTime, _endTime, _rate, _wallet, _token) {}

    function finalize() external onlyOwner {
        require(!isFinalized, "ZilliosCrowdsale: already finalized");
        require(hasEnded(), "ZilliosCrowdsale: not closed");
        finalization();
        emit Finalized();
        isFinalized = true;
    }

    function finalization() internal virtual {}
}


// Dependency file: contracts/distribution/RefundableCrowdsale.sol


// pragma solidity 0.8.0;

// import "contracts/distribution/RefundVault.sol";
// import "contracts/distribution/FinalizableCrowdsale.sol";

contract RefundableCrowdsale is FinalizableCrowdsale {
    uint256 internal goal;
    RefundVault private vault;

    constructor(
        uint256 _goal,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        ZilliosToken _token
    ) FinalizableCrowdsale(_startTime, _endTime, _rate, _wallet, _token) {
        require(_goal > 0, "ZilliosCrowdsale: goal is 0");

        vault = new RefundVault(wallet);
        goal = _goal;
    }

    function forwardFunds() internal virtual override(Crowdsale) {
        vault.deposit{value: msg.value}(msg.sender);
    }

    function claimRefund() external {
        require(isFinalized, "ZilliosCrowdsale: not finalized");
        require(!goalReached(), "ZilliosCrowdsale: goal reached");
        vault.refund(msg.sender);
    }

    function finalization() internal virtual override {
        if (goalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }
        super.finalization();
    }

    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }

    function getVaultAddress() external view onlyOwner returns (address) {
        return address(vault);
    }
}


// Dependency file: contracts/validation/CappedCrowdsale.sol


// pragma solidity 0.8.0;

// import "contracts/distribution/RefundableCrowdsale.sol";

contract CappedCrowdsale is RefundableCrowdsale {
    uint256 internal cap;

    constructor(
        uint256 _cap,
        uint256 _goal,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        ZilliosToken _token
    ) RefundableCrowdsale(_goal, _startTime, _endTime, _rate, _wallet, _token) {
        require(_cap > 0, "ZilliosCrowdsale: cap is 0");
        cap = _cap;
    }

    function validPurchase() internal view virtual override returns (bool) {
        bool withinCap = weiRaised + msg.value <= cap;
        return super.validPurchase() && withinCap;
    }

    function hasEnded() public view virtual override returns (bool) {
        bool capReached = weiRaised >= cap;
        return super.hasEnded() || capReached;
    }
}


// Root file: contracts/ZilliosCrowdsale.sol


pragma solidity 0.8.0;

// import "contracts/base/Crowdsale.sol";
// import "contracts/validation/CappedCrowdsale.sol";
// import "contracts/distribution/RefundableCrowdsale.sol";
// import "contracts/distribution/Allocations.sol";

contract ZilliosCrowdsale is CappedCrowdsale {
    constructor(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _hardCap,
        uint256 _softCap,
        address _wallet,
        ZilliosToken _token
    ) CappedCrowdsale(_hardCap, _softCap, _startTime, _endTime, _rate, _wallet, _token) {}

    receive() external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable virtual override whenNotPaused {
        require(CappedCrowdsale.validPurchase(), "ZilliosCrowdsale: cap exceeded or purchase is not valid");
        require(!CappedCrowdsale.hasEnded(), "ZilliosCrowdsale: crowdsale has ended");

        Crowdsale.buyTokens(beneficiary);
    }

    function setSoftCap(uint256 _goal) external onlyOwner {
        require(block.timestamp <= ICOstartTime, "ZilliosCrowdsale: ICO starts");
        require(_goal > 0, "ZilliosCrowdsale: goal is 0");
        goal = _goal;
    }

    function setHardCap(uint256 _cap) external onlyOwner {
        require(block.timestamp <= ICOstartTime, "ZilliosCrowdsale: ICO starts");
        require(_cap > 0, "ZilliosCrowdsale: cap is 0");
        cap = _cap;
    }
}