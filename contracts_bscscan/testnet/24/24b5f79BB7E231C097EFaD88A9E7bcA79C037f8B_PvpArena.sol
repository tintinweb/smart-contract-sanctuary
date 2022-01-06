pragma solidity ^0.6.0;
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interfaces/IRandoms.sol";
import "./cryptoblades.sol";
import "./characters.sol";
import "./weapons.sol";
import "./shields.sol";

contract PvpArena is Initializable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint8;
    using SafeMath for uint24;
    using SafeMath for uint256;
    using ABDKMath64x64 for int128;
    using SafeERC20 for IERC20;

    struct Fighter {
        uint256 characterID;
        uint256 weaponID;
        uint256 shieldID;
        uint256 wager;
        bool useShield;
    }

    struct Match {
        uint256 attackerID;
        uint256 defenderID;
        uint256 createdAt;
    }

    struct BountyDistribution {
        uint256 winnerReward;
        uint256 loserPayment;
        uint256 rankingPoolTax;
    }

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CryptoBlades public game;
    Characters public characters;
    Weapons public weapons;
    Shields public shields;
    IERC20 public skillToken;
    IRandoms public randoms;

    /// @dev the base amount wagered per duel in dollars
    int128 private _baseWagerUSD;
    /// @dev how much extra USD is wagered per level tier
    int128 private _tierWagerUSD;
    /// @dev how much of a duel's bounty is sent to the rankings pool
    uint8 private _rankingsPoolTaxPercent;
    /// @dev how many times the cost of battling must be wagered to enter the arena
    uint8 public wageringFactor;
    /// @dev amount of points earned by winning a duel
    uint8 public winningPoints;
    /// @dev amount of points subtracted by losing duel
    uint8 public losingPoints;
    /// @dev max amount of top characters by tier
    uint8 private _maxTopCharactersPerTier;
    /// @dev percentage of duel cost charged when rerolling opponent
    uint256 public reRollFeePercent;
    /// @dev percentage of entry wager charged when withdrawing from arena with pending duel
    uint256 public withdrawFeePercent;
    /// @dev current ranked season
    uint256 public currentRankedSeason;
    /// @dev timestamp of when the current season started
    uint256 public seasonStartedAt;
    /// @dev interval of ranked season restarts
    uint256 public seasonDuration;
    /// @dev amount of time a match finder has to make a decision
    uint256 public decisionSeconds;
    /// @dev amount of skill due for game coffers from tax
    uint256 public gameCofferTaxDue;
    /// @dev allows or blocks entering arena (we can extend later to disable other parts such as rerolls)
    uint256 public arenaAccess; // 0 = cannot join, 1 = can join
    /// @dev percentages of ranked prize distribution by fighter rank (represented as index)
    uint256[] public prizePercentages;
    /// @dev characters by id that are on queue to perform a duel
    EnumerableSet.UintSet private _duelQueue;

    /// @dev Fighter by characterID
    mapping(uint256 => Fighter) public fighterByCharacter;
    /// @dev Active match by characterID of the finder
    mapping(uint256 => Match) public matchByFinder;
    /// @dev if character is currently in the arena
    mapping(uint256 => bool) public isCharacterInArena;
    /// @dev if weapon is currently in the arena
    mapping(uint256 => bool) public isWeaponInArena;
    /// @dev if shield is currently in the arena
    mapping(uint256 => bool) public isShieldInArena;
    /// @dev if defender is in a duel that has not finished processing
    mapping(uint256 => bool) public isDefending;
    /// @dev if a character is someone else's opponent
    mapping(uint256 => uint256) public finderByOpponent;
    /// @dev character's tier when it last entered arena. Used to reset rank if it changes
    mapping(uint256 => uint8) public previousTierByCharacter;
    /// @dev excess wager by character for when they re-enter the arena
    mapping(uint256 => uint256) public excessWagerByCharacter;
    /// @dev season number associated to character
    mapping(uint256 => uint256) public seasonByCharacter;
    /// @dev ranking points by character
    mapping(uint256 => uint256) public rankingPointsByCharacter;
    /// @dev accumulated skill pool per tier
    mapping(uint8 => uint256) public rankingsPoolByTier;
    /// @dev funds available for withdrawal by address
    mapping(address => uint256) private _rankingRewardsByPlayer;
    /// @dev top ranking characters by tier
    mapping(uint8 => uint256[]) private _topRankingCharactersByTier;
    /// @dev IDs of characters available for matchmaking by tier
    mapping(uint8 => EnumerableSet.UintSet) private _matchableCharactersByTier;

    // Note: we might want the NewDuel (NewMatch) event
    
    event DuelFinished(
        uint256 indexed attacker,
        uint256 indexed defender,
        uint256 timestamp,
        uint256 attackerRoll,
        uint256 defenderRoll,
        bool attackerWon
    );

    modifier characterInArena(uint256 characterID) {
        _characterInArena(characterID);
        _;
    }

    function _characterInArena(uint256 characterID) internal view {
        require(isCharacterInArena[characterID], "Char not in arena");
    }

    modifier characterWithinDecisionTime(uint256 characterID) {
        _characterWithinDecisionTime(characterID);
        _;
    }

    function _characterWithinDecisionTime(uint256 characterID) internal view {
        require(
            isCharacterWithinDecisionTime(characterID),
            "Decision time expired"
        );
    }

    modifier characterNotUnderAttack(uint256 characterID) {
        _characterNotUnderAttack(characterID);
        _;
    }

    function _characterNotUnderAttack(uint256 characterID) internal view {
        require(isCharacterNotUnderAttack(characterID), "Under attack");
    }

    modifier isOwnedCharacter(uint256 characterID) {
        require(characters.ownerOf(characterID) == msg.sender);
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not admin");
    }

    modifier enteringArenaChecks(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield
    ) {
        require(
            characters.ownerOf(characterID) == msg.sender &&
                weapons.ownerOf(weaponID) == msg.sender
        );

        require(characters.getNftVar(characterID, 1) == 0, "Char busy");
        require(weapons.getNftVar(weaponID, 1) == 0, "Wpn busy");

        if (useShield) {
            require(shields.ownerOf(shieldID) == msg.sender);
            require(shields.getNftVar(shieldID, 1) == 0, "Shld busy");
        }

        require((arenaAccess & 1) == 1, "Arena locked");
        _;
    }

    function initialize(
        address gameContract,
        address shieldsContract,
        address randomsContract
    ) public initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        game = CryptoBlades(gameContract);
        characters = Characters(game.characters());
        weapons = Weapons(game.weapons());
        shields = Shields(shieldsContract);
        skillToken = IERC20(game.skillToken());
        randoms = IRandoms(randomsContract);

        // TODO: Tweak these values
        _baseWagerUSD = ABDKMath64x64.divu(500, 100); // $5
        _tierWagerUSD = ABDKMath64x64.divu(50, 100); // $0.5
        _rankingsPoolTaxPercent = 15;
        wageringFactor = 3;
        winningPoints = 5;
        losingPoints = 3;
        _maxTopCharactersPerTier = 4;
        reRollFeePercent = 25;
        withdrawFeePercent = 25;
        currentRankedSeason = 1;
        seasonStartedAt = block.timestamp;
        seasonDuration = 1 days;
        decisionSeconds = 2 minutes;
        prizePercentages.push(60);
        prizePercentages.push(30);
        prizePercentages.push(10);
    }

    /// @dev enter the arena with a character, a weapon and optionally a shield
    function enterArena(
        uint256 characterID,
        uint256 weaponID,
        uint256 shieldID,
        bool useShield
    ) external enteringArenaChecks(characterID, weaponID, shieldID, useShield) {
        uint256 wager = getEntryWager(characterID);
        uint8 tier = getArenaTier(characterID);

        if (previousTierByCharacter[characterID] != getArenaTier(characterID)) {
            rankingPointsByCharacter[characterID] = 0;
        }

        if (
            _topRankingCharactersByTier[tier].length <
            _maxTopCharactersPerTier &&
            seasonByCharacter[characterID] != currentRankedSeason
        ) {
            _topRankingCharactersByTier[tier].push(characterID);
        }

        if (seasonByCharacter[characterID] != currentRankedSeason) {
            rankingPointsByCharacter[characterID] = 0;
            seasonByCharacter[characterID] = currentRankedSeason;
        }

        isCharacterInArena[characterID] = true;
        characters.setNftVar(characterID, 1, 1);

        isWeaponInArena[weaponID] = true;
        weapons.setNftVar(weaponID, 1, 1);

        if (useShield) {
            isShieldInArena[shieldID] = true;
            shields.setNftVar(shieldID, 1, 1);
        }

        uint256 characterWager;

        if (excessWagerByCharacter[characterID] != 0) {
            characterWager = excessWagerByCharacter[characterID];
        } else {
            characterWager = fighterByCharacter[characterID].wager;
        }

        _matchableCharactersByTier[tier].add(characterID);
        fighterByCharacter[characterID] = Fighter(
            characterID,
            weaponID,
            shieldID,
            wager.add(characterWager),
            useShield
        );
        previousTierByCharacter[characterID] = getArenaTier(characterID);
        excessWagerByCharacter[characterID] = 0;

        skillToken.transferFrom(msg.sender, address(this), wager);
    }

    /// @dev withdraws a character and its items from the arena.
    /// if the character is in a battle, a penalty is charged
    function withdrawFromArena(uint256 characterID)
        external
        isOwnedCharacter(characterID)
        characterInArena(characterID)
        characterNotUnderAttack(characterID)
    {
        Fighter storage fighter = fighterByCharacter[characterID];
        uint256 wager = fighter.wager;
        uint256 entryWager = getEntryWager(characterID);

        if (matchByFinder[characterID].createdAt != 0) {
            if (wager < entryWager.mul(withdrawFeePercent).div(100)) {
                wager = 0;
            } else {
                wager = wager.sub(entryWager.mul(withdrawFeePercent).div(100));
            }
        }

        _removeCharacterFromArena(characterID);

        excessWagerByCharacter[characterID] = 0;
        fighter.wager = 0;

        skillToken.safeTransfer(msg.sender, wager);
    }

    /// @dev attempts to find an opponent for a character
    function findOpponent(uint256 characterID)
        external
        isOwnedCharacter(characterID)
        characterInArena(characterID)
        characterNotUnderAttack(characterID)
    {
        require(matchByFinder[characterID].createdAt == 0, "Already in match");

        _assignOpponent(characterID);
    }

    /// @dev attempts to find a new opponent for a fee
    function reRollOpponent(uint256 characterID)
        external
        characterInArena(characterID)
        characterNotUnderAttack(characterID)
        isOwnedCharacter(characterID)
    {
        uint256 opponentID = getOpponent(characterID);

        require(matchByFinder[characterID].createdAt != 0, "Not in match");

        delete finderByOpponent[opponentID];
        if (isCharacterInArena[opponentID]) {
            _matchableCharactersByTier[getArenaTier(opponentID)].add(opponentID);
        }

        _assignOpponent(characterID);

        skillToken.transferFrom(
            msg.sender,
            address(this),
            getDuelCost(characterID).mul(reRollFeePercent).div(100)
        );
    }

    /// @dev adds a character to the duel queue
    function prepareDuel(uint256 attackerID)
        external
        isOwnedCharacter(attackerID)
        characterInArena(attackerID)
        characterWithinDecisionTime(attackerID)
    {
        require(!_duelQueue.contains(attackerID), "Char in duel queue");

        uint256 defenderID = getOpponent(attackerID);

        if (seasonByCharacter[attackerID] != currentRankedSeason) {
            rankingPointsByCharacter[attackerID] = 0;
            seasonByCharacter[attackerID] = currentRankedSeason;
        }

        if (seasonByCharacter[defenderID] != currentRankedSeason) {
            rankingPointsByCharacter[defenderID] = 0;
            seasonByCharacter[defenderID] = currentRankedSeason;
        }

        isDefending[defenderID] = true;

        _duelQueue.add(attackerID);
    }

    /// @dev allows a player to withdraw their ranking earnings
    function withdrawRankedRewards() external {
        uint256 amountToTransfer = _rankingRewardsByPlayer[msg.sender];

        if (amountToTransfer > 0) {
            _rankingRewardsByPlayer[msg.sender] = 0;

            skillToken.safeTransfer(msg.sender, amountToTransfer);
        }
    }

    /// @dev restarts ranked season
    function restartRankedSeason() public restricted {
        uint256[] memory duelQueue = getDuelQueue();

        if (duelQueue.length > 0) {
            performDuels(duelQueue);
        }

        // Loops over 15 tiers. Should not be reachable anytime in the foreseeable future
        for (uint8 i = 0; i <= 15; i++) {
            if (_topRankingCharactersByTier[i].length == 0) {
                continue;
            }

            uint256 difference = 0;

            if (
                _topRankingCharactersByTier[i].length <= prizePercentages.length
            ) {
                difference =
                    prizePercentages.length -
                    _topRankingCharactersByTier[i].length;
            }

            // If there are less players than top positions, excess is transferred to top 1
            if (
                _topRankingCharactersByTier[i].length < prizePercentages.length
            ) {
                uint256 excessPercentage;
                address topOnePlayer = characters.ownerOf(
                    _topRankingCharactersByTier[i][0]
                );

                // We accumulate excess percentage
                for (
                    uint256 j = prizePercentages.length - difference;
                    j < prizePercentages.length;
                    j++
                ) {
                    excessPercentage = excessPercentage.add(
                        prizePercentages[j]
                    );
                }

                // We assign excessive rewards to top 1 player
                _rankingRewardsByPlayer[topOnePlayer] = _rankingRewardsByPlayer[
                    topOnePlayer
                ].add((rankingsPoolByTier[i].mul(excessPercentage)).div(100));
            }

            // We assign rewards normally to all possible players
            for (uint8 h = 0; h < prizePercentages.length - difference; h++) {
                _assignRewards(
                    _topRankingCharactersByTier[i][h],
                    h,
                    rankingsPoolByTier[i]
                );
            }

            // We reset ranking prize pools
            rankingsPoolByTier[i] = 0;
 
            // We reset top players' scores
            for (uint256 k = 0; k < _topRankingCharactersByTier[i].length; k++) {
                rankingPointsByCharacter[_topRankingCharactersByTier[i][k]] = 0;
            }
        }

        currentRankedSeason = currentRankedSeason.add(1);
        seasonStartedAt = block.timestamp;
    }

    /// @dev performs a list of duels
    function performDuels(uint256[] memory attackerIDs) public restricted {
        for (uint256 i = 0; i < attackerIDs.length; i++) {
            uint256 attackerID = attackerIDs[i];

            if (!_duelQueue.contains(attackerID)) continue;

            uint256 defenderID = getOpponent(attackerID);
            uint8 defenderTrait = characters.getTrait(defenderID);
            uint8 attackerTrait = characters.getTrait(attackerID);

            uint24 attackerRoll = _getCharacterPowerRoll(
                attackerID,
                defenderTrait
            );
            uint24 defenderRoll = _getCharacterPowerRoll(
                defenderID,
                attackerTrait
            );

            // Reduce defender roll if attacker has a shield
            if (fighterByCharacter[attackerID].useShield) {
                uint24 attackerShieldDefense = 3;

                (, , , uint8 attackerShieldTrait) = shields.getFightData(
                    fighterByCharacter[attackerID].shieldID,
                    attackerTrait
                );

                if (
                    game.isTraitEffectiveAgainst(
                        attackerShieldTrait,
                        defenderTrait
                    )
                ) {
                    attackerShieldDefense = 10;
                }

                defenderRoll = uint24(
                    (defenderRoll.mul(uint24(100).sub(attackerShieldDefense)))
                        .div(100)
                );
            }

            // Reduce attacker roll if defender has a shield
            if (fighterByCharacter[defenderID].useShield) {
                uint24 defenderShieldDefense = 3;

                (, , , uint8 defenderShieldTrait) = shields.getFightData(
                    fighterByCharacter[defenderID].shieldID,
                    defenderTrait
                );

                if (
                    game.isTraitEffectiveAgainst(
                        defenderShieldTrait,
                        attackerTrait
                    )
                ) {
                    defenderShieldDefense = 10;
                }

                attackerRoll = uint24(
                    (attackerRoll.mul(uint24(100).sub(defenderShieldDefense)))
                        .div(100)
                );
            }

            uint256 winnerID = attackerRoll >= defenderRoll
                ? attackerID
                : defenderID;
            uint256 loserID = attackerRoll >= defenderRoll
                ? defenderID
                : attackerID;

            emit DuelFinished(
                attackerID,
                defenderID,
                block.timestamp,
                attackerRoll,
                defenderRoll,
                attackerRoll >= defenderRoll
            );

            BountyDistribution
                memory bountyDistribution = _getDuelBountyDistribution(
                    attackerID
                );

            fighterByCharacter[winnerID].wager = fighterByCharacter[winnerID]
                .wager
                .add(bountyDistribution.winnerReward);

            uint256 loserWager;

            if (
                fighterByCharacter[loserID].wager <
                bountyDistribution.loserPayment
            ) {
                loserWager = 0;
            } else {
                loserWager = fighterByCharacter[loserID].wager.sub(
                    bountyDistribution.loserPayment
                );
            }

            fighterByCharacter[loserID].wager = loserWager;

            delete matchByFinder[attackerID];
            delete finderByOpponent[defenderID];
            isDefending[defenderID] = false;

            if (
                fighterByCharacter[loserID].wager < getDuelCost(loserID) ||
                fighterByCharacter[loserID].wager <
                getEntryWager(loserID).mul(withdrawFeePercent).div(100)
            ) {
                _removeCharacterFromArena(loserID);
            } else {
                _matchableCharactersByTier[getArenaTier(loserID)].add(loserID);
            }

            _matchableCharactersByTier[getArenaTier(winnerID)].add(winnerID);

            // Add ranking points to the winner
            rankingPointsByCharacter[winnerID] = rankingPointsByCharacter[
                winnerID
            ].add(winningPoints);
            // Check if the loser's current raking points are 'losingPoints' or less and set them to 0 if that's the case, else subtract the ranking points
            if (rankingPointsByCharacter[loserID] <= losingPoints) {
                rankingPointsByCharacter[loserID] = 0;
            } else {
                rankingPointsByCharacter[loserID] = rankingPointsByCharacter[
                    loserID
                ].sub(losingPoints);
            }

            processWinner(winnerID);
            processLoser(loserID);

            // Add to the rankings pool
            rankingsPoolByTier[getArenaTier(attackerID)] = rankingsPoolByTier[
                getArenaTier(attackerID)
            ].add(bountyDistribution.rankingPoolTax / 2);

            gameCofferTaxDue += bountyDistribution.rankingPoolTax / 2;

            _duelQueue.remove(attackerID);
        }
    }

    /// @dev updates the rank of the winner of a duel
    function processWinner(uint256 winnerID) private {
        uint256 rankingPoints = rankingPointsByCharacter[winnerID];
        uint8 tier = getArenaTier(winnerID);
        uint256[] storage topRankingCharacters = _topRankingCharactersByTier[
            tier
        ];
        uint256 winnerPosition;
        bool winnerInRanking;

        // check if winner is withing the top 4
        for (uint8 i = 0; i < topRankingCharacters.length; i++) {
            if (winnerID == topRankingCharacters[i]) {
                winnerPosition = i;
                winnerInRanking = true;
                break;
            }
        }
        // if the winner is not in the top characters we then compare it to the last character of the top rank, swapping positions if the condition is met
        if (
            !winnerInRanking &&
            rankingPoints >=
            rankingPointsByCharacter[
                topRankingCharacters[topRankingCharacters.length - 1]
            ]
        ) {
            topRankingCharacters[topRankingCharacters.length - 1] = winnerID;
            winnerPosition = topRankingCharacters.length - 1;
        }

        for (winnerPosition; winnerPosition > 0; winnerPosition--) {
            if (
                rankingPointsByCharacter[
                    topRankingCharacters[winnerPosition]
                ] >=
                rankingPointsByCharacter[
                    topRankingCharacters[winnerPosition - 1]
                ]
            ) {
                uint256 oldCharacter = topRankingCharacters[winnerPosition - 1];
                topRankingCharacters[winnerPosition - 1] = winnerID;
                topRankingCharacters[winnerPosition] = oldCharacter;
            } else {
                break;
            }
        }
    }

    /// @dev updates the rank of the loser of a duel
    function processLoser(uint256 loserID) private {
        uint256 rankingPoints = rankingPointsByCharacter[loserID];
        uint8 tier = getArenaTier(loserID);
        uint256[] storage ranking = _topRankingCharactersByTier[tier];
        uint256 loserPosition;
        bool loserFound;

        // check if the loser is in the top 4
        for (uint8 i = 0; i < ranking.length; i++) {
            if (loserID == ranking[i]) {
                loserPosition = i;
                loserFound = true;
                break;
            }
        }
        // if the character is within the top 4, compare it to the character that precedes it and swap positions if the condition is met
        if (loserFound) {
            for (
                loserPosition;
                loserPosition < ranking.length - 1;
                loserPosition++
            ) {
                if (
                    rankingPoints <
                    rankingPointsByCharacter[ranking[loserPosition + 1]]
                ) {
                    uint256 oldCharacter = ranking[loserPosition + 1];
                    ranking[loserPosition + 1] = loserID;
                    ranking[loserPosition] = oldCharacter;
                } else {
                    break;
                }
            }
        }
    }

    /// @dev wether or not the character is still in time to start a duel
    function isCharacterWithinDecisionTime(uint256 characterID)
        public
        view
        returns (bool)
    {
        return
            matchByFinder[characterID].createdAt.add(decisionSeconds) >
            block.timestamp;
    }

    /// @dev checks wether or not the character is actively someone else's opponent
    function isCharacterNotUnderAttack(uint256 characterID)
        public
        view
        returns (bool)
    {
        return
            (finderByOpponent[characterID] == 0 &&
                matchByFinder[0].defenderID != characterID) ||
            !isCharacterWithinDecisionTime(finderByOpponent[characterID]);
    }

    /// @dev gets the amount of SKILL required to enter the arena
    function getEntryWager(uint256 characterID) public view returns (uint256) {
        return getDuelCost(characterID).mul(wageringFactor);
    }

    /// @dev gets the amount of SKILL that is risked per duel
    function getDuelCost(uint256 characterID) public view returns (uint256) {
        int128 tierExtra = ABDKMath64x64
            .divu(getArenaTier(characterID).mul(100), 100)
            .mul(_tierWagerUSD);

        return game.usdToSkill(_baseWagerUSD.add(tierExtra));
    }

    /// @dev gets the arena tier of a character (tiers are 1-10, 11-20, etc...)
    function getArenaTier(uint256 characterID) public view returns (uint8) {
        uint256 level = characters.getLevel(characterID);
        return uint8(level.div(10));
    }

    /// @dev get an attacker's opponent
    function getOpponent(uint256 attackerID) public view returns (uint256) {
        return matchByFinder[attackerID].defenderID;
    }

    /// @dev get the top ranked characters by a character's ID
    function getTierTopCharacters(uint256 characterID)
        public
        view
        returns (uint256[] memory)
    {
        uint8 tier = getArenaTier(characterID);
        uint256 arrayLength;
        // we return only the top 3 players, returning the array without the pivot ranker if it exists
        if (
            _topRankingCharactersByTier[tier].length == _maxTopCharactersPerTier
        ) {
            arrayLength = _topRankingCharactersByTier[tier].length - 1;
        } else {
            arrayLength = _topRankingCharactersByTier[tier].length;
        }
        uint256[] memory topRankers = new uint256[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            topRankers[i] = _topRankingCharactersByTier[tier][i];
        }

        return topRankers;
    }

    /// @dev returns ranked prize percentages distribution
    function getPrizePercentages() external view returns (uint256[] memory) {
        return prizePercentages;
    }

    /// @dev returns the account's ranking prize pool earnings
    function getPlayerPrizePoolRewards() public view returns (uint256) {
        return _rankingRewardsByPlayer[msg.sender];
    }

    /// @dev returns the current duel queue
    function getDuelQueue() public view returns (uint256[] memory) {
        uint256 length = _duelQueue.length();
        uint256[] memory values = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = _duelQueue.at(i);
        }

        return values;
    }

    /// @dev assigns an opponent to a character
    function _assignOpponent(uint256 characterID) private {
        uint8 tier = getArenaTier(characterID);
        EnumerableSet.UintSet
            storage matchableCharacters = _matchableCharactersByTier[tier];

        require(matchableCharacters.length() != 0, "No enemy in tier");
        require(!_duelQueue.contains(characterID), "Char dueling");

        uint256 seed = randoms.getRandomSeed(msg.sender);
        uint256 randomIndex = RandomUtil.randomSeededMinMax(
            0,
            matchableCharacters.length() - 1,
            seed
        );
        uint256 opponentID;
        uint256 matchableCharactersCount = matchableCharacters.length();
        bool foundOpponent = false;

        for (uint256 i = 0; i < matchableCharactersCount; i++) {
            uint256 index = (randomIndex + i) % matchableCharactersCount;
            uint256 candidateID = matchableCharacters.at(index);

            if (candidateID == characterID) {
                if (matchableCharactersCount == 1) {
                    break;
                }
                if (
                    matchableCharacters.at(matchableCharactersCount - 1) ==
                    candidateID
                ) {
                    candidateID = matchableCharacters.at(0);
                } else {
                    candidateID = matchableCharacters.at(index + 1);
                }
            }
            if (
                characters.ownerOf(candidateID) ==
                characters.ownerOf(characterID)
            ) {
                continue;
            }

            foundOpponent = true;
            opponentID = candidateID;
            break;
        }

        require(foundOpponent, "No enemy found");

        matchByFinder[characterID] = Match(
            characterID,
            opponentID,
            block.timestamp
        );
        finderByOpponent[opponentID] = characterID;
        _matchableCharactersByTier[tier].remove(characterID);
        _matchableCharactersByTier[tier].remove(opponentID);
    }

    /// @dev increases a player's withdrawable funds depending on their position in the ranked leaderboard
    function _assignRewards(
        uint256 characterID,
        uint8 position,
        uint256 pool
    ) private {
        uint256 percentage = prizePercentages[position];
        uint256 amountToTransfer = (pool.mul(percentage)).div(100);
        address playerToTransfer = characters.ownerOf(characterID);

        _rankingRewardsByPlayer[playerToTransfer] = _rankingRewardsByPlayer[
            playerToTransfer
        ].add(amountToTransfer);
    }

    /// @dev removes a character from arena and clears it's matches
    function _removeCharacterFromArena(uint256 characterID)
        private
        characterInArena(characterID)
    {
        require(!isDefending[characterID], "Defender duel in process");

        Fighter storage fighter = fighterByCharacter[characterID];

        uint256 weaponID = fighter.weaponID;
        uint256 shieldID = fighter.shieldID;

        excessWagerByCharacter[characterID] = fighter.wager;

        // Shield removed first before the fighter is deleted
        if (fighter.useShield) {
            isShieldInArena[shieldID] = false;
            shields.setNftVar(shieldID, 1, 0);
        }

        delete fighterByCharacter[characterID];
        delete matchByFinder[characterID];

        if (_duelQueue.contains(characterID)) {
            _duelQueue.remove(characterID);
        }

        uint8 tier = getArenaTier(characterID);

        if (_matchableCharactersByTier[tier].contains(characterID)) {
            _matchableCharactersByTier[tier].remove(characterID);
        }

        isCharacterInArena[characterID] = false;
        isWeaponInArena[weaponID] = false;

        // setting characters, weapons and shield NFTVAR_BUSY to 0
        characters.setNftVar(characterID, 1, 0);
        weapons.setNftVar(weaponID, 1, 0);
    }

    function _getCharacterPowerRoll(uint256 characterID, uint8 opponentTrait)
        private
        view
        returns (uint24)
    {
        uint8 trait = characters.getTrait(characterID);
        uint24 basePower = characters.getPower(characterID);
        uint256 weaponID = fighterByCharacter[characterID].weaponID;
        uint256 seed = randoms.getRandomSeedUsingHash(
            msg.sender,
            blockhash(block.number)
        );

        bool useShield = fighterByCharacter[characterID].useShield;
        int128 bonusShieldStats;
        if (useShield) {
            bonusShieldStats = _getShieldStats(characterID);
        }

        (
            ,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait
        ) = weapons.getFightData(weaponID, trait);

        int128 playerTraitBonus = getPVPTraitBonusAgainst(
            trait,
            weaponTrait,
            opponentTrait
        );

        uint256 playerFightPower = game.getPlayerPower(
            basePower,
            weaponMultFight.add(bonusShieldStats),
            weaponBonusPower
        );

        uint256 playerPower = RandomUtil.plusMinus10PercentSeeded(
            playerFightPower,
            seed
        );

        return uint24(playerTraitBonus.mulu(playerPower));
    }

    function getPVPTraitBonusAgainst(
        uint8 characterTrait,
        uint8 weaponTrait,
        uint8 opponentTrait
    ) public view returns (int128) {
        int128 traitBonus = ABDKMath64x64.fromUInt(1);
        int128 fightTraitBonus = game.fightTraitBonus();
        int128 charTraitFactor = ABDKMath64x64.divu(50, 100);
        if (characterTrait == weaponTrait) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }

        // We apply 50% of char trait bonuses because they are applied twice (once per fighter)
        if (game.isTraitEffectiveAgainst(characterTrait, opponentTrait)) {
            traitBonus = traitBonus.add(fightTraitBonus.mul(charTraitFactor));
        } else if (
            game.isTraitEffectiveAgainst(opponentTrait, characterTrait)
        ) {
            traitBonus = traitBonus.sub(fightTraitBonus.mul(charTraitFactor));
        }
        return traitBonus;
    }

    function _getShieldStats(uint256 characterID)
        private
        view
        returns (int128)
    {
        uint8 trait = characters.getTrait(characterID);
        uint256 shieldID = fighterByCharacter[characterID].shieldID;
        (, int128 shieldMultFight, , ) = shields.getFightData(shieldID, trait);
        return (shieldMultFight);
    }

    function _getDuelBountyDistribution(uint256 attackerID)
        private
        view
        returns (BountyDistribution memory bountyDistribution)
    {
        uint256 duelCost = getDuelCost(attackerID);
        uint256 bounty = duelCost.mul(2);
        uint256 poolTax = _rankingsPoolTaxPercent.mul(bounty).div(100);

        uint256 reward = bounty.sub(poolTax).sub(duelCost);

        return BountyDistribution(reward, duelCost, poolTax);
    }

    function fillGameCoffers() public restricted {
        skillToken.safeTransfer(address(game), gameCofferTaxDue);
        game.trackIncome(gameCofferTaxDue);
        gameCofferTaxDue = 0;
    }

    function setBaseWagerInCents(uint256 cents) external restricted {
        _baseWagerUSD = ABDKMath64x64.divu(cents, 100);
    }

    function setTierWagerInCents(uint256 cents) external restricted {
        _tierWagerUSD = ABDKMath64x64.divu(cents, 100);
    }

    function setPrizePercentage(uint256 index, uint256 value)
        external
        restricted
    {
        prizePercentages[index] = value;
    }

    function setWageringFactor(uint8 factor) external restricted {
        wageringFactor = factor;
    }

    function setReRollFeePercent(uint256 percent) external restricted {
        reRollFeePercent = percent;
    }

    function setWithdrawFeePercent(uint256 percent) external restricted {
        withdrawFeePercent = percent;
    }

    function setRankingsPoolTaxPercent(uint8 percent) external restricted {
        _rankingsPoolTaxPercent = percent;
    }

    function setDecisionSeconds(uint256 secs) external restricted {
        decisionSeconds = secs;
    }

    function setWinningPoints(uint8 pts) external restricted {
        winningPoints = pts;
    }

    function setLosingPoints(uint8 pts) external restricted {
        losingPoints = pts;
    }

    function setMaxTopCharactersPerTier(uint8 max) external restricted {
        _maxTopCharactersPerTier = max;
    }

    function setSeasonDuration(uint256 duration) external restricted {
        seasonDuration = duration;
    }

    function setArenaAccess(uint256 accessFlags) external restricted {
        arenaAccess = accessFlags;
    }

    // Note: The following are debugging functions. Remove later.

    function clearDuelQueue() external restricted {
        uint256 length = _duelQueue.length();

        for (uint256 i = 0; i < length; i++) {
            if (matchByFinder[_duelQueue.at(i)].defenderID > 0) {
                isDefending[matchByFinder[_duelQueue.at(i)].defenderID] = false;
            }

            _duelQueue.remove(_duelQueue.at(i));
        }

        isDefending[0] = false;
    }

    function setRankingPoints(uint256 characterID, uint8 newRankingPoints)
        public
        restricted
    {
        rankingPointsByCharacter[characterID] = newRankingPoints;
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m)));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    uint256 absoluteResult;
    bool negativeResult = false;
    if (x >= 0) {
      absoluteResult = powu (uint256 (x) << 63, y);
    } else {
      // We rely on overflow behavior here
      absoluteResult = powu (uint256 (uint128 (-x)) << 63, y);
      negativeResult = y & 1 > 0;
    }

    absoluteResult >>= 63;

    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << uint256 (127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= uint256 (63 - (x >> 64));
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is unsigned 129.127 fixed point
   * number and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x unsigned 129.127-bit fixed point number
   * @param y uint256 value
   * @return unsigned 129.127-bit fixed point number
   */
  function powu (uint256 x, uint256 y) private pure returns (uint256) {
    if (y == 0) return 0x80000000000000000000000000000000;
    else if (x == 0) return 0;
    else {
      int256 msb = 0;
      uint256 xc = x;
      if (xc >= 0x100000000000000000000000000000000) { xc >>= 128; msb += 128; }
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 xe = msb - 127;
      if (xe > 0) x >>= uint256 (xe);
      else x <<= uint256 (-xe);

      uint256 result = 0x80000000000000000000000000000000;
      int256 re = 0;

      while (y > 0) {
        if (y & 1 > 0) {
          result = result * x;
          y -= 1;
          re += xe;
          if (result >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            result >>= 128;
            re += 1;
          } else result >>= 127;
          if (re < -127) return 0; // Underflow
          require (re < 128); // Overflow
        } else {
          x = x * x;
          y >>= 1;
          xe <<= 1;
          if (x >=
            0x8000000000000000000000000000000000000000000000000000000000000000) {
            x >>= 128;
            xe += 1;
          } else x >>= 127;
          if (xe < -127) return 0; // Underflow
          require (xe < 128); // Overflow
        }
      }

      if (re > 0) result <<= uint256 (re);
      else if (re < 0) result >>= uint256 (-re);

      return result;
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
      if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
      if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
      if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
      if (xx >= 0x100) { xx >>= 8; r <<= 4; }
      if (xx >= 0x10) { xx >>= 4; r <<= 2; }
      if (xx >= 0x8) { r <<= 1; }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return uint128 (r < r1 ? r : r1);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMapUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/EnumerableSetUpgradeable.sol";
import "../../utils/EnumerableMapUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using StringsUpgradeable for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSetUpgradeable.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMapUpgradeable.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721Upgradeable.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721Upgradeable.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721ReceiverUpgradeable(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./Promos.sol";
import "./util.sol";

contract Weapons is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint16;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP = keccak256("RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize () public initializer {
        __ERC721_init("CryptoBlades weapon", "CBW");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function migrateTo_e55d8c5() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        burnPointMultiplier = 2;
        lowStarBurnPowerPerPoint = 15;
        fourStarBurnPowerPerPoint = 30;
        fiveStarBurnPowerPerPoint = 60;
    }

    function migrateTo_aa9da90() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        oneFrac = ABDKMath64x64.fromUInt(1);
        powerMultPerPointBasic =  ABDKMath64x64.divu(1, 400);// 0.25%
        powerMultPerPointPWR = powerMultPerPointBasic.mul(ABDKMath64x64.divu(103, 100)); // 0.2575% (+3%)
        powerMultPerPointMatching = powerMultPerPointBasic.mul(ABDKMath64x64.divu(107, 100)); // 0.2675% (+7%)
    }

    function migrateTo_951a020() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        // Apparently ERC165 interfaces cannot be removed in this version of the OpenZeppelin library.
        // But if we remove the registration, then while local deployments would not register the interface ID,
        // existing deployments on both testnet and mainnet would still be registered to handle it.
        // That sort of inconsistency is a good way to attract bugs that only happens on some environments.
        // Hence, we keep registering the interface despite not actually implementing the interface.
        _registerInterface(0xe62e6974); // TransferCooldownableInterfaceId.interfaceId()
    }

    function migrateTo_surprise(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        promos = _promos;
    }

    /*
        visual numbers start at 0, increment values by 1
        levels: 1-128
        stars: 1-5 (1,2,3: primary only, 4: one secondary, 5: two secondaries)
        traits: 0-3 [0(fire) > 1(earth) > 2(lightning) > 3(water) > repeat]
        stats: STR(fire), DEX(earth), CHA(lightning), INT(water), PWR(traitless)
        base stat rolls: 1*(1-50), 2*(45-75), 3*(70-100), 4*(50-100), 5*(66-100, main is 68-100)
        burns: add level & main stat, and 50% chance to increase secondaries
        power: each point contributes .25% to fight power
        cosmetics: 0-255 but only 24 is used, may want to cap so future expansions dont change existing weps
    */

    struct Weapon {
        uint16 properties; // right to left: 3b stars, 2b trait, 7b stat pattern, 4b EMPTY
        // stats (each point refers to .25% improvement)
        uint16 stat1;
        uint16 stat2;
        uint16 stat3;
        uint8 level; // separate from stat1 because stat1 will have a pre-roll
    }

    struct WeaponBurnPoints {
        uint8 lowStarBurnPoints;
        uint8 fourStarBurnPoints;
        uint8 fiveStarBurnPoints;
    }

    struct WeaponCosmetics {
        uint8 version;
        uint256 seed;
    }

    Weapon[] private tokens;
    WeaponCosmetics[] private cosmetics;
    mapping(uint256 => WeaponBurnPoints) burnPoints;

    uint public burnPointMultiplier; // 2
    uint public lowStarBurnPowerPerPoint; // 15
    uint public fourStarBurnPowerPerPoint; // 30
    uint public fiveStarBurnPowerPerPoint; // 60

    int128 public oneFrac; // 1.0
    int128 public powerMultPerPointBasic; // 0.25%
    int128 public powerMultPerPointPWR; // 0.2575% (+3%)
    int128 public powerMultPerPointMatching; // 0.2675% (+7%)

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(uint256 => uint256) public lastTransferTimestamp;

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    mapping(uint256 => uint64) durabilityTimestamp;

    uint256 public constant maxDurability = 20;
    uint256 public constant secondsPerDurability = 3000; //50 * 60

    mapping(address => uint256) burnDust; // user address : burned item dust counts

    Promos public promos;

    uint256 public constant BIT_FEATURE_TRANSFER_BLOCKED = 1;
    
    uint256 public constant NUMBERPARAMETER_FEATURE_BITS = uint256(keccak256("FEATURE_BITS"));

    mapping(uint256 => uint256) public numberParameters;

    mapping(uint256 => mapping(uint256 => uint256)) public nftVars;//KEYS: NFTID, VARID
    uint256 public constant NFTVAR_BUSY = 1; // value bitflags: 1 (pvp) | 2 (raid) | 4 (TBD)..

    event Burned(address indexed owner, uint256 indexed burned);
    event NewWeapon(uint256 indexed weapon, address indexed minter);
    event Reforged(address indexed owner, uint256 indexed reforged, uint256 indexed burned, uint8 lowPoints, uint8 fourPoints, uint8 fivePoints);
    event ReforgedWithDust(address indexed owner, uint256 indexed reforged, uint8 lowDust, uint8 fourDust, uint8 fiveDust, uint8 lowPoints, uint8 fourPoints, uint8 fivePoints);
    
    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        needRole(hasRole(GAME_ADMIN, msg.sender));
    }

    modifier minterOnly() {
        _minterOnly();
        _;
    }

    function _minterOnly() internal view {
        needRole(hasRole(GAME_ADMIN, msg.sender) || hasRole(MINTER_ROLE, msg.sender));
    }

    function needRole(bool statement) internal pure {
        require(statement, "NR");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "NFL");
    }

    function getStats(uint256 id) internal view
        returns (uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level) {

        Weapon memory w = tokens[id];
        return (w.properties, w.stat1, w.stat2, w.stat3, w.level);
    }

    function getCosmetics(uint256 id) internal view
        returns (uint8 _blade, uint8 _crossguard, uint8 _grip, uint8 _pommel) {

        WeaponCosmetics memory wc = cosmetics[id];
        _blade = getRandomCosmetic(wc.seed, 1, 24);
        _crossguard = getRandomCosmetic(wc.seed, 2, 24);
        _grip = getRandomCosmetic(wc.seed, 3, 24);
        _pommel = getRandomCosmetic(wc.seed, 4, 24);
    }

    function getCosmeticsSeed(uint256 id) public view noFreshLookup(id)
        returns (uint256) {

        WeaponCosmetics memory wc = cosmetics[id];
        return wc.seed;
    }

    function get(uint256 id) public view noFreshLookup(id)
        returns (
            uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level,
            uint8 _blade, uint8 _crossguard, uint8 _grip, uint8 _pommel,
            uint24 _burnPoints, // burn points.. got stack limits so i put them together
            uint24 _bonusPower // bonus power
    ) {
        return _get(id);
    }

    function _get(uint256 id) internal view
        returns (
            uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3, uint8 _level,
            uint8 _blade, uint8 _crossguard, uint8 _grip, uint8 _pommel,
            uint24 _burnPoints, // burn points.. got stack limits so i put them together
            uint24 _bonusPower // bonus power
    ) {
        (_properties, _stat1, _stat2, _stat3, _level) = getStats(id);
        (_blade, _crossguard, _grip, _pommel) = getCosmetics(id);

        WeaponBurnPoints memory wbp = burnPoints[id];
        _burnPoints =
            uint24(wbp.lowStarBurnPoints) |
            (uint24(wbp.fourStarBurnPoints) << 8) |
            (uint24(wbp.fiveStarBurnPoints) << 16);

        _bonusPower = getBonusPower(id);
    }

    function mint(address minter, uint256 seed, uint8 chosenElement) public minterOnly returns(uint256) {
        uint256 stars;
        uint256 roll = seed % 100;
        // will need revision, possibly manual configuration if we support more than 5 stars
        if(roll < 1) {
            stars = 4; // 5* at 1%
        }
        else if(roll < 6) { // 4* at 5%
            stars = 3;
        }
        else if(roll < 21) { // 3* at 15%
            stars = 2;
        }
        else if(roll < 56) { // 2* at 35%
            stars = 1;
        }
        else {
            stars = 0; // 1* at 44%
        }

        return mintWeaponWithStars(minter, stars, seed, chosenElement);
    }

    function mintGiveawayWeapon(address to, uint256 stars, uint8 chosenElement) external minterOnly returns(uint256) {
        // MANUAL USE ONLY; DO NOT USE IN CONTRACTS!
        return mintWeaponWithStars(to, stars, uint256(keccak256(abi.encodePacked(now, tokens.length))), chosenElement);
    }

    function mintWeaponWithStars(address minter, uint256 stars, uint256 seed, uint8 chosenElement) public minterOnly returns(uint256) {
        require(stars < 8);
        require(chosenElement == 100 || (chosenElement>= 0 && chosenElement<= 3));
        (uint16 stat1, uint16 stat2, uint16 stat3) = getStatRolls(stars, seed);

        return performMintWeapon(minter,
            getRandomProperties(stars, seed, chosenElement),
            stat1,
            stat2,
            stat3,
            RandomUtil.combineSeeds(seed,3)
        );
    }

    function performMintWeapon(address minter,
        uint16 properties,
        uint16 stat1, uint16 stat2, uint16 stat3,
        uint256 cosmeticSeed
    ) public minterOnly returns(uint256) {

        uint256 tokenID = tokens.length;

        if(block.number != lastMintedBlock)
            firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        tokens.push(Weapon(properties, stat1, stat2, stat3, 0));
        cosmetics.push(WeaponCosmetics(0, cosmeticSeed));
        _mint(minter, tokenID);
        durabilityTimestamp[tokenID] = uint64(now.sub(getDurabilityMaxWait()));

        emit NewWeapon(tokenID, minter);
        return tokenID;
    }

    function performMintWeaponDetailed(address minter,
        uint256 metaData,
        uint256 cosmeticSeed, uint256 tokenID
    ) public minterOnly returns(uint256) {

        uint8 fiveStarBurnPoints = uint8(metaData & 0xFF);
        uint8 fourStarBurnPoints = uint8((metaData >> 8) & 0xFF);
        uint8 lowStarBurnPoints = uint8((metaData >> 16) & 0xFF);
        uint8 level = uint8((metaData >> 24) & 0xFF);
        uint16 stat3 = uint16((metaData >> 32) & 0xFFFF);
        uint16 stat2 = uint16((metaData >> 48) & 0xFFFF);
        uint16 stat1 = uint16((metaData >> 64) & 0xFFFF);
        uint16 properties = uint16((metaData >> 80) & 0xFFFF);

        require(lowStarBurnPoints <= 100 && fourStarBurnPoints <= 25 &&  fiveStarBurnPoints <= 10);

        if(tokenID == 0){
            tokenID = performMintWeapon(minter, properties, stat1, stat2, stat3, 0);
        }
        else {
            Weapon storage wp = tokens[tokenID];
            wp.properties = properties;
            wp.stat1 = stat1;
            wp.stat2 = stat2;
            wp.stat3 = stat3;
            wp.level = level;
        }
        WeaponCosmetics storage wc = cosmetics[tokenID];
        wc.seed = cosmeticSeed;
        
        tokens[tokenID].level = level;
        durabilityTimestamp[tokenID] = uint64(now); // avoid chain jumping abuse
        WeaponBurnPoints storage wbp = burnPoints[tokenID];

        wbp.lowStarBurnPoints = lowStarBurnPoints;
        wbp.fourStarBurnPoints = fourStarBurnPoints;
        wbp.fiveStarBurnPoints = fiveStarBurnPoints;

        return tokenID;
    }

    function getRandomProperties(uint256 stars, uint256 seed, uint8 chosenElement) public pure returns (uint16) {
        uint256 trait;
        if (chosenElement == 100) {
            trait = ((RandomUtil.randomSeededMinMax(0,3,RandomUtil.combineSeeds(seed,1)) & 0x3) << 3);
        } else {
            trait = ((chosenElement & 0x3) << 3);
        }
        return uint16((stars & 0x7) // stars aren't randomized here!
            | trait // trait
            | ((RandomUtil.randomSeededMinMax(0,124,RandomUtil.combineSeeds(seed,2)) & 0x7F) << 5)); // statPattern
    }

    function getStatRolls(uint256 stars, uint256 seed) private pure returns (uint16, uint16, uint16) {
        // each point refers to .25%
        // so 1 * 4 is 1%
        uint16 minRoll = getStatMinRoll(stars);
        uint16 maxRoll = getStatMaxRoll(stars);
        uint8 statCount = getStatCount(stars);

        uint16 stat1 = getRandomStat(minRoll, maxRoll, seed, 5);
        uint16 stat2 = 0;
        uint16 stat3 = 0;
        if(statCount > 1) {
            stat2 = getRandomStat(minRoll, maxRoll, seed, 3);
        }
        if(statCount > 2) {
            stat3 = getRandomStat(minRoll, maxRoll, seed, 4);
        }
        return (stat1, stat2, stat3);
    }

    function getRandomStat(uint16 minRoll, uint16 maxRoll, uint256 seed, uint256 seed2) public pure returns (uint16) {
        return uint16(RandomUtil.randomSeededMinMax(minRoll, maxRoll,RandomUtil.combineSeeds(seed, seed2)));
    }

    function getRandomCosmetic(uint256 seed, uint256 seed2, uint8 limit) public pure returns (uint8) {
        return uint8(RandomUtil.randomSeededMinMax(0, limit, RandomUtil.combineSeeds(seed, seed2)));
    }

    function getStatMinRoll(uint256 stars) public pure returns (uint16) {
        // 1 star
        if (stars == 0) return 4;
        // 2 star
        if (stars == 1) return 180;
        // 3 star
        if (stars == 2) return 280;
        // 4 star
        if (stars == 3) return 200;
        // 5+ star
        return 268;
    }

    function getStatMaxRoll(uint256 stars) public pure returns (uint16) {
        // 3+ star
        if (stars > 1) return 400;
        // 2 star
        if (stars > 0) return 300;
        // 1 star
        return 200;
    }

    function getStatCount(uint256 stars) public pure returns (uint8) {
        // 1-2 star
        if (stars < 3) return 1;
        // 3+ star
        return uint8(stars)-1;
    }

    function getProperties(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].properties;
    }

    function getStars(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStarsFromProperties(getProperties(id));
    }

    function getStarsFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8(properties & 0x7); // first two bits for stars
    }

    function getTrait(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getTraitFromProperties(getProperties(id));
    }

    function getTraitFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8((properties >> 3) & 0x3); // two bits after star bits (3)
    }

    function getStatPattern(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStatPatternFromProperties(getProperties(id));
    }

    function getStatPatternFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8((properties >> 5) & 0x7F); // 7 bits after star(3) and trait(2) bits
    }

    function getStat1Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(uint256(statPattern) % 5); // 0-3 regular traits, 4 = traitless (PWR)
    }

    function getStat2Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(SafeMath.div(statPattern, 5) % 5); // 0-3 regular traits, 4 = traitless (PWR)
    }

    function getStat3Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(SafeMath.div(statPattern, 25) % 5); // 0-3 regular traits, 4 = traitless (PWR)
    }

    function getLevel(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].level;
    }

    function getStat1(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat1;
    }

    function getStat2(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat2;
    }

    function getStat3(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat3;
    }

    function getPowerMultiplier(uint256 id) public view noFreshLookup(id) returns (int128) {
        // returns a 64.64 fixed point number for power multiplier
        // this function does not account for traits
        // it is used to calculate base enemy powers for targeting
        Weapon memory wep = tokens[id];
        int128 powerPerPoint = ABDKMath64x64.divu(1, 400); // 0.25% or x0.0025
        int128 stat1 = wep.stat1.fromUInt().mul(powerPerPoint);
        int128 stat2 = wep.stat2.fromUInt().mul(powerPerPoint);
        int128 stat3 = wep.stat3.fromUInt().mul(powerPerPoint);
        return ABDKMath64x64.fromUInt(1).add(stat1).add(stat2).add(stat3);
    }

    function getPowerMultiplierForTrait(
        uint16 properties,
        uint16 stat1,
        uint16 stat2,
        uint16 stat3,
        uint8 trait
    ) public view returns(int128) {
        // Does not include character trait to weapon trait match
        // Only counts arbitrary trait to weapon stat trait
        // This function can be used by frontend to get expected % bonus for each type
        // Making it easy to see on the market how useful it will be to you
        uint8 statPattern = getStatPatternFromProperties(properties);
        int128 result = oneFrac;

        if(getStat1Trait(statPattern) == trait)
            result = result.add(stat1.fromUInt().mul(powerMultPerPointMatching));
        else if(getStat1Trait(statPattern) == 4) // PWR, traitless
            result = result.add(stat1.fromUInt().mul(powerMultPerPointPWR));
        else
            result = result.add(stat1.fromUInt().mul(powerMultPerPointBasic));

        if(getStat2Trait(statPattern) == trait)
            result = result.add(stat2.fromUInt().mul(powerMultPerPointMatching));
        else if(getStat2Trait(statPattern) == 4) // PWR, traitless
            result = result.add(stat2.fromUInt().mul(powerMultPerPointPWR));
        else
            result = result.add(stat2.fromUInt().mul(powerMultPerPointBasic));

        if(getStat3Trait(statPattern) == trait)
            result = result.add(stat3.fromUInt().mul(powerMultPerPointMatching));
        else if(getStat3Trait(statPattern) == 4) // PWR, traitless
            result = result.add(stat3.fromUInt().mul(powerMultPerPointPWR));
        else
            result = result.add(stat3.fromUInt().mul(powerMultPerPointBasic));

        return result;
    }

    function getDustSupplies(address playerAddress) public view returns (uint32[] memory) {
        uint256 burnDustValue = burnDust[playerAddress];
        uint32[] memory supplies = new uint32[](3);
        supplies[0] = uint32(burnDustValue);
        supplies[1] = uint32(burnDustValue >> 32);
        supplies[2] = uint32(burnDustValue >> 64);
        return supplies;
    }

    function _setDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        uint256 burnDustValue = (uint256(amount5B) << 64) + (uint256(amount4B) << 32) + amountLB;
        burnDust[playerAddress] = burnDustValue;
    }

    function _decrementDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        uint32[] memory supplies = getDustSupplies(playerAddress);
        require(supplies[0] >= amountLB && supplies[1] >= amount4B && supplies[2] >= amount5B);
        supplies[0] -= amountLB;
        supplies[1] -= amount4B;
        supplies[2] -= amount5B;
        _setDustSupplies(playerAddress, supplies[0], supplies[1], supplies[2]);
    }

    function incrementDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) public restricted {
        _incrementDustSupplies(playerAddress, amountLB, amount4B, amount5B);
    }

    function _incrementDustSupplies(address playerAddress, uint32 amountLB, uint32 amount4B, uint32 amount5B) internal {
        uint32[] memory supplies = getDustSupplies(playerAddress);
        require(uint256(supplies[0]) + amountLB <= 0xFFFFFFFF
            && uint256(supplies[1]) + amount4B <= 0xFFFFFFFF
            && uint256(supplies[2]) + amount5B <= 0xFFFFFFFF);
        supplies[0] += amountLB;
        supplies[1] += amount4B;
        supplies[2] += amount5B;
        _setDustSupplies(playerAddress, supplies[0], supplies[1], supplies[2]);
    }

    function _calculateBurnValues(uint256 burnID) public view returns(uint8[] memory) {
        uint8[] memory values = new uint8[](3);

        // Carried burn points.
        WeaponBurnPoints storage burningbp = burnPoints[burnID];
        values[0] = (burningbp.lowStarBurnPoints + 1) / 2;
        values[1] = (burningbp.fourStarBurnPoints + 1) / 2;
        values[2] = (burningbp.fiveStarBurnPoints + 1) / 2;

        // Stars-based burn points.
        Weapon storage burning = tokens[burnID];
        uint8 stars = getStarsFromProperties(burning.properties);
        if(stars < 3) { // 1-3 star
            values[0] += uint8(burnPointMultiplier * (stars + 1));
        }
        else if(stars == 3) { // 4 star
            values[1] += uint8(burnPointMultiplier);
        }
        else if(stars == 4) { // 5 star
            values[2] += uint8(burnPointMultiplier);
        }

        return values;
    }

    function burn(uint256 burnID) public restricted {
        uint8[] memory values = _calculateBurnValues(burnID);

        address burnOwner = ownerOf(burnID);

        _burn(burnID);
        if(promos.getBit(burnOwner, 4) == false)
            _incrementDustSupplies(burnOwner, values[0], values[1], values[2]);

        emit Burned(
            burnOwner,
            burnID
        );
    }

    function reforge(uint256 reforgeID, uint256 burnID) public restricted {
        uint8[] memory values = _calculateBurnValues(burnID);

        // Note: preexisting issue of applying burn points even if _burn fails.
        if(promos.getBit(ownerOf(reforgeID), 4) == false)
            _applyBurnPoints(reforgeID, values[0], values[1], values[2]);
        _burn(burnID);

        WeaponBurnPoints storage wbp = burnPoints[reforgeID];
        emit Reforged(
            ownerOf(reforgeID),
            reforgeID,
            burnID,
            wbp.lowStarBurnPoints,
            wbp.fourStarBurnPoints,
            wbp.fiveStarBurnPoints
        );
    }

    function reforgeWithDust(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) public restricted {

        if(promos.getBit(ownerOf(reforgeID), 4) == false)
            _applyBurnPoints(reforgeID, amountLB, amount4B, amount5B);
        _decrementDustSupplies(ownerOf(reforgeID), amountLB, amount4B, amount5B);

        WeaponBurnPoints storage wbp = burnPoints[reforgeID];
        emit ReforgedWithDust(
            ownerOf(reforgeID),
            reforgeID,
            amountLB,
            amount4B,
            amount5B,
            wbp.lowStarBurnPoints,
            wbp.fourStarBurnPoints,
            wbp.fiveStarBurnPoints
        );
    }

    function _applyBurnPoints(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) private {
        WeaponBurnPoints storage wbp = burnPoints[reforgeID];

        if(amountLB > 0) {
            require(wbp.lowStarBurnPoints < 100, "LB capped");
        }
        if(amount4B > 0) {
            require(wbp.fourStarBurnPoints < 25, "4B capped");
        }
        if(amount5B > 0) {
            require(wbp.fiveStarBurnPoints < 10, "5B capped");
        }

        wbp.lowStarBurnPoints += amountLB;
        wbp.fourStarBurnPoints += amount4B;
        wbp.fiveStarBurnPoints += amount5B;

        if(wbp.lowStarBurnPoints > 100)
            wbp.lowStarBurnPoints = 100;
        if(wbp.fourStarBurnPoints > 25)
            wbp.fourStarBurnPoints = 25;
        if(wbp.fiveStarBurnPoints > 10)
            wbp.fiveStarBurnPoints = 10;
    }

    function getBonusPower(uint256 id) public view noFreshLookup(id) returns (uint24) {
        Weapon storage wep = tokens[id];
        return getBonusPowerForFight(id, wep.level);
    }

    function getBonusPowerForFight(uint256 id, uint8 level) public view returns (uint24) {
        WeaponBurnPoints storage wbp = burnPoints[id];
        return uint24(lowStarBurnPowerPerPoint.mul(wbp.lowStarBurnPoints)
            .add(fourStarBurnPowerPerPoint.mul(wbp.fourStarBurnPoints))
            .add(fiveStarBurnPowerPerPoint.mul(wbp.fiveStarBurnPoints))
            .add(uint256(15).mul(level))
        );
    }

    function getFightData(uint256 id, uint8 charTrait) public view noFreshLookup(id) returns (int128, int128, uint24, uint8) {
        Weapon storage wep = tokens[id];
        return (
            oneFrac.add(powerMultPerPointBasic.mul(
                    ABDKMath64x64.fromUInt(
                        wep.stat1 + wep.stat2 + wep.stat3
                    )
            )),//targetMult
            getPowerMultiplierForTrait(wep.properties, wep.stat1, wep.stat2, wep.stat3, charTrait),
            getBonusPowerForFight(id, wep.level),
            getTraitFromProperties(wep.properties)
        );
    }

    function getFightDataAndDrainDurability(address fighter,
        uint256 id, uint8 charTrait, uint8 drainAmount, bool allowNegativeDurability, uint256 busyFlag) public
        restricted
    returns (int128, int128, uint24, uint8) {
        require(fighter == ownerOf(id) && nftVars[id][NFTVAR_BUSY] == 0);
        nftVars[id][NFTVAR_BUSY] |= busyFlag;
        drainDurability(id, drainAmount, allowNegativeDurability);
        Weapon storage wep = tokens[id];
        return (
            oneFrac.add(powerMultPerPointBasic.mul(
                    ABDKMath64x64.fromUInt(
                        wep.stat1 + wep.stat2 + wep.stat3
                    )
            )),//targetMult
            getPowerMultiplierForTrait(wep.properties, wep.stat1, wep.stat2, wep.stat3, charTrait),
            getBonusPowerForFight(id, wep.level),
            getTraitFromProperties(wep.properties)
        );
    }

    function drainDurability(uint256 id, uint8 amount, bool allowNegativeDurability) internal {
        uint8 durabilityPoints = getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
        require((durabilityPoints >= amount
        || (allowNegativeDurability && durabilityPoints > 0)) // we allow going into negative, but not starting negative
            ,"Low durability!");

        uint64 drainTime = uint64(amount * secondsPerDurability);
        if(durabilityPoints >= maxDurability) { // if durability full, we reset timestamp and drain from that
            durabilityTimestamp[id] = uint64(now - getDurabilityMaxWait() + drainTime);
        }
        else {
            durabilityTimestamp[id] = uint64(durabilityTimestamp[id] + drainTime);
        }
    }

    function setBurnPointMultiplier(uint256 multiplier) public restricted {
        burnPointMultiplier = multiplier;
    }
    function setLowStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        lowStarBurnPowerPerPoint = powerPerBurnPoint;
    }
    function setFourStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        fourStarBurnPowerPerPoint = powerPerBurnPoint;
    }
    function setFiveStarBurnPowerPerPoint(uint256 powerPerBurnPoint) public restricted {
        fiveStarBurnPowerPerPoint = powerPerBurnPoint;
    }

    function getDurabilityTimestamp(uint256 id) public view returns (uint64) {
        return durabilityTimestamp[id];
    }

    function setDurabilityTimestamp(uint256 id, uint64 timestamp) public restricted {
        durabilityTimestamp[id] = timestamp;
    }

    function getDurabilityPoints(uint256 id) public view returns (uint8) {
        return getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
    }

    function getDurabilityPointsFromTimestamp(uint64 timestamp) public view returns (uint8) {
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerDurability;
        if(points > maxDurability) {
            points = maxDurability;
        }
        return uint8(points);
    }

    function isDurabilityFull(uint256 id) public view returns (bool) {
        return getDurabilityPoints(id) >= maxDurability;
    }

    function getDurabilityMaxWait() public pure returns (uint64) {
        return uint64(maxDurability * secondsPerDurability);
    }

    function getNftVar(uint256 weaponID, uint256 nftVar) public view returns(uint256) {
        return nftVars[weaponID][nftVar];
    }
    function setNftVar(uint256 weaponID, uint256 nftVar, uint256 value) public restricted {
        nftVars[weaponID][nftVar] = value;
    }

    function setFeatureEnabled(uint256 bit, bool enabled) public restricted {
        if (enabled) {
            numberParameters[NUMBERPARAMETER_FEATURE_BITS] |= bit;
        } else {
            numberParameters[NUMBERPARAMETER_FEATURE_BITS] &= ~bit;
        }
    }

    function _isFeatureEnabled(uint256 bit) private view returns (bool) {
        return (numberParameters[NUMBERPARAMETER_FEATURE_BITS] & bit) == bit;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(nftVars[tokenId][NFTVAR_BUSY] == 0);
        // Always allow minting and burning.
        if(from != address(0) && to != address(0)) {
            // But other transfers require the feature to be enabled.
            require(_isFeatureEnabled(BIT_FEATURE_TRANSFER_BLOCKED) == false);

            if(promos.getBit(from, 4)) { // bad actors, they can transfer to market but nowhere else
                require(hasRole(RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP, to));
            }
        }
    }
}

