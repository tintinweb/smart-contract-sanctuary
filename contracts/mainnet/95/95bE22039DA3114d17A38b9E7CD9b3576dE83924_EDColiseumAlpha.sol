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
 * @title Helps contracts guard agains reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b8caddd5dbd7f88a">[email&#160;protected]</a>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
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


/// @dev Core Contract of "Enter the Coliseum" game of the ED (Ether Dungeon) Platform.
contract EDColiseumAlpha is Pausable, ReentrancyGuard, Destructible {
    
    struct Participant {
        address player;
        uint heroId;
        uint heroPower;
    }
    
    /// @dev The address of the EtherDungeonCore contract.
    EDCoreInterface public edCoreContract = EDCoreInterface(0xf7eD56c1AC4d038e367a987258b86FC883b960a1);
    
    /// @dev Seed for the random number generator used for calculating fighting result.
    uint _seed;
    
    
    /* ======== SETTINGS ======== */

    /// @dev The required win count to win a jackpot.
    uint public jackpotWinCount = 3;
    
    /// @dev The percentage of jackpot a player get when reaching the jackpotWinCount.
    uint public jackpotWinPercent = 50;
    
    /// @dev The percentage of rewards a player get when being the final winner of a tournament.
    uint public winPercent = 55;
    
    /// @dev The percentage of rewards a player get when being the final loser of a tournament, remaining will add to tournamentJackpot.
    uint public losePercent = 35;
    
    /// @dev Dungeon difficulty to be used when calculating super hero power boost, 1 is no boost.
    uint public dungeonDifficulty = 1;

    /// @dev The required fee to join a participant
    uint public participationFee = 0.02 ether;
    
    /// @dev The maximum number of participants for a tournament.
    uint public constant maxParticipantCount = 8;
    
    
    /* ======== STATE VARIABLES ======== */
    
    /// @dev The next tournaments round number.
    uint public nextTournamentRound = 1;

    /// @dev The current accumulated rewards pool.
    uint public tournamentRewards;

    /// @dev The current accumulated jackpot.
    uint public tournamentJackpot = 0.2 ether;
    
    /// @dev Array of all the participant for next tournament.
    Participant[] public participants;
    
    /// @dev Array of all the participant for the previous tournament.
    Participant[] public previousParticipants;
    
    /// @dev Array to store the participant index all winners / losers for each "fighting round" of the previous tournament.
    uint[maxParticipantCount / 2] public firstRoundWinners;
    uint[maxParticipantCount / 4] public secondRoundWinners;
    uint[maxParticipantCount / 2] public firstRoundLosers;
    uint[maxParticipantCount / 4] public secondRoundLosers;
    uint public finalWinner;
    uint public finalLoser;
    
    /// @dev Mapping of hero ID to the hero&#39;s last participated tournament round to avoid repeated hero participation.
    mapping(uint => uint) public heroIdToLastRound;
    
    /// @dev Mapping of player ID to the consecutive win counts, used for calculating jackpot.
    mapping(address => uint) public playerToWinCounts;

    
    /* ======== EVENTS ======== */
    
    /// @dev The PlayerTransported event is fired when user transported to another dungeon.
    event TournamentFinished(uint timestamp, uint tournamentRound, address finalWinner, address finalLoser, uint winnerRewards, uint loserRewards, uint winCount, uint jackpotRewards);
    
    /// @dev Payable constructor to pass in the initial jackpot ethers.
    function EDColiseum() public payable {}

    
    /* ======== PUBLIC/EXTERNAL FUNCTIONS ======== */
    
    /// @dev The external function to get all the game settings in one call.
    function getGameSettings() external view returns (
        uint _jackpotWinCount,
        uint _jackpotWinPercent,
        uint _winPercent,
        uint _losePercent,
        uint _dungeonDifficulty,
        uint _participationFee,
        uint _maxParticipantCount
    ) {
        _jackpotWinCount = jackpotWinCount;
        _jackpotWinPercent = jackpotWinPercent;
        _winPercent = winPercent;
        _losePercent = losePercent;
        _dungeonDifficulty = dungeonDifficulty;
        _participationFee = participationFee;
        _maxParticipantCount = maxParticipantCount;
    }
    
    /// @dev The external function to get all the game settings in one call.
    function getNextTournamentData() external view returns (
        uint _nextTournamentRound,
        uint _tournamentRewards,
        uint _tournamentJackpot,
        uint _participantCount
    ) {
        _nextTournamentRound = nextTournamentRound;
        _tournamentRewards = tournamentRewards;
        _tournamentJackpot = tournamentJackpot;
        _participantCount = participants.length;
    }
    
    /// @dev The external function to call when joining the next tournament.
    function joinTournament(uint _heroId) whenNotPaused nonReentrant external payable {
        uint genes;
        address owner;
        (,,, genes, owner,,) = edCoreContract.getHeroDetails(_heroId);
        
        // Throws if the hero is not owned by the sender.
        require(msg.sender == owner);
        
        // Throws if the hero is already participated in the next tournament.
        require(heroIdToLastRound[_heroId] != nextTournamentRound);
        
        // Throws if participation count is full.
        require(participants.length < maxParticipantCount);
        
        // Throws if payment not enough, any exceeding funds will be transferred back to the player.
        require(msg.value >= participationFee);
        tournamentRewards += participationFee;

        if (msg.value > participationFee) {
            msg.sender.transfer(msg.value - participationFee);
        }
        
        // Set the hero participation round.
        heroIdToLastRound[_heroId] = nextTournamentRound;
        
        // Get the hero power and set it to storage.
        uint heroPower;
        (heroPower,,,,) = edCoreContract.getHeroPower(genes, dungeonDifficulty);
        
        // Throw if heroPower is 12 (novice hero).
        require(heroPower > 12);
        
        // Set the participant data to storage.
        participants.push(Participant(msg.sender, _heroId, heroPower));
    }
    
    /// @dev The onlyOwner external function to call when joining the next tournament.
    function startTournament() onlyOwner nonReentrant external {
        // Throws if participation count is not full.
        require(participants.length == maxParticipantCount);
        
        // FIGHT!
        _firstRoundFight();
        _secondRoundWinnersFight();
        _secondRoundLosersFight();
        _finalRoundWinnersFight();
        _finalRoundLosersFight();
        
        // REWARDS!
        uint winnerRewards = tournamentRewards * winPercent / 100;
        uint loserRewards = tournamentRewards * losePercent / 100;
        uint addToJackpot = tournamentRewards - winnerRewards - loserRewards;
        
        address winner = participants[finalWinner].player;
        address loser = participants[finalLoser].player;
        winner.transfer(winnerRewards);
        loser.transfer(loserRewards);
        tournamentJackpot += addToJackpot;
        
        // JACKPOT!
        playerToWinCounts[winner]++;
        
        // Reset other participants&#39; consecutive winCount.
        for (uint i = 0; i < participants.length; i++) {
            address participant = participants[i].player;
            
            if (participant != winner && playerToWinCounts[participant] != 0) {
                playerToWinCounts[participant] = 0;
            }
        }
        
        // Detemine if the winner have enough consecutive winnings for jackpot.
        uint jackpotRewards;
        uint winCount = playerToWinCounts[winner];
        if (winCount == jackpotWinCount) {
            // Reset consecutive winCount of winner.
            playerToWinCounts[winner] = 0;
            
            jackpotRewards = tournamentJackpot * jackpotWinPercent / 100;
            tournamentJackpot -= jackpotRewards;
            
            winner.transfer(jackpotRewards);
        }
        
        // Reset tournament data and increment round.
        tournamentRewards = 0;
        previousParticipants = participants;
        participants.length = 0;
        nextTournamentRound++;
        
        // Emit TournamentFinished event.
        TournamentFinished(now, nextTournamentRound - 1, winner, loser, winnerRewards, loserRewards, winCount, jackpotRewards);
    }
    
    /// @dev The onlyOwner external function to call to cancel the next tournament and refunds.
    function cancelTournament() onlyOwner nonReentrant external {
        for (uint i = 0; i < participants.length; i++) {
            address participant = participants[i].player;
            
            if (participant != 0x0) {
                participant.transfer(participationFee);
            }
        }
        
        // Reset tournament data and increment round.
        tournamentRewards = 0;
        participants.length = 0;
        nextTournamentRound++;
    }
    
    /// @dev Withdraw all Ether from the contract.
    function withdrawBalance() onlyOwner external {
        // Can only withdraw if no participants joined (i.e. call cancelTournament first.)
        require(participants.length == 0);
        
        msg.sender.transfer(this.balance);
    }

    /* ======== SETTER FUNCTIONS ======== */
    
    function setEdCoreContract(address _newEdCoreContract) onlyOwner external {
        edCoreContract = EDCoreInterface(_newEdCoreContract);
    }
    
    function setJackpotWinCount(uint _newJackpotWinCount) onlyOwner external {
        jackpotWinCount = _newJackpotWinCount;
    }
    
    function setJackpotWinPercent(uint _newJackpotWinPercent) onlyOwner external {
        jackpotWinPercent = _newJackpotWinPercent;
    }
    
    function setWinPercent(uint _newWinPercent) onlyOwner external {
        winPercent = _newWinPercent;
    }
    
    function setLosePercent(uint _newLosePercent) onlyOwner external {
        losePercent = _newLosePercent;
    }
    
    function setDungeonDifficulty(uint _newDungeonDifficulty) onlyOwner external {
        dungeonDifficulty = _newDungeonDifficulty;
    }
    
    function setParticipationFee(uint _newParticipationFee) onlyOwner external {
        participationFee = _newParticipationFee;
    }
    
    /* ======== INTERNAL/PRIVATE FUNCTIONS ======== */
    
    /// @dev Compute all winners and losers for the first round.
    function _firstRoundFight() private {
        // Get all hero powers.
        uint heroPower0 = participants[0].heroPower;
        uint heroPower1 = participants[1].heroPower;
        uint heroPower2 = participants[2].heroPower;
        uint heroPower3 = participants[3].heroPower;
        uint heroPower4 = participants[4].heroPower;
        uint heroPower5 = participants[5].heroPower;
        uint heroPower6 = participants[6].heroPower;
        uint heroPower7 = participants[7].heroPower;
        
        // Random number.
        uint rand;
        
        // 0 Vs 1
        rand = _getRandomNumber(100);
        if (
            (heroPower0 > heroPower1 && rand < 60) || 
            (heroPower0 == heroPower1 && rand < 50) ||
            (heroPower0 < heroPower1 && rand < 40)
        ) {
            firstRoundWinners[0] = 0;
            firstRoundLosers[0] = 1;
        } else {
            firstRoundWinners[0] = 1;
            firstRoundLosers[0] = 0;
        }
        
        // 2 Vs 3
        rand = _getRandomNumber(100);
        if (
            (heroPower2 > heroPower3 && rand < 60) || 
            (heroPower2 == heroPower3 && rand < 50) ||
            (heroPower2 < heroPower3 && rand < 40)
        ) {
            firstRoundWinners[1] = 2;
            firstRoundLosers[1] = 3;
        } else {
            firstRoundWinners[1] = 3;
            firstRoundLosers[1] = 2;
        }
        
        // 4 Vs 5
        rand = _getRandomNumber(100);
        if (
            (heroPower4 > heroPower5 && rand < 60) || 
            (heroPower4 == heroPower5 && rand < 50) ||
            (heroPower4 < heroPower5 && rand < 40)
        ) {
            firstRoundWinners[2] = 4;
            firstRoundLosers[2] = 5;
        } else {
            firstRoundWinners[2] = 5;
            firstRoundLosers[2] = 4;
        }
        
        // 6 Vs 7
        rand = _getRandomNumber(100);
        if (
            (heroPower6 > heroPower7 && rand < 60) || 
            (heroPower6 == heroPower7 && rand < 50) ||
            (heroPower6 < heroPower7 && rand < 40)
        ) {
            firstRoundWinners[3] = 6;
            firstRoundLosers[3] = 7;
        } else {
            firstRoundWinners[3] = 7;
            firstRoundLosers[3] = 6;
        }
    }
    
    /// @dev Compute all second winners of all first round winners.
    function _secondRoundWinnersFight() private {
        // Get all hero powers of all first round winners.
        uint winner0 = firstRoundWinners[0];
        uint winner1 = firstRoundWinners[1];
        uint winner2 = firstRoundWinners[2];
        uint winner3 = firstRoundWinners[3];
        uint heroPower0 = participants[winner0].heroPower;
        uint heroPower1 = participants[winner1].heroPower;
        uint heroPower2 = participants[winner2].heroPower;
        uint heroPower3 = participants[winner3].heroPower;
        
        // Random number.
        uint rand;
        
        // 0 Vs 1
        rand = _getRandomNumber(100);
        if (
            (heroPower0 > heroPower1 && rand < 60) || 
            (heroPower0 == heroPower1 && rand < 50) ||
            (heroPower0 < heroPower1 && rand < 40)
        ) {
            secondRoundWinners[0] = winner0;
        } else {
            secondRoundWinners[0] = winner1;
        }
        
        // 2 Vs 3
        rand = _getRandomNumber(100);
        if (
            (heroPower2 > heroPower3 && rand < 60) || 
            (heroPower2 == heroPower3 && rand < 50) ||
            (heroPower2 < heroPower3 && rand < 40)
        ) {
            secondRoundWinners[1] = winner2;
        } else {
            secondRoundWinners[1] = winner3;
        }
    }
    
    /// @dev Compute all second losers of all first round losers.
    function _secondRoundLosersFight() private {
        // Get all hero powers of all first round losers.
        uint loser0 = firstRoundLosers[0];
        uint loser1 = firstRoundLosers[1];
        uint loser2 = firstRoundLosers[2];
        uint loser3 = firstRoundLosers[3];
        uint heroPower0 = participants[loser0].heroPower;
        uint heroPower1 = participants[loser1].heroPower;
        uint heroPower2 = participants[loser2].heroPower;
        uint heroPower3 = participants[loser3].heroPower;
        
        // Random number.
        uint rand;
        
        // 0 Vs 1
        rand = _getRandomNumber(100);
        if (
            (heroPower0 > heroPower1 && rand < 60) || 
            (heroPower0 == heroPower1 && rand < 50) ||
            (heroPower0 < heroPower1 && rand < 40)
        ) {
            secondRoundLosers[0] = loser1;
        } else {
            secondRoundLosers[0] = loser0;
        }
        
        // 2 Vs 3
        rand = _getRandomNumber(100);
        if (
            (heroPower2 > heroPower3 && rand < 60) || 
            (heroPower2 == heroPower3 && rand < 50) ||
            (heroPower2 < heroPower3 && rand < 40)
        ) {
            secondRoundLosers[1] = loser3;
        } else {
            secondRoundLosers[1] = loser2;
        }
    }
    
    /// @dev Compute the final winner.
    function _finalRoundWinnersFight() private {
        // Get all hero powers of all first round winners.
        uint winner0 = secondRoundWinners[0];
        uint winner1 = secondRoundWinners[1];
        uint heroPower0 = participants[winner0].heroPower;
        uint heroPower1 = participants[winner1].heroPower;
        
        // Random number.
        uint rand;
        
        // 0 Vs 1
        rand = _getRandomNumber(100);
        if (
            (heroPower0 > heroPower1 && rand < 60) || 
            (heroPower0 == heroPower1 && rand < 50) ||
            (heroPower0 < heroPower1 && rand < 40)
        ) {
            finalWinner = winner0;
        } else {
            finalWinner = winner1;
        }
    }
    
    /// @dev Compute the final loser.
    function _finalRoundLosersFight() private {
        // Get all hero powers of all first round winners.
        uint loser0 = secondRoundLosers[0];
        uint loser1 = secondRoundLosers[1];
        uint heroPower0 = participants[loser0].heroPower;
        uint heroPower1 = participants[loser1].heroPower;
        
        // Random number.
        uint rand;
        
        // 0 Vs 1
        rand = _getRandomNumber(100);
        if (
            (heroPower0 > heroPower1 && rand < 60) || 
            (heroPower0 == heroPower1 && rand < 50) ||
            (heroPower0 < heroPower1 && rand < 40)
        ) {
            finalLoser = loser1;
        } else {
            finalLoser = loser0;
        }
    }
    
    // @dev Return a pseudo random uint smaller than lower bounds.
    function _getRandomNumber(uint _upper) private returns (uint) {
        _seed = uint(keccak256(
            _seed,
            block.blockhash(block.number - 1),
            block.coinbase,
            block.difficulty
        ));
        
        return _seed % _upper;
    }

}