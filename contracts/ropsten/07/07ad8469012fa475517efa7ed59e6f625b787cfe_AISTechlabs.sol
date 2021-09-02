/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*  Wrappers over Solidity's arithmetic operations with added overflow checks. */
library SafeMath {
    /* Addition cannot overflow. */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    /* Subtraction cannot overflow. */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    /*  Subtraction cannot overflow. */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
    /* Multiplication cannot overflow. */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    /* The divisor cannot be zero. */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /* The divisor cannot be zero. */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    /*The divisor cannot be zero */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /* The divisor cannot be zero. */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

/*
 * Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 */
  
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /* Returns the address of the current owner. */
    function owner() public view returns (address) {
        return _owner;
    }

    /* Throws if called by any account other than the owner. */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /* Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner. */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/* Interface of the ERC20 standard as defined in the EIP. */
interface IERC20 {
    
    /*  Returns the amount of tokens in existence. */
    function totalSupply() external view returns (uint256);

    /* Returns the amount of tokens owned by `account`. */
    function balanceOf(address account) external view returns (uint256);

    /* Moves `amount` tokens from the caller's account to `recipient`.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /* Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}.
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /* Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /* Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /* Emitted when `value` tokens are moved from one account (`from`) to another (`to`). */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance. */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event FreezTokenEvent(address sender, uint256 value);
}

contract ERCStander20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping (address => uint256) private _freezeOf;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    constructor (string memory name_, string memory symbol_, uint256 decimals_)  {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /*  Returns the name of the token. */
    function name() public view returns (string memory) {
        return _name;
    }

    /* Returns the symbol of the token, usually a shorter version of the name. */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function freezeBalance(address account) public view  returns (uint256){
        return _freezeOf[account];
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /* Atomically increases the allowance granted to `spender` by the caller.
      `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /*  Atomically decreases the allowance granted to `spender` by the caller. */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    /* Account owner freeze his amount of token  */
    function freezToken(uint256 amount) public virtual returns (bool){
        _freeztoken(amount);
        return true;
    }
    
    /* Account owner unfreeze his amount of token  */
    function unfreezeToken(uint256 amount) public virtual returns (bool){
        _unfreeztoken(amount);
        return true;
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
    /*  Reducing from account token amount  */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    /* Moves tokens `amount` from `sender` to `recipient`.
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        BeforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /* Creates `amount` tokens and assigns them to `account`, increasing  the total supply. */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        BeforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /*  Destroys `amount` tokens from `account`, reducing the total supply. */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        BeforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /* Sets `amount` as the allowance of `spender` over the `owner` s tokens. */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _unfreeztoken(uint256 amount) internal virtual {
        require (amount == 0, "ERC20: transfer amount exceeds balance");
        _freezeOf[_msgSender()] = _freezeOf[_msgSender()].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[_msgSender()] = _balances[_msgSender()].add(amount);
        
        emit FreezTokenEvent(_msgSender(), amount);
    }  
    
    function _freeztoken(uint256 amount) internal virtual {
        require (amount != 0, "ERC20: transfer amount exceeds balance");
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount, "ERC20: transfer amount exceeds balance");
        _freezeOf[_msgSender()] = _freezeOf[_msgSender()].add(amount);
        
        emit FreezTokenEvent(_msgSender(), amount);
    }
    
    /* Hook that is called before any transfer of tokens. This includes minting and burning. */
    function BeforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


abstract contract Blacklistable is Ownable {
    
    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    /* Throws if called by any account other than the blacklister */
    modifier onlyBlacklister() {
        require(msg.sender == owner());
        _;
    }

    /* Throws if argument account is blacklisted @param _account The address to check */
    modifier notBlacklisted(address _account) {
        require(blacklisted[_account] == false);
        _;
    }

    /* Checks if account is blacklisted @param _account The address to check  */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /* Adds account to blacklist @param _account The address to blacklist */
    function blacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /* Removes account from blacklist @param _account The address to remove from the blacklist */
    function unBlacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }
}


contract AISTechlabs is ERCStander20, Blacklistable {    
    constructor(uint256 initialSupply) ERCStander20("AIS Technolabs", "AIS",8) {        
        _mint(msg.sender, initialSupply);
    }

    function BeforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super.BeforeTokenTransfer(from, to, amount);

        require(!isBlacklisted(from), "ERC20WithSafeTransfer: invalid sender");
        require(!isBlacklisted(to), "ERC20WithSafeTransfer: invalid recipient");
    }
}