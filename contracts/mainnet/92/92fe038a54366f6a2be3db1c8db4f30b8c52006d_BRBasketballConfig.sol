pragma solidity ^0.4.7;
contract MobaBase {
    address public owner = 0x0;
    bool public isLock = false;
    constructor ()  public  {
        owner = msg.sender;
    }
    
    event transferToOwnerEvent(uint256 price);
    
    modifier onlyOwner {
        require(msg.sender == owner,"only owner can call this function");
        _;
    }
    
    modifier notLock {
        require(isLock == false,"contract current is lock status");
        _;
    }
    
    modifier msgSendFilter() {
        address addr = msg.sender;
        uint size;
        assembly { size := extcodesize(addr) }
        require(size <= 0,"address must is not contract");
        require(msg.sender == tx.origin, "msg.sender must equipt tx.origin");
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function transferToOwner()    
    onlyOwner 
    msgSendFilter 
    public {
        uint256 totalBalace = address(this).balance;
        owner.transfer(totalBalace);
        emit transferToOwnerEvent(totalBalace);
    }
    
    function updateLock(bool b) onlyOwner public {
        
        require(isLock != b," updateLock new status == old status");
        isLock = b;
    }
    
   
}

contract IRandomUtil{
     function getBaseRandom() public view returns (bytes32);
     function addContractAddr() public;
}

contract BRRandom {
    
    IRandomUtil public baseRandom;
    address internal mainnet_random_addr = 0x00Df567284E9c076eb207cB64fcDc14aE89199c44d;
    
    function initRandom (address addr) internal  {
        
        require(baseRandom == address(0x0),"BRRandom has been init!");
        baseRandom = IRandomUtil(addr);
        baseRandom.addContractAddr();
        require(getBaseRandom() != 0,"random init has error");
    }
    
    function getBaseRandom() public view returns (bytes32) {
         return baseRandom.getBaseRandom();
     }
}

///////////////////////////////////////////////yaoq邀请///////////////////////////

contract IInviteData{
    
    function GetAddressByName(bytes32 name) public view returns (address);
}
contract BRInvite{
    
    uint private inviteRate = 10;
    IInviteData public mInviteData;

    address internal mainnet_invite_addr = 0x008796E9e3b15869D444B8AabdA0d3ea7eEafDEa96;
    
    function initInviteAddr (address addr,uint rate) internal  {
        
        require(mInviteData == address(0x0),"BRInvite has been init!");
        mInviteData = IInviteData(addr);
        inviteRate  = rate;
    }
    
    function GetAddressByName(bytes32 name) public view returns (address) {
         return mInviteData.GetAddressByName(name);
    }
    
    
   function getInviteRate() public view returns (uint) {
       return inviteRate;
   }
}




contract IConfigData {
   function getPrice() public view returns (uint256);
   function getWinRate(uint8 winCount) public pure returns (uint);
   function getOverRate(uint8 winCount) public pure returns (uint);
   function getPumpRate() public view returns(uint8);
   function getBaseRandom() public view returns (bytes32);
   function GetAddressByName(bytes32 name) public view returns (address);
   function getInviteRate() public view returns (uint);
   function loseHandler(address addr,uint8 wincount) public ;
}

contract BRBasketballConfig is MobaBase,BRRandom,BRInvite {
    
   uint256 mPrice    = 10;
   uint8 mPumpRate   = 10;
   uint8 mWinRate    = 50;
   
   constructor() public {
       
      initRandom(mainnet_random_addr);
      initInviteAddr(mainnet_invite_addr,10);
   }
   
   function getPrice() public view returns (uint256) {
       return mPrice;
   }
 
   function getPumpRate() public view returns(uint8) {
       return mPumpRate;
   }
   
   function getWinRate(uint8 winCount) public view returns (uint8) {
       return mWinRate;
   }
    
   function getOverRate(uint8 winCount) public pure returns (uint) {
       
        if(winCount  <= 1) {
            return 50;
        }
        if(winCount  <= 2) {
            return 55;  
        } 
        if(winCount  <= 3) {
            return 60;  
        } 
        if(winCount  <= 4) {
            return 65;  
        } 
        if(winCount  <= 5) {
            return 70;  
        } 
        if(winCount  <= 6) {
            return 75;  
        } 
        return 80;  
   }
   

   
   function loseHandler(address addr,uint8 wincount) public {}
}