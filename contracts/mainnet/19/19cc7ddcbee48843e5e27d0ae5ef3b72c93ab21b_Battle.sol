pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


 /**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
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

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



contract BattleBase is Ownable {
	 using SafeMath for uint256;
	 
	/***********************************************************************************/
	/* EVENTS
	/***********************************************************************************/
	
	/**
	* History sequence will be represented by uint256, in other words the max round is 256 (rounds more than this will decide on hp left or draw)
	*  1 is challenger attack
	*  2 is defender attack
	*  3 is challenger attack with critical
	*  4 is defender attack with critical
	*/
	event BattleHistory(
		uint256 historyId,
		uint8 winner, // 0 - challenger; 1 - defender; 2 - draw;
		uint64 battleTime,
		uint256 sequence,
		uint256 blockNumber,
		uint256 tokensGained);
	
	event BattleHistoryChallenger(
		uint256 historyId,
		uint256 cardId,
		uint8 element,
		uint16 level,
		uint32 attack,
		uint32 defense,
		uint32 hp,
		uint32 speed,
		uint32 criticalRate,
		uint256 rank);
		
	event BattleHistoryDefender(
		uint256 historyId,
		uint256 cardId,
		uint8 element,
		uint16 level,
		uint32 attack,
		uint32 defense,
		uint32 hp,
		uint32 speed,
		uint16 criticalRate,
		uint256 rank);
	
	event RejectChallenge(
		uint256 challengerId,
		uint256 defenderId,
		uint256 defenderRank,
		uint8 rejectCode,
		uint256 blockNumber);
		
	event HashUpdated(
		uint256 cardId, 
		uint256 cardHash);
		
	event LevelUp(uint256 cardId);
	
	event CardCreated(address owner, uint256 cardId);
	
	
	/***********************************************************************************/
	/* CONST DATA
	/***********************************************************************************/		
	uint32[] expToNextLevelArr = [0,103,103,207,207,207,414,414,414,414,724,724,724,828,828,931,931,1035,1035,1138,1138,1242,1242,1345,1345,1449,1449,1552,1552,1656,1656,1759,1759,1863,1863,1966,1966,2070,2070,2173,2173,2173,2277,2277,2380,2380,2484,2484,2587,2587,2691,2691,2794,2794,2898,2898,3001,3001,3105,3105,3208,3208,3312,3312,3415,3415,3519,3519,3622,3622,3622,3726,3726,3829,3829,3933,3933,4036,4036,4140,4140,4243,4243,4347,4347,4450,4450,4554,4554,4657,4657,4761,4761,4864,4864,4968,4968,5071,5071,5175];
	
	uint32[] activeWinExp = [10,11,14,19,26,35,46,59,74,91,100,103,108,116,125,135,146,158,171,185,200,215,231,248,265,283,302,321,341,361,382];
	
	
	/***********************************************************************************/
	/* DATA VARIABLES
	/***********************************************************************************/		
	//Card structure that holds all information for battle
	struct Card {
		uint8 element; // 1 - fire; 2 - water; 3 - wood;    8 - light; 9 - dark;
		uint16 level; //"unlimited" level bound to uint16 Max level is 65535
		uint32 attack;
		uint32 defense;
		uint32 hp;
		uint32 speed;
		uint16 criticalRate; //max 8000
		uint32 flexiGems;
		uint256 cardHash;
		uint32 currentExp;
		uint32 expToNextLevel;
		uint64 createdDatetime;

		uint256 rank; //rank is n-1 (need to add 1 for display);

		//uint8 passiveSkill; //TBC
	}
	
	// Mapping from tokenId to Card Struct
	mapping (uint256 => Card) public cards;
	
	uint256[] ranking; //stores the token id according to array position starts from 0 (rank 1)
	
	// Mapping from rank to amount held in that rank (challenge tokens)
	mapping (uint256 => uint256) public rankTokens;
	
	uint8 public currentElement = 0; //start with 0 as +1 will become fire
	
	uint256 public historyId = 0;
	
	/***********************************************************************************/
	/* CONFIGURATIONS
	/***********************************************************************************/
	/// @dev The address of the HogSmashToken
	HogSmashToken public hogsmashToken;
	
	/// @dev The address of the Marketplace
	Marketplace public marketplace;
			
	// Challenge fee changes on ranking difference
	uint256 public challengeFee;

	// Upgrade fee
	uint256 public upgradeFee;
	
	// Avatar fee
	uint256 public avatarFee;
	
	// Referrer fee in % (x10000)
	uint256 public referrerFee;
	
	// Developer Cut in % (x10000)
	uint256 public developerCut;
	
	uint256 internal totalDeveloperCut;

	// Price for each card draw (in wei)
	uint256 public cardDrawPrice;

	// Gems provided for upgrade every level up
	uint8 public upgradeGems; //
	// Gems provided for upgrade every 10 level up
	uint8 public upgradeGemsSpecial;
	// 1 Gem to attack conversion
	uint16 public gemAttackConversion;
	// 1 Gem to defense conversion
	uint16 public gemDefenseConversion;
	// 1 Gem to hp conversion
	uint16 public gemHpConversion;
	// 1 Gem to speed conversion
	uint16 public gemSpeedConversion;
	// 1 Gem to critical rate conversion divided by 100, eg 25 = 0.25
	uint16 public gemCriticalRateConversion;
	
	//% to get a gold card, 0 to 100
	uint8 public goldPercentage;
	
	//% to get a silver card, 0 to 100
	uint8 public silverPercentage;
 	
	//Range of event card number 1-99999999
	uint32 public eventCardRangeMin;
	
	//Range of event card number 1-99999999
	uint32 public eventCardRangeMax;
	
	// Maximum rounds of battle, cannot exceed 128
	uint8 public maxBattleRounds; //
		
	// Record how much tokens are held as rank tokens
	uint256 internal totalRankTokens;
	
	// Flag for start fighting
	bool internal battleStart;
	
	//Flag for starter pack sale
	bool internal starterPackOnSale;
	
	uint256 public starterPackPrice; //price of starter pack
	
	uint16 public starterPackCardLevel; //card level from starter pack
	
	
	/***********************************************************************************/
	/* ADMIN FUNCTIONS FOR SETTING CONFIGS
	/***********************************************************************************/		
	/// @dev Sets the reference to the marketplace.
	/// @param _address - Address of marketplace.
	function setMarketplaceAddress(address _address) external onlyOwner {
		Marketplace candidateContract = Marketplace(_address);

		require(candidateContract.isMarketplace(),"needs to be marketplace");

		// Set the new contract address
		marketplace = candidateContract;
	}
		
	/**
	* @dev set upgrade gems for each level up and each 10 level up
	* @param _upgradeGems upgrade gems for normal levels
	* @param _upgradeGemsSpecial upgrade gems for every n levels
	* @param _gemAttackConversion gem to attack conversion
	* @param _gemDefenseConversion gem to defense conversion
	* @param _gemHpConversion gem to hp conversion
	* @param _gemSpeedConversion gem to speed conversion
	* @param _gemCriticalRateConversion gem to critical rate conversion
	* @param _goldPercentage percentage to get gold card
	* @param _silverPercentage percentage to get silver card
	* @param _eventCardRangeMin event card hash range start (inclusive)
	* @param _eventCardRangeMax event card hash range end (inclusive)	
	* @param _newMaxBattleRounds maximum battle rounds
	*/
	function setSettingValues(  uint8 _upgradeGems,
	uint8 _upgradeGemsSpecial,
	uint16 _gemAttackConversion,
	uint16 _gemDefenseConversion,
	uint16 _gemHpConversion,
	uint16 _gemSpeedConversion,
	uint16 _gemCriticalRateConversion,
	uint8 _goldPercentage,
	uint8 _silverPercentage,
	uint32 _eventCardRangeMin,
	uint32 _eventCardRangeMax,
	uint8 _newMaxBattleRounds) external onlyOwner {
		require(_eventCardRangeMax >= _eventCardRangeMin, "range max must be larger or equals range min" );
		require(_eventCardRangeMax<100000000, "range max cannot exceed 99999999");
		require((_newMaxBattleRounds <= 128) && (_newMaxBattleRounds >0), "battle rounds must be between 0 and 128");
		upgradeGems = _upgradeGems;
		upgradeGemsSpecial = _upgradeGemsSpecial;
		gemAttackConversion = _gemAttackConversion;
		gemDefenseConversion = _gemDefenseConversion;
		gemHpConversion = _gemHpConversion;
		gemSpeedConversion = _gemSpeedConversion;
		gemCriticalRateConversion = _gemCriticalRateConversion;
		goldPercentage = _goldPercentage;
		silverPercentage = _silverPercentage;
		eventCardRangeMin = _eventCardRangeMin;
		eventCardRangeMax = _eventCardRangeMax;
		maxBattleRounds = _newMaxBattleRounds;
	}
	
	
	// @dev function to allow contract owner to change the price (in wei) per card draw
	function setStarterPack(uint256 _newStarterPackPrice, uint16 _newStarterPackCardLevel) external onlyOwner {
		require(_newStarterPackCardLevel<=20, "starter pack level cannot exceed 20"); //starter pack level cannot exceed 20
		starterPackPrice = _newStarterPackPrice;
		starterPackCardLevel = _newStarterPackCardLevel;		
	} 	
	
	// @dev function to allow contract owner to enable/disable starter pack sale
	function setStarterPackOnSale(bool _newStarterPackOnSale) external onlyOwner {
		starterPackOnSale = _newStarterPackOnSale;
	}
	
	// @dev function to allow contract owner to start/stop the battle
	function setBattleStart(bool _newBattleStart) external onlyOwner {
		battleStart = _newBattleStart;
	}
	
	// @dev function to allow contract owner to change the price (in wei) per card draw
	function setCardDrawPrice(uint256 _newCardDrawPrice) external onlyOwner {
		cardDrawPrice = _newCardDrawPrice;
	}
	
	// @dev function to allow contract owner to change the referrer fee (in %, eg 3.75% is 375)
	function setReferrerFee(uint256 _newReferrerFee) external onlyOwner {
		referrerFee = _newReferrerFee;
	}

	// @dev function to allow contract owner to change the challenge fee (in wei)
	function setChallengeFee(uint256 _newChallengeFee) external onlyOwner {
		challengeFee = _newChallengeFee;
	}

	// @dev function to allow contract owner to change the upgrade fee (in wei)
	function setUpgradeFee(uint256 _newUpgradeFee) external onlyOwner {
		upgradeFee = _newUpgradeFee;
	}
	
	// @dev function to allow contract owner to change the avatar fee (in wei)
	function setAvatarFee(uint256 _newAvatarFee) external onlyOwner {
		avatarFee = _newAvatarFee;
	}
	
	// @dev function to allow contract owner to change the developer cut (%) divide by 100
	function setDeveloperCut(uint256 _newDeveloperCut) external onlyOwner {
		developerCut = _newDeveloperCut;
	}
		
	function getTotalDeveloperCut() external view onlyOwner returns (uint256) {
		return totalDeveloperCut;
	}
		
	function getTotalRankTokens() external view returns (uint256) {
		return totalRankTokens;
	}
	
	
	/***********************************************************************************/
	/* GET SETTINGS FUNCTION
	/***********************************************************************************/	
	/**
	* @dev get upgrade gems and conversion ratios of each field
	* @return _upgradeGems upgrade gems for normal levels
	* @return _upgradeGemsSpecial upgrade gems for every n levels
	* @return _gemAttackConversion gem to attack conversion
	* @return _gemDefenseConversion gem to defense conversion
	* @return _gemHpConversion gem to hp conversion
	* @return _gemSpeedConversion gem to speed conversion
	* @return _gemCriticalRateConversion gem to critical rate conversion
	*/
	function getSettingValues() external view returns(  uint8 _upgradeGems,
															uint8 _upgradeGemsSpecial,
															uint16 _gemAttackConversion,
															uint16 _gemDefenseConversion,
															uint16 _gemHpConversion,
															uint16 _gemSpeedConversion,
															uint16 _gemCriticalRateConversion,
															uint8 _maxBattleRounds)
	{
		_upgradeGems = uint8(upgradeGems);
		_upgradeGemsSpecial = uint8(upgradeGemsSpecial);
		_gemAttackConversion = uint16(gemAttackConversion);
		_gemDefenseConversion = uint16(gemDefenseConversion);
		_gemHpConversion = uint16(gemHpConversion);
		_gemSpeedConversion = uint16(gemSpeedConversion);
		_gemCriticalRateConversion = uint16(gemCriticalRateConversion);
		_maxBattleRounds = uint8(maxBattleRounds);
	}
		

}

