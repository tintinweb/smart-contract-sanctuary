//SourceUnit: kbgapi.sol

pragma solidity ^0.5.0;
interface token{
     function transfer(address a, uint256 am) external returns (bool success);
     function transferFrom(address a,address b,uint256 am) external returns (bool success);
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
    uint256 public burnrate;
    uint256 public mininvest;
    uint256 public kmininvest;
    event Invest(address a, uint256 am, uint256 period);
    event KBGInvest(address a, uint256 am, uint256 period);
    
    constructor() public {
      owner = msg.sender;
      rate=1000;
      burnrate=100;
      mininvest=0;
      kmininvest=0;
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
       require(msg.sender==owner || msg.sender==admin);
      rate = r;
    }
    function setBurnRate(uint256 r) public {
       require(msg.sender==owner || msg.sender==admin);
       burnrate = r;
    }
    function setMin(uint256 r) public {
       require(msg.sender==owner || msg.sender==admin);
       mininvest = r;
    }
    function setKMin(uint256 r) public {
       require(msg.sender==owner || msg.sender==admin);
       kmininvest = r;
    }
    
    function exchange(address u,uint256 am) public  returns (bool success)  {
        if( usdttoken(usdtaddr).transferFrom(u,address(this),am)){
            return token(tokenaddr).transfer(u,am*(rate/100));
        }
        else
        {
            return false;
        }
    }

    function exchangeToUsdt(address u,uint256 am) public  returns (bool success)  {
        if( token(tokenaddr).transferFrom(u,address(this),am)){
            return usdttoken(usdtaddr).transfer(u,am/(rate/100));
        }
        else
        {
            return false;
        }
    }
    
    function invest(address u,uint256 am,uint256 p) public  returns (bool success)  {
        require(am>=mininvest,"less then min invest");
        if( usdttoken(usdtaddr).transferFrom(u,address(this),am)  && token(tokenaddr).transferFrom(u,address(this),am*(burnrate/100))){
             emit Invest(u,am,p);
             return true;
        }
        else
        {
            return false;
        }
    }
    function investKBG(address u,uint256 am,uint256 p) public  returns (bool success)  {
        require(am>=kmininvest,"less then min kbg invest");
        if(token(tokenaddr).transferFrom(u,address(this),am)){
             emit KBGInvest(u,am,p);
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