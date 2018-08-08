pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface IDonQuixoteToken{                          
    function withhold(address _user,  uint256 _amount) external returns (bool _result);  
    function transfer(address _to, uint256 _value) external;                             
    function sendGameGift(address _player) external returns (bool _result);              
    function logPlaying(address _player) external returns (bool _result);               
    function balanceOf(address _user) constant  external returns (uint256 _balance);
} 

contract BaseGame {             
    string public gameName="BigOrSmall";         
     uint public constant gameType = 2001;   
    string public officialGameUrl;  
    mapping (address => uint256) public userTokenOf;     
    uint public bankerBeginTime;     
    uint public bankerEndTime;       
    address public currentBanker;      
    	
    function depositToken(uint256 _amount) public;
    function withdrawToken(uint256 _amount) public;
	function withdrawAllToken() public;
    function setBanker(address _banker, uint256 _beginTime, uint256 _endTime) public returns(bool _result);     
    function canSetBanker() view public returns (bool _result);         
}
contract Base is BaseGame { 
    using SafeMath for uint256;     
    uint public createTime = now;
    address public owner;
	
    IDonQuixoteToken public DonQuixoteToken;
      function Base() public {
    }
	
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
    function setOwner(address _newOwner)  public  onlyOwner {
         require(_newOwner!= 0x0);
        owner = _newOwner;
    }
        
    bool public globalLocked = false;     

    function lock() internal {             
        require(!globalLocked);
        globalLocked = true;
    }

    function unLock() internal {
        require(globalLocked);
        globalLocked = false;
    }    
  
    function setLock()  public onlyOwner{
        globalLocked = false;     
    }
    function tokenOf(address _user) view public returns(uint256 _result){
        _result = DonQuixoteToken.balanceOf(_user);
    }
	
    function depositToken(uint256 _amount) public {
        lock();
        _depositToken(msg.sender, _amount);
        unLock();
    }

    function _depositToken(address _to, uint256 _amount) internal {         
        require(_to != 0x0);
        DonQuixoteToken.withhold(_to, _amount);
        userTokenOf[_to] = userTokenOf[_to].add(_amount);
    }

    function withdrawAllToken() public{    
        uint256 _amount = userTokenOf[msg.sender];
        withdrawToken(_amount);
    }
	
	function withdrawToken(uint256 _amount) public {    
        lock();  
        _withdrawToken(msg.sender, _amount);
        unLock();
    }

    function _withdrawToken(address _to, uint256 _amount) internal {      
        require(_to != 0x0);
        userTokenOf[_to] = userTokenOf[_to].sub(_amount);
        DonQuixoteToken.transfer(_to, _amount);
    }

    uint public currentEventId = 1;            

    function getEventId() internal returns(uint _result) {  
        _result = currentEventId;
        currentEventId ++;
    }

    function setOfficialGameUrl(string _newOfficialGameUrl) public onlyOwner{
        officialGameUrl = _newOfficialGameUrl;
    }
        
}

