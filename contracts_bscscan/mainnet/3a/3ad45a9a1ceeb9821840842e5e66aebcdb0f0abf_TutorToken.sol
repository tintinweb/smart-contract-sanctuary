/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity ^0.8.3;

contract TutorToken {
    
    uint public totalSupply = 10000 *10**18;
    string public name = "Tutor Token";
    string public symbol = "TTT";
    uint public decimals = 18;
    
    
    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    } 
    function TotalSupply() public view returns(uint) {
        return totalSupply;
    }
    function transfer(address to, uint value) public returns(bool) {
        require(balances[msg.sender] >= value, 'Not Enough Balance' );
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to , value);
        return true; 
    }
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balances[from] >= value, 'not enough balance');
        require(allowance[from][msg.sender] >= value, 'not enough allowance balance');
        allowance[from][msg.sender] -= value;
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to , value);
        return true;
    }
}