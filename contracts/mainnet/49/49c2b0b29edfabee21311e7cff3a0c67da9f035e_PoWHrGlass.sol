pragma solidity ^0.4.22;/*
 _ _____  ___   _ _  __ 
 ` __ ___  ___  _  _  ,&#39;   
  `. __  ____   /__ ,&#39;
    `.  __  __ /  ,&#39;       
      `.__ _  /_,&#39;
        `. _ /,&#39;
          `./&#39;             
          ,/`.             
        ,&#39;/ __`.        
      ,&#39;_/_  _ _`.      
    ,&#39;__/_ ___ _  `.       
  ,&#39;_  /___ __ _ __ `.  
 &#39;-.._/____   _  __  _`.

The purpose of this contract is to fund the development of a protocol that secures individual sovereignty and incentivized communal responsibility.

Many thanks to the PoWH community for overall support

Key Features
	Flux Fee: Adapts to the "expansion" and "contraction" of the ecosystem&#39;s health.
	Resolve Tokens: The utility token that "licenses" new products and services into the ecosystem.

*/contract PoWHrGlass {

	// scaleFactor is used to convert Ether into tokens and vice-versa: they&#39;re of different
	// orders of magnitude, hence the need to bridge between the two.
	uint256 constant scaleFactor = 0x10000000000000000;  // 2^64

	// CRR = 50%
	// CRR is Cash Reserve Ratio (in this case Crypto Reserve Ratio).
	// For more on this: check out https://en.wikipedia.org/wiki/Reserve_requirement
	uint256 constant trickTax = 3;//tricklingUpTax
	uint256 constant tricklingUpTax = 6;//divided at every referral layer
	int constant crr_n = 1; // CRR numerator
	int constant crr_d = 2; // CRR denominator

	// The price coefficient. Chosen such that at 1 token total supply
	// the amount in reserve is 10 ether and token price is 1 Ether.
	int constant price_coeff = 0x2793DB20E4C20163A;//-0x570CAC130DBC4A9607;//-0x33548A9DD6D8344F0;

	// Array between each address and their number of staking bond tokens.
	mapping(address => uint256) public bondHoldings;
	mapping(address => uint256) public averageBuyInPrice;
	
	// Array between each address and how much Ether has been paid out to it.
	// Note that this is scaled by the scaleFactor variable.
	mapping(address => address) public reff;
	mapping(address => uint256) public tricklePocket;
	mapping(address => uint256) public trickling;
	mapping(address => int256) public payouts;

	// Variable tracking how many tokens are in existence overall.
	uint256 public totalBondSupply;

	// Aggregate sum of all payouts.
	// Note that this is scaled by the scaleFactor variable.
	int256 totalPayouts;
	uint256 public tricklingSum;
	uint256 public stakingRequirement = 1e18;
	address public lastGateway;

	//flux fee ratio score keepers
	uint256 public withdrawSum;
	uint256 public investSum;

	// Variable tracking how much Ether each token is currently worth.
	// Note that this is scaled by the scaleFactor variable.
	uint256 earningsPerToken;
	
	// Current contract balance in Ether
	uint256 public contractBalance;

	function PoWHrGlass() public {
	}


	event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy,
        uint256 feeFluxImport
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 totalTokensAtTheTime,//maybe it&#39;d be cool to see what % people are selling from their total bank
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
        uint256 ethereumWithdrawn,
        uint256 feeFluxExport
    );


	// Returns the number of tokens currently held by _owner.
	function holdingsOf(address _owner) public constant returns (uint256 balance) {
		return bondHoldings[_owner];
	}

	// Withdraws all dividends held by the caller sending the transaction, updates
	// the requisite global variables, and transfers Ether back to the caller.
	function withdraw() public {
		trickleUp();
		// Retrieve the dividends associated with the address the request came from.
		var balance = dividends(msg.sender);
		var pocketBalance = tricklePocket[msg.sender];
		tricklePocket[msg.sender] = 0;
		tricklingSum = sub(tricklingSum,pocketBalance);
		uint256 out = add(balance,pocketBalance);
		// Update the payouts array, incrementing the request address by `balance`.
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		// Increase the total amount that&#39;s been paid out to maintain invariance.
		totalPayouts += (int256) (balance * scaleFactor);
		
		// Send the dividends to the address that requested the withdraw.
		contractBalance = sub(contractBalance, out );

		withdrawSum = add(withdrawSum,out );
		msg.sender.transfer(out);
		emit onWithdraw(msg.sender, out, withdrawSum);
	}

	function withdrawOld(address to) public {
		trickleUp();
		// Retrieve the dividends associated with the address the request came from.
		var balance = dividends(msg.sender);
		var pocketBalance = tricklePocket[msg.sender];
		tricklePocket[msg.sender] = 0;
		tricklingSum = sub(tricklingSum,pocketBalance);//gotta preserve that things for dynamic calculation		
		uint256 out = add(balance,pocketBalance);

		// Update the payouts array, incrementing the request address by `balance`.
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		// Increase the total amount that&#39;s been paid out to maintain invariance.
		totalPayouts += (int256) (balance * scaleFactor);
		
		// Send the dividends to the address that requested the withdraw.
		contractBalance = sub(contractBalance, out);

		withdrawSum = add(withdrawSum, out);
		to.transfer(out);
		emit onWithdraw(to,out, withdrawSum);
	}


	// Sells your tokens for Ether. This Ether is assigned to the callers entry
	// in the bondHoldings array, and therefore is shown as a dividend. A second
	// call to withdraw() must be made to invoke the transfer of Ether back to your address.
	function sellMyTokens(uint256 _amount) public {
		if(_amount <= bondHoldings[msg.sender]){
			sell(_amount);
		}else{
			revert();
		}
	}

	// The slam-the-button escape hatch. Sells the callers tokens for Ether, then immediately
	// invokes the withdraw() function, sending the resulting Ether to the callers address.
    function getMeOutOfHere() public {
		sellMyTokens(bondHoldings[msg.sender]);
        withdraw();
	}

	function reffUp(address _reff) internal{
		address sender = msg.sender;
		if (_reff == 0x0000000000000000000000000000000000000000 || _reff == msg.sender)
			_reff = lastGateway;
			
		if(  bondHoldings[_reff] >= stakingRequirement ) {
			//good to go. good gateway
		}else{
			if(lastGateway == 0x0000000000000000000000000000000000000000){
				lastGateway = sender;//first buyer ever
				_reff = sender;//first buyer is their own gateway/masternode
			}
			else
				_reff = lastGateway;//the lucky last player gets to be the gate way.
		}

		reff[sender] = _reff;
	}
	// Gatekeeper function to check if the amount of Ether being sent isn&#39;t either
	// too small or too large. If it passes, goes direct to buy().
	function fund(address _reff) payable public {
		// Don&#39;t allow for funding if the amount of Ether sent is less than 1 szabo.
		reffUp(_reff);
		if (msg.value > 0.000001 ether) {
		    contractBalance = add(contractBalance, msg.value);
		    investSum = add(investSum,msg.value);
			buy();
			lastGateway = msg.sender;
		} else {
			revert();
		}
    }

	// Function that returns the (dynamic) price of buying a finney worth of tokens.
	function buyPrice() public constant returns (uint) {
		return getTokensForEther(1 finney);
	}

	// Function that returns the (dynamic) price of selling a single token.
	function sellPrice() public constant returns (uint) {
        var eth = getEtherForTokens(1 finney);

        uint256 fee;
        if(withdrawSum ==0){
    		return eth;
	    }
        else{
    		fee = fluxFeed(eth,false);
	    	return eth - fee;
	    }

        
    }
    function feeDiv(uint256 a, uint256 b) internal pure returns (uint256 amount) {
    	if (b == 0)
			return 0;
		else
			return div(a,b);
    }

	function fluxFeed(uint256 amount, bool slim_reinvest) public constant returns (uint256 fee) {
		if (withdrawSum == 0)
			return 0;
		else
		{
			if(slim_reinvest){
				return div( mul(amount , withdrawSum), mul(investSum,3) );//discount for supporting the Pyramid
			}else{
				return div( mul(amount , withdrawSum), investSum);// amount * withdrawSum / investSum	
			}
		}
		//gotta multiply and stuff in that order in order to get a high precision taxed amount.
		// because grouping (withdrawSum / investSum) can&#39;t return a precise decimal.
		//so instead we expand the value by multiplying then shrink it. by the denominator

		/*
		100eth IN & 100eth OUT = 100% tax fee (returning 1) !!!
		100eth IN & 50eth OUT = 50% tax fee (returning 2)
		100eth IN & 33eth OUT = 33% tax fee (returning 3)
		100eth IN & 25eth OUT = 25% tax fee (returning 4)
		100eth IN & 10eth OUT = 10% tax fee (returning 10)

		!!! keep in mind there is no fee if there are no holders. So if 100% of the eth has left the contract that means there can&#39;t possibly be holders to tax you
		*/
	}

	// Calculate the current dividends associated with the caller address. This is the net result
	// of multiplying the number of tokens held by their current value in Ether and subtracting the
	// Ether that has already been paid out.
	function dividends(address _owner) public constant returns (uint256 amount) {
		return (uint256) ((int256)(earningsPerToken * bondHoldings[_owner] ) - payouts[_owner]) / scaleFactor;
	}
	function cashWallet(address _owner) public constant returns (uint256 amount) {
		return tricklePocket[_owner] + dividends(_owner);
	}

	// Internal balance function, used to calculate the dynamic reserve value.
	function balance() internal constant returns (uint256 amount){
		// msg.value is the amount of Ether sent by the transaction.
		return contractBalance - msg.value - tricklingSum;
	}
				function trickleUp() internal{
					uint256 tricks = trickling[ msg.sender ];
					if(tricks > 0){
						trickling[ msg.sender ] = 0;
						uint256 passUp = div(tricks,tricklingUpTax);
						uint256 reward = sub(tricks,passUp);//trickling[]
						address reffo = reff[msg.sender];
						if( holdingsOf(reffo) >= stakingRequirement){ // your reff must be holding more than the staking requirement
							trickling[ reffo ] = add(trickling[ reffo ],passUp);
							tricklePocket[ reffo ] = add(tricklePocket[ reffo ],reward);
						}else{//basically. if your referral guy bailed out then he can&#39;t get the rewards, instead give it to the new guy that was baited in by this feature
							trickling[ lastGateway ] = add(trickling[ lastGateway ],passUp);
							tricklePocket[ lastGateway ] = add(tricklePocket[ lastGateway ],reward);
							reff[msg.sender] = lastGateway;
						}
					}
				}

								function buy() internal {
									// Any transaction of less than 1 szabo is likely to be worth less than the gas used to send it.
									if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
										revert();
													
									// msg.sender is the address of the caller.
									var sender = msg.sender;
									
									// 10% of the total Ether sent is used to pay existing holders.
									uint256 fee = 0; 
									uint256 trickle = 0; 
									if(bondHoldings[sender] < totalBondSupply){
										fee = fluxFeed(msg.value,false);
										trickle = div(fee, trickTax);
										fee = sub(fee , trickle);
										trickling[sender] = add(trickling[sender] ,  trickle);
									}
									var numEther = msg.value - (fee + trickle);// The amount of Ether used to purchase new tokens for the caller.
									var numTokens = getTokensForEther(numEther);// The number of tokens which can be purchased for numEther.


									// The buyer fee, scaled by the scaleFactor variable.
									var buyerFee = fee * scaleFactor;
									
									if (totalBondSupply > 0){// because ...
										// Compute the bonus co-efficient for all existing holders and the buyer.
										// The buyer receives part of the distribution for each token bought in the
										// same way they would have if they bought each token individually.
										uint256 bonusCoEff;
										bonusCoEff = (scaleFactor - (reserve() + numEther) * numTokens * scaleFactor / ( totalBondSupply + totalBondSupply + numTokens) / numEther) * (uint)(crr_d) / (uint)(crr_d-crr_n);
										
										
										// The total reward to be distributed amongst the masses is the fee (in Ether)
										// multiplied by the bonus co-efficient.
										var holderReward = fee * bonusCoEff;
										
										buyerFee -= holderReward;
										
										// The Ether value per token is increased proportionally.
										earningsPerToken += holderReward / totalBondSupply;
										
									}

									
									
									// Add the numTokens which were just created to the total supply. We&#39;re a crypto central bank!
									totalBondSupply = add(totalBondSupply, numTokens);

									var averageCostPerToken = div(numTokens , numEther);
									var newTokenSum = add(bondHoldings[sender], numTokens);
									var totalSpentBefore = mul(averageBuyInPrice[sender], holdingsOf(sender) );
									averageBuyInPrice[sender] = div( totalSpentBefore + mul( averageCostPerToken , numTokens), newTokenSum )  ;

									// Assign the tokens to the balance of the buyer.
									bondHoldings[sender] = add(bondHoldings[sender], numTokens);
									// Update the payout array so that the buyer cannot claim dividends on previous purchases.
									// Also include the fee paid for entering the scheme.
									// First we compute how much was just paid out to the buyer...
									int256 payoutDiff = (int256) ((earningsPerToken * numTokens) - buyerFee);
								
									
									
									// Then we update the payouts array for the buyer with this amount...
									payouts[sender] += payoutDiff;
									
									// And then we finally add it to the variable tracking the total amount spent to maintain invariance.
									totalPayouts += payoutDiff;

									
									
									tricklingSum = add(tricklingSum ,  trickle);
									trickleUp();
									emit onTokenPurchase(sender,numEther,numTokens, reff[sender], investSum);
								}

								// Sell function that takes tokens and converts them into Ether. Also comes with a 10% fee
								// to discouraging dumping, and means that if someone near the top sells, the fee distributed
								// will be *significant*.
								function sell(uint256 amount) internal {
								    var numEthersBeforeFee = getEtherForTokens(amount);
									
									// x% of the resulting Ether is used to pay remaining holders.
									uint256 fee = 0;
									uint256 trickle = 0;
									if(totalBondSupply != bondHoldings[msg.sender]){
										fee = fluxFeed(numEthersBeforeFee,false);//fluxFeed()
										trickle = div(fee, trickTax); 
										fee = sub(fee , trickle);
										trickling[msg.sender] = add(trickling[msg.sender] ,  trickle);
										tricklingSum = add(tricklingSum ,  trickle);
									} 
									
									// Net Ether for the seller after the fee has been subtracted.
							        var numEthers = numEthersBeforeFee - (fee + trickle);
									
									//How much you bought it for divided by how much you&#39;re getting back.
									//This means that if you get dumped on, you can get more resolve tokens if you sell out.
									mint( div( averageBuyInPrice[msg.sender] * scaleFactor , div(amount,numEthers) ) , msg.sender );

									// *Remove* the numTokens which were just sold from the total supply. We&#39;re /definitely/ a crypto central bank.
									totalBondSupply = sub(totalBondSupply, amount);
									// Remove the tokens from the balance of the buyer.
									bondHoldings[msg.sender] = sub(bondHoldings[msg.sender], amount);

							        // Update the payout array so that the seller cannot claim future dividends unless they buy back in.
									// First we compute how much was just paid out to the seller...
									int256 payoutDiff = (int256) (earningsPerToken * amount + (numEthers * scaleFactor));
									
									
							        // We reduce the amount paid out to the seller (this effectively resets their payouts value to zero,
									// since they&#39;re selling all of their tokens). This makes sure the seller isn&#39;t disadvantaged if
									// they decide to buy back in.
									payouts[msg.sender] -= payoutDiff;		
									
									// Decrease the total amount that&#39;s been paid out to maintain invariance.
							        totalPayouts -= payoutDiff;
									
									// Check that we have tokens in existence (this is a bit of an irrelevant check since we&#39;re
									// selling tokens, but it guards against division by zero).
									if (totalBondSupply > 0) {
										// Scale the Ether taken as the selling fee by the scaleFactor variable.
										var etherFee = fee * scaleFactor;
										
										// Fee is distributed to all remaining token holders.
										// rewardPerShare is the amount gained per token thanks to this sell.
										var rewardPerShare = etherFee / totalBondSupply;
										
										// The Ether value per token is increased proportionally.
										earningsPerToken = add(earningsPerToken, rewardPerShare);
									}
									
									trickleUp();
									emit onTokenSell(msg.sender,(bondHoldings[msg.sender]+amount),amount,numEthers);
								}

				// Converts the Ether accrued as dividends back into Staking tokens without having to
				// withdraw it first. Saves on gas and potential price spike loss.
				function reinvestDividends() public {
					// Retrieve the dividends associated with the address the request came from.
					var balance = tricklePocket[msg.sender];
					balance = add( balance, dividends(msg.sender) );
					tricklingSum = sub(tricklingSum,tricklePocket[msg.sender]);
					tricklePocket[msg.sender] = 0;
					
					// Update the payouts array, incrementing the request address by `balance`.
					// Since this is essentially a shortcut to withdrawing and reinvesting, this step still holds.
					payouts[msg.sender] += (int256) (balance * scaleFactor);
					
					// Increase the total amount that&#39;s been paid out to maintain invariance.
					totalPayouts += (int256) (balance * scaleFactor);
					
					// Assign balance to a new variable.
					uint value_ = (uint) (balance);
					
					// If your dividends are worth less than 1 szabo, or more than a million Ether
					// (in which case, why are you even here), abort.
					if (value_ < 0.000001 ether || value_ > 1000000 ether)
						revert();
						
					// msg.sender is the address of the caller.
					//var sender = msg.sender;
					

					// 10% of the total Ether sent is used to pay existing holders.
					//var fee = div(value_, 10);//old

					uint256 fee = 0; 
					uint256 trickle = 0;
					if(bondHoldings[msg.sender] != totalBondSupply){
						fee = fluxFeed(value_,true); // reinvestment fees are lower than regular ones.
						trickle = div(fee, trickTax);
						fee = sub(fee , trickle);
						trickling[msg.sender] += trickle;
					}
					

					var res = sub(reserve() , balance);
					// The amount of Ether used to purchase new tokens for the caller.
					var numEther = value_ - fee;
					
					// The number of tokens which can be purchased for numEther.
					var numTokens = calculateDividendTokens(numEther, balance);
					
					// The buyer fee, scaled by the scaleFactor variable.
					var buyerFee = fee * scaleFactor;
					
					// Check that we have tokens in existence (this should always be true), or
					// else you&#39;re gonna have a bad time.
					if (totalBondSupply > 0) {
						uint256 bonusCoEff;
						
						// Compute the bonus co-efficient for all existing holders and the buyer.
						// The buyer receives part of the distribution for each token bought in the
						// same way they would have if they bought each token individually.
						bonusCoEff =  (scaleFactor - (res + numEther ) * numTokens * scaleFactor / (totalBondSupply + numTokens) / numEther) * (uint)(crr_d) / (uint)(crr_d-crr_n);
					
						// The total reward to be distributed amongst the masses is the fee (in Ether)
						// multiplied by the bonus co-efficient.
						var holderReward = fee * bonusCoEff;
						
						buyerFee -= holderReward;

						// Fee is distributed to all existing token holders before the new tokens are purchased.
						// rewardPerShare is the amount gained per token thanks to this buy-in.
						
						// The Ether value per token is increased proportionally.
						earningsPerToken += holderReward / totalBondSupply;
					}
					
					int256 payoutDiff;
					// Add the numTokens which were just created to the total supply. We&#39;re a crypto central bank!
					totalBondSupply = add(totalBondSupply, numTokens);
					// Assign the tokens to the balance of the buyer.
					bondHoldings[msg.sender] = add(bondHoldings[msg.sender], numTokens);
					// Update the payout array so that the buyer cannot claim dividends on previous purchases.
					// Also include the fee paid for entering the scheme.
					// First we compute how much was just paid out to the buyer...
					payoutDiff = (int256) ((earningsPerToken * numTokens) - buyerFee);
				
					
					/*var averageCostPerToken = div(numTokens , numEther);
					var newTokenSum = add(bondHoldings_FNX[sender], numTokens);
					var totalSpentBefore = mul(averageBuyInPrice[sender], holdingsOf(sender) );*/
					//averageBuyInPrice[sender] = div( totalSpentBefore + mul( averageCostPerToken , numTokens), newTokenSum )  ;
					
					// Then we update the payouts array for the buyer with this amount...
					payouts[msg.sender] += payoutDiff;
					
					// And then we finally add it to the variable tracking the total amount spent to maintain invariance.
					totalPayouts += payoutDiff;

					

					tricklingSum += trickle;//add to trickle&#39;s Sum after reserve calculations
					trickleUp();
					emit onReinvestment(msg.sender,numEther,numTokens);
				}
	
	// Dynamic value of Ether in reserve, according to the CRR requirement.
	function reserve() internal constant returns (uint256 amount){
		return sub(balance(),
			  ((uint256) ((int256) (earningsPerToken * totalBondSupply) - totalPayouts ) / scaleFactor) 
		);
	}

	// Calculates the number of tokens that can be bought for a given amount of Ether, according to the
	// dynamic reserve and totalBondSupply values (derived from the buy and sell prices).
	function getTokensForEther(uint256 ethervalue) public constant returns (uint256 tokens) {
		return sub(fixedExp(fixedLog(reserve() + ethervalue)*crr_n/crr_d + price_coeff), totalBondSupply);
	}

	// Semantically similar to getTokensForEther, but subtracts the callers balance from the amount of Ether returned for conversion.
	function calculateDividendTokens(uint256 ethervalue, uint256 subvalue) public constant returns (uint256 tokens) {
		return sub(fixedExp(fixedLog(reserve() - subvalue + ethervalue)*crr_n/crr_d + price_coeff), totalBondSupply);
	}

	// Converts a number tokens into an Ether value.
	function getEtherForTokens(uint256 tokens) public constant returns (uint256 ethervalue) {
		// How much reserve Ether do we have left in the contract?
		var reserveAmount = reserve();

		// If you&#39;re the Highlander (or bagholder), you get The Prize. Everything left in the vault.
		if (tokens == (totalBondSupply) )
			return reserveAmount;

		// If there would be excess Ether left after the transaction this is called within, return the Ether
		// corresponding to the equation in Dr Jochen Hoenicke&#39;s original Ponzi paper, which can be found
		// at https://test.jochen-hoenicke.de/eth/ponzitoken/ in the third equation, with the CRR numerator 
		// and denominator altered to 1 and 2 respectively.
		return sub(reserveAmount, fixedExp((fixedLog(totalBondSupply - tokens) - price_coeff) * crr_d/crr_n));
	}

	// You don&#39;t care about these, but if you really do they&#39;re hex values for 
	// co-efficients used to simulate approximations of the log and exp functions.
	int256  constant one        = 0x10000000000000000;
	uint256 constant sqrt2      = 0x16a09e667f3bcc908;
	uint256 constant sqrtdot5   = 0x0b504f333f9de6484;
	int256  constant ln2        = 0x0b17217f7d1cf79ac;
	int256  constant ln2_64dot5 = 0x2cb53f09f05cc627c8;
	int256  constant c1         = 0x1ffffffffff9dac9b;
	int256  constant c3         = 0x0aaaaaaac16877908;
	int256  constant c5         = 0x0666664e5e9fa0c99;
	int256  constant c7         = 0x049254026a7630acf;
	int256  constant c9         = 0x038bd75ed37753d68;
	int256  constant c11        = 0x03284a0c14610924f;

	// The polynomial R = c1*x + c3*x^3 + ... + c11 * x^11
	// approximates the function log(1+x)-log(1-x)
	// Hence R(s) = log((1+s)/(1-s)) = log(a)
	function fixedLog(uint256 a) internal pure returns (int256 log) {
		int32 scale = 0;
		while (a > sqrt2) {
			a /= 2;
			scale++;
		}
		while (a <= sqrtdot5) {
			a *= 2;
			scale--;
		}
		int256 s = (((int256)(a) - one) * one) / ((int256)(a) + one);
		var z = (s*s) / one;
		return scale * ln2 +
			(s*(c1 + (z*(c3 + (z*(c5 + (z*(c7 + (z*(c9 + (z*c11/one))
				/one))/one))/one))/one))/one);
	}

	int256 constant c2 =  0x02aaaaaaaaa015db0;
	int256 constant c4 = -0x000b60b60808399d1;
	int256 constant c6 =  0x0000455956bccdd06;
	int256 constant c8 = -0x000001b893ad04b3a;
	
	// The polynomial R = 2 + c2*x^2 + c4*x^4 + ...
	// approximates the function x*(exp(x)+1)/(exp(x)-1)
	// Hence exp(x) = (R(x)+x)/(R(x)-x)
	function fixedExp(int256 a) internal pure returns (uint256 exp) {
		int256 scale = (a + (ln2_64dot5)) / ln2 - 64;
		a -= scale*ln2;
		int256 z = (a*a) / one;
		int256 R = ((int256)(2) * one) +
			(z*(c2 + (z*(c4 + (z*(c6 + (z*c8/one))/one))/one))/one);
		exp = (uint256) (((R + a) * one) / (R - a));
		if (scale >= 0)
			exp <<= scale;
		else
			exp >>= -scale;
		return exp;
	}
	
	// The below are safemath implementations of the four arithmetic operators
	// designed to explicitly prevent over- and under-flows of integer values.

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

	// reff fair
	function () payable public {
		//revert();// msg.value is the amount of Ether sent by the transaction.
		
		if (msg.value > 0) {
			fund(lastGateway);
		} else {
			withdrawOld(msg.sender);
		}
	}


