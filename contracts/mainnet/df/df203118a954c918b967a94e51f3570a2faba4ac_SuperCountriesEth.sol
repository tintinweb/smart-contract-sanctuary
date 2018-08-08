pragma solidity ^0.4.24;


/*
                                                                                                             

███████╗██╗   ██╗██████╗ ███████╗██████╗                                    
██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗                                   
███████╗██║   ██║██████╔╝█████╗  ██████╔╝                                   
╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗                                   
███████║╚██████╔╝██║     ███████╗██║  ██║                                   
╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝                                   
                                                                            
     ██████╗ ██████╗ ██╗   ██╗███╗   ██╗████████╗██████╗ ██╗███████╗███████╗
    ██╔════╝██╔═══██╗██║   ██║████╗  ██║╚══██╔══╝██╔══██╗██║██╔════╝██╔════╝
    ██║     ██║   ██║██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║█████╗  ███████╗
    ██║     ██║   ██║██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║██╔══╝  ╚════██║
    ╚██████╗╚██████╔╝╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║███████╗███████║
     ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝
                                                                           

&#169; 2018 SuperCountries

所有权 - 4CE434B6058EC7C24889EC2512734B5DBA26E39891C09DF50C3CE3191CE9C51E

Xuxuxu - LB - Xufo
																										   
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
  * @dev subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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






contract SuperCountriesEth {
  using SafeMath for uint256;

 
////////////////////////////
/// 	CONSTRUCTOR		 ///	
////////////////////////////
   
	constructor () public {
    owner = msg.sender;
	}
	
	address public owner;  

  
  /**
   * @dev Throws if called by any account other than the owner.
   */
	modifier onlyOwner() {
		require(owner == msg.sender);
		_;
	}


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
 


