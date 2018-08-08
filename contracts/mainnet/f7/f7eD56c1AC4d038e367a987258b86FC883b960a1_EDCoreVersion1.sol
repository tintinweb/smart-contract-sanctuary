pragma solidity ^0.4.19;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title EjectableOwnable
 * @dev The EjectableOwnable contract provides the function to remove the ownership of the contract.
 */
contract EjectableOwnable is Ownable {
    
    /**
     * @dev Remove the ownership by setting the owner address to null, 
     * after calling this function, all onlyOwner function will be be able to be called by anyone anymore, 
     * the contract will achieve truly decentralisation.
    */
    function removeOwnership() onlyOwner public {
        owner = 0x0;
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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  
}


/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send.
 */
contract PullPayment {
    
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
   * @dev withdraw accumulated balance, called by payee.
   */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

  /**
   * @dev Called by the payer to store the sent amount as credit to be pulled.
   * @param dest The destination address of the funds.
   * @param amount The amount to transfer.
   */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
  
}


/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
  
}


contract EDStructs {
    
    /**
     * @dev The main Dungeon struct. Every dungeon in the game is represented by this structure.
     * A dungeon is consists of an unlimited number of floors for your heroes to challenge, 
     * the power level of a dungeon is encoded in the floorGenes. Some dungeons are in fact more "challenging" than others,
     * the secret formula for that is left for user to find out.
     * 
     * Each dungeon also has a "training area", heroes can perform trainings and upgrade their stat,
     * and some dungeons are more effective in the training, which is also a secret formula!
     * 
     * When player challenge or do training in a dungeon, the fee will be collected as the dungeon rewards,
     * which will be rewarded to the player who successfully challenged the current floor.
     * 
     * Each dungeon fits in fits into three 256-bit words.
     */
    struct Dungeon {
        
        // Each dungeon has an ID which is the index in the storage array.

        // The timestamp of the block when this dungeon is created.
        uint32 creationTime;
        
        // The status of the dungeon, each dungeon can have 5 status, namely:
        // 0: Active | 1: Transport Only | 2: Challenge Only | 3: Train Only | 4: InActive
        uint8 status;
        
        // The dungeon&#39;s difficulty, the higher the difficulty, 
        // normally, the "rarer" the seedGenes, the higher the diffculty,
        // and the higher the contribution fee it is to challenge, train, and transport to the dungeon,
        // the formula for the contribution fee is in DungeonChallenge and DungeonTraining contracts.
        // A dungeon&#39;s difficulty never change.
        uint8 difficulty;
        
        // The dungeon&#39;s capacity, maximum number of players allowed to stay on this dungeon.
        // The capacity of the newbie dungeon (Holyland) is set at 0 (which is infinity).
        // Using 16-bit unsigned integers can have a maximum of 65535 in capacity.
        // A dungeon&#39;s capacity never change.
        uint16 capacity;
        
        // The current floor number, a dungeon is consists of an umlimited number of floors,
        // when there is heroes successfully challenged a floor, the next floor will be
        // automatically generated. Using 32-bit unsigned integer can have a maximum of 4 billion floors.
        uint32 floorNumber;
        
        // The timestamp of the block when the current floor is generated.
        uint32 floorCreationTime;
        
        // Current accumulated rewards, successful challenger will get a large proportion of it.
        uint128 rewards;
        
        // The seed genes of the dungeon, it is used as the base gene for first floor, 
        // some dungeons are rarer and some are more common, the exact details are, 
        // of course, top secret of the game! 
        // A dungeon&#39;s seedGenes never change.
        uint seedGenes;
        
        // The genes for current floor, it encodes the difficulty level of the current floor.
        // We considered whether to store the entire array of genes for all floors, but
        // in order to save some precious gas we&#39;re willing to sacrifice some functionalities with that.
        uint floorGenes;
        
    }
    
    /**
     * @dev The main Hero struct. Every hero in the game is represented by this structure.
     */
    struct Hero {

        // Each hero has an ID which is the index in the storage array.
        
        // The timestamp of the block when this dungeon is created.
        uint64 creationTime;
        
        // The timestamp of the block where a challenge is performed, used to calculate when a hero is allowed to engage in another challenge.
        uint64 cooldownStartTime;
        
        // Every time a hero challenge a dungeon, its cooldown index will be incremented by one.
        uint32 cooldownIndex;
        
        // The seed of the hero, the gene encodes the power level of the hero.
        // This is another top secret of the game! Hero&#39;s gene can be upgraded via
        // training in a dungeon.
        uint genes;
        
    }
    
}


/**
 * @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens.
 */
contract ERC721 {
    
    // Events
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    
    // ERC20 compatible functions.
    // function name() public constant returns (string);
    // function symbol() public constant returns (string);
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint);
    
    // Functions that define ownership.
    function ownerOf(uint _tokenId) external view returns (address);
    function transfer(address _to, uint _tokenId) external;
    
    // Approval related functions, mainly used in auction contracts.
    function approve(address _to, uint _tokenId) external;
    function approvedFor(uint _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint _tokenId) external;
    
    /**
     * @dev Each non-fungible token owner can own more than one token at one time. 
     * Because each token is referenced by its unique ID, however, 
     * it can get difficult to keep track of the individual tokens that a user may own. 
     * To do this, the contract keeps a record of the IDs of each token that each user owns.
     */
    mapping(address => uint[]) public ownerTokens;

}


contract DungeonTokenInterface is ERC721, EDStructs {

    /**
     * @notice Limits the number of dungeons the contract owner can ever create.
     */
    uint public constant DUNGEON_CREATION_LIMIT = 1024;
    
    /**
     * @dev Name of token.
     */
    string public constant name = "Dungeon";
    
    /**
     * @dev Symbol of token.
     */
    string public constant symbol = "DUNG";
    
    /**
     * @dev An array containing the Dungeon struct, which contains all the dungeons in existance.
     *  The ID for each dungeon is the index of this array.
     */ 
    Dungeon[] public dungeons;

    /**
     * @dev The external function that creates a new dungeon and stores it, only contract owners
     *  can create new token, and will be restricted by the DUNGEON_CREATION_LIMIT.
     *  Will generate a Mint event, a  NewDungeonFloor event, and a Transfer event.
     */ 
    function createDungeon(uint _difficulty, uint _capacity, uint _floorNumber, uint _seedGenes, uint _floorGenes, address _owner) external returns (uint);
    
    /**
     * @dev The external function to set dungeon status by its ID, 
     *  refer to DungeonStructs for more information about dungeon status.
     *  Only contract owners can alter dungeon state.
     */ 
    function setDungeonStatus(uint _id, uint _newStatus) external;
    
    /**
     * @dev The external function to add additional dungeon rewards by its ID, 
     *  only contract owners can alter dungeon state.
     */ 
    function addDungeonRewards(uint _id, uint _additinalRewards) external;
    
    /**
     * @dev The external function to add another dungeon floor by its ID, 
     *  only contract owners can alter dungeon state.
     */ 
    function addDungeonNewFloor(uint _id, uint _newRewards, uint _newFloorGenes) external;
    
}


