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
    uint256 c = a / b;
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
    uint public gameType = 1004;
    string public officialGameUrl;

    function userRefund() public  returns(bool _result);
	
	uint public bankerBeginTime;
	uint public bankerEndTime;
	address public currentBanker;
	
	mapping (address => uint256) public userEtherOf;
}


contract Base is BaseGame{
	using SafeMath for uint256;
    uint public createTime = now;
    address public owner;
	function Base() public {
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function setOwner(address _newOwner)  public  onlyOwner {
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

    function userRefund() public  returns(bool _result) {
        return _userRefund(msg.sender);
    }

    function _userRefund(address _to) internal returns(bool _result) {
        require (_to != 0x0);
        lock();
        uint256 amount = userEtherOf[msg.sender];
        if(amount > 0){
            userEtherOf[msg.sender] = 0;
            _to.transfer(amount);
            _result = true;
        }
        else{
            _result = false;
        }
        unLock();
    }
	
	uint public currentEventId = 1;

    function getEventId() internal returns(uint _result) {
        _result = currentEventId;
        currentEventId++;
    }
	
	string public officialGameUrl;
    function setOfficialGameUrl(string _newOfficialGameUrl) public onlyOwner{
        officialGameUrl = _newOfficialGameUrl;
    }
}

contract SoccerBet is Base
{
	function SoccerBet(string _gameName) public {
		gameName = _gameName;
        owner = msg.sender;
    }
	
	uint public unpayPooling = 0;
	uint public losePooling = 0;
	uint public winPooling = 0;
	uint public samePooling = 0;
	uint public bankerAllDeposit = 0;
	
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
		if(userEtherOf[this] == 0){
			_result = true;
		}
    }
	
	event OnSetNewBanker(uint indexed _gameID, address _caller, address _banker, uint _beginTime, uint _endTime, uint _errInfo, uint _eventTime, uint eventId);

    function setBanker(address _banker, uint _beginTime, uint _endTime) public onlyAuction returns(bool _result)
    {
        _result = false;
        require(_banker != 0x0);

        if(now < bankerEndTime){
            emit OnSetNewBanker(gameID, msg.sender, _banker,  _beginTime,  _endTime, 1, now, getEventId());
            return;
        }
		
		if(userEtherOf[this] > 0){
			emit OnSetNewBanker(gameID, msg.sender, _banker,  _beginTime,  _endTime, 5, now, getEventId());
			return;
		}
        
        if(_beginTime > now){
			emit OnSetNewBanker(gameID, msg.sender, _banker,  _beginTime,  _endTime, 3, now, getEventId());
            return;
        }

        if(_endTime <= now){
			emit OnSetNewBanker(gameID, msg.sender, _banker,  _beginTime,  _endTime, 4, now, getEventId());
            return;
        }

        currentBanker = _banker;
        bankerBeginTime = _beginTime;
        bankerEndTime =  _endTime;
		
		unpayPooling = 0;
		losePooling = 0;
		winPooling = 0;
		samePooling = 0;
		
		bankerAllDeposit = 0;
		
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
		require(now < betLastTime + 30 days);
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
	
    function newGame(string _team1, string _team2, uint _loseOdd, uint _winOdd, uint _sameOdd,  uint _betLastTime, uint256 _gameMinBetAmount, uint256 _gameMaxBetAmount) public onlyBanker payable returns(bool _result){
        if (msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }

        require(bytes(_team1).length < 100);
		require(bytes(_team2).length < 100);
		
		require(gameOver);
        require(now > bankerBeginTime);
        require(_gameMinBetAmount >= 100000000000000);
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
		
		bankerAllDeposit = 0;
		
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
		uint BetTime;
        bool IsReturnAward;
		uint ResultNO;
    }

    mapping (uint => betInfo) public playerBetInfoOf;

    event OnPlay( uint indexed _gameID, uint indexed _playNo, address indexed _player, string _gameName, uint odd, string _team1, uint _betNum, uint256 _betAmount,  uint _eventTime, uint eventId);
    function play(uint _betNum, uint256 _betAmount) public payable  returns(bool _result){
        if (msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }
		_result = _play(_betNum, _betAmount);
    }

    function _play(uint _betNum, uint256 _betAmount) private  returns(bool _result){
        _result = false;
        require(!gameOver);
      
        require( loseNum == _betNum || _betNum == winNum || _betNum == sameNum);
        require(msg.sender != currentBanker);

        require(now < betLastTime);
		
		require(_betAmount >= gameMinBetAmount);
        if (_betAmount > gameMaxBetAmount){
            _betAmount = gameMaxBetAmount;
        }
		
		_betAmount = _betAmount / 100 * 100;
		
		uint _odd = _seekOdd(_betNum, _betAmount);
		
        require(userEtherOf[msg.sender] >= _betAmount);

        betInfo memory bi= betInfo({
            Odd :_odd,
            Player :  msg.sender,
            BetNum : _betNum,
            BetAmount : _betAmount,
			BetTime : now,
            IsReturnAward: false,
			ResultNO: 9
        });

         playerBetInfoOf[playNo] = bi;
        userEtherOf[msg.sender] = userEtherOf[msg.sender].sub(_betAmount); 
		userEtherOf[this] = userEtherOf[this].add(_betAmount);
		
		uint _maxpooling = _getMaxPooling();
		if(userEtherOf[this] < _maxpooling){
			uint BankerAmount = _maxpooling.sub(userEtherOf[this]);
			require(userEtherOf[currentBanker] >= BankerAmount);
			userEtherOf[currentBanker] = userEtherOf[currentBanker].sub(BankerAmount);
			userEtherOf[this] = userEtherOf[this].add(BankerAmount);
			bankerAllDeposit = bankerAllDeposit.add(BankerAmount);
		}
		
        emit OnPlay(gameID, playNo, msg.sender, gameName, _odd, team1, _betNum, _betAmount, now, getEventId());

        playNo = playNo.add(1);
        _result = true;
    }
	
	function _seekOdd(uint _betNum, uint _betAmount) private returns (uint _odd){
		uint allAmount = 0;
		if(_betNum == 3){
			allAmount = _betAmount.mul(winOdd).div(100);
			winPooling = winPooling.add(allAmount);
			_odd  = winOdd;
		}else if(_betNum == 1){
			allAmount = _betAmount.mul(loseOdd).div(100);
			losePooling = losePooling.add(allAmount);
			_odd = loseOdd;
		}else if(_betNum == 0){
			allAmount = _betAmount.mul(sameOdd).div(100);
			samePooling = samePooling.add(allAmount);
			_odd = sameOdd;
		}
    }
	
	function _getMaxPooling() private view returns(uint maxpooling){
		maxpooling = winPooling;
		if(maxpooling < losePooling){
			maxpooling = losePooling;
		}
		if(maxpooling < samePooling){
			maxpooling = samePooling;
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
		
		_setGameOver();
		
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
		
		_setGameOver();
		
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
		
		_setGameOver();
		
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
		_setGameOver();
		_result = true;
    }
	
	function _checkOpenGame() private view{
		require(!gameOver);
		require( gameResult == loseNum || gameResult == winNum || gameResult == sameNum);
		require(betLastTime + 90 minutes < now);
	}
	
	function _cashPrize(betInfo storage _p, uint256 _allAmount,uint _playNo) private{
		if(_p.BetNum == gameResult){
			_allAmount = _p.BetAmount.mul(_p.Odd).div(100);
			
			_p.IsReturnAward = true;
			_p.ResultNO = gameResult;
			userEtherOf[this] = userEtherOf[this].sub(_allAmount);
			unpayPooling = unpayPooling.sub(_allAmount);
			userEtherOf[_p.Player] = userEtherOf[_p.Player].add(_allAmount);
			emit OnOpenGameResult(gameID,_playNo, msg.sender, gameResult, now, getEventId());
			
			if(_p.BetNum == 3){
				winPooling = winPooling.sub(_allAmount);
			}else if(_p.BetNum == 1){
				losePooling = losePooling.sub(_allAmount);
			}else if(_p.BetNum == 0){
				samePooling = samePooling.sub(_allAmount);
			}
			
		}else{
			_p.IsReturnAward = true;
			_p.ResultNO = gameResult;
			emit OnOpenGameResult(gameID,_playNo, msg.sender, gameResult, now, getEventId());
			
			_allAmount = _p.BetAmount.mul(_p.Odd).div(100);
			if(_p.BetNum == 3){
				winPooling = winPooling.sub(_allAmount);
			}else if(_p.BetNum == 1){
				losePooling = losePooling.sub(_allAmount);
			}else if(_p.BetNum == 0){
				samePooling = samePooling.sub(_allAmount);
			}
		}
	}
	
	function _setGameOver() private{
		if(unpayPooling == 0 && _canSetGameOver()){
			userEtherOf[currentBanker] = userEtherOf[currentBanker].add(userEtherOf[this]);
			userEtherOf[this] = 0;
			gameOver = true;
		}
	}
	
	function _canSetGameOver() private view returns(bool){
		return winPooling<100 && losePooling<100 && samePooling<100;
	}
	
	function failUserRefund(uint[] _playNos) public returns (bool _result) {
        _result = false;
        require(!gameOver);
		require(gameResult == 9);
        require(betLastTime + 31 days < now);
		for (uint _index = 0; _index < _playNos.length; _index++) {
			uint _playNo = _playNos[_index];
			if(_playNo >= gameBeginPlayNo && _playNo < playNo){
				betInfo storage p = playerBetInfoOf[_playNo];
				if(!p.IsReturnAward){
					p.IsReturnAward = true;
					uint256 ToUser = p.BetAmount;
					userEtherOf[this] = userEtherOf[this].sub(ToUser);
					userEtherOf[p.Player] =  userEtherOf[p.Player].add(ToUser);
				}
			}
		}
		if(msg.sender == currentBanker && bankerAllDeposit>0){
			userEtherOf[this] = userEtherOf[this].sub(bankerAllDeposit);
			userEtherOf[currentBanker] =  userEtherOf[currentBanker].add(bankerAllDeposit);
			bankerAllDeposit = 0;
		}
		if(userEtherOf[this] == 0){
			gameOver = true;
		}
		_result = true;
    }

	
	event OnRefund(uint indexed _gameId, address _to, uint _amount, bool _result, uint _eventTime, uint eventId);
	function _userRefund(address _to) internal  returns(bool _result){
		require (_to != 0x0);
		require(_to != currentBanker || gameOver);
		lock();
		uint256 amount = userEtherOf[_to];
		if(amount > 0){
			userEtherOf[msg.sender] = 0;
			_to.transfer(amount);
			_result = true;
		}else{
			_result = false;
		}
		
		emit OnRefund(gameID, _to, amount, _result, now, getEventId());
		unLock();                                                                            
    }
	
	function playEtherOf() public payable {
        if (msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);                  
        }
    }
	
	function () public payable {
        if(msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
			
        }
    }

}