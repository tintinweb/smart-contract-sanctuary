//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./chainlink/RandomNumberConsumer.sol";
import "./CardEngine.sol";

struct Player {
    uint256 enteredAt;
    address addr;
    uint256 reward;
    uint256 entryFee;
    bool shuffled;
}

struct RandReq {
    uint256 height;
    bytes32 reqID;
}

struct Match {
    // Block height when the match was created.
    uint256 createdAt;
    // Player A
    Player playerA;
    // Player B
    Player playerB;
    // The address of the player who plays next.
    address turn;
    // The most recently played card.
    uint256 lastPlay;
    // The block height when the last play occurred.
    uint256 lastPlayAt;
    // Indicates whether the match has ended.
    bool ended;
}

contract Whot is ERC20Burnable, RandomNumberConsumer, CardEngine {
    using SafeMath for uint256;
    address public deployer;
    address public dealer;
    mapping(address => uint256) public minters;
    mapping(address => RandReq) public randRequests;

    uint256 public matchEntryFee;
    uint256 public matchStarterReward;
    uint256 public matchWinnerReward;
    uint256 public matchDealerReward;
    uint256 public loserSlashPct; // e.g 10%, 20% etc
    uint256 public shuffleSlashPct; // e.g 10%, 20% etc
    uint256 public exitSlashPct; // e.g 10%, 20% etc
    uint256 public forfeitureRewardSlashPct; // e.g 10%, 20% etc
    uint256 public matchInactiveAfter;
    uint256 public randRequestExpiryAfter;

    ERC20 link;

    // Player Pool state
    Player[] public playerPool;
    mapping(address => uint256) public playerPoolIndex;

    // Match state
    Match[] public matches;
    mapping(address => uint256) public matchIndex;

    /// @dev Guard to allow access to only deployer
    modifier onlyDeployer() {
        require(msg.sender == deployer, "Caller must be deployer");
        _;
    }

    /// @dev Guard to allow access to only dealer
    modifier onlyDealer() {
        require(msg.sender == dealer, "Caller must be dealer");
        _;
    }

    /// @dev Guard to allow access to only minters
    modifier onlyMinter() {
        require(minters[msg.sender] > 0, "Caller must be minter");
        _;
    }

    /// @dev Emitted when a player enters the player pool.
    /// @param player is the address of the player.
    event Entered(address indexed player);
    event MatchEnded(uint256 indexed matchIdx, address indexed winner);
    event MatchForfieted(uint256 indexed matchIdx, address indexed winner);
    event Played(
        uint256 indexed matchIdx,
        address indexed player,
        uint256 indexed card
    );
    event MintReward(
        uint256 indexed matchIdx,
        address indexed to,
        uint256 indexed amount
    );
    event Exit(address indexed player);
    /// @dev Emitted when a new match was created.
    event NewMatch(
        address indexed playerA,
        address indexed PlayerB,
        uint256 indexed matchIndex
    );

    constructor(
        uint256 initialSupply,
        uint256 _linkFee,
        uint256 _matchEntryFee,
        uint256 _matchStarterReward,
        uint256 _matchWinnerReward,
        uint256 _matchDealerReward,
        uint256 _loserSlashPct,
        uint256 _exitSlashPct,
        uint256 _shuffleSlashPct,
        uint256 _forfeitureRewardSlashPct,
        uint256 _matchInactiveAfter
    )
        ERC20("WHOT CASH", "WHOT")
        RandomNumberConsumer(
            0xa555fC018435bef5A13C6c6870a9d4C11DEC329C,
            0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06,
            0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186,
            _linkFee
        )
    {
        deployer = msg.sender;
        link = ERC20(0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06);
        matchEntryFee = _matchEntryFee;
        matchStarterReward = _matchStarterReward;
        matchWinnerReward = _matchWinnerReward;
        matchDealerReward = _matchDealerReward;
        loserSlashPct = _loserSlashPct;
        exitSlashPct = _exitSlashPct;
        shuffleSlashPct = _shuffleSlashPct;
        forfeitureRewardSlashPct = _forfeitureRewardSlashPct;
        matchInactiveAfter = _matchInactiveAfter;
        _mint(msg.sender, initialSupply);
    }

    /// @notice set the link VRF fee to pay
    /// @param fee is the amount of fee
    function setVRFFee(uint256 fee) public onlyDeployer {
        linkVRFFee = fee;
    }

    /// @notice set the new deployer.
    /// @param newDeployer is the address of the new deployer.
    function setDeployer(address newDeployer) public onlyDeployer {
        deployer = newDeployer;
    }

    /// @notice set the new dealer.
    /// @param newDealer is the address of the new dealer.
    function setDealer(address newDealer) public onlyDeployer {
        dealer = newDealer;
    }

    /// @notice set the loser slash percentage
    /// @param value is the new
    function setLoserSlashPct(uint256 value) public onlyDeployer {
        loserSlashPct = value;
    }

    /// @notice set the exit slash percentage
    /// @param value is the new
    function setExitSlashPct(uint256 value) public onlyDeployer {
        exitSlashPct = value;
    }

    /// @notice set the wasted shuffle slash percentage
    /// @param value is the new
    function setShuffleSlashPct(uint256 value) public onlyDeployer {
        shuffleSlashPct = value;
    }

    /// @notice set the number of blocks to pass before match is inactive state.
    /// @param value is the new
    function setMatchInactiveAfter(uint256 value) public onlyDeployer {
        matchInactiveAfter = value;
    }

    /// @notice set the number of blocks to pass before randomness request is in
    /// expired
    /// @param value is the new
    function setRandRequestExpiryAfter(uint256 value) public onlyDeployer {
        randRequestExpiryAfter = value;
    }

    /// @notice set the end-by-forfeiture reward slash percentage.
    /// @param value is the new
    function setForfeitureRewardSlashPct(uint256 value) public onlyDeployer {
        forfeitureRewardSlashPct = value;
    }

    /// @notice set the match entry fee.
    /// @param amount is the new fee.
    function setMatchEntryFee(uint256 amount) public onlyDeployer {
        matchEntryFee = amount;
    }

    /// @notice set the match starter reward.
    /// @param amount is the new reward amount.
    function setMatchStarterReward(uint256 amount) public onlyDeployer {
        matchStarterReward = amount;
    }

    /// @notice set the match winner reward.
    /// @param amount is the new reward amount.
    function setMatchWinnerReward(uint256 amount) public onlyDeployer {
        matchWinnerReward = amount;
    }

    /// @notice set the match dealer reward.
    /// @param amount is the new reward amount.
    function setMatchDealerReward(uint256 amount) public onlyDeployer {
        matchDealerReward = amount;
    }

    /// @dev return size of player pool.
    function getPlayerPoolSize() public view returns (uint256) {
        return playerPool.length;
    }

    /// @notice Mint the given amount and credit to account.
    /// @param account The beneficiary account.
    /// @param amount The amount to be minted
    function mint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

    /// @notice adds the address as a minter.
    /// @param addr the address of the Whot contract.
    function addMinter(address addr) public onlyDeployer {
        minters[addr] = block.number;
    }

    /// @notice remove the address as a minter.
    /// @param addr the address of the Whot contract.
    function removeMinter(address addr) public onlyDeployer {
        delete minters[addr];
    }

    /// @notice checks if the acct has an active match
    function hasActiveMatch(address acct) public view returns (bool) {
        uint256 idx = matchIndex[acct];
        return (idx > 0) && !matches[idx - 1].ended;
    }

    /// @notice enter enters the sender in to the matchmaking pool.
    /// Rules:
    /// - The player must not be in the pool.
    /// - The player must be in an active match.
    /// - The player must have sufficient WHOT to burn.
    function enter() public {
        require(playerPoolIndex[msg.sender] == 0, "Sender cant be in a pool");
        require(!hasActiveMatch(msg.sender), "Sender cant be in a match");

        // Burn the entry WHOT.
        if (matchEntryFee > 0) {
            burn(matchEntryFee);
        }

        playerPool.push(
            Player(block.number, msg.sender, 0, matchEntryFee, false)
        );
        playerPoolIndex[msg.sender] = playerPool.length;

        emit Entered(msg.sender);
    }

    /// @dev getRandIndex returns a random index between 0 - player pool size.
    /// @param randomNum is the random number to use for random index calculation.
    function getRandIndex(uint256 randomNum) internal view returns (uint256) {
        if (playerPool.length == 1) return 1;
        return randomNum.mod(playerPool.length).add(1);
    }

    /// @dev remove a player by index
    function removePlayerFromPoolAt(uint256 index) internal {
        Player memory target = playerPool[index];
        if (playerPool.length > 1) {
            Player memory last = playerPool[playerPool.length - 1];
            playerPool[index] = last;
            playerPoolIndex[last.addr] = index + 1;
        }
        playerPool.pop();
        delete playerPoolIndex[target.addr];
    }

    /// @notice makeMatch will attempt to create a match or fill
    // an existing match with players. Anyone can call this function
    // to start a match with another player.
    // Note:
    //  - The match starter gets rewarded with small amount of WHOT.
    /// @return true when matches where created.
    function makeMatch() public returns (bool) {
        require(playerPoolIndex[msg.sender] > 0, "Sender must be in pool");
        require(playerPool.length >= 2, "Player pool size must be 2 or more");

        // Find existing request by sender.
        // If no existing request, send a request.
        // If an existing request was found, if it has expired, request new.
        RandReq storage randReq = randRequests[msg.sender];
        if (
            randReq.height == 0 ||
            block.number.sub(randReq.height) >= randRequestExpiryAfter
        ) {
            randRequests[msg.sender] = RandReq(block.number, getRandomNumber());
            playerPool[playerPoolIndex[msg.sender] - 1].shuffled = true;
        }

        // If there is a pending request, check if result has arrived.
        // If not, return false.
        uint256 randomNum = getVRFResult(randReq.reqID);
        if (randomNum == 0) {
            return false;
        }

        // Select player A (sender)
        uint256 idx = playerPoolIndex[msg.sender];
        Player memory playerA = playerPool[idx - 1];
        playerA.reward = matchStarterReward;
        removePlayerFromPoolAt(idx - 1);

        // Select player B
        idx = getRandIndex(uint256(keccak256(abi.encode(randomNum, 1))));
        Player memory playerB = playerPool[idx - 1];
        removePlayerFromPoolAt(idx - 1);

        // Create a match
        Match memory m = Match(
            block.number,
            playerA,
            playerB,
            address(0),
            0,
            0,
            false
        );
        matches.push(m);
        matchIndex[playerA.addr] = matches.length;
        matchIndex[playerB.addr] = matches.length;

        emit NewMatch(playerA.addr, playerB.addr, matches.length);

        delete randRequests[msg.sender];

        return true;
    }

    /// @dev exit the pool before being matched with a player.
    /// The player must currently exist in the pool.
    /// The player will be slashed for exiting.
    function exit() public {
        require(playerPoolIndex[msg.sender] > 0, "Sender must be in pool");
        uint256 playerIdx = playerPoolIndex[msg.sender] - 1;
        Player memory player = playerPool[playerIdx];

        uint256 slashPct = exitSlashPct;
        if (player.shuffled) {
            slashPct = slashPct.add(shuffleSlashPct);
        }

        _mint(
            player.addr,
            player.entryFee.sub(player.entryFee.mul(slashPct).div(100))
        );

        removePlayerFromPoolAt(playerIdx);
        emit Exit(msg.sender);
    }

    /// @dev returns the number of matches.
    function getNumMatches() public view returns (uint256) {
        return matches.length;
    }

    /// @dev computes reward for a finished match.
    /// @param winner is the player that won.
    /// @param m is the match
    /// @param matchIdx is the match index
    function computeRewards(
        address winner,
        Match memory m,
        uint256 matchIdx
    ) internal {
        // mint reward for winner.
        _mint(winner, matchWinnerReward);
        emit MintReward(matchIdx, winner, matchWinnerReward);

        // mint reward for dealer.
        if (dealer != address(0)) {
            _mint(dealer, matchDealerReward);
            emit MintReward(matchIdx, dealer, matchDealerReward);
        }

        // mint reward for match maker.
        if (m.playerA.reward > 0) {
            _mint(m.playerA.addr, m.playerA.reward);
            emit MintReward(matchIdx, m.playerA.addr, m.playerA.reward);
        }
        if (m.playerB.reward > 0) {
            _mint(m.playerB.addr, m.playerB.reward);
            emit MintReward(matchIdx, m.playerB.addr, m.playerB.reward);
        }
    }

    /// @dev returns entry WHOT fee back to loser.
    function returnLoserEntryFee(address winner, Match memory m) internal {
        Player memory loser;
        if (m.playerA.addr == winner) loser = m.playerB;
        else loser = m.playerA;
        _mint(
            loser.addr,
            loser.entryFee.sub(loser.entryFee.mul(loserSlashPct).div(100))
        );
    }

    /// @dev play allows the dealer to play a card on behalf of a player.
    /// @param matchIdx is the index of a match.
    /// @param player is the address of a player.
    /// @param card is the id of the card being played.
    /// @param lastCard indicates whether the card being played is the user's last.
    /// @param forceTurn indicates that the turn check should be ignored.
    function play(
        uint256 matchIdx,
        address player,
        uint256 card,
        bool lastCard,
        bool forceTurn
    ) public onlyDealer {
        require(matchIdx <= matches.length, "Match must exist");
        require(
            matches[matchIdx - 1].playerA.addr == player ||
                matches[matchIdx - 1].playerB.addr == player,
            "Player must be a match player"
        );
        Match storage m = matches[matchIdx - 1];
        require(!m.ended, "Match must not have ended");

        // Revert if its not the turn of the player.
        if (m.turn != player && m.turn != address(0) && !forceTurn)
            revert("Not player turn");

        // Check if the card is valid. Revert for invalid.
        if (!isValidCard(card)) revert("Card is invalid");

        // Check if the card can be played.
        if (!isValidPlay(m.lastPlay, card)) revert("Card is not a valid play");

        // Set last played card and block number.
        m.lastPlay = card;
        m.lastPlayAt = block.number;

        emit Played(matchIdx, player, card);

        // If this was the last card, end match and mint reward.
        if (lastCard) {
            computeRewards(player, m, matchIdx);
            returnLoserEntryFee(player, m);
            m.ended = true;
            matches[matchIdx - 1] = m;
            emit MatchEnded(matchIdx, player);
            return;
        }

        // Set next player turn.
        address otherPlayer = m.playerA.addr;
        if (player == m.playerA.addr) {
            otherPlayer = m.playerB.addr;
        }
        m.turn = getNextPlayer(card, player, otherPlayer);
    }

    /// @dev end an inactive match.
    /// Sender must be a player in the match.
    /// The match must have remained inactive for n blocks.
    /// @param matchIdx is the index of the match.
    function endMatch(uint256 matchIdx) public {
        require(matchIdx <= matches.length, "Match must exist");
        Match storage m = matches[matchIdx - 1];
        require(!m.ended, "Match must not have ended");
        require(
            m.playerA.addr == msg.sender || m.playerB.addr == msg.sender,
            "Sender must be a match player"
        );
        require(
            (m.lastPlayAt > 0 &&
                block.number.sub(m.lastPlayAt) >= matchInactiveAfter) ||
                (m.lastPlayAt == 0 &&
                    block.number.sub(m.createdAt) >= matchInactiveAfter),
            "Inactivity threshold must be reached"
        );

        // Determine winner by opponent forfeiture.
        // If `turn` is non-zero, the opponent who missed their turn is the loser.
        // If `turn` is zero, return player's WHOT - exit slash fee.
        Player memory winner;
        if (m.turn != address(0)) {
            if (m.turn == m.playerA.addr) {
                winner = m.playerB;
            } else {
                winner = m.playerA;
            }

            // Mint entry fee of player A and B and award to winner.
            uint256 totalEntryFee = m.playerA.entryFee.add(m.playerB.entryFee);
            _mint(
                winner.addr,
                totalEntryFee.sub(
                    totalEntryFee.mul(forfeitureRewardSlashPct).div(100)
                )
            );
        } else {
            _mint(
                m.playerA.addr,
                m.playerA.entryFee.sub(
                    m.playerA.entryFee.mul(exitSlashPct).div(100)
                )
            );
            _mint(
                m.playerB.addr,
                m.playerB.entryFee.sub(
                    m.playerB.entryFee.mul(exitSlashPct).div(100)
                )
            );
        }

        emit MatchForfieted(matchIdx, winner.addr);

        // delete the match
        m.ended = true;
        matches[matchIdx - 1] = m;
    }

    /// @dev withdraw LINK from contract.
    function linkWithdraw(address to) external onlyDeployer {
        link.transfer(to, link.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

abstract contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 public linkVRFFee;
    mapping(bytes32 => uint256) private randResults;

    event RandRequested(bytes32 indexed requestId);
    event RandReceived(bytes32 indexed requestId);

    /**
     * Constructor inherits VRFConsumerBase
     */
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyHash;
        linkVRFFee = _fee;
    }

    /// @dev request random number from Link VRF
    /// @return requestId which is a unique ID from LINK.
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= linkVRFFee, "Not enough LINK");
        requestId = requestRandomness(keyHash, linkVRFFee);
        randResults[requestId] = 0;
        emit RandRequested(requestId);
        return requestId;
    }

    /// @dev called when LINK responds with a random number.
    /// @param requestId is the request ID issued at request time.
    /// @param randomness is the random number.
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randResults[requestId] = randomness;
        emit RandReceived(requestId);
    }

    /// @dev get the result for the given request ID
    /// @param requestId is the request ID whose result to return
    function getVRFResult(bytes32 requestId) internal view returns (uint256) {
        return randResults[requestId];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Card {
    Shape shape;
    uint256 number;
}

enum Shape {
    Circle,
    Triangle,
    Star,
    Cross,
    Square,
    Wildcard
}

/// @dev CardEngine providers card logic and information.
contract CardEngine {
    mapping(uint256 => Card) public cards;

    constructor() {
        cards[1] = Card(Shape.Circle, 1);
        cards[2] = Card(Shape.Circle, 2);
        cards[3] = Card(Shape.Circle, 3);
        cards[4] = Card(Shape.Circle, 4);
        cards[5] = Card(Shape.Circle, 5);
        cards[6] = Card(Shape.Circle, 7);
        cards[7] = Card(Shape.Circle, 8);
        cards[8] = Card(Shape.Circle, 10);
        cards[9] = Card(Shape.Circle, 11);
        cards[10] = Card(Shape.Circle, 12);
        cards[11] = Card(Shape.Circle, 13);
        cards[12] = Card(Shape.Circle, 14);

        cards[13] = Card(Shape.Triangle, 1);
        cards[14] = Card(Shape.Triangle, 2);
        cards[15] = Card(Shape.Triangle, 3);
        cards[16] = Card(Shape.Triangle, 4);
        cards[17] = Card(Shape.Triangle, 5);
        cards[18] = Card(Shape.Triangle, 7);
        cards[19] = Card(Shape.Triangle, 8);
        cards[20] = Card(Shape.Triangle, 10);
        cards[21] = Card(Shape.Triangle, 11);
        cards[22] = Card(Shape.Triangle, 12);
        cards[23] = Card(Shape.Triangle, 13);
        cards[24] = Card(Shape.Triangle, 14);

        cards[25] = Card(Shape.Cross, 1);
        cards[26] = Card(Shape.Cross, 2);
        cards[27] = Card(Shape.Cross, 3);
        cards[28] = Card(Shape.Cross, 5);
        cards[29] = Card(Shape.Cross, 7);
        cards[30] = Card(Shape.Cross, 10);
        cards[31] = Card(Shape.Cross, 11);
        cards[32] = Card(Shape.Cross, 13);
        cards[33] = Card(Shape.Cross, 14);

        cards[34] = Card(Shape.Square, 1);
        cards[35] = Card(Shape.Square, 2);
        cards[36] = Card(Shape.Square, 3);
        cards[37] = Card(Shape.Square, 5);
        cards[38] = Card(Shape.Square, 7);
        cards[39] = Card(Shape.Square, 10);
        cards[40] = Card(Shape.Square, 11);
        cards[41] = Card(Shape.Square, 13);
        cards[42] = Card(Shape.Square, 14);

        cards[43] = Card(Shape.Star, 1);
        cards[44] = Card(Shape.Star, 2);
        cards[45] = Card(Shape.Star, 3);
        cards[46] = Card(Shape.Star, 4);
        cards[47] = Card(Shape.Star, 5);
        cards[48] = Card(Shape.Star, 7);
        cards[49] = Card(Shape.Star, 8);

        cards[50] = Card(Shape.Wildcard, 20);
        cards[51] = Card(Shape.Wildcard, 20);
        cards[52] = Card(Shape.Wildcard, 20);
        cards[53] = Card(Shape.Wildcard, 20);
        cards[54] = Card(Shape.Wildcard, 20);
    }

    /// @dev checks whether a card with the given id exists.
    /// @param id is the card's unique ID.
    function isValidCard(uint256 id) public view returns (bool) {
        return cards[id].number > 0;
    }

    /// @dev checks whether the card can become the next pile top given the
    /// current pile top.
    /// @param top is the current pile top.
    /// @param target is the current card top.
    /// @return true if card can be next top or false if not.
    function isValidPlay(uint256 top, uint256 target)
        public
        view
        returns (bool)
    {
        if (top == 0) return true;
        Card memory topCard = cards[top];
        Card memory targetCard = cards[target];
        return (topCard.shape == targetCard.shape ||
            topCard.number == targetCard.number ||
            targetCard.shape == Shape.Wildcard);
    }

    /// @dev returns the next player between cardPlayer and otherPlayer.
    function getNextPlayer(
        uint256 cardPlayed,
        address cardPlayer,
        address otherPlayer
    ) public view returns (address) {
        Card memory card = cards[cardPlayed];
        if (card.number == 1) return cardPlayer;
        if (card.number == 2) return otherPlayer;
        if (card.number == 5) return otherPlayer;
        if (card.number == 8) return cardPlayer;
        if (card.number == 14) return cardPlayer;
        return otherPlayer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}