////////////////////////
/// 	EVENTS		 ///	
////////////////////////
  
  event Bought (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _itemId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  
  event SetReferrerEvent(address indexed referral, address indexed referrer);
  event PayReferrerEvent(address indexed oldOwner, address indexed referrer1, address indexed referrer2, uint256 referralPart);
  
  event BonusConstant(uint256 bonusToDispatch_, uint256 bonusDispatched_, uint256 notYetDispatched_, uint256 indexed _itemSoldId_, uint256 kBonus, uint256 indexed countryScore);
  event BonusDispatch(uint256 bonusToGet_, uint256 indexed playerScoreForThisCountry_, address indexed player_, uint256 pendingBalanceTotal_, uint256 indexed _itemSoldId);
  event DivsDispatch(uint256 dividendsCut_, uint256 dividendsScore, uint256 indexed _itemId, uint256 price, uint256 worldScore_);
  event newRichest(address indexed richest_, uint256 richestScore_, uint256 indexed blocktimestamp_, uint256 indexed blocknumber_);
  
  event Withdrawal(address indexed playerAddress, uint256 indexed ethereumWithdrawn, uint256 indexed potVersion_);
  event ConfirmWithdraw(address indexed playerAddress, uint256 refbonus_, uint256 divs_, uint256 totalPending_, uint256 playerSc_, uint256 _handicap_);
  event ConfirmPotWithdraw(uint256 contractBalance, address indexed richest_, uint256 richestBalance_, address indexed lastBuyer_, uint256 lastBalance_, uint256 indexed potVersion);
  event PotWithdrawConstant(uint256 indexed blocktimestamp_, uint256 indexed timestamplimit_, uint256 dividendsScore_, uint256 indexed potVersion, uint256 lastWithdrawPotVersion_);
  event WithdrawOwner(uint256 indexed potVersion, uint256 indexed lastWithdrawPotVersion_, uint256 indexed balance_);

 
 


///////////////////////////////////////////
/// 	VARIABLES, MAPPINGS, STRUCTS 	///	
///////////////////////////////////////////
  
  bool private erc721Enabled = false;

  /// Price increase limits
  uint256 private increaseLimit1 = 0.04 ether;
  uint256 private increaseLimit2 = 0.6 ether;
  uint256 private increaseLimit3 = 2.5 ether;
  uint256 private increaseLimit4 = 7.0 ether;

  /// All countries
  uint256[] private listedItems;
  mapping (uint256 => address) private ownerOfItem;
  mapping (uint256 => uint256) private priceOfItem;
  mapping (uint256 => uint256) private previousPriceOfItem;
  mapping (uint256 => address) private approvedOfItem;
   
  
  /// Referrals and their referrers
  mapping(address => address) public referrerOf;
  
  /// Dividends and score
  uint256 private worldScore ; /// Worldscore = cumulated price of all owned countries + all spent ethers in this game
  mapping (address => uint256) private playerScore; /// For each player, the sum of each owned country + the sum of all spent ethers since the beginning of the game
  uint256 private dividendsScore ; /// Balance of dividends divided by the worldScore 
  mapping(uint256 => mapping(address => uint256)) private pendingBalance; /// Divs from referrals, bonus and dividends calculated after the playerScore change ; if the playerScore didn&#39;t change recently, there are some pending divs that can be calculated using dividendsScore and playerScore. The first mapping (uint256) is the jackpot version to use, the value goes up after each pot distribution and the previous pendingBalance are reseted.
  mapping(uint256 => mapping(address => uint256)) private handicap; /// a player cannot claim a % of all dividends but a % of the cumulated dividends after his join date, this is a handicap
  mapping(uint256 => mapping(address => uint256)) private balanceToWithdraw; /// A player cannot withdraw pending divs, he must request a withdraw first (pending divs move to balanceToWithdraw) then withdraw.	

  uint256 private potVersion = 1; /// Number of jackpots
  uint256 private lastWithdrawPotVersion = 1; /// Latest withdraw in the game (pot version)
  address private richestBuyer ; /// current player with the highest PlayerScore
  address private lastBuyer ; /// current latest buyer in the game
  uint256 private timestampLimit = 1528108990; /// after this timestamp, the richestBuyer and the lastBuyer will be allowed to withdraw 1/2 of the contract balance (1/4 each)
  
  struct CountryStruct {
		address[] itemToAddressArray; /// addresses that owned the same country	 
		uint256 priceHistory; /// cumulated price of the country
		uint256 startingPrice; /// starting price of the country
		}

  mapping (uint256 => CountryStruct) public countryStructs;
  
  mapping (uint256 => mapping(address => uint256)) private itemHistory; /// Store price history (cumulated) for each address for each country
  
  uint256 private HUGE = 1e13;
 
 
 


////////////////////////////////
/// 	USEFUL MODIFIER		 ///	
////////////////////////////////

	modifier onlyRealAddress() {
		require(msg.sender != address(0));
		_;
	}


	

	
////////////////////////////////
/// 	ERC721 PRIVILEGES	 ///	
////////////////////////////////

	modifier onlyERC721() {
		require(erc721Enabled);
		_;
	} 


  /**
   * @dev Unlocks ERC721 behaviour, allowing for trading on third party platforms.
   */	 
	function enableERC721 () onlyOwner() public {
		erc721Enabled = true;
	} 

  
 

 
///////////////////////////////////
///		LISTING NEW COUNTRIES 	///
///////////////////////////////////
	
	function listMultipleItems (uint256[] _itemIds, uint256 _price, address _owner) onlyOwner() external {
		for (uint256 i = 0; i < _itemIds.length; i++) {
			listItem(_itemIds[i], _price, _owner);
		}
	}

	
	function listItem (uint256 _itemId, uint256 _price, address _owner) onlyOwner() public {
		require(_price > 0);
		require(priceOfItem[_itemId] == 0);
		require(ownerOfItem[_itemId] == address(0));

		ownerOfItem[_itemId] = _owner;
		priceOfItem[_itemId] = _price;
		previousPriceOfItem[_itemId] = 0;
		listedItems.push(_itemId);
		newEntity(_itemId, _price);
	}

	
  /**
   * @dev Creates new Struct for a country each time a new country is listed.
   */	
	function newEntity(uint256 countryId, uint256 startPrice) private returns(bool success) {
		countryStructs[countryId].startingPrice = startPrice;
		return true;
	}

	
  /**
   * @dev Update the Struc each time a country is sold.
   * Push the newOwner, update the price history
   */	
	function updateEntity(uint256 countryId, address newOwner, uint256 priceUpdate) internal {
		countryStructs[countryId].priceHistory += priceUpdate;
		if (itemHistory[countryId][newOwner] == 0 ){
			countryStructs[countryId].itemToAddressArray.push(newOwner);
		}
	  }
 



 
///////////////////////
/// CALCULATE PRICE ///
///////////////////////

	function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
		if (_price < increaseLimit1) {
			return _price.mul(200).div(95);
		} else if (_price < increaseLimit2) {
			return _price.mul(160).div(96);
		} else if (_price < increaseLimit3) {
			return _price.mul(148).div(97);
		} else if (_price < increaseLimit4) {
			return _price.mul(136).div(97);
		} else {
			return _price.mul(124).div(98);
		}
	}

	function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
		if (_price < increaseLimit1) {
			return _price.mul(5).div(100); // 5%
		} else if (_price < increaseLimit2) {
			return _price.mul(4).div(100); // 4%
		} else if (_price < increaseLimit4) {
			return _price.mul(3).div(100); // 3%
		} else {
			return _price.mul(2).div(100); // 2%
		}
	}
 



 
