pragma solidity ^0.4.20;


contract S3D {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    
    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator(){
        require(administrators[msg.sender]);
        _;
    }
    
    modifier OnlySports3DContract(){
        require(address(msg.sender) == Sports3DContract);
        _;
    }
 
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenMint(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address customerAddress,
        uint256 amount
    );
    
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "S3D";
    string public symbol = "S3D";
    address Sports3DContract;
    INVESTORS investors;
    uint8 constant public decimals = 18;
    uint256 constant internal magnitude = 2**64;
    
   
    
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
    // administrator list (see above on what they can do)
    mapping(address => bool) public administrators;


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor(address investorsAddress)
        public
    {
        // add administrators here
        administrators[msg.sender] = true;
        investors = INVESTORS(investorsAddress);
    }
    
    
    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        public
    {
        distributeRewards(msg.value);
    }
    
    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = dividendsOf(_customerAddress);
        
        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);


        _customerAddress.transfer(_dividends);
        
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }

    /**
     * Transfer tokens from the caller to a new holder.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        
        // make sure we have the requested tokens
        require( _amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
                
        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        
        // ERC20
        return true; 
    }
    
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
   

    function setSports3DContract(address sports) 
        onlyAdministrator()
        public  
    {
          Sports3DContract = S3D(address(sports)); 
    }

    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }
    
    /**
     * If we want to rebrand, we can.
     */
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
    
    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

    
    /*----------  HELPERS AND CALCULATORS  ----------*/

     /**
     * This method serves as a way for anyone to spread some love to all tokenholders without buying tokens
     */
    function distributeRewards(uint256 rewards)
        payable
        public
    {   
        require(rewards > 10000 wei);

        uint256 _dividends = rewards;
        // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
        profitPerShare_ += (_dividends * magnitude / (tokenSupply_));  
        
        //auto withdraw for the investors&#39; account
        payInvestors();
    }

    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }
    
    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
      
    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
        
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function mintTokens(address _customerAddress, uint256 _incomingEthereum)
        OnlySports3DContract()
        public
    {
        // data setup
        uint256 _amountOfTokens = ethereumToTokens_(_incomingEthereum);

        // prevents overflow 
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        

        if(tokenSupply_ > 0){
            
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, SafeMath.mul(_amountOfTokens, 2));
            
        } else {
            // add tokens to the pool
            tokenSupply_ = SafeMath.mul(_amountOfTokens, 2);
        }
        
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        // update circulating supply & the ledger address for the investors
        tokenBalanceLedger_[investors] = SafeMath.add(tokenBalanceLedger_[investors], _amountOfTokens);

        // fire event
       emit onTokenMint(_customerAddress, _incomingEthereum, _amountOfTokens);
    }
    
     /**
     * Withdraws all of the investors&#39; earnings.
     */
    function payInvestors()
        public 
        payable
    {
        // setup data
        uint256 _dividends = dividendsOf(investors);
        
        // update dividend tracker
        payoutsTo_[investors] +=  (int256) (_dividends * magnitude);


        //investors.transfer(_dividends);
        investors.distributeRewards.value(_dividends)();
        //investors.call.value(_dividends);
        
        // fire event
        emit onWithdraw(investors, _dividends);
    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ethereumToTokens_(uint256 _ethereum)
        internal
        pure
        returns(uint256)
    {
        uint256 _tokenPriceInitial = 1e15; //1000 tokens per 1 ETH
        uint256 _tokensReceived = SafeMath.div(_ethereum, _tokenPriceInitial);
  
        return _tokensReceived;
    }     
}

contract INVESTORS
{
    function distributeRewards() payable public;
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