pragma solidity ^0.4.0;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Greedy is Owned {
    //A scam Game, 资金盘, 老鼠會, Ponzi scheme.
    //The Game like Fomo3D, But more simple and more short time.
    //Audit & be responsible for yourself.
    //The code is really simple, so don&#39;t ask idiot question.
    
    //Round Global Info
    uint public Round = 1;
    mapping(uint => uint) public RoundHeart;
    mapping(uint => uint) public RoundETH; // Pot
    mapping(uint => uint) public RoundTime;
    mapping(uint => uint) public RoundPayMask;
    mapping(uint => address) public RoundLastGreedyMan;
    
    //Globalinfo
    uint256 public Luckybuy;
    
    //Round Personal Info
    mapping(uint => mapping(address => uint)) public RoundMyHeart;
    mapping(uint => mapping(address => uint)) public RoundMyPayMask;
    mapping(address => uint) public MyreferredRevenue;
    
    //Lucky Buy Tracker
    uint256 public luckybuyTracker_ = 0;
    
    uint256 constant private RoundIncrease = 1 seconds; // every heart purchased adds this much to the timer
    uint256 constant private RoundMaxTime = 10 minutes; // max length a round timer can be
    
    //Owner fee
    uint256 public onwerfee;
    
    using SafeMath for *;
    using GreedyHeartCalcLong for uint256;
    
    event winnerEvent(address winnerAddr, uint256 newPot, uint256 round);
    event luckybuyEvent(address luckyAddr, uint256 amount, uint256 round);
    event buyheartEvent(address Addr, uint256 Heartamount, uint256 ethvalue, uint256 round, address ref);
    event referredEvent(address Addr, address RefAddr, uint256 ethvalue);
    
    event withdrawEvent(address Addr, uint256 ethvalue, uint256 Round);
    event withdrawRefEvent(address Addr, uint256 ethvalue);
    event withdrawOwnerEvent(uint256 ethvalue);

    //Get Heart Price
    function getHeartPrice() public view returns(uint256)
    {  
        return ( (RoundHeart[Round].add(1000000000000000000)).ethRec(1000000000000000000) );
    }
    
    //Get My Revenue
    function getMyRevenue(uint _round) public view returns(uint256)
    {
        return(  (((RoundPayMask[_round]).mul(RoundMyHeart[_round][msg.sender])) / (1000000000000000000)).sub(RoundMyPayMask[_round][msg.sender])  );
    }
    
    //Get Time Left
    function getTimeLeft() public view returns(uint256)
    {
        if(RoundTime[Round] == 0 || RoundTime[Round] < now) 
            return 0;
        else 
            return( (RoundTime[Round]).sub(now) );
    }

    function updateTimer(uint256 _hearts) private
    {
        if(RoundTime[Round] == 0)
            RoundTime[Round] = RoundMaxTime.add(now);
        
        uint _newTime = (((_hearts) / (1000000000000000000)).mul(RoundIncrease)).add(RoundTime[Round]);
        
        // compare to max and set new end time
        if (_newTime < (RoundMaxTime).add(now))
            RoundTime[Round] = _newTime;
        else
            RoundTime[Round] = RoundMaxTime.add(now);
    }

    //Buy some greedy heart
    function buyHeart(address referred) public payable {
        
        require(msg.value >= 1000000000, "pocket lint: not a valid currency");
        require(msg.value <= 100000000000000000000000, "no vitalik, no");
        
        address _addr = msg.sender;
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");

        //bought at least 1 whole key
        uint256 _hearts = (RoundETH[Round]).keysRec(msg.value);
        uint256 _pearn;
        require(_hearts >= 1000000000000000000);
        
        require(RoundTime[Round] > now || RoundTime[Round] == 0);
        
        updateTimer(_hearts);
        
        RoundHeart[Round] += _hearts;
        RoundMyHeart[Round][msg.sender] += _hearts;

        if (referred != address(0) && referred != msg.sender)
        {
             _pearn = (((msg.value.mul(30) / 100).mul(1000000000000000000)) / (RoundHeart[Round])).mul(_hearts)/ (1000000000000000000);

            onwerfee += (msg.value.mul(4) / 100);
            RoundETH[Round] += msg.value.mul(54) / 100;
            Luckybuy += msg.value.mul(2) / 100;
            MyreferredRevenue[referred] += (msg.value.mul(10) / 100);
            
            RoundPayMask[Round] += ((msg.value.mul(30) / 100).mul(1000000000000000000)) / (RoundHeart[Round]);
            RoundMyPayMask[Round][msg.sender] = (((RoundPayMask[Round].mul(_hearts)) / (1000000000000000000)).sub(_pearn)).add(RoundMyPayMask[Round][msg.sender]);

            emit referredEvent(msg.sender, referred, msg.value.mul(10) / 100);
        } else {
             _pearn = (((msg.value.mul(40) / 100).mul(1000000000000000000)) / (RoundHeart[Round])).mul(_hearts)/ (1000000000000000000);

            RoundETH[Round] += msg.value.mul(54) / 100;
            Luckybuy += msg.value.mul(2) / 100;
            onwerfee +=(msg.value.mul(4) / 100);
            
            RoundPayMask[Round] += ((msg.value.mul(40) / 100).mul(1000000000000000000)) / (RoundHeart[Round]);
            RoundMyPayMask[Round][msg.sender] = (((RoundPayMask[Round].mul(_hearts)) / (1000000000000000000)).sub(_pearn)).add(RoundMyPayMask[Round][msg.sender]);

        }
        
        // manage airdrops
        if (msg.value >= 100000000000000000){
            luckybuyTracker_++;
            if (luckyBuy() == true)
            {
                msg.sender.transfer(Luckybuy);
                emit luckybuyEvent(msg.sender, Luckybuy, Round);
                luckybuyTracker_ = 0;
                Luckybuy = 0;
            }
        }
        
        RoundLastGreedyMan[Round] = msg.sender;
        emit buyheartEvent(msg.sender, _hearts, msg.value, Round, referred);
    }
    
    function win() public {
        require(now > RoundTime[Round] && RoundTime[Round] != 0);
        //Round End 
        RoundLastGreedyMan[Round].transfer(RoundETH[Round]);
        emit winnerEvent(RoundLastGreedyMan[Round], RoundETH[Round], Round);
        Round++;
    }
    
    //withdrawEarnings
    function withdraw(uint _round) public {
        uint _revenue = getMyRevenue(_round);
        uint _revenueRef = MyreferredRevenue[msg.sender];

        RoundMyPayMask[_round][msg.sender] += _revenue;
        MyreferredRevenue[msg.sender] = 0;
        
        msg.sender.transfer(_revenue + _revenueRef); 
        
        emit withdrawRefEvent( msg.sender, _revenue);
        emit withdrawEvent(msg.sender, _revenue, _round);
    }
    
    function withdrawOwner()  public onlyOwner {
        uint _revenue = onwerfee;
        msg.sender.transfer(_revenue);    
        onwerfee = 0;
        emit withdrawOwnerEvent(_revenue);
    }
    
    //LuckyBuy
    function luckyBuy() private view returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        
        if((seed - ((seed / 1000) * 1000)) < luckybuyTracker_)
            return(true);
        else
            return(false);
    }
    
    function getFullround()public view returns(uint[] round,uint[] pot, address[] whowin,uint[] mymoney) {
        uint[] memory whichRound = new uint[](Round);
        uint[] memory totalPool = new uint[](Round);
        address[] memory winner = new address[](Round);
        uint[] memory myMoney = new uint[](Round);
        uint counter = 0;

        for (uint i = 1; i <= Round; i++) {
            whichRound[counter] = i;
            totalPool[counter] = RoundETH[i];
            winner[counter] = RoundLastGreedyMan[i];
            myMoney[counter] = getMyRevenue(i);
            counter++;
        }
   
        return (whichRound,totalPool,winner,myMoney);
    }
}

library GreedyHeartCalcLong {
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