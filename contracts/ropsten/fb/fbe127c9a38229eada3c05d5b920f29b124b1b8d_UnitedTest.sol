pragma solidity ^0.4.24;
/*
*
* https://www.unitedetc.club/cards
* Card Flip Game that feeds the United ETC Lending Game    
*
*/
contract UnitedTest {
    /*=================================
    =        MODIFIERS        =
    =================================*/
    modifier onlyOwner(){
        require(msg.sender == dev);
        _;
    }
    /*==============================
    =            EVENTS            =
    ==============================*/
    event oncardPurchase(
        address customerAddress,
        uint256 incomingEthereum,
        uint256 card,
        uint256 newPrice
    );
    event onWithdraw(
        address customerAddress,
        uint256 ethereumWithdrawn
    );
    // ERC20
    event Transfer(
        address from,
        address to,
        uint256 card
    );
   event Random(
   address player, 
   uint256 result
   );
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "United ETC Cards";
    string public symbol = "UEC";
    uint8 constant public promoterRate = 7;
    uint8 constant public subpromoterRate = 1;
    uint8 constant public ownerDivRate = 25;
    uint8 constant public distDivRate = 35;
    uint8 constant public referralRate = 5;
    uint8 constant public decimals = 18;
    uint256 public resetvalue = 955;
    uint public totalCardValue = 2.25 ether; // Make sure this is sum of constructor values
    uint public precisionFactor = 9;
    uint256 randomizer = 9734953091;
    uint256 private randNonce = 0;
  /*================================
    =            DATASETS            =
    ================================*/
    mapping(uint => address) internal cardOwner;
    mapping(uint => uint) public cardPrice;
    mapping(uint => uint) internal cardPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalCardDivs;
    uint cardPriceIncrement = 300;
    uint totalbackup = 0;
    uint public totalCards;
    bool allowReferral = true;
    address dev;
    address developer;
    address promoter;
    address subpromoter;
    address lendingcontract;
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --
    */
    constructor()
        public
    {
        dev = msg.sender;
        developer = 0xFf8C9bEdB97E3A2B69a315A87DA1aAB91364D310;
        promoter = 0xFf8C9bEdB97E3A2B69a315A87DA1aAB91364D310;
        subpromoter = 0xFf8C9bEdB97E3A2B69a315A87DA1aAB91364D310;
        lendingcontract = 0xFf8C9bEdB97E3A2B69a315A87DA1aAB91364D310; // Money will be sent to the lending contract once in 24 hours and portion of it will be used for games bankroll
        totalCards = 9;
        cardOwner[0] = developer;
        cardPrice[0] = 0.05 ether;
        cardPreviousPrice[0] = cardPrice[0];
        cardOwner[1] = developer;
        cardPrice[1] = 0.10 ether;
        cardPreviousPrice[1] = cardPrice[1];
        cardOwner[2] = developer;
        cardPrice[2] = 0.15 ether;
        cardPreviousPrice[2] = cardPrice[2];
        cardOwner[3] = developer;
        cardPrice[3] = 0.20 ether;
        cardPreviousPrice[3] = cardPrice[3];
        cardOwner[4] = developer;
        cardPrice[4] = 0.25 ether;
        cardPreviousPrice[4] = cardPrice[4];
        cardOwner[5] = developer;
        cardPrice[5] = 0.30 ether;
        cardPreviousPrice[5] = cardPrice[5];
        cardOwner[6] = developer;
        cardPrice[6] = 0.35 ether;
        cardPreviousPrice[6] = cardPrice[6];
        cardOwner[7] = developer;
        cardPrice[7] = 0.40 ether;
        cardPreviousPrice[7] = cardPrice[7];
        cardOwner[8] = developer;
        cardPrice[8] = 0.45 ether;
        cardPreviousPrice[8] = cardPrice[8];
}
    function addtotalCardValue(uint _new, uint _old)
    internal
    {
        uint newPrice = SafeMath.div(SafeMath.mul(_new,cardPriceIncrement),100);
        totalCardValue = SafeMath.add(totalCardValue, SafeMath.sub(newPrice,_old));
    }
    function buy(uint _card, address _referrer)
        public
        payable
    {
        require(_card < totalCards);
         if(msg.value >= cardPrice[_card]){
         require(msg.value-cardPrice[_card]<=0.001 ether);
         }else{
         require(cardPrice[_card]-msg.value<=0.001 ether);
         }
        require(msg.sender != cardOwner[_card]);
        addtotalCardValue(msg.value, cardPreviousPrice[_card]);
        uint _newPrice = SafeMath.div(SafeMath.mul(msg.value, cardPriceIncrement), 100);
        uint _baseDividends = SafeMath.sub(msg.value, cardPreviousPrice[_card]);
        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends, ownerDivRate), 100);
        totalCardDivs[_card] = SafeMath.add(totalCardDivs[_card], _ownerDividends);
        _ownerDividends = SafeMath.add(_ownerDividends, cardPreviousPrice[_card]);
        uint _distDividends = SafeMath.div(SafeMath.mul(_baseDividends, distDivRate), 100);
        if (allowReferral && (_referrer != msg.sender) && (_referrer != 0x0000000000000000000000000000000000000000)) {
            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends, referralRate), 100);
            _distDividends = SafeMath.sub(_distDividends, _referralDividends);
            ownerAccounts[_referrer] = SafeMath.add(ownerAccounts[_referrer], _referralDividends);
        }
        totalbackup = SafeMath.add(totalbackup, _distDividends);
        address _previousOwner = cardOwner[_card];
        address _newOwner = msg.sender;
        ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner], _ownerDividends);
        developer.transfer(SafeMath.div(SafeMath.mul(_baseDividends, promoterRate),100));
        promoter.transfer(SafeMath.div(SafeMath.mul(_baseDividends, promoterRate),100));
        subpromoter.transfer(SafeMath.div(SafeMath.mul(_baseDividends, subpromoterRate),100));
        lendingcontract.transfer(SafeMath.div(SafeMath.mul(_baseDividends, ownerDivRate), 100));
        uint256 random = getRandomNumber(msg.sender) + 1;
        if (random > resetvalue) {
        cardPreviousPrice[_card] = msg.value;
        cardPrice[_card] = _newPrice;
        cardOwner[_card] = _newOwner;
        cardOwner[0].transfer(SafeMath.div(SafeMath.mul(totalbackup, 2), 100));
        cardOwner[1].transfer(SafeMath.div(SafeMath.mul(totalbackup, 4), 100));
        cardOwner[2].transfer(SafeMath.div(SafeMath.mul(totalbackup, 6), 100));
        cardOwner[3].transfer(SafeMath.div(SafeMath.mul(totalbackup, 8), 100));
        cardOwner[4].transfer(SafeMath.div(SafeMath.mul(totalbackup, 12), 100));
        cardOwner[5].transfer(SafeMath.div(SafeMath.mul(totalbackup, 14), 100));
        cardOwner[6].transfer(SafeMath.div(SafeMath.mul(totalbackup, 16), 100));
        cardOwner[7].transfer(SafeMath.div(SafeMath.mul(totalbackup, 18), 100));
        cardOwner[8].transfer(SafeMath.div(SafeMath.mul(totalbackup, 20), 100));
        totalbackup = 0;
        resetcardPrice();
        emit Random(msg.sender, random);
        }
        else {
        cardPreviousPrice[_card] = msg.value;
        cardPrice[_card] = _newPrice;
        cardOwner[_card] = _newOwner;
        }
       emit oncardPurchase(msg.sender, msg.value, _card, SafeMath.div(SafeMath.mul(msg.value, cardPriceIncrement), 100));
}
 