pragma solidity ^0.6.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library RandomUtil {

    using SafeMath for uint256;

    function randomSeededMinMax(uint min, uint max, uint seed) internal pure returns (uint) {
        // inclusive,inclusive (don't use absolute min and max values of uint256)
        // deterministic based on seed provided
        uint diff = max.sub(min).add(1);
        uint randomVar = uint(keccak256(abi.encodePacked(seed))).mod(diff);
        randomVar = randomVar.add(min);
        return randomVar;
    }

    function combineSeeds(uint seed1, uint seed2) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed1, seed2)));
    }

    function combineSeeds(uint[] memory seeds) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeds)));
    }

    function plusMinus10PercentSeeded(uint256 num, uint256 seed) internal pure returns (uint256) {
        uint256 tenPercent = num.div(10);
        return num.sub(tenPercent).add(randomSeededMinMax(0, tenPercent.mul(2), seed));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./Promos.sol";
import "./util.sol";

contract Shields is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint16;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize () public initializer {
        __ERC721_init("CryptoBlades shield", "CBS");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        shieldBaseMultiplier = ABDKMath64x64.fromUInt(1);
        defenseMultPerPointBasic =  ABDKMath64x64.divu(1, 400); // 0.25%
        defenseMultPerPointDEF = defenseMultPerPointBasic.mul(ABDKMath64x64.divu(103, 100)); // 0.2575% (+3%)
        defenseMultPerPointMatching = defenseMultPerPointBasic.mul(ABDKMath64x64.divu(107, 100)); // 0.2675% (+7%)
    }

    function migrateTo_surprise(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        promos = _promos;
    }

    /*
        visual numbers start at 0, increment values by 1
        stars: 1-5 (1,2,3: primary only, 4: one secondary, 5: two secondaries)
        traits: 0-3 [0(fire) > 1(earth) > 2(lightning) > 3(water) > repeat]
        stats: STR(fire), DEX(earth), CHA(lightning), INT(water), BLK(traitless)
        base stat rolls: 1*(1-50), 2*(45-75), 3*(70-100), 4*(50-100), 5*(66-100, main is 68-100)
        defense: each point contributes .25% to fight defense
        cosmetics: 0-255, to be used for future display purposes
    */

    struct Shield {
        uint16 properties; // right to left: 3b stars, 2b trait, 7b stat pattern, 4b EMPTY
        // stats (each point refers to .25% improvement)
        uint16 stat1;
        uint16 stat2;
        uint16 stat3;
    }

    struct ShieldCosmetics {
        uint8 version;
        uint256 seed;
    }

    Shield[] private tokens;
    ShieldCosmetics[] private cosmetics;

    int128 public shieldBaseMultiplier; // 1.0
    int128 public defenseMultPerPointBasic; // 0.25%
    int128 public defenseMultPerPointDEF; // 0.2575% (+3%)
    int128 public defenseMultPerPointMatching; // 0.2675% (+7%)

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    mapping(uint256 => uint64) durabilityTimestamp;

    uint256 public constant maxDurability = 20;
    uint256 public constant secondsPerDurability = 3000; //50 * 60

    Promos public promos;

    mapping(uint256 => mapping(uint256 => uint256)) public nftVars;//KEYS: NFTID, VARID
    uint256 public constant NFTVAR_BUSY = 1; // value bitflags: 1 (pvp) | 2 (raid) | 4 (TBD)..
    uint256 public constant NFTVAR_SHIELD_TYPE = 2; // 0 = normal, 1 = founders, 2 = legendary defender

    event NewShield(uint256 indexed shield, address indexed minter);
    
    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "Too fresh for lookup");
    }

    function getStats(uint256 id) internal view
        returns (uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3) {

        Shield memory s = tokens[id];
        return (s.properties, s.stat1, s.stat2, s.stat3);
    }

    function get(uint256 id) public view noFreshLookup(id)
        returns (
            uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3
    ) {
        return _get(id);
    }

    function _get(uint256 id) internal view
        returns (
            uint16 _properties, uint16 _stat1, uint16 _stat2, uint16 _stat3
    ) {
        return getStats(id);
    }

    function getOwned() public view returns(uint256[] memory) {
        return getOwnedBy(msg.sender);
    }

    function getOwnedBy(address owner) public view returns(uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(owner));
        for(uint256 i = 0; i < tokens.length; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }

    function mintForPurchase(address buyer) external restricted {
        require(totalSupply() < 25000, "Out of stock"); // temporary restriction
        mint(buyer, uint256(keccak256(abi.encodePacked(buyer, blockhash(block.number - 1)))));
    }

    function mint(address minter, uint256 seed) public restricted returns(uint256) {
        uint256 stars;
        uint256 roll = seed % 100;
        // will need revision, possibly manual configuration if we support more than 5 stars
        if(roll < 1) {
            stars = 4; // 5* at 1%
        }
        else if(roll < 6) { // 4* at 5%
            stars = 3;
        }
        else if(roll < 21) { // 3* at 15%
            stars = 2;
        }
        else if(roll < 56) { // 2* at 35%
            stars = 1;
        }
        else {
            stars = 0; // 1* at 44%
        }

        return mintShieldWithStars(minter, stars, seed);
    }

    function mintShieldWithStars(address minter, uint256 stars, uint256 seed) public restricted returns(uint256) {
        require(stars < 8, "Stars parameter too high! (max 7)");
        (uint16 stat1, uint16 stat2, uint16 stat3) = getStatRolls(stars, seed);

        return performMintShield(minter,
            getRandomProperties(stars, seed),
            stat1,
            stat2,
            stat3,
            RandomUtil.combineSeeds(seed,3)
        );
    }

    function performMintShield(address minter,
        uint16 properties,
        uint16 stat1, uint16 stat2, uint16 stat3,
        uint256 cosmeticSeed
    ) public restricted returns(uint256) {

        uint256 tokenID = tokens.length;

        if(block.number != lastMintedBlock)
            firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        tokens.push(Shield(properties, stat1, stat2, stat3));
        cosmetics.push(ShieldCosmetics(0, cosmeticSeed));
        _mint(minter, tokenID);
        durabilityTimestamp[tokenID] = uint64(now.sub(getDurabilityMaxWait()));

        emit NewShield(tokenID, minter);
        return tokenID;
    }

    function getRandomProperties(uint256 stars, uint256 seed) public pure returns (uint16) {
        return uint16((stars & 0x7) // stars aren't randomized here!
            | ((RandomUtil.randomSeededMinMax(0,3,RandomUtil.combineSeeds(seed,1)) & 0x3) << 3) // trait
            | ((RandomUtil.randomSeededMinMax(0,124,RandomUtil.combineSeeds(seed,2)) & 0x7F) << 5)); // statPattern
    }

    function getStatRolls(uint256 stars, uint256 seed) private pure returns (uint16, uint16, uint16) {
        uint16 minRoll = getStatMinRoll(stars);
        uint16 maxRoll = getStatMaxRoll(stars);
        uint8 statCount = getStatCount(stars);

        uint16 stat1 = getRandomStat(minRoll, maxRoll, seed, 5);
        uint16 stat2 = 0;
        uint16 stat3 = 0;
        if(statCount > 1) {
            stat2 = getRandomStat(minRoll, maxRoll, seed, 3);
        }
        if(statCount > 2) {
            stat3 = getRandomStat(minRoll, maxRoll, seed, 4);
        }
        return (stat1, stat2, stat3);
    }

    function getRandomStat(uint16 minRoll, uint16 maxRoll, uint256 seed, uint256 seed2) public pure returns (uint16) {
        return uint16(RandomUtil.randomSeededMinMax(minRoll, maxRoll,RandomUtil.combineSeeds(seed, seed2)));
    }

    function getRandomCosmetic(uint256 seed, uint256 seed2, uint8 limit) public pure returns (uint8) {
        return uint8(RandomUtil.randomSeededMinMax(0, limit, RandomUtil.combineSeeds(seed, seed2)));
    }

    function getStatMinRoll(uint256 stars) public pure returns (uint16) {
        // 1 star
        if (stars == 0) return 4;
        // 2 star
        if (stars == 1) return 180;
        // 3 star
        if (stars == 2) return 280;
        // 4 star
        if (stars == 3) return 200;
        // 5+ star
        return 268;
    }

    function getStatMaxRoll(uint256 stars) public pure returns (uint16) {
        // 3+ star
        if (stars > 1) return 400;
        // 2 star
        if (stars > 0) return 300;
        // 1 star
        return 200;
    }

    function getStatCount(uint256 stars) public pure returns (uint8) {
        // 1-2 star
        if (stars < 3) return 1;
        // 3+ star
        return uint8(stars)-1;
    }

    function getProperties(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].properties;
    }

    function getStars(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStarsFromProperties(getProperties(id));
    }

    function getStarsFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8(properties & 0x7); // first two bits for stars
    }

    function getTrait(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getTraitFromProperties(getProperties(id));
    }

    function getTraitFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8((properties >> 3) & 0x3); // two bits after star bits (3)
    }

    function getStatPattern(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStatPatternFromProperties(getProperties(id));
    }

    function getStatPatternFromProperties(uint16 properties) public pure returns (uint8) {
        return uint8((properties >> 5) & 0x7F); // 7 bits after star(3) and trait(2) bits
    }

    function getStat1Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(uint256(statPattern) % 5); // 0-3 regular traits, 4 = traitless (DEF)
    }

    function getStat2Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(SafeMath.div(statPattern, 5) % 5); // 0-3 regular traits, 4 = traitless (DEF)
    }

    function getStat3Trait(uint8 statPattern) public pure returns (uint8) {
        return uint8(SafeMath.div(statPattern, 25) % 5); // 0-3 regular traits, 4 = traitless (DEF)
    }

    function getStat1(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat1;
    }

    function getStat2(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat2;
    }

    function getStat3(uint256 id) public view noFreshLookup(id) returns (uint16) {
        return tokens[id].stat3;
    }

    function getDefenseMultiplier(uint256 id) public view noFreshLookup(id) returns (int128) {
        // returns a 64.64 fixed point number for defense multiplier
        // this function does not account for traits
        // it is used to calculate base enemy defenses for targeting
        Shield memory shd = tokens[id];
        int128 defensePerPoint = defenseMultPerPointBasic;
        int128 stat1 = shd.stat1.fromUInt().mul(defensePerPoint);
        int128 stat2 = shd.stat2.fromUInt().mul(defensePerPoint);
        int128 stat3 = shd.stat3.fromUInt().mul(defensePerPoint);
        return shieldBaseMultiplier.add(stat1).add(stat2).add(stat3);
    }

    function getDefenseMultiplierForTrait(
        uint16 properties,
        uint16 stat1,
        uint16 stat2,
        uint16 stat3,
        uint8 trait
    ) public view returns(int128) {
        // Does not include character trait to shield trait match
        // Only counts arbitrary trait to shield stat trait
        // This function can be used by frontend to get expected % bonus for each type
        // Making it easy to see on the market how useful it will be to you
        uint8 statPattern = getStatPatternFromProperties(properties);
        int128 result = shieldBaseMultiplier;

        if(getStat1Trait(statPattern) == trait)
            result = result.add(stat1.fromUInt().mul(defenseMultPerPointMatching));
        else if(getStat1Trait(statPattern) == 4) // DEF, traitless
            result = result.add(stat1.fromUInt().mul(defenseMultPerPointDEF));
        else
            result = result.add(stat1.fromUInt().mul(defenseMultPerPointBasic));

        if(getStat2Trait(statPattern) == trait)
            result = result.add(stat2.fromUInt().mul(defenseMultPerPointMatching));
        else if(getStat2Trait(statPattern) == 4) // DEF, traitless
            result = result.add(stat2.fromUInt().mul(defenseMultPerPointDEF));
        else
            result = result.add(stat2.fromUInt().mul(defenseMultPerPointBasic));

        if(getStat3Trait(statPattern) == trait)
            result = result.add(stat3.fromUInt().mul(defenseMultPerPointMatching));
        else if(getStat3Trait(statPattern) == 4) // DEF, traitless
            result = result.add(stat3.fromUInt().mul(defenseMultPerPointDEF));
        else
            result = result.add(stat3.fromUInt().mul(defenseMultPerPointBasic));

        return result;
    }

    function getFightData(uint256 id, uint8 charTrait) public view noFreshLookup(id) returns (int128, int128, uint24, uint8) {
        Shield storage shd = tokens[id];
        return (
            shieldBaseMultiplier.add(defenseMultPerPointBasic.mul(
                    ABDKMath64x64.fromUInt(
                        shd.stat1 + shd.stat2 + shd.stat3
                    )
            )),//targetMult
            getDefenseMultiplierForTrait(shd.properties, shd.stat1, shd.stat2, shd.stat3, charTrait),
            // Bonus defense support intended in future.
            0,
            getTraitFromProperties(shd.properties)
        );
    }

    function getFightDataAndDrainDurability(uint256 id, uint8 charTrait, uint8 drainAmount) public
        restricted noFreshLookup(id)
    returns (int128, int128, uint24, uint8) {

        require(nftVars[id][NFTVAR_BUSY] == 0, "Shield is busy");
        uint8 durabilityPoints = getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
        require(durabilityPoints >= drainAmount, "Not enough durability!");

        uint64 drainTime = uint64(drainAmount * secondsPerDurability);
        if(durabilityPoints >= maxDurability) { // if durability full, we reset timestamp and drain from that
            durabilityTimestamp[id] = uint64(now - getDurabilityMaxWait() + drainTime);
        }
        else {
            durabilityTimestamp[id] = uint64(durabilityTimestamp[id] + drainTime);
        }

        Shield storage shd = tokens[id];
        return (
            shieldBaseMultiplier.add(defenseMultPerPointBasic.mul(
                    ABDKMath64x64.fromUInt(
                        shd.stat1 + shd.stat2 + shd.stat3
                    )
            )),//targetMult
            getDefenseMultiplierForTrait(shd.properties, shd.stat1, shd.stat2, shd.stat3, charTrait),
            // Bonus defense support intended in future.
            0,
            getTraitFromProperties(shd.properties)
        );
    }

    function drainDurability(uint256 id, uint8 amount) public restricted {
        uint8 durabilityPoints = getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
        require(durabilityPoints >= amount, "Not enough durability!");

        uint64 drainTime = uint64(amount * secondsPerDurability);
        if(durabilityPoints >= maxDurability) { // if durability full, we reset timestamp and drain from that
            durabilityTimestamp[id] = uint64(now - getDurabilityMaxWait() + drainTime);
        }
        else {
            durabilityTimestamp[id] = uint64(durabilityTimestamp[id] + drainTime);
        }
    }

    function getDurabilityTimestamp(uint256 id) public view returns (uint64) {
        return durabilityTimestamp[id];
    }

    function setDurabilityTimestamp(uint256 id, uint64 timestamp) public restricted {
        durabilityTimestamp[id] = timestamp;
    }

    function getDurabilityPoints(uint256 id) public view returns (uint8) {
        return getDurabilityPointsFromTimestamp(durabilityTimestamp[id]);
    }

    function getDurabilityPointsFromTimestamp(uint64 timestamp) public view returns (uint8) {
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerDurability;
        if(points > maxDurability) {
            points = maxDurability;
        }
        return uint8(points);
    }

    function isDurabilityFull(uint256 id) public view returns (bool) {
        return getDurabilityPoints(id) >= maxDurability;
    }

    function getDurabilityMaxWait() public pure returns (uint64) {
        return uint64(maxDurability * secondsPerDurability);
    }

    function getNftVar(uint256 shieldID, uint256 nftVar) public view returns(uint256) {
        return nftVars[shieldID][nftVar];
    }
    function setNftVar(uint256 shieldID, uint256 nftVar, uint256 value) public restricted {
        nftVars[shieldID][nftVar] = value;
    }
    function setNftVars(uint256[] calldata ids, uint256 nftVar, uint256 value) external restricted {
        for(uint i = 0; i < ids.length; i++)
            nftVars[ids[i]][nftVar] = value;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(promos.getBit(from, 4) == false && promos.getBit(to, 4) == false
            && nftVars[tokenId][NFTVAR_BUSY] == 0);
    }
}

