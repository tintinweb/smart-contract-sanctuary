pragma solidity ^0.4.24;

// File: contracts/library/SafeMath.sol

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
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
            for (uint256 i = 1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

// File: contracts/Lottery.sol

// import "./interface/QMGCoinInterface.sol";

contract Lottery {
    using SafeMath for *;

    // QMGCoinInterface constant private QMECoin = QMGCoinInterface(0x32140ee94f2a1C3232C91BE55f26ee89B8693546);

    address public owner_;

    uint256 public investmentBalance_;
    uint256 public developerBalance_;
    uint256 public topBonus500Balance_;

    uint256 public jackpotSplit = 50;                // % of buy in thats add to jackpot this round
    uint256 public nextJackpotSplit = 15;            // % of buy in thats add to jackpot next round
    uint256 public bonus500Split = 5;               // % of buy in thats paid to first 500 players
    uint256 public investorDividendSplit = 10;       // % of buy in thats paid to investors
    uint256 public developerDividendSplit = 10;      // % of buy in thats paid to developers
    uint256 public referrerDividendSplit = 10;       // % of buy in thats paid to referrer
    uint256[6] public jpSplit_ = [0, 50, 25, 12, 8, 5]; // % of jackpot in thats paid to each class prize

    uint256 public rID_;

    uint256 public jackpotBalance_;
    uint256 public jackpotNextBalance_;
    uint256 public jackpotLeftBalance_;

    uint256 public kID_;
    struct Key {
        uint key;
        uint tID;    // team id
        uint pID;    // player id
    }

    mapping(uint256 => Key) public keys_;   // (kID_ => data) key data

    uint256[500] public topPlayers_;    // first 500 players each round
    uint256 public tpID_;

    struct WonNum {
        uint256 blockNum;
        uint256 last6Num;
    }
    mapping(uint256 => WonNum) wonNums_;    // (rID_ => wonNum)

    bool public roundEnded_;

    uint256 public pID_;
    mapping (address => uint256) public pIDxAddr_;      // (addr => pID) returns player id by address
    mapping (uint256 => Player ) public plyr_;          // (pID => data) player data

    struct Player {
        address addr;
        uint256 referrerID;
        uint256 playedNum;
        uint256 referralsNum;
        uint256 teamBonus;
        uint256 referralsBonus;
        uint256 winPrize;
        uint256 accountBalance;
    }

    mapping (uint256 => mapping(uint256 => uint256[])) public histories_;      // (pID => rID => keys)

    uint[4] public teamNums_;

    event Transfer(address indexed from, address indexed to, uint value);
    event RoundEnd(address indexed from, address indexed to, uint value);
    event BuyAKeyWithEth(address indexed from, uint key, uint teamID);
    event BuyAKeyWithBalance(address indexed from, uint key, uint teamID);
    event WithdrawBalance(address indexed to, uint amount);
    event AddToInvestmentBalance(uint amount);
    event AddReferrerBalance(address indexed to, uint amount);
    event AddTeamBonusBalance(address indexed to, uint amount);
    event AddPrizeBalance(address indexed to, uint amount);

    constructor()
        public
    {
        owner_ = msg.sender;

        rID_ = 0;

        investmentBalance_ = 0;

        developerBalance_ = 0;

        plyr_[0].addr = 0x1F8ADEA9E727d334d34BD757E59b8B9B466E7251;
        plyr_[0].referrerID = 0;
        plyr_[0].playedNum = 0;
        plyr_[0].referralsNum = 0;
        plyr_[0].teamBonus = 0;
        plyr_[0].referralsBonus = 0;
        plyr_[0].winPrize = 0;
        plyr_[0].accountBalance = 0;

        pID_ = 1;
        teamNums_ = [0, 0, 0, 0];
    }

    modifier onlyOwner
    {
        require(msg.sender == owner_, "msg sender is not contract owner");
        _;
    }

    /* administrative functions */

    function roundStart ()
        public
        onlyOwner()
    {
        tpID_ = 0;

        kID_ = 1;

        rID_++;

        // init jackpot of new round
        jackpotBalance_ = (jackpotNextBalance_).add(jackpotLeftBalance_);
        jackpotNextBalance_ = 0;

        if (jackpotBalance_ > 10000000000000000000000) {
            jackpotBalance_ = (jackpotBalance_).sub(3000000000000000000000);
            investmentBalance_ = (investmentBalance_).add(3000000000000000000000);
            emit AddToInvestmentBalance(3000000000000000000000);
        }

        delete teamNums_;

        // reset top 500 players
        tpID_ = 0;

        roundEnded_ = false;
    }

    function roundEnd ()
        public
        onlyOwner()
    {
        roundEnded_ = true;
    }

    function pay(address _to, uint _amount) private {
        _to.transfer(_amount);
        emit Transfer(owner_, _to, _amount);
    }

    function changeIncomesSplits (uint _jkpt, uint _nxtjkpt, uint bns500, uint invst, uint dev, uint ref)
        public
        onlyOwner()
    {
        require(_jkpt > 0 && _nxtjkpt > 0 && bns500 > 0 && invst > 0 && dev > 0 && ref > 0, "split must more than 0");
        require((_jkpt + _nxtjkpt + bns500 + invst + dev + ref) <= 100, "sum splits must lte 100 ");

        jackpotSplit = _jkpt;
        nextJackpotSplit = _nxtjkpt;
        bonus500Split = bns500;
        investorDividendSplit = invst;
        developerDividendSplit = dev;
        referrerDividendSplit = ref;
    }

    function changePrizeSplits (uint c1, uint c2, uint c3, uint c4, uint c5)
        public
        onlyOwner()
    {
        require(c1 > 0 && c2 > 0 && c3 > 0 && c4 > 0 && c5 > 0, "split must more than 0");
        require((c1 + c2 + c3 + c4 + c5) <= 100, "sum splits must lte 100 ");
        jpSplit_ = [c1, c2, c3, c4, c5];
    }

    function createPlayer(address _addr, address _referrer)
        private
        returns (uint)
    {
        plyr_[pID_].addr = _addr;
        plyr_[pID_].playedNum = 0;
        plyr_[pID_].referralsNum = 0;
        plyr_[pID_].winPrize = 0;
        pIDxAddr_[_addr] = pID_;

        uint256 referrerID = getPlayerID(_referrer);
        if (referrerID != 0) {
            if (getPlayerPlayedTimes(referrerID) > 0) {
                plyr_[pID_].referrerID = referrerID;
                plyr_[referrerID].referralsNum ++;
            }
        }
        uint pID = pID_;
        pID_ ++;
        return pID;
    }

    function updatePlayedNum(address _addr, address _referrer, uint256 _key)
        private
        returns (uint)
    {
        uint plyrID = getPlayerID(_addr);
        if (plyrID == 0) {
            plyrID = createPlayer(_addr, _referrer);
        }

        plyr_[plyrID].playedNum += 1;
        histories_[plyrID][rID_].push(_key);
        return (plyrID);
    }

    function addRefBalance(address _addr, uint256 _val)
        private
        returns (uint256)
    {
        uint plyrID = getPlayerID(_addr);

        require(plyrID > 0, "Player should have played before");

        plyr_[plyrID].referralsBonus = (plyr_[plyrID].referralsBonus).add(_val);
        plyr_[plyrID].accountBalance = (plyr_[plyrID].accountBalance).add(_val);
        emit AddReferrerBalance(plyr_[plyrID].addr, _val);

        return (plyr_[plyrID].accountBalance);
    }

    function addBalance(uint _pID, uint256 _prizeVal, uint256 _teamVal)
        public
        onlyOwner()
        returns(uint256)
    {

        require(_pID > 0, "Player should have played before");

        uint256 refPlayedNum = getPlayerPlayedTimes(plyr_[_pID].referrerID);

        if (refPlayedNum > 0) {
            plyr_[plyr_[_pID].referrerID].referralsBonus = (plyr_[plyr_[_pID].referrerID].referralsBonus).add(_prizeVal / 10);
            plyr_[plyr_[_pID].referrerID].accountBalance = (plyr_[plyr_[_pID].referrerID].accountBalance).add(_prizeVal / 10);

            plyr_[_pID].winPrize = (plyr_[_pID].winPrize).add((_prizeVal).mul(9) / 10);
            plyr_[_pID].accountBalance = (plyr_[_pID].accountBalance).add((_prizeVal).mul(9) / 10);
        } else {
            plyr_[_pID].winPrize = (plyr_[_pID].winPrize).add(_prizeVal);
            plyr_[_pID].accountBalance = (plyr_[_pID].accountBalance).add(_prizeVal);
        }
        emit AddPrizeBalance(plyr_[_pID].addr, _prizeVal);

        plyr_[_pID].teamBonus = (plyr_[_pID].teamBonus).add(_teamVal);
        plyr_[_pID].accountBalance = (plyr_[_pID].accountBalance).add(_teamVal);
        emit AddTeamBonusBalance(plyr_[_pID].addr, _teamVal);

        return (plyr_[_pID].accountBalance);
    }

    function subAccountBalance(address _addr, uint256 _val)
        private
        returns(uint256)
    {
        uint plyrID = getPlayerID(_addr);
        require(plyr_[plyrID].accountBalance >= _val, "Account should have enough value");

        plyr_[plyrID].accountBalance = (plyr_[plyrID].accountBalance).sub(_val);
        return (plyr_[plyrID].accountBalance);
    }

    function withdrawBalance()
        public
        returns(uint256)
    {
        uint plyrID = getPlayerID(msg.sender);
        require(plyr_[plyrID].accountBalance >= 10000000000000000, "Account should have more than 0.01 eth");

        uint256 transferAmount = plyr_[plyrID].accountBalance;
        pay(msg.sender, transferAmount);
        plyr_[plyrID].accountBalance = 0;
        emit WithdrawBalance(msg.sender, transferAmount);
        return (plyr_[plyrID].accountBalance);
    }


    function changeOwner (address _to)
        public
        onlyOwner()
    {
        owner_ = _to;
    }

    function gameDestroy()
        public
        onlyOwner()
    {
        uint prize = jackpotBalance_ / pID_;
        for (uint i = 0; i < pID_; i ++) {
            pay(plyr_[i].addr, prize);
        }
    }

    function updateWonNums (uint256 _blockNum, uint256 _last6Num)
        public
        onlyOwner()
    {
        wonNums_[rID_].blockNum = _blockNum;
        wonNums_[rID_].last6Num = _last6Num;
    }

    function updateJackpotLeft (uint256 _jackpotLeft)
        public
        onlyOwner()
    {
        jackpotLeftBalance_ = _jackpotLeft;
    }

    function transferDividendBalance (address _to, uint _val)
        public
        onlyOwner()
    {
        require(_val > 10000000000000000, "Value must more than 0.01 eth");
        require(investmentBalance_ >= _val, "No more balance left");
        pay(_to, _val);
        investmentBalance_ = (investmentBalance_).sub(_val);
    }

    function transferDevBalance (address _to, uint _val)
        public
        onlyOwner()
    {
        require(_val > 10000000000000000, "Value must more than 0.01 eth");
        require(developerBalance_ >= _val, "No more balance left");
        pay(_to, _val);
        developerBalance_ = (developerBalance_).sub(_val);
    }

    /* public functions */

    function buyAKeyWithDeposit(uint256 _key, address _referrer, uint256 _teamID)
        public
        payable
        returns (bool)
    {
        require(msg.value > 10000000000000000, "Value must more than 0.01 eth");

        if (roundEnded_) {
            pay(msg.sender, msg.value);
            emit RoundEnd(address(this), msg.sender, msg.value);
            return(false);
        }

        jackpotBalance_ = (jackpotBalance_).add((msg.value).mul(jackpotSplit) / 100);
        jackpotNextBalance_ = (jackpotNextBalance_).add((msg.value).mul(nextJackpotSplit) / 100);
        investmentBalance_ = (investmentBalance_).add((msg.value).mul(investorDividendSplit) / 100);
        developerBalance_ = (developerBalance_).add((msg.value).mul(developerDividendSplit) / 100);
        topBonus500Balance_ = (topBonus500Balance_).add((msg.value).mul(bonus500Split) / 100);

        if (determinReferrer(_referrer)) {
            addRefBalance(_referrer, (msg.value).mul(referrerDividendSplit) / 100);
        } else {
            developerBalance_ = (developerBalance_).add((msg.value).mul(referrerDividendSplit) / 100);
        }

        uint pID = updatePlayedNum(msg.sender, _referrer, _key);

        keys_[kID_].key = _key;
        keys_[kID_].tID = _teamID;
        keys_[kID_].pID = pID;

        teamNums_[_teamID] ++;
        kID_ ++;

        if (tpID_ < 500) {
            topPlayers_[tpID_] = pID;
            tpID_ ++;
        }
        emit BuyAKeyWithEth(msg.sender, _key, _teamID);
        return (true);
    }

    function buyAKeyWithAmount(uint256 _key, address _referrer, uint256 _teamID)
        public
        payable
        returns (bool)
    {
        uint accBalance = getPlayerAccountBalance(msg.sender);
        if (roundEnded_) {
            emit RoundEnd(address(this), msg.sender, msg.value);
            return(false);
        }

        uint keyPrice = 10000000000000000;

        require(accBalance > keyPrice, "Account left balance should more than 0.01 eth");

        subAccountBalance(msg.sender, keyPrice);

        jackpotBalance_ = (jackpotBalance_).add((keyPrice).mul(jackpotSplit) / 100);
        jackpotNextBalance_ = (jackpotNextBalance_).add((keyPrice).mul(nextJackpotSplit) / 100);
        investmentBalance_ = (investmentBalance_).add((keyPrice).mul(investorDividendSplit) / 100);
        developerBalance_ = (developerBalance_).add((keyPrice).mul(developerDividendSplit) / 100);
        topBonus500Balance_ = (topBonus500Balance_).add((keyPrice).mul(bonus500Split) / 100);

        if (determinReferrer(_referrer)) {
            addRefBalance(_referrer, (keyPrice).mul(referrerDividendSplit) / 100);
        } else {
            developerBalance_ = (developerBalance_).add((keyPrice).mul(referrerDividendSplit) / 100);
        }

        uint pID = updatePlayedNum(msg.sender, _referrer, _key);

        keys_[kID_].key = _key;
        keys_[kID_].tID = _teamID;
        keys_[kID_].pID = pID;

        teamNums_[_teamID] ++;
        kID_ ++;

        if (tpID_ < 500) {
            topPlayers_[tpID_] = pID;
            tpID_ ++;
        }
        emit BuyAKeyWithBalance(msg.sender, _key, _teamID);
        return (true);
    }

    function showRoundNum () public view returns(uint256) { return rID_;}
    function showJackpotThisRd () public view returns(uint256) { return jackpotBalance_;}
    function showJackpotNextRd () public view returns(uint256) { return jackpotNextBalance_;}
    function showInvestBalance () public view returns(uint256) { return investmentBalance_;}
    function showDevBalance () public view returns(uint256) { return developerBalance_;}
    function showTopBonusBalance () public view returns(uint256) { return topBonus500Balance_;}
    function showTopsPlayer () external view returns(uint256[500]) { return topPlayers_; }
    function getTeamPlayersNum () public view returns (uint[4]) { return teamNums_; }
    function getPlayerID(address _addr)  public  view returns(uint256) { return (pIDxAddr_[_addr]); }
    function getPlayerPlayedTimes(uint256 _plyrID) public view returns (uint256) { return (plyr_[_plyrID].playedNum); }
    function getPlayerReferrerID(uint256 _plyrID) public view returns (uint256) { return (plyr_[_plyrID].referrerID); }
    function showKeys(uint _index) public view returns(uint256, uint256, uint256, uint256) {
        return (kID_, keys_[_index].key, keys_[_index].pID, keys_[_index].tID);
    }
    function showRdWonNum (uint256 _rID) public view returns(uint256[2]) {
        uint256[2] memory res;
        res[0] = wonNums_[_rID].blockNum;
        res[1] = wonNums_[_rID].last6Num;
        return (res);
    }
    function determinReferrer(address _addr) public view returns (bool)
    {
        uint256 pID = getPlayerID(_addr);
        uint256 playedNum = getPlayerPlayedTimes(pID);
        return (playedNum > 0);
    }
    function getReferrerAddr (address _addr) public view returns (address)
    {
        uint pID = getPlayerID(_addr);
        uint refID = plyr_[pID].referrerID;
        if (determinReferrer(plyr_[refID].addr)) {
            return plyr_[refID].addr;
        } else {
            return (0x0);
        }
    }
    function getPlayerAccountBalance (address _addr)  public view returns (uint)
    {
        uint plyrID = getPlayerID(_addr);
        return (plyr_[plyrID].accountBalance);
    }
    function getPlayerHistories (address _addr, uint256 _rID) public  view returns (uint256[])
    {
        uint plyrID = getPlayerID(_addr);

        return (histories_[plyrID][_rID]);
    }
}