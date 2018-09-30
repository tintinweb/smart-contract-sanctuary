pragma solidity ^0.4.24;


contract lhkjTNB{
    
    address public _owner;  //存储合约的所有者
    string _name;
    
    function lhkjTNB(){
        _owner = msg.sender;
    }
    
    function setName(string name) public returns(string){
        _name = name;
    }
    
    function getName() public returns(string){
        return _name;
    }
    
     //自毁方法
    function kill(address addr){
        //判断是否为合约的所有者
        if(msg.sender != _owner)
            throw;
            
        selfdestruct(addr);     //销毁合约并发送金额到指定地址
    }
}