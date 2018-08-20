pragma solidity ^0.4.24;
contract BREBuy {
    
    struct ContractParam {
        uint32  totalSize ; 
        uint256 singlePrice;
        uint8  pumpRate;
        bool hasChange;
    }
    
    address owner = 0x0;
    uint32  gameIndex = 0;
    uint256 totalPrice= 0;
    bool isLock = false;
    ContractParam public setConfig;
    ContractParam public curConfig;
    
    address[] public addressArray = new address[](0);
                    
    event openLockEvent();
    event addPlayerEvent(uint32 gameIndex,address player);
    event gameOverEvent(uint32 gameIndex,uint32 totalSize,uint256 singlePrice,uint8 pumpRate,address winAddr,uint overTime);
    event stopGameEvent(uint totalBalace,uint totalSize,uint price);
          
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor ( uint32 _totalSize,
                  uint256 _singlePrice
    )  public  {
        owner = msg.sender;
        setConfig = ContractParam(_totalSize,_singlePrice * 1 finney ,5,false);
        curConfig = ContractParam(_totalSize,_singlePrice * 1 finney ,5,false);
        startNewGame();
    }

    modifier onlyOwner {
        require(msg.sender == owner,"only owner can call this function");
        _;
    }
    
     modifier notLock {
        require(isLock == false,"contract current is lock status");
        _;
    }
    
    function isNotContract(address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size <= 0;
    }

    function updateLock(bool b) onlyOwner public {
        
        require(isLock != b," updateLock new status == old status");
       
        isLock = b;
       
        if(isLock) {
            stopGame();
        }else{
            startNewGame();
            emit openLockEvent();
        }
    }
    
    function stopGame() onlyOwner private {
      
      if(addressArray.length <= 0) {
          return;
      }  
      uint totalBalace = address(this).balance;
      uint price = totalBalace / addressArray.length;
      for(uint i = 0; i < addressArray.length; i++) {
          address curPlayer =  addressArray[i];
          curPlayer.transfer(price);
      }
      emit stopGameEvent(totalBalace,addressArray.length,price);
      addressArray.length=0;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function changeConfig( uint32 _totalSize,uint256 _singlePrice,uint8 _pumpRate) onlyOwner public payable {
    
        curConfig.hasChange = true;
        if(setConfig.totalSize != _totalSize) {
            setConfig.totalSize = _totalSize;
        }
        if(setConfig.pumpRate  != _pumpRate){
            setConfig.pumpRate  = _pumpRate;
        }
        if(setConfig.singlePrice != _singlePrice * 1 finney){
            setConfig.singlePrice = _singlePrice * 1 finney;
        }
    }
    
    function startNewGame() private {
        
        gameIndex++;
        if(curConfig.hasChange) {
            if(curConfig.totalSize   != setConfig.totalSize) {
                curConfig.totalSize   = setConfig.totalSize;
            }
            if(curConfig.singlePrice != setConfig.singlePrice){
               curConfig.singlePrice = setConfig.singlePrice; 
            }
            if( curConfig.pumpRate    != setConfig.pumpRate) {
                curConfig.pumpRate    = setConfig.pumpRate;
            }
            curConfig.hasChange = false;
        }
        addressArray.length=0;
    }
    
    function getGameInfo() public view returns  (uint256,uint32,uint256,uint8,address[],uint256,bool)  {
        return (gameIndex,
                curConfig.totalSize,
                curConfig.singlePrice,
                curConfig.pumpRate,
                addressArray,
                totalPrice,
                isLock);
    }
    
    function gameResult() private {
            
      uint index  = getRamdon();
      address lastAddress = addressArray[index];
      uint totalBalace = address(this).balance;
      uint giveToOwn   = totalBalace * curConfig.pumpRate / 100;
      uint giveToActor = totalBalace - giveToOwn;
      owner.transfer(giveToOwn);
      lastAddress.transfer(giveToActor);
      emit gameOverEvent(
                    gameIndex,
                    curConfig.totalSize,
                    curConfig.singlePrice,
                    curConfig.pumpRate,
                    lastAddress,
                    now);
    }
    
    function getRamdon() private view returns (uint) {
      bytes32 ramdon = keccak256(abi.encodePacked(ramdon,now,blockhash(block.number-1)));
      for(uint i = 0; i < addressArray.length; i++) {
            ramdon = keccak256(abi.encodePacked(ramdon,now, addressArray[i]));
      }
      uint index  = uint(ramdon) % addressArray.length;
      return index;
    }
    
    function() notLock payable public{
        require(isNotContract(msg.sender),"Contract not call addPlayer");
        require(msg.value == curConfig.singlePrice,"msg.value error");
        totalPrice = totalPrice + msg.value;
        addressArray.push(msg.sender);
       
        emit addPlayerEvent(gameIndex,msg.sender);
        if(addressArray.length >= curConfig.totalSize) {
            gameResult();
            startNewGame();
        }
    }
}