contract SelectOne is Base
{    
    uint public constant minNum = 1;        
    uint public maxNum = 22;               
    uint  public winMultiplePer = 90;     
    
    uint  public constant maxPlayerNum = 100;      
    uint public gameTime; 
    uint256 public gameMaxBetAmount;    
    uint256 public gameMinBetAmount;    
	
	function SelectOne(uint _maxNum, uint  _gameTime, uint256 _gameMinBetAmount, uint256 _gameMaxBetAmount,uint _winMultiplePer, string _gameName,address _DonQuixoteToken)  public {
        require(_gameMinBetAmount >= 0);
        require(_gameMaxBetAmount > 0);
        require(_gameMaxBetAmount >= _gameMinBetAmount);
		require(_maxNum < 10000);              
        require(1 < _maxNum);                   
        require(_winMultiplePer < _maxNum.mul(100));      
        
		gameMinBetAmount = _gameMinBetAmount;
        gameMaxBetAmount = _gameMaxBetAmount;
        gameTime = _gameTime;
        maxNum = _maxNum;                      
        winMultiplePer = _winMultiplePer;       
        owner = msg.sender;             
        gameName = _gameName;           

        require(_DonQuixoteToken != 0x0);
        DonQuixoteToken = IDonQuixoteToken(_DonQuixoteToken);
    }

    uint public lastBlockNumber = 0;            
    bool public betInfoIsLocked = false;       
    address public auction;             
    

    function setAuction(address _newAuction) public onlyOwner{
        require(_newAuction != 0x0);
        auction = _newAuction;
    }
    modifier onlyAuction {             
        require(msg.sender == auction);
        _;
    }

    function canSetBanker() public view returns (bool _result){
        _result =  bankerEndTime <= now && gameOver;
    }
	
    modifier onlyBanker {               
        require(msg.sender == currentBanker);
        require(bankerBeginTime <= now);
        require(now < bankerEndTime);     
        _;
    }

    event OnSetNewBanker(address _caller, address _banker, uint _beginTime, uint _endTime, uint _code, uint _eventTime, uint eventId);

    function setBanker(address _banker, uint _beginTime, uint _endTime) public onlyAuction returns(bool _result)
	{
        _result = false;
        require(_banker != 0x0);
        if(now < bankerEndTime){        
            emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 1, now, getEventId());
            return;
        }
        if(!gameOver){                  
            emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 2, now, getEventId());
            return;
        }
        if(_beginTime > now){               
            emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 3, now, getEventId()); 
            return;
        }
        if(_endTime <= now){
            emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 4, now, getEventId());
            return;
        }
	    if(now < donGameGiftLineTime){
            DonQuixoteToken.logPlaying(_banker);
        }
        currentBanker = _banker;
        bankerBeginTime = _beginTime;
        bankerEndTime = _endTime;
        emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 0 , now, getEventId());
        _result = true;
    }
 
    uint public playNo = 1;             
    uint public gameID = 0;             
    uint public gameBeginPlayNo;        
    uint public gameEndPlayNo;          
    bytes32 public gameEncryptedText;  
    uint public gameResult;            
    string public gameRandon1;          
    string public constant gameRandon2 = &#39;ChinasNewGovernmentBracesforTrump&#39;;   
    uint  public gameBeginTime;        
    uint  public gameEndTime;           
    bool public gameOver = true;       
    uint public donGameGiftLineTime = now.add(90 days);  
    
	
    event OnNewGame(uint _gameID, address _banker, bytes32 _gameEncryptedText, uint  _gameBeginTime,  uint  _gameEndTime, uint _eventTime, uint _eventId);

    function newGame(bytes32 _gameEncryptedText) public onlyBanker returns(bool _result)               
    {
        _result = _newGame( _gameEncryptedText);
    }

    function _newGame(bytes32 _gameEncryptedText) private  returns(bool _result)       
    {
        _result = false;
        require(gameOver); 
        require(bankerBeginTime < now);       
        require(now.add(gameTime) <= bankerEndTime);    
        gameID++;                           
        currentBanker = msg.sender;
        gameEncryptedText = _gameEncryptedText;
        gameRandon1 = &#39;&#39;;          
        gameBeginTime = now;                
        gameEndTime = now.add(gameTime);
        gameBeginPlayNo = playNo;          
        gameEndPlayNo = 0;                 
        gameResult = 0;  
        gameOver = false;
        
        emit OnNewGame(gameID, msg.sender, _gameEncryptedText, now, now.add(gameTime), now, getEventId());
        _result = true;
    }
    
    struct betInfo              
    {
        address Player;
        uint BetNum;            
        uint256 BetAmount;      
        bool IsReturnAward;     
    }

    mapping (uint => betInfo) public playerBetInfoOf;              
    event OnPlay(uint indexed _gameID, address indexed _player, uint _betNum, uint256 _betAmount, uint _playNo, uint _eventTime, uint _eventId);

    function play(uint _betNum, uint256 _betAmount) public  returns(bool _result){      
        _result = _play(_betNum, _betAmount);
    }

    function _play(uint _betNum, uint256 _betAmount) private  returns(bool _result){            
        _result = false;
        require(!gameOver);
        require(!betInfoIsLocked);                         
        require(now < gameEndTime);
        require(playNo.sub(gameBeginPlayNo) <= maxPlayerNum); 
        require(minNum <= _betNum && _betNum <= maxNum);    
        require(msg.sender != currentBanker);                
                   
        uint256 ba = _betAmount;
        if (ba > gameMaxBetAmount){                       
            ba = gameMaxBetAmount;
        }
        require(ba >= gameMinBetAmount);                   

        if(userTokenOf[msg.sender] < ba){                                       
            depositToken(ba.sub(userTokenOf[msg.sender]));                    
        }
        require(userTokenOf[msg.sender] >= ba);             
       
        uint256 BankerAmount = ba.mul(winMultiplePer).div(100);                  
      
        require(userTokenOf[currentBanker] >= BankerAmount);

        betInfo memory bi = betInfo({
                Player :  msg.sender,
                BetNum : _betNum,
                BetAmount : ba,
                IsReturnAward: false                 
        });

        playerBetInfoOf[playNo] = bi;
        userTokenOf[msg.sender] = userTokenOf[msg.sender].sub(ba);                     
        userTokenOf[currentBanker] = userTokenOf[currentBanker].sub(BankerAmount);      
        userTokenOf[this] = userTokenOf[this].add(ba.add(BankerAmount));                

        emit OnPlay(gameID,  msg.sender,  _betNum,  ba, playNo, now, getEventId());

        lastBlockNumber = block.number;    
        playNo++;                          

        if(now < donGameGiftLineTime){     
            DonQuixoteToken.logPlaying(msg.sender);           
        }
        _result = true;
    }

   
    
    function lockBetInfo() public onlyBanker returns (bool _result) {                  
        require(!gameOver);
        require(now < gameEndTime);
        require(!betInfoIsLocked);
        betInfoIsLocked = true;
        _result = true;
    }

    function uint8ToString(uint v) private pure returns (string)    
    {
        uint maxlength = 8;                    
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v.div(10);
            reversed[i++] = byte(remainder.add(48));
        }
        bytes memory s = new bytes(i);         
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[(i.sub(j)).sub(1)];         
        }
        string memory str = string(s);          
        return str;                             
    }

    event OnOpenGameResult(uint indexed _gameID, address _banker, uint _gameResult, string _r1, bool  _result, uint  _code, uint _eventTime, uint eventId);

    function openGameResult(uint _gameResult, string _r1) public onlyBanker  returns(bool _result){
        _result =  _openGameResult( _gameResult,  _r1);
    }
    
    function _openGameResult(uint _gameResult, string _r1) private  returns(bool _result){            
       
	   _result = false;
        require(betInfoIsLocked);          
        require(!gameOver);
        require(now <= gameEndTime);       

        if(lastBlockNumber == block.number){                        
            emit OnOpenGameResult(gameID, msg.sender, _gameResult, _r1,  false, 2, now, getEventId());         
            return;
        }

        string memory gr = uint8ToString(_gameResult); 
        if(keccak256(gr, gameRandon2,  _r1) ==  gameEncryptedText){
            if(_gameResult >= minNum && _gameResult <= maxNum){     
                gameResult = _gameResult;
                gameRandon1 = _r1;
                gameEndPlayNo = playNo.sub(1); 
                for(uint i = gameBeginPlayNo; i < playNo; i++){     
                    betInfo storage p = playerBetInfoOf[i];
                    if(!p.IsReturnAward){   
                        p.IsReturnAward = true;
                        uint256 AllAmount = p.BetAmount.mul(winMultiplePer.add(100)).div(100);    
                        if(p.BetNum == _gameResult){                                           
                            userTokenOf[p.Player] = userTokenOf[p.Player].add(AllAmount);     
                            userTokenOf[this] = userTokenOf[this].sub(AllAmount);               
                        }else{                                                                  
                            userTokenOf[currentBanker] = userTokenOf[currentBanker].add(AllAmount);
                            userTokenOf[this] = userTokenOf[this].sub(AllAmount);               
                            if(now < donGameGiftLineTime){  
                                DonQuixoteToken.sendGameGift(p.Player);                                
                            } 
                        }
                    }
                }
                gameOver = true;
                betInfoIsLocked = false;    
                emit OnOpenGameResult(gameID, msg.sender,  _gameResult,  _r1, true, 0, now, getEventId());      
                _result = true;
                return;
            }else{       
                emit OnOpenGameResult(gameID, msg.sender,  _gameResult,  _r1,  false, 3, now, getEventId()); 
                return;                  
            }
        }else{           
            emit OnOpenGameResult(gameID, msg.sender,  _gameResult,  _r1,  false,4, now, getEventId());
            return;
        }        
    }

    function openGameResultAndNewGame(uint _gameResult, string _r1, bytes32 _gameEncryptedText) public onlyBanker returns(bool _result){
		if(gameOver){
            _result = true ;
        }else{
            _result = _openGameResult( _gameResult,  _r1);
        }
        if (_result){      
            _result = _newGame( _gameEncryptedText);
        }
    }

    function noOpenGameResult() public  returns(bool _result){         
        _result = false;
        require(!gameOver);       
        require(gameEndTime < now); 
        if(lastBlockNumber == block.number){                           
            emit OnOpenGameResult(gameID, msg.sender,0, &#39;&#39;,false, 2, now, getEventId());
            return;
        }

        lock(); 
		
        gameEndPlayNo = playNo - 1;         
        for(uint i = gameBeginPlayNo; i < playNo; i++){                                
            betInfo storage p = playerBetInfoOf[i];
            if(!p.IsReturnAward){           
                p.IsReturnAward = true;
                uint256 AllAmount = p.BetAmount.mul(winMultiplePer.add(100)).div(100);     
                userTokenOf[p.Player] = userTokenOf[p.Player].add(AllAmount);          
                userTokenOf[this] = userTokenOf[this].sub(AllAmount);                  
            }
        }

        gameOver = true;
        if(betInfoIsLocked){
            betInfoIsLocked = false;    
        }
        emit OnOpenGameResult(gameID, msg.sender,   0,  &#39;&#39;,  true, 1, now, getEventId());
        _result = true;

        unLock();  
    }

    function  failUserRefund(uint _playNo) public returns (bool _result) {      
        _result = false;
        require(!gameOver);
        require(gameEndTime.add(30 days) < now);          

        betInfo storage p = playerBetInfoOf[_playNo];   
        require(p.Player == msg.sender);               
        
        if(!p.IsReturnAward && p.BetNum > 0){            
            p.IsReturnAward = true;
            uint256 ToUser = p.BetAmount;   
            uint256 ToBanker = p.BetAmount.mul(winMultiplePer).div(100);  
            userTokenOf[this] = userTokenOf[this].sub(ToUser.add(ToBanker));              
            userTokenOf[p.Player] = userTokenOf[p.Player].add(ToUser);         
            userTokenOf[currentBanker] = userTokenOf[currentBanker].add(ToBanker);
            _result = true;                                  
        }
    }

    function transEther() public onlyOwner()    
    {
        msg.sender.transfer(address(this).balance);
    }
    
    function () public payable {        
      
    }


}