//////////////////////////////
/// BALANCES & WITHDRAWALS ///
//////////////////////////////

	function getBalance(address _playerAddress)
		public
		view
		returns(uint256 pendingRefBonus_, uint256 pendingFromScore_, uint256 totalPending_, uint256 balanceReadyToWithdraw_, uint256 playerScore_, uint256 handicap_, uint256 dividendsScore_)
		{
			uint256 refbonus = pendingBalance[potVersion][_playerAddress];
			uint256 playerSc = playerScore[_playerAddress];
			uint256 playerHandicap = handicap[potVersion][_playerAddress];
			uint256 divs = playerSc.mul(dividendsScore.sub(playerHandicap)).div(HUGE);
			uint256 totalPending = refbonus.add(divs);
			uint256 ready = balanceToWithdraw[potVersion][_playerAddress];
			return (refbonus, divs, totalPending, ready, playerSc, playerHandicap, dividendsScore);				
		}


		
	function getOldBalance(uint256 _potVersion, address _playerAddress)
		public
		view
		returns(uint256 oldPendingRefBonus_, uint256 oldHandicap_, uint256 oldReadyToWithdraw_)
		{
			uint256 oldRefBonus = pendingBalance[_potVersion][_playerAddress];
			uint256 oldPlayerHandicap = handicap[_potVersion][_playerAddress];
			uint256 oldReady = balanceToWithdraw[_potVersion][_playerAddress];
			return (oldRefBonus, oldPlayerHandicap, oldReady);				
		}
		
		
		
  /**
   * @dev First step to withdraw : players must confirm their pending Divs before withdrawing
   * this function sums the pending balances (pendingDividends and the pending divs from playerScore)
   * Then this sum moves to balanceReadyToWithdraw, the player can call the next function and withdraw divs
   */
	function confirmDividends() public onlyRealAddress {
		require(playerScore[msg.sender] > 0);/// the player exists
		require (dividendsScore >= handicap[potVersion][msg.sender]);
		require (dividendsScore >= 0);
		
		address _playerAddress = msg.sender;
		uint256 playerSc = playerScore[_playerAddress];
		uint256 handicap_ = handicap[potVersion][_playerAddress];
		
		uint256 refbonus = pendingBalance[potVersion][_playerAddress];
		uint256 divs = playerSc.mul(dividendsScore.sub(handicap_)).div(HUGE);
		uint256 totalPending = refbonus.add(divs);	
						
		/// Reset the values
		pendingBalance[potVersion][_playerAddress] = 0; /// Reset the pending balance
		handicap[potVersion][_playerAddress] = dividendsScore;
		
		/// Now the player is ready to withdraw ///
		balanceToWithdraw[potVersion][_playerAddress] += totalPending;
		
		// fire event
		emit ConfirmWithdraw(_playerAddress, refbonus, divs, totalPending, playerSc, handicap_);
		
	}


  /**
   * @dev Second step to withdraw : after confirming divs, players can withdraw divs to their wallet
   */	
	function withdraw() public onlyRealAddress {
		require(balanceOf(msg.sender) > 0);
		require(balanceToWithdraw[potVersion][msg.sender] > 0);
				
		address _playerAddress = msg.sender;
		
			if (lastWithdrawPotVersion != potVersion){
					lastWithdrawPotVersion = potVersion;
			}

        
        /// Add referrals earnings, bonus and divs
		uint256 divToTransfer = balanceToWithdraw[potVersion][_playerAddress];
		balanceToWithdraw[potVersion][_playerAddress] = 0;
		
        _playerAddress.transfer(divToTransfer);
		
        /// fire event
        emit Withdrawal(_playerAddress, divToTransfer, potVersion);
    }
	

	
  /**
   * @dev After 7 days without any buy, the richest user and the latest player will share the contract balance !
   */		
	function confirmDividendsFromPot() public {
		require(richestBuyer != address(0) && lastBuyer != address(0)) ;
		require(address(this).balance > 100000000);	/// mini 1e8 wei
		require(block.timestamp > timestampLimit);
		
		uint256 confirmation_TimeStamp = timestampLimit;
		potVersion ++;
		uint256 balance = address(this).balance;
		uint256 balanceQuarter = balance.div(4);
		dividendsScore = 0; /// reset dividends
		updateTimestampLimit(); /// Reset the timer, if no new buys, the richest and the last buyers will be able to withdraw the left quarter in a week or so
		balanceToWithdraw[potVersion][richestBuyer] = balanceQuarter;
		balanceToWithdraw[potVersion][lastBuyer] += balanceQuarter; /// if the richest = last, dividends cumulate
		
		
		// fire events
        emit ConfirmPotWithdraw(	
			 balance, 
			 richestBuyer, 
			 balanceToWithdraw[potVersion][richestBuyer],
			 lastBuyer,
			 balanceToWithdraw[potVersion][lastBuyer],
			 potVersion
		);
		
		emit PotWithdrawConstant(	
			 block.timestamp,
			 confirmation_TimeStamp,
			 dividendsScore,
			 potVersion,
			 lastWithdrawPotVersion
		);
		
	}


	
  /**
   * @dev If no new buys occur (dividendsScore = 0) and the richest and latest players don&#39;t withdraw their dividends after 3 jackpots, the game can be stuck forever
   * Prevent from jackpot vicious circle : same dividends are shared between latest and richest users again and again
   * If the richest and/or the latest player withdraw(s) at least once between 3 jackpots, it means the game is alive
   * Or if contract balance drops down to 1e8 wei (that means many successful jackpots and that a current withdrawal could cost too much gas for players)
   */	
	function withdrawAll() public onlyOwner {
		require((potVersion > lastWithdrawPotVersion.add(3) && dividendsScore == 0) || (address(this).balance < 100000001) );
		require (address(this).balance >0);
		
		potVersion ++;
		updateTimestampLimit();
		uint256 balance = address(this).balance;
		
		owner.transfer(balance);
		
        // fire event
        emit WithdrawOwner(potVersion, lastWithdrawPotVersion, balance);
    } 	

	
	
	
	
