/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

abstract contract BPContract{
    function protect(address sender, address receiver, uint256 amount) external virtual;
}

interface IFactory {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
  function WETH() external pure returns (address);
  function factory() external view returns (address);
}

contract TT is IERC20, Ownable, Pausable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string constant public name = "TT";
    string constant public symbol = "TT";
    uint8 constant public decimals = 18;

    uint256 private _totalSupply = 10000000 * 1E18;

    address public beneficiaryAddress;
    uint8 public feePercentage = 4;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isBlacklisted;
    mapping (address => bool) public hasBlacklistPermission;
    uint public BLACKLIST_LOCK;

    BPContract public BP;
    bool public bpEnabled;
    bool private BPSet = false;

    IRouter public Router;
    address public TOKEN_PAIR;

    event SetFeePercentage(uint8 feePercentage);
    event SetBeneficiaryAddress(address beneficiaryAddress);
    event ExcludedFromFee(address account, bool isExcluded);
    event BlacklistPermission(address account, bool permission);
    event Blacklist(address account, bool isBlacklist);

    constructor(address beneficiaryAddress_) {
        beneficiaryAddress = beneficiaryAddress_;
        _balances[msg.sender] = _totalSupply;
        isExcludedFromFee[msg.sender] = true;
        hasBlacklistPermission[msg.sender] = true;
        BLACKLIST_LOCK = block.timestamp + 3 days;

        // Router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // mainnet
        // Router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // TOKEN_PAIR = IFactory(Router.factory()).createPair(address(this), Router.WETH());
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = _allowances[account][msg.sender];
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool)  {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setBPAddrss(address _bp) external onlyOwner {
        require(!BPSet, "BP call be set once only.");
        BPSet = true;
        BP = BPContract(_bp);
    }

    function setBpEnabled(bool _enabled) external onlyOwner {
        bpEnabled = _enabled;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setFeePercentage(uint8 feePercentage_) external onlyOwner {
        require(feePercentage_ <= 10, "Token: transaction fee percentage exceeds 10");
        require(feePercentage_ >= 0, "Token: transaction fee percentage equals 0");
        feePercentage = feePercentage_;
        emit SetFeePercentage(feePercentage);
    }

    function setBeneficiaryAddress(address beneficiaryAddress_) external onlyOwner {
        beneficiaryAddress = beneficiaryAddress_;
        emit SetBeneficiaryAddress(beneficiaryAddress);
    }

    function excludeFromFee(address address_, bool isExcluded) external onlyOwner {
        isExcludedFromFee[address_] = isExcluded;
        emit ExcludedFromFee(address_, isExcluded);
    }

    function setBlacklistPermission(address address_, bool permission) external onlyOwner {
        hasBlacklistPermission[address_] = permission;
        emit BlacklistPermission(address_, permission);
    }

    function blacklist(address[] calldata addresses, bool isBlacklist) external {
        require(hasBlacklistPermission[msg.sender], "Token: insufficient permission");
        if (isBlacklist)
            require(block.timestamp < BLACKLIST_LOCK, "Token: blacklist function is not available.");

        for (uint i=0; i<addresses.length; i++) {
            require(addresses[i] != address(this), "Token: unable to blacklist token.");
            // require(addresses[i] != TOKEN_PAIR, "Token: unable to blacklist pair.");
            isBlacklisted[addresses[i]] = isBlacklist;
            emit Blacklist(addresses[i], isBlacklist);
        }
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private whenNotPaused {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!isBlacklisted[sender], "Token: transfer from blacklisted address");
        require(!isBlacklisted[recipient], "Token: transfer to blacklisted address");
        require(!isBlacklisted[tx.origin], "Token: transfer called from blacklisted address");

        if (bpEnabled) {
            BP.protect(sender, recipient, amount);
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 receiveAmount = amount;
        if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            _balances[recipient] += receiveAmount;
        } else {
            uint256 feeAmount = amount * feePercentage / 100;
            receiveAmount = amount - feeAmount;
            _balances[beneficiaryAddress] += feeAmount;
            _balances[recipient] += receiveAmount;
            emit Transfer(sender, beneficiaryAddress, feeAmount);
        }

        emit Transfer(sender, recipient, receiveAmount);
    }

    function _burn(address account, uint256 amount) private whenNotPaused {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}