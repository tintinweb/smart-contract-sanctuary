/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

//YXBToken EIP20
contract YXBToken is IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply = 1000000;
    uint256 private _remain = _totalSupply;
    address private _Owner;
    
    modifier onlyOwner() {
        require(msg.sender == _Owner, "Only Owner can call this.");
        _;
    }

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Deposit (address indexed account, uint256 amount);

    constructor (string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _Owner = msg.sender;
    }
    
    // 1BNT = 1000YXB
    function exchangeYXB() public payable {
        uint256 count = msg.value/(10**15);
        require(_remain >= count, "Remain Not Enough");
        _remain -= count;
        _balances[msg.sender] += count;
        emit Deposit(msg.sender, count);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function remain() public view returns (uint256) {
        return _remain;
    }
    function contractbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0),"Recipient Is Zero");
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0),"sender Is Zero");
        require(recipient != address(0),"Recipient Is Zero");
        require(_balances[sender] >= amount && _allowances[sender][msg.sender] >= amount);
        _balances[sender] -= amount;
        _allowances[sender][msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function withdrawToOwner() public onlyOwner returns (bool) {
        uint256 count = address(this).balance;
        payable(msg.sender).transfer(count);
        return true;
    }
    
    receive() external payable { 
        uint256 count = msg.value/(10**15);
        require(_remain >= count, "Remain Not Enough");
        _remain -= count;
        _balances[msg.sender] += count;
        emit Deposit(msg.sender, count);
    }

}