/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


pragma solidity ^0.8.0;

interface IWhiteList {
    function isInWhiteList(address account) external view returns (bool);
}

contract ExchangeLockPool is Ownable {
    uint256 private startTime;
    address private withdrawToken;
    uint256 private releaseDuration = 86400 * 365;
    uint256 private releaseBuyDuration = 86400 * 30;
    bool private isOpen = true;
    uint256 private invitorRate = 300;
    uint256 private welfareRate = 1000;
    uint256 private invitorLockRate = 500;
    uint256 private maxBuyAmountOnce = 300000000000000000;
    address private whiteListContract;
    mapping(address => Record[]) buyLockRecords;
    mapping(address => Record[]) invitorLockRecords;
    mapping(address => Record[]) buyRecords;
    mapping(address => Record[]) invitorRecords;

    uint256 private totalLockAmount;
    mapping(address => uint256) private buyTimes;
    uint256 private maxBuyTimes = 1;
    address private swapAddress = 0x48E166C6f17A102Ef6e3097bc3677CEc174eE2D4;


    constructor(uint256 _startTime, address _withdrawToken){
        startTime = _startTime;
        withdrawToken = _withdrawToken;
    }

    function buy(address invitor) public payable {
        require(block.timestamp >= startTime, "this pool is not start");
        require(isOpen, "this pool is not open");
        require(maxBuyAmountOnce >= msg.value, "exchange amount is too large");
        if (maxBuyTimes > 0) {
            require(maxBuyTimes > buyTimes[msg.sender], "Your purchases have been used up");
        }
        uint256 rate = getPrice().rate;
        uint256 withdrawAmount = msg.value * rate / (10 ** 18);
        require(withdrawAmount > 0, "exchange amount is too small");
        uint256 invitorSendAmoumt = 0;
        uint256 invitorLockAmount = 0;
        if (invitor != address(0) && invitor != msg.sender && whiteListContract != address(0) && IWhiteList(whiteListContract).isInWhiteList(invitor)) {
            uint256 invitorAmount = withdrawAmount * invitorRate / 1000;
            if (invitorAmount > 0) {
                invitorLockAmount = invitorAmount * invitorLockRate / 1000;
                invitorSendAmoumt = invitorAmount - invitorLockAmount;
            }
        }


        uint256 buyLockAmount = withdrawAmount * welfareRate / 1000;


        if (buyLockAmount > 0) {
            Record memory record = Record({
            amount : buyLockAmount,
            timestamp : block.timestamp
            });
            buyLockRecords[msg.sender].push(record);
            totalLockAmount = totalLockAmount + buyLockAmount;
        }

        if (withdrawAmount > 0) {
            Record memory record = Record({
            amount : withdrawAmount,
            timestamp : block.timestamp
            });
            buyRecords[msg.sender].push(record);
            totalLockAmount = totalLockAmount + withdrawAmount;
        }

        if (invitorLockAmount > 0) {
            Record memory record = Record({
            amount : invitorLockAmount,
            timestamp : block.timestamp
            });
            invitorLockRecords[invitor].push(record);
            totalLockAmount = totalLockAmount + invitorLockAmount;
        }

        if (invitorSendAmoumt > 0) {
            Record memory record = Record({
            amount : invitorSendAmoumt,
            timestamp : block.timestamp
            });
            invitorRecords[invitor].push(record);
            totalLockAmount = totalLockAmount + invitorSendAmoumt;
        }

        buyTimes[msg.sender] = buyTimes[msg.sender] + 1;
    }

    function releaseInvitorToken(uint256 index) public {
        require(invitorRecords[msg.sender].length > 0, "not any release token");
        Record memory record = invitorRecords[msg.sender][index];
        require(block.timestamp > record.timestamp + releaseBuyDuration, "not release time now");
        require(record.amount > 0, "not any release token");
        ERC20(withdrawToken).transfer(msg.sender, record.amount);
        invitorRecords[msg.sender][index].amount = 0;
        totalLockAmount = totalLockAmount - record.amount;
    }

    function releaseBuyerToken(uint256 index) public {
        require(buyRecords[msg.sender].length > 0, "not any release token");
        Record memory record = buyRecords[msg.sender][index];
        require(block.timestamp > record.timestamp + releaseBuyDuration, "not release time now");
        require(record.amount > 0, "not any release token");
        ERC20(withdrawToken).transfer(msg.sender, record.amount);
        buyRecords[msg.sender][index].amount = 0;
        totalLockAmount = totalLockAmount - record.amount;
    }

    function releaseBuyerLockToken(uint256 index) public {
        require(buyLockRecords[msg.sender].length > 0, "not any release token");
        Record memory record = buyLockRecords[msg.sender][index];
        require(block.timestamp > record.timestamp + releaseDuration, "not release time now");
        require(record.amount > 0, "not any release token");
        ERC20(withdrawToken).transfer(msg.sender, record.amount);
        buyLockRecords[msg.sender][index].amount = 0;
        totalLockAmount = totalLockAmount - record.amount;
    }

    function releaseInvitorLockToken(uint256 index) public {
        require(invitorLockRecords[msg.sender].length > 0, "not any release token");
        Record memory record = invitorLockRecords[msg.sender][index];
        require(block.timestamp > record.timestamp + releaseDuration, "not release time now");
        require(record.amount > 0, "not any release token");
        ERC20(withdrawToken).transfer(msg.sender, record.amount);
        invitorLockRecords[msg.sender][index].amount = 0;
        totalLockAmount = totalLockAmount - record.amount;
    }

    function withdrawAll(address account) public onlyOwner {
        uint256 amount = ERC20(withdrawToken).balanceOf(address(this));
        require(amount > 0);
        ERC20(withdrawToken).transfer(account, amount);
    }

    function withdraw(address account) public onlyOwner {
        uint256 amount = ERC20(withdrawToken).balanceOf(address(this));
        require(amount > 0);
        uint256 withdrawAmount = amount - totalLockAmount;
        require(withdrawAmount > 0);
        ERC20(withdrawToken).transfer(account, withdrawAmount);
    }

    function withdrawBNB(address account) public onlyOwner {
        uint256 amount = address(this).balance;
        if (amount > 0) {
            payable(account).transfer(amount);
        }
    }


    function getBuyerRecordsLength(address account) public view returns (uint256) {
        return buyRecords[account].length;
    }

    function getBuyerRecordByIndex(address account, uint256 index) public view returns (Record memory) {
        return buyRecords[account][index];
    }

    function getBuyerLockRecordsLength(address account) public view returns (uint256) {
        return buyLockRecords[account].length;
    }

    function getBuyerLockRecordByIndex(address account, uint256 index) public view returns (Record memory) {
        return buyLockRecords[account][index];
    }

    function getInvitorRecordsLength(address account) public view returns (uint256)  {
        return invitorRecords[account].length;
    }

    function getInvitorRecordByIndex(address account, uint256 index) public view returns (Record memory)  {
        return invitorRecords[account][index];
    }


    function getInvitorLockRecordsLength(address account) public view returns (uint256)  {
        return invitorLockRecords[account].length;
    }

    function getInvitorLockRecordByIndex(address account, uint256 index) public view returns (Record memory)  {
        return invitorLockRecords[account][index];
    }

    function setWelfareRate(uint256 _welfareRate) public onlyOwner {
        welfareRate = _welfareRate;
    }

    function setWhiteListContract(address contractAddress) public onlyOwner {
        whiteListContract = contractAddress;
    }

    function setInvitorLockRate(uint256 _invitorLockRate) public onlyOwner {

        invitorLockRate = _invitorLockRate;
    }

    function setInvitorRate(uint256 _invitorRate) public onlyOwner {
        invitorRate = _invitorRate;
    }

    function setReleaseDuration(uint256 _duration) public onlyOwner {
        releaseDuration = _duration;
    }

    function setBuyReleaseDuration(uint256 _duration) public onlyOwner {
        releaseBuyDuration = _duration;
    }

    function setMaxBuyAmountOnce(uint256 _maxBuyAmountOnce) public onlyOwner {
        maxBuyAmountOnce = _maxBuyAmountOnce;
    }

    function getMaxBuyAmountOnce() public view returns (uint256) {
        return maxBuyAmountOnce;
    }

    function getWhiteListContract() public view returns (address) {
        return whiteListContract;
    }

    function getTotalLockAmount() public view returns (uint256) {
        return totalLockAmount;
    }

    function getReleaseDuration() public view returns (uint256) {
        return releaseDuration;
    }

    function getBuyReleaseDuration() public view returns (uint256) {
        return releaseBuyDuration;
    }

    function getWelfareRate() public view returns (uint256) {
        return welfareRate;
    }

    function getInvitorRate() public view returns (uint256) {
        return invitorRate;
    }

    function getInvitorLockRate() public view returns (uint256) {
        return invitorLockRate;
    }

    function setMaxBuyNumber(uint256 _maxBuyTimes) public onlyOwner {
        maxBuyTimes = _maxBuyTimes;
    }

    function getMaxBuyNumber() public view returns (uint256) {
        return maxBuyTimes;
    }

    function getBuyTimes(address account) public view returns (uint256){
        return buyTimes[account];
    }

    function setOpen(bool _isOpen) public onlyOwner {
        isOpen = _isOpen;
    }

    function balance() public view returns (uint256) {
        return ERC20(withdrawToken).balanceOf(address(this));
    }

    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    function getWithdrawToken() public view returns (address) {
        return withdrawToken;
    }

    function getPrice() public view returns (Price memory){
        uint256 btBalance = ERC20(withdrawToken).balanceOf(swapAddress);
        uint256 wbnbBalance = ERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c).balanceOf(swapAddress);
        uint256 amountInWithFee = 1e18 * 9975;
        uint256 numerator = amountInWithFee * btBalance;
        uint256 denominator = wbnbBalance * 10000 + amountInWithFee;
        uint256 amount = numerator / denominator;

        Price memory price = Price({
        exchangeToken : address(0),
        rate : amount
        });
        return price;
    }

    struct Record {
        uint256 amount;
        uint256 timestamp;
    }

    struct Price {
        address exchangeToken;
        uint256 rate;
    }

}