///////////////////////////////////////
/// REFERRERS - Setting and payment ///   
///////////////////////////////////////	

  /**
   * @dev Get the referrer of a player.
   * @param player The address of the player to get the referrer of.
   */
    function getReferrerOf(address player) public view returns (address) {
        return referrerOf[player];
    }

	
  /**
   * @dev Set a referrer.
   * @param newReferral The address to set the referrer for.
   * @param referrer The address of the referrer to set.
   * The referrer must own at least one country to keep his reflink active
   * Referrals got with an active link are forever, even if all the referrer&#39;s countries are sold
   */
    function setReferrer(address newReferral, address referrer) internal {
		if (getReferrerOf(newReferral) == address(0x0) && newReferral != referrer && balanceOf(referrer) > 0 && playerScore[newReferral] == 0) {
			
			/// Set the referrer, if no referrer has been set yet, and the player
			/// and referrer are not the same address.
				referrerOf[newReferral] = referrer;
        
			/// Emit event.
				emit SetReferrerEvent(newReferral, referrer);
		}
    }
	
	
	

  /**
   * @dev Dispatch the referrer bonus when a country is sold
   * @param referralDivToPay which dividends percentage will be dispatched to refererrs : 0 if no referrer, 2.5% if 1 referrer, 5% if 2
   */
	function payReferrer (address _oldOwner, uint256 _netProfit) internal returns (uint256 referralDivToPay) {
		address referrer_1 = referrerOf[_oldOwner];
		
		if (referrer_1 != 0x0) {
			referralDivToPay = _netProfit.mul(25).div(1000);
			pendingBalance[potVersion][referrer_1] += referralDivToPay;  /// 2.5% for the first referrer
			address referrer_2 = referrerOf[referrer_1];
				
				if (referrer_2 != 0x0) {
						pendingBalance[potVersion][referrer_2] += referralDivToPay;  /// 2.5% for the 2nd referrer
						referralDivToPay += referralDivToPay;
				}
		}
			
		emit PayReferrerEvent(_oldOwner, referrer_1, referrer_2, referralDivToPay);
		
		return referralDivToPay;
		
	}
	
	
	

	
