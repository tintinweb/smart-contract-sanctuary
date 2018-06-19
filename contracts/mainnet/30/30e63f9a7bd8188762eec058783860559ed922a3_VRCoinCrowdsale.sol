pragma solidity ^0.4.16; 

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address owner) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
}



contract VRCoinCrowdsale {
    // Information about a single period
    struct Period
    {
         uint start;
         uint end;
         uint priceInWei;
         uint tokenToDistibute;
    }

    // Some constant about our expected token distribution
    uint public constant VRCOIN_DECIMALS = 9;
    uint public constant TOTAL_TOKENS_TO_DISTRIBUTE = 750000 * (10 ** VRCOIN_DECIMALS); // 750000 VRtokenc
    
    uint public exchangeRate = 853;
    
    address public owner; // The owner of the crowdsale
    bool public hasStarted; // Has the crowdsale started?
    Period public sale; // The configured periods for this crowdsale
    ERC20Interface public tokenWallet; // The token wallet contract used for this crowdsale

    // The multiplier necessary to change a coin amount to the token amount
    uint coinToTokenFactor = 10 ** VRCOIN_DECIMALS;
    
    // Fired once the transfer tokens to contract was successfull
    event Transfer(address to, uint amount);

    // Fired once the sale starts
    event Start(uint timestamp);

    // Fired whenever a contribution is made
    event Contribution(address indexed from, uint weiContributed, uint tokensReceived);

    function VRCoinCrowdsale(address walletAddress)
    {
         // Setup the owner and wallet
         owner = msg.sender;
         tokenWallet = ERC20Interface(walletAddress);

         // Make sure the provided token has the expected number of tokens to distribute
         require(tokenWallet.totalSupply() >= TOTAL_TOKENS_TO_DISTRIBUTE);

         // Make sure the owner actually controls all the tokens
         require(tokenWallet.balanceOf(owner) >= TOTAL_TOKENS_TO_DISTRIBUTE);

         // We haven&#39;t started yet
         hasStarted = false;
                 
         sale.start = 1521234001; // 00:00:01, March 05, 2018 UTC
         sale.end = 1525122001; // 00:00:01, Apl 30, 2018 UTC
         sale.priceInWei = (1 ether) / (exchangeRate * coinToTokenFactor); // 1 ETH = 750 VRCoin
         sale.tokenToDistibute = TOTAL_TOKENS_TO_DISTRIBUTE;
    }
    
    function updatePrice() {
         // Only the owner can do this
         require(msg.sender == owner);
        
         // Update price
         sale.priceInWei = (1 ether) / (exchangeRate * coinToTokenFactor);
    }
    
    function setExchangeRate(uint256 _rate) {
         // Only the owner can do this
         require(msg.sender == owner);        
        
         // The ether in $ dollar 
         exchangeRate = _rate;
    }

    // Start the crowdsale
    function startSale()
    {
         // Only the owner can do this
         require(msg.sender == owner);
         
         // Cannot start if already started
         require(hasStarted == false);

         // Attempt to transfer all tokens to the crowdsale contract
         // The owner needs to approve() the transfer of all tokens to this contract
         if (!tokenWallet.transferFrom(owner, this, sale.tokenToDistibute))
         {
            // Something has gone wrong, the owner no longer controls all the tokens?
            // We cannot proceed
            revert();
         }else{
            Transfer(this, sale.tokenToDistibute);
         }

         // Sanity check: verify the crowdsale controls all tokens
         require(tokenWallet.balanceOf(this) >= sale.tokenToDistibute);

         // The sale can begin
         hasStarted = true;

         // Fire event that the sale has begun
         Start(block.timestamp);
    }

    // Allow the current owner to change the owner of the crowdsale
    function changeOwner(address newOwner) public
    {
         // Only the owner can do this
         require(msg.sender == owner);

         // Change the owner
         owner = newOwner;
    }

    // Allow the owner to change the tokens for sale number
    // But only if the sale has not begun yet
    function changeTokenForSale(uint newAmount) public
    {
         // Only the owner can do this
         require(msg.sender == owner);
         
         // We can change period details as long as the sale hasn&#39;t started yet
         require(hasStarted == false);
         
         // Make sure the provided token has the expected number of tokens to distribute
         require(tokenWallet.totalSupply() >= newAmount);

         // Make sure the owner actually controls all the tokens
         require(tokenWallet.balanceOf(owner) >= newAmount);


         // Change the price for this period
         sale.tokenToDistibute = newAmount;
    }

    // Allow the owner to change the start/end time for a period
    // But only if the sale has not begun yet
    function changePeriodTime(uint start, uint end) public
    {
         // Only the owner can do this
         require(msg.sender == owner);

         // We can change period details as long as the sale hasn&#39;t started yet
         require(hasStarted == false);

         // Make sure the input is valid
         require(start < end);

         // Everything checks out, update the period start/end time
         sale.start = start;
         sale.end = end;
    }

    // Allow the owner to withdraw all the tokens remaining after the
    // crowdsale is over
    function withdrawTokensRemaining() public
         returns (bool)
    {
         // Only the owner can do this
         require(msg.sender == owner);

         // Get the ending timestamp of the crowdsale
         uint crowdsaleEnd = sale.end;

         // The crowsale must be over to perform this operation
         require(block.timestamp > crowdsaleEnd);

         // Get the remaining tokens owned by the crowdsale
         uint tokensRemaining = getTokensRemaining();

         // Transfer them all to the owner
         return tokenWallet.transfer(owner, tokensRemaining);
    }

    // Allow the owner to withdraw all ether from the contract after the
    // crowdsale is over
    function withdrawEtherRemaining() public
         returns (bool)
    {
         // Only the owner can do this
         require(msg.sender == owner);

         // Transfer them all to the owner
         owner.transfer(this.balance);

         return true;
    }

    // Check how many tokens are remaining for distribution
    function getTokensRemaining() public constant
         returns (uint256)
    {
         return tokenWallet.balanceOf(this);
    }

    // Calculate how many tokens can be distributed for the given contribution
    function getTokensForContribution(uint weiContribution) public constant 
         returns(uint tokenAmount, uint weiRemainder)
    {
         // The bonus for contributor
         uint256 bonus = 0;
         
         // Get the ending timestamp of the crowdsale
         uint crowdsaleEnd = sale.end;
        
         // The crowsale must be going to perform this operation
         require(block.timestamp <= crowdsaleEnd);

         // Get the price for this current period
         uint periodPriceInWei = sale.priceInWei;

         // Return the amount of tokens that can be purchased
         
         tokenAmount = weiContribution / periodPriceInWei;
         
	 	
            if (block.timestamp < 1521234001) {
                // bonus for contributor from 5.03.2018 to 16.03.2018 
                bonus = tokenAmount * 20 / 100;
            } else if (block.timestamp < 1521925201) {
                // bonus for contributor from 17.03.2018 to 24.03.2018 
                bonus = tokenAmount * 15 / 100;
            } else {
                // bonus for contributor
                bonus = tokenAmount * 10 / 100;
            }
		 

            
        tokenAmount = tokenAmount + bonus;
        
         // Return the amount of wei that would be left over
         weiRemainder = weiContribution % periodPriceInWei;
    }
    
    // Allow a user to contribute to the crowdsale
    function contribute() public payable
    {
         // Cannot contribute if the sale hasn&#39;t started
         require(hasStarted == true);

         // Calculate the tokens to be distributed based on the contribution amount
         var (tokenAmount, weiRemainder) = getTokensForContribution(msg.value);

         // Need to contribute enough for at least 1 token
         require(tokenAmount > 0);
         
         // Sanity check: make sure the remainder is less or equal to what was sent to us
         require(weiRemainder <= msg.value);

         // Make sure there are enough tokens left to buy
         uint tokensRemaining = getTokensRemaining();
         require(tokensRemaining >= tokenAmount);

         // Transfer the token amount from the crowd sale&#39;s token wallet to the
         // sender&#39;s token wallet
         if (!tokenWallet.transfer(msg.sender, tokenAmount))
         {
            // Unable to transfer funds, abort transaction
            revert();
         }

         // Return the remainder to the sender
         msg.sender.transfer(weiRemainder);

         // Since we refunded the remainder, the actual contribution is the amount sent
         // minus the remainder
         uint actualContribution = msg.value - weiRemainder;

         // Record the event
         Contribution(msg.sender, actualContribution, tokenAmount);
    }
    
    function() payable
    {
        contribute();
    } 
}