pragma solidity ^0.6.0;
contract Ballot {
 
    uint256 public i=0; //int
    bool public is_=true; //false
    string private name="zhangsan";
 
    function updateI() public {
        i=1;
        is_=false;
        name="lisi";
    }
    
      function updateK(uint256 j,bool c,string memory k) public {
        i=j;
        is_=c;
        name=k;
    }
    
      function queryB(uint256 j,bool c,string memory k) public view returns(uint256,bool,string memory) {
        return (i,is_,name);
    }
    
}