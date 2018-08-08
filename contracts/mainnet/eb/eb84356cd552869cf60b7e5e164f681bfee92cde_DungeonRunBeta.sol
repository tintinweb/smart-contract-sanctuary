pragma solidity 0.4.19;

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


/// @dev Interface to the Core Contract of Ether Dungeon.
contract EDCoreInterface {

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
    );

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
    );

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
    );

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
    );

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
    );

    /// @dev Get the attributes (equipments + stats) of a hero from its gene.
    function getHeroAttributes(uint _genes) public pure returns (uint[]);

    /// @dev Calculate the power of a hero from its gene, it calculates the equipment power, stats power, and super hero boost.
    function getHeroPower(uint _genes, uint _dungeonDifficulty) public pure returns (
        uint totalPower,
        uint equipmentPower,
        uint statsPower,
        bool isSuper,
        uint superRank,
        uint superBoost
    );

    /// @dev Calculate the power of a dungeon floor.
    function getDungeonPower(uint _genes) public pure returns (uint);

    /**
     * @dev Calculate the sum of top 5 heroes power a player owns.
     *  The gas usage increased with the number of heroes a player owned, roughly 500 x hero count.
     *  This is used in transport function only to calculate the required tranport fee.
     */
    function calculateTop5HeroesPower(address _address, uint _dungeonId) public view returns (uint);

}


/**
 * @title Core Contract of "Dungeon Run" event game of the ED (Ether Dungeon) Platform.
 * @dev Dungeon Run is a single-player game mode added to the Ether Dungeon platform.
 *  The objective of Dungeon Run is to defeat as many monsters as possible.
 */