///////////////////////////////////
/// INTERNAL FUNCTIONS WHEN BUY ///   
///////////////////////////////////	

  /**
   * @dev Dispatch dividends to former owners of a country
   */
	function bonusPreviousOwner(uint256 _itemSoldId, uint256 _paidPrice, uint256 _bonusToDispatch) private {
		require(_bonusToDispatch < (_paidPrice.mul(5).div(100)));
		require(countryStructs[_itemSoldId].priceHistory > 0);

		CountryStruct storage c = countryStructs[_itemSoldId];
		uint256 countryScore = c.priceHistory;
		uint256 kBonus = _bonusToDispatch.mul(HUGE).div(countryScore);
		uint256 bonusDispatched = 0;
		  
		for (uint256 i = 0; i < c.itemToAddressArray.length && bonusDispatched < _bonusToDispatch ; i++) {
			address listedBonusPlayer = c.itemToAddressArray[i];
			uint256 playerBonusScore = itemHistory[_itemSoldId][listedBonusPlayer];
			uint256 bonusToGet = playerBonusScore.mul(kBonus).div(HUGE);
				
				if (bonusDispatched.add(bonusToGet) <= _bonusToDispatch) {
					pendingBalance[potVersion][listedBonusPlayer] += bonusToGet;
					bonusDispatched += bonusToGet;
					
					emitInfo(bonusToGet, playerBonusScore, listedBonusPlayer, pendingBalance[potVersion][listedBonusPlayer], _itemSoldId);
				}
		}  
			
		emit BonusConstant(_bonusToDispatch, bonusDispatched, _bonusToDispatch.sub(bonusDispatched), _itemSoldId, kBonus, countryScore);
	}


	
	function emitInfo(uint256 dividendsToG_, uint256 playerSc_, address player_, uint256 divsBalance_, uint256 itemId_) private {
		emit BonusDispatch(dividendsToG_, playerSc_, player_, divsBalance_, itemId_);
  
	}

  

  /**
   * @dev we need to update the oldOwner and newOwner balances each time a country is sold, their handicap and playerscore will also change
   * Worldscore and dividendscore : we don&#39;t care, it will be updated later.
   * If accurate, set a new richest player
   */
	function updateScoreAndBalance(uint256 _paidPrice, uint256 _itemId, address _oldOwner, address _newOwner) internal {	
		uint256 _previousPaidPrice = previousPriceOfItem[_itemId];
		assert (_paidPrice > _previousPaidPrice);

		
		/// OLD OWNER ///
			uint256 scoreSubHandicap = dividendsScore.sub(handicap[potVersion][_oldOwner]);
			uint256 playerScore_ = playerScore[_oldOwner];
		
			/// If the old owner is the owner of this contract, we skip this part, the owner of the contract won&#39;t get dividends
				if (_oldOwner != owner && scoreSubHandicap >= 0 && playerScore_ > _previousPaidPrice) {
					pendingBalance[potVersion][_oldOwner] += playerScore_.mul(scoreSubHandicap).div(HUGE);
					playerScore[_oldOwner] -= _previousPaidPrice; ///for the oldOwner, the playerScore goes down the previous price
					handicap[potVersion][_oldOwner] = dividendsScore; /// and setting his handicap to dividendsScore after updating his balance
				}

				
		/// NEW OWNER ///
			scoreSubHandicap = dividendsScore.sub(handicap[potVersion][_newOwner]); /// Rewrite the var with the newOwner values
			playerScore_ = playerScore[_newOwner]; /// Rewrite the var playerScore with the newOwner PlayerScore
				
			/// If new player, his playerscore = 0, handicap = 0, so the pendingBalance math = 0
				if (scoreSubHandicap >= 0) {
					pendingBalance[potVersion][_newOwner] += playerScore_.mul(scoreSubHandicap).div(HUGE);
					playerScore[_newOwner] += _paidPrice.mul(2); ///for the newOwner, the playerScore goes up twice the value of the purchase price
					handicap[potVersion][_newOwner] = dividendsScore; /// and setting his handicap to dividendsScore after updating his balance
				}

				
		/// Change the richest user if this is the case...
				if (playerScore[_newOwner] > playerScore[richestBuyer]) {
					richestBuyer = _newOwner;
					
					emit newRichest(_newOwner, playerScore[_newOwner], block.timestamp, block.number);
				}		

				
		/// Change the last Buyer in any case
			lastBuyer = _newOwner;
		
	}
		

		

  /**
   * @dev Update the worldScore
   * After each buy, the worldscore increases : 2x current purchase price - 1x previousPrice
   */
	function updateWorldScore(uint256 _countryId, uint256 _price) internal	{
		worldScore += _price.mul(2).sub(previousPriceOfItem[_countryId]);
	}
		

		
  /**
   * @dev Update timestampLimit : the date on which the richest player and the last buyer will be able to share the contract balance (1/4 each)
   */ 
	function updateTimestampLimit() internal {
		timestampLimit = block.timestamp.add(604800).add(potVersion.mul(28800)); /// add 7 days + (pot version * X 8hrs)
	}


	
  /**
   * @dev Refund the buyer if excess
   */ 
	function excessRefund(address _newOwner, uint256 _price) internal {		
		uint256 excess = msg.value.sub(_price);
			if (excess > 0) {
				_newOwner.transfer(excess);
			}
	}	
	

	


