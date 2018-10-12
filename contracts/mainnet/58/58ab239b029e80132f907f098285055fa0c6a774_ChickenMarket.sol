pragma solidity ^0.4.24;


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


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function withdraw() public;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ChickenMarket is Owned{
    using SafeMath for *;
    
    modifier notContract() {
        require (msg.sender == tx.origin);
        _;
    }
    
    struct Card{
        uint256 price;
        address owner;  
        uint256 payout;
        uint256 divdent;
    }
    
    Card public card1;
    Card public card2;
    Card public card3;
    
    bool public isOpen = true;

    uint256 public updateTime;
    address public mainContract = 0x211f3175e3632ed194368311223bd4f4e834fc33;
    ERC20Interface ChickenParkCoin;

    event Buy(
        address indexed from,
        address indexed to,
        uint tokens,
        uint card
    );

    event Reset(
        uint time,
        uint finalPriceCard1,
        uint finalPriceCard2,
        uint finalPriceCard3
    );
    
    constructor() public{
        card1 = Card(1000e18, msg.sender, 0, 10);
        card2 = Card(1000e18, msg.sender, 0, 20);
        card3 = Card(1000e18, msg.sender, 0, 70);
        
        ChickenParkCoin = ERC20Interface(mainContract);
        updateTime = now;
    }
    
    function() public payable{

    }
    
    function tokenFallback(address _from, uint _value, bytes _data) public {
        require(_from == tx.origin);
        require(msg.sender == mainContract);
        require(isOpen);

        address oldowner;
        
        if(uint8(_data[0]) == 1){
            withdraw(1);
            require(card1.price == _value);
            card1.price = _value.mul(2);
            oldowner = card1.owner;
            card1.owner = _from;            
            
            ChickenParkCoin.transfer(oldowner, _value.mul(80) / 100);
        } else if(uint8(_data[0]) == 2){
            withdraw(2);
            require(card2.price == _value);
            card2.price = _value.mul(2);
            oldowner = card2.owner;
            card2.owner = _from;            
            
            ChickenParkCoin.transfer(oldowner, _value.mul(80) / 100);
        } else if(uint8(_data[0]) == 3){
            withdraw(3);
            require(card3.price == _value);
            card3.price = _value.mul(2);
            oldowner = card3.owner;
            card3.owner = _from;            

            ChickenParkCoin.transfer(oldowner, _value.mul(80) / 100);
        }
    }
    
    function withdraw(uint8 card) public {
        uint _revenue;
        if(card == 1){
            _revenue = (getAllRevenue().mul(card1.divdent) / 100) - card1.payout;
            card1.payout = (getAllRevenue().mul(card1.divdent) / 100);
            card1.owner.transfer(_revenue);
        } else if(card == 2){
            _revenue = (getAllRevenue().mul(card2.divdent) / 100) - card2.payout;
            card2.payout = (getAllRevenue().mul(card2.divdent) / 100);
            card2.owner.transfer(_revenue);
        } else if(card == 3){
            _revenue = (getAllRevenue().mul(card3.divdent) / 100) - card3.payout;
            card3.payout = (getAllRevenue().mul(card3.divdent) / 100);
            card3.owner.transfer(_revenue);
        } 
    }
    
    
    function getCardRevenue(uint8 card) view public returns (uint256){
        if(card == 1){
            return (getAllRevenue().mul(card1.divdent) / 100) - card1.payout;
        } else if(card == 2){
            return (getAllRevenue().mul(card2.divdent) / 100) - card2.payout;
        } else if(card == 3){
            return (getAllRevenue().mul(card3.divdent) / 100) - card3.payout;
        }
    }
    
    function getAllRevenue() view public returns (uint256){
        return card1.payout.add(card2.payout).add(card3.payout).add(address(this).balance);
    }
    
    function reSet() onlyOwner public {
        require(now >= updateTime + 7 days);
        withdraw(1);
        withdraw(2);
        withdraw(3);
        
        card1.price = 1000e18;
        card2.price = 1000e18;
        card3.price = 1000e18;
        
        card1.owner = owner;
        card2.owner = owner;
        card3.owner = owner;
        
        card1.payout = 0;
        card2.payout = 0;
        card3.payout = 0;
        
        ChickenParkCoin.transfer(owner, ChickenParkCoin.balanceOf(address(this)));
        owner.transfer(address(this).balance);
        updateTime = now;
    }
    
    function withdrawMainDivi() public onlyOwner {
       ChickenParkCoin.withdraw();
    }
    
    function setStatus(bool _status) onlyOwner public {
        isOpen = _status;
    }
}