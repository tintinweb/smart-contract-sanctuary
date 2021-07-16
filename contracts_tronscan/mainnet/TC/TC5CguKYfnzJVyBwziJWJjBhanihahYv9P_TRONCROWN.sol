//SourceUnit: troncrown.sol

  pragma solidity ^ 0.4 .25;

  library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
      if (a == 0) {
        return 0;
      }

      uint256 c = a * b;
      require(c / a == b);

      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
      require(b > 0);
      uint256 c = a / b;

      return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
      require(b <= a);
      uint256 c = a - b;

      return c;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
      uint256 c = a + b;
      require(c >= a);

      return c;
    }

  }
  

  contract TRONCROWN {
    using SafeMath
    for uint256;
    uint public players;
    uint public totalFund;
    uint public startTime;
    uint public hasStarted;
    uint ratePerDay = 20;
    uint cashBackRate = 10;
    uint refferalBonus = 10;
    uint public Min = 30e6;
    uint public lastGivenSponsor;
    address _dev = msg.sender;
    uint public rewards;

    struct User {
      uint Id;
      address Sponsor;
      uint Invested;
      uint Withdrawn;
      uint CashBack;
      uint reffered;

    }
    mapping(address => User) public Player;
    mapping(address => bool) public isPlayer;
    mapping(address => uint) readyBalance;
    mapping(address => uint) readyCashBack;
    mapping(address => uint) _timing;
    mapping(uint => bool) public isCode;
    mapping(uint => address) public _codeOwner;
    mapping(uint => address) public _freeReferalLineUp;
    mapping(address => uint) hasReferral;
    mapping(address => uint) public totalRefBonus;

    constructor() {
      Player[msg.sender].Id = getCode();
      isCode[Player[msg.sender].Id] = true;
      isPlayer[msg.sender] = true;
      _codeOwner[Player[msg.sender].Id] = msg.sender;
      Player[msg.sender].Sponsor = 0x00;
      _freeReferalLineUp[players] = msg.sender;
      players++;
      startTime = now + 1 days;
    }

    function JoinGame(uint _sponsorCode, uint _usedFree) external {

      require(!isPlayer[msg.sender]);
      require(isCode[_sponsorCode]);
      User storage _investor = Player[msg.sender];
      if (_usedFree == 1) {
        assignSponsor();
      } else {
        _investor.Sponsor = _codeOwner[_sponsorCode];
      }

      hasReferral[_investor.Sponsor]++;
      _investor.Id = getCode();
      _freeReferalLineUp[players] = msg.sender;
      players++;
      isCode[_investor.Id] = true;
      isPlayer[msg.sender] = true;
      _codeOwner[Player[msg.sender].Id] = msg.sender;

    }

    function assignSponsor() internal {
      User storage _investor = Player[msg.sender];
      _investor.Sponsor = _freeReferalLineUp[lastGivenSponsor];
      lastGivenSponsor++;

    }

    function getCode() public view returns(uint) {
      uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, players))) % 90000;
      randomnumber = randomnumber + 1000;
      if (isCode[randomnumber]) {
        getCode();
      } else {
        return randomnumber;
      }
    }

    function investNow() public payable {
     require(now > startTime);
      require(isPlayer[msg.sender] && msg.value >= Min);
      User storage _investor = Player[msg.sender];
      readyBalance[msg.sender] =  _profits(msg.sender);
      readyCashBack[msg.sender] = 0;
      _timing[msg.sender] = now;
      _investor.Invested += msg.value;
      totalFund += msg.value;
      (hasReferral[msg.sender] >= 1 ? _investor.CashBack += ((msg.value * cashBackRate) / 100) : _investor.CashBack += 0);
      readyCashBack[msg.sender] += _investor.CashBack;
      address _sponsor = _investor.Sponsor;
      (_investor.Sponsor != 0x00 ? readyBalance[_sponsor] += ((msg.value * refferalBonus) / 100) : 0);
      (_investor.Sponsor != 0x00 ? totalRefBonus[_sponsor] += ((msg.value * refferalBonus) / 100) : 0);

      _dev.transfer((msg.value * 4) / 100);
    }

    function _profits(address _addr) public view returns(uint) {
      User storage _investor = Player[_addr];
      if (!isPlayer[_addr] && _timing[_addr] != 0) {
        return 0;
      } else {
        uint _secondPassed = now - _timing[_addr];
        uint rate = SafeMath.div(((_investor.Invested * ratePerDay) / 100), 1 days);
        uint _earned = _secondPassed * rate;
        return _earned + readyBalance[_addr] + readyCashBack[_addr];
      }

    }

    function withdraw() external returns(bool) {
      require(now > startTime);
      require(isPlayer[msg.sender]);
      uint _amount = _profits(msg.sender);
      uint _fee = (_amount * 4) / 100;
      _timing[msg.sender] = now;
      msg.sender.transfer(_amount - _fee);
      _dev.transfer(_fee);
      User storage _investor = Player[msg.sender];
      _investor.Withdrawn += (_amount - _fee);
      readyBalance[msg.sender] = 0;
      readyCashBack[msg.sender] = 0;
      rewards += _amount;

      return true;
    }

  }