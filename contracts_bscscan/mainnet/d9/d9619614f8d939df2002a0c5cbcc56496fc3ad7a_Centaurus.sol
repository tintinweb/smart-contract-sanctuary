/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

}
contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _lock;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address public Owner;

    address public PartnersandAdvisers;
    address public Project_Marketing;
    address public Project_Development;
    address public Project_Team;
    address public Project_Charity;
    
    constructor (string memory name_, string memory symbol_, uint8 decimals_ , address Partners_Advisers, address _Marketing, address _Development, address _Team, address _Charity) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        Owner = msg.sender;
        
        PartnersandAdvisers = Partners_Advisers;
        Project_Marketing = _Marketing;
        Project_Development = _Development;
        Project_Team = _Team;
        Project_Charity = _Charity;
    }
    
    
    modifier onlyOwner() {
        require(Owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function ownerTransfership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transfer(msg.sender,newOwner,_balances[msg.sender]);
        Owner = newOwner;
        return true;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(_lock[sender] <= block.timestamp,"sender address is locked");
        
        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        
        transfer(PartnersandAdvisers,amount.mul(10).div(100));
        transfer(Project_Marketing,amount.mul(15).div(100));
        transfer(Project_Development,amount.mul(15).div(100));
        transfer(Project_Team,amount.mul(5).div(100));
        transfer(Project_Charity,amount.mul(5).div(100));
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    function lock(address[] memory accounts, uint256 setTime) public onlyOwner returns (bool) {
        for(uint256 i = 0; i < accounts.length; i++) {
            _lock[accounts[i]] = block.timestamp.add(setTime.mul(86400));
        }
        return true;
    }
    
    function unlock(address[] memory accounts) public onlyOwner returns (bool) {
        for(uint256 i = 0; i < accounts.length; i++) {
            _lock[accounts[i]] = block.timestamp;
        }
        return true;
    }
}

contract Centaurus is BEP20 {

    constructor (address Partners_Advisers, address _Marketing, address _Development, address _Team, address _Charity) BEP20("The Centaurus", "CENT", 8, Partners_Advisers, _Marketing, _Development, _Team, _Charity) {
        _mint(msg.sender, 100000000000 * 10 ** 8);
    }
}