contract HeroTokenInterface is ERC721, EDStructs {
    
    /**
     * @dev Name of token.
     */
    string public constant name = "Hero";
    
    /**
     * @dev Symbol of token.
     */
    string public constant symbol = "HERO";

    /**
     * @dev An array containing the Hero struct, which contains all the heroes in existance.
     *  The ID for each hero is the index of this array.
     */ 
    Hero[] public heroes;

    /**
     * @dev An external function that creates a new hero and stores it,
     *  only contract owners can create new token.
     *  method doesn&#39;t do any checking and should only be called when the
     *  input data is known to be valid.
     * @param _genes The gene of the new hero.
     * @param _owner The inital owner of this hero.
     * @return The hero ID of the new hero.
     */
    function createHero(uint _genes, address _owner) external returns (uint);
    
    /**
     * @dev The external function to set the hero genes by its ID, 
     *  only contract owners can alter hero state.
     */ 
    function setHeroGenes(uint _id, uint _newGenes) external;

    /**
     * @dev Set the cooldownStartTime for the given hero. Also increments the cooldownIndex.
     */
    function triggerCooldown(uint _id) external;
    
}


/**
 * SECRET
 */
contract ChallengeFormulaInterface {
    
    /**
     * @dev given genes of current floor and dungeon seed, return a genetic combination - may have a random factor.
     * @param _floorGenes Genes of floor.
     * @param _seedGenes Seed genes of dungeon.
     * @return The resulting genes.
     */
    function calculateResult(uint _floorGenes, uint _seedGenes) external returns (uint);
    
}


/**
 * SECRET
 */
contract TrainingFormulaInterface {
    
    /**
     * @dev given genes of hero and current floor, return a genetic combination - may have a random factor.
     * @param _heroGenes Genes of hero.
     * @param _floorGenes Genes of current floor.
     * @param _equipmentId Equipment index to train for, 0 is train all attributes.
     * @return The resulting genes.
     */
    function calculateResult(uint _heroGenes, uint _floorGenes, uint _equipmentId) external returns (uint);
    
}


/**
 * @title EDBase
 * @dev Base contract for Ether Dungeon. It implements all necessary sub-classes,
 *  holds all the contracts, constants, game settings, storage variables, events, and some commonly used functions.
 */
