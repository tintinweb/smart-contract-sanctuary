pragma solidity ^0.4.23;

contract LotteryFactory {

	// contract profit
	uint public commissionSum;
	// default lottery params
	Params public defaultParams;
	// lotteries
	Lottery[] public lotteries;
	// lotteries count
	uint public lotteryCount;
	// contract owner address
	address public owner;

	struct Lottery {
		mapping(address => uint) ownerTokenCount;
		mapping(address => uint) ownerTokenCountToSell;
		mapping(address => uint) sellerId;
		address[] sellingAddresses;
		uint[] sellingAmounts;
		uint createdAt;
		uint tokenCount;
		uint tokenCountToSell;
		uint winnerSum;
		bool prizeRedeemed;
		address winner;
		address[] participants;
		Params params;
	}

	// lottery params
	struct Params {
		uint gameDuration;
		uint initialTokenPrice; 
		uint durationToTokenPriceUp; 
		uint tokenPriceIncreasePercent; 
		uint tradeCommission; 
		uint winnerCommission;
	}

	// event fired on purchase error, when user tries to buy a token from a seller
	event PurchaseError(address oldOwner, uint amount);

	/**
	 * Throws if called by account different from the owner account
	 */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	/**
	 * @dev Sets owner and default lottery params
	 */
	constructor() public {
		// set owner
		owner = msg.sender;
		// set default params
		updateParams(4 hours, 0.01 ether, 15 minutes, 10, 1, 10);
		// create a new lottery
		_createNewLottery();
	}

	/**
	 * @dev Approves tokens for selling
	 * @param _tokenCount amount of tokens to place for selling
	 */
	function approveToSell(uint _tokenCount) public {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		// check that user has enough tokens to sell
		require(lottery.ownerTokenCount[msg.sender] - lottery.ownerTokenCountToSell[msg.sender] >= _tokenCount);
		// if there are no sales or this is user&#39;s first sale
		if(lottery.sellingAddresses.length == 0 || lottery.sellerId[msg.sender] == 0 && lottery.sellingAddresses[0] != msg.sender) {
			uint sellingAddressesCount = lottery.sellingAddresses.push(msg.sender);
			uint sellingAmountsCount = lottery.sellingAmounts.push(_tokenCount);
			assert(sellingAddressesCount == sellingAmountsCount);
			lottery.sellerId[msg.sender] = sellingAddressesCount - 1;
		} else {
			// seller exists and placed at least 1 sale
			uint sellerIndex = lottery.sellerId[msg.sender];
			lottery.sellingAmounts[sellerIndex] += _tokenCount;
		}
		// update global lottery variables
		lottery.ownerTokenCountToSell[msg.sender] += _tokenCount;
		lottery.tokenCountToSell += _tokenCount;
	}

	/**
	 * @dev Returns token balance by user address
	 * @param _user user address
	 * @return token acount on the user balance
	 */
	function balanceOf(address _user) public view returns(uint) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		return lottery.ownerTokenCount[_user];
	}

	/**
	 * @dev Returns selling token balance by user address
	 * @param _user user address
	 * @return token acount selling by user
	 */
	function balanceSellingOf(address _user) public view returns(uint) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		return lottery.ownerTokenCountToSell[_user];
	}

	/**
	 * @dev Buys tokens
	 */
	function buyTokens() public payable {
		if(_isNeededNewLottery()) _createNewLottery();
		// get latest lottery
		Lottery storage lottery = lotteries[lotteryCount - 1];
		// get token count to buy
		uint price = _getCurrentTokenPrice();
		uint tokenCountToBuy = msg.value / price;
		// any extra eth added to winner sum
		uint rest = msg.value - tokenCountToBuy * price;
		if( rest > 0 ){
		    lottery.winnerSum = lottery.winnerSum + rest;
		}
		// check that user wants to buy at least 1 token
		require(tokenCountToBuy > 0);
		// buy tokens from sellers
		uint tokenCountToBuyFromSeller = _getTokenCountToBuyFromSeller(tokenCountToBuy);
		if(tokenCountToBuyFromSeller > 0) {
		 	_buyTokensFromSeller(tokenCountToBuyFromSeller);
		}
		// buy tokens from system
		uint tokenCountToBuyFromSystem = tokenCountToBuy - tokenCountToBuyFromSeller;
		if(tokenCountToBuyFromSystem > 0) {
			_buyTokensFromSystem(tokenCountToBuyFromSystem);
		}
		// add sender to participants
		_addToParticipants(msg.sender);
		// update winner values
		lottery.winnerSum += tokenCountToBuyFromSystem * price;
		lottery.winner = _getWinner();
	}

	/**
	 * @dev Removes tokens from selling
	 * @param _tokenCount amount of tokens to remove from selling
	 */
	function disapproveToSell(uint _tokenCount) public {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		// check that user has enough tokens to cancel selling
		require(lottery.ownerTokenCountToSell[msg.sender] >= _tokenCount);
		// remove tokens from selling
		uint sellerIndex = lottery.sellerId[msg.sender];
		lottery.sellingAmounts[sellerIndex] -= _tokenCount;
		// update global lottery variables
		lottery.ownerTokenCountToSell[msg.sender] -= _tokenCount;
		lottery.tokenCountToSell -= _tokenCount;
	}

	/**
	 * @dev Returns lottery details by index
	 * @param _index lottery index
	 * @return lottery details
	 */
	function getLotteryAtIndex(uint _index) public view returns(
		uint createdAt,
		uint tokenCount,
		uint tokenCountToSell,
		uint winnerSum,
		address winner,
		bool prizeRedeemed,
		address[] participants,
		uint paramGameDuration,
		uint paramInitialTokenPrice,
		uint paramDurationToTokenPriceUp,
		uint paramTokenPriceIncreasePercent,
		uint paramTradeCommission,
		uint paramWinnerCommission
	) {
		// check that lottery exists
		require(_index < lotteryCount);
		// return lottery details
		Lottery memory lottery = lotteries[_index];
		createdAt = lottery.createdAt;
		tokenCount = lottery.tokenCount;
		tokenCountToSell = lottery.tokenCountToSell;
		winnerSum = lottery.winnerSum;
		winner = lottery.winner;
		prizeRedeemed = lottery.prizeRedeemed;
		participants = lottery.participants;
		paramGameDuration = lottery.params.gameDuration;
		paramInitialTokenPrice = lottery.params.initialTokenPrice;
		paramDurationToTokenPriceUp = lottery.params.durationToTokenPriceUp;
		paramTokenPriceIncreasePercent = lottery.params.tokenPriceIncreasePercent;
		paramTradeCommission = lottery.params.tradeCommission;
		paramWinnerCommission = lottery.params.winnerCommission;
	}

	/**
	 * @dev Returns arrays of addresses who sell tokens and corresponding amounts
	 * @return array of addresses who sell tokens and array of amounts
	 */
	function getSales() public view returns(address[], uint[]) {
		// get latest lottery
		Lottery memory lottery = lotteries[lotteryCount - 1];
		// return array of addresses who sell tokens and amounts
		return (lottery.sellingAddresses, lottery.sellingAmounts);
	}

	/**
	 * @dev Returns top users by balances for current lottery
	 * @param _n number of top users to find
	 * @return array of addresses and array of balances sorted in balance descend
	 */
	function getTop(uint _n) public view returns(address[], uint[]) {
		// check that n > 0
		require(_n > 0);
		// get latest lottery
		Lottery memory lottery = lotteries[lotteryCount - 1];
		// find top n users with highest token balances
		address[] memory resultAddresses = new address[](_n);
		uint[] memory resultBalances = new uint[](_n);
		for(uint i = 0; i < _n; i++) {
			// if current iteration is more than number of participants then continue
			if(i > lottery.participants.length - 1) continue;
			// if 1st iteration then set 0 values
			uint prevMaxBalance = i == 0 ? 0 : resultBalances[i-1];
			address prevAddressWithMax = i == 0 ? address(0) : resultAddresses[i-1];
			uint currentMaxBalance = 0;
			address currentAddressWithMax = address(0);
			for(uint j = 0; j < lottery.participants.length; j++) {
				uint balance = balanceOf(lottery.participants[j]);
				// if first iteration then simply find max
				if(i == 0) {
					if(balance > currentMaxBalance) {
						currentMaxBalance = balance;
						currentAddressWithMax = lottery.participants[j];
					}
				} else {
					// find balance that is less or equal to the prev max
					if(prevMaxBalance >= balance && balance > currentMaxBalance && lottery.participants[j] != prevAddressWithMax) {
						currentMaxBalance = balance;
						currentAddressWithMax = lottery.participants[j];
					}
				}
			}
			resultAddresses[i] = currentAddressWithMax;
			resultBalances[i] = currentMaxBalance;
		}
		return(resultAddresses, resultBalances);
	}

	/**
	 * @dev Returns seller id by user address
	 * @param _user user address
	 * @return seller id/index
	 */
	function sellerIdOf(address _user) public view returns(uint) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		return lottery.sellerId[_user];
	}

	/**
	 * @dev Updates lottery parameters
	 * @param _gameDuration duration of the lottery in seconds
	 * @param _initialTokenPrice initial price for 1 token in wei
	 * @param _durationToTokenPriceUp how many seconds should pass to increase token price
	 * @param _tokenPriceIncreasePercent percentage of token increase. ex: 2 will increase token price by 2% each time interval
	 * @param _tradeCommission commission in percentage for trading tokens. When user1 sells token to user2 for 1.15 eth then commision applied
	 * @param _winnerCommission commission in percentage for winning sum
	 */
	function updateParams(
		uint _gameDuration,
		uint _initialTokenPrice,
		uint _durationToTokenPriceUp,
		uint _tokenPriceIncreasePercent,
		uint _tradeCommission,
		uint _winnerCommission
	) public onlyOwner {
		Params memory params;
		params.gameDuration = _gameDuration;
		params.initialTokenPrice = _initialTokenPrice;
		params.durationToTokenPriceUp = _durationToTokenPriceUp;
		params.tokenPriceIncreasePercent = _tokenPriceIncreasePercent;
		params.tradeCommission = _tradeCommission;
		params.winnerCommission = _winnerCommission;
		defaultParams = params;
	}

	/**
	 * @dev Withdraws commission sum to the owner
	 */
	function withdraw() public onlyOwner {
		// check that commision > 0
		require(commissionSum > 0);
		// save commission for later transfer and reset
		uint commissionSumToTransfer = commissionSum;
		commissionSum = 0;
		// transfer commission to owner
		owner.transfer(commissionSumToTransfer);
	}

	/**
	 * @dev Withdraws ether for winner
	 * @param _lotteryIndex lottery index
	 */
	function withdrawForWinner(uint _lotteryIndex) public {
		// check that lottery exists
		require(lotteries.length > _lotteryIndex);
		// check that sender is winner
		Lottery storage lottery = lotteries[_lotteryIndex];
		require(lottery.winner == msg.sender);
		// check that lottery is over
		require(now > lottery.createdAt + lottery.params.gameDuration);
		// check that prize is not redeemed
		require(!lottery.prizeRedeemed);
		// update contract commission sum and winner sum
		uint winnerCommissionSum = _getValuePartByPercent(lottery.winnerSum, lottery.params.winnerCommission);
		commissionSum += winnerCommissionSum;
		uint winnerSum = lottery.winnerSum - winnerCommissionSum;
		// mark lottery as redeemed
		lottery.prizeRedeemed = true;
		// send winner his prize
		lottery.winner.transfer(winnerSum);
	}

	/**
	 * @dev Disallow users to send ether directly to the contract
	 */
	function() public payable {
		revert();
	}

	/**
	 * @dev Adds user address to participants
	 * @param _user user address
	 */
	function _addToParticipants(address _user) internal {
		// check that user is not in participants
		Lottery storage lottery = lotteries[lotteryCount - 1];
		bool isParticipant = false;
		for(uint i = 0; i < lottery.participants.length; i++) {
			if(lottery.participants[i] == _user) {
				isParticipant = true;
				break;
			}
		}
		if(!isParticipant) {
			lottery.participants.push(_user);
		}
	}

	/**
	 * @dev Buys tokens from sellers
	 * @param _tokenCountToBuy amount of tokens to buy from sellers
	 */
	function _buyTokensFromSeller(uint _tokenCountToBuy) internal {
		// check that token count is not 0
		require(_tokenCountToBuy > 0);
		// get latest lottery
		Lottery storage lottery = lotteries[lotteryCount - 1];
		// get current token price and commission sum
		uint currentTokenPrice = _getCurrentTokenPrice();
		uint currentCommissionSum = _getValuePartByPercent(currentTokenPrice, lottery.params.tradeCommission);
		uint purchasePrice = currentTokenPrice - currentCommissionSum;
		// foreach selling amount
		uint tokensLeftToBuy = _tokenCountToBuy;
		for(uint i = 0; i < lottery.sellingAmounts.length; i++) {
			// if amount != 0 and buyer does not purchase his own tokens
			if(lottery.sellingAmounts[i] != 0 && lottery.sellingAddresses[i] != msg.sender) {
				address oldOwner = lottery.sellingAddresses[i];
				// find how many tokens to substitute
				uint tokensToSubstitute;
				if(tokensLeftToBuy < lottery.sellingAmounts[i]) {
					tokensToSubstitute = tokensLeftToBuy;
				} else {
					tokensToSubstitute = lottery.sellingAmounts[i];
				}
				// update old owner balance and send him ether
				lottery.sellingAmounts[i] -= tokensToSubstitute;
				lottery.ownerTokenCount[oldOwner] -= tokensToSubstitute;
				lottery.ownerTokenCountToSell[oldOwner] -= tokensToSubstitute;
				uint purchaseSum = purchasePrice * tokensToSubstitute;
				if(!oldOwner.send(purchaseSum)) {
					emit PurchaseError(oldOwner, purchaseSum);
				}
				// check if user bought enough
				tokensLeftToBuy -= tokensToSubstitute;
				if(tokensLeftToBuy == 0) break;
			}
		}
		// update contract variables
		commissionSum += _tokenCountToBuy * purchasePrice;
		lottery.ownerTokenCount[msg.sender] += _tokenCountToBuy;
		lottery.tokenCountToSell -= _tokenCountToBuy;
	}

	/**
	 * @dev Buys tokens from system(mint) for sender
	 * @param _tokenCountToBuy token count to buy
	 */
	function _buyTokensFromSystem(uint _tokenCountToBuy) internal {
		// check that token count is not 0
		require(_tokenCountToBuy > 0);
		// get latest lottery
		Lottery storage lottery = lotteries[lotteryCount - 1];
		// mint tokens for buyer
		lottery.ownerTokenCount[msg.sender] += _tokenCountToBuy;
		// update lottery values
		lottery.tokenCount += _tokenCountToBuy;
	}

	/**
	 * @dev Creates a new lottery
	 */
	function _createNewLottery() internal {
		Lottery memory lottery;
		lottery.createdAt = _getNewLotteryCreatedAt();
		lottery.params = defaultParams;
		lotteryCount = lotteries.push(lottery);
	}

	/**
	 * @dev Returns current price for 1 token
	 * @return token price
	 */
	function _getCurrentTokenPrice() internal view returns(uint) {
		Lottery memory lottery = lotteries[lotteryCount - 1];
		uint diffInSec = now - lottery.createdAt;
		uint stageCount = diffInSec / lottery.params.durationToTokenPriceUp;
		uint price = lottery.params.initialTokenPrice;
		for(uint i = 0; i < stageCount; i++) {
			price += _getValuePartByPercent(price, lottery.params.tokenPriceIncreasePercent);
		}
		return price;
	}

	/**
	 * @dev Returns new lottery created at. 
	 * Ex: latest lottery started at 0:00 and finished at 6:00. Now it is 7:00. User buys token. New lottery createdAt will be 06:00:01.
	 * @return new lottery created at timestamp
	 */
	function _getNewLotteryCreatedAt() internal view returns(uint) {
		// if there are no lotteries then return now
		if(lotteries.length == 0) return now;
		// else loop while new created at time is not found
		// get latest lottery end time
		uint latestEndAt = lotteries[lotteryCount - 1].createdAt + lotteries[lotteryCount - 1].params.gameDuration;
		// get next lottery end time
		uint nextEndAt = latestEndAt + defaultParams.gameDuration;
		while(now > nextEndAt) {
			nextEndAt += defaultParams.gameDuration;
		}
		return nextEndAt - defaultParams.gameDuration;
	}

	/**
	 * @dev Returns number of tokens that can be bought from seller
	 * @param _tokenCountToBuy token count to buy
	 * @return number of tokens that can be bought from seller
	 */
	function _getTokenCountToBuyFromSeller(uint _tokenCountToBuy) internal view returns(uint) {
		// check that token count is not 0
		require(_tokenCountToBuy > 0);
		// get latest lottery
		Lottery storage lottery = lotteries[lotteryCount - 1];
		// check that total token count on sale is more that user has
		require(lottery.tokenCountToSell >= lottery.ownerTokenCountToSell[msg.sender]);
		// substitute user&#39;s token on sale count from total count
		uint tokenCountToSell = lottery.tokenCountToSell - lottery.ownerTokenCountToSell[msg.sender];
		// if there are no tokens to sell then return 0
		if(tokenCountToSell == 0) return 0;
		// if there are less tokens to sell than we need
		if(tokenCountToSell < _tokenCountToBuy) {
			return tokenCountToSell;
		} else {
			// contract has all tokens to buy from sellers
			return _tokenCountToBuy;
		}
	}

	/**
	 * @dev Returns part of number by percent. Ex: (200, 1) => 2
	 * @param _initialValue initial number
	 * @param _percent percentage
	 * @return part of number by percent
	 */
	function _getValuePartByPercent(uint _initialValue, uint _percent) internal pure returns(uint) {
		uint onePercentValue = _initialValue / 100;
		return onePercentValue * _percent;
	}

	/**
	 * @dev Returns winner address
	 * @return winner address
	 */
	function _getWinner() internal view returns(address) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		// if there are no participants then return 0x00 address
		if(lottery.participants.length == 0) return address(0);
		// set the 1st participant as winner
		address winner = lottery.participants[0];
		uint maxTokenCount = 0;
		// loop through all participants to find winner
		for(uint i = 0; i < lottery.participants.length; i++) {
			uint currentTokenCount = lottery.ownerTokenCount[lottery.participants[i]];
			if(currentTokenCount > maxTokenCount) {
				winner = lottery.participants[i];
				maxTokenCount = currentTokenCount; 
			}
		}
		return winner;
	}

	/**
	 * @dev Checks whether new lottery should be created
	 * @return true if new lottery needs to be created false otherwise
	 */
	function _isNeededNewLottery() internal view returns(bool) {
		// if there are no lotteries then return true
		if(lotteries.length == 0) return true;
		// if now is more than lottery end time then return true else false
		Lottery memory lottery = lotteries[lotteries.length - 1];
		return now > lottery.createdAt + defaultParams.gameDuration;
	}

}