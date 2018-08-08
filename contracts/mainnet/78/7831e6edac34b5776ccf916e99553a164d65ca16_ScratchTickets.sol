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
  string public gameName = "ScratchTickets";
  uint public constant  gameType = 2005;
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
    require(_newOwner != 0x0);
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

contract ScratchTickets is Base
{

  uint256 public gameMaxBetAmount = 10**9;
  uint256 public gameMinBetAmount = 10**7;

  uint public playNo = 1;
  uint256 public lockTime = 3600;
  address public auction;

  uint public donGameGiftLineTime =  now + 60 days + 30 days;

  struct awardInfo{
    uint Type;
    uint Num;
    uint WinMultiplePer;
    uint KeyNumber;
    uint AddIndex;
  }

  mapping (uint => awardInfo) public awardInfoOf;

  struct betInfo
  {
    address Player;
    uint256 BetAmount;
    uint256 BlockNumber;
    string RandomStr;
    address Banker;
    uint BetNum;
    uint EventId;
    bool IsReturnAward;
  }
  mapping (uint => betInfo) public playerBetInfoOf;

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
    _result =  bankerEndTime <= now;
  }

  function ScratchTickets(string _gameName,uint256 _gameMinBetAmount,uint256 _gameMaxBetAmount,address _DonQuixoteToken) public{
    require(_DonQuixoteToken != 0x0);
    owner = msg.sender;
    gameName = _gameName;
    DonQuixoteToken = IDonQuixoteToken(_DonQuixoteToken);
    gameMinBetAmount = _gameMinBetAmount;
    gameMaxBetAmount = _gameMaxBetAmount;

    _initAwardInfo();
  }

  function _initAwardInfo() private {
    awardInfo memory a1 = awardInfo({
      Type : 1,
      Num : 1,
      WinMultiplePer :1000,
      KeyNumber : 7777,
      AddIndex : 0
    });
    awardInfoOf[1] = a1;

    awardInfo memory a2 = awardInfo({
      Type : 2,
      Num : 10,
      WinMultiplePer :100,
      KeyNumber : 888,
      AddIndex : 1000
    });
    awardInfoOf[2] = a2;

    awardInfo memory a3 = awardInfo({
      Type : 3,
      Num : 100,
      WinMultiplePer :10,
      KeyNumber : 99,
      AddIndex : 100
    });
    awardInfoOf[3] = a3;

    awardInfo memory a4 = awardInfo({
      Type : 4,
      Num : 1000,
      WinMultiplePer :2,
      KeyNumber : 6,
      AddIndex : 10
    });
    awardInfoOf[4] = a4;

    awardInfo memory a5 = awardInfo({
      Type : 5,
      Num : 2000,
      WinMultiplePer :1,
      KeyNumber : 3,
      AddIndex : 5
    });
    awardInfoOf[5] = a5;
  }

  event OnSetNewBanker(address _caller, address _banker, uint _beginTime, uint _endTime, uint _code,uint _eventTime, uint eventId);
  event OnPlay(address indexed _player, uint256 _betAmount,string _randomStr, uint _blockNumber,uint _playNo, uint _eventTime, uint eventId);
  event OnGetAward(address indexed _player,uint indexed _awardType, uint256 _playNo,string _randomStr, uint _blockNumber,bytes32 _blockHash,uint256 _betAmount, uint _eventTime, uint eventId,uint256 _allAmount,uint256 _awardAmount);

  function setAuction(address _newAuction) public onlyOwner{
    auction = _newAuction;
  }

  function setBanker(address _banker, uint _beginTime, uint _endTime) public onlyAuction returns(bool _result){
    _result = false;
    require(_banker != 0x0);
    if(now < bankerEndTime){
      emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime, 1, now, getEventId());
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
    currentBanker = _banker;
    bankerBeginTime = _beginTime;
    bankerEndTime = _endTime;
    emit OnSetNewBanker(msg.sender, _banker,  _beginTime,  _endTime,0, now, getEventId());
    if(now < donGameGiftLineTime){
      DonQuixoteToken.logPlaying(_banker);
    }
    _result = true;
  }

  function tokenOf(address _user) view public returns(uint256 _result){
    _result = DonQuixoteToken.balanceOf(_user);
  }

  function play(string _randomStr,uint256 _betAmount) public returns(bool _result){
    _result = _play(_randomStr, _betAmount);
  }

  function _play(string _randomStr, uint256 _betAmount) private  returns(bool _result){
    _result = false;
    require(msg.sender != currentBanker);
    require(now < bankerEndTime.sub(lockTime));
    require(userTokenOf[currentBanker]>=gameMaxBetAmount.mul(1000));
    require(bytes(_randomStr).length<=18);

    uint256 ba = _betAmount;
    if (ba > gameMaxBetAmount){
      ba = gameMaxBetAmount;
    }
    require(ba >= gameMinBetAmount);

    if(userTokenOf[msg.sender] < _betAmount){
      depositToken(_betAmount.sub(userTokenOf[msg.sender]));
    }
    require(userTokenOf[msg.sender] >= ba);
    betInfo memory bi = betInfo({
      Player :  msg.sender,
      BetAmount : ba,
      BlockNumber : block.number,
      RandomStr : _randomStr,
      Banker : currentBanker,
      BetNum : 0,
      EventId : currentEventId,
      IsReturnAward: false
    });
    playerBetInfoOf[playNo] = bi;
    userTokenOf[msg.sender] = userTokenOf[msg.sender].sub(ba);
    userTokenOf[currentBanker] = userTokenOf[currentBanker].add(ba);
    emit OnPlay(msg.sender,  ba,  _randomStr, block.number,playNo,now, getEventId());
    if(now < donGameGiftLineTime){
      DonQuixoteToken.logPlaying(msg.sender);
    }
    playNo++;
    _result = true;
  }

  function getAward(uint _playNo) public returns(bool _result){
    _result = _getaward(_playNo);
  }

  function _getaward(uint _playNo) private  returns(bool _result){
    require(_playNo<=playNo);
    _result = false;
    bool isAward = false;
    betInfo storage bi = playerBetInfoOf[_playNo];
    require(!bi.IsReturnAward);
    require(bi.BlockNumber>block.number.sub(256));
    bytes32 blockHash = block.blockhash(bi.BlockNumber);
    lock();
    uint256 randomNum = bi.EventId%1000;
    bytes32 encrptyHash = keccak256(bi.RandomStr,bi.Player,blockHash,uint8ToString(randomNum));
    bi.BetNum = uint(encrptyHash)%10000;
    bi.IsReturnAward = true;
    for (uint i = 1; i < 6; i++) {
      awardInfo memory ai = awardInfoOf[i];
      uint x = bi.BetNum%(10000/ai.Num);
      if(x == ai.KeyNumber){
        uint256 AllAmount = bi.BetAmount.mul(ai.WinMultiplePer);
        uint256 awadrAmount = AllAmount;
        if(AllAmount >= userTokenOf[bi.Banker]){
          awadrAmount = userTokenOf[bi.Banker];
        }
        userTokenOf[bi.Banker] = userTokenOf[bi.Banker].sub(awadrAmount) ;
        userTokenOf[bi.Player] =userTokenOf[bi.Player].add(awadrAmount);
        isAward = true;
        emit OnGetAward(bi.Player,i, _playNo,bi.RandomStr,bi.BlockNumber,blockHash,bi.BetAmount,now,getEventId(),AllAmount,awadrAmount);
        break;
      }
    }
    if(!isAward){
      if(now < donGameGiftLineTime){
        DonQuixoteToken.sendGameGift(bi.Player);
      }
      emit OnGetAward(bi.Player,0, _playNo,bi.RandomStr,bi.BlockNumber,blockHash,bi.BetAmount,now,getEventId(),0,0);
    }
    _result = true;
    unLock();
  }

  function _withdrawToken(address _to, uint256 _amount) internal {
    require(_to != 0x0);
    if(_to == currentBanker){
      require(userTokenOf[currentBanker] > gameMaxBetAmount.mul(1000));
      _amount = userTokenOf[currentBanker].sub(gameMaxBetAmount.mul(1000));
    }
    userTokenOf[_to] = userTokenOf[_to].sub(_amount);
    DonQuixoteToken.transfer(_to, _amount);
  }

  function uint8ToString(uint v) private pure returns (string)
  {
    uint maxlength = 8;
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

  function setLockTime(uint256 _lockTIme)public onlyOwner(){
    lockTime = _lockTIme;
  }

  function transEther() public onlyOwner()
  {
    msg.sender.transfer(address(this).balance);
  }

  function () public payable {
  }
}