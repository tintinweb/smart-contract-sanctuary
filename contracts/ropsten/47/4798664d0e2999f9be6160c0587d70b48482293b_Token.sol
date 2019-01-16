// pragma solidity ^0.4.24
contract Token {
    string public constant name = "jaehyung cho";
    string public constant symbol = "NU";
    uint8 public constant decimals = 18;
    
    uint256 public totalSupply;
    
    
    
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to,uint amount);
    
    constructor (
        uint256 _totalSupply
    ) public {
        totalSupply = _totalSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(this),msg.sender,totalSupply);
    }
}