/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

// Global Enums and Structs



struct MinigamePlayer {
    bool isInGame;

    // Will add more as needed
}
struct Hero {
    bool valid;
    string name;
    string affinity;
    int256 affinityPrice;
    uint256 roundMinted;
    uint256 elderId;
    uint256 raceId;
    uint256 classId;
    uint8 appearance;
    uint8 trait1;
    uint8 trait2;
    uint8 skill1;
    uint8 skill2;
    uint8 alignment;
    uint8 background;
    uint8 hometown;
    uint8 weather;
    uint8 level;
    uint8 hp;
    uint8 mana;
    uint8 stamina;
    uint8 strength;
    uint8 dexterity;
    uint8 constitution;
    uint8 intelligence;
    uint8 wisdom;
    uint8 charisma;
}
struct ElderSpirit {
    bool valid;
    uint256 raceId;
    uint256 classId;
    string affinity;
    int256 affinityPrice;
}

// Part: ICryptoChampions

interface ICryptoChampions {
    function createAffinity(string calldata tokenTicker, address feedAddress) external;

    function setElderMintPrice(uint256 price) external;

    function setTokenURI(uint256 id, string calldata uri) external;

    function mintElderSpirit(
        uint256 raceId,
        uint256 classId,
        string calldata affinity
    ) external payable returns (uint256);

    function getElderOwner(uint256 elderId) external view returns (address);

    function mintHero(uint256 elderId, string memory heroName) external payable returns (uint256);

    function getHeroOwner(uint256 heroId) external view returns (address);

    function getElderSpirit(uint256 elderId)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            string memory,
            int256
        );

    function getHeroGameData(uint256 heroId)
        external
        view
        returns (
            bool, // valid
            string memory, // affinity
            int256, // affinity price
            uint256, // round minted
            uint256 // elder id
        );

    function getHeroVisuals(uint256 heroId)
        external
        view
        returns (
            string memory, // name
            uint256, // race id
            uint256, // class id
            uint8 // appearance
        );

    function getHeroTraitsSkills(uint256 heroId)
        external
        view
        returns (
            uint8, // trait 1
            uint8, // trait 2
            uint8, // skill 1
            uint8 // skill 2
        );

    function getHeroLore(uint256 heroId)
        external
        view
        returns (
            uint8, // alignment
            uint8, // background
            uint8, // hometown
            uint8 // weather
        );

    function getHeroVitals(uint256 heroId)
        external
        view
        returns (
            uint8, // level
            uint8, // hp
            uint8, // mana
            uint8 // stamina
        );

    function getHeroStats(uint256 heroId)
        external
        view
        returns (
            uint8, // strength
            uint8, // dexterity
            uint8, // constitution
            uint8, // intelligence
            uint8, // wisdom
            uint8 // charisma
        );

    function getHeroMintPrice(uint256 round, uint256 elderId) external view returns (uint256);

    function getElderSpawnsAmount(uint256 round, uint256 elderId) external view returns (uint256);

    function getAffinityFeedAddress(string calldata affinity) external view returns (address);

    function declareRoundWinner(string calldata winningAffinity) external;

    function claimReward(uint256 heroId) external;

    function getNumEldersInGame() external view returns (uint256);

    function transferInGameTokens(address to, uint256 amount) external;

    function delegatedTransferInGameTokens(
        address from,
        address to,
        uint256 amount
    ) external;

    function refreshPhase() external;
}

// Part: OpenZeppelin/[email protected]/SignedSafeMath

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// Part: Minigame

