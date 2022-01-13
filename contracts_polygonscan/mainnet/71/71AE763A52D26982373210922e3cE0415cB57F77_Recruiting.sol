//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./IERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

import "./RaiderInfo.sol";
import "./Raiders.sol";
import "./RecruitingHistory.sol";
import "./RaiderRandomness.sol";

contract Recruiting is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    
    // Enums for consistency in the naming for Rarities and Races
    enum Rarity {
      Same, Common, Uncommon, Rare
    }

    enum Race {
      Mike, John, Tammy, Old, White, Blue, Orc, Skeleton, Cyborg, Dark, Fairy
    }

    // This lets us create counters for each Race
    mapping(Race => Counters.Counter) internal raceCount;
    // This lets us create counters for each Rarity
    mapping(Rarity => Counters.Counter) internal rarityCount;
    // We also need a mapping for max of each race

    mapping(Race => Counters.Counter) internal sameCount;

    mapping(Race => Rarity) internal raceRarity;

    uint public recruitingFrequency; // how often Raiders can recruit

    struct Thresholds {
      uint total;
      uint same;
      uint common;
      uint uncommon;
      uint rare;
    }

    mapping(Rarity => Thresholds) public rarityThresholds;
    mapping(Rarity => uint) public maxSameRarity;
    
    // Iterating through this array in order will give us an even distribution of Commons with a 0.8 ratio of Old Men 
    Race[] public commonChars = 
      [Race.Mike, Race.John, Race.Tammy, Race.Old, 
      Race.Mike, Race.John, Race.Tammy, Race.Old, 
      Race.Mike, Race.John, Race.Tammy, Race.Old, 
      Race.Mike, Race.John, Race.Tammy, Race.Old, 
      Race.Mike, Race.John, Race.Tammy];
    
    // For a 2:1 ratio of elves to orcs
    Race[] public uncommonChars = 
      [Race.White, Race.Blue, Race.Orc, 
      Race.White, Race.Blue]; 
    
    // This one is a little easier since they're 1:1:1
    Race[] public rareChars = [Race.Skeleton, Race.Cyborg, Race.Dark, Race.Fairy]; 

    address public immutable aurumAddress;
    address public immutable raidersAddress;
    address public treasuryAddress;
    address public immutable infoAddress;
    address public immutable historyAddress;
    address public randomnessAddress;

    uint public constant AURUM_DECIMALS = 10**18;
    uint public constant FIRST_DISCOUNT_GENERATION = 4;
    uint public discountStep;
    uint public gen10CostScale;

    uint public activeRecruitmentGeneration;

    mapping(uint => uint) public generationBasesInAurum;
    mapping(uint => uint) public generationMaxDiscount;

    constructor(
      address _aurum, 
      address _raiders, 
      address _treasury, 
      address _infoAddress,
      address _history,
      address _randomness,
      uint _frequency,
      uint _discountStep,
      uint _gen10CostScale
    ) {
      aurumAddress = _aurum;
      raidersAddress = _raiders;
      treasuryAddress = _treasury;
      infoAddress = _infoAddress;
      historyAddress = _history;
      recruitingFrequency = _frequency;
      randomnessAddress = _randomness;
      discountStep = _discountStep;
      gen10CostScale = _gen10CostScale;
      // Map the rarities 

      raceRarity[Race.Mike] = Rarity.Common;
      raceRarity[Race.John] = Rarity.Common;
      raceRarity[Race.Tammy] = Rarity.Common;
      raceRarity[Race.Old] = Rarity.Common;
      raceRarity[Race.White] = Rarity.Uncommon;
      raceRarity[Race.Blue] = Rarity.Uncommon;
      raceRarity[Race.Orc] = Rarity.Uncommon;
      raceRarity[Race.Skeleton] = Rarity.Rare;
      raceRarity[Race.Cyborg] = Rarity.Rare;
      raceRarity[Race.Dark] = Rarity.Rare;
      raceRarity[Race.Fairy] = Rarity.Rare;

      // Odds of getting each type based on the Rarity of the one doing the recruiting 
      // Order is Total, Same, Common, Uncommon, Rare

      rarityThresholds[Rarity.Common] = Thresholds(100, 50, 93, 98, 100); 
      rarityThresholds[Rarity.Uncommon] = Thresholds(100, 50, 65, 95, 100);
      rarityThresholds[Rarity.Rare] = Thresholds(100, 50, 55, 70, 100);
    }

    // ----------- EVENTS -----------

    event RaiderRecruited(uint tokenId, uint indexed race, uint indexed generation, address indexed owner);

    // ----------- BREVITY FUNCTIONS -----------

    function aurum() internal view returns(IERC20) {
      return IERC20(aurumAddress);
    }

    function raiders() internal view returns(IERC721) {
      return IERC721(raidersAddress);
    }

    function history() internal view returns(RecruitingHistory) {
      return RecruitingHistory(historyAddress);
    }

    // ----------- MODIFIERS -----------

    modifier humanOnly() {
      require(msg.sender == tx.origin, "Bad robot!");
      _;
    }

    // ----------- CORE FUNCTIONS -----------
    
    // On the Web3 side, you'll need to make sure they add allowance for this contract first for transferring Aurum.
    // Also make sure that the right indexes are being used for each Race! 

    function recruitRaider(uint raiderId) public whenNotPaused humanOnly nonReentrant returns (uint) {
      require(raiders().ownerOf(raiderId) == msg.sender, "You don't own this Raider!");
      require(canRaiderRecruit(raiderId), "It hasn't been long enough for your Raider to recruit again!");
      require(!RaiderInfo(infoAddress).invalidRaider(raiderId), "This is not a valid Raider!");
      require(RaiderInfo(infoAddress).raiderInfoAdded(raiderId), "We don't have info on this Raider!");
      require(activeRecruitmentGeneration != 0,"Invalid recruitment period");
      require(nextRaiderRecruitGeneration(raiderId) <= activeRecruitmentGeneration, "You can't recruit that generation yet!");
      
      uint[3] memory raiderInfo = RaiderInfo(infoAddress).checkRaider(raiderId);

      Race newRaiderRace;
      uint raceNum = raiderInfo[1]; // used for running the odds on what Race they get
      uint generation = raiderInfo[2]; // used for calculating how much the recruitment costs

      uint gen10Recruitments = history().gen10Recruitments(raiderId);
      uint newRaiderGeneration = nextRaiderRecruitGeneration(raiderId); // This way we can keep recruiting going though successive generations
      uint recruitingCost = calcRecruitment(newRaiderGeneration, generation, gen10Recruitments).mul(AURUM_DECIMALS);
      require(aurum().balanceOf(msg.sender) >= recruitingCost,"Not enough aurum");
      require(aurum().allowance(msg.sender, address(this)) >= recruitingCost,"Needs AURUM approval");

      newRaiderRace = masterRecruitment(Race(raceNum));

      raceCount[newRaiderRace].increment(); // Just for tracking purposes so we can make sure nothing weird is happening

      uint nextTokenId = Raiders(raidersAddress).totalSupply(); // Gets the total supply of Raiders so we know what ID the next one will be for the Info contract

      uint newRaceAsUint = uint(newRaiderRace);

      RaiderInfo(infoAddress).addRaider(nextTokenId, newRaceAsUint, newRaiderGeneration); // Add the raider info so they get spawned

      history().updateRecruitedTime(raiderId, block.timestamp); // Log when this Raider last recruited so we can track their cooldown
      history().addRecruitedCount(raiderId);
      history().logWhoRecruited(nextTokenId, raiderId); // Add a log of who recruited who, so we can track lineage over time
      history().logWhenRaiderWasRecruited(nextTokenId, block.timestamp);

      if (newRaiderGeneration == 10) {
        history().logGen10Recruitment(raiderId);
      }

      aurum().safeTransferFrom(msg.sender, treasuryAddress, recruitingCost); // Transfer the Aurum
      Raiders(raidersAddress).mintRaiders(msg.sender, 1); // Mint them the new Raider, since this all happens in one TX the tokenIDs will match up
      emit RaiderRecruited(nextTokenId, newRaceAsUint, newRaiderGeneration, msg.sender);
      return nextTokenId;
    }

    // ----------- RECRUITMENT FUNCTIONS -----------

    function masterRecruitment(Race _race) internal returns (Race) {
      Rarity rarity = raceRarity[_race];
      Thresholds memory thresholds = rarityThresholds[rarity];

      uint bigRanNum = getBigRandomNum(uint(_race).mul(sameCount[_race].current()));
    	uint ranNum = bigRanNum.mod(thresholds.total);

      if (ranNum < thresholds.same) {
        sameCount[_race].increment();
        return _race;
    	} else if (thresholds.same <= ranNum && ranNum < thresholds.common) {
        return nextCommon();
    	} else if (thresholds.common <= ranNum && ranNum < thresholds.uncommon) {
        return nextUncommon();    
    	} else if (thresholds.uncommon <= ranNum && ranNum < thresholds.rare) {
        return nextRare();
    	} else {
        revert("Invalid condition for recruitment");
      }
    }

    // ----------- RECRUITMENT UTILITY FUNCTIONS -----------

    // These are the set of functions used in the recruitment functions
    
    // This returns the next Common Race character by rotating through the commonChars array above.
    function nextCommon() internal returns (Race) {
      Race race = commonChars[rarityCount[Rarity.Common].current().mod(19)];
      rarityCount[Rarity.Common].increment();
      return race;
    }
    
    // This returns the next Uncommon Race character by rotating through the uncommonChars array above.
    function nextUncommon() internal returns (Race) {
      Race race = uncommonChars[rarityCount[Rarity.Uncommon].current().mod(5)];
      rarityCount[Rarity.Uncommon].increment();
      return race;
    }
    
    // This returns the next Rare Race character by rotating through the rareChars array above.
    function nextRare() internal returns (Race) {
      Race race = rareChars[rarityCount[Rarity.Rare].current().mod(4)];
      rarityCount[Rarity.Rare].increment();
      return race;
    }
    
    function calcRecruitment(uint targetGeneration, uint raiderGeneration, uint gen10Recruitments) public view returns (uint) {
      require(targetGeneration > 0,"Invalid generation period");
      require(raiderGeneration > 0,"Invalid raider generation");
      uint raiderDiscount = generationMaxDiscount[raiderGeneration];
      uint thisPrice = generationBasesInAurum[targetGeneration];
      require(thisPrice > 0,"Aurum price not set yet");

      if (targetGeneration < FIRST_DISCOUNT_GENERATION) {
        // thisPrice = thisPrice;
      } else if (raiderDiscount == 0 || targetGeneration.sub(1) == raiderGeneration) {
        // thisPrice = thisPrice;
      } else {
        uint newGap = (targetGeneration.sub(1)).sub(raiderGeneration);
        uint computedTotal = discountStep.mul(newGap);

        uint actual = Math.min(raiderDiscount, computedTotal); //enforce max.
        uint discountAmt = (thisPrice.mul(actual)).div(100);
        thisPrice = thisPrice.sub(discountAmt);
      }

      if (targetGeneration == 10) {
        if (gen10Recruitments > 0) {
          uint multiplier = (gen10CostScale ** gen10Recruitments);
          thisPrice = thisPrice.mul(multiplier).div(100 ** gen10Recruitments);
        }
      }

      return thisPrice;
    }

    function getRaiderRecruitCost(uint raiderId) public view returns(uint) {
      uint[3] memory raiderInfo = RaiderInfo(infoAddress).checkRaider(raiderId);
      uint generation = raiderInfo[2];

      uint nextGeneration = nextRaiderRecruitGeneration(raiderId);
      uint gen10Recruitments = history().gen10Recruitments(raiderId);

      return calcRecruitment(nextGeneration, generation, gen10Recruitments);

    }

    function canRaiderRecruit(uint _raiderId) public view returns(bool) {
      uint recruitedTime = history().whenRaiderWasRecruited(_raiderId).add(recruitingFrequency);
      uint lastRecruitTime = history().raiderLastRecruitedTime(_raiderId).add(recruitingFrequency);
      if (recruitedTime < block.timestamp) {
        if (lastRecruitTime < block.timestamp) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    }

    function nextRecruitTime(uint _raiderId) public view returns(uint) {
      uint lastRecruited = history().raiderLastRecruitedTime(_raiderId);
      if (lastRecruited > 0) {
        uint nextRecruitTime = lastRecruited.add(recruitingFrequency);
        return nextRecruitTime.sub(block.timestamp);
      } else {
        uint nextRecruitTime = history().whenRaiderWasRecruited(_raiderId).add(recruitingFrequency);
        return nextRecruitTime.sub(block.timestamp);
      }
    }

    function nextRaiderRecruitGeneration(uint _raiderId) public view returns(uint) {
      uint[3] memory info = RaiderInfo(infoAddress).checkRaider(_raiderId);
      uint _raiderGeneration = info[2];
      uint nextGen;
      if (_raiderGeneration <= 3) {
        nextGen = history().raiderRecruitingCount(_raiderId).add(4); //starts at 4 since we've already done 1-3
      } else {
        nextGen = _raiderGeneration.add(history().raiderRecruitingCount(_raiderId)).add(1);
      }

      if (nextGen >= 10) {
        return 10; //this lets us cap it at 10
      } else {
        return nextGen;
      }
      
    }

    function getBigRandomNum(uint _seed) public view returns(uint) {
      return RaiderRandomness(randomnessAddress).getBigRandomNum(_seed);
    }

    // ----------- ADMIN FUNCTIONS -----------

    function pause() external onlyOwner {
      _pause();
    }

    function unpause() external onlyOwner {
      _unpause();
    }

    function updateTreasuryAddress(address _address) external onlyOwner {
      treasuryAddress = _address;
    }

    function makeTreasuryRaidersOwner() external onlyOwner {
      Ownable(raidersAddress).transferOwnership(treasuryAddress);
    }

    function makeTreasuryInfoOwner() external onlyOwner {
      RaiderInfo(infoAddress).transferOwnership(treasuryAddress);
    }

    function updateRecruitingFrequency(uint _frequency) external onlyOwner {
      recruitingFrequency = _frequency;
    }

    function updateAurumBaseForGeneration(uint generation, uint aurumAmt) external onlyOwner {
      generationBasesInAurum[generation] = aurumAmt;
    }

    function updateMaxDiscountForGeneration(uint generation, uint maxDiscount) external onlyOwner {
      generationMaxDiscount[generation] = maxDiscount;
    }

    function updateDiscountStep(uint newStep) external onlyOwner {
      discountStep = newStep;
    }

    function updateActiveRecruitment(uint generation_number) external onlyOwner {
      activeRecruitmentGeneration = generation_number;
    }

    function updateGen10CostScale(uint _scale) external onlyOwner {
      gen10CostScale = _scale;
    }

    function updateRandomnessAddress(address _randomness) external onlyOwner {
      randomnessAddress = _randomness;
    }
    

    // ----------- VIEW FUNCTIONS -----------

    function currentRaceCounts() public view returns(uint[11] memory) {
      uint[11] memory raceCounts;
      raceCounts = [raceCount[Race.Mike].current(),
      raceCount[Race.John].current(),
      raceCount[Race.Tammy].current(),
      raceCount[Race.Old].current(),
      raceCount[Race.White].current(),
      raceCount[Race.Blue].current(),
      raceCount[Race.Orc].current(),
      raceCount[Race.Skeleton].current(),
      raceCount[Race.Cyborg].current(),
      raceCount[Race.Dark].current(),
      raceCount[Race.Fairy].current()];
      return raceCounts;
    }

    function recruitmentCost(uint _currentGeneration, uint _targetGeneration, uint _gen10Recruitments) external view returns(uint) {
      return calcRecruitment(_currentGeneration, _targetGeneration, _gen10Recruitments);
    }
}