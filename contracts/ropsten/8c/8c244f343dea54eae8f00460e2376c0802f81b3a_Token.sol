// pragma solidity ^0.4.24
contract Token {
    string public constant name = "jaehyung cho";
    string public constant symbol = "NU";
    uint8 public constant decimals = 18;
    
    uint256 public totalSupply;
    
    
    
    mapping(address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to,uint amount);
    event Burn(address indexed from,uint amount);
    address private owner;
    
    modifier onlyOwner(){
        require(msg.sender == owner ,"발행자가 아니시네요?");
        _;
    }  
    
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

    function burn(
        uint amount
    ) public onlyOwner {
        require(totalSupply >= amount * 10 ** uint256(decimals));
        balanceOf[msg.sender] -= amount * 10  ** uint256(decimals);
        totalSupply -= amount * amount ** uint256(decimals);
        emit Burn(msg.sender,amount);
    }

    function addPublish(
        uint amount
    ) onlyOwner public {
        totalSupply += amount * 10 ** uint256(decimals);
        balanceOf[msg.sender] += amount * 10 * uint256(decimals); 
    }
}