///////////////////////////   
/// 	BUY A COUNTRY 	///
///////////////////////////
/*
     Buy a country directly from the contract for the calculated price
     which ensures that the owner gets a profit.  All countries that
     have been listed can be bought by this method. User funds are sent
     directly to the previous owner and are never stored in the contract.
*/
	
	function buy (uint256 _itemId, address referrerAddress) payable public onlyRealAddress {
		require(priceOf(_itemId) > 0);
		require(ownerOf(_itemId) != address(0));
		require(msg.value >= priceOf(_itemId));
		require(ownerOf(_itemId) != msg.sender);
		require(!isContract(msg.sender));
		require(msg.sender != owner);
		require(block.timestamp < timestampLimit || block.timestamp > timestampLimit.add(3600));
		
		
		address oldOwner = ownerOf(_itemId);
		address newOwner = msg.sender;
		uint256 price = priceOf(_itemId);

		
		
	
	////////////////////////
	/// Set the referrer ///
	////////////////////////
		
		setReferrer(newOwner, referrerAddress);
		
	

	
	///////////////////////////////////
	/// Update scores and timestamp ///
	///////////////////////////////////
		
		/// Dividends are dispatched among players accordingly to their "playerScore".
		/// The playerScore equals the sum of all their countries (owned now, paid price) + sum of all their previously owned countries 
		/// After each sell / buy, players that owned at least one country can claim dividends
		/// DIVS of a player = playerScore * DIVS to dispatch / worldScore
		/// If a player is a seller or a buyer, his playerScore will change, we need to adjust his parameters
		/// If a player is not a buyer / seller, his playerScore doesn&#39;t change, no need to adjust
			updateScoreAndBalance(price, _itemId, oldOwner, newOwner);
			
		/// worldScore change after each flip, we need to adjust
		/// To calculate the worldScore after a flip: add buy price x 2, subtract previous price
			updateWorldScore(_itemId, price);
		
		/// If 7 days with no buys, the richest player and the last buyer win the jackpot (1/2 of contract balance ; 1/4 each)
		/// Waiting time increases after each pot distribution
			updateTimestampLimit();
	


	
	///////////////////////
	/// Who earns what? ///
	///////////////////////	
	
		/// When a country flips, who earns how much?
		/// Devs : 2% to 5% of country price
		/// Seller&#39;s reward : current paidPrice - previousPrice - devsCut = net profit. The seller gets the previous Price + ca.65% of net Profit
		/// The referrers of the seller : % of netProfit from their referrals R+1 & R+2. If no referrers, all the referrers&#39; cut goes to dividends to all players.
		/// All players, with or without a country now : dividends (% of netProfit)
		/// All previous owners of the flipped country : a special part of dividends called Bonus. If no previous buyer, all the bonus is also added up to dividends to all players.
			
		/// Calculate the devs cut
			uint256 devCut_ = calculateDevCut(price);
			
		/// Calculate the netProfit
			uint256 netProfit = price.sub(devCut_).sub(previousPriceOfItem[_itemId]);
		
		/// Calculate dividends cut from netProfit and what referrers left
			uint256 dividendsCut_ = netProfit.mul(30).div(100);
			
		/// Calculate the seller&#39;s reward
		/// Price sub the cuts : dev cut and 35% including referrer cut (5% max), 30% (25% if referrers) dividends (including 80% divs / 20% bonus max) and 5% (jackpot)
			uint256 oldOwnerReward = price.sub(devCut_).sub(netProfit.mul(35).div(100));

		/// Calculate the referrers cut and store the referrer&#39;s cut in the referrer&#39;s pending balance ///
		/// Update dividend&#39;s cut : 30% max ; 27,5% if 1 referrer ; 25% if 2 referrers
			uint256 refCut = payReferrer(oldOwner, netProfit);
			dividendsCut_ -= refCut;
		
	

	
	////////////////////////////////////////////////////////////
	///          Dispatch dividends to all players           ///
	/// Dispatch bonuses to previous owners of this country  ///
	////////////////////////////////////////////////////////////
		
		/// Dividends = 80% to all country owners (previous and current owners, no matter the country) + 20% bonus to previous owners of this country
		/// If no previous owners, 100% to all countries owners
	
		/// Are there previous owners for the current flipped country?
			if (price > countryStructs[_itemId].startingPrice && dividendsCut_ > 1000000 && worldScore > 0) {
				
				/// Yes, there are previous owners, they will get 20% of dividends of this country
					bonusPreviousOwner(_itemId, price, dividendsCut_.mul(20).div(100));
				
				/// So dividends for all the country owners are 100% - 20% = 80%
					dividendsCut_ = dividendsCut_.mul(80).div(100); 
			} 
	
				/// If else... nothing special to do, there are no previous owners, dividends remain 100%	
		
		/// Dispatch dividends to all country owners, no matter the country
		/// Note : to avoid floating numbers, we divide a constant called HUGE (1e13) by worldScore, of course we will multiply by HUGE when retrieving
			if (worldScore > 0) { /// worldScore must be greater than 0, the opposite is impossible and dividends are not calculated
				
				dividendsScore += HUGE.mul(dividendsCut_).div(worldScore);
			}
	

	
	////////////////////////////////////////////////
	/// Update the price history of the newOwner ///
	////////////////////////////////////////////////
	
		/// The newOwner is now known as an OWNER for this country
		/// We&#39;ll store his cumulated buy price for this country in a mapping
		/// Bonus : each time a country is flipped, players that previously owned this country get bonuses proportionally to the sum of their buys	
			updateEntity(_itemId, newOwner, price);
			itemHistory[_itemId][newOwner] += price;

	

	
	////////////////////////
	/// Update the price ///
	////////////////////////
	
		/// The price of purchase becomes the "previousPrice", and the "price" is the next price 
			previousPriceOfItem[_itemId] = price;
			priceOfItem[_itemId] = nextPriceOf(_itemId);
	

	
	/////////////////////////////////////////
	/// Transfer the reward to the seller ///
	/////////////////////////////////////////

		/// The seller&#39;s reward is transfered automatically to his wallet
		/// The dev cut is transfered automatically out the contract
		/// The other rewards (bonus, dividends, referrer&#39;s cut) will be stored in a pending balance
			oldOwner.transfer(oldOwnerReward);
			owner.transfer(devCut_);
			
		/// Transfer the token from oldOwner to newOwner
			_transfer(oldOwner, newOwner, _itemId);  	
	
		/// Emit the events
			emit Bought(_itemId, newOwner, price);
			emit Sold(_itemId, oldOwner, price);	
		
	

	
	///////////////////////////////////////////
	/// Transfer the excess to the newOwner ///
	///////////////////////////////////////////
	
		/// If the newOwner sent a higher price than the asked price, the excess is refunded
			excessRefund(newOwner, price);
		

	
	/// Send informations
		emit DivsDispatch(dividendsCut_, dividendsScore, _itemId, price, worldScore);		
		
/// END OF THE BUY FUNCTION ///
  
	}
  
 
  