contract EDBase is EjectableOwnable, Pausable, PullPayment, EDStructs {
    
    /* ======== CONTRACTS ======== */
    
    /// @dev The address of the ERC721 token contract managing all Dungeon tokens.
    DungeonTokenInterface public dungeonTokenContract;
    
    /// @dev The address of the ERC721 token contract managing all Hero tokens.
    HeroTokenInterface public heroTokenContract;
    
    /// @dev The address of the ChallengeFormula contract that handles the floor generation mechanics after challenge success.
    ChallengeFormulaInterface challengeFormulaContract;
    
    /// @dev The address of the TrainingFormula contract that handles the hero training mechanics.
    TrainingFormulaInterface trainingFormulaContract;
    
    
    /* ======== CONSTANTS / GAME SETTINGS (all variables are set to constant in order to save gas) ======== */
    
    // 1 finney = 0.001 ether
    // 1 szabo = 0.001 finney
    
    /// @dev Super Hero (full set of same-themed Rare Equipments, there are 8 in total)
    uint public constant SUPER_HERO_MULTIPLIER = 32;
    
    /// @dev Ultra Hero (full set of same-themed Epic Equipments, there are 4 in total)
    uint public constant ULTRA_HERO_MULTIPLIER = 64;
    
    /**
     * @dev Mega Hero (full set of same-themed Legendary Equipments, there are 2 in total)
     *  There are also 2 Ultimate Hero/Demon, Pangu and Chaos, which will use the MEGA_HERO_MULTIPLIER.
     */
    uint public constant MEGA_HERO_MULTIPLIER = 96;
    
    /// @dev The fee for recruiting a hero. The payment is accumulated to the rewards of the origin dungeon.
    uint public recruitHeroFee = 2 finney;
    
    /**
     * @dev The actual fee contribution required to call transport() is calculated by this feeMultiplier,
     *  times the dungeon difficulty of destination dungeon. The payment is accumulated to the rewards of the origin dungeon,
     *  and a large proportion will be claimed by whoever successfully challenged the floor.
     */
    uint public transportationFeeMultiplier = 250 szabo;
    
    ///@dev All hero starts in the novice dungeon, also hero can only be recruited in novice dungoen.
    uint public noviceDungeonId = 31; // < dungeon ID 31 = Abyss
    
    /// @dev Amount of faith required to claim a portion of the grandConsolationRewards.
    uint public consolationRewardsRequiredFaith = 100;
    
    /// @dev The percentage for which when a player can get from the grandConsolationRewards when meeting the faith requirement.
    uint public consolationRewardsClaimPercent = 50;
    
    /**
     * @dev The actual fee contribution required to call challenge() is calculated by this feeMultiplier,
     *  times the dungeon difficulty. The payment is accumulated to the dungeon rewards, 
     *  and a large proportion will be claimed by whoever successfully challenged the floor.
     */
    uint public constant challengeFeeMultiplier = 1 finney;
    
    /**
     * @dev The percentage for which successful challenger be rewarded of the dungeons&#39; accumulated rewards.
     *  The remaining rewards subtract dungeon master rewards and consolation rewards will be used as the base rewards for new floor.
     */
    uint public constant challengeRewardsPercent = 45;
    
    /**
     * @dev The developer fee for dungeon master (owner of the dungeon token).
     *  Note that when Ether Dungeon becomes truly decentralised, contract ownership will be ejected,
     *  and the master rewards will be rewarded to the dungeon owner (Dungeon Masters).
     */
    uint public constant masterRewardsPercent = 8;
    
    /// @dev The percentage for which the challenge rewards is added to the grandConsolationRewards.
    uint public consolationRewardsPercent = 2;
    
    /// @dev The preparation time period where a new dungeon is created, before it can be challenged.
    uint public dungeonPreparationTime = 60 minutes;
    
    /// @dev The challenge rewards percentage used right after the preparation period.
    uint public constant rushTimeChallengeRewardsPercent = 22;
    
    /// @dev The number of floor in which the rushTimeChallengeRewardsPercent be applied.
    uint public constant rushTimeFloorCount = 30;
    
    /**
     * @dev The actual fee contribution required to call trainX() is calculated by this feeMultiplier,
     *  times the dungeon difficulty, times training times. The payment is accumulated to the dungeon rewards, 
     *  and a large proportion will be claimed by whoever successfully challenged the floor.
     */
    uint public trainingFeeMultiplier = 2 finney;
    
    /**
     * @dev The actual fee contribution required to call trainEquipment() is calculated by this feeMultiplier,
     *  times the dungeon difficulty. The payment is accumulated to the dungeon rewards.
     *  (No preparation period discount on equipment training.)
     */
    uint public equipmentTrainingFeeMultiplier = 8 finney;
    
    /// @dev The discounted training fee multiplier to be used during preparation period.
    uint public constant preparationPeriodTrainingFeeMultiplier = 1600 szabo;
    
    /// @dev The discounted equipment training fee multiplier to be used during preparation period.
    uint public constant preparationPeriodEquipmentTrainingFeeMultiplier = 6400 szabo;
    
    
    /* ======== STATE VARIABLES ======== */
    
    /**
     * @dev After each successful training, do not update Hero immediately to avoid exploit.
     *  The hero power will be auto updated during next challenge/training for any player.
     *  Or calling the setTempHeroPower() public function directly.
     */
    mapping(address => uint) playerToLastActionBlockNumber;
    uint tempSuccessTrainingHeroId;
    uint tempSuccessTrainingNewHeroGenes = 1; // value 1 is used as no pending update
    
    /// @dev The total accumulated consolidation jackpot / rewards amount.
    uint public grandConsolationRewards = 168203010964693559; // < migrated from previous contract
    
    /// @dev A mapping from token IDs to the address that owns them, the value can get by getPlayerDetails.
    mapping(address => uint) playerToDungeonID;
    
    /// @dev A mapping from player address to the player&#39;s faith value, the value can get by getPlayerDetails.
    mapping(address => uint) playerToFaith;

    /**
     * @dev A mapping from owner address to a boolean flag of whether the player recruited the first hero.
     *  Note that transferring a hero from other address do not count, the value can get by getPlayerDetails.
     */
    mapping(address => bool) playerToFirstHeroRecruited;

    /// @dev A mapping from owner address to count of tokens that address owns, the value can get by getDungeonDetails.
    mapping(uint => uint) dungeonIdToPlayerCount;
    
    
    /* ======== EVENTS ======== */
    
    /// @dev The PlayerTransported event is fired when user transported to another dungeon.
    event PlayerTransported(uint timestamp, address indexed playerAddress, uint indexed originDungeonId, uint indexed destinationDungeonId);
    
    /// @dev The DungeonChallenged event is fired when user finished a dungeon challenge.
    event DungeonChallenged(uint timestamp, address indexed playerAddress, uint indexed dungeonId, uint indexed heroId, uint heroGenes, uint floorNumber, uint floorGenes, bool success, uint newFloorGenes, uint successRewards, uint masterRewards);
  
    /// @dev The DungeonChallenged event is fired when user finished a dungeon challenge.
    event ConsolationRewardsClaimed(uint timestamp, address indexed playerAddress, uint consolationRewards);
  
    /// @dev The HeroTrained event is fired when user finished a training.
    event HeroTrained(uint timestamp, address indexed playerAddress, uint indexed dungeonId, uint indexed heroId, uint heroGenes, uint floorNumber, uint floorGenes, bool success, uint newHeroGenes);
    
    
    /* ======== PUBLIC/EXTERNAL FUNCTIONS ======== */
    
    /**
     * @dev Get the attributes (equipments + stats) of a hero from its gene.
     */
    function getHeroAttributes(uint _genes) public pure returns (uint[]) {
        uint[] memory attributes = new uint[](12);
        
        for (uint i = 0; i < 12; i++) {
            attributes[11 - i] = _genes % 32;
            _genes /= 32 ** 4;
        }
        
        return attributes;
    }
    
    /**
     * @dev Calculate the power of a hero from its gene,
     *  it calculates the equipment power, stats power, and super hero boost.
     */
    function getHeroPower(uint _genes, uint _dungeonDifficulty) public pure returns (
        uint totalPower, 
        uint equipmentPower, 
        uint statsPower, 
        bool isSuper, 
        uint superRank,
        uint superBoost
    ) {
        // Individual power of each equipment.
        // DUPLICATE CODE with _getDungeonPower: Constant array variable is not yet implemented,
        // so need to put it here in order to save gas.
        uint16[32] memory EQUIPMENT_POWERS = [
            1, 2, 4, 5, 16, 17, 32, 33, // [Holy] Normal Equipments
            8, 16, 16, 32, 32, 48, 64, 96, // [Myth] Normal Equipments
            
            4, 16, 32, 64, // [Holy] Rare Equipments
            32, 48, 80, 128, // [Myth] Rare Equipments
            
            32, 96, // [Holy] Epic Equipments
            80, 192, // [Myth] Epic Equipments
            
            192, // [Holy] Legendary Equipments
            288, // [Myth] Legendary Equipments
            
            // Pangu / Chaos Legendary Equipments are reserved for far future use.
            // Their existence is still a mystery.
            384, // [Pangu] Legendary Equipments
            512 // [Chaos] Legendary Equipments
        ];
        
        uint[] memory attributes = getHeroAttributes(_genes);
        
        // Calculate total equipment power.
        superRank = attributes[0];
        
        for (uint i = 0; i < 8; i++) {
            uint equipment = attributes[i];
            equipmentPower += EQUIPMENT_POWERS[equipment];
            
            // If any equipment is of difference index, set superRank to 0.
            if (superRank != equipment) {
                superRank = 0;
            }
        }
        
        // Calculate total stats power.
        for (uint j = 8; j < 12; j++) {
            // Stat power is gene number + 1.
            statsPower += attributes[j] + 1;
        }
        
        // Calculate Super/Ultra/Mega Power Boost.
        isSuper = superRank >= 16;
        
        if (superRank >= 28) { // Mega Hero
            superBoost = (_dungeonDifficulty - 1) * MEGA_HERO_MULTIPLIER;
        } else if (superRank >= 24) { // Ultra Hero
            superBoost = (_dungeonDifficulty - 1) * ULTRA_HERO_MULTIPLIER;
        } else if (superRank >= 16) { // Super Hero
            superBoost = (_dungeonDifficulty - 1) * SUPER_HERO_MULTIPLIER;
        }
        
        totalPower = statsPower + equipmentPower + superBoost;
    }
    
    /**
     * @dev Calculate the power of a dungeon floor.
     */
    function getDungeonPower(uint _genes) public pure returns (uint) {
        // Individual power of each equipment.
        // DUPLICATE CODE with getHeroPower
        uint16[32] memory EQUIPMENT_POWERS = [
            1, 2, 4, 5, 16, 17, 32, 33, // [Holy] Normal Equipments
            8, 16, 16, 32, 32, 48, 64, 96, // [Myth] Normal Equipments
            
            4, 16, 32, 64, // [Holy] Rare Equipments
            32, 48, 80, 128, // [Myth] Rare Equipments
            
            32, 96, // [Holy] Epic Equipments
            80, 192, // [Myth] Epic Equipments
            
            192, // [Holy] Legendary Equipments
            288, // [Myth] Legendary Equipments
            
            // Pangu / Chaos Legendary Equipments are reserved for far future use.
            // Their existence is still a mystery.
            384, // [Pangu] Legendary Equipments
            512 // [Chaos] Legendary Equipments
        ];
        
        // Calculate total dungeon power.
        uint dungeonPower;
        
        for (uint j = 0; j < 12; j++) {
            dungeonPower += EQUIPMENT_POWERS[_genes % 32];
            _genes /= 32 ** 4;
        }
        
        return dungeonPower;
    }
    
    /**
     * @dev Calculate the sum of top 5 heroes power a player owns.
     *  The gas usage increased with the number of heroes a player owned, roughly 500 x hero count.
     *  This is used in transport function only to calculate the required tranport fee.
     */
    function calculateTop5HeroesPower(address _address, uint _dungeonId) public view returns (uint) {
        uint heroCount = heroTokenContract.balanceOf(_address);
        
        if (heroCount == 0) {
            return 0;
        }
        
        // Get the dungeon difficulty to factor in the super power boost when calculating hero power.
        uint difficulty;
        (,, difficulty,,,,,,) = dungeonTokenContract.dungeons(_dungeonId);
        
        // Compute all hero powers for further calculation.
        uint[] memory heroPowers = new uint[](heroCount);
        
        for (uint i = 0; i < heroCount; i++) {
            uint heroId = heroTokenContract.ownerTokens(_address, i);
            uint genes;
            (,,, genes) = heroTokenContract.heroes(heroId);
            (heroPowers[i],,,,,) = getHeroPower(genes, difficulty);
        }
        
        // Calculate the top 5 heroes power.
        uint result;
        uint curMax;
        uint curMaxIndex;
        
        for (uint j; j < 5; j++) {
            for (uint k = 0; k < heroPowers.length; k++) {
                if (heroPowers[k] > curMax) {
                    curMax = heroPowers[k];
                    curMaxIndex = k;
                }
            }
            
            result += curMax;
            heroPowers[curMaxIndex] = 0;
            curMax = 0;
            curMaxIndex = 0;
        }
        
        return result;
    }
    
    /// @dev Set the previously temp stored upgraded hero genes. Can only be called by contract owner.
    function setTempHeroPower() onlyOwner public {
       _setTempHeroPower();
    }
    
    
    /* ======== SETTER FUNCTIONS ======== */
    
    /// @dev Set the address of the dungeon token contract.
    function setDungeonTokenContract(address _newDungeonTokenContract) onlyOwner external {
        dungeonTokenContract = DungeonTokenInterface(_newDungeonTokenContract);
    }
    
    /// @dev Set the address of the hero token contract.
    function setHeroTokenContract(address _newHeroTokenContract) onlyOwner external {
        heroTokenContract = HeroTokenInterface(_newHeroTokenContract);
    }
    
    /// @dev Set the address of the secret dungeon challenge formula contract.
    function setChallengeFormulaContract(address _newChallengeFormulaAddress) onlyOwner external {
        challengeFormulaContract = ChallengeFormulaInterface(_newChallengeFormulaAddress);
    }
    
    /// @dev Set the address of the secret hero training formula contract.
    function setTrainingFormulaContract(address _newTrainingFormulaAddress) onlyOwner external {
        trainingFormulaContract = TrainingFormulaInterface(_newTrainingFormulaAddress);
    }
    
    /// @dev Updates the fee for calling recruitHero().
    function setRecruitHeroFee(uint _newRecruitHeroFee) onlyOwner external {
        recruitHeroFee = _newRecruitHeroFee;
    }
    
    /// @dev Updates the fee contribution multiplier required for calling transport().
    function setTransportationFeeMultiplier(uint _newTransportationFeeMultiplier) onlyOwner external {
        transportationFeeMultiplier = _newTransportationFeeMultiplier;
    }
    
    /// @dev Updates the novice dungeon ID.
    function setNoviceDungeonId(uint _newNoviceDungeonId) onlyOwner external {
        noviceDungeonId = _newNoviceDungeonId;
    }
    
    /// @dev Updates the required amount of faith to get a portion of the consolation rewards.
    function setConsolationRewardsRequiredFaith(uint _newConsolationRewardsRequiredFaith) onlyOwner external {
        consolationRewardsRequiredFaith = _newConsolationRewardsRequiredFaith;
    }
    
    /// @dev Updates the percentage portion of consolation rewards a player get when meeting the faith requirement.
    function setConsolationRewardsClaimPercent(uint _newConsolationRewardsClaimPercent) onlyOwner external {
        consolationRewardsClaimPercent = _newConsolationRewardsClaimPercent;
    }
    
    /// @dev Updates the consolation rewards percentage.
    function setConsolationRewardsPercent(uint _newConsolationRewardsPercent) onlyOwner external {
        consolationRewardsPercent = _newConsolationRewardsPercent;
    }
    
    /// @dev Updates the challenge cooldown time.
    function setDungeonPreparationTime(uint _newDungeonPreparationTime) onlyOwner external {
        dungeonPreparationTime = _newDungeonPreparationTime;
    }
    
    /// @dev Updates the fee contribution multiplier required for calling trainX().
    function setTrainingFeeMultiplier(uint _newTrainingFeeMultiplier) onlyOwner external {
        trainingFeeMultiplier = _newTrainingFeeMultiplier;
    }

    /// @dev Updates the fee contribution multiplier required for calling trainEquipment().
    function setEquipmentTrainingFeeMultiplier(uint _newEquipmentTrainingFeeMultiplier) onlyOwner external {
        equipmentTrainingFeeMultiplier = _newEquipmentTrainingFeeMultiplier;
    }
    
    
    /* ======== INTERNAL/PRIVATE FUNCTIONS ======== */
    
    /**
     * @dev Internal function to set the previously temp stored upgraded hero genes. 
     * Every challenge/training will first call this function.
     */
    function _setTempHeroPower() internal {
        // Genes of 1 is used as no pending update.
        if (tempSuccessTrainingNewHeroGenes != 1) {
            // ** STORAGE UPDATE **
            heroTokenContract.setHeroGenes(tempSuccessTrainingHeroId, tempSuccessTrainingNewHeroGenes);
            
            // Reset the variables to indicate no pending update.
            tempSuccessTrainingNewHeroGenes = 1;
        }
    }
    
    
    /* ======== MODIFIERS ======== */
    
    /**
     * @dev Throws if _dungeonId is not created yet.
     */
    modifier dungeonExists(uint _dungeonId) {
        require(_dungeonId < dungeonTokenContract.totalSupply());
        _;
    }
    
}


