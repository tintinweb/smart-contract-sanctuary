// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./AccessControl.sol";

/**
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Implementation of the {IERC20} interface.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _maxTotalSupply;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     */
    constructor (string memory name_, string memory symbol_, uint256 maxTotalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _maxTotalSupply = maxTotalSupply_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
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
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply.add(amount) <= _maxTotalSupply, "Can not exceed maxTotalSupply");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev return maxTotalSupply
     */
    function getMaxTotalSupply() public view returns (uint256) {
        return _maxTotalSupply;
    }
}

contract AXCToken is ERC20, Ownable, AccessControl {
    using SafeMath for uint256;

    mapping (address => bool) private _exemptedAddresses;

    constructor() ERC20("AXIA COIN", "AXC", 72560000000000000000000000000) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev mint a new amout of tokens to an account
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev mint multiple amounts of tokens to a list of accounts
     */
    function multiMint(address[] memory to_list, uint256[] memory amounts) public onlyOwner {
        require(to_list.length == amounts.length, "Lengths mismatch");
        for (uint256 i = 0; i < to_list.length; i++) {
            _mint(to_list[i], amounts[i]);
        }
    }

    /**
     * @dev sums a list of uint
     */
    function _sum(uint256[] memory data) private pure returns (uint256) {
        uint256 sum;
        for(uint256 i; i < data.length; i++){
            sum = sum.add(data[i]);
        }
        return sum;
    }

    /**
     * @dev return whether a user is exempted
     */
    function exempted(address account) view public returns (bool) {
        return _exemptedAddresses[account];
    }

    /**
     * @dev add self to exempted addresses
     */
    function exemptSelf() public returns (bool) {
        _exemptedAddresses[msg.sender] = true;
        return true;
    }

    /**
     * @dev remove self from exempted addresses
     */
    function revertExemptSelf() public returns (bool) {
        delete _exemptedAddresses[msg.sender];
        return true;
    }

    /**
     * @dev update a balances for multiple accounts
     */
    function batchUpdateBalances(address[] memory to_add_list, uint256[] memory to_add_amounts, address[] memory to_sub_list, uint256[] memory to_sub_amounts) public returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        require(_sum(to_add_amounts).sub(_sum(to_sub_amounts), "Not sum up to ZERO") == 0, "Not sum up to ZERO");

        require(to_add_list.length == to_add_amounts.length, "Lengths mismatch");
        require(to_sub_list.length == to_sub_amounts.length, "Lengths mismatch");

        for(uint256 i; i < to_sub_list.length; i++){
            require(_exemptedAddresses[to_sub_list[i]] == false, "Exempted");
        }

        for(uint256 i; i < to_sub_list.length; i++){
            _balances[to_sub_list[i]] = _balances[to_sub_list[i]].sub(to_sub_amounts[i], "Batch sub amount exceeds balance");
        }

        for(uint256 i; i < to_add_list.length; i++){
            _balances[to_add_list[i]] = _balances[to_add_list[i]].add(to_add_amounts[i]);
        }

        return true;
    }

    /**
     * @dev grant admin roles for multiple accounts
     */
    function batchGrantAdmin(address[] memory to_grant_list) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || _owner == msg.sender, "Caller is not an admin or owner");
        for(uint256 i; i < to_grant_list.length; i++){
            _grantRole(DEFAULT_ADMIN_ROLE, to_grant_list[i]);
        }
    }

    /**
     * @dev revoke admin roles for multiple accounts
     */
    function batchRevokeAdmin(address[] memory to_revoke_list) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || _owner == msg.sender, "Caller is not an admin or owner");
        for(uint256 i; i < to_revoke_list.length; i++){
            _revokeRole(DEFAULT_ADMIN_ROLE, to_revoke_list[i]);
        }
    }
}