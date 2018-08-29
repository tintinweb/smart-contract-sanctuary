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

contract PD88 is Owned {
    
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin);
        
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    //Round Global Info
    uint public Round = 1;
    mapping(uint => uint) public RoundDonation;
    mapping(uint => uint) public RoundETH; // Pot
    mapping(uint => uint) public RoundTime;
    mapping(uint => uint) public RoundPayMask;
    mapping(uint => address) public RoundLastDonationMan;
    
    //Globalinfo
    uint256 public Luckybuy;
    
    //Round Personal Info
    mapping(uint => mapping(address => uint)) public RoundMyDonation;
    mapping(uint => mapping(address => uint)) public RoundMyPayMask;
    mapping(address => uint) public MyreferredRevenue;
    
    //Product
    uint public product1_pot;
    uint public product2_pot;
    uint public product3_pot;
    uint public product4_pot;
    
    uint public product1_sell;
    uint public product2_sell;
    uint public product3_sell;
    uint public product4_sell;
    
    uint public product1_luckybuyTracker;
    uint public product2_luckybuyTracker;
    uint public product3_luckybuyTracker;
    uint public product4_luckybuyTracker;
    
    uint public product1 = 0.03 ether;
    uint public product2 = 0.05 ether;
    uint public product3 = 0.09 ether;
    uint public product4 = 0.01 ether;
    
    uint256 private RoundIncrease = 11 seconds; 
    uint256 constant private RoundMaxTime = 720 minutes; 
    
    uint public lasttimereduce = 0;
    
    //Owner fee
    uint256 public onwerfee;
    
    using SafeMath for *;
    using CalcLong for uint256;
    
    event winnerEvent(address winnerAddr, uint256 newPot, uint256 round);
    event luckybuyEvent(address luckyAddr, uint256 amount, uint256 round, uint product);
    event buydonationEvent(address Addr, uint256 Donationsamount, uint256 ethvalue, uint256 round, address ref);
    event referredEvent(address Addr, address RefAddr, uint256 ethvalue);
    
    event withdrawEvent(address Addr, uint256 ethvalue, uint256 Round);
    event withdrawRefEvent(address Addr, uint256 ethvalue);
    event withdrawOwnerEvent(uint256 ethvalue);


    function getDonationPrice() public view returns(uint256)
    {  
        return ( (RoundDonation[Round].add(1000000000000000000)).ethRec(1000000000000000000) );
    }
    
    //Get My Revenue
    function getMyRevenue(uint _round) public view returns(uint256)
    {
        return(  (((RoundPayMask[_round]).mul(RoundMyDonation[_round][msg.sender])) / (1000000000000000000)).sub(RoundMyPayMask[_round][msg.sender])  );
    }
    
    //Get Time Left
    function getTimeLeft() public view returns(uint256)
    {
        if(RoundTime[Round] == 0 || RoundTime[Round] < now) 
            return 0;
        else 
            return( (RoundTime[Round]).sub(now) );
    }

    function updateTimer(uint256 _donations) private
    {
        if(RoundTime[Round] == 0)
            RoundTime[Round] = RoundMaxTime.add(now);
        
        uint _newTime = (((_donations) / (1000000000000000000)).mul(RoundIncrease)).add(RoundTime[Round]);
        
        // compare to max and set new end time
        if (_newTime < (RoundMaxTime).add(now))
            RoundTime[Round] = _newTime;
        else
            RoundTime[Round] = RoundMaxTime.add(now);
    }


    function buyDonation(address referred, uint8 product) public isHuman() payable {
        
        require(msg.value >= 1000000000, "pocket lint: not a valid currency");
        require(msg.value <= 100000000000000000000000, "no vitalik, no");
        
        uint8 product_ = 1;
        if(product == 1) {
            require(msg.value >= product1 && msg.value % product1 == 0);
            product1_sell += msg.value / product1;
            product1_pot += msg.value.mul(20) / 100;
            product1_luckybuyTracker++;
            product_ = 1;
        } else if(product == 2) {
            require(msg.value >= product2 && msg.value % product2 == 0);
            product2_sell += msg.value / product2;
            product2_pot += msg.value.mul(20) / 100;
            product2_luckybuyTracker++;
            product_ = 2;
        } else if(product == 3) {
            require(msg.value >= product3 && msg.value % product3 == 0);
            product3_sell += msg.value / product3;
            product3_pot += msg.value.mul(20) / 100;
            product3_luckybuyTracker++;
            product_ = 3;
        } else {
            require(msg.value >= product4 && msg.value % product4 == 0);
            product4_sell += msg.value / product4;
            product4_pot += msg.value.mul(20) / 100;
            product4_luckybuyTracker++;
            product_ = 4;
        }
        

        //bought at least 1 whole key
        uint256 _donations = (RoundETH[Round]).keysRec(msg.value);
        uint256 _pearn;
        require(_donations >= 1000000000000000000);
        
        require(RoundTime[Round] > now || RoundTime[Round] == 0);
        
        updateTimer(_donations);
        
        RoundDonation[Round] += _donations;
        RoundMyDonation[Round][msg.sender] += _donations;

        if (referred != address(0) && referred != msg.sender)
        {
             _pearn = (((msg.value.mul(45) / 100).mul(1000000000000000000)) / (RoundDonation[Round])).mul(_donations)/ (1000000000000000000);

            onwerfee += (msg.value.mul(5) / 100);
            RoundETH[Round] += msg.value.mul(20) / 100;
            
            MyreferredRevenue[referred] += (msg.value.mul(10) / 100);
            
            RoundPayMask[Round] += ((msg.value.mul(45) / 100).mul(1000000000000000000)) / (RoundDonation[Round]);
            RoundMyPayMask[Round][msg.sender] = (((RoundPayMask[Round].mul(_donations)) / (1000000000000000000)).sub(_pearn)).add(RoundMyPayMask[Round][msg.sender]);

            emit referredEvent(msg.sender, referred, msg.value.mul(10) / 100);
        } else {
             _pearn = (((msg.value.mul(55) / 100).mul(1000000000000000000)) / (RoundDonation[Round])).mul(_donations)/ (1000000000000000000);

            RoundETH[Round] += msg.value.mul(20) / 100;

            onwerfee +=(msg.value.mul(5) / 100);
            
            RoundPayMask[Round] += ((msg.value.mul(55) / 100).mul(1000000000000000000)) / (RoundDonation[Round]);
            RoundMyPayMask[Round][msg.sender] = (((RoundPayMask[Round].mul(_donations)) / (1000000000000000000)).sub(_pearn)).add(RoundMyPayMask[Round][msg.sender]);
        }
        
        // airdrops

        if (luckyBuy(product_) == true)
        {
            
            uint _temp = 0;
            if(product_ == 1) {
                _temp = product1_pot;
                product1_pot = 0;
                product1_luckybuyTracker = 0;
            } else if(product_ == 2) {
                _temp = product2_pot;
                product2_pot = 0;
                product2_luckybuyTracker = 0;
            } else if(product_ == 3) {
                _temp = product3_pot;
                product3_pot = 0;
                product3_luckybuyTracker = 0;
            } else {
                _temp = product4_pot;
                product4_pot = 0;
                product4_luckybuyTracker = 0;
            }
            
            if(_temp != 0)
                msg.sender.transfer(_temp);
                
            emit luckybuyEvent(msg.sender, _temp, Round,product_);
        }
        
        
        RoundLastDonationMan[Round] = msg.sender;
        emit buydonationEvent(msg.sender, _donations, msg.value, Round, referred);
    }
    
    function reducetime() isHuman() public {
        require(now >= lasttimereduce + 12 hours);
        lasttimereduce = now;
        RoundIncrease -= 1 seconds;
    }
    
    function win() isHuman() public {
        require(now > RoundTime[Round] && RoundTime[Round] != 0);
        
        uint Round_ = Round;
        Round++;
        
        //Round End 
        RoundLastDonationMan[Round_].transfer(RoundETH[Round_].mul(80) / 100);
        owner.transfer(RoundETH[Round_].mul(20) / 100);
        
        RoundIncrease = 11 seconds;
        lasttimereduce = now;
        emit winnerEvent(RoundLastDonationMan[Round_], RoundETH[Round_], Round_);
    }
    
    //withdrawEarnings
    function withdraw(uint _round) isHuman() public {
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
    function luckyBuy(uint8 product_) private view returns(bool)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
            
        )));
        
        uint luckybuyTracker_;
        
        if(product_ == 1) {
            luckybuyTracker_ = product1_luckybuyTracker;
        } else if(product_ == 2) {
            luckybuyTracker_ = product2_luckybuyTracker;
        } else if(product_ == 3) {
            luckybuyTracker_ = product3_luckybuyTracker;
        } else {
            luckybuyTracker_ = product4_luckybuyTracker;
        }
        
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
            winner[counter] = RoundLastDonationMan[i];
            myMoney[counter] = getMyRevenue(i);
            counter++;
        }
   
        return (whichRound,totalPool,winner,myMoney);
    }
}

library CalcLong {
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