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
		mapping(address => uint[]) ownerToken;
		mapping(uint => address) tokenOwner;
		mapping(address => uint) ownerTokenCountToSell; 
		mapping(uint => bool) tokenSell;
		uint createdAt;
		uint tokenCount;
		uint tokenCountToSell;
		uint winnerSum;
		bool prizeRedeemed;
		address winner;
		address[] participants;
		uint[] tokensToSellOnce;
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
		updateParams(6 hours, 0.01 ether, 15 minutes, 10, 15, 20);
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
		require(lottery.ownerToken[msg.sender].length - lottery.ownerTokenCountToSell[msg.sender] >= _tokenCount);
		// place tokens for selling
		for(uint i = 0; i < _tokenCount; i++) {
			uint tokenId = lottery.ownerToken[msg.sender][i];
			// if token is not for selling then place for selling
			if(!lottery.tokenSell[tokenId]) {
				lottery.tokenSell[tokenId] = true;
				lottery.tokensToSellOnce.push(tokenId);
			}
		}
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
		return lottery.ownerToken[_user].length;
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
		lottery.winnerSum += msg.value;
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
		uint disapprovedCount = 0;
		for(uint i = 0; i < lottery.ownerToken[msg.sender].length; i++) {
			uint tokenId = lottery.ownerToken[msg.sender][i];
			// if token is for selling then remove for selling
			if(lottery.tokenSell[tokenId]) {
				lottery.tokenSell[tokenId] = false;
				disapprovedCount++;
			}
			// if we have already marked the needed amount of tokens as disapproved then break
			if(disapprovedCount == _tokenCount) break;
		}
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
	 * @dev Checks whether token is selling at the moment
	 * @param _tokenId token index
	 * @return whether token is on sale
	 */
	function isTokenSelling(uint _tokenId) public view returns(bool) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		return lottery.tokenSell[_tokenId];
	}

	/**
	 * @dev Returns owner address by token id
	 * @param _tokenId token index
	 * @return owner address
	 */
	function ownerOf(uint _tokenId) public view returns(address) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		return lottery.tokenOwner[_tokenId];
	}

	/**
	 * @dev Returns token ids by user address for current lottery
	 * @param _user user address
	 * @return array of user&#39;s token ids
	 */
	function tokensOf(address _user) public view returns(uint[]) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		return lottery.ownerToken[_user];
	}

	/**
	 * @dev Returns token ids that were once placed on sale. Notice that there might be duplicate token ids so you should
	 * check manually via isTokenSelling() whether token is really on sale.
	 * @return array of token ids that were placed on sale
	 */
	function tokensToSellOnce() public view returns(uint[]) {
		Lottery memory lottery = lotteries[lotteryCount - 1];
		return lottery.tokensToSellOnce;
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
		owner.transfer(commissionSum);
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
		uint purchaseSum = currentTokenPrice - currentCommissionSum;
		// foreach token on sale
		for(uint i = 0; i < lottery.tokensToSellOnce.length; i++) {
			uint tokenId = lottery.tokensToSellOnce[i];
			// if token is on sale
			if(lottery.tokenSell[tokenId]) {
				// save the old owner
				address oldOwner = lottery.tokenOwner[tokenId];
				// transfer token from old owner to new owner
				_transferFrom(oldOwner, msg.sender, tokenId);
				// update contract commission sum and send eth to previous owner
				commissionSum += currentCommissionSum;
				if(!oldOwner.send(purchaseSum)) {
					emit PurchaseError(oldOwner, purchaseSum);
				}
			}
		}
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
		for(uint tokenIndex = lottery.tokenCount; tokenIndex < lottery.tokenCount + _tokenCountToBuy; tokenIndex++) {
			lottery.ownerToken[msg.sender].push(tokenIndex);
			lottery.tokenOwner[tokenIndex] = msg.sender;
		}
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
		uint addPerStage = _getValuePartByPercent(price, lottery.params.tokenPriceIncreasePercent);
		for(uint i = 0; i < stageCount; i++) {
			price += addPerStage;
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
		Lottery memory lottery = lotteries[lotteryCount - 1];
		// if there are no tokens to sell then return 0
		if(lottery.tokenCountToSell == 0) return 0;
		// if there are less tokens to sell than we need
		if(lottery.tokenCountToSell < _tokenCountToBuy) {
			return lottery.tokenCountToSell;
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
		uint maxTokenCount = lottery.ownerToken[winner].length;
		// loop through all participants to find winner
		for(uint i = 0; i < lottery.participants.length; i++) {
			uint currentTokenCount = lottery.ownerToken[lottery.participants[i]].length;
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

	/**
	 * @dev Transfers token from old owner to new owner
	 * @param _oldOwner old owner address
	 * @param _newOwner new owner address
	 * @param _tokenId token index
	 */
	function _transferFrom(address _oldOwner, address _newOwner, uint _tokenId) internal {
		// get latest lottery
		Lottery storage lottery = lotteries[lotteryCount - 1];
		// remove token from ownerToken
		uint[] storage ownerTokens = lottery.ownerToken[_oldOwner];
		bool indexFound = false;
		for(uint j = 0; j < ownerTokens.length; j++) {
			if(ownerTokens[j] == _tokenId) {
				uint indexToRemove = j;
				indexFound = true;
				break;
			}
		}
		assert(indexFound);
		ownerTokens[indexToRemove] = ownerTokens[ownerTokens.length - 1];
		ownerTokens.length--;
		// substitute 1 from ownerTokenCountToSell
		lottery.ownerTokenCountToSell[lottery.tokenOwner[_tokenId]]--;
		// set new token owner
		lottery.tokenOwner[_tokenId] = _newOwner;
		// add token to new owner in ownerToken
		lottery.ownerToken[_newOwner].push(_tokenId);
		// set token sell to false
		lottery.tokenSell[_tokenId] = false;
		// substitute 1 from tokenCountToSell
		lottery.tokenCountToSell--;
	}

}