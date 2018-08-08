pragma solidity ^0.4.23;
contract BullTokenBearMarket{
	uint256 constant scaleFactor = 0x10000000000000000;// 2^64
	int constant crr_n = 4;
	int constant crr_d = 5;
	
	uint256 constant fee_premine = 0;//No Premine

	int constant price_coeff = 0x57ea9ce452cde44ff;

	// Array between each address and their number of tokens.
	mapping(address => uint256) public bullBonds;
	mapping(address => uint256) public bearBonds;
	//cut down by a percentage when you sell out.
	mapping(address => uint256) public avgFactor_ethSpent;

	// Array between each address and how much Ether has been paid out to it.
	// Note that this is scaled by the scaleFactor variable.
	mapping(address => address) public reff;
	mapping(address => uint256) private tricklingPass;
	mapping(address => uint256) public pocket;
	mapping(address => int256) public payouts;

	// Variable tracking how many tokens are in existence overall.
	uint256 public totalBullSupply;
	uint256 public totalBearSupply;

	// Aggregate sum of all payouts.
	// Note that this is scaled by the scaleFactor variable.
	int256 totalPayouts;
	uint256 public trickleSum;
	uint256 public stakingRequirement = 1e18;
	
	address public lastGateway;
	uint256 constant trickTax = 4;

	//flux fee ratio and contract score keepers
	uint256 public withdrawSum;
	uint256 public investSum;

	// Variable tracking how much Ether each token is currently worth.
	// Note that this is scaled by the scaleFactor variable.
	uint256 earningsPerBull;
	uint256 earningsPerBear;

	event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed gateway
    );
	event onBoughtFor(
        address indexed buyerAddress,
        address indexed forWho,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed gateway
    );
	event onReinvestFor(
        address indexed buyerAddress,
        address indexed forWho,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed gateway
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 totalTokensAtTheTime,//maybe it&#39;d be cool to see what % people are selling from their total bank
        uint256 tokensBurned,
        uint256 ethereumEarned,
        uint256 resolved,
        address indexed gateway
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted,
        address indexed gateway
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    event onCashDividends(
        address indexed ownerAddress,
        address indexed receiverAddress,
        uint256 ethereumWithdrawn
    );

    event onTrickle(
        address indexed fromWho,
        address indexed finalReff,
        uint256 reward,
        uint256 passUp
    );


	// Returns the number of tokens currently held by _owner.
	function bondsOf(address _owner) public constant returns (uint256 balance) {
		return bullBonds[_owner]+bearBonds[_owner];
	}

	// Withdraws all dividends held by the caller sending the transaction, updates
	// the requisite global variables, and transfers Ether back to the caller.
	function withdraw(address to) public {
		to = nullFace(to);
		trickleUp(msg.sender);
		// Retrieve the dividends associated with the address the request came from.
		uint256 balance = dividends(msg.sender);

		// Update the payouts array, incrementing the request address by `balance`.
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		
		// Increase the total amount that&#39;s been paid out to maintain invariance.
		totalPayouts += (int256) (balance * scaleFactor);

		uint256 pocketETH = pocket[msg.sender];
		pocket[msg.sender] = 0;
		trickleSum -= pocketETH;

		balance += pocketETH;
		// Send the dividends to the address that requested the withdraw.
		withdrawSum += balance;
		to.transfer(balance);
		emit onCashDividends(msg.sender,to,balance);
	}
	function fullCycleSellBonds(uint256 balance) internal {
		// Send the cashed out stake to the address that requested the withdraw.
		withdrawSum += balance;
		msg.sender.transfer(balance);
		emit onWithdraw(msg.sender, balance);
	}


	// Sells your tokens for Ether. This Ether is assigned to the callers entry
	// in the tokenBalance array, and therefore is shown as a dividend. A second
	// call to withdraw() must be made to invoke the transfer of Ether back to your address.
	function sellBonds(uint256 _amount, bool bondType) public {
		uint256 bondBalance;
		if(bondType)
			bondBalance = bullBonds[msg.sender];
		else
			bondBalance = bearBonds[msg.sender];

		if(_amount <= bondBalance){
			if( _amount > 0)
				sell(_amount,bondType);
		}else{
			sell(bondBalance,bondType);
		}
	}

	// The slam-the-button escape hatch. Sells the callers tokens for Ether, then immediately
	// invokes the withdraw() function, sending the resulting Ether to the callers address.
    function getMeOutOfHere() public {
		sellBonds( bullBonds[msg.sender], true );
		sellBonds( bearBonds[msg.sender], false );
        withdraw(msg.sender);
	}

	function reffUp(address _reff) internal{
		address sender = msg.sender;
		if (_reff == 0x0000000000000000000000000000000000000000 || _reff == msg.sender){
			_reff = reff[sender];
		}
			
		if(  bondsOf(_reff) < stakingRequirement ){//if req not met
			if(lastGateway == 0x0000000000000000000000000000000000000000){
				lastGateway = sender;//first buyer ever
				_reff = sender;//first buyer is their own gateway/masternode
				
				//initialize fee pre-mine
				investSum = msg.value * fee_premine;
				withdrawSum = msg.value * fee_premine;
			}
			else
				_reff = lastGateway;//the lucky last player gets to be the gate way.
		}
		reff[sender] = _reff;
	}
	function nullFace(address _face) view internal returns (address){
		if (_face == 0x0000000000000000000000000000000000000000)
			return msg.sender;
	}
	function fund( address _reff, address forWho, bool bondType) payable public {
		// Don&#39;t allow for funding if the amount of Ether sent is less than 1 szabo.
		reffUp(_reff);
		if (msg.value > 0.000001 ether){
			investSum += msg.value;
		    buy( nullFace(forWho), bondType);
		    if (bondsOf(msg.sender)>0)
				lastGateway = msg.sender;
		} else {
			revert();
		}
    }

    function reinvest(address forWho, bool bondType) public {
		processReinvest( nullFace(forWho) , bondType);
	}

	// Function that returns the (dynamic) price of a single token.
	function price(bool buyOrSell) public constant returns (uint) {
        if(buyOrSell){
        	return getTokensForEther(1 finney);
        }else{
        	uint256 eth = getEtherForTokens(1 finney);
        	uint256 fee = fluxFeed(eth, false, false);
	        return eth - fee;
        }
    }

	function fluxFeed(uint256 _eth, bool slim_reinvest,bool newETH) public constant returns (uint256 amount) {
		uint256 finalInvestSum;
		if(newETH)
			finalInvestSum = investSum-_eth;//bigger buy bonus
		else
			finalInvestSum = investSum;

		uint256 contract_ETH = finalInvestSum - withdrawSum;
		if(slim_reinvest){//trickleSum can never be 0, trust me
			return  _eth/(contract_ETH/trickleSum) *  contract_ETH /investSum;
		}else{
			return  _eth *  contract_ETH / investSum;
		}
	}

	// Calculate the current dividends associated with the caller address. This is the net result
	// of multiplying the number of tokens held by their current value in Ether and subtracting the
	// Ether that has already been paid out.
	function dividends(address _owner) public constant returns (uint256 amount) {
		return (uint256) ((int256)( earningsPerBull * bullBonds[_owner] + earningsPerBear * bearBonds[_owner]) - payouts[_owner] ) / scaleFactor;
	}
	function dividends_by_type(address _owner,bool bondType) public constant returns (uint256 amount) {
		int256 earnings;
		if(bondType)
			earnings = (int256)( earningsPerBull * bullBonds[_owner] );
		else
			earnings = (int256)( earningsPerBear * bearBonds[_owner] );
		return (uint256) ( earnings - payouts[_owner] ) / scaleFactor;
	}

	function totalBondSupply() public constant returns (uint256 amount){
		return totalBearSupply+totalBullSupply;
	}

	function contractBalance() internal constant returns (uint256 amount){
		// msg.value is the amount of Ether sent by the transaction.
		return investSum - withdrawSum - msg.value - trickleSum;
	}
				function trickleUp(address fromWho) internal{//you can trickle up other people by giving them some.
					uint256 tricks = tricklingPass[ fromWho ];//this is the amount moving in the trickle flo
					if(tricks > 0){
						tricklingPass[ fromWho ] = 0;//we&#39;ve already captured the amount so set your tricklingPass flo to 0
						uint256 passUp = tricks * (investSum - withdrawSum)/investSum;
						uint256 reward = tricks-passUp;//and our remaining reward for ourselves is the amount we just slice off subtracted from the flo
						address finalReff;//we&#39;re not exactly sure who we&#39;re gonna pass this up to yet
						address reffo =  reff[ fromWho ];//this is who it should go up to. if everything is legit
						if( bondsOf(reffo) >= stakingRequirement){
							finalReff = reffo;//if that address is holding enough to stake, it&#39;s a legit node to flo up to.
						}else{
							finalReff = lastGateway;//if not, then we use the last buyer
						}
						tricklingPass[ finalReff ] += passUp;//so now we add that flo you&#39;ve passed up to the tricklingPass of the final Reff
						pocket[ finalReff ] += reward;// Reward
						emit onTrickle(fromWho, finalReff, reward, passUp);
					}
				}
								function buy(address forWho, bool bondType) internal {
									// Any transaction of less than 1 szabo is likely to be worth less than the gas used to send it.
									if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
										revert();	
									
									//Fee to pay existing holders, and the referral commission
									uint256 fee = 0; 
									uint256 trickle = 0; 
									if(bullBonds[forWho] != totalBullSupply){
										fee = fluxFeed(msg.value, false, true);
										trickle = fee/trickTax;
										fee = fee - trickle;
										tricklingPass[forWho] += trickle;
									}

									uint256 numEther = msg.value - ( fee + trickle );// The amount of Ether used to purchase new tokens for the caller.
									uint256 numTokens = 0;
									if(numEther > 0){
										numTokens = getTokensForEther(numEther);// The number of tokens which can be purchased for numEther.

										buyCalcAndPayout( forWho, fee, numTokens, numEther, reserve(), bondType );
									}
									if(forWho != msg.sender){//make sure you&#39;re not yourself
										//if forWho doesn&#39;t have a reff or if that masternode is weak, then reset it
										if( (bondsOf(forWho) == 0 && bondsOf(msg.sender) > bondsOf(reff[forWho]) ) || reff[forWho] == 0x0000000000000000000000000000000000000000 || (bondsOf(reff[forWho]) < stakingRequirement) )
											reff[forWho] = msg.sender;
										
										emit onBoughtFor(msg.sender, forWho, numEther, numTokens, reff[forWho] );
									}else{
										emit onTokenPurchase(forWho, numEther ,numTokens , reff[forWho] );
									}

									trickleSum += trickle;//add to trickle&#39;s Sum after reserve calculations
									trickleUp(forWho);
								}
													function buyCalcAndPayout(address forWho,uint256 fee,uint256 numTokens,uint256 numEther,uint256 res,bool bondType)internal{
														// The buyer fee, scaled by the scaleFactor variable.
														uint256 buyerFee = fee * scaleFactor;
														
														if (totalBullSupply > 0){// because ...
															uint256 holderReward;
															if(bondType){
																// Compute the bonus co-efficient for all existing holders and the buyer.
																// The buyer receives part of the distribution for each token bought in the
																// same way they would have if they bought each token individually.
																uint256 bonusCoEff = (scaleFactor - (res + numEther) * numTokens * scaleFactor / ( totalBondSupply()  + numTokens) / numEther)
										 						*(uint)(crr_d) / (uint)(crr_d-crr_n);
																
																// The total reward to be distributed amongst the masses is the fee (in Ether)
																// multiplied by the bonus co-efficient.
																holderReward = fee * bonusCoEff;
															}else{
																holderReward = fee;
															}
															
															buyerFee -= holderReward;
															
															// The Ether value per token is increased proportionally.
															earningsPerBull +=  holderReward / totalBullSupply;
														}
														//resolve reward tracking stuff
														avgFactor_ethSpent[forWho] += numEther;

														int256 payoutDiff;
														if(bondType){
															// Add the numTokens which were just created to the total supply. We&#39;re a crypto central bank!
															totalBullSupply += numTokens;
															// Assign the tokens to the balance of the buyer.
															bullBonds[forWho] += numTokens;
															// Update the payout array so that the buyer cannot claim dividends on previous purchases.
															// Also include the fee paid for entering the scheme.
															// First we compute how much was just paid out to the buyer...
															payoutDiff = (int256) ((earningsPerBull * numTokens) - buyerFee);	
														}else{
															totalBearSupply += numTokens;
															bearBonds[forWho] += numTokens;
															payoutDiff = (int256) ((earningsPerBear * numTokens));
														}
														// Then we update the payouts array for the buyer with this amount...
														payouts[forWho] += payoutDiff;
														
														// And then we finally add it to the variable tracking the total amount spent to maintain invariance.
														totalPayouts += payoutDiff;
													}
								// Sell function that takes tokens and converts them into Ether. Also comes with a 10% fee
								// to discouraging dumping, and means that if someone near the top sells, the fee distributed
								// will be *significant*.
								function TOKEN_scaleDown(uint256 value,uint256 reduce) internal view returns(uint256 x){
									uint256 bondsOfSender = bondsOf(msg.sender);
									return value * ( bondsOfSender - reduce) / bondsOfSender;
								}
								function sell(uint256 amount, bool bondType) internal {
								    uint256 numEthersBeforeFee = getEtherForTokens(amount);
									
									// x% of the resulting Ether is used to pay remaining holders.
									uint256 fee = 0;
									uint256 trickle = 0;
									if(totalBearSupply != bearBonds[msg.sender]){
										fee = fluxFeed(numEthersBeforeFee, false,false);
							        	trickle = fee/ trickTax;
										fee -= trickle;
										tricklingPass[msg.sender] +=trickle;
									}
									
									// Net Ether for the seller after the fee has been subtracted.
							        uint256 numEthers = numEthersBeforeFee - (fee+trickle);

									//How much you bought it for divided by how much you&#39;re getting back.
									//This means that if you get dumped on, you can get more resolve tokens if you sell out.
									uint256 resolved = mint(
										calcResolve(msg.sender,amount,numEthersBeforeFee),
										msg.sender
									);

									// *Remove* the numTokens which were just sold from the total supply.
									avgFactor_ethSpent[msg.sender] = TOKEN_scaleDown(avgFactor_ethSpent[msg.sender] , amount);
									
									int256 payoutDiff;
									if(bondType){
										totalBullSupply -= amount;
										// Remove the tokens from the balance of the buyer.
										bullBonds[msg.sender] -= amount;
										payoutDiff = (int256) (earningsPerBull * amount);//we don&#39;t add in numETH because it is immedietly paid out.
									}else{
										totalBearSupply -= amount;
										bearBonds[msg.sender] -= amount;
										payoutDiff = (int256) (earningsPerBear * amount);
									}
									
		
							        // We reduce the amount paid out to the seller (this effectively resets their payouts value to zero,
									// since they&#39;re selling all of their tokens). This makes sure the seller isn&#39;t disadvantaged if
									// they decide to buy back in.
									payouts[msg.sender] -= payoutDiff;
									
									// Decrease the total amount that&#39;s been paid out to maintain invariance.
							        totalPayouts -= payoutDiff;
							        

									// Check that we have tokens in existence (this is a bit of an irrelevant check since we&#39;re
									// selling tokens, but it guards against division by zero).
									if (totalBearSupply != bearBonds[msg.sender]){
										// Scale the Ether taken as the selling fee by the scaleFactor variable.
										uint256 etherFee = fee * scaleFactor;
										
										// Fee is distributed to all remaining token holders.
										// rewardPerShare is the amount gained per token thanks to this sell.
										uint256 rewardPerShare = etherFee / totalBearSupply;
										
										// The Ether value per token is increased proportionally.
										earningsPerBear +=  rewardPerShare;
									}
									fullCycleSellBonds(numEthers);
								
									trickleSum += trickle;
									trickleUp(msg.sender);
									emit onTokenSell(msg.sender,bearBonds[msg.sender]+amount,amount,numEthers,resolved,reff[msg.sender]);
								}

				// Converts the Ether accrued as dividends back into Staking tokens without having to
				// withdraw it first. Saves on gas and potential price spike loss.
				function processReinvest(address forWho,bool bondType) internal{
					// Retrieve the dividends associated with the address the request came from.
					uint256 balance = dividends(msg.sender);

					// Update the payouts array, incrementing the request address by `balance`.
					// Since this is essentially a shortcut to withdrawing and reinvesting, this step still holds.
					payouts[msg.sender] += (int256) (balance * scaleFactor);
					
					// Increase the total amount that&#39;s been paid out to maintain invariance.
					totalPayouts += (int256) (balance * scaleFactor);					
						
					// Assign balance to a new variable.
					uint256 pocketETH = pocket[msg.sender];
					uint value_ = (uint) (balance + pocketETH);
					pocket[msg.sender] = 0;
					
					// If your dividends are worth less than 1 szabo, or more than a million Ether
					// (in which case, why are you even here), abort.
					if (value_ < 0.000001 ether || value_ > 1000000 ether)
						revert();


					uint256 fee = 0; 
					uint256 trickle = 0;
					if(bullBonds[forWho] != totalBullSupply){
						fee = fluxFeed(value_, true,false );// reinvestment fees are lower than regular ones.
						trickle = fee/ trickTax;
						fee = fee - trickle;
						tricklingPass[forWho] += trickle;
					}
					
					// A temporary reserve variable used for calculating the reward the holder gets for buying tokens.
					// (Yes, the buyer receives a part of the distribution as well!)
					uint256 res = reserve() - balance;

					// The amount of Ether used to purchase new tokens for the caller.
					uint256 numEther = value_ - (fee+trickle);
					
					// The number of tokens which can be purchased for numEther.
					uint256 numTokens = calculateDividendTokens(numEther, balance);
					
					buyCalcAndPayout( forWho, fee, numTokens, numEther, res, bondType);

					if(forWho != msg.sender){//make sure you&#39;re not yourself
						//if the person you bought for doesn&#39;t have a reff, or the masternode is broken, then set it to yours
						//...OR...if the person you bought for is not holding any BONDs, then let the greatest holder claim their reff.
						address reffOfWho = reff[forWho];
						if( (bondsOf(forWho) == 0 && bondsOf(msg.sender) > bondsOf(reffOfWho) ) || reffOfWho == 0x0000000000000000000000000000000000000000 || ( bondsOf(reffOfWho) < stakingRequirement ) )
							reff[forWho] = msg.sender;

						emit onReinvestFor(msg.sender,forWho,numEther,numTokens,reff[forWho]);
					}else{
						emit onReinvestment(forWho,numEther,numTokens,reff[forWho]);	
					}

					trickleUp(forWho);
					trickleSum += trickle - pocketETH;
				}
	
	// Dynamic value of Ether in reserve, according to the CRR requirement.
	function reserve() internal constant returns (uint256 amount){
		return contractBalance()-((uint256) ((int256) (earningsPerBear * totalBearSupply + earningsPerBull * totalBullSupply) - totalPayouts ) / scaleFactor);
	}

	// Calculates the number of tokens that can be bought for a given amount of Ether, according to the
	// dynamic reserve and totalSupply values (derived from the buy and sell prices).
	function getTokensForEther(uint256 ethervalue) public constant returns (uint256 tokens) {
		return fixedExp(fixedLog(reserve() + ethervalue)*crr_n/crr_d + price_coeff) - totalBondSupply();
	}

	// Semantically similar to getTokensForEther, but subtracts the callers balance from the amount of Ether returned for conversion.
	function calculateDividendTokens(uint256 ethervalue, uint256 subvalue) public constant returns (uint256 tokens) {
		return fixedExp(fixedLog(reserve() - subvalue + ethervalue)*crr_n/crr_d + price_coeff) - totalBondSupply();
	}

	// Converts a number tokens into an Ether value.
	function getEtherForTokens(uint256 tokens) public constant returns (uint256 ethervalue) {
		// How much reserve Ether do we have left in the contract?
		uint256 reserveAmount = reserve();
		uint256 totalBonds = totalBondSupply();

		// If you&#39;re the Highlander (or bagholder), you get The Prize. Everything left in the vault.
		if (tokens == totalBonds )
			return reserveAmount;

		// If there would be excess Ether left after the transaction this is called within, return the Ether
		// corresponding to the equation in Dr Jochen Hoenicke&#39;s original Ponzi paper, which can be found
		// at https://test.jochen-hoenicke.de/eth/ponzitoken/ in the third equation, with the CRR numerator 
		// and denominator altered to 1 and 2 respectively.
		return reserveAmount - fixedExp((fixedLog(totalBonds  - tokens) - price_coeff) * crr_d/crr_n);
	}

	function () payable public {
		if (msg.value > 0) {
			fund(lastGateway, msg.sender, true);
		} else {
			withdraw(msg.sender);
		}
	}

										address public resolver = this;
									    uint256 public totalSupply;
									    uint256 constant private MAX_UINT256 = 2**256 - 1;
									    mapping (address => uint256) public balances;
									    mapping (address => mapping (address => uint256)) public allowed;
									    
									    string public name = "Resolve";
									    uint8 public decimals = 18;
									    string public symbol = "RSLV";
									    
									    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
									    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
									    event Resolved(address indexed _owner, uint256 amount);

									    function mint(uint256 amount,address _account) internal returns (uint minted){
									    	totalSupply += amount;
									    	balances[_account] += amount;
									    	emit Resolved(_account,amount);
									    	return amount;
									    }

									    function balanceOf(address _owner) public view returns (uint256 balance) {
									        return balances[_owner];
									    }
									    

										function calcResolve(address _owner,uint256 amount,uint256 _eth) public constant returns (uint256 calculatedResolveTokens) {
											return amount*amount*avgFactor_ethSpent[_owner]/bondsOf(_owner)/_eth/1000;
										}


									    function transfer(address _to, uint256 _value) public returns (bool success) {
									        require( balanceOf(msg.sender) >= _value);
									        balances[msg.sender] -= _value;
									        balances[_to] += _value;
									        emit Transfer(msg.sender, _to, _value);
									        return true;
									    }
										
									    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
									        uint256 allowance = allowed[_from][msg.sender];
									        require(    balanceOf(_from)  >= _value && allowance >= _value );
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

									    function resolveSupply() public view returns (uint256 balance) {
									        return totalSupply;
									    }

									    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
									        return allowed[_owner][_spender];
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
		int256 z = (s*s) / one;
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
}