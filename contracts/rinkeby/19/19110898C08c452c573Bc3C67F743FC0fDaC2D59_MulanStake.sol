/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: MIT

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


// File contracts/token/ERC20/extensions/IERC20Metadata.sol





/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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


// File contracts/utils/Context.sol

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

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

abstract contract WhitelistForSelf is Ownable {
    //      caller
    mapping(address => bool) public canBeModified;

    function addRelationByOwner(address caller) external virtual onlyOwner {
        canBeModified[caller] = true;
    }

    modifier allowModification() {
        require(canBeModified[msg.sender], "modification not allowed");
        _;
    }
}

contract mulanV2 is ERC20, WhitelistForSelf {

    constructor() ERC20("Mulan.Finance V2", "$MULAN2") {}

    function mintByWhitelist(address _to, uint256 _amount ) external allowModification {
        _mint(_to, _amount);
    }

    function mint(address _to, uint256 _amount ) external onlyOwner {
        _mint(_to, _amount);
    }
}

contract timelocks is WhitelistForSelf {

    IERC20 private immutable _token;

    event LockCreated(
        address indexed user,
        uint256 indexed lockNumber,
        uint256 value,
        uint256 reward,
        uint256 startTime,
        uint256 releaseTime
    );
    event Released(
        address indexed user,
        uint256 indexed lockNumber,
        uint256 actualReleaseTime
    );

    uint256 public lockedTotal;
    uint256 public rewardTotal;

    constructor(IERC20 token_) {
        _token = token_;
    }

    struct LockDetail {
        uint256 value;  //locked mulan value
        uint256 reward; //reward mulanV2 value
        uint256 releaseTime;
        bool released;
    }

    mapping(address => LockDetail[]) public userLocks;

    function getTotalLocksOf(address _user) public view returns (uint256) {
        return userLocks[_user].length;
    }

    function getDetailOf(address _user, uint256 _lockNumber)
        public
        view
        returns (
            uint256 value,
            uint256 reward,
            uint256 releaseTime,
            bool released
        )
    {
        LockDetail memory detail = userLocks[_user][_lockNumber];
        return (
            detail.value,
            detail.reward,
            detail.releaseTime,
            detail.released
        );
    }

    ///@dev it's caller's responsibility to transfer _value token to this contract
    function lockByWhitelist(
        address _user,
        uint256 _value,
        uint256 _reward,
        uint256 _releaseTime
    ) external virtual allowModification returns (bool) {
        require(
            _releaseTime >= block.timestamp,
            "lock time should be after current time"
        );
        require(_value > 0, "value should be above 0");
        uint256 lockNumber = userLocks[_user].length;
        userLocks[_user].push(LockDetail(_value, _reward, _releaseTime, false));
        lockedTotal += _value;
        rewardTotal += _reward;
        emit LockCreated(
            _user,
            lockNumber,
            _value,
            _reward,
            block.timestamp,
            _releaseTime
        );
        return true;
    }

    function canRelease(address _user, uint256 _lockNumber)
        public
        view
        virtual
        returns (bool)
    {
        return
            userLocks[_user][_lockNumber].releaseTime <= block.timestamp &&
            !userLocks[_user][_lockNumber].released;
    }

    function releaseByWhitelist(address _user, uint256 _lockNumber)
        public
        virtual
        allowModification
        returns (bool)
    {
        require(
            canRelease(_user, _lockNumber),
            "still locked or already released"
        );
        LockDetail memory detail = userLocks[_user][_lockNumber];
        _token.transfer(_user, detail.value);
        userLocks[_user][_lockNumber].released = true;
        emit Released(_user, _lockNumber, block.timestamp);
        return true;
    }

}

contract MulanStake is Ownable {

    uint256 private immutable _base = 10000;
    uint256 private immutable _year = 365;

    IERC20 public mulan;
    mulanV2 public mulan2;
    timelocks public lock;

    constructor(
        address mulan_,
        address mulan2_,
        address timelock_
    ) {
        mulan = IERC20(mulan_);
        mulan2 = mulanV2(mulan2_);
        lock = timelocks(timelock_);
    }

    struct product {
        string prodName;
        uint256 lockDays;
        uint256 basedAPY; // base 10000. e.g. 1000 => 1000/10000 = 10%
        bool onSale;
    }

    struct productSales{
        uint256 lockedTotal;
        uint256 rewardTotal;
    }

    product[] public products;
    mapping(uint256 => productSales) public sales;

    function getProductCount() public view returns (uint256) {
        return products.length;
    }

    function addProduct(
        string memory _name,
        uint256 _lockDays,
        uint256 _basedAPY
    ) external virtual onlyOwner {
        products.push(product(_name, _lockDays, _basedAPY, true));
    }

    function changeAPY(uint256 _productId, uint256 _APY) external virtual onlyOwner {
        products[_productId].basedAPY = _APY;
    }

    function offTheShelf(uint256 _productId) external virtual onlyOwner {
        products[_productId].onSale = false;
    }

    function deposit(uint256 _productId, uint256 _amount)
        external
        virtual
        returns (bool)
    {
        product memory prod = products[_productId];
        require(prod.onSale, "product is not vaild");
        mulan.transferFrom(msg.sender, address(lock), _amount);
        uint256 releaseTime = prod.lockDays * 1 days + block.timestamp;
        uint256 reward = _amount * prod.basedAPY / _base * prod.lockDays / _year;

        sales[_productId].lockedTotal += _amount;
        sales[_productId].rewardTotal += reward;
        return lock.lockByWhitelist(msg.sender, _amount, reward, releaseTime);
    }

    function withdraw(uint256 _lockNumber) external virtual returns (bool) {
        (, uint256 reward, , ) =
            lock.getDetailOf(msg.sender, _lockNumber);
        lock.releaseByWhitelist(msg.sender, _lockNumber);
        mulan2.mintByWhitelist(msg.sender, reward);
        return true;
    }
}