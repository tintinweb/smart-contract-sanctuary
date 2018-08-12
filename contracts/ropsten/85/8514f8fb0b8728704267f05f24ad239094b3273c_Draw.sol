pragma solidity ^0.4.24;

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    
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
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}
contract Draw {
    using SafeMath for *;

    event RandEvent(uint256 random, string randName);
    event JoinRet(bool ret, uint256 inviteCode);
    event Result(uint256 winnerPid, uint256 winnerValue, uint256 mostInvitePid, 
    uint256 mostInviteValue, uint256 laffPid, uint256 laffValue);
    event RoundStop(uint256 roundId);

    struct Player {
        address addr;   // player address
        uint256 vault;    // vault
        uint256 laff;   // affiliate pid 
        uint256 joinTime; //join time 
        uint256 drawCount; // draw timtes
        uint256 inviteCode; 
        uint256 inviteCount; // invite count
        uint256 newInviteCount; // new round invite count 
        uint256 inviteTs; // last invite time 
        //uint256 totalDrawCount; 
    }
    
    mapping (address => uint256) public pIDxAddr_; //玩家地址-ID映射
    mapping (uint256 => uint256) public pIDxCount_; //玩家ID-抽奖次数映射

    uint256 public totalPot_ = 0;
    uint256 public beginTime_ = 0;
    uint256 public endTime_ = 0;
    uint256 public pIdIter_ = 0;  //pid自增器
    uint256 public fund_  = 0;  //总奖池基金

    // draw times
    uint64 public times_ = 0;   
    uint256 public drawNum_ = 0; //抽奖人次

    mapping (uint256 => uint256) pInvitexID_;  //(inviteID => ID) 
    
    mapping (bytes32 => address) pNamexAddr_;  //(name => addr) 
    mapping (uint256 => Player) public plyr_;  
    
    mapping (address => uint256) pAddrxFund_;  

    uint256[3] public winners_;  //抽奖一二三等奖的玩家ID

    uint256 public dayLimit_; //每日限额

    uint256[] public joinPlys_;

    uint256 public inviteIter_; //邀请计数

    uint256 public roundId_ = 0; 

    //uint256 public constant gapTime_ = 24 hours;
    uint256 public constant gapTime_ = 3 minutes;

    address private owner_;
    
    constructor () public {
        beginTime_ = now;
        endTime_ = beginTime_ + gapTime_;
        roundId_ = 1;
        owner_ = msg.sender;
    }

    /**
     * @dev prevents contracts from interacting with fomo3d 
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /*
        is the same day
     */
    function isSameDay(uint256 time1, uint256 time2) 
        private 
        pure
        returns(bool)
    {
        uint256 dayTs = 24 * 60 * 60;
        if (time1/dayTs != time2/dayTs) {
            return false;
        } 
        return true;
    }

    uint256 public newMostInviter_ = 0;
    uint256 public newMostInviteTimes_ = 0;
    function determineNewRoundMostInviter (uint256 pid, uint256 times) 
        private
    {
        if (times > newMostInviteTimes_) {
            newMostInviter_ = pid;
            newMostInviteTimes_ = times;
        }
    }

    function joinDraw(uint256 _affCode) 
        isHuman()
        public 
    {
        uint256 _pID = determinePID();

        //邀请一个新玩家，抽奖次数加1
        if (_affCode != 0 && _affCode != plyr_[_pID].inviteCode) {
            uint256 _affPID = pInvitexID_[_affCode];
            if (_affPID != 0) {
                Player storage laffPlayer = plyr_[_affPID];
                if (laffPlayer.inviteTs == 0) {
                    laffPlayer.inviteCount = laffPlayer.inviteCount + 1;
                    if (laffPlayer.inviteTs < beginTime_) {
                        laffPlayer.newInviteCount = 0;
                    }
                    laffPlayer.newInviteCount += 1;
                    laffPlayer.inviteTs = now;
                    determineNewRoundMostInviter(_affPID, laffPlayer.newInviteCount);
                    laffPlayer.laff = _affCode;
                }
            }
        }

        Player storage player = plyr_[_pID];

        if (player.joinTime < beginTime_) {
            player.drawCount = 0;
        } 

        if (player.drawCount == 0) {
            player.drawCount += 1;
            player.joinTime = now;
        } else if (player.drawCount < player.inviteCount &&
            player.drawCount < 5) {
            player.drawCount += 1;
            player.inviteCount -= 1;
            player.joinTime = now;
        } else {
            emit JoinRet(false, player.inviteCode);
        }

        joinPlys_.push(_pID);

        emit JoinRet(true, player.inviteCode);
    }

    function roundEnd() private {
        emit RoundStop(roundId_);
    }

    function charge()
        isHuman()
        public 
        payable
    {
        // online open
        // require(
        //     msg.sender == 0xa28015d172d7573089bb20d8ef1eaf7b94172c31 ||
        //     msg.sender == 0x35e13633dbCa25A3fB5a7CaB0c7F444b927Ab41d,
        //     "only amdin can do this"
        // );

        uint256 _eth = msg.value;
        fund_ = fund_.add(_eth);
    }

    function setParam(uint256 dayLimit) public {
        //admin
        // require (
        //     msg.sender == 0xa28015d172d7573089bb20d8ef1eaf7b94172c31 ||
        //     msg.sender == 0x35e13633dbCa25A3fB5a7CaB0c7F444b927Ab41d,
        //     "only amdin can do this"
        // );

        dayLimit_ = dayLimit;
    }

    function setEndTime(uint256 endTime) public {
        //admin
        // online open
        // require (
        //     msg.sender == 0xa28015d172d7573089bb20d8ef1eaf7b94172c31 ||
        //     msg.sender == 0x35e13633dbCa25A3fB5a7CaB0c7F444b927Ab41d,
        //     "only amdin can do this"
        // );

        endTime_ = endTime;
    }

    modifier havePlay() {
        require (joinPlys_.length > 0, "must have at least 1 player");
        _;
    } 

    function random() 
        havePlay()
        public 
        view
        returns(uint256)
    {
        uint256 _seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));

        require(joinPlys_.length != 0, "no one join draw");

        uint256 _rand = _seed % joinPlys_.length;
        return _rand;
    }

    function joinCount() 
        public 
        view 
        returns (uint256)
    {
        return joinPlys_.length;
    }

    modifier haveFund() {
        require (fund_ > 0, "fund must more than 0");
        _;
    }
    
    function test()
        public 
    {
        //fund_ = fund_ - 100000000000000000;
        fund_ = 0;
    }
    
    function setFund() 
        public
    {
        fund_ = 100000000000000000;
        //fund_ = fund_ - 100000000000000000;
    }

    //开奖
    function onDraw() 
        haveFund()
        public 
    {
        // require (
        //     msg.sender == 0xa28015d172d7573089bb20d8ef1eaf7b94172c31 ||
        //     msg.sender == 0x35e13633dbCa25A3fB5a7CaB0c7F444b927Ab41d,
        //     "only amdin can do this"
        // );

        require(joinPlys_.length != 0, "no one join draw");
        require (fund_ != 0, "fund must more than zero");

        if (dayLimit_ == 0) {
            dayLimit_ = fund_;
        }
        
        winners_[0] = 0;
        winners_[1] = 0;
        winners_[2] = 0;

        uint256 _rand = random();
        uint256 _winner =  joinPlys_[_rand];

        winners_[0] = _winner;
        winners_[1] = newMostInviter_;
        winners_[2] = plyr_[_winner].laff;

        
        uint256 _tempValue = 0;
        uint256 _winnerValue = 0;
        uint256 _mostInviteValue = 0;
        uint256 _laffValue = 0;
        //if (true) {
        if (fund_ >= dayLimit_) {
            _tempValue = dayLimit_;
            fund_ = fund_.div(dayLimit_);
            _winnerValue = dayLimit_.mul(6).div(10);
            _mostInviteValue = dayLimit_.mul(3).div(10);
            _laffValue = dayLimit_.div(10);
            plyr_[winners_[0]].vault = plyr_[winners_[0]].vault.add(_winnerValue);
            if (winners_[1] == 0) {
                _mostInviteValue = 0;
                plyr_[winners_[1]].vault = plyr_[winners_[1]].vault.add(_mostInviteValue);
            }
            if (winners_[2] == 0) { 
                _laffValue = 0;
                plyr_[winners_[2]].vault = plyr_[winners_[2]].vault.add(_laffValue);
            }
        } else {
            _tempValue = fund_;
            fund_ = 0;
            _winnerValue = _tempValue.mul(6).div(10);
            _mostInviteValue = _tempValue.mul(3).div(10);
            _laffValue = _tempValue.div(10);
            plyr_[winners_[0]].vault = plyr_[winners_[0]].vault.add(_winnerValue);
            if (winners_[1] == 0) {
                _mostInviteValue = 0;
                plyr_[winners_[1]].vault = plyr_[winners_[1]].vault.add(_mostInviteValue);
            }
            if (winners_[2] == 0) {
                _laffValue = 0;
                plyr_[winners_[2]].vault = plyr_[winners_[2]].vault.add(_laffValue);
            }
        }

        emit Result(winners_[0], _winnerValue, winners_[1], _mostInviteValue, winners_[2], _laffValue);

        nextRound();
    }

    function nextRound() 
        private 
    {
        beginTime_ = now;
        endTime_ = now + gapTime_;

        delete joinPlys_;
        
        newMostInviteTimes_ = 0;
        newMostInviter_ = 0;

        roundId_++;
        beginTime_ = now;
        endTime_ = beginTime_ + gapTime_;
    }

    function withDraw() 
        isHuman()
        public 
        returns(bool) 
    {
        uint256 _now = now;
        uint256 _pID = determinePID();
        
        if (_pID == 0) {
            return;
        }
        
        if (endTime_ > _now && fund_ > 0) {
            roundEnd();
        }

        if (plyr_[_pID].vault != 0) {
            msg.sender.transfer(plyr_[_pID].vault);
        }

        return true;
    }

    function exportFund()
        public 
    {
        require(msg.sender == owner_, "must onwer can do this");
        msg.sender.transfer(fund_); //Todo make sure contract sum 
    }

    function getRemainCount(address addr) 
        public
        view
        returns(uint256)  
    {
        uint256 pID = pIDxAddr_[addr];
        if (pID == 0) {
            return 1;
        }
        
        uint256 remainCount = 0;

        //uint256 _pID = determinePID();

        if (plyr_[pID].joinTime < beginTime_) {
            remainCount = plyr_[pID].inviteCount < 4 ? plyr_[pID].inviteCount + 1 : 5;
        } else {
            if (plyr_[pID].inviteCount == 0) {
                remainCount = plyr_[pID].drawCount == 0 ? 1 : 0;
            } else {
                if (plyr_[pID].drawCount >= 5) {
                    remainCount = 0;
                } else {
                    uint256 temp = (5 - plyr_[pID].drawCount);
                    remainCount = plyr_[pID].inviteCount > temp ? temp :  plyr_[pID].inviteCount;
                }
            }  
        } 

        return remainCount;
    }

     /**
     * @dev gets existing or registers new pID.  use this when a player may be new
     * @return pID 
     */
    function determinePID()
        private
        returns(uint256)
    {
        uint256 _pID = pIDxAddr_[msg.sender];

        if (_pID == 0) {
            pIdIter_ = pIdIter_ + 1;
            _pID = pIdIter_;
            pIDxAddr_[msg.sender] = _pID;
            plyr_[_pID].addr = msg.sender;
            inviteIter_ = inviteIter_.add(1);
            plyr_[_pID].inviteCode = inviteIter_;
            pInvitexID_[inviteIter_] = _pID;
        }

        return _pID;
    }
}