//////////////////////////////
/// Practical informations ///
//////////////////////////////

	function itemHistoryOfPlayer(uint256 _itemId, address _owner) public view returns (uint256 _valueAddressOne) {
		return itemHistory[_itemId][_owner];
	}
  
  
	function implementsERC721() public view returns (bool _implements) {
		return erc721Enabled;
	}

	
	function name() public pure returns (string _name) {
		return "SuperCountries";
	}

	
	function symbol() public pure returns (string _symbol) {
		return "SUP";
	}

	
	function totalSupply() public view returns (uint256 _totalSupply) {
		return listedItems.length;
	}

	
	function balanceOf (address _owner) public view returns (uint256 _balance) {
		uint256 counter = 0;

			for (uint256 i = 0; i < listedItems.length; i++) {
				if (ownerOf(listedItems[i]) == _owner) {
					counter++;
				}
			}

		return counter;
	}


	function ownerOf (uint256 _itemId) public view returns (address _owner) {
		return ownerOfItem[_itemId];
	}

	
	function tokensOf (address _owner) public view returns (uint256[] _tokenIds) {
		uint256[] memory items = new uint256[](balanceOf(_owner));
		uint256 itemCounter = 0;
			
			for (uint256 i = 0; i < listedItems.length; i++) {
				if (ownerOf(listedItems[i]) == _owner) {
					items[itemCounter] = listedItems[i];
					itemCounter += 1;
				}
			}

		return items;
	}


	function tokenExists (uint256 _itemId) public view returns (bool _exists) {
		return priceOf(_itemId) > 0;
	}

	
	function approvedFor(uint256 _itemId) public view returns (address _approved) {
		return approvedOfItem[_itemId];
	}


	function approve(address _to, uint256 _itemId) onlyERC721() public {
		require(msg.sender != _to);
		require(tokenExists(_itemId));
		require(ownerOf(_itemId) == msg.sender);

		if (_to == 0) {
			if (approvedOfItem[_itemId] != 0) {
				delete approvedOfItem[_itemId];
				emit Approval(msg.sender, 0, _itemId);
			}
		}
		else {
			approvedOfItem[_itemId] = _to;
			emit Approval(msg.sender, _to, _itemId);
		}
	  }

	  
  /* Transferring a country to another owner will entitle the new owner the profits from `buy` */
	function transfer(address _to, uint256 _itemId) onlyERC721() public {
		require(msg.sender == ownerOf(_itemId));
		_transfer(msg.sender, _to, _itemId);
	}

	
	function transferFrom(address _from, address _to, uint256 _itemId) onlyERC721() public {
		require(approvedFor(_itemId) == msg.sender);
		_transfer(_from, _to, _itemId);
	}

	
	function _transfer(address _from, address _to, uint256 _itemId) internal {
		require(tokenExists(_itemId));
		require(ownerOf(_itemId) == _from);
		require(_to != address(0));
		require(_to != address(this));

		ownerOfItem[_itemId] = _to;
		approvedOfItem[_itemId] = 0;

		emit Transfer(_from, _to, _itemId);
	}


	
