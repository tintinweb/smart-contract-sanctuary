/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

pragma solidity ^0.8.2;

contract NewToken{
    string public Name = "Test";
    string public symbol = "TE";
    uint public totalSupply = 100000 * 10 ** 18;
    
    //mapping
    mapping(address => uint)public balance;
    address public OwnerAdress;
    //event
    event Transfer(address indexed From,address indexed To,uint Amount);
    
    constructor(){
        balance[msg.sender] = totalSupply;
        OwnerAdress = msg.sender;
    }
    
    function balanceOf(address owner) public view returns(uint){
        return balance[owner];
    }
    
    function transfer(address to,uint amount) public returns(bool){
        require(balanceOf(msg.sender) >= amount,"balance low");
        balance[to] += amount;
        balance[msg.sender] -= amount;
        emit Transfer(msg.sender,to,amount);
        return true;
    }
    
    function transferFrom(address from,address to,uint amount) public returns(bool){
        require(msg.sender == OwnerAdress,"khong co quyen!");
        require(balanceOf(from) >= amount,"khong du tien");
        balance[to] += amount;
        balance[from] -= amount;
        return true;
    }
    
}