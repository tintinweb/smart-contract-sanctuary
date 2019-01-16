pragma solidity ^0.4.19;


contract LaolaiManage{
    
    mapping(string=>string) laolaiMap;
    //查询价格
    uint price = 0.001 ether;
    
    address owner;
    
    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
  
    function LaolaiManage() public {
        owner = msg.sender;
    }
    
    function addLaolai(string idCard, string val)public onlyOwner returns(bool){
        laolaiMap[idCard]=val;
        return true;
    }
    
    function judgeLaolai(string idCard)public payable returns(string){
        require(msg.value >= price);
        return laolaiMap[idCard];
    }
    
    function hello() pure public returns(string){
        return "hello";
    }
    
}