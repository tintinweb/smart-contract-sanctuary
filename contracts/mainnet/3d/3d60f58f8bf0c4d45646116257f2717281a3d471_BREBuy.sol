pragma solidity ^0.4.24;
contract BREBuy {
    

    struct ContractParam {
        uint32  totalSize ; 
        uint256 singlePrice;  // 一个eth &#39;
        uint8  pumpRate;
        bool hasChange;
    }
    
    address owner = 0x0;
    uint32  gameIndex = 0;
    uint256 totalPrice= 0;
    ContractParam public setConfig;
    ContractParam public curConfig;
    
    address[] public addressArray = new address[](0);
    
    
   event  addPlayerEvent(uint32,address);
    event GameOverEvent(uint32,uint32,uint256,uint8,address,uint );
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor ( uint32 _totalSize,
                  uint256 _singlePrice
    )  public payable  {
        owner = msg.sender;
        setConfig = ContractParam(_totalSize,_singlePrice * 1 finney ,5,false);
        curConfig = ContractParam(_totalSize,_singlePrice * 1 finney ,5,false);
        startNewGame();
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
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
    
    
    function addPlayer() public payable {
      
        require(msg.value == curConfig.singlePrice);
        totalPrice = totalPrice + msg.value;
        addressArray.push(msg.sender);
       
        emit addPlayerEvent(gameIndex,msg.sender);
        if(addressArray.length >= curConfig.totalSize) {
            gameResult();
            startNewGame();
        }
    }
    
    function getGameInfo() public view returns  (uint256,uint32,uint256,uint8,address[],uint256)  {
        return (gameIndex,
                curConfig.totalSize,
                curConfig.singlePrice,
                curConfig.pumpRate,
                addressArray,
                totalPrice);
    }
    
    function getSelfCount() private view returns (uint32) {
        uint32 count = 0;
        for(uint i = 0; i < addressArray.length; i++) {
            if(msg.sender == addressArray[i]) {
                count++;
            }
        }
        return count;
    }
    
    function gameResult() private {
            
      uint index  = getRamdon();
      address lastAddress = addressArray[index];
      uint totalBalace = address(this).balance;
      uint giveToOwn   = totalBalace * curConfig.pumpRate / 100;
      uint giveToActor = totalBalace - giveToOwn;
      owner.transfer(giveToOwn);
      lastAddress.transfer(giveToActor);
      emit GameOverEvent(
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
}