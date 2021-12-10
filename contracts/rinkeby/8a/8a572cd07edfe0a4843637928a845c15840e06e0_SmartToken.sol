/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract SmartToken is Context {
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private owner;
    // address public owners;
    uint256 public transferFee = 0;
    address internal burnWallet = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _balances;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint8 totalSupply_) {
        owner=msg.sender;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_ * (10 ** uint256(6)) * (10 ** uint256(18));
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    //get owner address
    function getOwner() public view virtual returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    // function Coin() public {
    //     owners = getOwner();
    // }

    function mint(uint256 amount) public virtual onlyOwner {
        _mint(_msgSender(), amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "ERC20: transfer amount is zero");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
    function burnFrom(address account, uint256 amount) public virtual {
        if(_msgSender() != account && _msgSender() != getOwner()) {
            revert("Ownable: caller is not the owner of contract or this account");
        }
        require(account != address(0), "ERC20: burn from the zero address");
        require(amount > 0, "ERC20: transfer amount is zero");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(amount > 0, "ERC20: transfer amount is zero");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    function setTransferFee(uint256 _transferFee) public onlyOwner virtual returns (bool) {
        require(_transferFee >= 0 && _transferFee <= 100, "Transfer fee is between 1 and 100.");
        transferFee = _transferFee;
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount is zero");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;

        if(transferFee != 0) {
            uint256 burnAmount = amount * transferFee / 100;
            _balances[burnWallet] += burnAmount;
            emit Transfer(sender, burnWallet, burnAmount);
            amount -= burnAmount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public onlyOwner virtual returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount is zero");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;

        if(transferFee != 0) {
            uint256 burnAmount = amount * transferFee / 100;
            _balances[burnWallet] += burnAmount;
            emit Transfer(sender, burnWallet, burnAmount);
            amount -= burnAmount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

}