function withdraw()
        public
    {
        address _customerAddress = msg.sender;
        require(ownerAccounts[_customerAddress] >= 0.001 ether);
        uint _dividends = ownerAccounts[_customerAddress];
        ownerAccounts[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }

 /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    function setName(string _name)
        onlyOwner()
        public
    {
        name = _name;
    }
    function setSymbol(string _symbol)
        onlyOwner()
        public
    {
        symbol = _symbol;
    }
    function setcardPrice(uint _card, uint _price)  
        onlyOwner()
        public
    {
         cardPrice[_card] = _price;
    }
    function setAllowReferral(bool _allowReferral)
         onlyOwner()
         public
     {
         allowReferral = _allowReferral;
     }
    function settotalCardValue(uint _price)  
        onlyOwner()
        public
    {
         totalCardValue = _price;
    }
     function ResetCardPriceAdmin()  
        onlyOwner()
        public
    {
         resetcardPrice();
    }
     function resetcardPrice()   
        private
    {
        cardOwner[0] = developer;
        cardPrice[0] = 0.05 ether;
        cardPreviousPrice[0] = cardPrice[0];
        cardOwner[1] = developer;
        cardPrice[1] = 0.10 ether;
        cardPreviousPrice[1] = cardPrice[1];
        cardOwner[2] = developer;
        cardPrice[2] = 0.15 ether;
        cardPreviousPrice[2] = cardPrice[2];
        cardOwner[3] = developer;
        cardPrice[3] = 0.20 ether;
        cardPreviousPrice[3] = cardPrice[3];
        cardOwner[4] = developer;
        cardPrice[4] = 0.25 ether;
        cardPreviousPrice[4] = cardPrice[4];
        cardOwner[5] = developer;
        cardPrice[5] = 0.30 ether;
        cardPreviousPrice[5] = cardPrice[5];
        cardOwner[6] = developer;
        cardPrice[6] = 0.35 ether;
        cardPreviousPrice[6] = cardPrice[6];
        cardOwner[7] = developer;
        cardPrice[7] = 0.40 ether;
        cardPreviousPrice[7] = cardPrice[7];
        cardOwner[8] = developer;
        cardPrice[8] = 0.45 ether;
        cardPreviousPrice[8] = cardPrice[8];
        totalCardValue = 2.25 ether;
    }
     function setRandomizer(uint256 _Randomizer) public {
      require(msg.sender==dev);
      randomizer = _Randomizer;
    }
     function setResetvalue(uint256 _resetvalue) public {
      require(msg.sender==dev);
      resetvalue = _resetvalue;
    }
     function setPromoter(address _promoter) public {
      require(msg.sender==dev);
      promoter = _promoter;
    }
     function setSubPromoter(address _subpromoter) public {
      require(msg.sender==dev);
      subpromoter = _subpromoter;
    }
    function setLendingContract(address _lendingcontract) public {
      require(msg.sender==dev);
      lendingcontract = _lendingcontract;
    }
    function addNewcard(uint _price)
        onlyOwner()
        public
    {
        cardPrice[totalCards-1] = _price;
        cardOwner[totalCards-1] = dev;
        totalCardDivs[totalCards-1] = 0;
        totalCards = totalCards + 1;
    }
          function end() public onlyOwner {
    if(msg.sender == dev) { // Only let the contract creator do this
        selfdestruct(dev); // Makes contract inactive, returns funds
    }
    }
    function getRandomNumber(address _addr) private returns(uint256 randomNumber) 
    {
        randNonce++;
        randomNumber = uint256(keccak256(abi.encodePacked(now, _addr, randNonce, randomizer, block.coinbase, block.number))) % 1000;
    }
        function getMyBalance()
         public
         view
         returns(uint)
     {
         return ownerAccounts[msg.sender];
    }
    function getOwnerBalance(address _cardOwner)
        public
        view
        returns(uint)
    {
        return ownerAccounts[_cardOwner];
    }
    function getcardPrice(uint _card)
        public
        view
        returns(uint)
    {
        require(_card < totalCards);
        return cardPrice[_card];
    }
    function getcardOwner(uint _card)
        public
        view
        returns(address)
    {
        require(_card < totalCards);
        return cardOwner[_card];
    }
    
    function gettotalbackup()
         public
         view
         returns(uint)
     {
         return totalbackup;
     }
     
    function gettotalCardDivs(uint _card)
         public
         view
         returns(uint)
     {
         require(_card < totalCards);
         return totalCardDivs[_card];
     }
     
     function getCardDivShare(uint _card)
         public
         view
         returns(uint)
     {
         require(_card < totalCards);
         return SafeMath.div(SafeMath.div(SafeMath.mul(cardPreviousPrice[_card], 10 ** (precisionFactor + 1)), totalCardValue) + 5, 10);
     }
     function getCardDivs(uint  _card, uint _amt)
         public
         view
         returns(uint)
     {
         uint _share = getCardDivShare(_card);
         return SafeMath.div(SafeMath.mul( _share, _amt), 10 ** precisionFactor);
     }
     function gettotalCardValue()
         public
         view
         returns(uint)
     {
         return totalCardValue;
     }
     
     
  function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address (this).balance;
    }
    function gettotalCards()
        public
        view
        returns(uint)
    {
        return totalCards;
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