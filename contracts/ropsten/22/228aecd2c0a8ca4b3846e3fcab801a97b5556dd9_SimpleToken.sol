pragma solidity ^0.4.20;

contract SimpleToken{
    //map 币总量 map =>adr:val
    mapping(address=>uint256) public balanceOf;
    
    //构造函数 初始化，总量
    function SimpleToken(uint256 initialSupply)public{
        balanceOf[msg.sender]=initialSupply;
    }
    
    //转账 要转过去的地址，数量
    function transfer(address _to,uint256 _value)public{
        require(balanceOf[msg.sender]>=_value);
        require(balanceOf[_to]+_value>=balanceOf[_to]);
        
        balanceOf[msg.sender]-=_value;
        balanceOf[_to]+=_value;
    }
}