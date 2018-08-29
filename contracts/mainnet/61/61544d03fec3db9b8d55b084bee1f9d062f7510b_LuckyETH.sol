pragma solidity ^0.4.24;
/** title -LuckyETH- v0.1.0
* ┌┬┐┌─┐┌─┐┌┬┐  ╦    ╦  ┌─┐┬─┐┌─┐┌─┐┌─┐┌┐┌┌┬┐┌─┐ 
*  │ ├┤ ├─┤│││   ║  ║   ├─┘├┬┘├┤ └─┐├┤ │││ │ └─┐
*  ┴ └─┘┴ ┴┴ ┴    ╚╝    ┴  ┴└─└─┘└─┘└─┘┘└┘ ┴ └─┘  
*/

//==============================================================================
//     _    _  _ _|_ _  .
//    (/_\/(/_| | | _\  .
//==============================================================================
contract LuckyEvents {
    // fired at end of buy
    event onEndTx
    (
        address player,
        uint256 playerID,
        uint256 ethIn,
        address wonAddress,
        uint256 wonAmount,          // amount won
        uint256 genAmount,          // amount distributed to gen
        uint256 airAmount          // amount added to airdrop
    );
    
	// fired whenever theres a withdraw
    event onWithdraw
    (
        uint256 indexed playerID,
        address playerAddress,
        uint256 ethOut,
        uint256 timeStamp
    );
}