/// @title Minigame
/// @author cds95
/// @notice This is contract for a minigame
abstract contract Minigame {
    // Possible game phases
    enum MinigamePhase { OPEN, CLOSED }

    // The current game's phase
    MinigamePhase public currentPhase;

    // Map of hero ids to player struct
    mapping(uint256 => MinigamePlayer) public players;

    // List of hero IDs in the game
    uint256[] public heroIds;

    // Number of players currently in the game
    uint256 public numPlayers;

    // Name of the game
    string public gameName;

    // Reference to crypto champions contract
    ICryptoChampions public cryptoChampions;

    // Event to signal that a game has started
    event GameStarted();

    // Event to signal that a game has ended
    event GameEnded();

    // Initializes a new minigame
    /// @param nameOfGame The minigame's name
    /// @param cryptoChampionsAddress The address of the cryptoChampions contract
    constructor(string memory nameOfGame, address cryptoChampionsAddress) public {
        gameName = nameOfGame;
        currentPhase = MinigamePhase.OPEN;
        cryptoChampions = ICryptoChampions(cryptoChampionsAddress);
    }

    /// @notice Joins a game
    /// @param heroId The id of the joining player's hero
    function joinGame(uint256 heroId) public virtual {
        require(currentPhase == MinigamePhase.OPEN);
        MinigamePlayer memory player;
        player.isInGame = true;
        players[heroId] = player;
        heroIds.push(heroId);
        numPlayers++;
    }

    /// @notice Leaves a game
    /// @param heroId The id of the leaving player's hero
    function leaveGame(uint256 heroId) public virtual {
        require(currentPhase == MinigamePhase.OPEN);
        MinigamePlayer storage player = players[heroId];
        player.isInGame = false;
        numPlayers--;
    }

    /// @notice Starts a new game and closes it when it's finished
    function startGame() external {
        require(currentPhase == MinigamePhase.OPEN);
        emit GameStarted();
        play();
        setPhase(MinigamePhase.CLOSED);
        emit GameEnded();
    }

    /// @notice Sets the current game's phase
    /// @param phase The phase the game should be set to
    function setPhase(MinigamePhase phase) internal {
        currentPhase = phase;
    }

    /// @notice Gets the number of players in the game
    function getNumPlayers() public view returns (uint256) {
        return numPlayers;
    }

    /// @notice Handler function to execute game logic.  This should be implemented by the concrete class.
    function play() internal virtual;
}

// Part: PriceWars

/// @title PriceWars
/// @author cds95
/// @notice This is the contract for the price wars minigame
contract PriceWars is Minigame {
    using SignedSafeMath for int256;

    // Initializes a new price war minigame
    constructor(address cryptoChampionsContractAddress) public Minigame("price-wars", cryptoChampionsContractAddress) {}

    /// @notice Executes one round of a price war minigame by determining the affinity with the token that had the greatest gain.
    function play() internal override {
        string memory winningAffinity;
        int256 greatestPercentageChange;
        for (uint256 elderId = 1; elderId <= cryptoChampions.getNumEldersInGame(); elderId++) {
            string memory affinity;
            int256 startAffinityPrice;
            (, , , affinity, startAffinityPrice) = cryptoChampions.getElderSpirit(elderId);
            int256 percentageChange = determinePercentageChange(startAffinityPrice, affinity);
            if (percentageChange > greatestPercentageChange || greatestPercentageChange == 0) {
                greatestPercentageChange = percentageChange;
                winningAffinity = affinity;
            }
        }
        cryptoChampions.declareRoundWinner(winningAffinity);
    }

    /// @notice Determines the percentage change of a token.
    /// @return The token's percentage change.
    function determinePercentageChange(int256 startAffinityPrice, string memory affinity)
        internal
        view
        returns (int256)
    {
        address feedAddress = cryptoChampions.getAffinityFeedAddress(affinity);
        int256 currentAffinityPrice;
        (, currentAffinityPrice, , , ) = AggregatorV3Interface(feedAddress).latestRoundData();
        int256 absoluteChange = currentAffinityPrice.sub(startAffinityPrice);
        return absoluteChange.mul(100).div(startAffinityPrice);
    }
}

// File: PriceWarsFactory.sol

/// @title PriceWarsFactory
/// @author cds95
/// @notice This is the price wars factory contract to manage creating new price war contracts
contract PriceWarsFactory {
    // List of price war contracts that have been deployed
    PriceWars[] public games;

    /// @notice Triggered when a new price war contract is created
    event PriceWarCreated();

    /// @notice Creates a new price war game contract
    /// @param cryptoChampionsContractAddress The address of the crypto champions contract
    function createPriceWar(address cryptoChampionsContractAddress) external returns (PriceWars) {
        // TODO:  Look into clone factories to save gas
        PriceWars game = new PriceWars(cryptoChampionsContractAddress);
        games.push(game);
        emit PriceWarCreated();
        return game;
    }
}