contract DungeonRunBeta is Pausable, Destructible {

    /*=================================
    =             STRUCTS             =
    =================================*/

    struct Monster {
        uint64 creationTime;
        uint8 level;
        uint16 initialHealth;
        uint16 health;
    }


    /*=================================
    =            CONTRACTS            =
    =================================*/

    /// @dev The address of the EtherDungeonCore contract.
    EDCoreInterface public edCoreContract = EDCoreInterface(0xf7eD56c1AC4d038e367a987258b86FC883b960a1);


    /*=================================
    =            CONSTANTS            =
    =================================*/

    /// @dev By defeating the checkPointLevel, half of the entranceFee is refunded.
    uint8 public constant checkpointLevel = 4;

    /// @dev By defeating the breakevenLevel, another half of the entranceFee is refunded.
    uint8 public constant breakevenLevel = 8;

    /// @dev By defeating the jackpotLevel, the player win the entire jackpot.
    uint8 public constant jackpotLevel = 12;

    /// @dev Dungeon difficulty to be used when calculating super hero power boost, 3 is 64 power boost.
    uint public constant dungeonDifficulty = 3;

    /// @dev The health of a monster is level * monsterHealth;
    uint16 public monsterHealth = 10;

    /// @dev When a monster flees, the hero health is reduced by monster level + monsterStrength.
    uint public monsterStrength = 4;

    /// @dev After a certain period of time, the monster will attack the hero and flee.
    uint64 public monsterFleeTime = 8 minutes;


    /*=================================
    =            SETTINGS             =
    =================================*/

    /// @dev To start a run, a player need to pay an entrance fee.
    uint public entranceFee = 0.04 ether;

    /// @dev 0.1 ether is provided as the initial jackpot.
    uint public jackpot = 0.1 ether;

    /**
     * @dev The dungeon run entrance fee will first be deposited to a pool first, when the hero is
     *  defeated by a monster, then the fee will be added to the jackpot.
     */
    uint public entranceFeePool;

    /// @dev Private seed for the PRNG used for calculating damage amount.
    uint _seed;


    /*=================================
    =         STATE VARIABLES         =
    =================================*/

    /// @dev A mapping from hero ID to the current run monster, a 0 value indicates no current run.
    mapping(uint => Monster) public heroIdToMonster;

    /// @dev A mapping from hero ID to its current health.
    mapping(uint => uint) public heroIdToHealth;

    /// @dev A mapping from hero ID to the refunded fee.
    mapping(uint => uint) public heroIdToRefundedFee;


    /*==============================
    =            EVENTS            =
    ==============================*/

    /// @dev The LogAttack event is fired whenever a hero attack a monster.
    event LogAttack(uint timestamp, address indexed player, uint indexed heroId, uint indexed monsterLevel, uint damageByHero, uint damageByMonster, bool isMonsterDefeated, uint rewards);

    function DungeonRunAlpha() public payable {}

    /*=======================================
    =       PUBLIC/EXTERNAL FUNCTIONS       =
    =======================================*/

    /// @dev The external function to get all the game settings in one call.
    function getGameSettings() external view returns (
        uint _checkpointLevel,
        uint _breakevenLevel,
        uint _jackpotLevel,
        uint _dungeonDifficulty,
        uint _monsterHealth,
        uint _monsterStrength,
        uint _monsterFleeTime,
        uint _entranceFee
    ) {
        _checkpointLevel = checkpointLevel;
        _breakevenLevel = breakevenLevel;
        _jackpotLevel = jackpotLevel;
        _dungeonDifficulty = dungeonDifficulty;
        _monsterHealth = monsterHealth;
        _monsterStrength = monsterStrength;
        _monsterFleeTime = monsterFleeTime;
        _entranceFee = entranceFee;
    }

    /// @dev The external function to get the dungeon run details in one call.
    function getRunDetails(uint _heroId) external view returns (
        uint _heroPower,
        uint _heroStrength,
        uint _heroInitialHealth,
        uint _heroHealth,
        uint _monsterCreationTime,
        uint _monsterLevel,
        uint _monsterInitialHealth,
        uint _monsterHealth,
        uint _gameState // 0: NotStarted | 1: NewMonster | 2: Active | 3: RunEnded
    ) {
        uint genes;
        address owner;
        (,,, genes, owner,,) = edCoreContract.getHeroDetails(_heroId);
        (_heroPower,,,,) = edCoreContract.getHeroPower(genes, dungeonDifficulty);
        _heroStrength = (genes / (32 ** 8)) % 32 + 1;
        _heroInitialHealth = (genes / (32 ** 12)) % 32 + 1;
        _heroHealth = heroIdToHealth[_heroId];

        Monster memory monster = heroIdToMonster[_heroId];
        _monsterCreationTime = monster.creationTime;

        // Dungeon run is ended if either hero is defeated (health exhausted),
        // or hero failed to damage a monster before it flee.
        bool _dungeonRunEnded = monster.level > 0 && (
            _heroHealth == 0 ||
            now > _monsterCreationTime + monsterFleeTime * 2 ||
            (monster.health == monster.initialHealth && now > monster.creationTime + monsterFleeTime)
        );

        // Calculate hero and monster stats based on different game state.
        if (monster.level == 0) {
            // Dungeon run not started yet.
            _heroHealth = _heroInitialHealth;
            _monsterLevel = 1;
            _monsterInitialHealth = monsterHealth;
            _monsterHealth = _monsterInitialHealth;
            _gameState = 0;
        } else if (_dungeonRunEnded) {
            // Dungeon run ended.
            _monsterLevel = monster.level;
            _monsterInitialHealth = monster.initialHealth;
            _monsterHealth = monster.health;
            _gameState = 3;
        } else if (now > _monsterCreationTime + monsterFleeTime) {
            // Previous monster just fled, new monster awaiting.
            if (monster.level + monsterStrength > _heroHealth) {
                _heroHealth = 0;
                _monsterLevel = monster.level;
                _monsterInitialHealth = monster.initialHealth;
                _monsterHealth = monster.health;
                _gameState = 2;
            } else {
                _heroHealth -= monster.level + monsterStrength;
                _monsterCreationTime += monsterFleeTime;
                _monsterLevel = monster.level + 1;
                _monsterInitialHealth = _monsterLevel * monsterHealth;
                _monsterHealth = _monsterInitialHealth;
                _gameState = 1;
            }
        } else {
            // Active monster.
            _monsterLevel = monster.level;
            _monsterInitialHealth = monster.initialHealth;
            _monsterHealth = monster.health;
            _gameState = 2;
        }
    }

    /**
     * @dev To start a dungeon run, player need to call the attack function with an entranceFee.
     *  Future attcks required no fee, player just need to send a free transaction
     *  to the contract, before the monster flee. The lower the gas price, the larger the damage.
     *  This function is prevented from being called by a contract, using the onlyHumanAddress modifier.
     *  Note that each hero can only perform one dungeon run.
     */
    function attack(uint _heroId) whenNotPaused onlyHumanAddress external payable {
        uint genes;
        address owner;
        (,,, genes, owner,,) = edCoreContract.getHeroDetails(_heroId);

        // Throws if the hero is not owned by the player.
        require(msg.sender == owner);

        // Get the health and strength of the hero.
        uint heroInitialHealth = (genes / (32 ** 12)) % 32 + 1;
        uint heroStrength = (genes / (32 ** 8)) % 32 + 1;

        // Get the current monster and hero current health.
        Monster memory monster = heroIdToMonster[_heroId];
        uint currentLevel = monster.level;
        uint heroCurrentHealth = heroIdToHealth[_heroId];

        // A flag determine whether the dungeon run has ended.
        bool dungeonRunEnded;

        // To start a run, the player need to pay an entrance fee.
        if (currentLevel == 0) {
            // Throws if not enough fee, and any exceeding fee will be transferred back to the player.
            require(msg.value >= entranceFee);
            entranceFeePool += entranceFee;

            // Create level 1 monster, initial health is 1 * monsterHealth.
            heroIdToMonster[_heroId] = Monster(uint64(now), 1, monsterHealth, monsterHealth);
            monster = heroIdToMonster[_heroId];

            // Set the hero initial health to storage.
            heroIdToHealth[_heroId] = heroInitialHealth;
            heroCurrentHealth = heroInitialHealth;

            // Refund exceeding fee.
            if (msg.value > entranceFee) {
                msg.sender.transfer(msg.value - entranceFee);
            }
        } else {
            // If the hero health is 0, the dungeon run has ends.
            require(heroCurrentHealth > 0);

            // If a hero failed to damage a monster before it flee, the dungeon run ends,
            // regardless of the remaining hero health.
            dungeonRunEnded = now > monster.creationTime + monsterFleeTime * 2 ||
                (monster.health == monster.initialHealth && now > monster.creationTime + monsterFleeTime);

            if (dungeonRunEnded) {
                // Add the non-refunded fee to jackpot.
                uint addToJackpot = entranceFee - heroIdToRefundedFee[_heroId];
                jackpot += addToJackpot;
                entranceFeePool -= addToJackpot;

                // Sanity check.
                assert(addToJackpot <= entranceFee);
            }

            // Future attack do not require any fee, so refund all ether sent with the transaction.
            msg.sender.transfer(msg.value);
        }

        if (!dungeonRunEnded) {
            // All pre-conditions passed, call the internal attack function.
            _attack(_heroId, genes, heroStrength, heroCurrentHealth);
        }
    }


    /*=======================================
    =           SETTER FUNCTIONS            =
    =======================================*/

    function setEdCoreContract(address _newEdCoreContract) onlyOwner external {
        edCoreContract = EDCoreInterface(_newEdCoreContract);
    }

    function setEntranceFee(uint _newEntranceFee) onlyOwner external {
        entranceFee = _newEntranceFee;
    }


    /*=======================================
    =      INTERNAL/PRIVATE FUNCTIONS       =
    =======================================*/

    /// @dev Internal function of attack, assume all parameter checking is done.
    function _attack(uint _heroId, uint _genes, uint _heroStrength, uint _heroCurrentHealth) internal {
        Monster storage monster = heroIdToMonster[_heroId];
        uint8 currentLevel = monster.level;

        // Get the hero power.
        uint heroPower;
        (heroPower,,,,) = edCoreContract.getHeroPower(_genes, dungeonDifficulty);

        // Calculate the damage by monster.
        uint damageByMonster;

        // Determine if the monster has fled due to hero failed to attack within flee period.
        if (now > monster.creationTime + monsterFleeTime) {
            // When a monster flees, the monster will attack the hero and flee.
            // The damage is calculated by monster level + monsterStrength.
            damageByMonster = currentLevel + monsterStrength;
        } else {
            // When a monster attack back the hero, the damage will be less than monster level / 2.
            if (currentLevel >= 2) {
                damageByMonster = _getRandomNumber(currentLevel / 2);
            }
        }

        // Check if hero is defeated.
        if (damageByMonster >= _heroCurrentHealth) {
            // Hero is defeated, the dungeon run ends.
            heroIdToHealth[_heroId] = 0;

            // Added the non-refunded fee to jackpot.
            uint addToJackpot = entranceFee - heroIdToRefundedFee[_heroId];
            jackpot += addToJackpot;
            entranceFeePool -= addToJackpot;

            // Sanity check.
            assert(addToJackpot <= entranceFee);
        } else {
            // Hero is damanged but didn&#39;t defeated, game continues with a new monster.
            heroIdToHealth[_heroId] -= damageByMonster;

            // Create next level monster, the health of a monster is level * monsterHealth.
            currentLevel++;
            heroIdToMonster[_heroId] = Monster(uint64(monster.creationTime + monsterFleeTime),
                currentLevel, currentLevel * monsterHealth, currentLevel * monsterHealth);
            monster = heroIdToMonster[_heroId];
        }

        // The damage formula is [[strength / gas + power / (10 * rand)]],
        // where rand is a random integer from 1 to 5.
        uint damageByHero = (_heroStrength + heroPower / (10 * (1 + _getRandomNumber(5)))) / tx.gasprice / 1e9;
        bool isMonsterDefeated = damageByHero >= monster.health;
        uint rewards;

        if (isMonsterDefeated) {
            // Monster is defeated, game continues with a new monster.
            // Create next level monster, the health of a monster is level * monsterHealth.
            uint8 newLevel = currentLevel + 1;
            heroIdToMonster[_heroId] = Monster(uint64(now), newLevel, newLevel * monsterHealth, newLevel * monsterHealth);
            monster = heroIdToMonster[_heroId];

            // Determine the rewards based on current level.
            if (currentLevel == checkpointLevel) {
                // By defeating the checkPointLevel, half of the entranceFee is refunded.
                rewards = entranceFee / 2;
                heroIdToRefundedFee[_heroId] += rewards;
                entranceFeePool -= rewards;
            } else if (currentLevel == breakevenLevel) {
                // By defeating the breakevenLevel, another half of the entranceFee is refunded.
                rewards = entranceFee / 2;
                heroIdToRefundedFee[_heroId] += rewards;
                entranceFeePool -= rewards;
            } else if (currentLevel == jackpotLevel) {
                // By defeating the jackpotLevel, the player win the entire jackpot.
                rewards = jackpot / 2;
                jackpot -= rewards;
            }

            msg.sender.transfer(rewards);
        } else {
            // Monster is damanged but not defeated, hurry up!
            monster.health -= uint8(damageByHero);
        }

        // Emit LogAttack event.
        LogAttack(now, msg.sender, _heroId, currentLevel, damageByHero, damageByMonster, isMonsterDefeated, rewards);
    }

    /// @dev Return a pseudo random uint smaller than _upper bounds.
    function _getRandomNumber(uint _upper) private returns (uint) {
        _seed = uint(keccak256(
            _seed,
            block.blockhash(block.number - 1),
            block.coinbase,
            block.difficulty
        ));

        return _seed % _upper;
    }


    /*==============================
    =           MODIFIERS          =
    ==============================*/

    /// @dev Throws if the caller address is a contract.
    modifier onlyHumanAddress() {
        address addr = msg.sender;
        uint size;
        assembly { size := extcodesize(addr) }
        require(size == 0);
        _;
    }

}