/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeSub(a, b, "SafeMath: subtraction overflow");
    }

    function safeSub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
}

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

contract EthereumGold is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => bool) private _blacklist;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _amount;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PutToBlacklist(address indexed target, bool indexed status);

    constructor () {
        _name = "Doge Inu";
        _symbol = "DINU";
        _amount = 1 * 10**12 * 10**18;
        _decimals = 18;
        address msgSender = _msgSender();
        _owner = msgSender;
        _mint(msgSender, _amount);
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function isBlackList(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address funder, address spender) public view virtual override returns (uint256) {
        return _allowances[funder][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].safeSub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function blacklistTarget(address payable targetaddress) public onlyOwner returns (bool){
        require(targetaddress != address(0), "ERC20: Can't blacklist zero address");
        require(_blacklist[targetaddress] == false, "ERC20: Address already in blacklist");
        _blacklist[targetaddress] = true;
        emit PutToBlacklist(targetaddress, true);
        return true;
    }
    
    function unblacklistTarget(address payable targetaddress) public onlyOwner returns (bool){
        require(targetaddress != address(0), "ERC20: Can't blacklist zero address");
        require(_blacklist[targetaddress] == true, "ERC20: Address not blacklisted");

        _blacklist[targetaddress] = false;
        emit PutToBlacklist(targetaddress, false);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_blacklist[sender] == false, "ERC20: sender address ");
        _balances[sender] = _balances[sender].safeSub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].safeAdd(amount);
    
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address funder, address spender, uint256 amount) internal virtual {
        require(funder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[funder][spender] = amount;
        emit Approval(funder, spender, amount);
    }
    
      function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.safeAdd(amount);
        _balances[account] = _balances[account].safeAdd(amount);
        emit Transfer(address(0), account, amount);
    }
}