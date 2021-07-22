/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

pragma solidity ^0.8.2;

contract VIPTOKEN {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000 * 10 ** 18;
    string public name = "VIP TOKEN";
    string public symbol = "VIPTOKEN";
    uint public decimals = 18;
    uint256 public TokenPrice;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    
    //modifier onlyOwner {
        //require(msg.sender == owner);
        //_;
    //}
    
    constructor(uint256 _price) {
        balances[msg.sender] = totalSupply;
        TokenPrice = _price;
    }
    
    //function setEthPrice(uint _etherPrice) {
        //oneTokenInWei = 1 ether * 2 / _etherPrice / 100;
        //changed(msg.sender);
    //}
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}