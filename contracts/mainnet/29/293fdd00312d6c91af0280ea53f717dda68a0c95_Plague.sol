pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
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

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }
    
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
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
    
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
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

contract PlagueEvents {
	
	//infective person
    event onInfectiveStage
    (
        address indexed player,
        uint256 indexed rndNo,
        uint256 keys,
        uint256 eth,
        uint256 timeStamp,
		address indexed inveter
    );

    // become leader during second stage
    event onDevelopmentStage
    (
        address indexed player,
        uint256 indexed rndNo,
        uint256 eth,
        uint256 timeStamp,
		address indexed inveter
    );

    // award
    event onAward
    (
        address indexed player,
        uint256 indexed rndNo,
        uint256 eth,
        uint256 timeStamp
    );
}

contract Plague is PlagueEvents{
    using SafeMath for *;
    using KeysCalc for uint256;

    struct Round {
        uint256 eth;                // total eth
        uint256 keys;               // total keys
        uint256 startTime;          // end time
        uint256 endTime;            // end time
        uint256 infectiveEndTime;   // infective end time
        address leader;             // leader
        address infectLastPlayer;   // the player will award 10% eth
        address [11] lastInfective;  // the lastest 11 infective
        address [4] loseInfective;  // the lose infective
        bool [11] infectiveAward_m; //
        uint256 totalInfective;     // the count of this round
        uint256 inveterAmount;      // remain inveter amount of this round
        uint256 lastRoundReward;    // last round remain eth 10% + eth 4% - inveterAmount + last remain award
        uint256 exAward;            // development award
    }

    struct PlayerRound {
        uint256 eth;        // eth player has added to round
        uint256 keys;       // keys
        uint256 withdraw;   // how many eth has been withdraw
        uint256 getInveterAmount; // inverter amount
        uint256 hasGetAwardAmount;  // player has get award amount
    }

    uint256 public rndNo = 1;                                   // current round number
    uint256 public totalEth = 0;                                // total eth in all round

    uint256 constant private rndInfectiveStage_ = 10 minutes;          // round timer at iinfective stage12 hours;
    uint256 constant private rndInfectiveReadyTime_ = 1 minutes;      // round timer at infective stage ready time
    uint256 constant private rndDevelopmentStage_ = 3 minutes;       // round timer at development stage 30 minutes; 
    uint256 constant private rndDevelopmentReadyTime_ = 1 minutes;       // round timer at development stage ready time 1 hours;
    uint256 constant private allKeys_ = 100 * (10 ** 18);   // all keys count
    uint256 constant private allEths_ = 7500773437500000; // all eths count
    uint256 constant private rndIncreaseTime_ = 3 minutes;       // increase time 3 hours
    uint256 constant private developmentAwardPercent = 1;   // 0.1% reduction every 3 hours

    mapping (uint256 => Round) public round_m;                  // (rndNo => Round)
    mapping (uint256 => mapping (address => PlayerRound)) public playerRound_m;   // (rndNo => addr => PlayerRound)

    address public owner;               // owner address
    address public receiver = address(0);            // receive eth address
    uint256 public ownerWithdraw = 0;   // how many eth has been withdraw by owner
    bool public isStartGame = false;    // start game flag

    constructor()
        public
    {
        owner = msg.sender;
    }

    /**
     * @dev prevents contracts from interacting
     */
    modifier onlyHuman() 
    {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    /**
     * @dev sets boundaries for incoming tx 
     */
    modifier isWithinLimits(uint256 _eth) 
    {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }

    /**
     * @dev only owner
     */
    modifier onlyOwner() 
    {
        require(owner == msg.sender, "only owner can do it");
        _;    
    }
    
    /**
     * @dev It must be human beings to call the function.
     */
    function isHuman(address _addr) private view returns (bool)
    {
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        return _codeLength == 0;
    }
   
   /**
	 * @dev player infect a person at current round
	 * 
	 */
    function buyKeys(address _inveter) private
    {
        uint256 _eth = msg.value;
        uint256 _now = now;
        uint256 _rndNo = rndNo;
        uint256 _ethUse = msg.value;

        // start next round?
        if (_now > round_m[_rndNo].endTime)
        {
            require(round_m[_rndNo].endTime + rndDevelopmentReadyTime_ < _now, "we should wait some times");
            
            uint256 lastAwardEth = (round_m[_rndNo].eth.mul(14) / 100).sub(round_m[_rndNo].inveterAmount);
            
            if(round_m[_rndNo].totalInfective < round_m[_rndNo].lastInfective.length.sub(1))
            {
                uint256 nextPlayersAward = round_m[_rndNo].lastInfective.length.sub(1).sub(round_m[_rndNo].totalInfective);
                uint256 _totalAward = round_m[_rndNo].eth.mul(30) / 100;
                _totalAward = _totalAward.add(round_m[_rndNo].lastRoundReward);
                if(round_m[_rndNo].infectLastPlayer != address(0))
                {
                    lastAwardEth = lastAwardEth.add(nextPlayersAward.mul(_totalAward.mul(3)/100));
                }
                else
                {
                    lastAwardEth = lastAwardEth.add(nextPlayersAward.mul(_totalAward.mul(4)/100));
                }
            }
            
            _rndNo = _rndNo.add(1);
            rndNo = _rndNo;
            round_m[_rndNo].startTime = _now;
            round_m[_rndNo].endTime = _now + rndInfectiveStage_;
            round_m[_rndNo].totalInfective = 0;
            round_m[_rndNo].lastRoundReward = lastAwardEth;
        }

        // infective or second stage
        if (round_m[_rndNo].keys < allKeys_)
        {
            // infection stage
            uint256 _keys = (round_m[_rndNo].eth).keysRec(_eth);
            
            if (_keys.add(round_m[_rndNo].keys) >= allKeys_)
            {
                _keys = allKeys_.sub(round_m[_rndNo].keys);

                if (round_m[_rndNo].eth >= allEths_)
                {
                    _ethUse = 0;
                } 
                else {
                    _ethUse = (allEths_).sub(round_m[_rndNo].eth);
                }

                if (_eth > _ethUse)
                {
                    // refund
                    msg.sender.transfer(_eth.sub(_ethUse));
                } 
                else {
                    // fix
                    _ethUse = _eth;
                }
                // first stage is over, record current time
                round_m[_rndNo].infectiveEndTime = _now.add(rndInfectiveReadyTime_);
                round_m[_rndNo].endTime = _now.add(rndDevelopmentStage_).add(rndInfectiveReadyTime_);
                round_m[_rndNo].infectLastPlayer = msg.sender;
            }
            else
            {
                require (_keys >= 1 * 10 ** 19, "at least 10 thound people");
                round_m[_rndNo].endTime = _now + rndInfectiveStage_;
            }
            
            round_m[_rndNo].leader = msg.sender;

            // update playerRound
            playerRound_m[_rndNo][msg.sender].keys = _keys.add(playerRound_m[_rndNo][msg.sender].keys);
            playerRound_m[_rndNo][msg.sender].eth = _ethUse.add(playerRound_m[_rndNo][msg.sender].eth);

            // update round
            round_m[_rndNo].keys = _keys.add(round_m[_rndNo].keys);
            round_m[_rndNo].eth = _ethUse.add(round_m[_rndNo].eth);

            // update global variable
            totalEth = _ethUse.add(totalEth);

            // event
            emit PlagueEvents.onInfectiveStage
            (
                msg.sender,
                _rndNo,
                _keys,
                _ethUse,
                _now,
				_inveter
            );
        } else {
            // second stage
            require(round_m[_rndNo].infectiveEndTime < _now, "The virus is being prepared...");
            
            // increase 0.05 Ether every 3 hours
            _ethUse = (((_now.sub(round_m[_rndNo].infectiveEndTime)) / rndIncreaseTime_).mul(5 * 10 ** 16)).add((5 * 10 ** 16));
            
            require(_eth >= _ethUse, "Ether amount is wrong");
            
            if(_eth > _ethUse)
            {
                msg.sender.transfer(_eth.sub(_ethUse));
            }

            round_m[_rndNo].endTime = _now + rndDevelopmentStage_;
            round_m[_rndNo].leader = msg.sender;

            // update playerRound
            playerRound_m[_rndNo][msg.sender].eth = _ethUse.add(playerRound_m[_rndNo][msg.sender].eth);

            // update round
            round_m[_rndNo].eth = _ethUse.add(round_m[_rndNo].eth);

            // update global variable
            totalEth = _ethUse.add(totalEth);
            
            // update development award
            uint256 _exAwardPercent = ((_now.sub(round_m[_rndNo].infectiveEndTime)) / rndIncreaseTime_).mul(developmentAwardPercent).add(developmentAwardPercent);
            if(_exAwardPercent >= 410)
            {
                _exAwardPercent = 410;
            }
            round_m[_rndNo].exAward = (_exAwardPercent.mul(_ethUse) / 1000).add(round_m[_rndNo].exAward);

            // event
            emit PlagueEvents.onDevelopmentStage
            (
                msg.sender,
                _rndNo,
                _ethUse,
                _now,
				_inveter
            );
        }
        
        // caculate share inveter amount
        if(_inveter != address(0) && isHuman(_inveter)) 
        {
            playerRound_m[_rndNo][_inveter].getInveterAmount = playerRound_m[_rndNo][_inveter].getInveterAmount.add(_ethUse.mul(10) / 100);
            round_m[_rndNo].inveterAmount = round_m[_rndNo].inveterAmount.add(_ethUse.mul(10) / 100);
        }
        
        round_m[_rndNo].loseInfective[round_m[_rndNo].totalInfective % 4] = round_m[_rndNo].lastInfective[round_m[_rndNo].totalInfective % 11];
        round_m[_rndNo].lastInfective[round_m[_rndNo].totalInfective % 11] = msg.sender;
        
        round_m[_rndNo].totalInfective = round_m[_rndNo].totalInfective.add(1);
    }
    
	/**
	 * @dev recommend a player
	 */
    function buyKeyByAddr(address _inveter)
        onlyHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        require(isStartGame == true, "The game hasn&#39;t started yet.");
        buyKeys(_inveter);
    }

    /**
     * @dev play
     */
    function()
        onlyHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        require(isStartGame == true, "The game hasn&#39;t started yet.");
        buyKeys(address(0));
    }
    
    /**
     * @dev Award by rndNo.
     * 0x80ec35ff
     * 0x80ec35ff0000000000000000000000000000000000000000000000000000000000000001
     */
    function awardByRndNo(uint256 _rndNo)
        onlyHuman()
        public
    {
        require(isStartGame == true, "The game hasn&#39;t started yet.");
        require(_rndNo <= rndNo, "You&#39;re running too fast");
        
        uint256 _ethOut = 0;
        uint256 _totalAward = round_m[_rndNo].eth.mul(30) / 100;
        _totalAward = _totalAward.add(round_m[_rndNo].lastRoundReward);
        _totalAward = _totalAward.add(round_m[_rndNo].exAward);
        uint256 _getAward = 0;
        
        //withdraw award
        uint256 _totalWithdraw = round_m[_rndNo].eth.mul(51) / 100;
        _totalWithdraw = _totalWithdraw.sub(round_m[_rndNo].exAward);
        _totalWithdraw = (_totalWithdraw.mul(playerRound_m[_rndNo][msg.sender].keys));
        _totalWithdraw = _totalWithdraw / round_m[_rndNo].keys;
        
        uint256 _inveterAmount = playerRound_m[_rndNo][msg.sender].getInveterAmount;
        _totalWithdraw = _totalWithdraw.add(_inveterAmount);
        uint256 _withdrawed = playerRound_m[_rndNo][msg.sender].withdraw;
        if(_totalWithdraw > _withdrawed)
        {
            _ethOut = _ethOut.add(_totalWithdraw.sub(_withdrawed));
            playerRound_m[_rndNo][msg.sender].withdraw = _totalWithdraw;
        }
        
         //lastest infect player
        if(msg.sender == round_m[_rndNo].infectLastPlayer && round_m[_rndNo].infectLastPlayer != address(0) && round_m[_rndNo].infectiveEndTime != 0)
        {
            _getAward = _getAward.add(_totalAward.mul(10)/100);
        }
        
        if(now > round_m[_rndNo].endTime)
        {
            // finally award
            if(round_m[_rndNo].leader == msg.sender)
            {
                _getAward = _getAward.add(_totalAward.mul(60)/100);
            }
            
            //finally ten person award
            for(uint256 i = 0;i < round_m[_rndNo].lastInfective.length; i = i.add(1))
            {
                if(round_m[_rndNo].lastInfective[i] == msg.sender && (round_m[_rndNo].totalInfective.sub(1) % 11) != i){
                    if(round_m[_rndNo].infectiveAward_m[i])
                        continue;
                    if(round_m[_rndNo].infectLastPlayer != address(0))
                    {
                        _getAward = _getAward.add(_totalAward.mul(3)/100);
                    }
                    else{
                        _getAward = _getAward.add(_totalAward.mul(4)/100);
                    }
                        
                    round_m[_rndNo].infectiveAward_m[i] = true;
                }
            }
        }
        _ethOut = _ethOut.add(_getAward.sub(playerRound_m[_rndNo][msg.sender].hasGetAwardAmount));
        playerRound_m[_rndNo][msg.sender].hasGetAwardAmount = _getAward;
        
        if(_ethOut != 0)
        {
            msg.sender.transfer(_ethOut); 
        }
        
        // event
        emit PlagueEvents.onAward
        (
            msg.sender,
            _rndNo,
            _ethOut,
            now
        );
    }
    
    /**
     * @dev Get player bonus data
     * 0xd982466d
     * 0xd982466d0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000028f211f6c07d3b79e0aab886d56333e4027d4f59
     * @return player&#39;s award
     * @return player&#39;s can withdraw amount
     * @return player&#39;s inveter amount
     * @return player&#39;s has been withdraw
     */
    function getPlayerAwardByRndNo(uint256 _rndNo, address _playAddr)
        view
        public
        returns (uint256, uint256, uint256, uint256)
    {
        require(isStartGame == true, "The game hasn&#39;t started yet.");
        require(_rndNo <= rndNo, "You&#39;re running too fast");
        
        uint256 _ethPlayerAward = 0;
        
        //withdraw award
        uint256 _totalWithdraw = round_m[_rndNo].eth.mul(51) / 100;
        _totalWithdraw = _totalWithdraw.sub(round_m[_rndNo].exAward);
        _totalWithdraw = (_totalWithdraw.mul(playerRound_m[_rndNo][_playAddr].keys));
        _totalWithdraw = _totalWithdraw / round_m[_rndNo].keys;
        
        uint256 _totalAward = round_m[_rndNo].eth.mul(30) / 100;
        _totalAward = _totalAward.add(round_m[_rndNo].lastRoundReward);
        _totalAward = _totalAward.add(round_m[_rndNo].exAward);
        
        //lastest infect player
        if(_playAddr == round_m[_rndNo].infectLastPlayer && round_m[_rndNo].infectLastPlayer != address(0) && round_m[_rndNo].infectiveEndTime != 0)
        {
            _ethPlayerAward = _ethPlayerAward.add(_totalAward.mul(10)/100);
        }
        
        if(now > round_m[_rndNo].endTime)
        {
            // finally award
            if(round_m[_rndNo].leader == _playAddr)
            {
                _ethPlayerAward = _ethPlayerAward.add(_totalAward.mul(60)/100);
            }
            
            //finally ten person award
            for(uint256 i = 0;i < round_m[_rndNo].lastInfective.length; i = i.add(1))
            {
                if(round_m[_rndNo].lastInfective[i] == _playAddr && (round_m[_rndNo].totalInfective.sub(1) % 11) != i)
                {
                    if(round_m[_rndNo].infectLastPlayer != address(0))
                    {
                        _ethPlayerAward = _ethPlayerAward.add(_totalAward.mul(3)/100);
                    }
                    else{
                        _ethPlayerAward = _ethPlayerAward.add(_totalAward.mul(4)/100);
                    }
                }
            }
        }
        
        
        return
        (
            _ethPlayerAward,
            _totalWithdraw,
            playerRound_m[_rndNo][_playAddr].getInveterAmount,
            playerRound_m[_rndNo][_playAddr].hasGetAwardAmount + playerRound_m[_rndNo][_playAddr].withdraw
        );
    }
    
    /**
     * @dev fee withdraw to receiver, everyone can do it.
     * 0x6561e6ba
     */
    function feeWithdraw()
        onlyHuman()
        public 
    {
        require(isStartGame == true, "The game hasn&#39;t started yet.");
        require(receiver != address(0), "The receiver address has not been initialized.");
        
        uint256 _total = (totalEth.mul(5) / (100));
        uint256 _withdrawed = ownerWithdraw;
        require(_total > _withdrawed, "No need to withdraw");
        ownerWithdraw = _total;
        receiver.transfer(_total.sub(_withdrawed));
    }
    
    /**
     * @dev start game
     */
    function startGame()
        onlyOwner()
        public
    {
        round_m[1].startTime = now;
        round_m[1].endTime = now + rndInfectiveStage_;
        round_m[1].lastRoundReward = 0;
        isStartGame = true;
    }

    /**
     * @dev change owner.
     */
    function changeReceiver(address newReceiver)
        onlyOwner()
        public
    {
        receiver = newReceiver;
    }

    /**
     * @dev returns all current round info needed for front end
     * 0x747dff42
     */
    function getCurrentRoundInfo()
        public 
        view 
        returns(uint256, uint256[2], uint256[3], address[2], uint256[6], address[11],address[4])
    {
        require(isStartGame == true, "The game hasn&#39;t started yet.");
        uint256 _rndNo = rndNo;
        uint256 _totalAwardAtRound = round_m[_rndNo].lastRoundReward.add(round_m[_rndNo].exAward).add(round_m[_rndNo].eth.mul(30) / 100);
        
        return (
            _rndNo,
            [round_m[_rndNo].eth, round_m[_rndNo].keys],
            [round_m[_rndNo].startTime, round_m[_rndNo].endTime, round_m[_rndNo].infectiveEndTime],
            [round_m[_rndNo].leader, round_m[_rndNo].infectLastPlayer],
            [getBuyPrice(), round_m[_rndNo].lastRoundReward, _totalAwardAtRound, round_m[_rndNo].inveterAmount, round_m[_rndNo].totalInfective % 11, round_m[_rndNo].exAward],
            round_m[_rndNo].lastInfective,
            round_m[_rndNo].loseInfective
        );
    }

    /**
     * @dev return the price buyer will pay for next 1 individual key during first stage.
     * 0x018a25e8
     * @return price for next key bought (in wei format)
     */
    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {
        require(isStartGame == true, "The game hasn&#39;t started yet.");
        uint256 _rndNo = rndNo;
        uint256 _now = now;
        
        // start next round?
        if (_now > round_m[_rndNo].endTime)
        {
            return (750007031250000);
        }
        if (round_m[_rndNo].keys < allKeys_)
        {
            return ((round_m[_rndNo].keys.add(10000000000000000000)).ethRec(10000000000000000000));
        }
        if(round_m[_rndNo].keys >= allKeys_ && 
            round_m[_rndNo].infectiveEndTime != 0 && 
            round_m[_rndNo].infectLastPlayer != address(0) &&
            _now < round_m[_rndNo].infectiveEndTime)
        {
            return 5 * 10 ** 16;
        }
        if(round_m[_rndNo].keys >= allKeys_ && _now > round_m[_rndNo].infectiveEndTime)
        {
            // increase 0.05 Ether every 3 hours
            uint256 currentPrice = (((_now.sub(round_m[_rndNo].infectiveEndTime)) / rndIncreaseTime_).mul(5 * 10 ** 16)).add((5 * 10 ** 16));
            return currentPrice;
        }
        //second stage
        return (0);
    }
}

library KeysCalc {
    using SafeMath for *;
    /**
     * @dev calculates number of keys received given X eth 
     * @param _curEth current amount of eth in contract 
     * @param _newEth eth being spent
     * @return amount of ticket purchased
     */
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }
    
    /**
     * @dev calculates amount of eth received if you sold X keys 
     * @param _curKeys current amount of keys that exist 
     * @param _sellKeys amount of keys you wish to sell
     * @return amount of eth received
     */
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    /**
     * @dev calculates how many keys would exist with given an amount of eth
     * @param _eth eth "in contract"
     * @return number of keys that would exist
     */
    function keys(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(312500000000000000000000000)).add(5624988281256103515625000000000000000000000000000000000000000000)).sqrt()).sub(74999921875000000000000000000000)) / (156250000);
    }
    
    /**
     * @dev calculates how much eth would be in contract given a number of keys
     * @param _keys number of keys "in contract" 
     * @return eth that would exists
     */
    function eth(uint256 _keys) 
        internal
        pure
        returns(uint256)  
    {
        return ((78125000).mul(_keys.sq()).add(((149999843750000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}