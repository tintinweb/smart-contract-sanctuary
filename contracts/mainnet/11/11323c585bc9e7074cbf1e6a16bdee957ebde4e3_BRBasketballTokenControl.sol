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
    
    IRandomUtil private baseRandom;
    address internal mainnet_random_addr = 0x31E0d4b2d086e8Bfc25A10bE133dEc09cb5284d2;
    
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
   function getBaseRandom() public returns (bytes32);
   function GetAddressByName(bytes32 name) public view returns (address);
   function getInviteRate() public view returns (uint);
   function loseHandler(address addr,uint8 wincount) public ;
}

contract IERC20Token {
    function name() public view returns (string) ;
    function symbol() public view returns (string); 
    function decimals() public view returns (uint8); 
    function totalSupply() public view returns (uint256); 
    function balanceOf(address _owner) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract ConvertUtil{
    
     function bytesToUint(bytes b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    }
    
   function slice(bytes memory data,uint start,uint len) internal pure returns(bytes){
      bytes memory b=new bytes(len);
      for(uint i=0;i<len;i++){
          b[i]=data[i+start];
      }
      return b;
  }
    
    function stringToBytes32( bytes source) internal pure returns (bytes32 result) {
  
        if (source.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function isNotContract(address addr) internal view returns (bool) {
        
        uint size;
        assembly { size := extcodesize(addr) }
        require(size <= 0,"address must is not contract");
        
        if(size <= 0)
            return true;
        return false;
    }
}

contract BRBasketballTokenControl is MobaBase,ConvertUtil{
    
    Winner public mWinner;

    uint gameIndex;
    IConfigData public mNewConfig;
    IConfigData public mConfig = IConfigData(0x00e04c5271ee336cc7b499a2765a752f3f99e65fee);
    IERC20Token public token  =  IERC20Token(0x007a6eBE5Cc20DA8655640fC1112522367569F2114);

    constructor(address config,address tokenAddr) public {
        mConfig = IConfigData(config);
        if(token != address(0)){
            token   = IERC20Token(tokenAddr);
        }
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
    

    
    ////////////////////////////////////////////////////////
    // handle logic gate after receive Token
    ////////////////////////////////////////////////////////
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
       
        IERC20Token t = IERC20Token(_token);
        require(_token == address(token),"token is error" );
        require(_from == tx.origin,  "token from must equal tx.origin");
        require(isNotContract(_from),"token from  is not Contract");
        require(_value ==  mConfig.getPrice(),"value is error" );
        require(t.transferFrom(_from, this, _value),"transferFrom has error");

        bytes memory inviteBytes = slice(_extraData,0,_extraData.length-1);
        bytes memory numBytes = slice(_extraData,_extraData.length-1,1);
        uint8  num = uint8(bytesToUint(numBytes));
        bytes32 inviteName = stringToBytes32(inviteBytes);
        PK(_from,num,inviteName);
    }
    
    

    function PK(address pkAddr,uint8 num,bytes32 name) 
    notLock
    private  {
        
        uint winRate  = mConfig.getWinRate(mWinner.winCount);

        uint curWinRate ; uint curOverRate;
        (curWinRate,curOverRate) = getRandom(100);
        
        inviteHandler(name);
        address oldWinAddr = mWinner.addr;
        if(mWinner.addr == address(0) ) {
            mWinner = Winner(num,0,pkAddr);
        }
        else if( winRate < curWinRate ) {
            mWinner = Winner(num,1,pkAddr);
        }
        else{
       
            mWinner.winCount = mWinner.winCount + 1;
        }
        bool pkIsWin = (pkAddr == mWinner.addr);
        uint overRate = mConfig.getOverRate(mWinner.winCount);
        emit pkEvent(mWinner.addr,pkAddr,name, winRate, overRate, curWinRate, curOverRate,pkIsWin, mConfig.getPrice());
        if(oldWinAddr != address(0) && curOverRate < overRate  ) {
        
          require(mWinner.addr != address(0),"Winner.addr is null");
          
          uint pumpRate = mConfig.getPumpRate();
          uint totalBalace = token.balanceOf(address(this));
          
          uint giveToOwn   = totalBalace * pumpRate / 100;
          uint giveToActor = totalBalace - giveToOwn;
          
          token.transfer(owner,giveToOwn);
          token.transfer(mWinner.addr,giveToActor);
            
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
        if( mConfig.getInviteRate() <= 0 ){
            return;
        }
        address inviteAddr = mConfig.GetAddressByName(inviteName);
        if(inviteAddr != address(0)) {
           uint giveToToken   = mConfig.getPrice() * mConfig.getInviteRate() / 100;
           token.transfer(inviteAddr,giveToToken);
        }
    }
    function getRandom(uint maxNum) private returns(uint,uint) {
     
        bytes32 curRandom = mConfig.getBaseRandom();
        
        curRandom = keccak256(abi.encodePacked(tx.origin,now,tx.gasprice,curRandom,block.timestamp ,block.number, block.difficulty,((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) ));

        uint value1 = (uint(curRandom) % maxNum);
        curRandom  = keccak256(abi.encodePacked(tx.origin,now,tx.gasprice,curRandom,value1,block.timestamp ,block.number, block.difficulty,((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) ));
        uint value2 = (uint(curRandom) % maxNum);
       
        return (value1,value2);
    }
    
    function getGameInfo() public view returns (uint index,uint price,uint256 balace, 
                                          uint winNum,uint winCount,address WinAddr,uint winRate,uint winOverRate,
                                          uint pkOverRate
                                          ){
        uint curbalace    =  token.balanceOf(address(this));
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
    function () payable public {
        require(msg.value == 0 );
    }
}