///////////////////////////	
/// READ ONLY FUNCTIONS ///
///////////////////////////

	function gameInfo() public view returns (address richestPlayer_, address lastBuyer_, uint256 thisBalance_, uint256 lastWithdrawPotVersion_, uint256 worldScore_, uint256 potVersion_,  uint256 timestampLimit_) {
		
		return (richestBuyer, lastBuyer, address(this).balance, lastWithdrawPotVersion, worldScore, potVersion, timestampLimit);
	}
	
	
	function priceOf(uint256 _itemId) public view returns (uint256 _price) {
		return priceOfItem[_itemId];
	}
	
	
	function nextPriceOf(uint256 _itemId) public view returns (uint256 _nextPrice) {
		return calculateNextPrice(priceOf(_itemId));
	}

	
	function allOf(uint256 _itemId) external view returns (address _owner, uint256 _price, uint256 previous_, uint256 _nextPrice) {
		return (ownerOf(_itemId), priceOf(_itemId), previousPriceOfItem[_itemId], nextPriceOf(_itemId));
	}


///  is Contract ///
	function isContract(address addr) internal view returns (bool) {
		uint size;
		assembly { size := extcodesize(addr) } // solium-disable-line
		return size > 0;
	}




////////////////////////
/// USEFUL FUNCTIONS ///
////////////////////////

  /** 
   * @dev Fallback function to accept all ether sent directly to the contract
   * Nothing is lost, it will raise the jackpot !
   */

    function() payable public
    {    }


}