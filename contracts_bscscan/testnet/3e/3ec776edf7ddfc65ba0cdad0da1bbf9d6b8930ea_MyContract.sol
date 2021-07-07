/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;


contract MyContract {
    
    mapping(address => uint256) private _addressBalances;
    
    uint256 private _totalSupply;
    
    address private _owner;
    string private _symbol;
    string private _name;
    uint8 private _decimals;
    
    

    constructor() public {
        _totalSupply=1000000;
        _addressBalances[msg.sender] = 100000;
        _totalSupply-=_addressBalances[msg.sender];
        _owner = msg.sender;
        _symbol = "STR";
        _name = "StrongToken";
        _decimals = 0;
        
    }
    
    function connectMyWallet(address addressWallet) public returns (bool result){
        if(_addressBalances[addressWallet] !=0) return false;
        _addressBalances[addressWallet] = 0;
        return true;
    }
    
    function _transfer(address fromAddress, address toAddress, uint256 amount) private returns (bool result){
        if(_addressBalances[fromAddress] >amount){
            _addressBalances[fromAddress] = _addressBalances[fromAddress] - amount;
            _addressBalances[toAddress] += amount;
            return true;
        }
        return false;
    }
    
    function transfer(address toAddress, uint amount) public returns (bool result){
        return _transfer(msg.sender, toAddress, amount);
    }
    
    function balanceOf(address account) public view returns (uint256 balance){
        return _addressBalances[account];
    }
    
    function symbol() external view returns (string memory){
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory){
        return _name;
        
    }
    
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address){
        return _owner;
    }
    
    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8){
        return _decimals;
    }
    
    
    
    
    
}