/*                                                                             
                                                    @@@@@                          
                                                @@@@@@@@@@                         
                                             @@@@@@@@@@@@@@                        
                                          @@@@@@@@@@@@@@@@                         
           @@                          @@@@@@@@@@@@@@@                @@           
          @@@@@@@                     @@@@@@@@@@@@@               @@@@@@@          
         @@@@@@@@@@@                  @@@@@@@@@                @@@@@@@@@@@         
        @@@@@@@@@@@@@@@@              @@@@@@@               @@@@@@@@@@@@@@@        
           @@@@@@@@@@@@@@@@           @@@@@@@           @@@@@@@@@@@@@@@@           
               @@@@@@@@@@@@           @@@@@@@           @@@@@@@@@@@@@              
                  @@@@@@@@            @@@@@@@             @@@@@@@                  
                     @@@              @@@@@@@              @@@                     
                                      @@@@@@@                                      
           @@                         @@@@@@@                                      
          @@@@@@                   @@@@@@@@@@@@@                                   
         @@@@@@@@@@             @@@@@@@@@@@@@@@@@@@                                
        @@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@                            
           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@                         
              @@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@                      
                 @@@@@@@@@@@@@@@@@               @@@@@@@@@@@@                      
                     @@@@@@@@@@                      @@@@@@@@                      
                         @@                           @@@@@@@                      
                                                      @@@@@@@                      
                                                      @@@@@@@                      
                                      @@@@@@@         @@@@@@@                      
                                      @@@@@@@         @@@@@@@                      
                                      @@@@@@@         @@@@@@@                      
                                      @@@@@@@         @@@@@@@                      
                                      @@@@@@@         @@@@@@@                      
                                      @@@@@@@                                      
                                      @@@@@@@                                      
                                      @@@@@@@                                      
                                      @@@@@@@                                      
*/

	uint256 public totalSupply;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    string public name = "0xBabylon";
    uint8 public decimals = 18; 
    string public symbol = "PoWHr";
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function mint(uint256 amount,address _account) internal{
    	totalSupply += amount;
    	balances[_account] += amount;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
	
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}