pragma solidity ^0.6.5;

interface IStakeFromGame {
    function stakeFromGame(address player, uint256 amount) external;

    function unstakeToGame(address player, uint256 amount) external;
}

pragma solidity ^0.6.5;

interface IRandoms {
    // Views
    function getRandomSeed(address user) external view returns (uint256 seed);
    function getRandomSeedUsingHash(address user, bytes32 hash) external view returns (uint256 seed);
}

pragma solidity ^0.6.5;

interface IPriceOracle {
    // Views
    function currentPrice() external view returns (uint256 price);

    // Mutative
    function setCurrentPrice(uint256 price) external;

    // Events
    event CurrentPriceUpdated(uint256 price);
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IStakeFromGame.sol";
import "./interfaces/IRandoms.sol";
import "./interfaces/IPriceOracle.sol";
import "./characters.sol";
import "./Promos.sol";
import "./weapons.sol";
import "./util.sol";
import "./Blacksmith.sol";

contract CryptoBlades is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeERC20 for IERC20;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    int128 public constant PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT =
        14757395258967641292; // 0.8 in fixed-point 64x64 format

    // Mapped variables (vars[]) keys, one value per key
    // Using small numbers for now to save on contract size (3% for 13 vars vs using uint256(keccak256("name"))!)
    // Can be migrated later via setVars if needed
    uint256 public constant VAR_HOURLY_INCOME = 1;
    uint256 public constant VAR_HOURLY_FIGHTS = 2;
    uint256 public constant VAR_HOURLY_POWER_SUM = 3;
    uint256 public constant VAR_HOURLY_POWER_AVERAGE = 4;
    uint256 public constant VAR_HOURLY_PAY_PER_FIGHT = 5;
    uint256 public constant VAR_HOURLY_TIMESTAMP = 6;
    uint256 public constant VAR_DAILY_MAX_CLAIM = 7;
    uint256 public constant VAR_CLAIM_DEPOSIT_AMOUNT = 8;
    uint256 public constant VAR_PARAM_PAYOUT_INCOME_PERCENT = 9;
    uint256 public constant VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT = 10;
    uint256 public constant VAR_PARAM_DAILY_CLAIM_DEPOSIT_PERCENT = 11;
    uint256 public constant VAR_PARAM_MAX_FIGHT_PAYOUT = 12;
    uint256 public constant VAR_HOURLY_DISTRIBUTION = 13;
    uint256 public constant VAR_UNCLAIMED_SKILL = 14;
    uint256 public constant VAR_HOURLY_MAX_POWER_AVERAGE = 15;
    uint256 public constant VAR_PARAM_HOURLY_MAX_POWER_PERCENT = 16;
    uint256 public constant VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS = 17;
    uint256 public constant VAR_PARAM_HOURLY_PAY_ALLOWANCE = 18;

