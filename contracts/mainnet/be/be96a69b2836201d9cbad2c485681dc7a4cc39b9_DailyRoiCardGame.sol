pragma solidity ^0.4.24;

/*
*
*
*/

contract DailyRoiCardGame {
    /*=================================
    =        MODIFIERS        =
    =================================*/



    modifier onlyOwner(){

        require(msg.sender == dev);
        _;
    }

    modifier senderVerify() {
        require (msg.sender == tx.origin);
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


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "DailyRoi CARDS";
    string public symbol = "DROICARD";

    uint8 constant public cardsDivRate = 10;
    uint8 constant public ownerDivRate = 50;
    uint8 constant public distDivRate = 40;
    uint8 constant public referralRate = 5;
    uint8 constant public decimals = 18;
    uint public totalCardValue = 14.51 ether; // Make sure this is sum of constructor values
    uint public precisionFactor = 9;


   /*================================
    =            DATASETS            =
    ================================*/

    mapping(uint => address) internal cardOwner;
    mapping(uint => uint) public cardPrice;
    mapping(uint => uint) internal cardPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    mapping(uint => uint) internal totalCardDivs;

    uint cardPriceIncrement = 110;
    uint totalDivsProduced = 0;

    uint public totalCards;

    bool allowReferral = true;

    address dev;
    address promoter;
    address promoter2;
    address dailyRoiDivsAddr;



    uint ACTIVATION_TIME = 1537912800;



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
        promoter = 0x41FE3738B503cBaFD01C1Fd8DD66b7fE6Ec11b01;
        promoter2 = 0xEafE863757a2b2a2c5C3f71988b7D59329d09A78;
        dailyRoiDivsAddr = 0x9F0a1bcD44f522318900e70A2617C0056378BB2D;

        totalCards = 16;

        cardOwner[0] = dev;
        cardPrice[0] = 4 ether;
        cardPreviousPrice[0] = cardPrice[0];

        cardOwner[1] = promoter2;
        cardPrice[1] = 3 ether;
        cardPreviousPrice[1] = cardPrice[1];

        cardOwner[2] = promoter2;
        cardPrice[2] = 2 ether;
        cardPreviousPrice[2] = cardPrice[2];

        cardOwner[3] = dev;
        cardPrice[3] = 1.5 ether;
        cardPreviousPrice[3] = cardPrice[3];

        cardOwner[4] = promoter;
        cardPrice[4] = 1 ether;
        cardPreviousPrice[4] = cardPrice[4];

        cardOwner[5] = dev;
        cardPrice[5] = 0.8 ether;
        cardPreviousPrice[5] = cardPrice[5];

        cardOwner[6] = dev;
        cardPrice[6] = 0.6 ether;
        cardPreviousPrice[6] = cardPrice[6];

        cardOwner[7] = dev;
        cardPrice[7] = 0.5 ether;
        cardPreviousPrice[7] = cardPrice[7];

        cardOwner[8] = dev;
        cardPrice[8] = 0.4 ether;
        cardPreviousPrice[8] = cardPrice[8];

        cardOwner[9] = dev;
        cardPrice[9] = 0.3 ether;
        cardPreviousPrice[9] = cardPrice[9];

        cardOwner[10] = dev;
        cardPrice[10] = 0.2 ether;
        cardPreviousPrice[10] = cardPrice[10];

        cardOwner[11] = dev;
        cardPrice[11] = 0.1 ether;
        cardPreviousPrice[11] = cardPrice[11];

        cardOwner[12] = dev;
        cardPrice[12] = 0.05 ether;
        cardPreviousPrice[12] = cardPrice[12];

        cardOwner[13] = dev;
        cardPrice[13] = 0.03 ether;
        cardPreviousPrice[13] = cardPrice[13];

        cardOwner[14] = dev;
        cardPrice[14] = 0.02 ether;
        cardPreviousPrice[14] = cardPrice[14];

        cardOwner[15] = dev;
        cardPrice[15] = 0.01 ether;
        cardPreviousPrice[15] = cardPrice[15];
    }

    function addtotalCardValue(uint _new, uint _old)
    internal
    {
        uint newPrice = SafeMath.div(SafeMath.mul(_new,cardPriceIncrement),100);
        totalCardValue = SafeMath.add(totalCardValue, SafeMath.sub(newPrice,_old));
    }

    function buy(uint _card, address _referrer)
        senderVerify()
        public
        payable
    {
        require(_card < totalCards);
        require(now >= ACTIVATION_TIME);
        require(msg.value == cardPrice[_card]);
        require(msg.sender != cardOwner[_card]);

        addtotalCardValue(msg.value, cardPreviousPrice[_card]);

        uint _newPrice = SafeMath.div(SafeMath.mul(msg.value, cardPriceIncrement), 100);

         //Determine the total dividends
        uint _baseDividends = SafeMath.sub(msg.value, cardPreviousPrice[_card]);

        totalDivsProduced = SafeMath.add(totalDivsProduced, _baseDividends);

        uint _cardsDividends = SafeMath.div(SafeMath.mul(_baseDividends, cardsDivRate),100);

        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends, ownerDivRate), 100);

        totalCardDivs[_card] = SafeMath.add(totalCardDivs[_card], _ownerDividends);

        _ownerDividends = SafeMath.add(_ownerDividends, cardPreviousPrice[_card]);

        uint _distDividends = SafeMath.div(SafeMath.mul(_baseDividends, distDivRate), 100);

        if (allowReferral && (_referrer != msg.sender) && (_referrer != 0x0000000000000000000000000000000000000000)) {

            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends, referralRate), 100);

            _distDividends = SafeMath.sub(_distDividends, _referralDividends);

            ownerAccounts[_referrer] = SafeMath.add(ownerAccounts[_referrer], _referralDividends);
        }


        //distribute dividends to accounts
        address _previousOwner = cardOwner[_card];
        address _newOwner = msg.sender;

        ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner], _ownerDividends);

        dailyRoiDivsAddr.transfer(_cardsDividends);

        distributeDivs(_distDividends);

        //Increment the card Price
        cardPreviousPrice[_card] = msg.value;
        cardPrice[_card] = _newPrice;
        cardOwner[_card] = _newOwner;

        emit oncardPurchase(msg.sender, msg.value, _card, SafeMath.div(SafeMath.mul(msg.value, cardPriceIncrement), 100));
    }


    function distributeDivs(uint _distDividends) internal{

            for (uint _card=0; _card < totalCards; _card++){

                uint _divShare = SafeMath.div(SafeMath.div(SafeMath.mul(cardPreviousPrice[_card], 10 ** (precisionFactor + 1)), totalCardValue) + 5, 10);
                uint _cardDivs = SafeMath.div(SafeMath.mul(_distDividends, _divShare), 10 ** precisionFactor);

                ownerAccounts[cardOwner[_card]] += _cardDivs;

                totalCardDivs[_card] = SafeMath.add(totalCardDivs[_card], _cardDivs);
            }
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

    /**
   * Transfer bond to another address
   */
   function transfer(address _to, uint _card )

      public
    {
        require(cardOwner[_card] == msg.sender);

        cardOwner[_card] = _to;

        emit Transfer(msg.sender, _to, _card);

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

    function setcardPrice(uint _card, uint _price)   //Allow the changing of a card price owner if the dev owns it
        onlyOwner()
        public
    {
        require(cardOwner[_card] == dev);
        cardPrice[_card] = _price;
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

    function setAllowReferral(bool _allowReferral)
        onlyOwner()
        public
    {
        allowReferral = _allowReferral;
    }



    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */


    /* function getCardDivShare(uint _card)
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
    } */



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

    function gettotalCardDivs(uint _card)
        public
        view
        returns(uint)
    {
        require(_card < totalCards);
        return totalCardDivs[_card];
    }

    function getTotalDivsProduced()
        public
        view
        returns(uint)
    {
        return totalDivsProduced;
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