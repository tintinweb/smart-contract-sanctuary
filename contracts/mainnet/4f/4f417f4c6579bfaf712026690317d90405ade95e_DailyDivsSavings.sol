pragma solidity ^0.4.20; // solhint-disable-line


/*
  modified pyramid contract by Cryptopinions (https://ethverify.net)
*/
contract DailyDivsSavings{
  using SafeMath for uint;
  address public ceo;
  address public ceo2;
  mapping(address => address) public referrer;//who has referred who
  mapping(address => uint256) public referralsHeld;//amount of eth from referrals held
  mapping(address => uint256) public refBuys;//how many people you have referred
  mapping(address => uint256) public tokenBalanceLedger_;
  mapping(address => int256) public payoutsTo_;
  uint256 public tokenSupply_ = 0;
  uint256 public profitPerShare_;
  uint256 constant internal magnitude = 2**64;
  uint256 constant internal tokenPriceInitial_ = 0.0000000001 ether;
  uint8 constant internal dividendFee_ = 50;

  event onTokenPurchase(
      address indexed customerAddress,
      uint256 incomingEthereum,
      uint256 tokensMinted,
      address indexed referredBy
  );
   event onTokenSell(
       address indexed customerAddress,
       uint256 tokensBurned,
       uint256 ethereumEarned
   );

   event onReinvestment(
       address indexed customerAddress,
       uint256 ethereumReinvested,
       uint256 tokensMinted
   );

   event onWithdraw(
       address indexed customerAddress,
       uint256 ethereumWithdrawn
   );

   function DailyDivsSavings() public{
     ceo=msg.sender;
     ceo2=0x93c5371707D2e015aEB94DeCBC7892eC1fa8dd80;
   }

  function ethereumToTokens_(uint _ethereum) public view returns(uint){
    //require(_ethereum>tokenPriceInitial_);
    return _ethereum.div(tokenPriceInitial_);
  }
  function tokensToEthereum_(uint _tokens) public view returns(uint){
    return tokenPriceInitial_.mul(_tokens);
  }
  function myHalfDividends() public view returns(uint){
    return (dividendsOf(msg.sender)*98)/200;//no safemath because for external use only
  }
  function myDividends()
    public
    view
    returns(uint256)
  {
      return dividendsOf(msg.sender) ;
  }
  function dividendsOf(address _customerAddress)
      view
      public
      returns(uint)
  {
      return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
  }
  function balance() public view returns(uint256){
    return address(this).balance;
  }
  function mySavings() public view returns(uint){
    return tokensToEthereum_(tokenBalanceLedger_[msg.sender]);
  }
  function depositNoRef() public payable{
    deposit(0);
  }
  function deposit(address ref) public payable{
    require(ref!=msg.sender);
    if(referrer[msg.sender]==0 && ref!=0){
      referrer[msg.sender]=ref;
      refBuys[ref]+=1;
    }

    purchaseTokens(msg.value);
  }
  function purchaseTokens(uint _incomingEthereum) private
    {
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _dividends = _undividedDividends;
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens.add(tokenSupply_) > tokenSupply_);



        // we can&#39;t give people infinite ethereum
        if(tokenSupply_ > 0){

            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        //remove divs from before buy
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        // fire event
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, 0);

        //return _amountOfTokens;
    }
    function sell(uint _amountOfEth) public {
      reinvest();
      sell_(ethereumToTokens_(_amountOfEth));
      withdraw();
    }
    function withdraw()
    private
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(); // get ref. bonus later in the code

        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // add ref. bonus
        //_dividends += referralBalance_[_customerAddress];
        //referralBalance_[_customerAddress] = 0;

        //payout
        _customerAddress.transfer(_dividends);

        // fire event
        onWithdraw(_customerAddress, _dividends);
    }
    function sell_(uint256 _amountOfTokens)
        private
    {
        // setup data
        address _customerAddress = msg.sender;
        require(tokenBalanceLedger_[_customerAddress]>0);
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        //uint256 _dividends = SafeMath.div(_ethereum, dividendFee_);
        uint256 _taxedEthereum = _ethereum;//SafeMath.sub(_ethereum, _dividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        // no divs on sell
        //if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            //profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        //}

        // fire event
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    function reinvest()
    public
    {
        // fetch dividends
        uint256 _dividends = myDividends(); // retrieve ref. bonus later in the code
        //require(_dividends>1);
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // retrieve ref. bonus
        //_dividends += referralBalance_[_customerAddress];
        //referralBalance_[_customerAddress] = 0;

        uint halfDivs=_dividends.div(2);

        // dispatch a buy order with the virtualized "withdrawn dividends"
        if(ethereumToTokens_(halfDivs.add(referralsHeld[msg.sender]))>0){
          purchaseTokens(halfDivs.add(referralsHeld[msg.sender]));//uint256 _tokens =
          referralsHeld[msg.sender]=0;
        }

        //give half to the referrer

        address refaddr=referrer[_customerAddress];
        if(refaddr==0){
          uint quarterDivs=halfDivs.div(2);
          referralsHeld[ceo]=referralsHeld[ceo].add(quarterDivs);
          referralsHeld[ceo2]=referralsHeld[ceo2].add(quarterDivs);
        }
        else{
          referralsHeld[refaddr]=referralsHeld[refaddr].add(halfDivs);
        }

        // fire event
        onReinvestment(_customerAddress, _dividends, halfDivs);
    }
}
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