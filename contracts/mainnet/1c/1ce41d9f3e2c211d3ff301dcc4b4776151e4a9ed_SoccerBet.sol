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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract BaseGame { 
	function canSetBanker() view public returns (bool _result);
    function setBanker(address _banker, uint256 _beginTime, uint256 _endTime) public returns(bool _result);
    
    string public gameName = "NO.1";
    uint public gameType = 2004;
    string public officialGameUrl;

	uint public bankerBeginTime;
	uint public bankerEndTime;
	address public currentBanker;
	
	function depositToken(uint256 _amount) public;
	function withdrawAllToken() public;
    function withdrawToken(uint256 _amount) public;
    mapping (address => uint256) public userTokenOf;

}
interface IDonQuixoteToken{
    function withhold(address _user,  uint256 _amount) external returns (bool _result);
    function transfer(address _to, uint256 _value) external;
	//function canSendGameGift() view external returns(bool _result);
    function sendGameGift(address _player) external returns (bool _result);
	function logPlaying(address _player) external returns (bool _result);
	function balanceOf(address _user) constant external returns(uint256 balance);
}  


contract Base is BaseGame{
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

    function setOwner(address _newOwner) public onlyOwner {
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

    function withdrawAllToken() public {    
        lock();  
		uint256 _amount = userTokenOf[msg.sender];
        _withdrawToken(msg.sender,_amount);
        unLock();
    }
	
	function withdrawToken(uint256 _amount) public {   
        lock();  
        _withdrawToken(msg.sender, _amount);
        unLock();
    }
	
    function _withdrawToken(address _from, uint256 _amount) internal {
        require(_from != 0x0);
		require(_amount > 0 && _amount <= userTokenOf[_from]);
		userTokenOf[_from] = userTokenOf[_from].sub(_amount);
		DonQuixoteToken.transfer(_from, _amount);
    }
	
	uint public currentEventId = 1;

    function getEventId() internal returns(uint _result) {
        _result = currentEventId;
        currentEventId = currentEventId.add(1); //currentEventId++
    }
	
    function setOfficialGameUrl(string _newOfficialGameUrl) public onlyOwner{
        officialGameUrl = _newOfficialGameUrl;
    }
}

contract SoccerBet is Base
{
	function SoccerBet(string _gameName,uint _bankerDepositPer, address _DonQuixoteToken) public {
		require(_DonQuixoteToken != 0x0);
		gameName = _gameName;
		bankerDepositPer = _bankerDepositPer;
        DonQuixoteToken = IDonQuixoteToken(_DonQuixoteToken);
        owner = msg.sender;
    }

	uint public unpayPooling = 0;
	uint public losePooling = 0;
	uint public winPooling = 0;
	uint public samePooling = 0;
	
	uint public bankerDepositPer = 20;

    address public auction;
	function setAuction(address _newAuction) public onlyOwner{
        auction = _newAuction;
    }
    modifier onlyAuction {
	    require(msg.sender == auction);
        _;
    }
	
    modifier onlyBanker {
        require(msg.sender == currentBanker);
        require(bankerBeginTime <= now);
        require(now < bankerEndTime);
        _;
    }    
	
	function canSetBanker() public view returns (bool _result){
        _result =  false;
		if(now < bankerEndTime){
			return;
		}
		if(userTokenOf[this] == 0){
			_result = true;
		}
    }
	
	event OnSetNewBanker(uint indexed _gameID , address _caller, address _banker, uint _beginTime, uint _endTime, uint _errInfo, uint _eventTime, uint eventId);
    function setBanker(address _banker, uint _beginTime, uint _endTime) public onlyAuction returns(bool _result)
    {
        _result = false;
        require(_banker != 0x0);

        if(now < bankerEndTime){
            emit OnSetNewBanker(gameID, msg.sender, _banker,  _beginTime,  _endTime, 1, now, getEventId());//"bankerEndTime > now"
            return;
        }
		
		if(userTokenOf[this] > 0){
			emit OnSetNewBanker(gameID, msg.sender, _banker,  _beginTime,  _endTime, 5, now, getEventId());//"userTokenOf[this] > 0"
			return;
		}
        
        if(_beginTime > now){
			emit OnSetNewBanker(gameID, msg.sender, _banker,  _beginTime,  _endTime, 3, now, getEventId());//&#39;_beginTime > now&#39;
            return;
        }

        if(_endTime <= now){
			emit OnSetNewBanker(gameID, msg.sender, _banker,  _beginTime,  _endTime, 4, now, getEventId());//&#39;_endTime <= now&#39;
            return;
        }
		
		if(now < donGameGiftLineTime){
            DonQuixoteToken.logPlaying(_banker);
        }
        currentBanker = _banker;
        bankerBeginTime = _beginTime;
        bankerEndTime =  _endTime;
	
		unpayPooling = 0;
		losePooling = 0;
		winPooling = 0;
		samePooling = 0;
		
		gameResult = 9;
		
		gameOver = true;

		emit OnSetNewBanker(gameID, msg.sender, _banker,  _beginTime,  _endTime, 0, now, getEventId());
        _result = true;
    }

	string public team1;
    string public team2;
	
    uint public constant loseNum = 1;
    uint public constant winNum = 3;
    uint public constant sameNum = 0;

    uint public loseOdd;
    uint public winOdd;
    uint public sameOdd;

    uint public betLastTime;

    uint public playNo = 1;
    uint public gameID = 0;

    uint public gameBeginPlayNo;

    uint public gameResult = 9;

    uint  public gameBeginTime;

    uint256 public gameMaxBetAmount;
    uint256 public gameMinBetAmount;
    bool public gameOver = true;
	
	uint public nextRewardPlayNo=1;
    uint public currentRewardNum = 100;
	
	uint public donGameGiftLineTime =  now + 90 days;
	
	address public decider;
    function setDecider(address _decider) public onlyOwner{	
        decider = _decider;
    }
    modifier onlyDecider{
        require(msg.sender == decider);
        _;
    }
	function setGameResult(uint _gameResult) public onlyDecider{
		require(!gameOver);
		require(betLastTime + 90 minutes < now);
		require(gameResult == 9);
		require( _gameResult == loseNum || _gameResult == winNum || _gameResult == sameNum);
		gameResult = _gameResult;
		if(gameResult == 3){
			unpayPooling = winPooling;
		}else if(gameResult == 1){
			unpayPooling = losePooling;
		}else if(gameResult == 0){
			unpayPooling = samePooling;
		}
	}

    event OnNewGame(uint indexed _gameID, address _banker , uint _betLastTime, uint _gameBeginTime, uint256 _gameMinBetAmount, uint256 _gameMaxBetAmount, uint _eventTime, uint eventId);
	event OnGameInfo(uint indexed _gameID, string _team1, string _team2, uint _loseOdd, uint _winOdd, uint _sameOdd, uint _eventTime, uint eventId);
    function newGame(string _team1, string _team2, uint _loseOdd, uint _winOdd, uint _sameOdd, uint _betLastTime, uint256 _gameMinBetAmount, uint256 _gameMaxBetAmount) public onlyBanker returns(bool _result){ //开局
        require(bytes(_team1).length < 100);
		require(bytes(_team2).length < 100);
		
		require(gameOver);
        require(now > bankerBeginTime);
		require(_gameMinBetAmount >= 10000000);
        require(_gameMaxBetAmount >= _gameMinBetAmount);
		require(now < _betLastTime);
		require(_betLastTime+ 1 days < bankerEndTime);

        _result = _newGame(_team1, _team2, _loseOdd, _winOdd, _sameOdd, _betLastTime, _gameMinBetAmount,  _gameMaxBetAmount);
    }

    function _newGame(string _team1, string _team2, uint _loseOdd, uint _winOdd, uint _sameOdd, uint _betLastTime, uint256 _gameMinBetAmount, uint256 _gameMaxBetAmount) private  returns(bool _result){
        _result = false;
		gameID = gameID.add(1);
		
		team1 = _team1;
        team2 = _team2;
		loseOdd = _loseOdd;
		winOdd = _winOdd;
		sameOdd = _sameOdd;
		emit OnGameInfo(gameID, team1, team2, loseOdd, winOdd, sameOdd, now, getEventId());
		
		betLastTime = _betLastTime;
        gameBeginTime = now;
		gameMinBetAmount = _gameMinBetAmount;
        gameMaxBetAmount = _gameMaxBetAmount;
		emit OnNewGame(gameID, msg.sender, betLastTime,  gameBeginTime, gameMinBetAmount,   gameMaxBetAmount, now, getEventId());
        
        gameBeginPlayNo = playNo;
        gameResult = 9;
        gameOver = false;
		unpayPooling = 0;
		losePooling = 0;
		winPooling = 0;
		samePooling = 0;

        _result = true;
    }
	
    event OnSetOdd(uint indexed _gameID, uint _winOdd, uint _loseOdd, uint _sameOdd, uint _eventTime, uint eventId);
	function setOdd(uint _winOdd, uint _loseOdd, uint _sameOdd) onlyBanker public{		
		winOdd = _winOdd;
		loseOdd = _loseOdd;
		sameOdd = _sameOdd;	
		emit OnSetOdd(gameID, winOdd, loseOdd, sameOdd, now, getEventId());
	}

    struct betInfo
    {
        uint Odd;
        address Player;
        uint BetNum;
        uint256 BetAmount;
		uint loseToken;
        bool IsReturnAward;
    }

    mapping (uint => betInfo) public playerBetInfoOf;

    event OnPlay(uint indexed _gameID, string _gameName, address _player, uint odd, string _team1, uint _betNum, uint256 _betAmount, uint _playNo, uint _eventTime, uint eventId);
    function play(uint _betNum, uint256 _betAmount) public returns(bool _result){ 
        _result = _play(_betNum, _betAmount);
    }

    function _play(uint _betNum, uint256 _betAmount) private  returns(bool _result){
        _result = false;
        require(!gameOver);

        require(_betNum == loseNum || _betNum == winNum || _betNum == sameNum);
        require(msg.sender != currentBanker);

        require(now < betLastTime);
		
		require(_betAmount >= gameMinBetAmount);
        if (_betAmount > gameMaxBetAmount){
            _betAmount = gameMaxBetAmount;
        }

		_betAmount = _betAmount / 100 * 100;

        if(userTokenOf[msg.sender] < _betAmount){
            depositToken(_betAmount.sub(userTokenOf[msg.sender]));
        }
        
        uint BankerAmount = _betAmount.mul(bankerDepositPer).div(100);
        require(userTokenOf[msg.sender] >= _betAmount);
        require(userTokenOf[currentBanker] >= BankerAmount);


        uint _odd = seekOdd(_betNum,_betAmount);

        betInfo memory bi= betInfo({
            Odd :_odd,
            Player :  msg.sender,
            BetNum : _betNum,
            BetAmount : _betAmount,
            loseToken : 0,
            IsReturnAward: false
        });

        playerBetInfoOf[playNo] = bi;
        userTokenOf[msg.sender] = userTokenOf[msg.sender].sub(_betAmount);
		userTokenOf[this] = userTokenOf[this].add(_betAmount);
        userTokenOf[currentBanker] = userTokenOf[currentBanker].sub(BankerAmount);
		userTokenOf[this] = userTokenOf[this].add(BankerAmount);
        emit OnPlay(gameID, gameName, msg.sender, _odd, team1, _betNum, _betAmount, playNo, now, getEventId());

        playNo = playNo.add(1); 
		if(now < donGameGiftLineTime){
            DonQuixoteToken.logPlaying(msg.sender);
        }
		
        _result = true;
    }
	
	function seekOdd(uint _betNum, uint _betAmount) private returns (uint _odd){
		uint allAmount = 0;
		if(_betNum == 3){
			allAmount = _betAmount.mul(winOdd).div(100);//allAmount = _betAmount*winOdd/100
			winPooling = winPooling.add(allAmount);
			_odd  = winOdd;
		}else if(_betNum == 1){
			allAmount = _betAmount.mul(loseOdd).div(100);//allAmount = _betAmount*loseOdd/100
			losePooling = losePooling.add(allAmount);
			_odd = loseOdd;
		}else if(_betNum == 0){
			allAmount = _betAmount.mul(sameOdd).div(100);//allAmount = _betAmount*sameOdd/100
			samePooling = samePooling.add(allAmount);
			_odd = sameOdd;
		}
    }
	
    event OnOpenGameResult(uint indexed _gameID,uint indexed _palyNo, address _player, uint _gameResult, uint _eventTime, uint eventId);
    function openGameLoop() public returns(bool _result){
		lock();
        _result =  _openGameLoop();
        unLock();
    }

    function _openGameLoop() private returns(bool _result){
        _result = false;
        _checkOpenGame();
		uint256 allAmount = 0;
		for(uint i = 0; nextRewardPlayNo < playNo && i < currentRewardNum; i++ ){
			betInfo storage p = playerBetInfoOf[nextRewardPlayNo];
			if(!p.IsReturnAward){
				_cashPrize(p, allAmount,nextRewardPlayNo);
			}
			nextRewardPlayNo = nextRewardPlayNo.add(1);
		}
		if(unpayPooling == 0 && _canSetGameOver()){
			userTokenOf[currentBanker] = userTokenOf[currentBanker].add(userTokenOf[this]);
			userTokenOf[this] = 0;
			gameOver = true;
		}
		_result = true;
    }
	
	function openGamePlayNo(uint _playNo) public returns(bool _result){
		lock();
        _result =  _openGamePlayNo(_playNo);
        unLock();
    }
	
    function _openGamePlayNo(uint _playNo) private returns(bool _result){
        _result = false;
		require(_playNo >= gameBeginPlayNo && _playNo < playNo);
		_checkOpenGame();
		
		betInfo storage p = playerBetInfoOf[_playNo];
		require(!p.IsReturnAward);
		
		uint256 allAmount = 0;
		_cashPrize(p, allAmount,_playNo);
		
		if(unpayPooling == 0 && _canSetGameOver()){
			userTokenOf[currentBanker] = userTokenOf[currentBanker].add(userTokenOf[this]);
			userTokenOf[this] = 0;
			gameOver = true;
		}
		_result = true;
    }
	
	function openGamePlayNos(uint[] _playNos) public returns(bool _result){
		lock();
        _result =  _openGamePlayNos(_playNos);
        unLock();
    }
	
    function _openGamePlayNos(uint[] _playNos) private returns(bool _result){
        _result = false;
        _checkOpenGame();
		uint256 allAmount = 0;
		for (uint _index = 0; _index < _playNos.length; _index++) {
			uint _playNo = _playNos[_index];
			if(_playNo >= gameBeginPlayNo && _playNo < playNo){
				betInfo storage p = playerBetInfoOf[_playNo];
				if(!p.IsReturnAward){
					_cashPrize(p, allAmount,_playNo);
				}
			}
		}
		
		if(unpayPooling == 0 && _canSetGameOver()){
			userTokenOf[currentBanker] = userTokenOf[currentBanker].add(userTokenOf[this]);
			userTokenOf[this] = 0;
			gameOver = true;
		}
		_result = true;
    }
	
	function openGameRange(uint _beginPlayNo, uint _endPlayNo) public returns(bool _result){
		lock();
        _result =  _openGameRange(_beginPlayNo, _endPlayNo);
        unLock();
    }
	
    function _openGameRange(uint _beginPlayNo, uint _endPlayNo) private returns(bool _result){
        _result = false;
		require(_beginPlayNo < _endPlayNo);
		require(_beginPlayNo >= gameBeginPlayNo && _endPlayNo < playNo);
		
		_checkOpenGame();
		uint256 allAmount = 0;
		for (uint _indexPlayNo = _beginPlayNo; _indexPlayNo <= _endPlayNo; _indexPlayNo++) {
			betInfo storage p = playerBetInfoOf[_indexPlayNo];
			if(!p.IsReturnAward){
				_cashPrize(p, allAmount,_indexPlayNo);
			}
		}
		if(unpayPooling == 0 && _canSetGameOver()){
			userTokenOf[currentBanker] = userTokenOf[currentBanker].add(userTokenOf[this]);
			userTokenOf[this] = 0;
			gameOver = true;
		}
		_result = true;
    }
	
	function _checkOpenGame() private{
		require(!gameOver);
		require( gameResult == loseNum || gameResult == winNum || gameResult == sameNum);
		require(betLastTime + 90 minutes < now);
		
		if(unpayPooling > userTokenOf[this]){
			uint shortOf = unpayPooling.sub(userTokenOf[this]);
			if(shortOf > userTokenOf[currentBanker]){
				shortOf = userTokenOf[currentBanker];
			}
			userTokenOf[currentBanker] = userTokenOf[currentBanker].sub(shortOf);
			userTokenOf[this] = userTokenOf[this].add(shortOf);
		}
	}
	
	function _cashPrize(betInfo storage _p, uint256 _allAmount,uint _playNo) private{
		if(_p.BetNum == gameResult){
			_allAmount = _p.BetAmount.mul(_p.Odd).div(100);
			_allAmount = _allAmount.sub(_p.loseToken);
			if(userTokenOf[this] >= _allAmount){
				_p.IsReturnAward = true;
				userTokenOf[_p.Player] = userTokenOf[_p.Player].add(_allAmount);
				userTokenOf[this] = userTokenOf[this].sub(_allAmount);
				unpayPooling = unpayPooling.sub(_allAmount);
				emit OnOpenGameResult(gameID,_playNo, msg.sender, gameResult, now, getEventId());
				if(_p.BetNum == 3){
					winPooling = winPooling.sub(_allAmount);
				}else if(_p.BetNum == 1){
					losePooling = losePooling.sub(_allAmount);
				}else if(_p.BetNum == 0){
					samePooling = samePooling.sub(_allAmount);
				}
			}else{
				_p.loseToken = _p.loseToken.add(userTokenOf[this]);
				userTokenOf[_p.Player] = userTokenOf[_p.Player].add(userTokenOf[this]);
				unpayPooling = unpayPooling.sub(userTokenOf[this]);
				if(_p.BetNum == 3){
					winPooling = winPooling.sub(userTokenOf[this]);
				}else if(_p.BetNum == 1){
					losePooling = losePooling.sub(userTokenOf[this]);
				}else if(_p.BetNum == 0){
					samePooling = samePooling.sub(userTokenOf[this]);
				}
				
				userTokenOf[this] = 0;
			}
		}else{
			_p.IsReturnAward = true;
			emit OnOpenGameResult(gameID,_playNo, msg.sender, gameResult, now, getEventId());
			_allAmount = _p.BetAmount.mul(_p.Odd).div(100);
			//_allAmount = _allAmount.sub(_p.loseToken);
			if(_p.BetNum == 3){
				winPooling = winPooling.sub(_allAmount);
			}else if(_p.BetNum == 1){
				losePooling = losePooling.sub(_allAmount);
			}else if(_p.BetNum == 0){
				samePooling = samePooling.sub(_allAmount);
			}
			
			if(now < donGameGiftLineTime){
				DonQuixoteToken.sendGameGift(_p.Player);
			}
		}
	}
	

	function _canSetGameOver() private view returns(bool){
		return winPooling<100 && losePooling<100 && samePooling<100;//todo
	}
	
    function _withdrawToken(address _from, uint256 _amount) internal {
        require(_from != 0x0);
		require(_from != currentBanker || gameOver);
		if(_amount > 0 && _amount <= userTokenOf[_from]){  
			userTokenOf[_from] = userTokenOf[_from].sub(_amount);
			DonQuixoteToken.transfer(_from, _amount);
		}
    }
	
	
	function transEther() public onlyOwner()
    {
        msg.sender.transfer(address(this).balance);
    }
	
	function () public payable {        //fall back function
    }

}