//==============================================================================
//   __|_ _    __|_ _  .
//  _\ | | |_|(_ | _\  .
//==============================================================================
library LuckyDatasets {
    struct EventReturns {
        address player;
        uint256 playerID;
        uint256 ethIn;
        address wonAddress;         // address won
        uint256 wonAmount;          // amount won
        uint256 genAmount;          // amount distributed to gen
        uint256 airAmount;          // amount added to airdrop
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract LuckyETH is LuckyEvents, Ownable  {
    using SafeMath for *;
    
//==============================================================================
//     _ _  _  |`. _     _ _ |_ | _  _  .
//    (_(_)| |~|~|(_||_|| (_||_)|(/__\  .  (game settings)
//=================_|===========================================================
    string constant public name = "Lucky ETH";
    string constant public symbol = "L";
//****************
// Pot DATA 
//****************
    uint256 public pIndex; // the index for next player
//==============================================================================
//     _| _ _|_ _    _ _ _|_    _   .
//    (_|(_| | (_|  _\(/_ | |_||_)  .  (data used to store distributed info that changes)
//=============================|================================================
	uint256 public genPot_;             // distributed pot for all players
//==============================================================================
//     _| _ _|_ _    _ _ _|_    _   .
//    (_|(_| | (_|  _\(/_ | |_||_)  .  (data used to store airdrop info that changes)
//=============================|================================================
	uint256 public airDropPot_;             // person who gets the airdrop wins part of this pot
    uint256 public airDropTracker_ = 0;     // incremented each time a "qualified" tx occurs.  used to determine winning air drop
//****************
// PLAYER DATA 
//****************
    mapping (address => uint256) public pIDxAddr_;          // (addr => pID) returns player id by address
    mapping (address => address) public pAff_;              // (addr => affAddr)
//****************
// TEAM FEE DATA 
//****************
    // TeamV act as player
    address public teamV;
//==============================================================================
//     _ _  _  __|_ _    __|_ _  _  .
//    (_(_)| |_\ | | |_|(_ | (_)|   .  (initial data setup upon contract deploy)
//==============================================================================
    constructor()
        public
    {
        // player id start from 1
        pIndex = 1;
	}

//==============================================================================
//     _ _  _  _|. |`. _  _ _  .
//    | | |(_)(_||~|~|(/_| _\  .  (these are safety checks)
//==============================================================================
    /**
     * @dev prevents contracts from interacting with fomo3d 
     */
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin);
        
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx 
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency"); /** 1Gwei **/
        require(_eth <= 100000000000000000000000, "no vitalik, no");    /** 1 KEth **/
		_;    
	}
	
//==============================================================================
//     _    |_ |. _   |`    _  __|_. _  _  _  .
//    |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  .  (use these to interact with contract)
//====|=========================================================================

    function ()
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        address _affAddr = address(0);
        if (pAff_[msg.sender] != address(0)) {
            _affAddr = pAff_[msg.sender];
        }
        core(msg.sender, msg.value, _affAddr);
    }
    
    /**
     * @dev converts all incoming ethereum to keys.
     * -functionhash- 0x98a0871d (using address for affiliate)
     * @param _affAddr the address of the player who gets the affiliate fee
     */
    function buy(address _affAddr)
        isHuman()
        isWithinLimits(msg.value)
        public
        payable
    {
        if (_affAddr == address(0)) {
            _affAddr = pAff_[msg.sender];
        } else {
            pAff_[msg.sender] = _affAddr;
        }
        core(msg.sender, msg.value, _affAddr);
    }
    
    /**
     * @dev withdraws all of your earnings.
     * -functionhash- 0x3ccfd60b
     */
    function withdraw()
        isHuman()
        public
    {
       playerWithdraw(msg.sender);
    }
    
    /**
     * @dev updateTeamV withdraw and buy
     */
    function updateTeamV(address _team)
        onlyOwner()
        public
    {
        if (teamV != address(0)) {
           playerWithdraw(teamV);
        }
        core(_team, 0, address(0));
        teamV = _team;
    }
    
    /**
     * @dev this is the core logic for any buy
     * is live.
     */
    function core(address _pAddr, uint256 _eth, address _affAddr)
        private
    {
        // set up our tx event data
        LuckyDatasets.EventReturns memory _eventData_;
        _eventData_.player = _pAddr;
        
        uint256 _pID =  pIDxAddr_[_pAddr];
        if (_pID == 0) {
            _pID = pIndex;
            pIndex = pIndex.add(1);
            pIDxAddr_[_pAddr] = _pID;
        }
         _eventData_.playerID = _pID;
         _eventData_.ethIn = _eth;
        
        // manage airdrops
        if (_eth >= 100000000000000000)
        {
            airDropTracker_++;
            if (airdrop() == true)
            {
                // gib muni
                uint256 _prize = 0;
                if (_eth >= 10000000000000000000)
                {
                    // calculate prize
                    _prize = ((airDropPot_).mul(75)) / 100;
                } else if (_eth >= 1000000000000000000 && _eth < 10000000000000000000) {
                    // calculate prize
                    _prize = ((airDropPot_).mul(50)) / 100;
                } else if (_eth >= 100000000000000000 && _eth < 1000000000000000000) {
                    // calculate prize
                    _prize = ((airDropPot_).mul(25)) / 100;
                }
                
                // adjust airDropPot 
                airDropPot_ = (airDropPot_).sub(_prize);
                    
                // give prize to winner
                _pAddr.transfer(_prize);
                    
                // set airdrop happened bool to true
                _eventData_.wonAddress = _pAddr;
                // let event know how much was won 
                _eventData_.wonAmount = _prize;
                
                
                // reset air drop tracker
                airDropTracker_ = 0;
            }
        }
        
        // 20% for affiliate share fee
        uint256 _aff = _eth / 5;
        // 30% for _distributed rewards
        uint256 _gen = _eth.mul(30) / 100;
        // 50% for pot
        uint256 _airDrop = _eth.sub(_aff.add(_gen));
       
        // distributeExternal
        uint256 _affID = pIDxAddr_[_affAddr];
        if (_affID != 0 && _affID != _pID) {
            _affAddr.transfer(_aff);
        } else {
            _airDrop = _airDrop.add(_aff);
        }

        airDropPot_ = airDropPot_.add(_airDrop);
        genPot_ = genPot_.add(_gen);

        // set up event data
        _eventData_.genAmount = _gen;
        _eventData_.airAmount = _airDrop;

        // call end tx function to fire end tx event.
        endTx(_eventData_);
    }
    
    function airdrop()
        private 
        view 
        returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        if((seed - ((seed / 1000) * 1000)) <= airDropTracker_)
            return(true);
        else
            return(false);
    }
    
    /**
     * @dev prepares compression data and fires event for buy or reload tx&#39;s
     */
    function endTx(LuckyDatasets.EventReturns memory _eventData_)
        private
    {
        emit LuckyEvents.onEndTx
        (
            _eventData_.player,
            _eventData_.playerID,
            _eventData_.ethIn,
            _eventData_.wonAddress,
            _eventData_.wonAmount,
            _eventData_.genAmount,
            _eventData_.airAmount
        );
    }
    
      /**
     * @dev withdraws all of your earnings.
     * -functionhash- 0x3ccfd60b
     */
    function playerWithdraw(address _pAddr)
        private
    {
        // grab time
        uint256 _now = now;
        
        // player 
        uint256 _pID =  pIDxAddr_[_pAddr];
        require(_pID != 0, "no, no, no...");
        delete(pIDxAddr_[_pAddr]);
        delete(pAff_[_pAddr]);
        pIDxAddr_[_pAddr] = 0; // oh~~
        
         // set up our tx event data
        LuckyDatasets.EventReturns memory _eventData_;
        _eventData_.player = _pAddr;
        
        // setup local rID
        uint256 _pIndex = pIndex;
        uint256 _gen = genPot_;
        uint256 _sum = _pIndex.mul(_pIndex.sub(1)) / 2;
        uint256 _percent = _pIndex.sub(1).sub(_pID);
        assert(_percent < _pIndex);
        _percent = _gen.mul(_percent) / _sum;
        
        genPot_ = genPot_.sub(_percent);
        _pAddr.transfer(_percent);
        
        
        // fire withdraw event
        emit LuckyEvents.onWithdraw(_pID, _pAddr, _percent, _now);
        
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