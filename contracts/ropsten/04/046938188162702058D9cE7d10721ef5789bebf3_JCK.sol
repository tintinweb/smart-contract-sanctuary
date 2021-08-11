/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract JCK {
    uint256 public _price;
    address public _admin;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address[] private tokenOwners;
    
    constructor()
    {
        _admin = msg.sender;
        tokenOwners.push(_admin);
        _price = 1000;
    }
    
    event SetTokenPrice(uint256 price);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address spender, address recipient, uint256 amount);
    
    function getTokenOwners() public view returns (address[] memory) {
        return tokenOwners;
    }
    
    // function getAllToken() internal
    // {
    //     require(msg.sender == _admin);
        
    //     for(uint i = 0; i < tokenOwners.length; i++)
    //     {
    //         _transferFrom(tokenOwners[i], _admin, _balances[address[i]]);
    //     }
    // }
    
    function setTokenPrice(uint256 price) public
    {
        require(msg.sender == _admin);
        _price = price;
        emit SetTokenPrice(price);
    }
    
    function getTokenPrice() public view returns(uint256)
    {
        return _price;
    }
    
    function swap(uint256 ethPrice) public payable 
    {
        _transfer(_admin, msg.sender, ethPrice * 200 * getTokenPrice());
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != _admin, "ERC20: transfer from the zero address");
        require(recipient != _admin, "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount);
        _approve(sender, msg.sender, amount);
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}