    // Mapped user variable(userVars[]) keys, one value per wallet
    uint256 public constant USERVAR_DAILY_CLAIMED_AMOUNT = 10001;
    uint256 public constant USERVAR_CLAIM_TIMESTAMP = 10002;

    Characters public characters;
    Weapons public weapons;
    IERC20 public skillToken;//0x154A9F9cbd3449AD22FDaE23044319D6eF2a1Fab;
    IPriceOracle public priceOracleSkillPerUsd;
    IRandoms public randoms;

    function initialize(IERC20 _skillToken, Characters _characters, Weapons _weapons, IPriceOracle _priceOracleSkillPerUsd, IRandoms _randoms) public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GAME_ADMIN, msg.sender);

        skillToken = _skillToken;
        characters = _characters;
        weapons = _weapons;
        priceOracleSkillPerUsd = _priceOracleSkillPerUsd;
        randoms = _randoms;

        staminaCostFight = 40;
        mintCharacterFee = ABDKMath64x64.divu(10, 1);//10 usd;
        mintWeaponFee = ABDKMath64x64.divu(3, 1);//3 usd;

        // migrateTo_1ee400a
        fightXpGain = 32;

        // migrateTo_aa9da90
        oneFrac = ABDKMath64x64.fromUInt(1);
        fightTraitBonus = ABDKMath64x64.divu(75, 1000);

        // migrateTo_7dd2a56
        // numbers given for the curves were $4.3-aligned so they need to be multiplied
        // additional accuracy may be in order for the setter functions for these
        fightRewardGasOffset = ABDKMath64x64.divu(23177, 100000); // 0.0539 x 4.3
        fightRewardBaseline = ABDKMath64x64.divu(344, 1000); // 0.08 x 4.3

        // migrateTo_5e833b0
        durabilityCostFight = 1;
    }

    function migrateTo_ef994e2(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        promos = _promos;
    }

    function migrateTo_23b3a8b(IStakeFromGame _stakeFromGame) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        stakeFromGameImpl = _stakeFromGame;
    }

    function migrateTo_801f279() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        burnWeaponFee = ABDKMath64x64.divu(2, 10);//0.2 usd;
        reforgeWeaponWithDustFee = ABDKMath64x64.divu(3, 10);//0.3 usd;

        reforgeWeaponFee = burnWeaponFee + reforgeWeaponWithDustFee;//0.5 usd;
    }

    function migrateTo_60872c8(Blacksmith _blacksmith) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        blacksmith = _blacksmith;
    }

    function migrateTo_6a97bd1() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        rewardsClaimTaxMax = 2767011611056432742; // = ~0.15 = ~15%
        rewardsClaimTaxDuration = 15 days;
    }

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    uint characterLimit;
    // config vars
    uint8 staminaCostFight;

    // prices & payouts are in USD, with 4 decimals of accuracy in 64.64 fixed point format
    int128 public mintCharacterFee;
    //int128 public rerollTraitFee;
    //int128 public rerollCosmeticsFee;
    int128 public refillStaminaFee;
    // lvl 1 player power could be anywhere between ~909 to 1666
    // cents per fight multiplied by monster power divided by 1000 (lv1 power)
    int128 public fightRewardBaseline;
    int128 public fightRewardGasOffset;

    int128 public mintWeaponFee;
    int128 public reforgeWeaponFee;

    uint256 nonce;

    mapping(address => uint256) lastBlockNumberCalled;

    uint256 public fightXpGain; // multiplied based on power differences

    mapping(address => uint256) tokenRewards; // user adress : skill wei
    mapping(uint256 => uint256) xpRewards; // character id : xp

    int128 public oneFrac; // 1.0
    int128 public fightTraitBonus; // 7.5%

    mapping(address => uint256) public inGameOnlyFunds;
    uint256 public totalInGameOnlyFunds;

    Promos public promos;

    mapping(address => uint256) private _rewardsClaimTaxTimerStart;

    IStakeFromGame public stakeFromGameImpl;

    uint8 durabilityCostFight;

    int128 public burnWeaponFee;
    int128 public reforgeWeaponWithDustFee;

    Blacksmith public blacksmith;

    struct MintPayment {
        bytes32 blockHash;
        uint256 blockNumber;
        address nftAddress;
        uint count;
    }

    mapping(address => MintPayment) mintPayments;

    struct MintPaymentSkillDeposited {
        uint256 skillDepositedFromWallet;
        uint256 skillDepositedFromRewards;
        uint256 skillDepositedFromIgo;

        uint256 skillRefundableFromWallet;
        uint256 skillRefundableFromRewards;
        uint256 skillRefundableFromIgo;

        uint256 refundClaimableTimestamp;
    }

    uint256 public totalMintPaymentSkillRefundable;
    mapping(address => MintPaymentSkillDeposited) mintPaymentSkillDepositeds;

    int128 private rewardsClaimTaxMax;
    uint256 private rewardsClaimTaxDuration;

    mapping(uint256 => uint256) public vars;
    mapping(address => mapping(uint256 => uint256)) public userVars;

    event FightOutcome(address indexed owner, uint256 indexed character, uint256 weapon, uint32 target, uint24 playerRoll, uint24 enemyRoll, uint16 xpGain, uint256 skillGain);
    event InGameOnlyFundsGiven(address indexed to, uint256 skillAmount);

    function recoverSkill(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));

        skillToken.safeTransfer(msg.sender, amount);
    }

    function REWARDS_CLAIM_TAX_MAX() public view returns (int128) {
        return rewardsClaimTaxMax;
    }

    function REWARDS_CLAIM_TAX_DURATION() public view returns (uint256) {
        return rewardsClaimTaxDuration;
    }

    function getSkillToSubtractSingle(uint256 _needed, uint256 _available)
        public
        pure
        returns (uint256 _used, uint256 _remainder) {

        if(_needed <= _available) {
            return (_needed, 0);
        }

        _needed -= _available;

        return (_available, _needed);
    }

    function getSkillToSubtract(uint256 _inGameOnlyFunds, uint256 _tokenRewards, uint256 _skillNeeded)
        public
        pure
        returns (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 fromUserWallet) {

        if(_skillNeeded <= _inGameOnlyFunds) {
            return (_skillNeeded, 0, 0);
        }

        _skillNeeded -= _inGameOnlyFunds;

        if(_skillNeeded <= _tokenRewards) {
            return (_inGameOnlyFunds, _skillNeeded, 0);
        }

        _skillNeeded -= _tokenRewards;

        return (_inGameOnlyFunds, _tokenRewards, _skillNeeded);
    }

    function getSkillNeededFromUserWallet(address playerAddress, uint256 skillNeeded, bool allowInGameOnlyFunds)
        public
        view
        returns (uint256 skillNeededFromUserWallet) {

        uint256 inGameOnlyFundsToUse = 0;
        if (allowInGameOnlyFunds) {
            inGameOnlyFundsToUse = inGameOnlyFunds[playerAddress];
        }
        (,, skillNeededFromUserWallet) = getSkillToSubtract(
            inGameOnlyFundsToUse,
            tokenRewards[playerAddress],
            skillNeeded
        );
    }

    function unpackFightData(uint96 playerData)
        public pure returns (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) {

        charTrait = uint8(playerData & 0xFF);
        basePowerLevel = uint24((playerData >> 8) & 0xFFFFFF);
        timestamp = uint64((playerData >> 32) & 0xFFFFFFFFFFFFFFFF);
    }

    function fight(uint256 char, uint256 wep, uint32 target, uint8 fightMultiplier) external
        onlyNonContract() {
        require(fightMultiplier >= 1 && fightMultiplier <= 5);

        (uint8 charTrait, uint24 basePowerLevel, uint64 timestamp) =
            unpackFightData(characters.getFightDataAndDrainStamina(msg.sender,
                char, staminaCostFight * fightMultiplier, false, 0));

        (int128 weaponMultTarget,
            int128 weaponMultFight,
            uint24 weaponBonusPower,
            uint8 weaponTrait) = weapons.getFightDataAndDrainDurability(msg.sender, wep, charTrait,
                durabilityCostFight * fightMultiplier, false, 0);

        // dirty variable reuse to avoid stack limits
        target = grabTarget(
            getPlayerPower(basePowerLevel, weaponMultTarget, weaponBonusPower),
            timestamp,
            target,
            now / 1 hours
        );
        performFight(
            char,
            wep,
            getPlayerPower(basePowerLevel, weaponMultFight, weaponBonusPower),
            uint24(charTrait | (uint24(weaponTrait) << 8) | (target & 0xFF000000) >> 8),
            uint24(target & 0xFFFFFF),
            fightMultiplier
        );
    }

    function performFight(
        uint256 char,
        uint256 wep,
        uint24 playerFightPower,
        uint24 traitsCWE, // could fit into uint8 since each trait is only stored on 2 bits (TODO)
        uint24 targetPower,
        uint8 fightMultiplier
    ) private {
        uint256 seed = uint256(keccak256(abi.encodePacked(now, msg.sender)));
        uint24 playerRoll = getPlayerPowerRoll(playerFightPower,traitsCWE,seed);
        uint24 monsterRoll = getMonsterPowerRoll(targetPower, RandomUtil.combineSeeds(seed,1));

        updateHourlyPayouts(); // maybe only check in trackIncome? (or do via bot)

        uint16 xp = getXpGainForFight(playerFightPower, targetPower) * fightMultiplier;
        uint256 tokens = getTokenGainForFight(targetPower, true) * fightMultiplier;

        if(playerRoll < monsterRoll) {
            tokens = 0;
            xp = 0;
        }

        if(tokenRewards[msg.sender] == 0 && tokens > 0) {
            _rewardsClaimTaxTimerStart[msg.sender] = block.timestamp;
        }

        // this may seem dumb but we want to avoid guessing the outcome based on gas estimates!
        tokenRewards[msg.sender] += tokens;
        vars[VAR_UNCLAIMED_SKILL] += tokens;
        vars[VAR_HOURLY_DISTRIBUTION] -= tokens;
        xpRewards[char] += xp;

        vars[VAR_HOURLY_FIGHTS] += fightMultiplier;
        vars[VAR_HOURLY_POWER_SUM] += playerFightPower * fightMultiplier;

        emit FightOutcome(msg.sender, char, wep, (targetPower | ((uint32(traitsCWE) << 8) & 0xFF000000)), playerRoll, monsterRoll, xp, tokens);
    }

    function getMonsterPower(uint32 target) public pure returns (uint24) {
        return uint24(target & 0xFFFFFF);
    }

    function getTokenGainForFight(uint24 monsterPower, bool applyLimit) public view returns (uint256) {
        // monsterPower / avgPower * payPerFight * powerMultiplier
        uint256 amount = ABDKMath64x64.divu(monsterPower, vars[VAR_HOURLY_POWER_AVERAGE])
            .mulu(vars[VAR_HOURLY_PAY_PER_FIGHT]);
        
        if(amount > vars[VAR_PARAM_MAX_FIGHT_PAYOUT])
            amount = vars[VAR_PARAM_MAX_FIGHT_PAYOUT];
        if(vars[VAR_HOURLY_DISTRIBUTION] < amount * 5 && applyLimit) // the * 5 is a temp measure until we can sync frontend on main
            amount = 0;
        return amount;
    }

    function getXpGainForFight(uint24 playerPower, uint24 monsterPower) internal view returns (uint16) {
        return uint16(ABDKMath64x64.divu(monsterPower, playerPower).mulu(fightXpGain));
    }

    function getPlayerPowerRoll(
        uint24 playerFightPower,
        uint24 traitsCWE,
        uint256 seed
    ) internal view returns(uint24) {

        uint256 playerPower = RandomUtil.plusMinus10PercentSeeded(playerFightPower,seed);
        return uint24(getPlayerTraitBonusAgainst(traitsCWE).mulu(playerPower));
    }

    function getMonsterPowerRoll(uint24 monsterPower, uint256 seed) internal pure returns(uint24) {
        // roll for fights
        return uint24(RandomUtil.plusMinus10PercentSeeded(monsterPower, seed));
    }

    function getPlayerPower(
        uint24 basePower,
        int128 weaponMultiplier,
        uint24 bonusPower
    ) public pure returns(uint24) {
        return uint24(weaponMultiplier.mulu(basePower).add(bonusPower));
    }

    function getPlayerTraitBonusAgainst(uint24 traitsCWE) public view returns (int128) {
        int128 traitBonus = oneFrac;
        uint8 characterTrait = uint8(traitsCWE & 0xFF);
        if(characterTrait == (traitsCWE >> 8) & 0xFF/*wepTrait*/) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }
        if(isTraitEffectiveAgainst(characterTrait, uint8(traitsCWE >> 16)/*enemy*/)) {
            traitBonus = traitBonus.add(fightTraitBonus);
        }
        else if(isTraitEffectiveAgainst(uint8(traitsCWE >> 16)/*enemy*/, characterTrait)) {
            traitBonus = traitBonus.sub(fightTraitBonus);
        }
        return traitBonus;
    }

    function getTargets(uint256 char, uint256 wep) public view returns (uint32[4] memory) {
        // this is a frontend function
        (int128 weaponMultTarget,,
            uint24 weaponBonusPower,
            ) = weapons.getFightData(wep, characters.getTrait(char));

        return getTargetsInternal(
            getPlayerPower(characters.getPower(char), weaponMultTarget, weaponBonusPower),
            characters.getStaminaTimestamp(char),
            now / 1 hours
        );
    }

    function getTargetsInternal(uint24 playerPower,
        uint64 staminaTimestamp,
        uint256 currentHour
    ) private pure returns (uint32[4] memory) {
        // 4 targets, roll powers based on character + weapon power
        // trait bonuses not accounted for
        // targets expire on the hour

        uint32[4] memory targets;
        for(uint32 i = 0; i < targets.length; i++) {
            // we alter seed per-index or they would be all the same
            // this is a read only function so it's fine to pack all 4 params each iteration
            // for the sake of target picking it needs to be the same as in grabTarget(i)
            // even the exact type of "i" is important here
            uint256 indexSeed = uint256(keccak256(abi.encodePacked(
                staminaTimestamp, currentHour, playerPower, i
            )));
            targets[i] = uint32(
                RandomUtil.plusMinus10PercentSeeded(playerPower, indexSeed) // power
                | (uint32(indexSeed % 4) << 24) // trait
            );
        }

        return targets;
    }

    function grabTarget(
        uint24 playerPower,
        uint64 staminaTimestamp,
        uint32 enemyIndex,
        uint256 currentHour
    ) private pure returns (uint32) {
        require(enemyIndex < 4);

        uint256 enemySeed = uint256(keccak256(abi.encodePacked(
            staminaTimestamp, currentHour, playerPower, enemyIndex
        )));
        return uint32(
            RandomUtil.plusMinus10PercentSeeded(playerPower, enemySeed) // power
            | (uint32(enemySeed % 4) << 24) // trait
        );
    }

    function isTraitEffectiveAgainst(uint8 attacker, uint8 defender) public pure returns (bool) {
        return (((attacker + 1) % 4) == defender); // Thanks to Tourist
    }

    function mintCharacter() public onlyNonContract oncePerBlock(msg.sender) {

        uint256 skillAmount = usdToSkill(mintCharacterFee);
        (,, uint256 fromUserWallet) =
            getSkillToSubtract(
                0,
                tokenRewards[msg.sender],
                skillAmount
            );
        require(skillToken.balanceOf(msg.sender) >= fromUserWallet && promos.getBit(msg.sender, 4) == false);

        uint256 convertedAmount = usdToSkill(mintCharacterFee);
        _payContractTokenOnly(msg.sender, convertedAmount);

        uint256 seed = randoms.getRandomSeed(msg.sender);
        characters.mint(msg.sender, seed);

        // first weapon free with a character mint, max 1 star
        if(weapons.balanceOf(msg.sender) == 0) {
            weapons.performMintWeapon(msg.sender,
                weapons.getRandomProperties(0, RandomUtil.combineSeeds(seed,100), 100),
                weapons.getRandomStat(4, 200, seed, 101),
                0, // stat2
                0, // stat3
                RandomUtil.combineSeeds(seed,102)
            );
        }
    }

    function mintWeaponN(uint32 num, uint8 chosenElement)
        external
        onlyNonContract
        oncePerBlock(msg.sender)
    {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(mintWeaponFee * num * chosenElementFee));
        _mintWeaponNLogic(num, chosenElement);
    }

    function mintWeapon(uint8 chosenElement) external onlyNonContract oncePerBlock(msg.sender) {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(mintWeaponFee * chosenElementFee));
        _mintWeaponLogic(chosenElement);
    }

    function mintWeaponNUsingStakedSkill(uint32 num, uint8 chosenElement)
        external
        onlyNonContract
        oncePerBlock(msg.sender)
    {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        int128 discountedMintWeaponFee =
            mintWeaponFee
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT)
                .mul(ABDKMath64x64.fromUInt(num))
                .mul(ABDKMath64x64.fromUInt(chosenElementFee));
        _payContractStakedOnly(msg.sender, usdToSkill(discountedMintWeaponFee));

        _mintWeaponNLogic(num, chosenElement);
    }

    function mintWeaponUsingStakedSkill(uint8 chosenElement) external onlyNonContract oncePerBlock(msg.sender) {
        uint8 chosenElementFee = chosenElement == 100 ? 1 : 2;
        int128 discountedMintWeaponFee =
            mintWeaponFee
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT)
                .mul(ABDKMath64x64.fromUInt(chosenElementFee));
        _payContractStakedOnly(msg.sender, usdToSkill(discountedMintWeaponFee));

        _mintWeaponLogic(chosenElement);
    }

    function _mintWeaponNLogic(uint32 num, uint8 chosenElement) internal {
        require(num > 0 && num <= 10);
        for (uint i = 0; i < num; i++) {
            weapons.mint(msg.sender, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, i))), chosenElement);
        }
    }

    function _mintWeaponLogic(uint8 chosenElement) internal {
        //uint256 seed = randoms.getRandomSeed(msg.sender);
        weapons.mint(msg.sender, uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender))), chosenElement);
    }

    function burnWeapon(uint256 burnID) external isWeaponOwner(burnID) {
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(burnWeaponFee));

        _burnWeaponLogic(burnID);
    }

    function burnWeapons(uint256[] calldata burnIDs) external isWeaponsOwner(burnIDs) {
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(burnWeaponFee.mul(ABDKMath64x64.fromUInt(burnIDs.length))));

        _burnWeaponsLogic(burnIDs);
    }

    function reforgeWeapon(uint256 reforgeID, uint256 burnID) external isWeaponOwner(reforgeID) isWeaponOwner(burnID) {
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(reforgeWeaponFee));

        _reforgeWeaponLogic(reforgeID, burnID);
    }

    function reforgeWeaponWithDust(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) external isWeaponOwner(reforgeID) {
        _payContractConvertedSupportingStaked(msg.sender, usdToSkill(reforgeWeaponWithDustFee));

        _reforgeWeaponWithDustLogic(reforgeID, amountLB, amount4B, amount5B);
    }

    function burnWeaponUsingStakedSkill(uint256 burnID) external isWeaponOwner(burnID) {
        int128 discountedBurnWeaponFee =
            burnWeaponFee.mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        _payContractStakedOnly(msg.sender, usdToSkill(discountedBurnWeaponFee));

        _burnWeaponLogic(burnID);
    }

    function burnWeaponsUsingStakedSkill(uint256[] calldata burnIDs) external isWeaponsOwner(burnIDs) {
        int128 discountedBurnWeaponFee =
            burnWeaponFee
                .mul(ABDKMath64x64.fromUInt(burnIDs.length))
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        _payContractStakedOnly(msg.sender, usdToSkill(discountedBurnWeaponFee));

        _burnWeaponsLogic(burnIDs);
    }

    function reforgeWeaponUsingStakedSkill(uint256 reforgeID, uint256 burnID) external isWeaponOwner(reforgeID) isWeaponOwner(burnID) {
        int128 discountedReforgeWeaponFee =
            reforgeWeaponFee
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        _payContractStakedOnly(msg.sender, usdToSkill(discountedReforgeWeaponFee));

        _reforgeWeaponLogic(reforgeID, burnID);
    }

    function reforgeWeaponWithDustUsingStakedSkill(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) external isWeaponOwner(reforgeID) {
        int128 discountedReforgeWeaponWithDustFee =
            reforgeWeaponWithDustFee
                .mul(PAYMENT_USING_STAKED_SKILL_COST_AFTER_DISCOUNT);
        _payContractStakedOnly(msg.sender, usdToSkill(discountedReforgeWeaponWithDustFee));

        _reforgeWeaponWithDustLogic(reforgeID, amountLB, amount4B, amount5B);
    }

    function _burnWeaponLogic(uint256 burnID) internal {
        weapons.burn(burnID);
    }

    function _burnWeaponsLogic(uint256[] memory burnIDs) internal {
        for(uint i = 0; i < burnIDs.length; i++) {
            weapons.burn(burnIDs[i]);
        }
    }

    function _reforgeWeaponLogic(uint256 reforgeID, uint256 burnID) internal {
        weapons.reforge(reforgeID, burnID);
    }

    function _reforgeWeaponWithDustLogic(uint256 reforgeID, uint8 amountLB, uint8 amount4B, uint8 amount5B) internal {
        weapons.reforgeWithDust(reforgeID, amountLB, amount4B, amount5B);
    }

    function migrateRandoms(IRandoms _newRandoms) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        randoms = _newRandoms;
    }

    modifier onlyNonContract() {
        _onlyNonContract();
        _;
    }

    function _onlyNonContract() internal view {
        require(tx.origin == msg.sender, "ONC");
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "NGA");
    }

    modifier oncePerBlock(address user) {
        _oncePerBlock(user);
        _;
    }

    function _oncePerBlock(address user) internal {
        require(lastBlockNumberCalled[user] < block.number, "OCB");
        lastBlockNumberCalled[user] = block.number;
    }

    modifier isWeaponOwner(uint256 weapon) {
        _isWeaponOwner(weapon);
        _;
    }

    function _isWeaponOwner(uint256 weapon) internal view {
        require(weapons.ownerOf(weapon) == msg.sender);
    }

    modifier isWeaponsOwner(uint256[] memory weaponArray) {
        _isWeaponsOwner(weaponArray);
        _;
    }

    function _isWeaponsOwner(uint256[] memory weaponArray) internal view {
        for(uint i = 0; i < weaponArray.length; i++) {
            require(weapons.ownerOf(weaponArray[i]) == msg.sender);
        }
    }

    modifier isCharacterOwner(uint256 character) {
        _isCharacterOwner(character);
        _;
    }

    function _isCharacterOwner(uint256 character) internal view {
        require(characters.ownerOf(character) == msg.sender);
    }

    function payPlayerConverted(address playerAddress, uint256 convertedAmount) public restricted {
        _payPlayerConverted(playerAddress, convertedAmount);
    }

    function payContractTokenOnly(address playerAddress, uint256 convertedAmount) public restricted {
        _payContractTokenOnly(playerAddress, convertedAmount, true);
    }

    function payContractTokenOnly(address playerAddress, uint256 convertedAmount, bool track) public restricted {
        _payContractTokenOnly(playerAddress, convertedAmount, track);
    }

    function _payContractTokenOnly(address playerAddress, uint256 convertedAmount) internal {
        _payContractTokenOnly(playerAddress, convertedAmount, true);
    }

    function _payContractTokenOnly(address playerAddress, uint256 convertedAmount, bool track) internal {
        (, uint256 fromTokenRewards, uint256 fromUserWallet) =
            getSkillToSubtract(
                0,
                tokenRewards[playerAddress],
                convertedAmount
            );

        _deductPlayerSkillStandard(playerAddress, 0, fromTokenRewards, fromUserWallet, track);
    }

    function _payContract(address playerAddress, int128 usdAmount) internal
        returns (uint256 _fromInGameOnlyFunds, uint256 _fromTokenRewards, uint256 _fromUserWallet) {

        return _payContractConverted(playerAddress, usdToSkill(usdAmount));
    }

    function _payContractConverted(address playerAddress, uint256 convertedAmount) internal
        returns (uint256 _fromInGameOnlyFunds, uint256 _fromTokenRewards, uint256 _fromUserWallet) {

        (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 fromUserWallet) =
            getSkillToSubtract(
                inGameOnlyFunds[playerAddress],
                tokenRewards[playerAddress],
                convertedAmount
            );

        require(skillToken.balanceOf(playerAddress) >= fromUserWallet,
            string(abi.encodePacked("Not enough SKILL! Need ",RandomUtil.uint2str(convertedAmount))));

        _deductPlayerSkillStandard(playerAddress, fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);

        return (fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);
    }

    function _payContractConvertedSupportingStaked(address playerAddress, uint256 convertedAmount) internal
        returns (
            uint256 _fromInGameOnlyFunds,
            uint256 _fromTokenRewards,
            uint256 _fromUserWallet,
            uint256 _fromStaked
        ) {

        (uint256 fromInGameOnlyFunds, uint256 fromTokenRewards, uint256 _remainder) =
            getSkillToSubtract(
                inGameOnlyFunds[playerAddress],
                tokenRewards[playerAddress],
                convertedAmount
            );

        (uint256 fromUserWallet, uint256 fromStaked) =
            getSkillToSubtractSingle(
                _remainder,
                skillToken.balanceOf(playerAddress)
            );

        _deductPlayerSkillStandard(playerAddress, fromInGameOnlyFunds, fromTokenRewards, fromUserWallet);

        if(fromStaked > 0) {
            stakeFromGameImpl.unstakeToGame(playerAddress, fromStaked);
            _trackIncome(fromStaked);
        }

        return (fromInGameOnlyFunds, fromTokenRewards, fromUserWallet, fromStaked);
    }

    function _payContractStakedOnly(address playerAddress, uint256 convertedAmount) internal {
        stakeFromGameImpl.unstakeToGame(playerAddress, convertedAmount);
        _trackIncome(convertedAmount);
    }

    function _deductPlayerSkillStandard(
        address playerAddress,
        uint256 fromInGameOnlyFunds,
        uint256 fromTokenRewards,
        uint256 fromUserWallet
    ) internal {
        _deductPlayerSkillStandard(
            playerAddress,
            fromInGameOnlyFunds,
            fromTokenRewards,
            fromUserWallet,
            true
        );
    }

    function _deductPlayerSkillStandard(
        address playerAddress,
        uint256 fromInGameOnlyFunds,
        uint256 fromTokenRewards,
        uint256 fromUserWallet,
        bool trackInflow
    ) internal {
        if(fromInGameOnlyFunds > 0) {
            totalInGameOnlyFunds = totalInGameOnlyFunds.sub(fromInGameOnlyFunds);
            inGameOnlyFunds[playerAddress] = inGameOnlyFunds[playerAddress].sub(fromInGameOnlyFunds);
        }

        if(fromTokenRewards > 0) {
            tokenRewards[playerAddress] = tokenRewards[playerAddress].sub(fromTokenRewards);
        }

        if(fromUserWallet > 0) {
            skillToken.transferFrom(playerAddress, address(this), fromUserWallet);
            if(trackInflow)
                _trackIncome(fromUserWallet);
        }
    }

    function deductAfterPartnerClaim(uint256 amount, address player) external restricted {
        tokenRewards[player] = tokenRewards[player].sub(amount);
        _trackIncome(amount);
    }

    function trackIncome(uint256 income) public restricted {
        _trackIncome(income);
    }

    function _trackIncome(uint256 income) internal {
        vars[VAR_HOURLY_INCOME] += ABDKMath64x64.divu(vars[VAR_PARAM_PAYOUT_INCOME_PERCENT],100)
                .mulu(income);
        updateHourlyPayouts();
    }

    function updateHourlyPayouts() internal {
        // Could be done by a bot instead?
        if(now - vars[VAR_HOURLY_TIMESTAMP] >= 1 hours) {
            vars[VAR_HOURLY_TIMESTAMP] = now;

            uint256 undistributed = vars[VAR_HOURLY_INCOME] + vars[VAR_HOURLY_DISTRIBUTION];

            vars[VAR_HOURLY_DISTRIBUTION] = undistributed > vars[VAR_PARAM_HOURLY_PAY_ALLOWANCE]
                ? vars[VAR_PARAM_HOURLY_PAY_ALLOWANCE] : undistributed;
            vars[VAR_HOURLY_INCOME] = undistributed.sub(vars[VAR_HOURLY_DISTRIBUTION]);

            uint256 fights = vars[VAR_HOURLY_FIGHTS];
            if(fights >= vars[VAR_PARAM_SIGNIFICANT_HOUR_FIGHTS]) {
                uint256 averagePower = vars[VAR_HOURLY_POWER_SUM] / fights;

                if(averagePower > vars[VAR_HOURLY_MAX_POWER_AVERAGE])
                    vars[VAR_HOURLY_MAX_POWER_AVERAGE] = averagePower;
            }
            vars[VAR_HOURLY_POWER_AVERAGE] = ABDKMath64x64.divu(vars[VAR_PARAM_HOURLY_MAX_POWER_PERCENT],100)
                .mulu(vars[VAR_HOURLY_MAX_POWER_AVERAGE]);

            vars[VAR_DAILY_MAX_CLAIM] = vars[VAR_HOURLY_PAY_PER_FIGHT] * vars[VAR_PARAM_DAILY_CLAIM_FIGHTS_LIMIT];
            vars[VAR_HOURLY_FIGHTS] = 0;
            vars[VAR_HOURLY_POWER_SUM] = 0;
        }
    }

    function _payPlayer(address playerAddress, int128 baseAmount) internal {
        _payPlayerConverted(playerAddress, usdToSkill(baseAmount));
    }

    function _payPlayerConverted(address playerAddress, uint256 convertedAmount) internal {
        skillToken.transfer(playerAddress, convertedAmount);
    }

    function setCharacterMintValue(uint256 cents) public restricted {
        mintCharacterFee = ABDKMath64x64.divu(cents, 100);
    }

    function setWeaponMintValue(uint256 cents) public restricted {
        mintWeaponFee = ABDKMath64x64.divu(cents, 100);
    }

    function setBurnWeaponValue(uint256 cents) public restricted {
        burnWeaponFee = ABDKMath64x64.divu(cents, 100);
    }

    function setReforgeWeaponValue(uint256 cents) public restricted {
        int128 newReforgeWeaponFee = ABDKMath64x64.divu(cents, 100);
        require(newReforgeWeaponFee > burnWeaponFee);
        reforgeWeaponWithDustFee = newReforgeWeaponFee - burnWeaponFee;
        reforgeWeaponFee = newReforgeWeaponFee;
    }

    function setReforgeWeaponWithDustValue(uint256 cents) public restricted {
        reforgeWeaponWithDustFee = ABDKMath64x64.divu(cents, 100);
        reforgeWeaponFee = burnWeaponFee + reforgeWeaponWithDustFee;
    }

    function setStaminaCostFight(uint8 points) public restricted {
        staminaCostFight = points;
    }

    function setDurabilityCostFight(uint8 points) public restricted {
        durabilityCostFight = points;
    }

    function setFightXpGain(uint256 average) public restricted {
        fightXpGain = average;
    }

    function setRewardsClaimTaxMaxAsPercent(uint256 _percent) public restricted {
        rewardsClaimTaxMax = ABDKMath64x64.divu(_percent, 100);
    }

    function setRewardsClaimTaxDuration(uint256 _rewardsClaimTaxDuration) public restricted {
        rewardsClaimTaxDuration = _rewardsClaimTaxDuration;
    }

    function setVar(uint256 varField, uint256 value) external restricted {
        vars[varField] = value;
    }

    function setVars(uint256[] calldata varFields, uint256[] calldata values) external restricted {
        for(uint i = 0; i < varFields.length; i++) {
            vars[varFields[i]] = values[i];
        }
    }

    function giveInGameOnlyFunds(address to, uint256 skillAmount) external restricted {
        totalInGameOnlyFunds = totalInGameOnlyFunds.add(skillAmount);
        inGameOnlyFunds[to] = inGameOnlyFunds[to].add(skillAmount);

        skillToken.safeTransferFrom(msg.sender, address(this), skillAmount);

        emit InGameOnlyFundsGiven(to, skillAmount);
    }

    function _giveInGameOnlyFundsFromContractBalance(address to, uint256 skillAmount) internal {
        totalInGameOnlyFunds = totalInGameOnlyFunds.add(skillAmount);
        inGameOnlyFunds[to] = inGameOnlyFunds[to].add(skillAmount);

        emit InGameOnlyFundsGiven(to, skillAmount);
    }

    function giveInGameOnlyFundsFromContractBalance(address to, uint256 skillAmount) external restricted {
        _giveInGameOnlyFundsFromContractBalance(to, skillAmount);
    }

    function usdToSkill(int128 usdAmount) public view returns (uint256) {
        return usdAmount.mulu(priceOracleSkillPerUsd.currentPrice());
    }

    function claimTokenRewards() public {
        claimTokenRewards(getRemainingTokenClaimAmountPreTax());
    }

    function claimTokenRewards(uint256 _claimingAmount) public {

        trackDailyClaim(_claimingAmount);

        uint256 _tokenRewardsToPayOut = _claimingAmount.sub(
            _getRewardsClaimTax(msg.sender).mulu(_claimingAmount)
        );

        // Tax goes to game contract itself, which would mean
        // transferring from the game contract to ...itself.
        // So we don't need to do anything with the tax part of the rewards.
        if(promos.getBit(msg.sender, 4) == false) {
            _payPlayerConverted(msg.sender, _tokenRewardsToPayOut);
            if(_tokenRewardsToPayOut <= vars[VAR_UNCLAIMED_SKILL])
                vars[VAR_UNCLAIMED_SKILL] -= _tokenRewardsToPayOut;
        }
    }

    function trackDailyClaim(uint256 _claimingAmount) internal {

        if(isDailyTokenClaimAmountExpired()) {
            userVars[msg.sender][USERVAR_CLAIM_TIMESTAMP] = now;
            userVars[msg.sender][USERVAR_DAILY_CLAIMED_AMOUNT] = 0;
        }
        require(_claimingAmount <= getRemainingTokenClaimAmountPreTax() && _claimingAmount > 0);
        // safemath throws error on negative
        tokenRewards[msg.sender] = tokenRewards[msg.sender].sub(_claimingAmount);
        userVars[msg.sender][USERVAR_DAILY_CLAIMED_AMOUNT] += _claimingAmount;
    }

    function isDailyTokenClaimAmountExpired() public view returns (bool) {
        return userVars[msg.sender][USERVAR_CLAIM_TIMESTAMP] <= now - 1 days;
    }

    function getClaimedTokensToday() public view returns (uint256) {
        // if claim timestamp is older than a day, it's reset to 0
        return isDailyTokenClaimAmountExpired() ? 0 : userVars[msg.sender][USERVAR_DAILY_CLAIMED_AMOUNT];
    }

    function getRemainingTokenClaimAmountPreTax() public view returns (uint256) {
        // used to get how much can be withdrawn until the daily withdraw timer expires
        uint256 max = getMaxTokenClaimAmountPreTax();
        uint256 claimed = getClaimedTokensToday();
        if(claimed >= max)
            return 0; // all tapped out for today
        uint256 remainingOfMax = max-claimed;
        return tokenRewards[msg.sender] >= remainingOfMax ? remainingOfMax : tokenRewards[msg.sender];
    }

    function getMaxTokenClaimAmountPreTax() public view returns(uint256) {
        // if tokenRewards is above VAR_CLAIM_DEPOSIT_AMOUNT, we let them withdraw more
        // this function does not account for amount already withdrawn today
        if(tokenRewards[msg.sender] >= vars[VAR_CLAIM_DEPOSIT_AMOUNT]) { // deposit bonus active
            // max is either 10% of amount above deposit, or 2x the regular limit, whichever is higher
            uint256 aboveDepositAdjusted = ABDKMath64x64.divu(vars[VAR_PARAM_DAILY_CLAIM_DEPOSIT_PERCENT],100)
                .mulu(tokenRewards[msg.sender]-vars[VAR_CLAIM_DEPOSIT_AMOUNT]); // 10% above deposit
            if(aboveDepositAdjusted > vars[VAR_DAILY_MAX_CLAIM] * 2) {
                return aboveDepositAdjusted;
            }
            return vars[VAR_DAILY_MAX_CLAIM] * 2;
        }
        return vars[VAR_DAILY_MAX_CLAIM];
    }
    
    function stakeUnclaimedRewards() public {
        stakeUnclaimedRewards(getRemainingTokenClaimAmountPreTax());
    }

    function stakeUnclaimedRewards(uint256 amount) public {

        trackDailyClaim(amount);

        if(promos.getBit(msg.sender, 4) == false) {
            skillToken.approve(address(stakeFromGameImpl), amount);
            stakeFromGameImpl.stakeFromGame(msg.sender, amount);
        }
    }

    function claimXpRewards() public {
        // our characters go to the tavern to rest
        // they meditate on what they've learned

        uint256[] memory chars = characters.getReadyCharacters(msg.sender);
        require(chars.length > 0);
        uint256[] memory xps = new uint256[](chars.length);
        for(uint256 i = 0; i < chars.length; i++) {
            xps[i] = xpRewards[chars[i]];
            xpRewards[chars[i]] = 0;
        }
        characters.gainXpAll(chars, xps);
    }

    function getTokenRewards() public view returns (uint256) {
        return tokenRewards[msg.sender];
    }

    function getXpRewards(uint256 char) public view returns (uint256) {
        return xpRewards[char];
    }

    function getTokenRewardsFor(address wallet) public view returns (uint256) {
        return tokenRewards[wallet];
    }

    function getTotalSkillOwnedBy(address wallet) public view returns (uint256) {
        return inGameOnlyFunds[wallet] + getTokenRewardsFor(wallet) + skillToken.balanceOf(wallet);
    }

    function _getRewardsClaimTax(address playerAddress) internal view returns (int128) {
        assert(_rewardsClaimTaxTimerStart[playerAddress] <= block.timestamp);

        uint256 rewardsClaimTaxTimerEnd = _rewardsClaimTaxTimerStart[playerAddress].add(rewardsClaimTaxDuration);

        (, uint256 durationUntilNoTax) = rewardsClaimTaxTimerEnd.trySub(block.timestamp);

        assert(0 <= durationUntilNoTax && durationUntilNoTax <= rewardsClaimTaxDuration);

        int128 frac = ABDKMath64x64.divu(durationUntilNoTax, rewardsClaimTaxDuration);

        return rewardsClaimTaxMax.mul(frac);
    }

    function getOwnRewardsClaimTax() public view returns (int128) {
        return _getRewardsClaimTax(msg.sender);
    }

}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Promos.sol";
import "./util.sol";
import "./Garrison.sol";
contract Characters is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    using SafeMath for uint16;
    using SafeMath for uint8;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");
    bytes32 public constant RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP = keccak256("RECEIVE_DOES_NOT_SET_TRANSFER_TIMESTAMP");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize () public initializer {
        __ERC721_init("CryptoBlades character", "CBC");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function migrateTo_1ee400a() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        experienceTable = [
            16, 17, 18, 19, 20, 22, 24, 26, 28, 30, 33, 36, 39, 42, 46, 50, 55, 60, 66
            , 72, 79, 86, 94, 103, 113, 124, 136, 149, 163, 178, 194, 211, 229, 248, 268
            , 289, 311, 334, 358, 383, 409, 436, 464, 493, 523, 554, 586, 619, 653, 688
            , 724, 761, 799, 838, 878, 919, 961, 1004, 1048, 1093, 1139, 1186, 1234, 1283
            , 1333, 1384, 1436, 1489, 1543, 1598, 1654, 1711, 1769, 1828, 1888, 1949, 2011
            , 2074, 2138, 2203, 2269, 2336, 2404, 2473, 2543, 2614, 2686, 2759, 2833, 2908
            , 2984, 3061, 3139, 3218, 3298, 3379, 3461, 3544, 3628, 3713, 3799, 3886, 3974
            , 4063, 4153, 4244, 4336, 4429, 4523, 4618, 4714, 4811, 4909, 5008, 5108, 5209
            , 5311, 5414, 5518, 5623, 5729, 5836, 5944, 6053, 6163, 6274, 6386, 6499, 6613
            , 6728, 6844, 6961, 7079, 7198, 7318, 7439, 7561, 7684, 7808, 7933, 8059, 8186
            , 8314, 8443, 8573, 8704, 8836, 8969, 9103, 9238, 9374, 9511, 9649, 9788, 9928
            , 10069, 10211, 10354, 10498, 10643, 10789, 10936, 11084, 11233, 11383, 11534
            , 11686, 11839, 11993, 12148, 12304, 12461, 12619, 12778, 12938, 13099, 13261
            , 13424, 13588, 13753, 13919, 14086, 14254, 14423, 14593, 14764, 14936, 15109
            , 15283, 15458, 15634, 15811, 15989, 16168, 16348, 16529, 16711, 16894, 17078
            , 17263, 17449, 17636, 17824, 18013, 18203, 18394, 18586, 18779, 18973, 19168
            , 19364, 19561, 19759, 19958, 20158, 20359, 20561, 20764, 20968, 21173, 21379
            , 21586, 21794, 22003, 22213, 22424, 22636, 22849, 23063, 23278, 23494, 23711
            , 23929, 24148, 24368, 24589, 24811, 25034, 25258, 25483, 25709, 25936, 26164
            , 26393, 26623, 26854, 27086, 27319, 27553, 27788, 28024, 28261, 28499, 28738
            , 28978
        ];
    }

    function migrateTo_951a020() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        // Apparently ERC165 interfaces cannot be removed in this version of the OpenZeppelin library.
        // But if we remove the registration, then while local deployments would not register the interface ID,
        // existing deployments on both testnet and mainnet would still be registered to handle it.
        // That sort of inconsistency is a good way to attract bugs that only happens on some environments.
        // Hence, we keep registering the interface despite not actually implementing the interface.
        _registerInterface(0xe62e6974); // TransferCooldownableInterfaceId.interfaceId()
    }

    function migrateTo_ef994e2(Promos _promos) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        promos = _promos;
    }

    function migrateTo_b627f23() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        characterLimit = 4;
    }

    function migrateTo_1a19cbb(Garrison _garrison) external {
        garrison = _garrison;
    }

    /*
        visual numbers start at 0, increment values by 1
        levels: 1-256
        traits: 0-3 [0(fire) > 1(earth) > 2(lightning) > 3(water) > repeat]
    */

    struct Character {
        uint16 xp; // xp to next level
        uint8 level; // up to 256 cap
        uint8 trait; // 2b trait, TBD
        uint64 staminaTimestamp; // standard timestamp in seconds-resolution marking regen start from 0
    }
    struct CharacterCosmetics {
        uint8 version;
        uint256 seed;
    }

    Character[] private tokens;
    CharacterCosmetics[] private cosmetics;

    uint256 public constant maxStamina = 200;
    uint256 public constant secondsPerStamina = 300; //5 * 60

    uint256[256] private experienceTable; // fastest lookup in the west

    // UNUSED; KEPT FOR UPGRADEABILITY PROXY COMPATIBILITY
    mapping(uint256 => uint256) public lastTransferTimestamp;

    Promos public promos;

    uint256 private lastMintedBlock;
    uint256 private firstMintedOfLastBlock;

    uint256 public characterLimit;

    mapping(uint256 => uint256) public raidsDone;
    mapping(uint256 => uint256) public raidsWon;

    mapping(uint256 => mapping(uint256 => uint256)) public nftVars;//KEYS: NFTID, VARID
    uint256 public constant NFTVAR_BUSY = 1; // value bitflags: 1 (pvp) | 2 (raid) | 4 (TBD)..

    Garrison public garrison;

    event NewCharacter(uint256 indexed character, address indexed minter);
    event LevelUp(address indexed owner, uint256 indexed character, uint16 level);

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier noFreshLookup(uint256 id) {
        _noFreshLookup(id);
        _;
    }

    modifier minterOnly() {
        _minterOnly();
        _;
    }

    function _minterOnly() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(MINTER_ROLE, msg.sender), 'no access');
    }

    function _noFreshLookup(uint256 id) internal view {
        require(id < firstMintedOfLastBlock || lastMintedBlock < block.number, "Too fresh for lookup");
    }

    function get(uint256 id) public view noFreshLookup(id) returns (uint16, uint8, uint8, uint64, uint16, uint16, uint16, uint16, uint16, uint16) {
        Character memory c = tokens[id];
        CharacterCosmetics memory cc = cosmetics[id];
        return (c.xp, c.level, c.trait, c.staminaTimestamp,
            getRandomCosmetic(cc.seed, 1, 13), // head
            getRandomCosmetic(cc.seed, 2, 45), // arms
            getRandomCosmetic(cc.seed, 3, 61), // torso
            getRandomCosmetic(cc.seed, 4, 41), // legs
            getRandomCosmetic(cc.seed, 5, 22), // boots
            getRandomCosmetic(cc.seed, 6, 2) // race
        );
    }

    function getRandomCosmetic(uint256 seed, uint256 seed2, uint16 limit) private pure returns (uint16) {
        return uint16(RandomUtil.randomSeededMinMax(0, limit, RandomUtil.combineSeeds(seed, seed2)));
    }

    function getCosmeticsSeed(uint256 id) public view noFreshLookup(id) returns (uint256) {
        CharacterCosmetics memory cc = cosmetics[id];
        return cc.seed;
    }

    function mint(address minter, uint256 seed) public restricted {
        uint256 tokenID = tokens.length;

        if(block.number != lastMintedBlock)
            firstMintedOfLastBlock = tokenID;
        lastMintedBlock = block.number;

        uint16 xp = 0;
        uint8 level = 0; // 1
        uint8 trait = uint8(RandomUtil.randomSeededMinMax(0,3,seed));
        uint64 staminaTimestamp = uint64(now.sub(getStaminaMaxWait()));

        tokens.push(Character(xp, level, trait, staminaTimestamp));
        cosmetics.push(CharacterCosmetics(0, RandomUtil.combineSeeds(seed, 1)));
        address receiver = minter;
        if(minter != address(0) && minter != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, minter) && balanceOf(minter) >= characterLimit) {
            receiver = address(garrison);
            garrison.redirectToGarrison(minter, tokenID);
            _mint(address(garrison), tokenID);
        }
        else {
            _mint(minter, tokenID);
        }
        emit NewCharacter(tokenID, receiver);
    }

    function customMint(address minter, uint16 xp, uint8 level, uint8 trait, uint256 seed, uint256 tokenID) minterOnly public returns (uint256) {
        uint64 staminaTimestamp = uint64(now); // 0 on purpose to avoid chain jumping abuse

        if(tokenID == 0){
            tokenID = tokens.length;

            if(block.number != lastMintedBlock)
                firstMintedOfLastBlock = tokenID;
            lastMintedBlock = block.number;

            tokens.push(Character(xp, level, trait, staminaTimestamp));
            cosmetics.push(CharacterCosmetics(0, RandomUtil.combineSeeds(seed, 1)));
            address receiver = minter;
            if(minter != address(0) && minter != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, minter) && balanceOf(minter) >= characterLimit) {
                receiver = address(garrison);
                garrison.redirectToGarrison(minter, tokenID);
                _mint(address(garrison), tokenID);
            }
            else {
                _mint(minter, tokenID);
            }
            emit NewCharacter(tokenID, receiver);
        }
        else {
            Character storage ch = tokens[tokenID];
            ch.xp = xp;
            ch.level = level;
            ch.trait = trait;
            ch.staminaTimestamp = staminaTimestamp;

            CharacterCosmetics storage cc = cosmetics[tokenID];
            cc.seed = seed;
        }

        return tokenID;
    }

    function getLevel(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].level; // this is used by dataminers and it benefits us
    }

    function getRequiredXpForNextLevel(uint8 currentLevel) public view returns (uint16) {
        return uint16(experienceTable[currentLevel]); // this is helpful to users as the array is private
    }

    function getPower(uint256 id) public view noFreshLookup(id) returns (uint24) {
        return getPowerAtLevel(tokens[id].level);
    }

    function getPowerAtLevel(uint8 level) public pure returns (uint24) {
        // does not use fixed points since the numbers are simple
        // the breakpoints every 10 levels are floored as expected
        // level starts at 0 (visually 1)
        // 1000 at lvl 1
        // 9000 at lvl 51 (~3months)
        // 22440 at lvl 105 (~3 years)
        // 92300 at lvl 255 (heat death of the universe)
        return uint24(
            uint256(1000)
                .add(level.mul(10))
                .mul(level.div(10).add(1))
        );
    }

    function getTrait(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return tokens[id].trait;
    }

    function setTrait(uint256 id, uint8 trait) public restricted {
        tokens[id].trait = trait;
    }

    function getXp(uint256 id) public view noFreshLookup(id) returns (uint32) {
        return tokens[id].xp;
    }

    function gainXp(uint256 id, uint16 xp) public restricted {
        _gainXp(id, xp);
    }

    function _gainXp(uint256 id, uint256 xp) internal {
        Character storage char = tokens[id];
        if (char.level < 255) {
            uint newXp = char.xp.add(xp);
            uint requiredToLevel = experienceTable[char.level]; // technically next level
            while (newXp >= requiredToLevel) {
                newXp = newXp - requiredToLevel;
                char.level += 1;
                emit LevelUp(ownerOf(id), id, char.level);
                if (char.level < 255)
                    requiredToLevel = experienceTable[char.level];
                else newXp = 0;
            }
            char.xp = uint16(newXp);
        }
    }

    function gainXpAll(uint256[] calldata chars, uint256[] calldata xps) external restricted {
        for(uint i = 0; i < chars.length; i++)
            _gainXp(chars[i], xps[i]);
    }

    function getStaminaTimestamp(uint256 id) public view noFreshLookup(id) returns (uint64) {
        return tokens[id].staminaTimestamp;
    }

    function setStaminaTimestamp(uint256 id, uint64 timestamp) public restricted {
        tokens[id].staminaTimestamp = timestamp;
    }

    function getStaminaPoints(uint256 id) public view noFreshLookup(id) returns (uint8) {
        return getStaminaPointsFromTimestamp(tokens[id].staminaTimestamp);
    }

    function getStaminaPointsFromTimestamp(uint64 timestamp) public view returns (uint8) {
        if(timestamp  > now)
            return 0;

        uint256 points = (now - timestamp) / secondsPerStamina;
        if(points > maxStamina) {
            points = maxStamina;
        }
        return uint8(points);
    }

    function isStaminaFull(uint256 id) public view noFreshLookup(id) returns (bool) {
        return getStaminaPoints(id) >= maxStamina;
    }

    function getStaminaMaxWait() public pure returns (uint64) {
        return uint64(maxStamina * secondsPerStamina);
    }

    function getFightDataAndDrainStamina(address fighter,
        uint256 id, uint8 amount, bool allowNegativeStamina, uint256 busyFlag) public restricted returns(uint96) {
        require(fighter == ownerOf(id) && nftVars[id][NFTVAR_BUSY] == 0);
        nftVars[id][NFTVAR_BUSY] |= busyFlag;

        Character storage char = tokens[id];
        uint8 staminaPoints = getStaminaPointsFromTimestamp(char.staminaTimestamp);
        require((staminaPoints > 0 && allowNegativeStamina) // we allow going into negative, but not starting negative
            || staminaPoints >= amount, "Not enough stamina!");

        uint64 drainTime = uint64(amount * secondsPerStamina);
        uint64 preTimestamp = char.staminaTimestamp;
        if(staminaPoints >= maxStamina) { // if stamina full, we reset timestamp and drain from that
            char.staminaTimestamp = uint64(now - getStaminaMaxWait() + drainTime);
        }
        else {
            char.staminaTimestamp = uint64(char.staminaTimestamp + drainTime);
        }
        // bitwise magic to avoid stacking limitations later on
        return uint96(char.trait | (getPowerAtLevel(char.level) << 8) | (preTimestamp << 32));
    }

    function processRaidParticipation(uint256 id, bool won, uint16 xp) public restricted {
        raidsDone[id] = raidsDone[id] + 1;
        raidsWon[id] = won ? (raidsWon[id] + 1) : (raidsWon[id]);
        require(nftVars[id][NFTVAR_BUSY] == 0); // raids do not apply busy flag for now
        //nftVars[id][NFTVAR_BUSY] = 0;
        _gainXp(id, xp);
    }

    function getCharactersOwnedBy(address wallet) public view returns(uint256[] memory chars) {
        uint256 count = balanceOf(wallet);
        chars = new uint256[](count);
        for(uint256 i = 0; i < count; i++)
            chars[i] = tokenOfOwnerByIndex(wallet, i);
    }

    function getReadyCharacters(address wallet) public view returns(uint256[] memory chars) {
        uint256[] memory owned = getCharactersOwnedBy(wallet);
        uint256 ready = 0;
        for(uint i = 0; i < owned.length; i++)
            if(nftVars[owned[i]][NFTVAR_BUSY] == 0)
                ready++;
        chars = new uint[](ready);
        for(uint i = 0; i < owned.length; i++)
            if(nftVars[owned[i]][NFTVAR_BUSY] == 0)
                chars[--ready] = owned[i];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        require(nftVars[tokenId][NFTVAR_BUSY] == 0);

        promos.setBit(from, promos.BIT_FIRST_CHARACTER());
        promos.setBit(to, promos.BIT_FIRST_CHARACTER());
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) override public {
        if(to != address(0) && to != address(0x000000000000000000000000000000000000dEaD) && !hasRole(NO_OWNED_LIMIT, to) && balanceOf(to) >= characterLimit) {
            garrison.redirectToGarrison(to, tokenId);
            super.safeTransferFrom(from, address(garrison), tokenId);
        }
        else {
            super.safeTransferFrom(from, to, tokenId);
        }
    }

    function setCharacterLimit(uint256 max) public restricted {
        characterLimit = max;
    }

    function getNftVar(uint256 characterID, uint256 nftVar) public view returns(uint256) {
        return nftVars[characterID][nftVar];
    }
    function setNftVar(uint256 characterID, uint256 nftVar, uint256 value) public restricted {
        nftVars[characterID][nftVar] = value;
    }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract Promos is Initializable, AccessControlUpgradeable {
    using ABDKMath64x64 for int128;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    function initialize() public initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function migrateTo_f73df27() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        firstCharacterPromoInGameOnlyFundsGivenInUsd = ABDKMath64x64.divu(
            17220,
            100
        );
    }

    mapping(address => uint256) public bits;
    uint256 public constant BIT_FIRST_CHARACTER = 1;
    uint256 public constant BIT_FOUNDER_SHIELD = 2;
    uint256 public constant BIT_BAD_ACTOR = 4;
    uint256 public constant BIT_LEGENDARY_DEFENDER = 8;

    int128 public firstCharacterPromoInGameOnlyFundsGivenInUsd;

    modifier restricted() {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
        _;
    }

    function setBit(address user, uint256 bit) external restricted {
        bits[user] |= bit;
    }

    function setBits(address[] memory user, uint256 bit) public restricted {
        for(uint i = 0; i < user.length; i++)
            bits[user[i]] |= bit;
    }

    function unsetBit(address user, uint256 bit) public restricted {
        bits[user] &= ~bit;
    }

    function unsetBits(address[] memory user, uint256 bit) public restricted {
        for(uint i = 0; i < user.length; i++)
            bits[user[i]] &= ~bit;
    }

    function getBit(address user, uint256 bit) external view returns (bool) {
        return (bits[user] & bit) == bit;
    }

    function firstCharacterPromoInGameOnlyFundsGivenInUsdAsCents() external view returns (uint256) {
        return firstCharacterPromoInGameOnlyFundsGivenInUsd.mulu(100);
    }

    function setFirstCharacterPromoInGameOnlyFundsGivenInUsdAsCents(
        uint256 _usdCents
    ) external restricted {
        firstCharacterPromoInGameOnlyFundsGivenInUsd = ABDKMath64x64.divu(
            _usdCents,
            100
        );
    }

    function setFirstCharacterPromoInGameOnlyFundsGivenInUsdAsRational(
        uint256 _numerator,
        uint256 _denominator
    ) external restricted {
        firstCharacterPromoInGameOnlyFundsGivenInUsd = ABDKMath64x64.divu(
            _numerator,
            _denominator
        );
    }
}

