pragma solidity ^0.4.24;

//import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";



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
    event evtBetting(
        bytes indexed gameType,
        address indexed playerAddr,
        bytes name,
        uint[] bet,
        bool result,
        uint number,
        uint amount,
        uint winAmount
        );
    
}

contract Poker is Ownable,pokerEvents{
    using inArrayExt for address[];
    using intArrayExt for uint[];
    
    address private wallet1;
    address private operator;

    uint public gid=1000;
    bool public gamePaused=false;
    
    mapping(string=>uint) odds;

    /* setting*/
    uint minPrize=0.01 ether;
    uint lotteryPercent = 3 ether;
    uint public minBetVal=0.01 ether;
    uint public maxBetVal=100 ether;
    
    mapping(address=>bytes) public playerNames;
    
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
    
    /*misc */
    uint public rndSeed;
    uint private hour=60*60;
    
    /*
    ===========================================
    CONSTRUCTOR
    ===========================================
    */
    constructor(address _operator,uint _rndSeed) public{
        wallet1=msg.sender;
        operator=_operator;
        
        odds[&#39;bs&#39;]=1.97 ether;
        odds[&#39;suit&#39;]=3.82 ether;
        odds[&#39;num&#39;]=12 ether;
        odds[&#39;nsuit&#39;]=46 ether;
    
        /* free lottery initial*/
        lotto[1]=FreeLotto(true,1000,0.1 ether,hour,0);
        lotto[2]=FreeLotto(true,100000,1 ether,3*hour,0);
        //FreeLotto storage lotto1=FreeLotto(true,1000,0.1 ether,hour,0);
        /*
        lotto1.active=true;
        lotto1.prob=1000;
        lotto1.prize=0.1 ether;
        lotto1.freezeTimer=hour;
        lotto1.count=0;
        */
        //lotto[1]=lotto1;
        
        
        //FreeLotto memory lotto2=FreeLotto(true,100000,1 ether,3*hour,0);
        
        /*FreeLotto storage lotto2;
        lotto2.active=true;
        lotto2.prob=100000;
        lotto2.prize=1 ether;
        lotto2.freezeTimer=3 * hour;
        lotto2.count=0;
        */
        //lotto[2]=lotto2;

        
        /* initial random seed*/
        rndSeed=uint(keccak256(abi.encodePacked(blockhash(block.number-1), msg.sender,now,_rndSeed)));
    }
    
    function test() public view returns(uint,uint,uint){
        /*
        uint[] memory ret=new uint[](1000);
        for(uint i=0;i<1000;i++){
            ret[i]=uint(keccak256(abi.encodePacked(rndSeed,msg.sender,block.coinbase,block.timestamp, block.difficulty,block.gaslimit,i))) % 52 + 1;
        }
        */
        
        return(odds[&#39;bs&#39;],(0.1 ether * odds[&#39;bs&#39;]) / 1 ether,5.2 ether);
    }
    
    function playBigger(uint[] _bet) payable isHuman() public returns(uint){
        require(msg.value >=  minBetVal*_bet.length && msg.value <=  maxBetVal*_bet.length);
        
        uint _betAmount= msg.value /_bet.length;
        bool _ret=false;
        uint _num=0;
        _num= uint(keccak256(abi.encodePacked(rndSeed,msg.sender,block.coinbase,block.timestamp, block.difficulty,block.gaslimit))) % 52 + 1;
        
        if((_num > 31 && _bet.contain(2)) || (_num < 28 && _bet.contain(0))){
            _ret=true;
            
            msg.sender.transfer((_betAmount * odds[&#39;bs&#39;]) / 1 ether);
        }else if(_num>=28 && _num <=31){
            _ret=false;
            msg.sender.transfer(msg.value*12);
        }
        

        gid+=1;
        rndSeed = uint(uint(keccak256(abi.encodePacked(msg.sender,block.timestamp, block.difficulty,block.gaslimit,_num))));
        
        emit evtBetting(&#39;bigger&#39;,msg.sender,playerNames[msg.sender],_bet,_ret,_num,msg.value,(_ret?(msg.value * odds[&#39;bs&#39;]) / 1 ether:0));
        
        return _num;
    }
    
    
    
    function play(uint _gType,uint[] _bet) payable isHuman() public returns(uint){
        require(msg.value >=  minBetVal*_bet.length && msg.value <=  maxBetVal*_bet.length );

        bool _ret=false;
        uint _betAmount= msg.value /_bet.length;
        uint _prize=0;
        uint _winNo= uint(keccak256(abi.encodePacked(rndSeed,msg.sender,block.coinbase,block.timestamp, block.difficulty,block.gaslimit))) % 52 + 1;
        
        /*
        ret%4=0 spades;
        ret%4=1 hearts
        ret%4=2 clubs;
        ret%4=3 diamonds;
        */
        
        if(_gType==1){
            if((_winNo > 31 && _bet.contain(2)) || (_winNo < 28 && _bet.contain(0))){
                _ret=true;
                _prize=(_betAmount * odds[&#39;bs&#39;]) / 1 ether;
            }else if(_winNo>=28 && _winNo <=31){
                _ret=true;
                _prize=(_betAmount * 12) / 1 ether; 
            }
        }
        
        if(_gType==2 && _bet.contain(_winNo%4+1)){
            _ret=true;
            _prize=(_betAmount * odds[&#39;suit&#39;]) / 1 ether; 
        }
        
        if(_gType==3 && _bet.contain(_winNo/13 +1)){
            _ret=true;
            _prize=(_betAmount * odds[&#39;num&#39;]) / 1 ether; 
        }
        
        if(_gType==4 && _bet.contain(_winNo)){
            _ret=true;
            _prize=(_betAmount * odds[&#39;nsuit&#39;]) / 1 ether; 
            
        }

        gid+=1;
        msg.sender.transfer(_prize);
        emit evtBetting(&#39;suit&#39;,msg.sender,playerNames[msg.sender],_bet,_ret,_winNo,msg.value,_prize);
        
        rndSeed = uint(uint(keccak256(abi.encodePacked(msg.sender,block.timestamp, block.difficulty,block.gaslimit,_winNo))));
        
        return _winNo;
    }
    
    /*
    function playNumber(uint[] _bet) payable isHuman() public returns(uint){
        require(msg.value >=  minBetVal*_bet.length && msg.value <=  maxBetVal*_bet.length);

        uint _betAmount= msg.value /_bet.length;
        bool _ret=false;
        uint _num=0;
        _num= uint(keccak256(abi.encodePacked(rndSeed,msg.sender,block.coinbase,block.timestamp, block.difficulty,block.gaslimit))) % 52 + 1;
        
        if(_bet.contain(_num/13 +1)){
            _ret=true;
            msg.sender.transfer((msg.value * odds[&#39;num&#39;]) / (1 ether * _bet.length));
        }

        gid+=1;
        rndSeed = uint(uint(keccak256(abi.encodePacked(msg.sender,block.timestamp, block.difficulty,block.gaslimit,_num))));
        
        emit evtBetting(&#39;number&#39;,msg.sender,playerNames[msg.sender],_bet,_ret,_num,msg.value,(msg.value * odds[&#39;num&#39;]) /  (1 ether * _bet.length));
        
        return _num;
    }
    
    function playNumberSuit(uint[] _bet) payable isHuman() public returns(uint){
        require(msg.value >=  minBetVal*_bet.length && msg.value <=  maxBetVal*_bet.length);

        uint _betAmount= msg.value /_bet.length;
        bool _ret=false;
        uint _num=0;
        _num= uint(keccak256(abi.encodePacked(rndSeed,msg.sender,block.coinbase,block.timestamp, block.difficulty,block.gaslimit))) % 52 + 1;

        if(_bet.contain(_num)){
            _ret=true;
            msg.sender.transfer((msg.value * odds[&#39;nsuit&#39;]) /  (1 ether * _bet.length));
        }

        gid+=1;
        rndSeed = uint(uint(keccak256(abi.encodePacked(msg.sender,block.timestamp, block.difficulty,block.gaslimit,_num))));
        
        emit evtBetting(&#39;numberSuit&#39;,msg.sender,playerNames[msg.sender],_bet,_ret,_num,msg.value,(msg.value * odds[&#39;nsuit&#39;]) / (1 ether * _bet.length));
        
        return _num;
    }
    */
    
    function register(bytes _name) public{
        playerNames[msg.sender]=_name;
    }
    
    function myName() public view returns(bytes){
        return playerNames[msg.sender];
    }
    
    function freeLottery(uint _gid) public{
        //require(!lotteryPlayers.contain(msg.sender),&#39;limit once a day &#39;);
        require(now - lotto[_gid].lastTime[msg.sender] >= lotto[_gid].freezeTimer,&#39;in the freeze time&#39;);
        
        uint winNo = uint(keccak256(abi.encodePacked(msg.sender,block.number,block.timestamp, block.difficulty,block.gaslimit))) % lotto[_gid].prob+1;
        
        if(winNo==777){
            msg.sender.transfer(lotto[_gid].prize);
        }
        
        lotto[_gid].lastTime[msg.sender]=now;
    }
    
    function updateRndSeed() public{
        rndSeed = uint(uint(keccak256(abi.encodePacked(msg.sender,block.number,block.timestamp,block.coinbase, block.difficulty,block.gaslimit))));
    }
    
    function updateOdds(string _game,uint _val) public{
        require(msg.sender==owner || msg.sender==operator);
        
        odds[_game]=_val;
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
        require(msg.sender==owner || msg.sender==operator);
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
    

    function withdrawTo(address _to,uint amount) public onlyOwner returns(bool){
        require(address(this).balance - amount > 0);
        _to.transfer(amount);
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