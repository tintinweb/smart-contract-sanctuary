pragma solidity ^0.4.25;

contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    //emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
    /**
    * @dev prevents contracts from interacting with others
    */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
    
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }


}

contract pokerEvents{
    event Bettings(
        uint indexed guid,
        uint gameType,
        address indexed playerAddr,
        uint[] bet,
        bool indexed result,
        uint winNo,
        uint amount,
        uint winAmount,
        uint jackpot
        );
        
    event JackpotPayment(
        uint indexed juid,
        address indexed playerAddr,
        uint amount,
        uint winAmount
        );
    
    event FreeLottery(
        uint indexed luid,
        address indexed playerAddr,
        uint indexed winAmount
        );
    
}

contract Poker is Ownable,pokerEvents{
    using inArrayExt for address[];
    using intArrayExt for uint[];
    
    address private opAddress;
    address private wallet1;
    address private wallet2;
    
    bool public gamePaused=false;
    uint public guid=1;
    uint public luid=1;
    mapping(string=>uint) odds;

    /* setting*/
    uint minPrize=0.01 ether;
    uint lotteryPercent = 3 ether;
    uint public minBetVal=0.01 ether;
    uint public maxBetVal=1 ether;
    
    /* free lottery */
    struct FreeLotto{
        bool active;
        uint prob;
        uint prize;
        uint freezeTimer;
        uint count;
        mapping(address => uint) lastTime;
    }
    mapping(uint=>FreeLotto) lotto;
    mapping(address=>uint) playerCount;
    bool freeLottoActive=true;
    
    /* jackpot */
    uint public jpBalance=0;
    uint jpMinBetAmount=0.05 ether;
    uint jpMinPrize=0.01 ether;
    uint jpChance=1000;
    uint jpPercent=0.3 ether;
    
        /*misc */
    uint public rndSeed;
    uint private minute=60;
    uint private hour=60*60;
    
    /*
    ===========================================
    CONSTRUCTOR
    ===========================================
    */
    constructor(uint _rndSeed) public{
        opAddress=msg.sender;
        wallet1=msg.sender;
        wallet2=msg.sender;
        
        odds[&#39;bs&#39;]=1.97 ether;
        odds[&#39;suit&#39;]=3.82 ether;
        odds[&#39;num&#39;]=11.98 ether;
        odds[&#39;nsuit&#39;]=49.98 ether;
    
        /* free lottery initial*/
        lotto[1]=FreeLotto(true,1000,0.1 ether,hour / 100 ,0);
        lotto[2]=FreeLotto(true,100000,1 ether,3*hour/100 ,0);

        
        /* initial random seed*/
        rndSeed=uint(keccak256(abi.encodePacked(blockhash(block.number-1), msg.sender,now,_rndSeed)));
    }

     function play(uint _gType,uint[] _bet) payable isHuman() public returns(uint){
        require(msg.value >=  minBetVal*_bet.length && msg.value <=  maxBetVal*_bet.length );

        bool _ret=false;
        uint _betAmount= msg.value /_bet.length;
        uint _prize=0;
        uint _winNo= uint(keccak256(abi.encodePacked(rndSeed,msg.sender,block.coinbase,block.timestamp, block.difficulty,block.gaslimit))) % 52 + 1;
        
        if(_gType==1){
            if(_betAmount * odds[&#39;bs&#39;]  / 1 ether >= address(this).balance/2){
                revert("over max bet amount");
            }
            
            if((_winNo > 31 && _bet.contain(2)) || (_winNo < 28 && _bet.contain(1))){
                _ret=true;
                _prize=(_betAmount * odds[&#39;bs&#39;]) / 1 ether;
            }else if(_winNo>=28 && _winNo <=31 && _bet.contain(0)){
                _ret=true;
                _prize=(_betAmount * 12 ether) / 1 ether; 
            }
        }
        
        /*
        ret%4=0 spades;
        ret%4=1 hearts
        ret%4=2 clubs;
        ret%4=3 diamonds;
        */
        if(_gType==2 && _bet.contain(_winNo%4+1)){
            if(_betAmount * odds[&#39;suit&#39;] / 1 ether >= address(this).balance/2){
                revert("over max bet amount");
            }
            
            _ret=true;
            _prize=(_betAmount * odds[&#39;suit&#39;]) / 1 ether; 
        }
        
        if(_gType==3 && _bet.contain((_winNo-1)/4+1)){
            if(_betAmount * odds[&#39;num&#39;] / 1 ether >= address(this).balance/2){
                revert("over max bet amount");
            }
            
            _ret=true;
            _prize=(_betAmount * odds[&#39;num&#39;]) / 1 ether; 
        }
        
        if(_gType==4 && _bet.contain(_winNo)){
            if(_betAmount * odds[&#39;nsuit&#39;] / 1 ether >= address(this).balance/2){
                revert("over max bet amount");
            }
            
            _ret=true;
            _prize=(_betAmount * odds[&#39;nsuit&#39;]) / 1 ether; 
            
        }

        if(_ret){
            msg.sender.transfer(_prize);
        }else{
            jpBalance += (msg.value * jpPercent) / 100 ether;
        }
        
        rndSeed = uint(uint(keccak256(abi.encodePacked(msg.sender,block.timestamp, block.difficulty,block.gaslimit,_winNo))));
        

        /* JackPot*/
        uint tmpJackpot=0;
        if(_betAmount >= jpMinBetAmount){
            uint _jpNo= uint(keccak256(abi.encodePacked(rndSeed,msg.sender,block.coinbase,block.timestamp, block.difficulty,block.gaslimit))) % jpChance;
            if(_jpNo==77 && jpBalance>jpMinPrize){
                msg.sender.transfer(jpBalance);
                emit JackpotPayment(guid,msg.sender,_betAmount,jpBalance);
                tmpJackpot=jpBalance;
                jpBalance=0;
            }else{
                tmpJackpot=0;
            }
            
            rndSeed = uint(uint(keccak256(abi.encodePacked(msg.sender,block.timestamp, block.difficulty,block.gaslimit,_jpNo))));
        }
        
        emit Bettings(guid,_gType,msg.sender,_bet,_ret,_winNo,msg.value,_prize,tmpJackpot);
        
        guid+=1;
        return _winNo;
    }
    

    function freeLottery(uint _gid) public{
        require(freeLottoActive && lotto[_gid].active,&#39;Free Lotto is closed&#39;);
        require(now - lotto[_gid].lastTime[msg.sender] >= lotto[_gid].freezeTimer,&#39;in the freeze time&#39;);
        
        uint chancex=1;
        uint winNo = 0;
        if(playerCount[msg.sender]>=3){
            chancex=2;
        }
        if(playerCount[msg.sender]>=6){
            chancex=3;
        }
        
        winNo=uint(keccak256(abi.encodePacked(msg.sender,block.number,block.timestamp, block.difficulty,block.gaslimit))) % (playerCount[msg.sender]>=3?lotto[_gid].prob/chancex:lotto[_gid].prob)+1;

        bool result;
        if(winNo==7){
            result=true;
            msg.sender.transfer(lotto[_gid].prize);
        }else{
            result=false;
            if(playerCount[msg.sender]==0 || lotto[_gid].lastTime[msg.sender] <= now -lotto[_gid].freezeTimer - 15*60){
                playerCount[msg.sender]+=1;
            }else{
                playerCount[msg.sender]=0;
            }
        }
        
        emit FreeLottery(luid,msg.sender,result?lotto[_gid].prize:0);
        
        luid=luid+1;
        lotto[_gid].lastTime[msg.sender]=now;
    }
    
    function freeLottoInfo() public view returns(uint,uint,uint){
        uint chance=1;
        if(playerCount[msg.sender]>=3){
            chance=2;
        }
        if(playerCount[msg.sender]>=6){
            chance=3;
        }
        return (lotto[1].lastTime[msg.sender],lotto[2].lastTime[msg.sender],chance);
    }
    
    function updateRndSeed() public {
        require(msg.sender==owner || msg.sender==opAddress,"DENIED");
        
        rndSeed = uint(uint(keccak256(abi.encodePacked(msg.sender,block.number,block.timestamp,block.coinbase, block.difficulty,block.gaslimit))));
    }
    
    function updateOdds(string _game,uint _val) public{
        require(msg.sender==owner || msg.sender==opAddress);
        
        odds[_game]=_val;
    }
    
    function updateStatus(uint _p,bool _status) public{
        require(msg.sender==owner || msg.sender==opAddress);
        
        if(_p==1){gamePaused=_status;}
        if(_p==2){freeLottoActive=_status;}
        if(_p==3){lotto[1].active =_status;}
        if(_p==4){lotto[1].active =_status;}
    }
    
    function getOdds() public view returns(uint[]) {
        uint[] memory ret=new uint[](4);
        ret[0]=odds[&#39;bs&#39;];
        ret[1]=odds[&#39;suit&#39;];
        ret[2]=odds[&#39;num&#39;];
        ret[3]=odds[&#39;nsuit&#39;];
        
        return ret;
    }
    
    function updateLottoParams(uint _gid,uint _key,uint _val) public{
        require(msg.sender==owner || msg.sender==opAddress);
        /* 
        _ke y=> 1:active,2:prob,3:prize,4:freeTimer
        */
        
        if(_key==1){lotto[_gid].active=(_val==1);}
        if(_key==2){lotto[_gid].prob=_val;}
        if(_key==3){lotto[_gid].prize=_val;}
        if(_key==4){lotto[_gid].freezeTimer=_val;}
        
    }
    
    function getLottoData(uint8 _gid) public view returns(bool,uint,uint,uint,uint){
        return (lotto[_gid].active,lotto[_gid].prob,lotto[_gid].prize,lotto[_gid].freezeTimer,lotto[_gid].count);
        
    }
    
    function setAddr(uint _acc,address _addr) public onlyOwner{
        if(_acc==1){wallet1=_addr;}
        if(_acc==2){wallet2=_addr;}
        if(_acc==3){opAddress=_addr;}
    }
    
    function getAddr(uint _acc) public view onlyOwner returns(address){
        if(_acc==1){return wallet1;}
        if(_acc==2){return wallet2;}
        if(_acc==3){return opAddress;}
    }
    

    function withdraw(address _to,uint amount) public onlyOwner returns(bool){
        require(address(this).balance - amount > 0);
        _to.transfer(amount);
    }
    
    function distribute(uint _p) public onlyOwner{
        uint prft1=_p* 85 / 100;
        uint prft2=_p* 10 / 100;
        uint prft3=_p* 5 / 100;

        owner.transfer(prft1);
        wallet1.transfer(prft2);
        wallet2.transfer(prft3);

    }
    
    
    function() payable isHuman() public {
        
    }
    
}


library inArrayExt{
    function contain(address[] _arr,address _val) internal pure returns(bool){
        for(uint _i=0;_i< _arr.length;_i++){
            if(_arr[_i]==_val){
                return true;
                break;
            }
        }
        return false;
    }
}

library intArrayExt{
    function contain(uint[] _arr,uint _val) internal pure returns(bool){
        for(uint _i=0;_i< _arr.length;_i++){
            if(_arr[_i]==_val){
                return true;
                break;
            }
        }
        return false;
    }
}