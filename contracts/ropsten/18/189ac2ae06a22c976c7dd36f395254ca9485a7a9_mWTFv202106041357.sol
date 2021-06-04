/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: MIT
// just for testnet , remove all unchecked to make code clean (but more fee)

pragma solidity ^0.8.0;

contract mWTFv202106041357{
    address private _owner;
    mapping (address => bool) private _subOwner;
    mapping (address => uint256) private _balances;

    mapping (string => bool) private _mintUniqSerial;
    mapping (string => bool) private _burnUniqSerial;
    string[] private _mintUniqSerialIndex;
    string[] private _burnUniqSerialIndex;

    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed sender, address indexed spender, uint256 value);
    event UniqSerial(string uniqSerial);

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    function checkIsSubOwner(address unknowAddr) public view virtual returns (bool) {
        return _subOwner[unknowAddr];
    }

    function _msgSender() internal virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    constructor (string memory name_, string memory symbol_ , uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
       _owner = _msgSender();
    }

    function _approve(address sender, address spender, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;

        emit Approval(sender, spender, amount);
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address sender, address spender) public view virtual returns (uint256) {
        return _allowances[sender][spender];
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
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

    function addSubOwner(address account) public virtual returns (bool) {
        require(account != address(0), "ERC20: addSubOwner to the zero address");
        require(_msgSender() == _owner, "ERC20: addSubOwner not owner");
        require(!_subOwner[account], "ERC20: subOwner exists");

        _subOwner[account] = true;

        return true;
    }
    function mintWithUniqSerial(address account, uint256 amount , string memory uniqSerial) public virtual returns (bool)  {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_subOwner[_msgSender()], "ERC20: mint not subOwner");
        require(!_mintUniqSerial[uniqSerial], "ERC20: mint dup UniqSerial");

        _totalSupply += amount;
        _balances[account] += amount;
        _mintUniqSerial[uniqSerial] = true;
        _mintUniqSerialIndex.push(uniqSerial);

        emit Transfer(address(0), account, amount);
        emit UniqSerial(uniqSerial);

        return true;
    }
    function burnWithUniqSerial(address account, uint256 amount , string memory uniqSerial) public virtual returns (bool) {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_subOwner[_msgSender()], "ERC20: mint not subOwner");
        require(!_burnUniqSerial[uniqSerial], "ERC20: mint dup uniqSerial");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        _burnUniqSerial[uniqSerial] = true;
        _burnUniqSerialIndex.push(uniqSerial);

        emit Transfer(account, address(0), amount);
        emit UniqSerial(uniqSerial);

        return true;
    }

    function cleanUpHistory() public virtual returns (bool) {
        require(_owner == _msgSender(), "ERC20: cleanUpHistory not owner");
        while(_mintUniqSerialIndex.length > 1000){
            delete(_mintUniqSerial[_mintUniqSerialIndex[0]]);
            delete(_mintUniqSerialIndex[0]);
        }
        while(_burnUniqSerialIndex.length > 1000){
            delete(_burnUniqSerial[_mintUniqSerialIndex[0]]);
            delete(_burnUniqSerialIndex[0]);
        }
        return true;
    }
}