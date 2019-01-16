pragma solidity ^0.4.25;


contract Prosperity {
    
    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral
     */
    function buy(address _referredBy) public payable returns(uint256);
    
    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    function reinvest() public;
    
    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens) public;
    
    /**
     * Alias of sell() and withdraw().
     */
    function exit() public;
    
    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw() public;
    
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress) view public returns(uint256);
    
    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress) view public returns(uint256);
}

contract Fertilizer {
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onDistribute(
        address pusher, 
        uint256 percent, 
        uint256 oldBal, 
        uint256 newBal
    );
    
    
    /*================================
    =            DATASETS            =
    ================================*/
    address internal fund_;
    Prosperity internal Exchange_;
    
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    constructor() 
        public 
    {
        Exchange_ = Prosperity(0xFf567f72F6BC585A3143E6852A2fF7DF26e5f455);
        fund_ = 0x1E2F082CB8fd71890777CA55Bd0Ce1299975B25f;
    }
    
    // used so the distribute function can call Prosperities withdraw function
    function() external payable {}
    
    function distribute(uint256 _percent) 
        public
    {
        require(_percent > 0 && _percent < 100);
        
        address _pusher = msg.sender;
        uint256 _bal = address(this).balance;
        
        // setup _stop.  this will be used to tell the loop to stop
        uint256 _stop = (_bal * (100 - _percent)) / 100;
        
        // buy & sell    
        Exchange_.buy.value(_bal)(fund_);
        Exchange_.sell(Exchange_.balanceOf(address(this)));
        
        // setup tracker.  this will be used to tell the loop to stop
        uint256 _tracker = Exchange_.dividendsOf(address(this));

        // reinvest/sell loop
        while (_tracker >= _stop) 
        {
            // lets burn some tokens to distribute dividends to THC hodlers
            Exchange_.reinvest();
            Exchange_.sell(Exchange_.balanceOf(address(this)));
            
            // update our tracker with estimates (yea. not perfect, but cheaper on gas)
            _tracker = (_tracker * 81) / 100;
        }
        
        // withdraw
        Exchange_.withdraw();
        
        // fire event
        emit onDistribute(_pusher, _percent, _bal, address(this).balance);
    }
}