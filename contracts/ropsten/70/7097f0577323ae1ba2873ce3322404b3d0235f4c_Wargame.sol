pragma solidity ^0.4.25;


contract Wargame {
    using SafeMath for *;
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrator_ == _customerAddress);
        _;
    }
    
    
    /*=================================
    =             EVENTS              =
    =================================*/
    event onCardFlip(
        uint8 index,
        address indexed owner,
        uint256 price
    );
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    // attack timers
    uint256 internal baseTenMinutes_ = 10 minutes;
    uint256 internal baseOneMinutes_ = 2 minutes;
    
    // base price for a card
    uint256 internal initialPrice_ = 0.005 ether;
    
    
    /*=================================
    =             DATASET             =
    =================================*/
    // administrator address
    address internal administrator_;
    
    // fund address
    address internal fundAddress_;
    
    // always 12 Cards
    Card[12] internal nations_;
    
    
    /*=================================
    =   PRIVATE / INTERNAL FUNCTIONS  =
    =================================*/
    function initCards() internal {
        for (uint8 i = 0; i < nations_.length; i++) {
            Card storage _nation = nations_[i];
            uint256 _baseTenMinutes = uint256((i/4) + 1) * baseTenMinutes_;
            uint256 _column = (i%4);
            uint256 _baseOneMinutes = _column * baseOneMinutes_;
            
            // set time for each card
            
            _nation.time = _baseTenMinutes + _baseOneMinutes;
        }
    }
    
    function resetCards() internal {
        for (uint8 i = 0; i < nations_.length; i++) {
            Card storage _nation = nations_[i];
            
            // reset Cards
            _nation.price = initialPrice_;  // reset price
            _nation.owner = address(this);  // reset owner to this contract
        }
    }
    
    function setCard(Card storage _nation, address _buyer)
        internal 
    {
        // reset Cards
        _nation.price = _nation.price * 2;  // double the price
        _nation.owner = _buyer;      // set owner equal to buyer
    }
    
    
    /*=================================
    =         PUBLIC FUNCTIONS        =
    =================================*/
    constructor() 
        public
    {
        administrator_ = 0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825;
        fundAddress_ = 0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825;
        
        initCards();
        resetCards();
    }
    
    /**
     * Buy the nation for the exact amount of eth 
     */
    function buyNation(uint8 _index) 
        public
        payable
    {
        uint256 _value = msg.value;
        
        // nation is buyable for the exact amount of eth
        require(_value == nations_[_index].price, "Nation has already been bought");
        
        _buyNationInternal(_index, _value);
    }
    
    /**
     * Buy the nation for up to the amount of eth 
     */
    function overbidNation(uint8 _index)
        public 
        payable
    {
        Card storage _nation = nations_[_index];
        uint256 _value = msg.value;
        
        // nation is buyable for the exact amount of eth
        require(_value >= _nation.price, "Nation has already been bought");
        _value = _nation.price; // set value equal to price of the nation
        
        _buyNationInternal(_index, _value);
        
        // 62,5 % to current owner
        // 6% to fund
        // 31,5% to pot
        uint256 _ethToOwner = _value.mul(5).div(8);     // 62,5% owner
        uint256 _ethToFund  = _value.mul(6).div(100);   // 6%    fund
        uint256 _ethToPot   = _value.mul(63).div(200);  // 31,5% pot
        
        // transfer back the overbid amount
        uint256 _overbid = msg.value.sub(_ethToOwner).sub(_ethToFund).sub(_ethToPot);
        if (_overbid > 0) {
            address _buyer = msg.sender;
            _buyer.transfer(_overbid);
        }
    }
    
    function _buyNationInternal(uint8 _index, uint256 _value)
        internal
    {
        Card storage _nation = nations_[_index];
        
        address _buyer = msg.sender;
        address _owner = _nation.owner;
        
        // 62,5 % to current owner
        // 6% to fund
        // 31,5% to pot
        uint256 _ethToOwner = _value.mul(5).div(8);     // 62,5% owner
        
        // if the buy order is for the first card
        // instead pay fund at the end of the round
        if (_nation.price != initialPrice_) {
            _owner.transfer(_ethToOwner);   // instant delivery service
        }
        
        // set new values for the flipped card
        setCard(_nation, _buyer);
        
        // trigger event
        emit onCardFlip(_index, _buyer, _nation.price);
    }
    
    /* Views*/
    function getNation(uint8 _index)
        public 
        view 
        returns(uint256, uint256, address)
    {
        Card storage _nation = nations_[_index];
        return (_nation.price, _nation.time, _nation.owner);
    }
    
    
    /*=================================
    =            DATA TYPES           =
    =================================*/
    struct Card {
        uint256 price;
        uint256 time;
        address owner;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}