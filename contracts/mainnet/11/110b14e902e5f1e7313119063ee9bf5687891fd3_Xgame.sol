pragma solidity ^0.4.24;

library SafeMath {
    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, &#39;div failed&#39;);
        uint256 c = a / b;
        require(a == b * c + a % b, &#39;div failed&#39;);
        if (b * c != a) {
            c += 1;
        }
        return c;
    }
}

library Random {
    function getRandom (uint256 _start, uint256 _end) internal view returns (uint256) {
        require(_start >= 0 && _end >= _start, &#39;get random error&#39;);
        if (_end == _start) {
            return _start;
        }
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp
            + block.difficulty
            + (uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)
            + block.gaslimit
            + (uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)
            + block.number
        )));
        return seed % (_end - _start) + _start;
    }
}

contract Events {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event BalanceChange(uint256 _changeType, address _owner, uint256 _amount, uint256 _roundId);
    event Invite(uint256 _firstInvitor, uint256 _firstInvitorAward, uint256 _secondInvitor, uint256 _secondInvitorAward);
    event Buy(uint256 _roundId, uint256 _token, uint256 _ethNoUse, uint256 _ticketEnd, uint256 _ticketNum);
    event RoundStart(uint256 _roundId, uint256 _startTime);
    event RoundEnd(uint256 _roundId, uint256 _endTime, address _luckyPlayerAddr, address _finalPlayerAddr, address _richPlayerAddr, uint256 _currentOut, uint256 _currentSharePool);
    event TokenOver(uint256 _totalRemain);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Xgame is Events {
    using SafeMath for *;
    
    mapping (address => mapping (address => uint256)) private allowed;
    uint256 public outToken = 0;
    uint256 public outOverRoundId = 0;
    uint256 public totalSharePool = 0;
    bool private activated = false;
    uint256 public pid = 0;
    mapping (uint256 => Datasets.Round) public rounds;
    uint256 public roundId = 0;
    mapping (address => uint256) public addrPids; // address => playerId
    mapping (uint256 => Datasets.Player) public players; // playerId => struct
    Datasets.Token public token;
    Datasets.Config public _config;
    Datasets.Config public _oldConfig;
    address private admin;
    uint256 private adminId;
    mapping (uint256 => mapping(uint256 => Datasets.PlayerRound)) public _playerRounds; // playerId => roundId => struct
    mapping (uint256 => mapping(uint256 => address)) public _roundTickets; // roundId => ticketId => player address
    uint256 private bigRoundStartTime;
    uint256 private hasRoundNum;  // rounds num of big round
    bool private bigRoundLock = false;
    uint256 public bigRoundMaxRoundNum = 12;
    
    constructor () public {
        admin = msg.sender;
        // init config
        token = Datasets.Token(&#39;XGT&#39;, 18, 50000000000000000000000000, false);
        _config = Datasets.Config(10, 5, 50, 30, 10, 5, 5, 5000000000000000000, 10 minutes, 25000000000000000000000, 500, 5, 4 hours, 24 hours);
        _oldConfig = Datasets.Config(10, 5, 50, 30, 10, 5, 5, 5000000000000000000, 10 minutes, 25000000000000000000000, 500, 5, 4 hours, 24 hours);
        // init admin account
        _determinePid(admin);
        adminId = addrPids[admin];
        players[adminId] = Datasets.Player(0, 0, admin, 0, 0, 0, 0);
    }
    
    modifier isAdmin() {
        require(msg.sender == admin, "must be admin");
        _;
    }
    
    modifier isActivated () {
        require(activated == true, &#39;game not be activated&#39;);
        _;
    }
    
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, &#39;eth too small&#39;);
        require(_eth <= 100000000000000000000, &#39;eth too big&#39;);
        _;
    }
    
    modifier notPaused() {
        require(token.paused == false, &#39;transfer paused&#39;);
        _;
    }
    
    //==============================================================================
    //     _    |_ |. _   |`    _  __|_. _  _  _  .
    //    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (view)
    //====|=========================================================================
    
    function getRoundAwardTicketNum (uint256 _roundId) external view returns (uint256 last_lucky_ticketnum, uint256 last_rich_ticketnum, uint256 last_final_ticketnum) {
        return (
            activated == false || _roundId < 1 ? 0 : _playerRounds[addrPids[rounds[_roundId].luckyPlayerAddr]][_roundId].ticketNum,
            activated == false || _roundId < 1 ? 0 : _playerRounds[addrPids[rounds[_roundId].richPlayerAddr]][_roundId].ticketNum,
            activated == false || _roundId < 1 ? 0 : _playerRounds[addrPids[rounds[_roundId].finalPlayerAddr]][_roundId].ticketNum
            );
    }
    
    function getTimes () external view returns (uint256 small_gap, uint256 big_gap) {
        if (activated == false) {
            return (0, 0);
        }
        uint256 smallGap = _config.roundGap + rounds[roundId].endTime - now;
        if (!(rounds[roundId].ended == true && rounds[roundId + 1].startTime == 0) || smallGap > _config.roundGap) {
            smallGap = 0;
        }
        
        uint256 bigGap = _config.bigRoundGapTime - now + bigRoundStartTime;
        if (bigRoundLock == false || bigGap > _config.bigRoundGapTime) {
            bigGap = 0;
        }
        
        return (
            smallGap,
            bigGap
            );
    }
    
    function getEthBalance (address _addr) external view returns (uint256) {
        return players[addrPids[_addr]].ethBalance;
    }
    
    
    
    //==============================================================================
    //     _    |_ |. _   |`    _  __|_. _  _  _  .
    //    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (public function)
    //====|=========================================================================
    function pauseTransfer () external isHuman notPaused isAdmin {
        token.paused = true;
    }
    
    function deposit () external isHuman isActivated isWithinLimits(msg.value) payable {
        _determinePid(msg.sender);
        players[addrPids[msg.sender]].ethBalance = players[addrPids[msg.sender]].ethBalance.add(msg.value);
    }
    
    function withdraw () external isHuman isActivated {
        require(players[addrPids[msg.sender]].ethBalance > 0, &#39;balance not enough&#39;);
        uint256 _temp = players[addrPids[msg.sender]].ethBalance;
        players[addrPids[msg.sender]].ethBalance = 0;
        msg.sender.transfer(_temp);
    }
    
    function activate () external isAdmin {
        require(rounds[roundId].roundId == 0, &#39;activate error&#39;);
        activated = true;
        
        roundId = 1;
        uint256 _time = now;
        rounds[1] = Datasets.Round(1, 0, 0, _config.initMaxBet, false, _time, 0, 0, 0, 0, 0, 0, 0);
        bigRoundStartTime = _time;

        emit Events.RoundStart(roundId, rounds[roundId].startTime);
    }
    
    function () external isActivated isHuman isWithinLimits(msg.value) payable {
        _determinePid(msg.sender);
        uint256 _playerId = addrPids[msg.sender];
        uint256 _gotToken = _buyToken(_playerId, msg.value, 0);
        if (rounds[roundId].ended == false && (_gotToken == 0 || _config.ticketSum <= rounds[roundId].ticketIndex)) {
            _endRound();
        }
    }
    
    function withdrawShare (address _to) external isAdmin isActivated isHuman payable {
        require(addrPids[_to] != 0);
        players[addrPids[_to]].ethBalance += msg.value;
    }
    
    function rebuy (uint256 _num) external isActivated isHuman {
        require(_num <= _config.ticketSum);
        require(addrPids[msg.sender] != 0 && players[addrPids[msg.sender]].ethBalance > 0, &#39;player not exist&#39;);
        uint256 _eth = players[addrPids[msg.sender]].ethBalance;
        players[addrPids[msg.sender]].ethBalance = 0;
        uint256 _gotToken = _buyToken(addrPids[msg.sender], _eth, _num);
        
        invite(addrPids[msg.sender], _gotToken, 0);
        
        if (rounds[roundId].ended == false && (_gotToken == 0 || _config.ticketSum <= rounds[roundId].ticketIndex)) {
            _endRound();
        }
    }
    
    function buy(uint256 _invitor) external isActivated isHuman isWithinLimits(msg.value) payable {
        _determinePid(msg.sender);
        uint256 _playerId = addrPids[msg.sender];
        uint256 _gotToken = _buyToken(_playerId, msg.value, 0);
        
        invite(_playerId, _gotToken, _invitor);
        
        
        if (rounds[roundId].ended == false && (_gotToken == 0 || _config.ticketSum <= rounds[roundId].ticketIndex)) {
            _endRound();
        }
    }

    function transfer(address _to, uint256 _value) external notPaused returns (bool success) {
        require(_to != address(0));
        require(_value <= players[addrPids[msg.sender]].tBalance);
        require(players[addrPids[_to]].tBalance.add(_value) > players[addrPids[_to]].tBalance);
        players[addrPids[msg.sender]].tBalance = players[addrPids[msg.sender]].tBalance.sub(_value);
        emit Events.BalanceChange(0, msg.sender, _value, rounds[roundId].ended ? roundId + 1 : roundId);
        _determinePid(_to);
        players[addrPids[_to]].tBalance = players[addrPids[_to]].tBalance.add(_value);
        emit Events.BalanceChange(1, _to, _value, rounds[roundId].ended ? roundId + 1 : roundId);
        emit Events.Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) constant external returns (uint256 balance) {
        return players[addrPids[_owner]].tBalance;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0));
        require(_value <= players[addrPids[_from]].tBalance);
        require(_value <= allowed[_from][msg.sender]);
        require(players[addrPids[_to]].tBalance + _value > players[addrPids[_to]].tBalance);
        players[addrPids[_to]].tBalance = players[addrPids[_to]].tBalance.add(_value);
        players[addrPids[_from]].tBalance = players[addrPids[_from]].tBalance.sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Events.Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Events.Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    
    
    
    //==============================================================================
    //     _    |_ |. _   |`    _  __|_. _  _  _  .
    //    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (private function)
    //====|=========================================================================
    
    function invite (uint256 _playerId, uint256 _amount, uint256 _invitor) private returns (bool) {
        if (_amount > 10) {
            if (players[_playerId].invitor != 0) {
                _invitor = players[_playerId].invitor;
            } else {
                if (_invitor == 0 || _playerId == _invitor || players[_invitor].addr == address(0)) {
                    return false;
                }
                players[_playerId].invitor = _invitor;
            }
            
            
            uint256 _firstInvitorAward = _amount * _config.firstInviteAward / 100;
            _giveToken(_invitor, _firstInvitorAward);
            players[_invitor].tokenForInvite += _firstInvitorAward;

    
            uint256 secondInvitor = players[_invitor].invitor;
            if (secondInvitor != 0 && players[secondInvitor].addr != address(0)) {
                uint256 _secondInvitorAward = _amount * _config.secondInviteAward / 100;
                _giveToken(secondInvitor, _secondInvitorAward);
                players[secondInvitor].tokenForInvite += _secondInvitorAward;
            }
            emit Events.Invite(_invitor, _firstInvitorAward, secondInvitor, _secondInvitorAward);
            return true;
        }
        return false;
    }
    
    
    function _endRound () private {
        // end round
        rounds[roundId].ended = true;
        rounds[roundId].endTime = now;
        rounds[roundId].currentOutToken = outToken;
        
        uint256 _totalEth = rounds[roundId].hasBetted + rounds[roundId].wrapPool;
        // share
        uint256 _currentShareAward = _totalEth * _config.sharePoolPercent / 100;
        admin.transfer(_currentShareAward);
        totalSharePool += _currentShareAward;
        // wrap
        rounds[roundId + 1].wrapPool = _totalEth * _config.wrapPercent / 100;
        // lucky
        address _luckyPlayerAddr = _roundTickets[roundId][Random.getRandom(1, rounds[roundId].ticketIndex + 1) - 1];
        if (_luckyPlayerAddr == address(0)) {
            _luckyPlayerAddr = admin;
        }
        rounds[roundId].luckyPlayerAddr = _luckyPlayerAddr;
        uint256 _luckyAward = _totalEth * _config.luckyPoolPercent / 100;
        players[addrPids[_luckyPlayerAddr]].ethBalance += _luckyAward;
        
        // final
        if (rounds[roundId].finalPlayerAddr == address(0)) {
            rounds[roundId].finalPlayerAddr = admin;
        }
        players[addrPids[rounds[roundId].finalPlayerAddr]].ethBalance += _totalEth * _config.finalPoolPercent / 100;
        
        // rich
        if (rounds[roundId].richPlayerAddr == address(0)) {
            rounds[roundId].richPlayerAddr = admin;
        }
        players[addrPids[rounds[roundId].richPlayerAddr]].ethBalance += _totalEth * _config.richPoolPercent / 100;
        
        // next round data 
        if (rounds[roundId].ticketIndex < _config.ticketSum) {
            rounds[roundId + 1].maxBet = rounds[roundId].maxBet - (rounds[roundId].maxBet * _config.maxBetRate / 10000);
        } else {
            rounds[roundId + 1].maxBet = rounds[roundId].maxBet + (rounds[roundId].maxBet * _config.maxBetRate).divUp(10000);
        }
        if (rounds[roundId + 1].maxBet < 500000000000000000) {
            rounds[roundId + 1].maxBet = 500000000000000000;
        }
        
        // remain token
        uint256 _totalRemain = token.total - outToken;
        if (outToken < token.total && _totalRemain < _config.tokenMaxIssue * 3 / 2) {
            // change
            _config.firstInviteAward = 0;
            _config.secondInviteAward = 0;
            _config.sharePoolPercent = 1;
            _config.finalPoolPercent = 5;
            _config.richPoolPercent = 5;
            _config.luckyPoolPercent = 79;
            _config.wrapPercent = 10;
            outOverRoundId = roundId;
            players[addrPids[admin]].tBalance += _totalRemain;
            emit Events.BalanceChange(1, admin, _totalRemain, rounds[roundId].ended ? roundId + 1 : roundId);
            outToken = token.total;
            rounds[roundId].currentOutToken = outToken;
            emit Events.TokenOver(_totalRemain);
        }
        
        if (hasRoundNum == bigRoundMaxRoundNum - 1) {
            bigRoundLock = true;
        }
        if (now - bigRoundStartTime > _config.bigRoundGapTime) {
            bigRoundLock = false;
            bigRoundStartTime = rounds[roundId].startTime;
            hasRoundNum = 0;
        }
        
        hasRoundNum += 1;
        emit Events.RoundEnd(roundId, rounds[roundId].endTime, _luckyPlayerAddr, rounds[roundId].finalPlayerAddr, rounds[roundId].richPlayerAddr, rounds[roundId].currentOutToken, _currentShareAward);
    }
    
    function _startRound () private {
        rounds[roundId + 1].roundId = roundId + 1;
        rounds[roundId + 1].ended = false;
        rounds[roundId + 1].startTime = now;
        roundId = roundId + 1;
        emit Events.RoundStart(roundId, rounds[roundId].startTime);
    }
    
    function _buyToken (uint256 _playerId, uint256 _eth, uint256 _num) private returns (uint256) {
        if (rounds[roundId].ended == true) {
            if (now < rounds[roundId].endTime + _config.roundGap) {
                players[_playerId].ethBalance += _eth;
                return 1;
            }
            if (bigRoundLock == true && now - bigRoundStartTime < _config.bigRoundGapTime) {
                players[_playerId].ethBalance += _eth;
                return 1;
            }
            _startRound();
        }
        
        if (rounds[roundId].ended == false && rounds[roundId].startTime + _config.maxRoundTime < now) {
            players[_playerId].ethBalance += _eth;
            return 0;
        }
        
        uint256 _ticketPrice = rounds[roundId].maxBet.divUp(_config.ticketSum);
        if (_eth < _ticketPrice) {
            players[_playerId].ethBalance += _eth;
            return 1;
        }
        
        uint256 _ethNoUse = 0;
        uint256 _ethForToken = _eth;
        uint256 _remainBet = (_config.ticketSum - rounds[roundId].ticketIndex) * _ticketPrice;
        if (_eth > _remainBet) {
            _ethNoUse = _eth - _remainBet;
            players[_playerId].ethBalance += _ethNoUse;
            _ethForToken = _remainBet;
        }
        
        // lucky
        if (_num == 0) {
            uint256 _ticketNum = _ethForToken / _ticketPrice;
        } else {
            _ticketNum = _num;
            require(_ethForToken >= _ticketNum * _ticketPrice);
        }
        
        uint256 _dust = _ethForToken - (_ticketNum * _ticketPrice);
        players[_playerId].ethBalance += _dust;
        _ethNoUse += _dust;
        _ethForToken = _ticketNum * _ticketPrice;
        for (uint256 i = 0; i < _ticketNum; i++) {
            _roundTickets[roundId][rounds[roundId].ticketIndex + i] = msg.sender;
        }
        rounds[roundId].ticketIndex += _ticketNum;
        _playerRounds[_playerId][roundId].ticketNum += _ticketNum;
        
        
        rounds[roundId].hasBetted += _ethForToken;
        
        if (outToken < token.total) {
            // token for eth
            uint256 _gotToken = _ticketNum * _config.tokenMaxIssue / _config.ticketSum;
            _giveToken(_playerId, _gotToken);
            players[_playerId].tokenForEth += _gotToken;
            players[addrPids[admin]].tokenForEth += (_gotToken / 4);
        } else {
            _gotToken = 2;
        }
        
        
        // caculate rich player
        if (rounds[roundId].richPlayerAddr == address(0) || _playerRounds[_playerId][roundId].ticketNum > rounds[roundId].richPlayerTicketsNum) {
            rounds[roundId].richPlayerAddr = msg.sender;
            rounds[roundId].richPlayerTicketsNum = _playerRounds[_playerId][roundId].ticketNum;
        }
        
        // record last
        rounds[roundId].finalPlayerAddr = msg.sender;
        
        emit Events.Buy(roundId, _gotToken, _ethNoUse, rounds[roundId].ticketIndex, _ticketNum);
        
        return _gotToken;
    }
    
    function _giveToken (uint256 _playerId, uint256 _amount) private {
        players[_playerId].tBalance += _amount;
        emit Events.BalanceChange(1, players[_playerId].addr, _amount, rounds[roundId].ended ? roundId + 1 : roundId);
        
        // system got token
        uint256 systemGot = _amount / 4;
        players[addrPids[admin]].tBalance += systemGot;
        emit Events.BalanceChange(1, players[addrPids[admin]].addr, systemGot, rounds[roundId].ended ? roundId + 1 : roundId);
        
        
        outToken += (_amount + systemGot);
    }
    
    function _determinePid(address _addr) private returns (bool) {
        // if pid not exist, generate it
        if (addrPids[_addr] == 0) {
            pid++;
            addrPids[_addr] = pid;
            players[pid].addr = _addr;
            return true;
        } else {
            return false;
        }
    }
}

library Datasets {
    struct Player {
        uint256 tBalance;
        uint256 ethBalance;
        address addr;
        uint256 invitor;
        uint256 tokenForInvite;
        uint256 hasWithdrawRoundNum;
        uint256 tokenForEth;
    }
    
    struct Token {
        string tokenName;
        uint256 decimals;
        uint256 total;
        bool paused;
    }
    
    struct Config {
        uint256 firstInviteAward; // percent
        uint256 secondInviteAward;
        uint256 sharePoolPercent;
        uint256 luckyPoolPercent;
        uint256 wrapPercent;
        uint256 finalPoolPercent;
        uint256 richPoolPercent;
        uint256 initMaxBet;
        uint256 roundGap;
        uint256 tokenMaxIssue;
        uint256 ticketSum;
        uint256 maxBetRate;  // per ten thousand
        uint256 maxRoundTime;  // max round time. s
        uint256 bigRoundGapTime; // max big round time
    }
    
    struct Round {
        uint256 roundId;
        uint256 hasBetted;
        uint256 wrapPool;
        uint256 maxBet;
        bool ended;
        uint256 startTime;
        uint256 endTime;
        address richPlayerAddr;
        uint256 richPlayerTicketsNum;
        address luckyPlayerAddr;
        uint256 ticketIndex;
        address finalPlayerAddr;
        uint256 currentOutToken;
    }
    
    struct PlayerRound {
        uint256 ticketNum;
    }
}