pragma solidity ^0.6.2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./characters.sol";

contract Garrison is Initializable, IERC721ReceiverUpgradeable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    // STATE
    Characters characters;

    EnumerableSet.AddressSet private supportedTokenTypes;

    mapping(address => EnumerableSet.UintSet) userGarrison;
    mapping(uint256 => address) characterOwner;
    EnumerableSet.UintSet private allCharactersInGarrison;

    event CharacterReceived(uint256 indexed character, address indexed minter);

    function initialize(Characters _characters)
        public
        initializer
    {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        characters = _characters;
    }

    // MODIFIERS
    modifier restricted() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(GAME_ADMIN, msg.sender), "Not admin");
        _;
    }

    modifier isCharacterOwner(uint256 id) {
        require(characterOwner[id] == msg.sender);
        _;
    }

    modifier isInGarrison(uint256 id) {
        require(allCharactersInGarrison.contains(id));
        _;
    }

    // VIEWS
    function getUserCharacters() public view  returns (uint256[] memory tokens) {
        uint256 amount = balanceOf(msg.sender);
        tokens = new uint256[](amount);

        EnumerableSet.UintSet storage storedTokens = userGarrison[msg.sender];

        for (uint256 i = 0; i < amount; i++) {
            uint256 id = storedTokens.at(i);
                tokens[i] = id;
        }
    }

    function balanceOf(address user) public view returns(uint256) {
        return userGarrison[user].length();
    }

    // MUTATIVE
    function sendToGarrison(uint256 id) public {
        characterOwner[id] = msg.sender;
        userGarrison[msg.sender].add(id);
        allCharactersInGarrison.add(id);
        characters.safeTransferFrom(msg.sender, address(this), id);

        emit CharacterReceived(id, msg.sender);
    }

    function redirectToGarrison(address user, uint256 id) restricted external {
        characterOwner[id] = user;
        userGarrison[user].add(id);
        allCharactersInGarrison.add(id);

        emit CharacterReceived(id, user);
    }

    function restoreFromGarrison(uint256 id)
        public
        isCharacterOwner(id)
        isInGarrison(id)
    {
        require(characters.balanceOf(msg.sender) < characters.characterLimit(), "Receiver has too many characters");
        delete characterOwner[id];
        userGarrison[msg.sender].remove(id);
        allCharactersInGarrison.remove(id);
        characters.safeTransferFrom(address(this), msg.sender, id);
    }

    function swapWithGarrison(uint256 plazaId, uint256 garrisonId) external {
      sendToGarrison(plazaId);
      restoreFromGarrison(garrisonId);
    }

    function allowToken(IERC721 _tokenAddress) public restricted {
        supportedTokenTypes.add(address(_tokenAddress));
    }

    function disallowToken(IERC721 _tokenAddress) public restricted {
        supportedTokenTypes.remove(address(_tokenAddress));
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256 _id,
        bytes calldata /* data */
    ) external override returns (bytes4) {
        // NOTE: The contract address is always the message sender.
        address _tokenAddress = msg.sender;

        require(
            supportedTokenTypes.contains(_tokenAddress) &&
                allCharactersInGarrison.contains(_id),
            "Token ID not listed"
        );

        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}

pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract Cosmetics is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    event CosmeticGiven(address indexed owner, uint32 cosmetic, uint32 amount);
    event CosmeticUsed(address indexed owner, uint32 cosmetic, uint32 amount);
    event CosmeticRestored(address indexed owner, uint32 cosmetic, uint32 amount);
    
    event CosmeticGivenByAdmin(address indexed owner, uint32 cosmetic, uint32 amount);
    event CosmeticTakenByAdmin(address indexed owner, uint32 cosmetic, uint32 amount);

    mapping(address => mapping(uint32 => uint32)) public owned;

    mapping(uint32 => bool) internal _cosmeticAvailable;

    uint32 internal constant _noCosmetic = 0;

    function initialize()
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier isAdmin() {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier cosmeticAvailable(uint32 cosmetic) {
         require(_cosmeticAvailable[cosmetic], "Not available");
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier haveCosmetic(uint32 cosmetic, uint32 amount) {
        require(owned[msg.sender][cosmetic] >= amount, "No cosmetic");
        _;
    }

    function giveCosmetic(address buyer, uint32 cosmetic, uint32 amount) public restricted {
        owned[buyer][cosmetic] += amount;
        emit CosmeticGiven(buyer, cosmetic, amount);
    }

    function useCosmetic(uint32 cosmetic, uint32 amount) internal haveCosmetic(cosmetic, amount) cosmeticAvailable(cosmetic) {
        owned[msg.sender][cosmetic] -= amount;
        emit CosmeticUsed(msg.sender, cosmetic, amount);
    }

    function _restoreCosmetic(uint32 cosmetic, uint32 amount) internal {
        owned[msg.sender][cosmetic] += amount;
        emit CosmeticRestored(msg.sender, cosmetic, amount);
    }

    function getCosmeticCount(uint32 cosmetic) public view returns(uint32) {
        return owned[msg.sender][cosmetic];
    }

    function isCosmeticAvailable(uint32 cosmetic) public view returns (bool){
        return _cosmeticAvailable[cosmetic];
    }

    function toggleCosmeticAvailable(uint32 cosmetic, bool available) external isAdmin {
        _cosmeticAvailable[cosmetic] = available;
    }

    function giveCosmeticByAdmin(address receiver, uint32 cosmetic, uint32 amount) external isAdmin cosmeticAvailable(cosmetic) {
        owned[receiver][cosmetic] += amount;
        emit CosmeticGivenByAdmin(receiver, cosmetic, amount);
    }

    function takeCosmeticByAdmin(address target, uint32 cosmetic, uint32 amount) external isAdmin {
        require(owned[target][cosmetic] >= amount, 'Not enough cosmetic');
        owned[target][cosmetic] -= amount;
        emit CosmeticTakenByAdmin(target, cosmetic, amount);
    }
}

pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract Consumables is Initializable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    event ConsumableGiven(address indexed owner, uint32 amount);

    mapping(address => uint32) public owned;
    
    bool internal _enabled;

    function initialize()
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = true;
    }

    modifier isAdmin() {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier itemNotDisabled() {
         require(_enabled, "Item disabled");
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    modifier haveItem(uint32 amount) {
        require(owned[msg.sender] >= amount, "No item");
        _;
    }

    function giveItem(address buyer, uint32 amount) public restricted {
        owned[buyer] += amount;
        emit ConsumableGiven(buyer, amount);
    }

    function consumeItem(uint32 amount) internal haveItem(amount) itemNotDisabled {
        owned[msg.sender] -= amount;
    }

    function getItemCount() public view returns (uint32) {
        return owned[msg.sender];
    }

    function toggleItemCanUse(bool canUse) external isAdmin {
        _enabled = canUse;
    }

    function giveItemByAdmin(address receiver, uint32 amount) external isAdmin {
        owned[receiver] += amount;
    }

    function takeItemByAdmin(address target, uint32 amount) external isAdmin {
        require(owned[target] >= amount, 'Not enough item');
        owned[target] -= amount;
    }

    function itemEnabled() public view returns (bool){
        return _enabled;
    }
}

pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./CBKLand.sol";

contract CBKLandSale is Initializable, AccessControlUpgradeable {

    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");

    CBKLand public cbkLand;
     /* ========== EVENTS ========== */
    event T1Given(address indexed owner, uint256 stamp);
    event T2Given(address indexed owner, uint256 chunkId);
    event T3Given(address indexed owner, uint256 chunkId);
    event T1GivenFree(address indexed owner, uint256 stamp);
    event T2GivenFree(address indexed owner, uint256 chunkId);
    event T3GivenFree(address indexed owner, uint256 chunkId);
    event T1GivenReserved(address indexed reseller, address indexed owner, uint256 chunkId);
    event T2GivenReserved(address indexed reseller, address indexed owner, uint256 chunkId);
    event T3GivenReserved(address indexed reseller, address indexed owner, uint256 chunkId);
    event LandTokenGiven(address indexed reseller, address indexed owner, uint256 tier);

    event ReservedLandClaimed(uint256 indexed reservation, address indexed reseller, address indexed owner, uint256 tier, uint256 chunkId);
    event MassMintReservedLand(address indexed player, address indexed reseller, uint256 chunkId, uint256 tier1, uint256 tier2, bool giveTier3);
    event MassMintReservedChunklessLand(address indexed player, address indexed reseller, uint256 tier1, uint256 tier2,  uint256 tier3);
    event ReservedLandClaimedForPlayer(uint256 indexed reservation, address indexed reseller, address indexed owner, uint256 tier, uint256 chunkId);
    
    /* ========== LAND SALE INFO ========== */
    uint256 private constant NO_LAND = 0;
    uint256 public constant TIER_ONE = 1;
    uint256 public constant TIER_TWO = 2;
    uint256 public constant TIER_THREE = 3;
    uint256 private constant MAX_CHUNK_ID = 9999; // 100 x 100

    struct purchaseInfo {
        address buyer;
        uint256 purchasedTier;
        uint256 stamp; // chunkId or roundrobin stamp
        bool free;
    }

    uint256 private totalSales;
    mapping(uint256 => purchaseInfo) public sales; // Put all sales in an mapping for easier tracking
    mapping(address => purchaseInfo) public purchaseAddressMapping;
    mapping(uint256 => uint256) public availableLand; // Land that is up for sale. 
    mapping(uint256 => uint256) public chunkZoneLandSales;

    /* ========== T1 LAND SALE INFO ========== */
    // T1 land is sold with no exact coordinates commitment and assigned based on round robin
    // once minting is done. For now the player gets a stamp which can reflect PROJECTED land coordinates
    // should it need be.
    uint256 private t1LandsSold;



    /* ========== T2 LAND SALE INFO ========== */
    uint256 private t2LandsSold;
    uint256 private chunksWithT2Land;

    uint256 private _allowedLandSalePerChunk;
    uint256 private _allowedLandOffset; // Max allowed deviation allowed from theoretical average

    // T2 sold per chunk
    mapping(uint256 => uint256) public chunkT2LandSales;


    /* ========== T3 LAND SALE INFO ========== */
    uint256 private t3LandsSold;
    mapping(uint256 => address) public chunkT3LandSoldTo;


    /* ========== RESERVED CHUNKS SALE INFO ========== */
    EnumerableSet.UintSet private reservedChunkIds;

    bool internal _enabled;
    bool internal _reservedEnabled;
    
    mapping(address => EnumerableSet.UintSet) private reservedChunks;
    mapping(address => uint256) private reservedChunksCounter;
    mapping(uint256 => address) private chunksReservedFor;

    // reseller address => land tier => budget
    mapping(address => mapping(uint256 => uint256)) private resellerLandBudget;

    // player reserved land
    uint256 private playerReservedLandAt;
    mapping(address => EnumerableSet.UintSet) private playerReservedLands;
    mapping(uint256 => uint256) private playerReservedLandTier;
    mapping(uint256 => address) private playerReservedLandReseller;
    mapping(uint256 => address) private playerReservedLandForPlayer;
    mapping(uint256 => bool) private playerReservedLandClaimed;
    
    EnumerableSet.UintSet private takenT3Chunks;

    function initialize(CBKLand _cbkLand)
        public
        initializer
    {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _enabled = false;

        _allowedLandOffset = 2;
        _allowedLandSalePerChunk = 99; // At least 1 reserved for T3
        availableLand[TIER_ONE] = 1000; // Placeholder value
        availableLand[TIER_TWO] = 100; // Placeholder value
        availableLand[TIER_THREE] = 10; // Placeholder value

        cbkLand = _cbkLand;
    }

    modifier isAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        _;
    }

    modifier saleAllowed() {
        require(_enabled, "Sales disabled");
        _;
    }

    modifier reservedSaleAllowed() {
        require(_reservedEnabled, "Sales disabled");
        _;
    }

    modifier canPurchase(address buyer) {
        require(purchaseAddressMapping[buyer].purchasedTier == 0, "Already purchased");
        _;
    }

    modifier chunkAvailable(uint256 chunkId) {
        require(chunkId <= MAX_CHUNK_ID, "Chunk not valid");
        require(!reservedChunkIds.contains(chunkId), "Chunk reserved");
        require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "Chunk not available");
        require(_chunkAvailableForT2(chunkId), "Chunk overpopulated");
        _;
    }

    // modifier reservedChunkAvailable(uint256 chunkId) {
    //     require(chunkId <= MAX_CHUNK_ID, "Chunk not valid");
    //     require(reservedChunks[msg.sender].contains(chunkId), "Chunk not reserved");
    //     require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "Chunk not available");
    //     _;
    // }

    // Will not overcomplicate the math on this one. Keeping it simple on purpose for gas cost.
    // Limited to t2 because T3 not many and T1 round robins
    function _chunkAvailableForT2(uint256 chunkId) internal view returns (bool) {
        return chunksWithT2Land == 0 ||
            (chunkT2LandSales[chunkId] + 1 < _allowedLandOffset + t2LandsSold / chunksWithT2Land);
    }

    modifier t3Available(uint256 chunkId) {
        require(_chunkAvailableForT3(chunkId), "T3 not available");
        _;
    }

    function _chunkAvailableForT3(uint256 chunkId) internal view returns (bool) {
        return chunkT3LandSoldTo[chunkId] == address(0);
    }

    modifier tierAvailable(uint256 tier) {
        require(availableLand[tier] > 0, "Tier not available");
        _;
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender), "Not game admin");
    }

    function giveT1Land(address buyer) public saleAllowed canPurchase(buyer) tierAvailable(TIER_ONE) restricted {
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_ONE, t1LandsSold, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        emit T1Given(buyer, t1LandsSold);
        t1LandsSold++;
        availableLand[TIER_ONE]--;
        cbkLand.mint(buyer, TIER_ONE, 0);
    }

    function giveT2Land(address buyer, uint256 chunkId) public saleAllowed canPurchase(buyer) tierAvailable(TIER_TWO) chunkAvailable(chunkId) restricted {
        // First t2 sale
        if(chunkT2LandSales[chunkId] == 0){
            chunksWithT2Land++;
        }

        t2LandsSold++;
        chunkT2LandSales[chunkId]++;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_TWO, chunkId, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_TWO]--;

        emit T2Given(buyer, chunkId);
        cbkLand.mint(buyer, TIER_TWO, chunkId);
    }

    function giveT3Land(address buyer, uint256 chunkId) public saleAllowed canPurchase(buyer) tierAvailable(TIER_THREE) chunkAvailable(chunkId) t3Available(chunkId) restricted {
        t3LandsSold++;
        
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_THREE, chunkId, false);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_THREE]--;
        chunkT3LandSoldTo[chunkId] = buyer;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        takenT3Chunks.add(chunkId);
        emit T3Given(buyer, chunkId);
        cbkLand.mint(buyer, TIER_THREE, chunkId);
    }

    function giveT1LandFree(address buyer) public tierAvailable(TIER_ONE) restricted {
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_ONE, t1LandsSold, true);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        emit T1GivenFree(buyer, t1LandsSold);
        t1LandsSold++;
        availableLand[TIER_ONE]--;
        cbkLand.mint(buyer, TIER_ONE, 0);
    }

    function giveT2LandFree(address buyer, uint256 chunkId) public tierAvailable(TIER_TWO) chunkAvailable(chunkId) restricted {
        // First t2 sale
        if(chunkT2LandSales[chunkId] == 0){
            chunksWithT2Land++;
        }

        t2LandsSold++;
        chunkT2LandSales[chunkId]++;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_TWO, chunkId, true);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_TWO]--;

        emit T2GivenFree(buyer, chunkId);
        cbkLand.mint(buyer, TIER_TWO, chunkId);
    }

    function giveT3LandFree(address buyer, uint256 chunkId) public tierAvailable(TIER_THREE) chunkAvailable(chunkId) t3Available(chunkId) restricted {
        t3LandsSold++;
        
        purchaseAddressMapping[buyer] = purchaseInfo(buyer, TIER_THREE, chunkId, true);
        sales[totalSales++] = purchaseAddressMapping[buyer];
        availableLand[TIER_THREE]--;
        chunkT3LandSoldTo[chunkId] = buyer;
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;
        takenT3Chunks.add(chunkId);
        emit T3GivenFree(buyer, chunkId);
        cbkLand.mint(buyer, TIER_THREE, chunkId);
    }

    // function giveLandToken(address buyer, uint256 tier) public reservedSaleAllowed() {
    //     require(resellerLandBudget[msg.sender][tier] > 0); // will protect against invalid tiers
    //     resellerLandBudget[msg.sender][tier]--;
    //     cbkLand.mintLandToken(msg.sender, buyer, tier);
    //     emit LandTokenGiven(msg.sender, buyer, tier);
    // }

    // function getResellerBudget(address reseller) public view returns (uint256 t1, uint256 t2, uint256 t3) {
    //     t1 = resellerLandBudget[reseller][TIER_ONE];
    //     t2 = resellerLandBudget[reseller][TIER_TWO];
    //     t3 = resellerLandBudget[reseller][TIER_THREE];
    // }

    // function setResellerBudget(address reseller, uint256 t1, uint256 t2, uint256 t3) public restricted {
    //     resellerLandBudget[reseller][TIER_ONE] = t1;
    //     resellerLandBudget[reseller][TIER_TWO] = t2;
    //     resellerLandBudget[reseller][TIER_THREE] = t3;
    // }

    // Solidity hates polymorphism for this particular function
    function giveT1LandReservedBulk(address[] memory players, address reseller) public restricted {
        for (uint256 i = 0; i < players.length; i++) {
            giveT1LandReserved(players[i], reseller);
        }
    }

    function giveT1LandReserved(address player, address reseller) public restricted {
        uint256 rcLength = reservedChunks[reseller].length();
        require(rcLength > 0, "no reserved chunks");
        uint256 counter = reservedChunksCounter[reseller];
        for(uint256 i = counter; i < counter + rcLength; i++){
            uint256 cId = reservedChunks[reseller].at(uint256(i % rcLength));
            // it's actually a T1, but we will play on the T2 because population is shared
            if(chunkT2LandSales[cId] < _allowedLandSalePerChunk) {
                if(chunkT2LandSales[cId] == 0){
                    chunksWithT2Land++;
                }
                chunkT2LandSales[cId]++;
                chunkZoneLandSales[chunkIdToZoneId(cId)]++;
                cbkLand.mint(player, TIER_ONE, cId, reseller);
                emit T1GivenReserved(reseller, player, cId);
                reservedChunksCounter[reseller] = uint256(i + 1);
                return;
            }
        }

        // Could not find a land
        revert();
    }

    // For mass mint
    function massMintReservedLand(address player, address reseller, uint256 chunkId, uint256 tier1, uint256 tier2, bool giveTier3) public restricted {
        require(reservedChunks[reseller].contains(chunkId), "not reserved");
        require(chunkT2LandSales[chunkId] + tier1 + tier2 <= _allowedLandSalePerChunk, "NA");
        require(!giveTier3 || _chunkAvailableForT3(chunkId), "NA2");
    
        if((tier1 + tier2) > 0 && chunkT2LandSales[chunkId] == 0) {
             chunksWithT2Land++;
        }
                
        if(tier1 > 0) {
            cbkLand.massMint(player, TIER_ONE, chunkId, reseller, tier1);
            chunkT2LandSales[chunkId] += tier1;
        }

        if(tier2 > 0) {
            cbkLand.massMint(player, TIER_TWO, chunkId, reseller, tier2);
            chunkT2LandSales[chunkId] += tier2;
        }

        if(giveTier3) {
            chunkT3LandSoldTo[chunkId] = player;
            takenT3Chunks.add(chunkId);
            cbkLand.mint(player, TIER_THREE, chunkId, reseller);
        }

        chunkZoneLandSales[chunkIdToZoneId(chunkId)] += tier1 + tier2 + (giveTier3 ? 1 : 0);
        emit MassMintReservedLand(player, reseller, chunkId, tier1, tier2, giveTier3);
    }

    // For mass mint 
    // Can change chunk id once
    // Call with caution
    function massMintReservedLand(address player, address reseller, uint256 tier1, uint256 tier2, uint256 tier3) public restricted {
        require(reservedChunks[reseller].length() > 0, "no reservation");
                
        if(tier1 > 0) {
            cbkLand.massMint(player, TIER_ONE, 0, reseller, tier1);
        }

        if(tier2 > 0) {
            cbkLand.massMint(player, TIER_TWO, 0, reseller, tier2);
        }

        if(tier3 > 0) {
            cbkLand.massMint(player, TIER_THREE, 0, reseller, tier3);
        }

        emit MassMintReservedChunklessLand(player, reseller, tier1, tier2, tier3);
    }

    // Can be called only from land with reseller address and chunkid 0
    // For T1; assignedChunkId is a dummy param
    function changeLandChunkId(uint256 landId, uint256 assignedChunkid) public {
        require(cbkLand.ownerOf(landId) == msg.sender, "NA1"); // Owns the land
        (uint256 tier, uint256 chunkId, , , address reseller) = cbkLand.get(landId);
        require(chunkId == 0 && reseller != address(0), "NA2"); // Is a reseller land with chunk id 0
        require(assignedChunkid == 0 || reservedChunks[reseller].contains(assignedChunkid), "NA3"); // FE didn't send chunkId or reseller owns the assigned chunkId
        require(tier != TIER_THREE || _chunkAvailableForT3(assignedChunkid), "NA4"); // Not tier 3 or tier 3 available
        require((tier == TIER_ONE && assignedChunkid == 0) || assignedChunkid > 0, "NA5"); // tier 1 or chunkid requested
        require(tier != TIER_TWO || chunkT2LandSales[assignedChunkid] < _allowedLandSalePerChunk, "NA6"); // Not T2 or population allows it

        // T1 => get random reseller chunkId
        if(tier == TIER_ONE) {
            uint256 rcLength = reservedChunks[reseller].length();
            require(rcLength > 0, "no reserved chunks");
            uint256 counter = reservedChunksCounter[reseller];
            for(uint256 i = counter; i < counter + rcLength; i++) {
                uint256 cId = reservedChunks[reseller].at(uint256(i % rcLength));
                if(chunkT2LandSales[cId] < _allowedLandSalePerChunk) {
                    assignedChunkid = cId;
                    reservedChunksCounter[reseller] = uint256(i + 1);
                    break;
                }
            }
        }

        require(assignedChunkid != 0, "NA7"); // Would only happen if T1 && round robin failed; shouldn't

        // T1 and T2 share population
        if(tier != TIER_THREE) {
            if(chunkT2LandSales[assignedChunkid] == 0){
                chunksWithT2Land++;
            }

            chunkT2LandSales[assignedChunkid]++;
        }

        // T3 => tag the land
        if(tier == TIER_THREE) {
            chunkT3LandSoldTo[assignedChunkid] = msg.sender;
            takenT3Chunks.add(assignedChunkid);
        }

        chunkZoneLandSales[chunkIdToZoneId(assignedChunkid)]++;
        cbkLand.updateChunkId(landId, assignedChunkid);
    }

    function giveT1LandReservedBulk(address[] memory players, address reseller, uint256 chunkId) public restricted {
        require(reservedChunks[reseller].contains(chunkId), "not reserved");
        for (uint256 i = 0; i < players.length; i++) {
            giveT1LandReserved(players[i], reseller, chunkId);
        }
    }

    function giveT1LandReserved(address player, address reseller, uint256 chunkId) public restricted {
        require(reservedChunks[reseller].contains(chunkId), "not reserved");
        if(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk) {
            if(chunkT2LandSales[chunkId] == 0){
                chunksWithT2Land++;
            }
            chunkT2LandSales[chunkId]++;
            chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;
            cbkLand.mint(player, TIER_ONE, chunkId, reseller);
            emit T1GivenReserved(reseller, player, chunkId);
             return;
        }
        // Could not find a land
        revert();
    }

    // function giveT2LandReserved(address buyer, uint256 chunkId) public reservedChunkAvailable(chunkId) reservedSaleAllowed() {
    //      if(chunkT2LandSales[chunkId] == 0){
    //         chunksWithT2Land++;
    //     }

    //     chunkT2LandSales[chunkId]++;
    //     chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

    //     emit T2GivenReserved(msg.sender, buyer, chunkId);
    //     cbkLand.mint(buyer, TIER_TWO, chunkId);
    // }

    // function giveT3LandReserved(address buyer, uint256 chunkId) public reservedChunkAvailable(chunkId) t3Available(chunkId) reservedSaleAllowed() {
    //     chunkT3LandSoldTo[chunkId] = buyer;
    //     chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;

    //     emit T3GivenReserved(msg.sender, buyer, chunkId);
    //     cbkLand.mint(buyer, TIER_THREE, chunkId);
    // }

    // Will leave this commented
    // function setLandURI(uint256 landId, string memory uri) public {
    //     (, uint256 chunkId,,) = cbkLand.get(landId);
    //     require(reservedChunks[msg.sender].contains(chunkId), "no access");
    //     cbkLand.setURI(landId, uri);
    // }

    function chunkIdToZoneId(uint256 chunkId) internal pure returns (uint256){
        return 10 * (chunkId / 1000) + (chunkId % 100) / 10;
    }

    function salesAllowed() public view returns (bool){
        return _enabled;
    }

    function reservedSalesAllowed() public view returns (bool){
        return _reservedEnabled;
    }

    function getAllowedLandOffset()  public view returns (uint256){
        return _allowedLandOffset;
    }

    function checkIfChunkAvailable(uint256 tier, uint256 chunkId) public view returns (bool){
        if(reservedChunkIds.contains(chunkId)){
            return false;
        }

        if(chunkId > MAX_CHUNK_ID){
            return false;
        }

        if(tier == TIER_ONE){
            return availableLand[TIER_ONE] > 0;
        }

        if(tier == TIER_TWO){
            return availableLand[TIER_TWO] > 0
                    && chunkT2LandSales[TIER_TWO] < _allowedLandSalePerChunk
                    && _chunkAvailableForT2(chunkId);
        }

        if(tier == TIER_THREE){
            return availableLand[TIER_THREE] > 0
                    && _chunkAvailableForT3(chunkId);
        }

        return false;
    }

    function checkChunkReserved(uint256 chunkId) public view returns (bool){
        return reservedChunkIds.contains(chunkId);
    }

    function getAllZonesPopulation() public view returns (uint256[] memory) {
        uint256[] memory toReturn = new uint256[](100);

        for (uint256 i = 0; i < 100; i++) {
            toReturn[i] = chunkZoneLandSales[i];
        }

        return toReturn;
    }

    function getZonePopulation(uint256[] memory zoneIds) public view returns (uint256[] memory) {
        require(zoneIds.length > 0 && zoneIds.length <= 100, "invalid request");
        uint256[] memory toReturn = new uint256[](zoneIds.length);

        for (uint256 i = 0; i < zoneIds.length; i++) {
            toReturn[i] = chunkZoneLandSales[zoneIds[i]];
        }

        return toReturn;
    }

    function getZoneChunkPopulation(uint256 zoneId) public view returns (uint256[] memory) {
        require(zoneId < 100, "invalid request");
        uint256 zoneX = zoneId % 10;
        uint256 zoneY = zoneId / 10;

        uint256[] memory toReturn = new uint256[](100);
        uint256 counter = 0;

        for(uint256 j = zoneY * 1000; j < zoneY * 1000 + 1000; j += 100) {
            for(uint256 i = zoneX * 10; i < zoneX * 10 + 10; i++) {
                uint256 projectedId = i + j;
                toReturn[counter++] = chunkT2LandSales[projectedId] + (chunkT3LandSoldTo[projectedId] != address(0) ? 1 : 0);
            }
        }

        return toReturn;
    }

    function getChunkPopulation(uint256[] memory chunkIds) public view returns (uint256[] memory) {
        require(chunkIds.length > 0 && chunkIds.length <= 100, "invalid request");
        uint256[] memory toReturn = new uint256[](chunkIds.length);

        for (uint256 i = 0; i < chunkIds.length; i++) {
            toReturn[i] = chunkT2LandSales[chunkIds[i]] + (chunkT3LandSoldTo[chunkIds[i]] != address(0) ? 1 : 0);
        }

        return toReturn;
    }

    function getAvailableLand()  public view returns (uint256, uint256, uint256) {
        return (availableLand[TIER_ONE], availableLand[TIER_TWO], availableLand[TIER_THREE]);
    }

    function getAvailableLandPerChunk()  public view returns (uint256) {
        return _allowedLandSalePerChunk;
    }

    function getSoldLand()  public view returns (uint256, uint256, uint256) {
        return (t1LandsSold, t2LandsSold, t3LandsSold);
    }

    function getPopulatedT2Chunks()  public view returns (uint256) {
        return chunksWithT2Land;
    }

    function getPurchase()  public view returns (uint256, uint256) {
        return (purchaseAddressMapping[msg.sender].purchasedTier, purchaseAddressMapping[msg.sender].stamp);
    }

    function getPurchaseOf(address owner)  public view returns (uint256, uint256) {
        return (purchaseAddressMapping[owner].purchasedTier, purchaseAddressMapping[owner].stamp);
    }

    function getSalesCount() public view returns (uint256){
        return totalSales;
    }

    function getPurchaseBySale(uint256 sale)  public view returns (address, uint256, uint256) {
        return (sales[sale].buyer, sales[sale].purchasedTier, sales[sale].stamp);
    }

    function setSaleAllowed(bool allowed) external isAdmin {
        _enabled = allowed;
    }

    function setReservedSaleAllowed(bool allowed) external isAdmin {
        _reservedEnabled = allowed;
    }

    // do NOT use this for reserve false unless really needed. This doesn't update reseller data
    // the purpose of this function is to provide a cheap way to bulk reserve blocks that don't have resellers
    function setChunksReservation(uint256[] calldata chunkIds, bool reserved) external isAdmin {
        for (uint256 i = 0; i < chunkIds.length; i++) {
            
            if(reserved && !reservedChunkIds.contains(chunkIds[i])) {
                reservedChunkIds.add(chunkIds[i]);
            }

            if(!reserved) {
                reservedChunkIds.remove(chunkIds[i]);
            }
        }
    }

    // be careful with forced, a chunkId may still remain attached to an existing reseller
    // forced should not be used unless something is really wrong
    function setChunksReservationInfo(uint256[] calldata chunkIds, address reserveFor, bool reserved, bool forced) external isAdmin {
        for (uint256 i = 0; i < chunkIds.length; i++) {
            require (chunkIds[i] != 0, "0 NA"); // chunk id 0 shouldn't be reserved
            require(!reserved || (forced || chunksReservedFor[chunkIds[i]] == address(0)), "AS"); // already reserved, request has to be forced to avoid issues
            
            if(reserved && !reservedChunkIds.contains(chunkIds[i])) {
                reservedChunkIds.add(chunkIds[i]);
            }

            if(!reserved) {
                reservedChunkIds.remove(chunkIds[i]);
                chunksReservedFor[chunkIds[i]] = address(0);
                 reservedChunks[reserveFor].remove(chunkIds[i]);
            }

            if(reserved && !reservedChunks[reserveFor].contains(chunkIds[i])) {
                reservedChunks[reserveFor].add(chunkIds[i]);
                chunksReservedFor[chunkIds[i]] = reserveFor;
            }
        }
    }

    function givePlayersReservedLand(address[] calldata players, address reseller, uint256 tier) external isAdmin {
        for (uint256 i = 0; i < players.length; i++) {
            playerReservedLands[players[i]].add(++playerReservedLandAt);
            playerReservedLandTier[playerReservedLandAt] = tier;
            playerReservedLandReseller[playerReservedLandAt] = reseller;
            playerReservedLandForPlayer[playerReservedLandAt] = players[i];
        }
    }

    function getPlayerReservedLand(address player) public view returns(uint256[] memory t2Reservations, uint256[] memory t3Reservations) {
        uint256 amount = playerReservedLands[player].length();
        uint256 t2Count = 0;
        uint256 t3Count = 0;
         for (uint256 i = 0; i < amount; i++) {
            uint256 reservation = playerReservedLands[player].at(i);
            uint256 reservedTier = playerReservedLandTier[reservation];
           if(reservedTier == 2) {
               t2Count++;
           }
           else if(reservedTier == 3) {
               t3Count++;
           }
        }

        if(t2Count == 0 && t3Count == 0) {
            return (new uint256[](0), new uint256[](0));
        }

        t2Reservations = new uint256[](t2Count); 
        t3Reservations = new uint256[](t3Count); 
        t2Count = 0;
        t3Count = 0;

        for (uint256 i = 0; i < amount; i++) {
            uint256 reservation = playerReservedLands[player].at(i);
            uint256 reservedTier = playerReservedLandTier[reservation];
           if(reservedTier == 2) {
               t2Reservations[t2Count++] = reservation;
           }
           else if(reservedTier == 3) {
               t3Reservations[t3Count++] = reservation;
           }
        }
    }

    function getChunksOfReservations(uint256 reservationId) public view returns (uint256[] memory chunkIds) {
        address reseller = playerReservedLandReseller[reservationId];
        return getChunksOfReseller(reseller);
    }

    function getInfoOfReservation(uint256 reservationId) public view returns (address player, address reseller, uint256 tier, bool claimed) {
        return (playerReservedLandForPlayer[reservationId], playerReservedLandReseller[reservationId], playerReservedLandTier[reservationId], playerReservedLandClaimed[reservationId]);
    }

    function getChunksOfReseller(address reservedFor) public view  returns (uint256[] memory chunkIds) {
        uint256 amount = reservedChunks[reservedFor].length();
        chunkIds = new uint256[](amount);

        uint256 index = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = reservedChunks[reservedFor].at(i);
                chunkIds[index++] = id;
        }
    }

    function claimPlayerReservedLand(uint256 reservation, uint256 chunkId, uint256 tier) public reservedSaleAllowed {
        require(tier != 1, "NT1");
        require(playerReservedLandClaimed[reservation] == false, "AC"); // already claimed
        require(playerReservedLands[msg.sender].contains(reservation), "IR"); // invalid reservation
        require(playerReservedLandTier[reservation] == tier, "IT"); // invalid tier
        address reseller = playerReservedLandReseller[reservation];
        require(reservedChunks[reseller].contains(chunkId), "IR2"); // invalid reseller

        if(tier == 3) {
            require(_chunkAvailableForT3(chunkId), "T3 NA"); 
            chunkT3LandSoldTo[chunkId] = msg.sender;
            takenT3Chunks.add(chunkId);
        }

        if(tier == 2) {
            require(chunkT2LandSales[chunkId] < _allowedLandSalePerChunk, "T2 NA");
            if(chunkT2LandSales[chunkId] == 0){
                chunksWithT2Land++;
            }
            chunkT2LandSales[chunkId]++;
        }
        
        chunkZoneLandSales[chunkIdToZoneId(chunkId)]++;
        playerReservedLands[msg.sender].remove(reservation);
        playerReservedLandClaimed[reservation] = true;
        cbkLand.mint(msg.sender, tier, chunkId, reseller);
        emit ReservedLandClaimed(reservation, reseller, msg.sender, tier, chunkId);
    }


    
    function massClaimReservationsForPlayer(address player, uint256[] calldata reservations) external isAdmin {
        for (uint256 i = 0; i < reservations.length; i++) {
            uint256 reservation = reservations[i];
            require(playerReservedLandClaimed[reservation] == false, "AC"); // already claimed
            require(playerReservedLands[player].contains(reservation), "IR"); // invalid reservation
            address reseller = playerReservedLandReseller[reservation];
            uint256 rcLength = reservedChunks[reseller].length();
            require(rcLength > 0, "no reserved chunks");
            
            uint256 assignedChunkid = 0;
            uint256 reservedTier = playerReservedLandTier[reservation];
            
            require(reservedTier == TIER_TWO || reservedTier == TIER_THREE, "NA");

            uint256 counter = reservedChunksCounter[reseller];
            for(uint256 i = counter; i < counter + rcLength; i++) {
                uint256 cId = reservedChunks[reseller].at(uint256(i % rcLength));
                if(reservedTier == TIER_TWO) { // T2, find a spot with enough population
                    if(chunkT2LandSales[cId] < _allowedLandSalePerChunk) {
                        assignedChunkid = cId;
                        reservedChunksCounter[reseller] = uint256(i + 1);
                        break;
                    }
                }
                else if(!takenT3Chunks.contains(cId)) { // This is a T3, find a chunk that isn't claimed as T3
                    assignedChunkid = cId;
                     reservedChunksCounter[reseller] = uint256(i + 1);
                    break;
                }
                
            }

            require(assignedChunkid != 0, "NA");

            if(reservedTier == TIER_TWO) {
                if(chunkT2LandSales[assignedChunkid] == 0){
                    chunksWithT2Land++;
                }
                chunkT2LandSales[assignedChunkid]++;
            }
            else {
                chunkT3LandSoldTo[assignedChunkid] = player;
                takenT3Chunks.add(assignedChunkid);
            }

            playerReservedLands[player].remove(reservation);
            playerReservedLandClaimed[reservation] = true;
            cbkLand.mint(player, reservedTier, assignedChunkid, reseller);
            chunkZoneLandSales[chunkIdToZoneId(assignedChunkid)]++;
            emit ReservedLandClaimedForPlayer(reservation, reseller, player, reservedTier, assignedChunkid);
        }
    }

    function getResellerOfChunk(uint256 chunkId) public view  returns (address reservedFor) {
        reservedFor = chunksReservedFor[chunkId];
    }

    function getReservedChunksIds() public view  returns (uint256[] memory chunkIds) {
        uint256 amount = reservedChunkIds.length();
        chunkIds = new uint256[](amount);

        uint256 index = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = reservedChunkIds.at(i);
                chunkIds[index++] = id;
        }
    }

    function getTakenT3Chunks() public view  returns (uint256[] memory chunkIds) {
        uint256 amount = takenT3Chunks.length();
        chunkIds = new uint256[](amount);

        uint256 index = 0;
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = takenT3Chunks.at(i);
                chunkIds[index++] = id;
        }
    }

    function setAllowedLandOffset(uint256 allowedOffset) external isAdmin {
        _allowedLandOffset = allowedOffset;
    }

    function setAllowedLandPerChunk(uint256 allowedLandSalePerChunk) external isAdmin {
        _allowedLandSalePerChunk = allowedLandSalePerChunk;
    }

    function setAvailableLand(uint256 tier, uint256 available) external isAdmin {
        require(tier >= TIER_ONE && tier <= TIER_THREE, "Invalid tier");
        availableLand[tier] = available;
    }

    function getReservationAt() public view returns (uint256) {
        return playerReservedLandAt;
    }

    // function updateResellerOfReservation(uint256[] calldata ids, address reseller) external isAdmin {
    //     for (uint256 i = 0; i < ids.length; i++) {
    //         playerReservedLandReseller[ids[i]] = reseller;
    //     }
    // }

    // Do not use forced unless really needed. If used, preferable don't update population
    // Do NOT use with T3
    // function updateLandChunkIdBulk(uint256[] calldata landIds, uint256 fromChunkId, uint256 toChunkId, bool updateToPopulation, bool forced) external isAdmin {
    //     require(forced || cbkLand.landsBelongToChunk(landIds, fromChunkId), "NA");

    //     if(updateToPopulation) {
    //         uint256 populationFrom = chunkT2LandSales[fromChunkId];
    //         uint256 populationTo = chunkT2LandSales[toChunkId];
    //         uint256 populationChange = landIds.length;

    //         if(populationFrom - populationChange < 0) {
    //             require(forced, "NA2"); // forced or don't allow. Something is wrong.
    //             populationChange = populationFrom; // can't have negative population
    //         }

    //         if(populationTo + populationChange > _allowedLandSalePerChunk) {
    //             require(forced, "NA3"); // forced or don't allow. Something is wrong. No reset on populationChange
    //         }

    //         chunkT2LandSales[fromChunkId] -= populationChange;
    //         chunkZoneLandSales[chunkIdToZoneId(fromChunkId)] -= populationChange;

    //         chunkT2LandSales[toChunkId] += populationChange;
    //         chunkZoneLandSales[chunkIdToZoneId(toChunkId)] += populationChange;
    //     }

    //     cbkLand.updateChunkId(landIds, toChunkId);
    // }
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./util.sol";

