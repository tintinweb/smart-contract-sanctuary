pragma solidity ^0.4.24;

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
contract IInviteData{
    function GetAddressByName(bytes32 name) public view returns (address);
}
contract IRandomUtil {
     function getBaseRandom() public view returns (bytes32);
     function addContractAddr() public;
}

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
    
    function isNotContract(address addr) returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        require(size <= 0,"address must is not contract");
        
        if(size <= 0)
            return true;
        return false;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract BREBuy_ERC20 is MobaBase  {
    
    struct ContractParam {
        uint32  totalSize ; 
        uint256 singlePrice;
        uint8  pumpRate;
        bool hasChange;
    }

    uint32  gameIndex = 0;
    uint256 totalPrice= 0;
    uint8 inviteRate = 10;
    ContractParam public setConfig;
    ContractParam public curConfig;
    address[] public addressArray = new address[](0);
    
    IRandomUtil public baseRandom =  IRandomUtil(0x00df567284e9c076eb207cb64fcdc14ae89199c44d);
    IERC20Token public token      =  IERC20Token(0x007a6eBE5Cc20DA8655640fC1112522367569F2114);
    IInviteData public invite     =  IInviteData(0x008796E9e3b15869D444B8AabdA0d3ea7eEafDEa96);

    event openLockEvent();
    event addPlayerEvent(uint32 gameIndex,address player);
    event gameOverEvent(uint32 gameIndex,uint32 totalSize,uint256 singlePrice,uint8 pumpRate,address winAddr,uint overTime);
    event stopGameEvent(uint totalBalace,uint totalSize,uint price);
 
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor ()  public payable  {
        uint32 _totalSize = 3;
        uint256  _singlePrice = 10;
        owner = msg.sender;
        setConfig = ContractParam(_totalSize,_singlePrice  ,5,false);
        curConfig = ContractParam(_totalSize,_singlePrice  ,5,false);
        baseRandom.addContractAddr();
        startNewGame();
    }
   
    
    ////////////////////////////////////////////////////////
    // onlyOwner or private method
    ////////////////////////////////////////////////////////
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
    
    function changeConfig( uint32 _totalSize,uint256 _singlePrice,uint8 _pumpRate) onlyOwner public  {
    
        curConfig.hasChange = true;
        setConfig.totalSize = _totalSize;
        setConfig.pumpRate  = _pumpRate;
        setConfig.singlePrice = _singlePrice;
    }
    
     function updateInviteInfo(address _addr,uint8 _rate) onlyOwner public  {
        invite = IInviteData(_addr);
        inviteRate = _rate;
    }
    
    function stopGame() onlyOwner private {
      
      if(addressArray.length <= 0) {
          return;
      }  
      uint256 totalBalace = token.balanceOf(this);
      uint price = totalBalace / addressArray.length;
      for(uint i = 0; i < addressArray.length; i++) {
          address curPlayer =  addressArray[i];
           token.transfer(curPlayer,price);
      }
      emit stopGameEvent(totalBalace,addressArray.length,price);
      addressArray.length=0;
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
    
    function addPlayer(address player) private {
    
        totalPrice = totalPrice + curConfig.singlePrice;
        addressArray.push(player);
       
        emit addPlayerEvent(gameIndex,player);
        if(addressArray.length >= curConfig.totalSize) {
            gameResult();
            startNewGame();
        }
    } 
    function gameResult() private {
            
      uint index  = getRamdon();
      address winAddress = addressArray[index];
      uint256 totalBalace = token.balanceOf(this);
      uint256 giveToOwn   = totalBalace * curConfig.pumpRate / 100;
      uint256 giveToWin = totalBalace - giveToOwn;
      
      token.transfer(owner,giveToOwn);
      token.transfer(winAddress,giveToWin);
 
      emit gameOverEvent(
                    gameIndex,
                    curConfig.totalSize,
                    curConfig.singlePrice,
                    curConfig.pumpRate,
                    winAddress,
                    now);
    }
    function getRamdon() private view returns (uint) {
      
      bytes32 ramdon = baseRandom.getBaseRandom();
      require(ramdon !=0,"baseRandom error!");
      ramdon = keccak256(abi.encodePacked(ramdon,now,blockhash(block.number-1)));
      for(uint i = 0; i < addressArray.length; i++) {
         ramdon = keccak256(abi.encodePacked(ramdon,now, addressArray[i]));
      }
      uint index  = uint(ramdon) % addressArray.length;
      return index;
    }
    
    ////////////////////////////////////////////////////////
    // handle logic gate after receive Token
    ////////////////////////////////////////////////////////
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
       
        IERC20Token t = IERC20Token(_token);
        require(_token == address(token) );
        require(_from == tx.origin,  "token from must equal tx.origin");
        require(isNotContract(_from),"token from  is not Contract");
        require(_value == curConfig.singlePrice );
        require(t.transferFrom(_from, this, _value));
        addPlayer(_from);
        
        bytes32 inviteName = stringToBytes32(_extraData);
        inviteHandler(inviteName);
    }
    
        
    function inviteHandler(bytes32 inviteName) private {
        
        if(invite == address(0)) {
          return ;
        }
        address inviteAddr = invite.GetAddressByName(inviteName);
        if(inviteAddr != address(0)) {
           uint giveToEth   =  curConfig.singlePrice * inviteRate / 100;
           inviteAddr.transfer(giveToEth);
        }
    }
    
    function stringToBytes32( bytes source) returns (bytes32 result) {
  
        if (source.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
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
    
    function () payable public {
        require(msg.value == 0 );
    }
}