contract EDTransportation is EDBase {

    /* ======== PUBLIC/EXTERNAL FUNCTIONS ======== */
    
    /// @dev Recruit a new novice hero with no attributes (gene = 0).
    function recruitHero() whenNotPaused external payable returns (uint) {
        // Only allow recruiting hero in the novice dungeon, or first time recruiting hero.
        require(playerToDungeonID[msg.sender] == noviceDungeonId || !playerToFirstHeroRecruited[msg.sender]);
        
        // Checks for payment, any exceeding funds will be transferred back to the player.
        require(msg.value >= recruitHeroFee);
        
        // ** STORAGE UPDATE **
        // Increment the accumulated rewards for the dungeon, 
        // since player can only recruit hero in the novice dungeon, rewards is added there.
        dungeonTokenContract.addDungeonRewards(noviceDungeonId, recruitHeroFee);

        // Calculate any excess funds and make it available to be withdrawed by the player.
        asyncSend(msg.sender, msg.value - recruitHeroFee);
        
        // If it is the first time recruiting a hero, set the player&#39;s location to the novice dungeon.
        if (!playerToFirstHeroRecruited[msg.sender]) {
            // ** STORAGE UPDATE **
            dungeonIdToPlayerCount[noviceDungeonId]++;
            playerToDungeonID[msg.sender] = noviceDungeonId;
            playerToFirstHeroRecruited[msg.sender] = true;
        }
        
        return heroTokenContract.createHero(0, msg.sender);
    }
    
    /**
     * @dev The main external function to call when a player transport to another dungeon.
     *  Will generate a PlayerTransported event.
     *  Player must have at least one hero in order to perform
     */
    function transport(uint _destinationDungeonId) whenNotPaused dungeonCanTransport(_destinationDungeonId) playerAllowedToTransport() external payable {
        uint originDungeonId = playerToDungeonID[msg.sender];
        
        // Disallow transport to the same dungeon.
        require(_destinationDungeonId != originDungeonId);
        
        // Get the dungeon details from the token contract.
        uint difficulty;
        (,, difficulty,,,,,,) = dungeonTokenContract.dungeons(_destinationDungeonId);
        
        // Disallow weaker user to transport to "difficult" dungeon.
        uint top5HeroesPower = calculateTop5HeroesPower(msg.sender, _destinationDungeonId);
        require(top5HeroesPower >= difficulty * 12);
        
        // Checks for payment, any exceeding funds will be transferred back to the player.
        // The transportation fee is calculated by a base fee from transportationFeeMultiplier,
        // plus an additional fee increased with the total power of top 5 heroes owned.
        uint baseFee = difficulty * transportationFeeMultiplier;
        uint additionalFee = top5HeroesPower / 64 * transportationFeeMultiplier;
        uint requiredFee = baseFee + additionalFee;
        require(msg.value >= requiredFee);
        
        // ** STORAGE UPDATE **
        // Increment the accumulated rewards for the dungeon.
        dungeonTokenContract.addDungeonRewards(originDungeonId, requiredFee);

        // Calculate any excess funds and make it available to be withdrawed by the player.
        asyncSend(msg.sender, msg.value - requiredFee);

        _transport(originDungeonId, _destinationDungeonId);
    }
    
    
    /* ======== INTERNAL/PRIVATE FUNCTIONS ======== */
    
    /// @dev Internal function to assigns location of a player.
    function _transport(uint _originDungeonId, uint _destinationDungeonId) internal {
        // ** STORAGE UPDATE **
        // Update the dungeons&#39; player count.
        // Normally the player count of original dungeon will already be > 0,
        // perform checking to avoid unexpected overflow
        if (dungeonIdToPlayerCount[_originDungeonId] > 0) {
            dungeonIdToPlayerCount[_originDungeonId]--;
        }
        
        dungeonIdToPlayerCount[_destinationDungeonId]++;
        
        // ** STORAGE UPDATE **
        // Update player location.
        playerToDungeonID[msg.sender] = _destinationDungeonId;
            
        // Emit the DungeonChallenged event.
        PlayerTransported(now, msg.sender, _originDungeonId, _destinationDungeonId);
    }
    
    
    /* ======== MODIFIERS ======== */
    
    /**
     * @dev Throws if dungeon status do not allow transportation, also check for dungeon existence.
     *  Also check if the capacity of the destination dungeon is reached.
     */
    modifier dungeonCanTransport(uint _destinationDungeonId) {
        require(_destinationDungeonId < dungeonTokenContract.totalSupply());
        
        uint status;
        uint capacity;
        (, status,, capacity,,,,,) = dungeonTokenContract.dungeons(_destinationDungeonId);
        require(status == 0 || status == 1);
        
        // Check if the capacity of the destination dungeon is reached.
        // Capacity 0 = Infinity
        require(capacity == 0 || dungeonIdToPlayerCount[_destinationDungeonId] < capacity);
        _;
    }
    
    /// @dev Throws if player did recruit first hero yet.
    modifier playerAllowedToTransport() {
        // Note that we check playerToFirstHeroRecruited instead of heroTokenContract.balanceOf
        // in order to prevent "capacity attack".
        require(playerToFirstHeroRecruited[msg.sender]);
        _;
    }
    
}


