//SourceUnit: kbgapi.sol

pragma solidity ^0.5.0;
interface token{
     function transfer(address a, uint256 am) external returns (bool success);
} 
interface usdttoken{
     function transfer(address a, uint256 am) external returns (bool success);
     function transferFrom(address a,address b,uint256 am) external returns (bool success);
} 

contract KBGAPI{
    address public tokenaddr ;
    address public usdtaddr ;
    address public owner;
    address public admin;
    uint256 public rate;
    event Invest(address a, uint256 am);
    
    constructor() public {
      owner = msg.sender;
      rate=10;
    }
    
    function setToken(address a) public {
      require(msg.sender==owner);
      tokenaddr = a;
    }
   
    function setUsdt(address a) public {
      require(msg.sender==owner);
      usdtaddr = a;
    }
    
    function setAdmin(address a) public {
      require(msg.sender==owner);
      admin = a;
    }
    function setRate(uint256 r) public {
      require(msg.sender==owner);
      rate = r;
    }
    
    function exchange(address u,uint256 am) public  returns (bool success)  {
        if( usdttoken(usdtaddr).transferFrom(u,address(this),am)){
            return token(tokenaddr).transfer(u,am*rate);
        }
        else
        {
            return false;
        }
    }
    
    function invest(address u,uint256 am) public  returns (bool success)  {
        if( usdttoken(usdtaddr).transferFrom(u,address(this),am)){
             emit Invest(u,am);
             return true;
        }
        else
        {
            return false;
        }
    }
    
     function collect(uint256 am) public  returns (bool success){
        require(msg.sender==owner || msg.sender==admin);
        return token(tokenaddr).transfer(msg.sender,am);
     }
     
     function usdtcollect(uint256 am) public  returns (bool success){
        require(msg.sender==owner || msg.sender==admin);
        return usdttoken(usdtaddr).transfer(msg.sender,am);
     }
}