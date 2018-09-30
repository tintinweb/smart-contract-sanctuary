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

contract IConfigData {
   function getPrice() public view returns (uint256);
   function getWinRate(uint8 winCount) public pure returns (uint);
   function getOverRate(uint8 winCount) public pure returns (uint);
   function getPumpRate() public view returns(uint8);
   function getRandom(bytes32 param) public returns (bytes32);
   function GetAddressByName(bytes32 name) public view returns (address);
   function getInviteRate() public view returns (uint);
   function loseHandler(address addr,uint8 wincount) public ;
}

contract BRBasketballControl is MobaBase {
    
    Winner public mWinner;
    bytes32 mRandomValue;

    uint gameIndex;
    IConfigData public mConfig;
    IConfigData public mNewConfig;
   
    constructor(address config) public {
        mConfig = IConfigData(config);
        startNewGame();
    }
    event pkEvent(address winAddr,address pkAddr,bytes32 pkInviteName,uint winRate,uint overRate,uint curWinRate,uint curOverRate,bool pkIsWin,uint256 price);
    event gameOverEvent(uint gameIndex,address winAddr,uint256 price,uint256 totalBalace);
    struct Winner {
        uint8 num;
        uint8 winCount;
        address addr;
    }
    
    function updateConfig(address newAddr)
    onlyOwner 
    public{
        mNewConfig = IConfigData(newAddr);
  
    }
    
    function PK(uint8 num,bytes32 name) 
    notLock
    msgSendFilter
    public payable {
        
        require(msg.value == mConfig.getPrice(),"msg.value is error");
        require(msg.sender != mWinner.addr,"msg.sender != winner");
        uint winRate  = mConfig.getWinRate(mWinner.winCount);

        uint curWinRate ; uint curOverRate;
        (curWinRate,curOverRate) = getRandom(100);
        
  
                
        inviteHandler(name);
        address oldWinAddr = mWinner.addr;
        if(mWinner.addr == address(0) ) {
            mWinner = Winner(num,0,msg.sender);
        }
        else if( winRate < curWinRate ) {
            mWinner = Winner(num,1,msg.sender);
        }
        else{
            mWinner.winCount = mWinner.winCount + 1;
        }
        uint overRate = mConfig.getOverRate(mWinner.winCount);
        emit pkEvent(mWinner.addr,msg.sender,name, winRate, overRate, curWinRate, curOverRate,msg.sender == mWinner.addr, mConfig.getPrice());
        if(oldWinAddr != address(0) && curOverRate < overRate  ) {
        
          require(mWinner.addr != address(0),"Winner.addr is null");
          
          uint pumpRate = mConfig.getPumpRate();
          uint totalBalace = address(this).balance;
          uint giveToOwn   = totalBalace * pumpRate / 100;
          uint giveToActor = totalBalace - giveToOwn;
          owner.transfer(giveToOwn);
          mWinner.addr.transfer(giveToActor);
            
         emit gameOverEvent(gameIndex, mWinner.addr,mConfig.getPrice(),giveToActor);
          startNewGame();
        }
    }
    
    function startNewGame() private {
        
        gameIndex++;
        mWinner = Winner(0,1,address(0));
        if(mNewConfig != address(0) && mNewConfig != mConfig){
            mConfig = mNewConfig;
        }
    }
    
    function inviteHandler(bytes32 inviteName) private {
        
        if(mConfig == address(0)) {
          return ;
        }
        address inviteAddr = mConfig.GetAddressByName(inviteName);
        if(inviteAddr != address(0)) {
           uint giveToEth   = msg.value * mConfig.getInviteRate() / 100;
           inviteAddr.transfer(giveToEth);
        }
    }
    function getRandom(uint maxNum) private returns(uint,uint) {
     
        bytes32 curRandom = keccak256(abi.encodePacked(msg.sender,mRandomValue));
        curRandom = mConfig.getRandom(curRandom);
        curRandom = keccak256(abi.encodePacked(msg.sender,mRandomValue));
        uint value1 = (uint(curRandom) % maxNum);
        
        curRandom  = keccak256(abi.encodePacked(msg.sender,curRandom,value1));
        uint value2 = (uint(curRandom) % maxNum);
        mRandomValue = curRandom;
        return (value1,value2);
    }
    
    function getGameInfo() public view returns (uint index,uint price,uint256 balace, 
                                          uint winNum,uint winCount,address WinAddr,uint winRate,uint winOverRate,
                                          uint pkOverRate
                                          ){
        uint curbalace    = address(this).balance;
        uint winnernum   = mWinner.num;
        uint winnercount = mWinner.winCount;
        address winneraddr  = mWinner.addr;
        uint curWinRate  = mConfig.getWinRate(mWinner.winCount);
        uint curOverRate = mConfig.getOverRate(mWinner.winCount);
        uint curPkOverRate= mConfig.getOverRate(1);
        return (gameIndex, mConfig.getPrice(), curbalace,
                winnernum,winnercount,winneraddr,curWinRate,curOverRate,
                curPkOverRate);
    }
}