contract EDChallenge is EDTransportation {
    
    /* ======== PUBLIC/EXTERNAL FUNCTIONS ======== */
    
    /**
     * @dev The main external function to call when a player challenge a dungeon,
     *  it determines whether if the player successfully challenged the current floor.
     *  Will generate a DungeonChallenged event.
     */
    function challenge(uint _dungeonId, uint _heroId) whenNotPaused dungeonCanChallenge(_dungeonId) heroAllowedToChallenge(_heroId) external payable {
        // Set the last action block number, disallow player to perform another train or challenge in the same block.
        playerToLastActionBlockNumber[msg.sender] = block.number;
        
        // Set the previously temp stored upgraded hero genes.
        _setTempHeroPower();
        
        // Get the dungeon details from the token contract.
        uint difficulty;
        uint seedGenes;
        (,, difficulty,,,,, seedGenes,) = dungeonTokenContract.dungeons(_dungeonId);
        
        // Checks for payment, any exceeding funds will be transferred back to the player.
        uint requiredFee = difficulty * challengeFeeMultiplier;
        require(msg.value >= requiredFee);
        
        // ** STORAGE UPDATE **
        // Increment the accumulated rewards for the dungeon.
        dungeonTokenContract.addDungeonRewards(_dungeonId, requiredFee);

        // Calculate any excess funds and make it available to be withdrawed by the player.
        asyncSend(msg.sender, msg.value - requiredFee);
        
        // Split the challenge function into multiple parts because of stack too deep error.
        _challengePart2(_dungeonId, difficulty, _heroId);
    }
    
    
    /* ======== INTERNAL/PRIVATE FUNCTIONS ======== */
    
    /// @dev Compute the remaining time for which the hero can perform a challenge again.
    function _computeCooldownRemainingTime(uint _heroId) internal view returns (uint) {
        uint cooldownStartTime;
        uint cooldownIndex;
        (, cooldownStartTime, cooldownIndex,) = heroTokenContract.heroes(_heroId);
        
        // Cooldown period is FLOOR(challenge count / 2) ^ 2 minutes
        uint cooldownPeriod = (cooldownIndex / 2) ** 2 * 1 minutes;
        
        if (cooldownPeriod > 100 minutes) {
            cooldownPeriod = 100 minutes;
        }
        
        uint cooldownEndTime = cooldownStartTime + cooldownPeriod;
        
        if (cooldownEndTime <= now) {
            return 0;
        } else {
            return cooldownEndTime - now;
        }
    }
    
    /// @dev Split the challenge function into multiple parts because of stack too deep error.
    function _challengePart2(uint _dungeonId, uint _dungeonDifficulty, uint _heroId) private {
        uint floorNumber;
        uint rewards;
        uint floorGenes;
        (,,,, floorNumber,, rewards,, floorGenes) = dungeonTokenContract.dungeons(_dungeonId);
        
        // Get the hero gene.
        uint heroGenes;
        (,,, heroGenes) = heroTokenContract.heroes(_heroId);
        
        bool success = _getChallengeSuccess(heroGenes, _dungeonDifficulty, floorGenes);
        
        uint newFloorGenes;
        uint masterRewards;
        uint consolationRewards;
        uint successRewards;
        uint newRewards;
        
        // Whether a challenge is success or not is determined by a simple comparison between hero power and floor power.
        if (success) {
            newFloorGenes = _getNewFloorGene(_dungeonId);
            
            masterRewards = rewards * masterRewardsPercent / 100;
            
            consolationRewards = rewards * consolationRewardsPercent / 100;
            
            if (floorNumber < rushTimeFloorCount) { // rush time right after prepration period
                successRewards = rewards * rushTimeChallengeRewardsPercent / 100;
                
                // The dungeon rewards for new floor as total rewards - challenge rewards - devleoper fee.
                newRewards = rewards * (100 - rushTimeChallengeRewardsPercent - masterRewardsPercent - consolationRewardsPercent) / 100;
            } else {
                successRewards = rewards * challengeRewardsPercent / 100;
                newRewards = rewards * (100 - challengeRewardsPercent - masterRewardsPercent - consolationRewardsPercent) / 100;
            }
            
            // TRIPLE CONFIRM sanity check.
            require(successRewards + masterRewards + consolationRewards + newRewards <= rewards);
            
            // ** STORAGE UPDATE **
            // Add the consolation rewards to grandConsolationRewards.
            grandConsolationRewards += consolationRewards;
            
            // Add new floor with the new floor genes and new rewards.
            dungeonTokenContract.addDungeonNewFloor(_dungeonId, newRewards, newFloorGenes);
            
            // Mark the challenge rewards available to be withdrawed by the player.
            asyncSend(msg.sender, successRewards);
            
            // Mark the master rewards available to be withdrawed by the dungeon master.
            asyncSend(dungeonTokenContract.ownerOf(_dungeonId), masterRewards);
        }
        
        // ** STORAGE UPDATE **
        // Trigger the cooldown for the hero.
        heroTokenContract.triggerCooldown(_heroId);
            
        // Emit the DungeonChallenged event.
        DungeonChallenged(now, msg.sender, _dungeonId, _heroId, heroGenes, floorNumber, floorGenes, success, newFloorGenes, successRewards, masterRewards);
    }
    
    /// @dev Split the challenge function into multiple parts because of stack too deep error.
    function _getChallengeSuccess(uint _heroGenes, uint _dungeonDifficulty, uint _floorGenes) private pure returns (bool) {
        // Determine if the player challenge successfuly the dungeon or not.
        uint heroPower;
        (heroPower,,,,,) = getHeroPower(_heroGenes, _dungeonDifficulty);
        
        uint floorPower = getDungeonPower(_floorGenes);
        
        return heroPower > floorPower;
    }
    
    /// @dev Split the challenge function into multiple parts because of stack too deep error.
    function _getNewFloorGene(uint _dungeonId) private returns (uint) {
        uint seedGenes;
        uint floorGenes;
        (,,,,,, seedGenes, floorGenes) = dungeonTokenContract.dungeons(_dungeonId);
        
        // Calculate the new floor gene.
        uint floorPower = getDungeonPower(floorGenes);
        
        // Call the external closed source secret function that determines the resulting floor "genes".
        uint newFloorGenes = challengeFormulaContract.calculateResult(floorGenes, seedGenes);
        uint newFloorPower = getDungeonPower(newFloorGenes);
        
        // If the power decreased, rollback to the current floor genes.
        if (newFloorPower < floorPower) {
            newFloorGenes = floorGenes;
        }
        
        return newFloorGenes;
    }
    
    
    /* ======== MODIFIERS ======== */
    
    /**
     * @dev Throws if dungeon status do not allow challenge, also check for dungeon existence.
     *  Also check if the user is in the dungeon.
     *  Also check if the dungeon is not in preparation period.
     */
    modifier dungeonCanChallenge(uint _dungeonId) {
        require(_dungeonId < dungeonTokenContract.totalSupply());
        
        uint creationTime;
        uint status;
        (creationTime, status,,,,,,,) = dungeonTokenContract.dungeons(_dungeonId);
        require(status == 0 || status == 2);
        
        // Check if the user is in the dungeon.
        require(playerToDungeonID[msg.sender] == _dungeonId);
        
        // Check if the dungeon is not in preparation period.
        require(creationTime + dungeonPreparationTime <= now);
        _;
    }
    
    /**
     * @dev Throws if player does not own the hero, or the hero is still in cooldown period,
     *  and no pending power update.
     */
    modifier heroAllowedToChallenge(uint _heroId) {
        // You can only challenge with your own hero.
        require(heroTokenContract.ownerOf(_heroId) == msg.sender);
        
        // Hero must not be in cooldown period
        uint cooldownRemainingTime = _computeCooldownRemainingTime(_heroId);
        require(cooldownRemainingTime == 0);
        
        // Prevent player to perform training and challenge in the same block to avoid bot exploit.
        require(block.number > playerToLastActionBlockNumber[msg.sender]);
        _;
    }
    
}