contract CBKLand is Initializable, ERC721Upgradeable, AccessControlUpgradeable {

    bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
    bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");

    // Land specific
    uint256 public constant LT = 0; // Land Tier
    uint256 public constant LC = 1; // Land Chunk Id
    uint256 public constant LX = 2; // Land Coordinate X
    uint256 public constant LY = 3; // Land Coordinate Y
    

    event LandMinted(address indexed minter, uint256 id, uint256 tier, uint256 chunkId);
    event LandTransfered(address indexed from, address indexed to, uint256 id);
    event LandTokenMinted(address indexed reseller, address indexed minter, uint256 id, uint256 tier);
    event LandMintedWithReseller(address indexed minter, uint256 id, uint256 tier, uint256 chunkId, address reseller);
    event LandChunkIdUpdated(uint256 indexed id, uint256 chunkId);

    // TotalLand
    uint256 landMinted;
    // Avoiding structs for stats
    mapping(uint256 => mapping(uint256 => uint256)) landData;

    mapping(uint256 => mapping(uint256 => string)) landStrData;

    uint256 public constant LBT = 0; // Land is a Token, it will have its chunkId updated later
    mapping(uint256 => mapping(uint256 => bool)) landBoolData;

    uint256 public constant LAR = 0; // Land Reseller, the one who minted the token
    mapping(uint256 => mapping(uint256 => address)) landAddressData;

    uint256 public constant TSU = 0; // URI of a tier. Will put this in land NFT because it kinda belongs here
    mapping(uint256 => mapping(uint256 => string)) tierStrData;

    function initialize () public initializer {
        __ERC721_init("CryptoBladesKingdoms Land", "CBKL");
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(GAME_ADMIN, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NA");
    }

     // tier, chunkid, x, y, reseller address
    function get(uint256 id) public view returns (uint256, uint256, uint256, uint256, address) {
        return (landData[id][LT], landData[id][LC], landData[id][LX], landData[id][LY], landAddressData[id][LAR]);
    }

    function getOwned(address owner) public view returns (uint256[] memory ownedIds) {
        uint256 ownedLandCount = balanceOf(owner);
        ownedIds = new uint256[](ownedLandCount);
         for(uint256 i = 0; i < ownedLandCount; i++) {
             ownedIds[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    function getLandReseller(uint256 land) public view returns (address) {
        return landAddressData[land][LAR];
    }

    // DO NOT call directly outside the logic of CBKLandSale to avoid breaking tier and chunk logic
    function mint(address minter, uint256 tier, uint256 chunkId) public restricted {
        uint256 tokenID = landMinted++;
        
        landData[tokenID][LT] = tier;
        landData[tokenID][LC] = chunkId;
        //landData[tokenID][LX] = x; // not yet
        //landData[tokenID][LY] = y; // not yet
        
        _mint(minter, tokenID);
        emit LandMinted(minter, tokenID, tier, chunkId);
    }

    function mint(address minter, uint256 tier, uint256 chunkId, address reseller) public restricted {
        uint256 tokenID = landMinted++;
        
        landData[tokenID][LT] = tier;
        landData[tokenID][LC] = chunkId;
        //landData[tokenID][LX] = x; // not yet
        //landData[tokenID][LY] = y; // not yet
        
        landAddressData[tokenID][LAR] = reseller;

        _mint(minter, tokenID);
        emit LandMintedWithReseller(minter, tokenID, tier, chunkId, reseller);
    }

    function massMint(address minter, uint256 tier, uint256 chunkId, address reseller, uint256 quantity) public restricted {
        for(uint256 i = 0; i < quantity; i++) {
            mint(minter, tier, chunkId, reseller);
        }
    }

    function updateChunkId(uint256 id, uint256 chunkId) public restricted {
        landData[id][LC] = chunkId;
        emit LandChunkIdUpdated(id, chunkId);
    }

    function updateChunkId(uint256[] memory ids, uint256 chunkId) public restricted {
        for(uint256 i = 0; i < ids.length; i++) {
            updateChunkId(ids[i], chunkId);
        }
    }

    // Helper function for bulk moving land without having to jump chains
    function landsBelongToChunk(uint256[] memory ids, uint256 chunkId) public view returns (bool) {
        for(uint256 i = 0; i < ids.length; i++) {
            if(landData[ids[i]][LC] != chunkId) {
                return false;
            }

            if(ids[i] > landMinted) {
                return false;
            }
        }

        return true;
    }

    function getLandTierURI(uint256 id) public view returns (string memory uri) {
       (uint256 tier,,,,) = get(id);
        return getTierURI(tier);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return getLandTierURI(id);
    }

    function getTierURI(uint256 tier) public view returns (string memory uri) {
        return tierStrData[tier][TSU];
    }

    function setTierStr(uint256 tier, uint256 index, string memory val) public restricted {
        tierStrData[tier][index] = val;
    }

    function getLandTier(uint256 id) public view returns (uint256) {
        return landData[id][LT];
    }
}

pragma solidity ^0.6.5;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IRandoms.sol";
import "./shields.sol";
import "./Consumables.sol";
import "./Cosmetics.sol";
import "./weapons.sol";
import "./cryptoblades.sol";
import "./CBKLandSale.sol";

contract Blacksmith is Initializable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;
    /* ========== CONSTANTS ========== */

    bytes32 public constant GAME = keccak256("GAME");

    uint256 public constant ITEM_WEAPON_RENAME = 1;
    uint256 public constant ITEM_CHARACTER_RENAME = 2;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_FIRE = 3;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_EARTH = 4;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_WATER = 5;
    uint256 public constant ITEM_CHARACTER_TRAITCHANGE_LIGHTNING = 6;
    uint256 public constant ITEM_COSMETIC_WEAPON = 7; // series
    uint256 public constant ITEM_COSMETIC_CHARACTER = 8; // series
    uint256 public constant ITEM_SHIELD = 9;

    uint256 public constant NUMBERPARAMETER_GIVEN_TICKETS = uint256(keccak256("GIVEN_TICKETS"));
    uint256 public constant NUMBERPARAMETER_SPENT_TICKETS = uint256(keccak256("SPENT_TICKETS"));

    uint256 public constant LINK_SKILL_ORACLE_2 = 1; // technically second skill oracle (it's separate)
    uint256 public constant LINK_KING_ORACLE = 2;

    /* ========== STATE VARIABLES ========== */

    Weapons public weapons;
    IRandoms public randoms;

    mapping(address => uint32) public tickets;

    Shields public shields;
    CryptoBlades public game;


    // keys: ITEM_ constant
    mapping(uint256 => address) public itemAddresses;
    mapping(uint256 => uint256) public itemFlatPrices;

    mapping(uint256 => uint256) public numberParameters;

    mapping(uint256 => mapping(uint256 => uint256)) public itemSeriesFlatPrices;
    CBKLandSale public cbkLandSale;
    // ERC20 => tier => price
    mapping(uint256 => mapping(uint256 => uint256)) public landPrices;
    mapping(uint256 => address) currencies;

    mapping(uint256 => address) public links;

    /* ========== INITIALIZERS AND MIGRATORS ========== */

    function initialize(Weapons _weapons, IRandoms _randoms)
        public
        initializer
    {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        weapons = _weapons;
        randoms = _randoms;
    }

    function migrateRandoms(IRandoms _newRandoms) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        randoms = _newRandoms;
    }

    function migrateTo_61c10da(Shields _shields, CryptoBlades _game) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        shields = _shields;
        game = _game;
    }

    function migrateTo_16884dd(
        address _characterRename,
        address _weaponRename,
        address _charFireTraitChange,
        address _charEarthTraitChange,
        address _charWaterTraitChange,
        address _charLightningTraitChange
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
        itemAddresses[ITEM_WEAPON_RENAME] = _weaponRename;
        itemAddresses[ITEM_CHARACTER_RENAME] = _characterRename;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_FIRE] = _charFireTraitChange;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_EARTH] = _charEarthTraitChange;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_WATER] = _charWaterTraitChange;
        itemAddresses[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING] = _charLightningTraitChange;

        itemFlatPrices[ITEM_WEAPON_RENAME] = 0.1 ether;
        itemFlatPrices[ITEM_CHARACTER_RENAME] = 0.1 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE] = 0.2 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH] = 0.2 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER] = 0.2 ether;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING] = 0.2 ether;
    }

    function migrateTo_bcdf4c(CBKLandSale _cbkLandSale) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        cbkLandSale = _cbkLandSale;
    }

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    function recoverToken(address tokenAddress, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    // function spendTicket(uint32 _num) external {
    //     require(_num > 0);
    //     require(tickets[msg.sender] >= _num, "Not enough tickets");
    //     tickets[msg.sender] -= _num;
    //     numberParameters[NUMBERPARAMETER_SPENT_TICKETS] += _num;

    //     for (uint256 i = 0; i < _num; i++) {
    //         weapons.mint(
    //             msg.sender,
    //             // TODO: Ensure no exploiting possible
    //         );
    //     }
    // }

    function giveTicket(address _player, uint32 _num) external onlyGame {
        tickets[_player] += _num;
        numberParameters[NUMBERPARAMETER_GIVEN_TICKETS] += _num;
    }

    function purchaseShield() public {
        Promos promos = game.promos();
        uint256 BIT_LEGENDARY_DEFENDER = promos.BIT_LEGENDARY_DEFENDER();

        require(!promos.getBit(msg.sender, BIT_LEGENDARY_DEFENDER), "Limit 1");
        require(itemFlatPrices[ITEM_SHIELD] > 0);
        promos.setBit(msg.sender, BIT_LEGENDARY_DEFENDER);
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_SHIELD]);
        shields.mintForPurchase(msg.sender);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGame() {
        require(hasRole(GAME, msg.sender), "Only game");
        _;
    }

    modifier isAdmin() {
         _isAdmin();
        _;
    }
    
    function _isAdmin() internal view {
         require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
    }

    /* ========== Generic Getters ========== */

    function getAddressOfItem(uint256 itemIndex) public view returns(address) {
        return itemAddresses[itemIndex];
    }

    function getFlatPriceOfItem(uint256 itemIndex) public view returns(uint256) {
        return itemFlatPrices[itemIndex];
    }

    function getFlatPriceOfSeriesItem(uint256 itemIndex, uint256 seriesIndex) public view returns(uint256) {
        return itemSeriesFlatPrices[itemIndex][seriesIndex];
    }

    function getCurrency(uint256 currency) public view returns (address) {
        return currencies[currency];
    }

    function getLink(uint256 linkId) public view returns (address) {
        return links[linkId];
    }

    /* ========== Generic Setters ========== */

    function setAddressOfItem(uint256 itemIndex, address to) external isAdmin {
        itemAddresses[itemIndex] = to;
    }

    function setFlatPriceOfItem(uint256 itemIndex, uint256 flatWeiPrice) external isAdmin {
        itemFlatPrices[itemIndex] = flatWeiPrice;
    }

    function setFlatPriceOfItemSeries(uint256 itemIndex,
        uint256[] calldata seriesIndices,
        uint256[] calldata seriesPrices
    ) external isAdmin {
        for(uint i = 0; i < seriesIndices.length; i++) {
            itemSeriesFlatPrices[itemIndex][seriesIndices[i]] = seriesPrices[i];
        }
    }

    function setCurrency(uint256 currency, address currencyAddress, bool forced) external isAdmin {
        require(currency > 0 && (forced || currencies[currency] == address(0)), 'used');
        currencies[currency] = currencyAddress;
    }

    function setLink(uint256 linkId, address linkAddress) external isAdmin {
        links[linkId] = linkAddress;
    }

    /* ========== Character Rename ========== */

    function setCharacterRenamePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        itemFlatPrices[ITEM_CHARACTER_RENAME] = newPrice;
    }

    function characterRenamePrice() public view returns (uint256){
        return itemFlatPrices[ITEM_CHARACTER_RENAME];
    }

    function purchaseCharacterRenameTag(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_RENAME], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_RENAME]);
        Consumables(itemAddresses[ITEM_CHARACTER_RENAME]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterRenameTagDeal(uint256 paying) public { // 4 for the price of 3
        require(paying == itemFlatPrices[ITEM_CHARACTER_RENAME] * 3, 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_RENAME] * 3);
        Consumables(itemAddresses[ITEM_CHARACTER_RENAME]).giveItem(msg.sender, 4);
    }

    /* ========== Weapon Rename ========== */

    function setWeaponRenamePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        itemFlatPrices[ITEM_WEAPON_RENAME] = newPrice;
    }

    function weaponRenamePrice() public view returns (uint256){
        return itemFlatPrices[ITEM_WEAPON_RENAME];
    }

    function purchaseWeaponRenameTag(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_WEAPON_RENAME], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_WEAPON_RENAME]);
        Consumables(itemAddresses[ITEM_WEAPON_RENAME]).giveItem(msg.sender, 1);
    }

    function purchaseWeaponRenameTagDeal(uint256 paying) public { // 4 for the price of 3
        require(paying == itemFlatPrices[ITEM_WEAPON_RENAME] * 3, 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_WEAPON_RENAME] * 3);
        Consumables(itemAddresses[ITEM_WEAPON_RENAME]).giveItem(msg.sender, 4);
    }

     /* ========== Character Trait Change ========== */

     function setCharacterTraitChangePrice(uint256 newPrice) external isAdmin {
        require(newPrice > 0, 'invalid price');
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE] = newPrice;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH] = newPrice;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER] = newPrice;
        itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING] = newPrice;
    }

     function characterTraitChangePrice() public view returns (uint256){
        return itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE];
    }

    function purchaseCharacterFireTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_FIRE]);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_FIRE]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterEarthTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_EARTH]);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_EARTH]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterWaterTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_WATER]);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_WATER]).giveItem(msg.sender, 1);
    }

    function purchaseCharacterLightningTraitChange(uint256 paying) public {
        require(paying == itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemFlatPrices[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING]);
        Consumables(itemAddresses[ITEM_CHARACTER_TRAITCHANGE_LIGHTNING]).giveItem(msg.sender, 1);
    }


    /* ========== Weapon cosmetics ========== */
    function setWeaponCosmeticPrice(uint32 cosmetic, uint256 newPrice) external isAdmin {
        require(cosmetic > 0 && newPrice > 0, 'invalid request');
        itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic] = newPrice;
    }

     function getWeaponCosmeticPrice(uint32 cosmetic) public view returns (uint256){
        return itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic];
    }

    function purchaseWeaponCosmetic(uint32 cosmetic, uint256 paying) public {
        require(paying > 0 && paying == itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemSeriesFlatPrices[ITEM_COSMETIC_WEAPON][cosmetic]);
        Cosmetics(itemAddresses[ITEM_COSMETIC_WEAPON]).giveCosmetic(msg.sender, cosmetic, 1);
    }

    /* ========== Character cosmetics ========== */
    function setCharacterCosmeticPrice(uint32 cosmetic, uint256 newPrice) external isAdmin {
        require(cosmetic > 0 && newPrice > 0, 'invalid request');
        itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic] = newPrice;
    }

     function getCharacterCosmeticPrice(uint32 cosmetic) public view returns (uint256){
        return itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic];
    }

    function purchaseCharacterCosmetic(uint32 cosmetic, uint256 paying) public {
        require(paying > 0 && paying == itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic], 'Invalid price');
        game.payContractTokenOnly(msg.sender, itemSeriesFlatPrices[ITEM_COSMETIC_CHARACTER][cosmetic]);
        Cosmetics(itemAddresses[ITEM_COSMETIC_CHARACTER]).giveCosmetic(msg.sender, cosmetic, 1);
    }

    /* ========== CBK Land sale ========== */

    event CBKLandPurchased(address indexed owner, uint256 tier, uint256 price, uint256 currency);

    function purchaseT1CBKLand(uint256 paying, uint256 currency) public {
        uint256 price = getCBKLandPrice(cbkLandSale.TIER_ONE(), currency);
        require(paying > 0 && price == paying, 'Invalid price');
        payCurrency(msg.sender, price, currency);
        cbkLandSale.giveT1Land(msg.sender);
        emit CBKLandPurchased(msg.sender, cbkLandSale.TIER_ONE(), price, currency);
    }

    function purchaseT2CBKLand(uint256 paying, uint256 chunkId, uint256 currency) public {
        uint256 price = getCBKLandPrice(cbkLandSale.TIER_TWO(), currency);
        require(paying > 0 && price == paying,  'Invalid price');
        payCurrency(msg.sender, price, currency);
        cbkLandSale.giveT2Land(msg.sender, chunkId);
        emit CBKLandPurchased(msg.sender, cbkLandSale.TIER_TWO(), price, currency);
    }

    function purchaseT3CBKLand(uint256 paying, uint256 chunkId, uint256 currency) public {
        uint256 price = getCBKLandPrice(cbkLandSale.TIER_THREE(), currency);
        require(paying > 0 && price == paying, 'Invalid price');
        payCurrency(msg.sender, price, currency);
        cbkLandSale.giveT3Land(msg.sender, chunkId);
        emit CBKLandPurchased(msg.sender, cbkLandSale.TIER_THREE(), price, currency);
    }

    function getCBKLandPrice(uint256 tier, uint256 currency) public view returns (uint256){
        return landPrices[currency][tier] * getOracledTokenPerUSD(currency);
    }

    function getOracledTokenPerUSD(uint256 currency) public view returns (uint256) {
        if(currency == 0) {
            return IPriceOracle(links[LINK_SKILL_ORACLE_2]).currentPrice();
        }
        else {
            return IPriceOracle(links[LINK_KING_ORACLE]).currentPrice();
        }
    }

    function setCBKLandPrice(uint256 tier, uint256 newPrice, uint256 currency) external isAdmin {
        require(newPrice > 0, 'invalid price');
        require(tier >= cbkLandSale.TIER_ONE() && tier <= cbkLandSale.TIER_THREE(), "Invalid tier");
        landPrices[currency][tier] = newPrice;
    }

    function payCurrency(address payer, uint256 paying, uint256 currency) internal {
        if(currency == 0){
             game.payContractTokenOnly(payer, paying, true);
        }
        else {
            IERC20(currencies[currency]).transferFrom(payer, address(this), paying);
        }
    }
}