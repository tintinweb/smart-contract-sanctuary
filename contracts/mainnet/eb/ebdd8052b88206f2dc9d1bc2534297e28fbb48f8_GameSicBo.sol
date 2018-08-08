pragma solidity ^0.4.21;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract BaseGame {
    using SafeMath for uint256;
    string public officialGameUrl;
    string public gameName = "GameSicBo";
    uint public gameType = 1003;

    mapping (address => uint256) public userEtherOf;
    function userRefund() public  returns(bool _result);

    address public currentBanker;
    uint public bankerBeginTime;
    uint public bankerEndTime;

    function canSetBanker() view public returns (bool _result);
    function setBanker(address _banker, uint256 _beginTime, uint256 _endTime) public returns(bool _result);
}

contract Base is  BaseGame{
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
        currentEventId ++;
    }

    function setOfficialGameUrl(string _newOfficialGameUrl) public onlyOwner{
        officialGameUrl = _newOfficialGameUrl;
    }
}

contract GameSicBo is Base
{
    uint public lastBlockNumber = 0;

    uint public gameID = 0;
    uint  public gameBeginTime;
    uint  public gameEndTime;
    uint public gameTime;
    uint256 public gameMaxBetAmount;
    uint256 public gameMinBetAmount;
    bool public gameOver = true;
    bytes32 public gameEncryptedText;
    uint public gameResult;
    string public gameRandon1;
    string public constant gameRandon2 = &#39;ChinasNewGovernmentBracesforTrump&#39;;
    bool public betInfoIsLocked = false;

    uint public playNo = 1;
    uint public gameBeginPlayNo;
    uint public gameEndPlayNo;
    uint public nextRewardPlayNo;
    uint public currentRewardNum = 100;
    

    function GameSicBo(string _gameName,uint  _gameTime, uint256 _gameMinBetAmount, uint256 _gameMaxBetAmount)  public {
        require(_gameTime > 0);
        require(_gameMinBetAmount > 0);
        require(_gameMaxBetAmount > 0);
        require(_gameMaxBetAmount >= _gameMinBetAmount);

        gameMinBetAmount = _gameMinBetAmount;
        gameMaxBetAmount = _gameMaxBetAmount;
        gameTime = _gameTime;
        gameName = _gameName;
        owner = msg.sender;
    }

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
        _result =  bankerEndTime <= now && gameOver;
    }

    event OnSetNewBanker(address _caller, address _banker, uint _beginTime, uint _endTime, uint _code,uint _eventId,uint _time);
    function setBanker(address _banker, uint _beginTime, uint _endTime) public onlyAuction returns(bool _result)        
    {
        _result = false;
        require(_banker != 0x0);

        if(now < bankerEndTime){
            emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 1 ,getEventId(),now);
            return;
        }

        if(!gameOver){
            emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 2 ,getEventId(),now);
            return;
        }

        if(_beginTime > now){
            emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 3 ,getEventId(),now);
            return;
        }

        if(_endTime <= now){
            emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 4 ,getEventId(),now);
            return;
        }

        currentBanker = _banker;
        bankerBeginTime = _beginTime;
        bankerEndTime = _endTime;

        emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 0, getEventId(),now);
        _result = true;
    }


    function setCurrentRewardNum(uint _currentRewardNum) public onlyBanker{
        currentRewardNum = _currentRewardNum ;
    }

    event OnNewGame(uint _gameID, address _banker, bytes32 _gameEncryptedText, uint  _gameBeginTime,  uint  _gameEndTime, uint _eventId,uint _time);

    function newGame(bytes32 _gameEncryptedText) public onlyBanker payable returns(bool _result)
    {
        if (msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }
        _result = _newGame( _gameEncryptedText);
    }

    function _newGame(bytes32 _gameEncryptedText)   private  returns(bool _result)
    {
        _result = false;
        require(gameOver);
        require(now > bankerBeginTime);
        require(now + gameTime <= bankerEndTime);

        gameID++;
        gameEncryptedText = _gameEncryptedText;
        gameRandon1 = &#39;&#39;;
        gameBeginTime = now;
        gameEndTime =  now + gameTime;
        gameBeginPlayNo = playNo;
        nextRewardPlayNo = playNo;
        gameEndPlayNo = 0;
        gameResult = 0;
        gameOver = false;

        emit OnNewGame(gameID, msg.sender, _gameEncryptedText, now,gameEndTime,getEventId(),now);
        _result = true;
    }

    struct betInfo
    {
        address Player;
        uint BetType;
        uint256 BetAmount;
        uint Odds;
        uint SmallNum;
        uint BigNum;
        bool IsReturnAward;
        bool IsWin ;
        uint BetTime;
    }

    mapping (uint => betInfo) public playerBetInfoOf;

    event OnPlay(address indexed _player,uint indexed _gameID, uint indexed _playNo, uint _eventId,uint _time, uint _smallNum,uint _bigNum, uint256 _betAmount, uint _betType);

    function playEtherOf() public payable {
        if (msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }
    }

    function _play(uint _smallNum,uint _bigNum,  uint256 _betAmount, uint _odds,uint _betType) private  returns(bool _result){
        _result = false;

        require(userEtherOf[msg.sender] >= _betAmount);
        uint bankerAmount = _betAmount.mul(_odds);
        require(userEtherOf[currentBanker] >= bankerAmount);

        if(gameBeginPlayNo == playNo){
            if(now >= gameEndTime){
                require(gameTime.add(now) <= bankerEndTime); 
                gameBeginTime = now;
                gameEndTime = gameTime.add(now);                
            }
        }

        require(now < gameEndTime);

        betInfo memory bi = betInfo({
            Player :  msg.sender,
            SmallNum : _smallNum,
            BigNum : _bigNum,
            BetAmount : _betAmount,
            BetType : _betType,
            Odds : _odds,
            IsReturnAward: false,
            IsWin :  false ,
            BetTime : now
            });
        playerBetInfoOf[playNo] = bi;
        userEtherOf[msg.sender] = userEtherOf[msg.sender].sub(_betAmount);
        userEtherOf[this] = userEtherOf[this].add(_betAmount);
        userEtherOf[currentBanker] = userEtherOf[currentBanker].sub(bankerAmount);
        userEtherOf[this] = userEtherOf[this].add(bankerAmount);

        emit OnPlay(msg.sender, gameID, playNo ,getEventId(), now, _smallNum,_bigNum,  _betAmount, _betType);

        lastBlockNumber = block.number;
        playNo++;
        _result = true;
    }

    modifier playable(uint betAmount) {
        require(!gameOver);
        require(!betInfoIsLocked);
        require(msg.sender != currentBanker);
        require(betAmount >= gameMinBetAmount);
        _;
    }   

    function playBatch(uint[] _betNums,uint256[] _betAmounts) public payable returns(bool _result){
        _result = false;
        require(!gameOver);
        require(!betInfoIsLocked);
        require(msg.sender != currentBanker);

        playEtherOf();
        require(_betNums.length == _betAmounts.length);
        require (_betNums.length <= 10);
        _result = true ; 
        for(uint i = 0; i < _betNums.length && _result ; i++ ){
            uint _betNum = _betNums[i];
            uint256 _betAmount = _betAmounts[i];
            if(_betAmount < gameMinBetAmount){
                continue ;
            }
            if (_betAmount > gameMaxBetAmount){
                _betAmount = gameMaxBetAmount;
            }
            if(_betNum > 0 && _betNum <= 2){
                _result = _play(_betNum,0, _betAmount,1,1);
            }else if(_betNum == 3){
                _result = _play(0,0, _betAmount,24,2);
            }else if(_betNum <= 9){
                _result = _play(_betNum.sub(3),0, _betAmount,150,3);
            }else if(_betNum <= 15){
                _play(_betNum.sub(9),0, _betAmount,150,3);
            }else if(_betNum <= 29){
                    uint _odds = 0;
                    _betNum = _betNum.sub(12);
                    if(_betNum == 4 || _betNum == 17){
                        _odds = 50;
                    }else if(_betNum == 5 || _betNum == 16){
                        _odds = 18;
                    }else if(_betNum == 6 || _betNum == 15){
                        _odds = 14;
                    }else if(_betNum == 7 || _betNum == 14){
                        _odds = 12;
                    }else if(_betNum == 8 || _betNum == 13){
                        _odds = 8;
                    }else{
                        _odds = 6;
                    }
                _result = _play(_betNum,0, _betAmount,_odds,5);
            }else if(_betNum <= 44){
                if(_betNum <= 34){
                    uint _betMinNum = 1;
                    uint _betMaxNum = _betNum.sub(28);
                }else if(_betNum <= 38){
                    _betMinNum = 2;
                    _betMaxNum = _betNum.sub(32);
                }else if(_betNum <= 41){
                    _betMinNum = 3;
                    _betMaxNum = _betNum.sub(35);
                }else if(_betNum <= 43){
                    _betMinNum = 4;
                    _betMaxNum = _betNum.sub(37);
                }else{
                    _betMinNum = 5;
                    _betMaxNum = 6;
                }
                _result = _play(_betMinNum,_betMaxNum, _betAmount,5,6);
            }else if(_betNum <= 50){
                _result = _play(_betNum.sub(44),0, _betAmount,3,7);
            }
        }
        _result = true;
    }

    function playBigOrSmall(uint _betNum, uint256 _betAmount) public payable playable(_betAmount) returns(bool _result){
        playEtherOf();
        require(_betNum ==1 || _betNum == 2);
        if (_betAmount > gameMaxBetAmount){
            _betAmount = gameMaxBetAmount;
        }
        _result = _play(_betNum,0, _betAmount,1,1);
    }

    function playAnyTriples(uint256 _betAmount) public payable  playable(_betAmount)  returns(bool _result){
        playEtherOf();
        if (_betAmount > gameMaxBetAmount){
            _betAmount = gameMaxBetAmount;
        }
        _result = _play(0,0, _betAmount,24,2);
    }

    function playSpecificTriples(uint _betNum, uint256 _betAmount) public payable playable(_betAmount)  returns(bool _result){
        playEtherOf();
        require(_betNum >= 1 && _betNum <=6);
        if (_betAmount > gameMaxBetAmount){
            _betAmount = gameMaxBetAmount;
        }
        _result = _play(_betNum,0, _betAmount,150,3);
    }

    function playSpecificDoubles(uint _betNum, uint256 _betAmount) public payable playable(_betAmount)  returns(bool _result){
        playEtherOf();
        require(_betNum >= 1 && _betNum <=6);
        if (_betAmount > gameMaxBetAmount){
            _betAmount = gameMaxBetAmount;
        }
        _result = _play(_betNum,0, _betAmount,8,4);
    }

    function playThreeDiceTotal(uint _betNum,uint256 _betAmount) public payable  playable(_betAmount)  returns(bool _result){
        playEtherOf();
        require(_betNum >= 4 && _betNum <=17);
        if (_betAmount > gameMaxBetAmount){
            _betAmount = gameMaxBetAmount;
        }
        uint _odds = 0;
        if(_betNum == 4 || _betNum == 17){
            _odds = 50;
        }else if(_betNum == 5 || _betNum == 16){
            _odds = 18;
        }else if(_betNum == 6 || _betNum == 15){
            _odds = 14;
        }else if(_betNum == 7 || _betNum == 14){
            _odds = 12;
        }else if(_betNum == 8 || _betNum == 13){
            _odds = 8;
        }else{
            _odds = 6;
        }
        _result = _play(_betNum,0, _betAmount,_odds,5);
    }

    function playDiceCombinations(uint _smallNum,uint _bigNum,uint256 _betAmount) public payable playable(_betAmount)  returns(bool _result){
        playEtherOf();
        require(_smallNum < _bigNum);
        require(_smallNum >= 1 && _smallNum <=5);
        require(_bigNum >= 2 && _bigNum <=6);
        if (_betAmount > gameMaxBetAmount){
            _betAmount = gameMaxBetAmount;
        }
        _result = _play(_smallNum,_bigNum, _betAmount,5,6);
    }

    function playSingleDiceBet(uint _betNum,uint256 _betAmount) public payable playable(_betAmount)  returns(bool _result){
        playEtherOf();
        require(_betNum >= 1 && _betNum <=6);
        if (_betAmount > gameMaxBetAmount){
            _betAmount = gameMaxBetAmount;
        }
        _result = _play(_betNum,0, _betAmount,3,7);
    }

    function lockBetInfo() public onlyBanker returns (bool _result) {
        require(!gameOver);
        require(now < gameEndTime);
        require(!betInfoIsLocked);
        betInfoIsLocked = true;
        _result = true;
    }

    function uintToString(uint v) private pure returns (string) {
        uint maxlength = 3;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        string memory str = string(s);
        return str;
    }


    event OnOpenGameResult(uint indexed _gameID, bool indexed _result, string _remark, address _banker,uint _gameResult, string _r1,uint _eventId,uint _time);

    function openGameResult(uint _minGameResult,uint _midGameResult,uint _maxGameResult, string _r1) public onlyBanker  returns(bool _result){
        _result =  _openGameResult( _minGameResult,_midGameResult,_maxGameResult,_r1);
    }

    function _playRealOdds(uint _betType,uint _odds,uint _smallNuml,uint _bigNum,uint _minGameResult,uint _midGameResult,uint _maxGameResult) private  pure returns(uint _realOdds){
        _realOdds = 0;
        if(_betType == 1){
            bool _isAnyTriple = (_minGameResult == _midGameResult && _midGameResult == _maxGameResult);
            if(_isAnyTriple){
                return 0;
            }
            uint _threeDiceTotal = _minGameResult.add(_midGameResult).add(_maxGameResult);
            uint _bigOrSmall = _threeDiceTotal >= 11 ? 2 : 1 ;
            if(_bigOrSmall == _smallNuml){
                _realOdds = _odds;
            }
        }else if(_betType == 2){
            _isAnyTriple = (_minGameResult == _midGameResult && _midGameResult == _maxGameResult);
            if(_isAnyTriple){
                _realOdds = _odds;
            }
        }else if(_betType == 3){
            _isAnyTriple = (_minGameResult == _midGameResult && _midGameResult == _maxGameResult);
            uint _specificTriple  = (_isAnyTriple) ? _minGameResult : 0 ;
            if( _specificTriple == _smallNuml){
                _realOdds = _odds;
            }
        }else if(_betType == 4){
            uint _doubleTriple = (_minGameResult == _midGameResult) ? _minGameResult : ((_midGameResult == _maxGameResult)? _maxGameResult: 0);
            if(_doubleTriple == _smallNuml){
                _realOdds = _odds;
            }
        }else if(_betType == 5){
            _threeDiceTotal = _minGameResult + _midGameResult + _maxGameResult ;
            if(_threeDiceTotal == _smallNuml){
                _realOdds = _odds;
            }
        }else  if(_betType == 6){
            if(_smallNuml == _minGameResult || _smallNuml == _midGameResult){
                if(_bigNum == _midGameResult || _bigNum == _maxGameResult){
                    _realOdds = _odds;
                }
            }
        }else if(_betType == 7){
            if(_smallNuml == _minGameResult){
                _realOdds++;
            }
            if(_smallNuml == _midGameResult){
                _realOdds++;
            }
            if(_smallNuml == _maxGameResult){
                _realOdds++;
            }

        }
    }


    function _openGameResult(uint _minGameResult,uint _midGameResult, uint _maxGameResult, string _r1) private  returns(bool _result){
        _result = false;
        require(betInfoIsLocked);
        require(!gameOver);
        require(now <= gameEndTime);
        require(_minGameResult <= _midGameResult);
        require(_midGameResult <= _maxGameResult);
        require (_minGameResult >= 1 && _maxGameResult <= 6);

        uint _gameResult = _minGameResult*100 + _midGameResult*10 + _maxGameResult;
        if(lastBlockNumber == block.number){
            emit OnOpenGameResult(gameID,  false, &#39;block.number is equal&#39;, msg.sender, _gameResult, _r1,getEventId(),now);
            return;
        }
        if(keccak256(uintToString(_gameResult) , gameRandon2 , _r1) ==  gameEncryptedText){
            if(_minGameResult >= 1 && _minGameResult <= 6 && _midGameResult>=1 && _midGameResult<=6 && _maxGameResult>=1 && _maxGameResult<=6){
                gameResult = _gameResult ;
                gameRandon1 = _r1;
                gameEndPlayNo = playNo - 1;

                for(uint i = 0; nextRewardPlayNo < playNo && i < currentRewardNum; i++ ){
                    betInfo  storage p = playerBetInfoOf[nextRewardPlayNo];
                    if(!p.IsReturnAward){
                        p.IsReturnAward = true;
                        uint realOdd = _playRealOdds(p.BetType,p.Odds,p.SmallNum,p.BigNum,_minGameResult,_midGameResult,_maxGameResult);
                        p.IsWin =_calResultReturnIsWin(nextRewardPlayNo,realOdd);
                        if(p.IsWin){
                            p.Odds = realOdd;
                        }
                    }
                    nextRewardPlayNo++;
                }
                if(nextRewardPlayNo == playNo){
                    gameOver = true;
                    betInfoIsLocked = false;
                }

                emit OnOpenGameResult(gameID, true, &#39;Success&#39;, msg.sender,  _gameResult,  _r1,getEventId(),now);
                _result = true;
                return;
            }else{
                emit OnOpenGameResult(gameID,  false, &#39;The result is illegal&#39;, msg.sender, _gameResult, _r1,getEventId(),now);
                return;
            }
        }else{
            emit OnOpenGameResult(gameID,  false, &#39;Hash Value Not Match&#39;, msg.sender,  _gameResult,  _r1,getEventId(),now);
            return;
        }

    }

    function _calResultReturnIsWin(uint  _playerBetInfoOfIndex,uint _realOdd) private returns(bool _isWin){
        betInfo memory  p = playerBetInfoOf[_playerBetInfoOfIndex];
        uint256 AllAmount = p.BetAmount.mul(1 + p.Odds);
        if(_realOdd > 0){
            if(_realOdd == p.Odds){
                userEtherOf[p.Player] = userEtherOf[p.Player].add(AllAmount);
                userEtherOf[this] = userEtherOf[this].sub(AllAmount);
            }else{
                uint256 winAmount = p.BetAmount.mul(1 + _realOdd);
                userEtherOf[p.Player] =  userEtherOf[p.Player].add(winAmount);
                userEtherOf[this] = userEtherOf[this].sub(winAmount);
                userEtherOf[currentBanker] = userEtherOf[currentBanker].add(AllAmount.sub(winAmount));
                userEtherOf[this] = userEtherOf[this].sub(AllAmount.sub(winAmount));
            }
            return true ;
        }else{
            userEtherOf[currentBanker] = userEtherOf[currentBanker].add(AllAmount) ;
            userEtherOf[this] = userEtherOf[this].sub(AllAmount);
            return false ;
        }
    }

    function openGameResultAndNewGame(uint _minGameResult,uint _midGameResult,uint _maxGameResult, string _r1, bytes32 _gameEncryptedText) public onlyBanker payable returns(bool _result)
    {
        if(msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }
        if(!gameOver){
            _result =  _openGameResult( _minGameResult,_midGameResult,_maxGameResult,  _r1);
        }
        if (gameOver){
            _result = _newGame( _gameEncryptedText);
        }
    }

    function noOpenGameResult() public  returns(bool _result){
        _result = false;
        require(!gameOver);
        require(gameEndTime < now);
        if(lastBlockNumber == block.number){
            emit OnOpenGameResult(gameID,false, &#39;block.number&#39;, msg.sender,0,&#39;&#39;,getEventId(),now);
            return;
        }

        for(uint i = 0; nextRewardPlayNo < playNo && i < currentRewardNum; i++){
            betInfo  storage p = playerBetInfoOf[nextRewardPlayNo];
            if(!p.IsReturnAward){
                p.IsReturnAward = true;
                p.IsWin = true ;
                uint AllAmount = p.BetAmount.mul(1 + p.Odds);
                userEtherOf[p.Player] =userEtherOf[p.Player].add(AllAmount);
                userEtherOf[this] =userEtherOf[this].sub(AllAmount);
            }
            nextRewardPlayNo++;
        }
        if(nextRewardPlayNo == playNo){
            gameOver = true;
            if(betInfoIsLocked){
                betInfoIsLocked = false;
            }
        }

        emit OnOpenGameResult(gameID,  true, &#39;Banker Not Call&#39;, msg.sender,   0, &#39;&#39;,getEventId(),now);
        _result = true;
    }


    function  failUserRefund(uint _playNo) public returns (bool _result) {
        _result = true;
        require(!gameOver);
        require(gameEndTime + 30 days < now);

        betInfo storage p = playerBetInfoOf[_playNo];
        require(p.Player == msg.sender);

        if(!p.IsReturnAward && p.SmallNum > 0){
            p.IsReturnAward = true;
            uint256 ToUser = p.BetAmount;
            uint256 ToBanker = p.BetAmount.mul(p.Odds);
            userEtherOf[p.Player] =  userEtherOf[p.Player].add(ToUser);
            userEtherOf[this] =  userEtherOf[this].sub(ToUser);
            userEtherOf[currentBanker] =  userEtherOf[p.Player].add(ToBanker);
            userEtherOf[this] =  userEtherOf[this].sub(ToBanker);
            p.Odds = 0;
            _result = true;
        }
    }

    function () public payable {
        if(msg.value > 0){
            userEtherOf[msg.sender] = userEtherOf[msg.sender].add(msg.value);
        }
    }

}