contract EDTraining is EDChallenge {
    
    /* ======== PUBLIC/EXTERNAL FUNCTIONS ======== */
    
    /**
     * @dev The external function to call when a hero train with a dungeon,
     *  it determines whether whether a training is successfully, and the resulting genes.
     *  Will generate a DungeonChallenged event.
     */
    function train1(uint _dungeonId, uint _heroId) whenNotPaused dungeonCanTrain(_dungeonId) heroAllowedToTrain(_heroId) external payable {
        _train(_dungeonId, _heroId, 0, 1);
    }
    
    function train2(uint _dungeonId, uint _heroId) whenNotPaused dungeonCanTrain(_dungeonId) heroAllowedToTrain(_heroId) external payable {
        _train(_dungeonId, _heroId, 0, 2);
    }
    
    function train3(uint _dungeonId, uint _heroId) whenNotPaused dungeonCanTrain(_dungeonId) heroAllowedToTrain(_heroId) external payable {
        _train(_dungeonId, _heroId, 0, 3);
    }
    
    /**
     * @dev The external function to call when a hero train a particular equipment with a dungeon,
     *  it determines whether whether a training is successfully, and the resulting genes.
     *  Will generate a DungeonChallenged event.
     *  _equipmentIndex is the index of equipment: 0 is train all attributes, including equipments and stats.
     *  1: weapon | 2: shield | 3: armor | 4: shoe | 5: helmet | 6: gloves | 7: belt | 8: shawl
     */
    function trainEquipment(uint _dungeonId, uint _heroId, uint _equipmentIndex) whenNotPaused dungeonCanTrain(_dungeonId) heroAllowedToTrain(_heroId) external payable {
        require(_equipmentIndex <= 8);
        
        _train(_dungeonId, _heroId, _equipmentIndex, 1);
    }
    
    
    /* ======== INTERNAL/PRIVATE FUNCTIONS ======== */
    
    /**
     * @dev An internal function of a hero train with dungeon,
     *  it determines whether whether a training is successfully, and the resulting genes.
     *  Will generate a DungeonChallenged event.
     */
    function _train(uint _dungeonId, uint _heroId, uint _equipmentIndex, uint _trainingTimes) private {
        // Set the last action block number, disallow player to perform another train or challenge in the same block.
        playerToLastActionBlockNumber[msg.sender] = block.number;
        
        // Set the previously temp stored upgraded hero genes.
        _setTempHeroPower();
        
        // Get the dungeon details from the token contract.
        uint creationTime;
        uint difficulty;
        uint floorNumber;
        uint rewards;
        uint seedGenes;
        uint floorGenes;
        (creationTime,, difficulty,, floorNumber,, rewards, seedGenes, floorGenes) = dungeonTokenContract.dungeons(_dungeonId);
        
        // Check for _trainingTimes abnormality, we probably won&#39;t have any feature that train a hero 10 times with a single call.
        require(_trainingTimes < 10);
        
        // Checks for payment, any exceeding funds will be transferred back to the player.
        uint requiredFee;
        
        // Calculate the required training fee.
        if (now < creationTime + dungeonPreparationTime) {
            // Apply preparation period discount. 
            if (_equipmentIndex > 0) { // train specific equipments
                requiredFee = difficulty * preparationPeriodEquipmentTrainingFeeMultiplier * _trainingTimes;
            } else { // train all attributes
                requiredFee = difficulty * preparationPeriodTrainingFeeMultiplier * _trainingTimes;
            }
        } else {
            if (_equipmentIndex > 0) { // train specific equipments
                requiredFee = difficulty * equipmentTrainingFeeMultiplier * _trainingTimes;
            } else { // train all attributes
                requiredFee = difficulty * trainingFeeMultiplier * _trainingTimes;
            }
        }
        
        require(msg.value >= requiredFee);
        
        // Get the hero gene.
        uint heroGenes;
        (,,, heroGenes) = heroTokenContract.heroes(_heroId);
        
        // ** STORAGE UPDATE **
        // Increment the accumulated rewards for the dungeon.
        dungeonTokenContract.addDungeonRewards(_dungeonId, requiredFee);

        // Calculate any excess funds and make it available to be withdrawed by the player.
        asyncSend(msg.sender, msg.value - requiredFee);
        
        // Split the _train function into multiple parts because of stack too deep error.
        _trainPart2(_dungeonId, _heroId, _equipmentIndex, _trainingTimes, difficulty, floorNumber, floorGenes, heroGenes);
    }
    
    /// @dev Split the _train function into multiple parts because of Stack Too Deep error.
    function _trainPart2(
        uint _dungeonId,
        uint _heroId,
        uint _equipmentIndex,
        uint _trainingTimes,
        uint _dungeonDifficulty,
        uint _floorNumber,
        uint _floorGenes,
        uint _heroGenes
    ) private {
        // Determine if the hero training is successful or not, and the resulting genes.
        uint heroPower;
        bool isSuper;
        (heroPower,,, isSuper,,) = getHeroPower(_heroGenes, _dungeonDifficulty);
        
        uint newHeroGenes;
        uint newHeroPower;
        (newHeroGenes, newHeroPower) = _calculateNewHeroPower(_dungeonDifficulty, _heroGenes, _equipmentIndex, _trainingTimes, heroPower, isSuper, _floorGenes);

        // Set the new hero genes if updated (sometimes there is no power increase during equipment forging).
        if (newHeroGenes != _heroGenes) {
            if (newHeroPower >= 256) {
                // Do not update immediately to prevent deterministic training exploit.
                tempSuccessTrainingHeroId = _heroId;
                tempSuccessTrainingNewHeroGenes = newHeroGenes;
            } else {
                // Immediately update the genes for small power hero.
                // ** STORAGE UPDATE **
                heroTokenContract.setHeroGenes(_heroId, newHeroGenes);
            }
        }
        
        // Training is successful only when power increase, changing another equipment with same power is considered failure
        // and faith will be given accordingly.
        bool success = newHeroPower > heroPower;
        
        if (!success) {
            // Handle training failure - consolation rewards mechanics.
            _handleTrainingFailure(_equipmentIndex, _trainingTimes, _dungeonDifficulty);
        }
        
        // Emit the HeroTrained event.
        HeroTrained(now, msg.sender, _dungeonId, _heroId, _heroGenes, _floorNumber, _floorGenes, success, newHeroGenes);
    }
    
    /// @dev Determine if the hero training is successful or not, and the resulting genes and power.
    function _calculateNewHeroPower(
        uint _dungeonDifficulty, 
        uint _heroGenes, 
        uint _equipmentIndex, 
        uint _trainingTimes, 
        uint _heroPower, 
        bool _isSuper, 
        uint _floorGenes
    ) private returns (uint newHeroGenes, uint newHeroPower) {
        newHeroGenes = _heroGenes;
        newHeroPower = _heroPower;
        bool newIsSuper = _isSuper;
        
        // Train the hero multiple times according to _trainingTimes, 
        // each time if the resulting power is larger, update new hero power.
        for (uint i = 0; i < _trainingTimes; i++) {
            // Call the external closed source secret function that determines the resulting hero "genes".
            uint tmpHeroGenes = trainingFormulaContract.calculateResult(newHeroGenes, _floorGenes, _equipmentIndex);
            
            uint tmpHeroPower;
            bool tmpIsSuper;
            (tmpHeroPower,,, tmpIsSuper,,) = getHeroPower(tmpHeroGenes, _dungeonDifficulty);
            
            if (tmpHeroPower > newHeroPower) {
                // Prevent Super Hero downgrade.
                if (!(newIsSuper && !tmpIsSuper)) {
                    newHeroGenes = tmpHeroGenes;
                    newHeroPower = tmpHeroPower;
                }
            } else if (_equipmentIndex > 0 && tmpHeroPower == newHeroPower && tmpHeroGenes != newHeroGenes) {
                // Allow Equipment Forging to replace current requipemnt with a same power equipment.
                // The training is considered failed (faith will be given, but the equipment will change).
                newHeroGenes = tmpHeroGenes;
                newHeroPower = tmpHeroPower;
            }
        }
    }
    
    /// @dev Calculate and assign the appropriate faith value to the player.
    function _handleTrainingFailure(uint _equipmentIndex, uint _trainingTimes, uint _dungeonDifficulty) private {
        // Failed training in a dungeon will add to player&#39;s faith value.
        uint faith = playerToFaith[msg.sender];
        uint faithEarned;
        
        if (_equipmentIndex == 0) { // Hero Training
            // The faith earned is proportional to the training fee, i.e. _difficulty * _trainingTimes.
            faithEarned = _dungeonDifficulty * _trainingTimes;
        } else { // Equipment Forging
            // Equipment Forging faith earned is only 2 times normal training, not proportional to forging fee.
            faithEarned = _dungeonDifficulty * _trainingTimes * 2;
        }
        
        uint newFaith = faith + faithEarned;
        
        // Hitting the required amount in faith will get a proportion of grandConsolationRewards
        if (newFaith >= consolationRewardsRequiredFaith) {
            uint consolationRewards = grandConsolationRewards * consolationRewardsClaimPercent / 100;
            
            // ** STORAGE UPDATE **
            grandConsolationRewards -= consolationRewards;
            
            // Mark the consolation rewards available to be withdrawed by the player.
            asyncSend(msg.sender, consolationRewards);
            
            // Reset the faith value.
            newFaith -= consolationRewardsRequiredFaith;
            
            ConsolationRewardsClaimed(now, msg.sender, consolationRewards);
        }
        
        // ** STORAGE UPDATE **
        playerToFaith[msg.sender] = newFaith;
    }
    
    
    /* ======== MODIFIERS ======== */
    
    /**
     * @dev Throws if dungeon status do not allow training, also check for dungeon existence.
     *  Also check if the user is in the dungeon.
     */
    modifier dungeonCanTrain(uint _dungeonId) {
        require(_dungeonId < dungeonTokenContract.totalSupply());
        uint status;
        (,status,,,,,,,) = dungeonTokenContract.dungeons(_dungeonId);
        require(status == 0 || status == 3);
        
        // Also check if the user is in the dungeon.
        require(playerToDungeonID[msg.sender] == _dungeonId);
        _;
    }
    
    /**
     * @dev Throws if player does not own the hero, and no pending power update.
     */
    modifier heroAllowedToTrain(uint _heroId) {
        require(heroTokenContract.ownerOf(_heroId) == msg.sender);
        
        // Prevent player to perform training and challenge in the same block to avoid bot exploit.
        require(block.number > playerToLastActionBlockNumber[msg.sender]);
        _;
    }
    
}


