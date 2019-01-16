// pragma solidity ^0.4.24
contract Token {
    string public constant name = "jaehyung cho";
    string public constant symbol = "NU";
    uint8 public constant decimals = 18;
    
    uint256 public totalSupply;
    
    
    
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to,uint amount);
    
    address private owner;
    
    constructor (
        uint256 _totalSupply
    ) public {
        owner = msg.sender;
        totalSupply = _totalSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(this),msg.sender,totalSupply);
    }
    
    
    function transfer(
        address to,
        uint amount
    ) public {
        require(balanceOf[msg.sender] >= amount,"from 계정의 보유 금액이 부족합니다.");
        
        uint before1 = balanceOf[msg.sender];
        uint before2 = balanceOf[to];
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        assert(before1 >= balanceOf[msg.sender]);
        assert(before2 <= balanceOf[to]);
        
        emit Transfer(msg.sender,to,amount);
    }

}