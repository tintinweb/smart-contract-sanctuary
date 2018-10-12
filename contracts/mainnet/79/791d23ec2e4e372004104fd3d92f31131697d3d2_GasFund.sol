pragma solidity 0.4.25;
// ----------------------------------------------------------------------------
// &#39;Gas Fund&#39; token contract, having Crowdsale and Investment functionality
//
// Contract Owner : 0x956881bc9Fbef7a2D176bfB371Be9Ab3e66683fD
// Symbol      	  : GAF
// Name           : Gas Fund
// Total supply   : 50,000,000,000
// Decimals       : 18
//
// Copyright &#169; 2018 onwards Gas Fund Inc. (https://gas-fund.com)
// Contract designed by GDO Infotech Pvt Ltd (www.GDO.co.in)
// ----------------------------------------------------------------------------
    
    /**
     * @title SafeMath
     * @dev Math operations with safety checks that throw on error
     */
    library SafeMath {
      function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
      }
    
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
      }
    
      function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }
    
      function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
      }
    }
    
    contract owned {
        address public owner;
    	using SafeMath for uint256;
    	
         constructor () public {
            owner = msg.sender;
        }
    
        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
    
        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
    }
    
    interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
    
    contract TokenERC20 {
        // Public variables of the token
        using SafeMath for uint256;
    	string public name;
        string public symbol;
        uint8 public decimals = 18;
        // 18 decimals is the strongly suggested default, avoid changing it
        uint256 public totalSupply;
    
        // This creates an array with all balances
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
    
        // This generates a public event on the blockchain that will notify clients
        event Transfer(address indexed from, address indexed to, uint256 value);
    
        // This notifies clients about the amount burnt
        event Burn(address indexed from, uint256 value);
    
        /**
         * Constrctor function
         *
         * Initializes contract with initial supply tokens to the creator of the contract
         */
        constructor (
            uint256 initialSupply,
            string tokenName,
            string tokenSymbol
        ) public {
            totalSupply = initialSupply.mul(1 ether);           // Update total supply with the decimal amount
            uint256 ownerTokens = 8000000;
            balanceOf[msg.sender] = ownerTokens.mul(1 ether);   // Give the creator 8,000,000 tokens
            balanceOf[this]=totalSupply.sub(ownerTokens.mul(1 ether));// Remaining tokens in the contract address for ICO and Dividends
            name = tokenName;                                   // Set the name for display purposes
            symbol = tokenSymbol;                               // Set the symbol for display purposes
        }
    
        /**
         * Internal transfer, only can be called by this contract
         */
        function _transfer(address _from, address _to, uint _value) internal {
            // Prevent transfer to 0x0 address. Use burn() instead
            require(_to != 0x0);
            // Check if the sender has enough
            require(balanceOf[_from] >= _value);
            // Check for overflows
            require(balanceOf[_to].add(_value) > balanceOf[_to]);
            // Save this for an assertion in the future
            uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
            // Subtract from the sender
            balanceOf[_from] = balanceOf[_from].sub(_value);
            // Add the same to the recipient
            balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(_from, _to, _value);
            // Asserts are used to use static analysis to find bugs in your code. They should never fail
            assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
        }
    
        /**
         * Transfer tokens
         *
         * Send `_value` tokens to `_to` from your account
         *
         * @param _to The address of the recipient
         * @param _value the amount to send
         */
        function transfer(address _to, uint256 _value) public {
            _transfer(msg.sender, _to, _value);
        }
    
        /**
         * Transfer tokens from other address
         *
         * Send `_value` tokens to `_to` in behalf of `_from`
         *
         * @param _from The address of the sender
         * @param _to The address of the recipient
         * @param _value the amount to send
         */
        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            require(_value <= allowance[_from][msg.sender]);     // Check allowance
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
            _transfer(_from, _to, _value);
            return true;
        }
    
        /**
         * Set allowance for other address
         *
         * Allows `_spender` to spend no more than `_value` tokens in your behalf
         *
         * @param _spender The address authorized to spend
         * @param _value the max amount they can spend
         */
        function approve(address _spender, uint256 _value) public
            returns (bool success) {
            allowance[msg.sender][_spender] = _value;
            return true;
        }
    
        /**
         * Set allowance for other address and notify
         *
         * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
         *
         * @param _spender The address authorized to spend
         * @param _value the max amount they can spend
         * @param _extraData some extra information to send to the approved contract
         */
        function approveAndCall(address _spender, uint256 _value, bytes _extraData)
            public
            returns (bool success) {
            tokenRecipient spender = tokenRecipient(_spender);
            if (approve(_spender, _value)) {
                spender.receiveApproval(msg.sender, _value, this, _extraData);
                return true;
            }
        }
    
        /**
         * Destroy tokens
         *
         * Remove `_value` tokens from the system irreversibly
         *
         * @param _value the amount of money to burn
         */
        function burn(uint256 _value) public returns (bool success) {
            require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);            // Subtract from the sender
            totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
           emit Burn(msg.sender, _value);
            return true;
        }
    
        /**
         * Destroy tokens from other account
         *
         * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
         *
         * @param _from the address of the sender
         * @param _value the amount of money to burn
         */
        function burnFrom(address _from, uint256 _value) public returns (bool success) {
            require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
            require(_value <= allowance[_from][msg.sender]);    // Check allowance
            balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the targeted balance
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);             // Subtract from the sender&#39;s allowance
            totalSupply = totalSupply.sub(_value);                              // Update totalSupply
          emit  Burn(_from, _value);
            return true;
        }
    }
    
    /********************************************************/
    /*       MAIN GAS FUND TOKEN CONTRACT STARTS HERE       */
    /********************************************************/
    
    contract GasFund is owned, TokenERC20 {
        using SafeMath for uint256;
        
        //**************************************************//
        //------------- Code for the GAF Token -------------//
        //**************************************************//
        
        // Public variables of the token
    	string internal tokenName = "Gas Fund";
        string internal tokenSymbol = "GAF";
        uint256 internal initialSupply = 50000000000; 	// Initial supply of the tokens   
	
    	// Records for the fronzen accounts 
        mapping (address => bool) public frozenAccount;
    
        // This generates a public event on the blockchain that will notify clients 
        event FrozenFunds(address target, bool frozen);
    
        // Initializes contract with initial supply of tokens sent to the creator as well as contract 
        constructor () TokenERC20(initialSupply, tokenName, tokenSymbol) public {
            tokenHolderExist[msg.sender] = true;
            tokenHolders.push(msg.sender);
        }
    
         
        /**
         * Transfer tokens - Internal transfer, only can be called by this contract
         * 
         * This checks if the sender or recipient is not fronzen
         * 
         * This keeps the track of total token holders and adds new holders as well.
         *
         * Send `_value` tokens to `_to` from your account
         *
         * @param _from The address of the sender
         * @param _to The address of the recipient
         * @param _value the amount of tokens to send
         */
        function _transfer(address _from, address _to, uint _value) internal {
            require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
            require (balanceOf[_from] >= _value);               // Check if the sender has enough
            require (balanceOf[_to].add(_value) >= balanceOf[_to]); // Check for overflows
            require(!frozenAccount[_from]);                     // Check if sender is frozen
            require(!frozenAccount[_to]);                       // Check if recipient is frozen
            balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the sender
            balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
            //if receiver does not exist in tokenHolderExist mapping, then add into it as well as add in tokenHolders array
            if(!tokenHolderExist[_to]){
                tokenHolderExist[_to] = true;
                tokenHolders.push(_to);
            }
           emit Transfer(_from, _to, _value);
        }
    
        /**
         * @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
         * 
         * @param target Address to be frozen
         * @param freeze either to freeze it or not
         */
        function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
          emit  FrozenFunds(target, freeze);
        }
    
        //**************************************************//
        //------------- Code for the Crowdsale -------------//
        //**************************************************//
    
        //public variables for the Crowdsale
        uint256 public icoStartDate = 1540800000 ;  // October 29, 2018 - 8am GMT
        uint256 public icoEndDate   = 1548057600 ;  // January 21, 2019 - 8am GMT
        uint256 public exchangeRate = 1000;         // 1 ETH = 1000 GAF which equals to 1 GAF = 0.001 ETH
        uint256 public totalTokensForICO = 12000000;// Tokens allocated for crowdsale
        uint256 public tokensSold = 0;              // How many tokens sold in crowdsale
        bool internal withdrawTokensOnlyOnce = true;// Admin can withdraw unsold tokens after ICO only once
        
        /**
         * Fallback function, only accepts ether if ICO is running or Reject
         * 
         * It calcualtes token amount from exchangeRate and also adds Bonuses if applicable
         * 
         * Ether will be forwarded to owner immidiately.
         */
		function () payable public {
    		require(icoEndDate > now);
    		require(icoStartDate < now);
    		uint ethervalueWEI=msg.value;
    		uint256 token = ethervalueWEI.mul(exchangeRate);    // token amount = weiamount * price
    		uint256 totalTokens = token.add(purchaseBonus(token)); // token + bonus
    		tokensSold = tokensSold.add(totalTokens);
    		_transfer(this, msg.sender, totalTokens);           // makes the token transfer
    		forwardEherToOwner();                               // send ether to owner
		}
        
        
        /**
         * Automatocally forwards ether from smart contract to owner address.
         */
		function forwardEherToOwner() internal {
			owner.transfer(msg.value); 
		}
		
		/**
         * Calculates purchase bonus according to the schedule.
         * 
         * @param _tokenAmount calculating tokens from amount of tokens 
         * 
         * @return bonus amount in wei
         * 
         */
		function purchaseBonus(uint256 _tokenAmount) public view returns(uint256){
		    uint256 first24Hours = icoStartDate + 86400;    //Level 1: First 24 hours = 50% bonus
		    uint256 week1 = first24Hours + 604800;    //Level 2: next 7 days = 40%
		    uint256 week2 = week1 + 604800;           //Level 3: next 7 days = 30%
		    uint256 week3 = week2 + 604800;           //Level 4: next 7 days = 25%
		    uint256 week4 = week3 + 604800;           //Level 5: next 7 days = 20%
		    uint256 week5 = week4 + 604800;           //Level 6: next 7 days = 15%
		    uint256 week6 = week5 + 604800;           //Level 7: next 7 days = 10%
		    uint256 week7 = week6 + 604800;           //Level 8: next 7 days = 5%

		    if(now < (first24Hours)){ 
                return _tokenAmount.div(2);             //50% bonus
		    }
		    else if(now > first24Hours && now < week1){
		        return _tokenAmount.mul(40).div(100);   //40% bonus
		    }
		    else if(now > week1 && now < week2){
		        return _tokenAmount.mul(30).div(100);   //30% bonus
		    }
		    else if(now > week2 && now < week3){
		        return _tokenAmount.mul(25).div(100);   //25% bonus
		    }
		    else if(now > week3 && now < week4){
		        return _tokenAmount.mul(20).div(100);   //20% bonus
		    }
		    else if(now > week4 && now < week5){
		        return _tokenAmount.mul(15).div(100);   //15% bonus
		    }
		    else if(now > week5 && now < week6){
		        return _tokenAmount.mul(10).div(100);   //10% bonus
		    }
		    else if(now > week6 && now < week7){
		        return _tokenAmount.mul(5).div(100);   //5% bonus
		    }
		    else{
		        return 0;
		    }
		}
        
        
        /**
         * Function to check wheter ICO is running or not. 
         * 
         * @return bool for whether ICO is running or not
         */
        function isICORunning() public view returns(bool){
            if(icoEndDate > now && icoStartDate < now){
                return true;                
            }else{
                return false;
            }
        }
        
        
        /**
         * Function to withdraw unsold tokens to owner after ICO is over 
         * 
         * This can be called only once. 
         */
        function withdrawTokens() onlyOwner public {
            require(icoEndDate < now);
            require(withdrawTokensOnlyOnce);
            uint256 tokens = (totalTokensForICO.mul(1 ether)).sub(tokensSold);
            _transfer(this, msg.sender, tokens);
            withdrawTokensOnlyOnce = false;
        }
        
        
        //*********************************************************//
        //------------- Code for the Divident Payment -------------//
        //*********************************************************//
        
        uint256 public dividendStartDate = 1549008000;  // February 1, 2019 8:00:00 AM - GMT
        uint256 public dividendMonthCounter = 0;
        uint256 public monthlyAllocation = 6594333;
        
        //Following mapping which track record whether token holder exist or not
        mapping(address => bool) public tokenHolderExist;
        
        //Array of addresses of token holders
        address[] public tokenHolders;
        
        //Following is necessary to split the iteration of array execution to token transfer
        uint256 public tokenHolderIndex = 0;
        
        
        event DividendPaid(uint256 totalDividendPaidThisRound, uint256 lastAddressIndex);

        /**
         * Just to check if dividend payment is available to send out 
         * 
         * This function will be called from the clients side to check if main dividend payment function should be called or not.
         * 
         * @return length or array of token holders. If 0, means not available. If more than zero, then the time has come for dividend payment
         */
        function checkDividendPaymentAvailable() public view returns (uint256){
            require(now > (dividendStartDate.add(dividendMonthCounter.mul(2592000))));
            return tokenHolders.length;
        }
        
        /**
         * Main function to call to distribute the dividend payment
         * 
         * It will only work every month once, according to dividend schedule
         * 
         * It will send only 150 token transfer at a time, to prevent eating out all the gas if token holders are so many.
         * 
         * If there are more than 150 token holders, then this function must be called multiple times
         * 
         * And it will resume from where it was left over.
         * 
         * Dividend percentage is is calculated and distributed from the monthly token allocation.
         * 
         * Monthly allocation multiplies every month by 1.5%
         */
        function runDividendPayment() public { 
            if(now > (dividendStartDate.add(dividendMonthCounter.mul(2592000)))){
                uint256 totalDividendPaidThisRound = 0;
                //Total token balance hold by all the token holders, is total supply minus - tokens in the contract
                uint256 totalTokensHold = totalSupply.sub(balanceOf[this]);
                for(uint256 i = 0; i < 150; i++){
                    if(tokenHolderIndex < tokenHolders.length){
                        uint256 userTokens = balanceOf[tokenHolders[tokenHolderIndex]];
                        if(userTokens > 0){
                            uint256 dividendPercentage =  userTokens.div(totalTokensHold);
                            uint256 dividend = monthlyAllocation.mul(1 ether).mul(dividendPercentage);
                            _transfer(this, tokenHolders[tokenHolderIndex], dividend);
                            tokenHolderIndex++;
                            totalDividendPaidThisRound = totalDividendPaidThisRound.add(dividend);
                        }
                    }else{
                        //this code will run only once in 30 days when dividendPaymentAvailable is true and all the dividend has been paid
                        tokenHolderIndex = 0;
                        dividendMonthCounter++;
                        monthlyAllocation = monthlyAllocation.add(monthlyAllocation.mul(15).div(1000)); //1.5% multiplication of monthlyAllocation each month
                        break;
                    }
                }
                //final tokenHolderIndex woluld be 0 instead of last index of the array.
                emit DividendPaid(totalDividendPaidThisRound,  tokenHolderIndex);
            }
        }
    }