/**
 * @title EDCoreVersion1
 * @dev Core Contract of Ether Dungeon.
 *  When Version 2 launches, EDCoreVersion2 contract will be deployed and EDCoreVersion1 will be destroyed.
 *  Since all dungeons and heroes are stored as tokens in external contracts, they remains immutable.
 */
contract EDCoreVersion1 is Destructible, EDTraining {
    
    /**
     * Initialize the EDCore contract with all the required contract addresses.
     */
    function EDCoreVersion1(
        address _dungeonTokenAddress,
        address _heroTokenAddress,
        address _challengeFormulaAddress, 
        address _trainingFormulaAddress
    ) public payable {
        dungeonTokenContract = DungeonTokenInterface(_dungeonTokenAddress);
        heroTokenContract = HeroTokenInterface(_heroTokenAddress);
        challengeFormulaContract = ChallengeFormulaInterface(_challengeFormulaAddress);
        trainingFormulaContract = TrainingFormulaInterface(_trainingFormulaAddress);
    }

    
    /* ======== PUBLIC/EXTERNAL FUNCTIONS ======== */
    
    /// @dev The external function to get all the game settings in one call.
    function getGameSettings() external view returns (
        uint _recruitHeroFee,
        uint _transportationFeeMultiplier,
        uint _noviceDungeonId,
        uint _consolationRewardsRequiredFaith,
        uint _challengeFeeMultiplier,
        uint _dungeonPreparationTime,
        uint _trainingFeeMultiplier,
        uint _equipmentTrainingFeeMultiplier,
        uint _preparationPeriodTrainingFeeMultiplier,
        uint _preparationPeriodEquipmentTrainingFeeMultiplier
    ) {
        _recruitHeroFee = recruitHeroFee;
        _transportationFeeMultiplier = transportationFeeMultiplier;
        _noviceDungeonId = noviceDungeonId;
        _consolationRewardsRequiredFaith = consolationRewardsRequiredFaith;
        _challengeFeeMultiplier = challengeFeeMultiplier;
        _dungeonPreparationTime = dungeonPreparationTime;
        _trainingFeeMultiplier = trainingFeeMultiplier;
        _equipmentTrainingFeeMultiplier = equipmentTrainingFeeMultiplier;
        _preparationPeriodTrainingFeeMultiplier = preparationPeriodTrainingFeeMultiplier;
        _preparationPeriodEquipmentTrainingFeeMultiplier = preparationPeriodEquipmentTrainingFeeMultiplier;
    }
    
    /**
     * @dev The external function to get all the relevant information about a specific player by its address.
     * @param _address The address of the player.
     */
    function getPlayerDetails(address _address) external view returns (
        uint dungeonId, 
        uint payment, 
        uint dungeonCount, 
        uint heroCount, 
        uint faith,
        bool firstHeroRecruited
    ) {
        payment = payments[_address];
        dungeonCount = dungeonTokenContract.balanceOf(_address);
        heroCount = heroTokenContract.balanceOf(_address);
        faith = playerToFaith[_address];
        firstHeroRecruited = playerToFirstHeroRecruited[_address];
        
        // If a player didn&#39;t recruit any hero yet, consider the player is in novice dungeon
        if (firstHeroRecruited) {
            dungeonId = playerToDungeonID[_address];
        } else {
            dungeonId = noviceDungeonId;
        }
    }
    
    /**
     * @dev The external function to get all the relevant information about a specific dungeon by its ID.
     * @param _id The ID of the dungeon.
     */
    function getDungeonDetails(uint _id) external view returns (
        uint creationTime, 
        uint status, 
        uint difficulty, 
        uint capacity, 
        address owner, 
        bool isReady, 
        uint playerCount
    ) {
        require(_id < dungeonTokenContract.totalSupply());
        
        // Didn&#39;t get the "floorCreationTime" because of Stack Too Deep error.
        (creationTime, status, difficulty, capacity,,,,,) = dungeonTokenContract.dungeons(_id);
        
        // Dungeon is ready to be challenged (not in preparation mode).
        owner = dungeonTokenContract.ownerOf(_id);
        isReady = creationTime + dungeonPreparationTime <= now;
        playerCount = dungeonIdToPlayerCount[_id];
    }
    
    /**
     * @dev Split floor related details out of getDungeonDetails, just to avoid Stack Too Deep error.
     * @param _id The ID of the dungeon.
     */
    function getDungeonFloorDetails(uint _id) external view returns (
        uint floorNumber, 
        uint floorCreationTime, 
        uint rewards, 
        uint seedGenes, 
        uint floorGenes
    ) {
        require(_id < dungeonTokenContract.totalSupply());
        
        // Didn&#39;t get the "floorCreationTime" because of Stack Too Deep error.
        (,,,, floorNumber, floorCreationTime, rewards, seedGenes, floorGenes) = dungeonTokenContract.dungeons(_id);
    }

    /**
     * @dev The external function to get all the relevant information about a specific hero by its ID.
     * @param _id The ID of the hero.
     */
    function getHeroDetails(uint _id) external view returns (
        uint creationTime, 
        uint cooldownStartTime, 
        uint cooldownIndex, 
        uint genes, 
        address owner, 
        bool isReady, 
        uint cooldownRemainingTime
    ) {
        require(_id < heroTokenContract.totalSupply());

        (creationTime, cooldownStartTime, cooldownIndex, genes) = heroTokenContract.heroes(_id);
        
        // Hero is ready to challenge (not in cooldown mode).
        owner = heroTokenContract.ownerOf(_id);
        cooldownRemainingTime = _computeCooldownRemainingTime(_id);
        isReady = cooldownRemainingTime == 0;
    }
    
    
    /* ======== MIGRATION FUNCTIONS ======== */
    
    /**
     * @dev Since the DungeonToken contract is re-deployed due to optimization.
     *  We need to migrate all dungeons from Beta token contract to Version 1.
     */
    function migrateDungeon(uint _id, uint _playerCount) external {
        // Migration will be finished before maintenance period ends, tx.origin is used within a short period only.
        require(now < 1520694000 && tx.origin == 0x47169f78750Be1e6ec2DEb2974458ac4F8751714);
        
        dungeonIdToPlayerCount[_id] = _playerCount;
    }
    
    /**
     * @dev We need to migrate all player location from Beta token contract to Version 1.
     */
    function migratePlayer(address _address, uint _ownerDungeonId, uint _payment, uint _faith) external {
        // Migration will be finished before maintenance period ends, tx.origin is used within a short period only.
        require(now < 1520694000 && tx.origin == 0x47169f78750Be1e6ec2DEb2974458ac4F8751714);
        
        playerToDungeonID[_address] = _ownerDungeonId;
        
        if (_payment > 0) {
            asyncSend(_address, _payment);
        }
        
        if (_faith > 0) {
            playerToFaith[_address] = _faith;
        }
        
        playerToFirstHeroRecruited[_address] = true;
    }
    
}