/***********************************************************************************/
/* RANDOM GENERATOR
/***********************************************************************************/
contract Random {
	uint private pSeed = block.number;

	function getRandom() internal returns(uint256) {
		return (pSeed = uint(keccak256(abi.encodePacked(pSeed,
		blockhash(block.number - 1),
		blockhash(block.number - 3),
		blockhash(block.number - 5),
		blockhash(block.number - 7))
		)));
	}
}

/***********************************************************************************/
/* CORE BATTLE CONTRACT
/***********************************************************************************/
/**
* Omits fallback to prevent accidentally sending ether to this contract
*/
contract Battle is BattleBase, Random, Pausable {

	/***********************************************************************************/
	/* CONSTRUCTOR
	/***********************************************************************************/
	// @dev Contructor for Battle Contract
	constructor(address _tokenAddress) public {
		HogSmashToken candidateContract = HogSmashToken(_tokenAddress);
		// Set the new contract address
		hogsmashToken = candidateContract;
		
		starterPackPrice = 30000000000000000;
		starterPackCardLevel = 5;
		starterPackOnSale = true; // start by selling starter pack
		
		challengeFee = 10000000000000000;
		
		upgradeFee = 10000000000000000;
		
		avatarFee = 50000000000000000;
		
		developerCut = 375;
		
		referrerFee = 2000;
		
		cardDrawPrice = 15000000000000000;
 		
		battleStart = true;
 		
		paused = false; //default contract paused
				
		totalDeveloperCut = 0; //init to 0
	}
	
	/***********************************************************************************/
	/* MODIFIER
	/***********************************************************************************/
	/**
	* @dev Guarantees msg.sender is owner of the given token
	* @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
	*/
	modifier onlyOwnerOf(uint256 _tokenId) {
		require(hogsmashToken.ownerOf(_tokenId) == msg.sender, "must be owner of token");
		_;
	}
		
	
	/***********************************************************************************/
	/* GAME FUNCTIONS
	/***********************************************************************************/
	/**
	* @dev External function for getting info of card
	* @param _id card id of target query card
	* @return information of the card
	*/
	function getCard(uint256 _id) external view returns (
	uint256 cardId,
	address owner,
	uint8 element,
	uint16 level,
	uint32[] stats,
	uint32 currentExp,
	uint32 expToNextLevel,
	uint256 cardHash,
	uint64 createdDatetime,
	uint256 rank
	) {
		cardId = _id;
		
		owner = hogsmashToken.ownerOf(_id);
		
		Card storage card = cards[_id];
		
		uint32[] memory tempStats = new uint32[](6);

		element = uint8(card.element);
		level = uint16(card.level);
		tempStats[0] = uint32(card.attack);
		tempStats[1] = uint32(card.defense);
		tempStats[2] = uint32(card.hp);
		tempStats[3] = uint32(card.speed);
		tempStats[4] = uint16(card.criticalRate);
		tempStats[5] = uint32(card.flexiGems);
		stats = tempStats;
		currentExp = uint32(card.currentExp);
		expToNextLevel = uint32(card.expToNextLevel);
		cardHash = uint256(card.cardHash);
		createdDatetime = uint64(card.createdDatetime);
		rank = uint256(card.rank);
	}
	
	
	/**
	* @dev External function for querying card Id at rank (zero based)
	* @param _rank zero based rank of the card
	* @return id of the card at the rank
	*/
	function getCardIdByRank(uint256 _rank) external view returns(uint256 cardId) {
		return ranking[_rank];
	}
	

	/**
	* @dev External function for drafting new card
	* @return uint of cardId
	*/
	function draftNewCard() external payable whenNotPaused returns (uint256) {
		require(msg.value == cardDrawPrice, "fee must be equal to draw price"); //make sure the fee is enough for drafting a new card`
				
		require(address(marketplace) != address(0), "marketplace not set"); //need to set up marketplace before drafting new cards is allowed
				
		hogsmashToken.setApprovalForAllByContract(msg.sender, marketplace, true); //let marketplace have approval for escrow if the card goes on sale
		
		totalDeveloperCut = totalDeveloperCut.add(cardDrawPrice);
		
		return _createCard(msg.sender, 1); //level 1 cards
	}
	
	/**
	* @dev External function for drafting new card
	* @return uint of cardId
	*/
	function draftNewCardWithReferrer(address referrer) external payable whenNotPaused returns (uint256 cardId) {
		require(msg.value == cardDrawPrice, "fee must be equal to draw price"); //make sure the fee is enough for drafting a new card`
				
		require(address(marketplace) != address(0), "marketplace not set"); //need to set up marketplace before drafting new cards is allowed
				
		hogsmashToken.setApprovalForAllByContract(msg.sender, marketplace, true); //let marketplace have approval for escrow if the card goes on sale
		
		cardId = _createCard(msg.sender, 1); //level 1 cards
		
		if ((referrer != address(0)) && (referrerFee!=0) && (referrer!=msg.sender) && (hogsmashToken.balanceOf(referrer)>0)) {
			uint256 referrerCut = msg.value.mul(referrerFee)/10000;
			require(referrerCut<=msg.value, "referre cut cannot be larger than fee");
			referrer.transfer(referrerCut);
			totalDeveloperCut = totalDeveloperCut.add(cardDrawPrice.sub(referrerCut));
		} else {
			totalDeveloperCut = totalDeveloperCut.add(cardDrawPrice);
		}		
	}
	

	/**
	* @dev External function for leveling up
	* @param _id card id of target query card
	* @param _attackLevelUp gems allocated to each attribute for upgrade
	* @param _defenseLevelUp gems allocated to each attribute for upgrade
	* @param _hpLevelUp gems allocated to each attribute for upgrade
	* @param _speedLevelUp gems allocated to each attribute for upgrade
	* @param _criticalRateLevelUp gems allocated to each attribute for upgrade
	* @param _flexiGemsLevelUp are gems allocated to each attribute for upgrade
	*/
	function levelUp( 	uint256 _id,
						uint16 _attackLevelUp,
						uint16 _defenseLevelUp,
						uint16 _hpLevelUp,
						uint16 _speedLevelUp,
						uint16 _criticalRateLevelUp,
						uint16 _flexiGemsLevelUp) external payable whenNotPaused onlyOwnerOf(_id) {
		require(
		_attackLevelUp >= 0        &&
		_defenseLevelUp >= 0       &&
		_hpLevelUp >= 0            &&
		_speedLevelUp >= 0         &&
		_criticalRateLevelUp >= 0  &&
		_flexiGemsLevelUp >= 0, "level up attributes must be more than 0"
		); //make sure all upgrade attributes will not be negative

		require(msg.value == upgradeFee, "fee must be equals to upgrade price"); //make sure the fee is enough for upgrade

		Card storage card = cards[_id];		
		require(card.currentExp==card.expToNextLevel, "exp is not max yet for level up"); //reject if currentexp not maxed out
		
		require(card.level < 65535, "card level maximum has reached"); //make sure level is not maxed out, although not likely
		
		require((card.criticalRate + (_criticalRateLevelUp * gemCriticalRateConversion))<=7000, "critical rate max of 70 has reached"); //make sure criticalrate is not upgraded when it reaches 70 to prevent waste

		uint totalInputGems = _attackLevelUp + _defenseLevelUp + _hpLevelUp;
		totalInputGems += _speedLevelUp + _criticalRateLevelUp + _flexiGemsLevelUp;
		
		uint16 numOfSpecials = 0;
				
		//Cater for initial high level cards but have not leveled up before
		if ((card.level > 1) && (card.attack==1) && (card.defense==1) && (card.hp==3) && (card.speed==1) && (card.criticalRate==25) && (card.flexiGems==1)) {
			numOfSpecials = (card.level+1)/5; //auto floor to indicate how many Ns for upgradeGemsSpecial; cardlevel +1 is the new level
			uint totalGems = (numOfSpecials * upgradeGemsSpecial) + (((card.level) - numOfSpecials) * upgradeGems);
			require(totalInputGems==totalGems, "upgrade gems not used up"); //must use up all gems when upgrade
		} else {
			if (((card.level+1)%5)==0) { //special gem every 5 levels
				require(totalInputGems==upgradeGemsSpecial, "upgrade gems not used up"); //must use up all gems when upgrade	
				numOfSpecials = 1;
			} else {
				require(totalInputGems==upgradeGems, "upgrade gems not used up"); //must use up all gems when upgrade
			}
		}
		
		totalDeveloperCut = totalDeveloperCut.add(upgradeFee);
		
		//start level up process
		_upgradeLevel(_id, _attackLevelUp, _defenseLevelUp, _hpLevelUp, _speedLevelUp, _criticalRateLevelUp, _flexiGemsLevelUp, numOfSpecials);
								
		emit LevelUp(_id);
	}

	function _upgradeLevel( uint256 _id,
							uint16 _attackLevelUp,
							uint16 _defenseLevelUp,
							uint16 _hpLevelUp,
							uint16 _speedLevelUp,
							uint16 _criticalRateLevelUp,
							uint16 _flexiGemsLevelUp,
							uint16 numOfSpecials) private {
		Card storage card = cards[_id];
		uint16[] memory extraStats = new uint16[](5); //attack, defense, hp, speed, flexigem
		if (numOfSpecials>0) { //special gem every 5 levels
			if (card.cardHash%100 >= 70) { //6* or 7* cards
				uint cardType = (uint(card.cardHash/10000000000))%100; //0-99
				if (cardType < 20) {
					extraStats[0]+=numOfSpecials;
				} else if (cardType < 40) {
					extraStats[1]+=numOfSpecials;
				} else if (cardType < 60) {
					extraStats[2]+=numOfSpecials;
				} else if (cardType < 80) {
					extraStats[3]+=numOfSpecials;
				} else {
					extraStats[4]+=numOfSpecials;
				}
				
				if (card.cardHash%100 >=90) { //7* cards			
					uint cardTypeInner = cardType%10; //0-9
					if (cardTypeInner < 2) {
						extraStats[0]+=numOfSpecials;
					} else if (cardTypeInner < 4) {
						extraStats[1]+=numOfSpecials;
					} else if (cardTypeInner < 6) {
						extraStats[2]+=numOfSpecials;
					} else if (cardTypeInner < 8) {
						extraStats[3]+=numOfSpecials;
					} else {
						extraStats[4]+=numOfSpecials;
					}
				}
			}
		}
		card.attack += (_attackLevelUp + extraStats[0]) * gemAttackConversion;
		card.defense += (_defenseLevelUp + extraStats[1]) * gemDefenseConversion;
		card.hp += (_hpLevelUp + extraStats[2]) * gemHpConversion;
		card.speed += (_speedLevelUp + extraStats[3]) * gemSpeedConversion;		
		card.criticalRate += uint16(_criticalRateLevelUp * gemCriticalRateConversion);
		card.flexiGems += _flexiGemsLevelUp + extraStats[4]; // turn Gem into FlexiGem
		card.level += 1; //level + 1

		card.currentExp = 0; //reset exp
		//card.expToNextLevel = card.level*100 + max(0,card.level-8) * (1045/1000)**card.level;
		uint256 tempExpLevel = card.level;
		if (tempExpLevel > expToNextLevelArr.length) {
			tempExpLevel = expToNextLevelArr.length; //cap it at max level exp
		}
		card.expToNextLevel = expToNextLevelArr[tempExpLevel];
	}

	function max(uint a, uint b) private pure returns (uint) {
		return a > b ? a : b;
	}

	function challenge( uint256 _challengerCardId,
						uint32[5] _statUp, //0-attack, 1-defense, 2-hp, 3-speed, 4-criticalrate
						uint256 _defenderCardId,						
						uint256 _defenderRank,
						uint16 _defenderLevel) external payable whenNotPaused onlyOwnerOf(_challengerCardId) {
		require(battleStart != false, "battle has not started"); //make sure the battle has started
		require(msg.sender != hogsmashToken.ownerOf(_defenderCardId), "cannot challenge own cards"); //make sure user doesn&#39;t attack his own cards
		Card storage challenger = cards[_challengerCardId];		
		require((_statUp[0] + _statUp[1] + _statUp[2] + _statUp[3] + _statUp[4])==challenger.flexiGems, "flexi gems not used up"); //flexi points must be exactly used, not more not less
		
		Card storage defender = cards[_defenderCardId];
		
		if (defender.rank != _defenderRank) {
			emit RejectChallenge(_challengerCardId, _defenderCardId, _defenderRank, 1, uint256(block.number));
			(msg.sender).transfer(msg.value);		
			return;
		}
		
		if (defender.level != _defenderLevel) {
			emit RejectChallenge(_challengerCardId, _defenderCardId, _defenderRank, 2, uint256(block.number));
			(msg.sender).transfer(msg.value);
			return;
		}
		
		uint256 requiredChallengeFee = challengeFee;
		if (defender.rank <150) { //0-149 rank within 150
			requiredChallengeFee = requiredChallengeFee.mul(2);
		}
		require(msg.value == requiredChallengeFee, "fee must be equals to challenge price"); //challenge fee to challenge defender
		
		uint256 developerFee = 0;
		if (msg.value > 0) {
			developerFee = _calculateFee(msg.value);
		}
		
		uint256[] memory stats = new uint256[](14); //challengerattack, challengerdefense, challengerhp, challengerspeed, challengercritical, defendercritical, defenderhp, finalWinner

		stats[0] = challenger.attack + (_statUp[0] * gemAttackConversion);
		stats[1] = challenger.defense + (_statUp[1] * gemDefenseConversion);
		stats[2] = challenger.hp + (_statUp[2] * gemHpConversion);
		stats[3] = challenger.speed + (_statUp[3] * gemSpeedConversion);
		stats[4] = challenger.criticalRate + (_statUp[4] * gemCriticalRateConversion);
		stats[5] = defender.criticalRate;
		stats[6] = defender.hp;
		stats[8] = challenger.hp + (_statUp[2] * gemHpConversion); //challenger hp for record purpose
		stats[9] = challenger.rank; //for looting
		stats[10] = defender.rank; //for looting
		stats[11] = 0; //tokensGained
		stats[12] = _challengerCardId;
		stats[13] = _defenderCardId;

		//check challenger critical rate
		if (stats[4]>7000) {
			stats[4] = 7000; //hard cap at 70 critical rate
		}

		//check defender critical rate
		if (stats[5]>7000) {
			stats[5] = 7000; //hard cap at 70 critical rate
		}

		// 1 - fire; 2 - water; 3 - wood;    8 - light; 9 - dark;
		if (((challenger.element-1) == defender.element) || ((challenger.element==1) && (defender.element==3)) || ((challenger.element==8) && (defender.element==9))) {
			stats[4] += 3000; //30% critical rate increase for challenger
			if (stats[4]>8000) {
				stats[4] = 8000; //hard cap at 80 critical rate for element advantage
			}
		}

		if (((defender.element-1) == challenger.element) || ((defender.element==1) && (challenger.element==3)) || ((defender.element==8) && (challenger.element==9))) {
			stats[5] += 3000; //30% critical rate increase for defender
			if (stats[5]>8000) {
				stats[5] = 8000; //hard cap at 80 critical rate for element advantage
			}
		}
		
		uint256 battleSequence = _simulateBattle(challenger, defender, stats);
		
		stats[11] = _transferFees(_challengerCardId, stats, developerFee);	
		
		
		emit BattleHistory(
			historyId,
			uint8(stats[7]),
			uint64(now),
			uint256(battleSequence),
			uint256(block.number),
			uint256(stats[11])
		);
		
		emit BattleHistoryChallenger(
			historyId,
			uint256(_challengerCardId),
			uint8(challenger.element),
			uint16(challenger.level),
			uint32(stats[0]),
			uint32(stats[1]),
			uint32(stats[8]),
			uint32(stats[3]),
			uint16(stats[4]), //pretty sure trimming down the uint won&#39;t affect the number as max is just 80000
			uint256(stats[9])
		);
			
		emit BattleHistoryDefender(	
			historyId,
			uint256(_defenderCardId),
			uint8(defender.element),
			uint16(defender.level),
			uint32(defender.attack),
			uint32(defender.defense),
			uint32(defender.hp),
			uint32(defender.speed),
			uint16(stats[5]),
			uint256(stats[10])
		);
		
		historyId = historyId.add(1); //add one for next history
	}
	
	function _addBattleSequence(uint8 attackType, uint8 rounds, uint256 battleSequence) private pure returns (uint256) {
		// Assumed rounds 0-based; attackType is 0xB (B:0,1,2,3), i.e. the last 2 bits is the value with other bits zeros
		uint256 mask = 0x3;
		mask = ~(mask << 2*rounds);
		uint256 newSeq = battleSequence & mask;

		newSeq = newSeq | (uint256(attackType) << 2*rounds);

		return newSeq;
	}


	function _simulateBattle(Card storage challenger, Card storage defender, uint[] memory stats) private returns (uint256 battleSequence) {
	
		bool continueBattle = true;
		uint8 currentAttacker = 0; //0 challenger, 1 defender
		uint256 tempAttackStrength;
		uint8 battleRound = 0;
		if (!_isChallengerAttackFirst(stats[3], defender.speed)){
			currentAttacker = 1;
		}
		while (continueBattle) {
			if (currentAttacker==0) { //challenger attack
				if (_rollCriticalDice() <= stats[4]){
					tempAttackStrength = stats[0] * 2; //critical hit
					battleSequence = _addBattleSequence(2, battleRound, battleSequence); //move sequence to left and add record
				} else {
					tempAttackStrength = stats[0]; //normal hit
					battleSequence = _addBattleSequence(0, battleRound, battleSequence); //move sequence to left and add record
				}
				if (tempAttackStrength <= defender.defense) {
					tempAttackStrength = 1; //at least deduct 1 hp
				} else {
					tempAttackStrength -= defender.defense;
				}
				if (stats[6] <= tempAttackStrength) {
					stats[6] = 0; //do not let it overflow
				} else {
					stats[6] -= tempAttackStrength; //defender hp
				}
				currentAttacker = 1; //defender turn up next
			} else if (currentAttacker==1) { //defender attack
				if (_rollCriticalDice() <= stats[5]){
					tempAttackStrength = defender.attack * 2; //critical hit
					battleSequence = _addBattleSequence(3, battleRound, battleSequence); //move sequence to left and add record
				} else {
					tempAttackStrength = defender.attack; //normal hit
					battleSequence = _addBattleSequence(1, battleRound, battleSequence); //move sequence to left and add record
				}
				if (tempAttackStrength <= stats[1]) {
					tempAttackStrength = 1; //at least deduct 1 hp
				} else {
					tempAttackStrength -= stats[1];
				}
				if (stats[2] <= tempAttackStrength) {
					stats[2] = 0; //do not let it overflow
				} else {
					stats[2] -= tempAttackStrength; //challenger hp
				}
				currentAttacker = 0; //challenger turn up next
			}
			battleRound ++;

			if ((battleRound>=maxBattleRounds) || (stats[6]<=0) || (stats[2]<=0)){
				continueBattle = false; //end battle
			}
		}

		uint32 challengerGainExp = 0;
		uint32 defenderGainExp = 0;

		//calculate Exp
		if (challenger.level == defender.level) { //challenging a same level card
			challengerGainExp = activeWinExp[10];
		} else if (challenger.level > defender.level) { //challenging a lower level card
			if ((challenger.level - defender.level) >= 11) {
				challengerGainExp = 1; //defender too weak, grant only 1 exp
			} else {
				//challengerGainExp = (((1 + ((defender.level - challenger.level)/10))**2) + (1/10)) * baseExp;
				challengerGainExp = activeWinExp[10 + defender.level - challenger.level]; //0 - 9
			}
		} else if (challenger.level < defender.level) { //challenging a higher level card
			//challengerGainExp = ((1 + ((defender.level - challenger.level)/10)**(3/2))) * baseExp;
			uint256 levelDiff = defender.level - challenger.level;
			if (levelDiff > 20) {
				levelDiff = 20; //limit level difference to 20 as max exp gain
			}
			challengerGainExp = activeWinExp[10+levelDiff];
		}
		
		if (stats[2] == stats[6]) { //challenger hp = defender hp
			stats[7] = 2; //draw
			//No EXP when draw
		} else if (stats[2] > stats[6]) { //challenger hp > defender hp
			stats[7] = 0; //challenger wins
			if (defender.rank < challenger.rank) { //swap ranks
				ranking[defender.rank] = stats[12]; //update ranking table position
				ranking[challenger.rank] = stats[13]; //update ranking table position
				uint256 tempRank = defender.rank;
				defender.rank = challenger.rank; //update rank on card
				challenger.rank = tempRank; //update rank on card
			}

			//award Exp
			//active win
			challenger.currentExp += challengerGainExp;
			if (challenger.currentExp > challenger.expToNextLevel) {
				challenger.currentExp = challenger.expToNextLevel; //cap it at max exp for level up
			}

			//passive lose
			//defenderGainExp = challengerGainExp*35/100*30/100 + (5/10);
			defenderGainExp = ((challengerGainExp*105/100) + 5)/10; // 30% of 35% + round up
			if (defenderGainExp <= 0) {
				defenderGainExp = 1; //at least 1 Exp
			}
			defender.currentExp += defenderGainExp;
			if (defender.currentExp > defender.expToNextLevel) {
				defender.currentExp = defender.expToNextLevel; //cap it at max exp for level up
			}

		} else if (stats[6] > stats[2]) { //defender hp > challenger hp
			stats[7] = 1; //defender wins
			//award Exp
			//active lose
			uint32 tempChallengerGain = challengerGainExp*35/100; //35% of winning
			if (tempChallengerGain <= 0) {
				tempChallengerGain = 1; //at least 1 Exp
			}
			challenger.currentExp += tempChallengerGain; //35% of winning
			if (challenger.currentExp > challenger.expToNextLevel) {
				challenger.currentExp = challenger.expToNextLevel; //cap it at max exp for level up
			}

			//passive win
			defenderGainExp = challengerGainExp*30/100;
			if (defenderGainExp <= 0) {
				defenderGainExp = 1; //at least 1 Exp
			}
			defender.currentExp += defenderGainExp;
			if (defender.currentExp > defender.expToNextLevel) {
				defender.currentExp = defender.expToNextLevel; //cap it at max exp for level up
			}
		}
		
		return battleSequence;
	}
	
	
	
	function _transferFees(uint256 _challengerCardId, uint[] stats, uint256 developerFee) private returns (uint256 totalGained) {
		totalDeveloperCut = totalDeveloperCut.add(developerFee);		
		uint256 remainFee = msg.value.sub(developerFee); //minus developer fee
		totalGained = 0;
		if (stats[7] == 1) { //challenger loses			
			// put all of challenger fee in rankTokens (minus developerfee of course)			
			rankTokens[stats[10]] = rankTokens[stats[10]].add(remainFee);
			totalRankTokens = totalRankTokens.add(remainFee);
		} else { //draw or challenger wins
			address challengerAddress = hogsmashToken.ownerOf(_challengerCardId); //get address of card owner
			if (stats[7] == 0) { //challenger wins				
				if (stats[9] > stats[10]) { //challenging a higher ranking defender					
					//1. get tokens from defender rank if defender rank is higher
					if (rankTokens[stats[10]] > 0) {
						totalGained = totalGained.add(rankTokens[stats[10]]);
						totalRankTokens = totalRankTokens.sub(rankTokens[stats[10]]);
						rankTokens[stats[10]] = 0;						
					}
					//2. get self rank tokens if moved to higher rank
					if (rankTokens[stats[9]] > 0) {
						totalGained = totalGained.add(rankTokens[stats[9]]);
						totalRankTokens = totalRankTokens.sub(rankTokens[stats[9]]);
						rankTokens[stats[9]] = 0;
					}					
				} else { //challenging a lower ranking defender					
					if (stats[9]<50) { //rank 1-50 gets to get self rank tokens and lower rank (within 150) tokens if win
						if ((stats[10] < 150) && (rankTokens[stats[10]] > 0)) { // can get defender rank tokens if defender rank within top 150 (0-149)
							totalGained = totalGained.add(rankTokens[stats[10]]);
							totalRankTokens = totalRankTokens.sub(rankTokens[stats[10]]);
							rankTokens[stats[10]] = 0;
						}
						
						if ((stats[10] < 150) && (rankTokens[stats[9]] > 0)) { //can get self rank tokens if defender rank within top 150
							totalGained = totalGained.add(rankTokens[stats[9]]);
							totalRankTokens = totalRankTokens.sub(rankTokens[stats[9]]);
							rankTokens[stats[9]] = 0;
						}
					}
				}
				challengerAddress.transfer(totalGained.add(remainFee)); //give back challenge fee untouched + total gained				
			} else { //draw
				challengerAddress.transfer(remainFee); //give back challenge fee untouched
			} 
		}			
	}
	

	function _rollCriticalDice() private returns (uint16 result){
		return uint16((getRandom() % 10000) + 1); //get 1 to 10000
	}

	function _isChallengerAttackFirst(uint _challengerSpeed, uint _defenderSpeed ) private returns (bool){
		uint8 randResult = uint8((getRandom() % 100) + 1); //get 1 to 100
		uint challengerChance = (((_challengerSpeed * 10 ** 3) / (_challengerSpeed + _defenderSpeed))+5) / 10;//round
		if (randResult <= challengerChance) {
			return true;
		} else {
			return false;
		}
	}

	
	/// @dev function to buy starter package, with card and tokens directly from contract
	function buyStarterPack() external payable whenNotPaused returns (uint256){
		require(starterPackOnSale==true, "starter pack is not on sale");
		require(msg.value==starterPackPrice, "fee must be equals to starter pack price");
		require(address(marketplace) != address(0), "marketplace not set"); //need to set up marketplace before drafting new cards is allowed
		
		totalDeveloperCut = totalDeveloperCut.add(starterPackPrice);
				
		hogsmashToken.setApprovalForAllByContract(msg.sender, marketplace, true); //let marketplace have approval for escrow if the card goes on sale
		
		return _createCard(msg.sender, starterPackCardLevel); //level n cards
	}
		
	/**
	* @dev Create card function
	* @param _to The address that will own the minted card
	* @param _initLevel The level to start with, usually 1
	* @return uint256 ID of the new card
	*/
	function _createCard(address _to, uint16 _initLevel) private returns (uint256) {
		require(_to != address(0), "cannot create card for unknown address"); //check if address is not 0 (the origin address)

		currentElement+= 1;
		if (currentElement==4) {
			currentElement = 8;
		}
		if (currentElement == 10) {
			currentElement = 1;
		}
		uint256 tempExpLevel = _initLevel;
		if (tempExpLevel > expToNextLevelArr.length) {
			tempExpLevel = expToNextLevelArr.length; //cap it at max level exp
		}
		
		uint32 tempCurrentExp = 0;
		if (_initLevel>1) { //let exp max out so that user can level up the card according to preference
			tempCurrentExp = expToNextLevelArr[tempExpLevel];
		}
		
		uint256 tokenId = hogsmashToken.mint(_to);
		
		// use memory as this is a temporary variable, cheaper and will not be stored since cards store all of them
		Card memory _card = Card({
			element: currentElement, // 1 - fire; 2 - water; 3 - wood;    8 - light; 9 - dark;
			level: _initLevel, // level
			attack: 1, // attack,
			defense: 1, // defense,
			hp: 3, // hp,
			speed: 1, // speed,
			criticalRate: 25, // criticalRate
			flexiGems: 1, // flexiGems,
			currentExp: tempCurrentExp, // currentExp,
			expToNextLevel: expToNextLevelArr[tempExpLevel], // expToNextLevel,
			cardHash: generateHash(),
			createdDatetime :uint64(now),
			rank: tokenId // rank
		});
		
		cards[tokenId] = _card;
		ranking.push(tokenId); //push to ranking mapping
		
		emit CardCreated(msg.sender, tokenId);

		return tokenId;
	}
	
	function generateHash() private returns (uint256 hash){
		hash = uint256((getRandom()%1000000000000)/10000000000);		
		hash = hash.mul(10000000000);
		
		uint256 tempHash = ((getRandom()%(eventCardRangeMax-eventCardRangeMin+1))+eventCardRangeMin)*100;
		hash = hash.add(tempHash);
		
		tempHash = getRandom()%100;
		
		if (tempHash < goldPercentage) {
			hash = hash.add(90);
		} else if (tempHash < (goldPercentage+silverPercentage)) {
			hash = hash.add(70);
		} else {
			hash = hash.add(50);
		}
	}
	
	/// @dev function to update avatar hash 
	function updateAvatar(uint256 _cardId, uint256 avatarHash) external payable whenNotPaused onlyOwnerOf(_cardId) {
		require(msg.value==avatarFee, "fee must be equals to avatar price");
				
		Card storage card = cards[_cardId];
		
		uint256 tempHash = card.cardHash%1000000000000; //retain hash fixed section
		
		card.cardHash = tempHash.add(avatarHash.mul(1000000000000));
		
		emit HashUpdated(_cardId, card.cardHash);		
	}
		
	
	/// @dev Compute developer&#39;s fee
	/// @param _challengeFee - transaction fee
	function _calculateFee(uint256 _challengeFee) internal view returns (uint256) {
		return developerCut.mul(_challengeFee/10000);
	}
	
	
	/***********************************************************************************/
	/* ADMIN FUNCTIONS
	/***********************************************************************************/	
	/**
	* @dev External function for drafting new card for Owner, for promotional purposes
	* @param _cardLevel initial level of card created, must be less or equals to 20
	* @return uint of cardId
	*/
	function generateInitialCard(uint16 _cardLevel) external whenNotPaused onlyOwner returns (uint256) {
		require(address(marketplace) != address(0), "marketplace not set"); //need to set up marketplace before drafting new cards is allowed
		require(_cardLevel<=20, "maximum level cannot exceed 20"); //set maximum level at 20 that Owner can generate
		
		hogsmashToken.setApprovalForAllByContract(msg.sender, marketplace, true); //let marketplace have approval for escrow if the card goes on sale

		return _createCard(msg.sender, _cardLevel); //level 1 cards
	}
	
	/// @dev Function for contract owner to put tokens into ranks for events
	function distributeTokensToRank(uint[] ranks, uint256 tokensPerRank) external payable onlyOwner {
		require(msg.value == (tokensPerRank*ranks.length), "tokens must be enough to distribute among ranks");
		uint i;
		for (i=0; i<ranks.length; i++) {
			rankTokens[ranks[i]] = rankTokens[ranks[i]].add(tokensPerRank);
			totalRankTokens = totalRankTokens.add(tokensPerRank);
		}
	}
	
	
	// @dev Allows contract owner to withdraw the all developer cut from the contract
	function withdrawBalance() external onlyOwner {
		address thisAddress = this;
		uint256 balance = thisAddress.balance;
		uint256 withdrawalSum = totalDeveloperCut;

		if (balance >= withdrawalSum) {
			totalDeveloperCut = 0;
			owner.transfer(withdrawalSum);
		}
	}
}

/***********************************************************************************/
/* INTERFACES
/***********************************************************************************/
interface Marketplace {
	function isMarketplace() external returns (bool);
}

interface HogSmashToken {
	function ownerOf(uint256 _tokenId) external view returns (address);
	function balanceOf(address _owner) external view returns (uint256);
	function tokensOf(address _owner) external view returns (uint256[]);
	function mint(address _to) external returns (uint256 _tokenId);
	function setTokenURI(uint256 _tokenId, string _uri) external;
	function setApprovalForAllByContract(address _sender, address _to, bool _approved) external;
}