// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "./SafeMathLib.sol";

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


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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


contract Trollbox {
    using SafeMathLib for uint;

    /**
        Votes are a mapping from choices to weights, plus a metadataHash, which references an arbitrary bit of metadata
        stored on IPFS. The meaning of these choices is not stored on chain, only the index. For example, if  the choices
        are ["BTC", "ETH", "DASH"],  and the user  wants to put 3 votes on BTC, 5 votes on ETH and 4 on DASH, then this
        will be recorded as weights[1]  = 3; weights[2]  = 5; weights[3] = 4; The choices are indexed starting on 1 to
        prevent confusion caused by empty votes.
    **/
    struct Vote {
        mapping(uint => uint) weights;
        bytes32 metadataHash;
    }

    /**
        Rounds occur with some frequency and represent a complete cycle of prediction->resolution. Each round has an id,
        which represents it's location in a linear sequence of rounds of the same type. It stores a mapping of voter
        ids to votes and records the winning option when the round is resolved.
    **/
    struct Round {
        uint roundId;
        mapping (uint => Vote) votes;
        mapping (uint => uint) voteTotals;
        uint winningOption;
    }

    /**
        A tournament is a linear sequence of rounds of the same type. Tournaments are identified by an integer that
        increases sequentially with each tournament. Tournaments also have hash for storing off-chain metadata about the
        tournament. A tournament has a set wavelength and phase, called roundLengthSeconds and startDate, respectively. Each
        tournament also has it's own set of voice credits, which is a mapping from address to balance. The rounds
        mapping takes a round id and spits out a Round struct. The tokenRoundBonus attribute describes how much IERC20 to be
        distributed to the voters each round. The tokenListENS stores the ENS address of a token list that forms the
        choices of the tournament.
    **/
    struct Tournament {
        uint tournamentId;
        bytes32 metadataHash;  // ipfs hash of more verbose description, possibly multimedia
        uint startTime;
        uint roundLengthSeconds;
        uint tokenRoundBonus;
        uint minimumRank;
        uint voiceUBI;   // number of voice credits available to spend each round
        bytes32 tokenListENS;
        address winnerOracle;  // address that sets the winner for a tournament
        mapping (uint => uint) voiceCredits;
        mapping (uint => Round) rounds;
    }

    /**
        An identity is purchased with IERC20 and stores the creation time and a mapping of tournament id to the last round
        id that the identity voted in, which is used for deferred reward computation.
    **/
    struct IdMetadata {
        mapping (uint => uint) lastRoundVoted;
//        uint firstTimeVoted;
//        uint timesVoted;
        uint cumulativeBonus;
        uint rank;
    }

    address public management; // authoritative key that can make important decisions, can be DAO address later
    address public rankManager;
    IERC20 public token;
    IERC721 public identity;

    uint public numTournaments = 0; // a counter to know what index to assign to new tournaments
    bytes32 public siteHash;

    mapping (uint => Tournament) public tournaments; // mapping from tournament id to tournament struct
    mapping (uint => IdMetadata) public identities; // mapping from address to identity struct
    mapping (uint => uint) public tokensWon; // tokensWon[voterId] = fvt-wei owed
    mapping (uint => mapping (uint => mapping (uint => bool))) public syncMap; // syncMap[voterId][tournamentId][roundId] = true/false

    // events for consumption by off chain systems
    event VoteOccurred(uint indexed tournamentId, uint indexed roundId, uint indexed voterId, uint[] choices, uint[] weights, bytes32 metadata);
    event RoundResolved(uint indexed tournamentId, uint roundId, uint winningChoice);
    event TournamentCreated(uint tournamentId, bytes32 metadataHash, uint startTime, uint roundLengthSeconds, uint tokenRoundBonus, uint minimumRank, uint voiceUBI, bytes32 tokenListENS, address winnerOracle);
    event ManagementUpdated(address oldManagement, address newManagement);
    event SiteHashUpdated(bytes32 oldSiteHash, bytes32 newSiteHash);
    event RankUpdated(uint voterId, uint oldRank, uint newRank);
    event RankManagerUpdated(address oldManager, address newManager);
    event TournamentUpdated(uint tournamentId, bytes32 metadataHash, uint tokenRoundBonus, uint minimumRank, uint voiceUBI, bytes32 tokenListENS, address winnerOracle);
    event AccountSynced(uint tournamentId, uint voterId);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address mgmt, address rankMgmt, address id) {
        management = mgmt;
        rankManager = rankMgmt;
        identity = IERC721(id);
    }

    // this function creates a new tournament type, only management can call it
    function createTournament(
        bytes32 hash,
        uint startTime,
        uint roundLengthSeconds,
        uint tokenRoundBonus,
        bytes32 tokenListENS,
        address oracle,
        uint minRank,
        uint voiceUBI) public managementOnly {
        numTournaments = numTournaments.plus(1);
        Tournament storage tournament = tournaments[numTournaments];
        tournament.metadataHash = hash;
        tournament.startTime = startTime == 0 ? block.timestamp : startTime;
        tournament.tournamentId = numTournaments;
        tournament.roundLengthSeconds = roundLengthSeconds;
        tournament.tokenRoundBonus = tokenRoundBonus;
        tournament.minimumRank = minRank;
        tournament.voiceUBI = voiceUBI;
        tournament.tokenListENS = tokenListENS;
        tournament.winnerOracle = oracle;
        emit TournamentCreated(numTournaments, hash, startTime, roundLengthSeconds, tokenRoundBonus, minRank, voiceUBI, tokenListENS, oracle);
    }



    // this completes the round, and assigns it a winning choice, which enables deferred updates to voice credits
    function resolveRound(uint tournamentId, uint roundId, uint winningOption) public {
        Tournament storage tournament = tournaments[tournamentId];
        require(msg.sender == tournament.winnerOracle, 'Only winner oracle can call this');
        uint currentRoundId = getCurrentRoundId(tournamentId);
        Round storage round = tournament.rounds[roundId];
        require(roundAlreadyResolved(tournamentId, roundId) == false, 'Round already resolved');
        require(currentRoundId > roundId + 1, 'Too early to resolve');
        round.roundId = roundId;
        round.winningOption = winningOption;
        emit RoundResolved(tournamentId, roundId, winningOption);
    }

    function voteCheck(uint voterId, uint tournamentId, uint roundId) internal view {
        require(roundId > 0, 'Tournament not started yet');
        require(identity.ownerOf(voterId) == msg.sender, 'Must own identity to vote with it');
        require(roundId > identities[voterId].lastRoundVoted[tournamentId], 'Can only vote one time per round');
        require(tournaments[tournamentId].minimumRank <= identities[voterId].rank, 'Insufficient rank to participate in this tournament');
    }

    // this is called by an identity that wishes to vote on a given tournament, with the choices and weights
    function vote(
        uint voterId,
        uint tournamentId,
        uint[] memory choices,
        uint[] memory weights,
        bytes32 hash,
        uint updateRoundId
    ) public {
        uint roundId = getCurrentRoundId(tournamentId);
        Round storage currentRound = tournaments[tournamentId].rounds[roundId];

        voteCheck(voterId, tournamentId, roundId);
        require(choices.length == weights.length, 'Mismatched choices and lengths');

        updateAccount(voterId, tournamentId, updateRoundId);

        identities[voterId].lastRoundVoted[tournamentId] = roundId;

        Vote storage currentVote = currentRound.votes[voterId];
        currentVote.metadataHash = hash;
        uint balance = getVoiceCredits(tournamentId, voterId);
        uint sum = 0;

        for (uint i = 0; i < weights.length; i++) {
            currentVote.weights[choices[i]] = weights[i];
            currentRound.voteTotals[choices[i]] = currentRound.voteTotals[choices[i]].plus(weights[i]);
            sum = sum.plus(weights[i].times(weights[i]));
        }
        require(sum <= balance, 'Must not spend more than your balance');

        emit VoteOccurred(tournamentId, roundId, voterId, choices, weights, hash);
    }

    function withdrawWinnings(uint voterId) public {
        uint winnings = tokensWon[voterId];
        address owner = identity.ownerOf(voterId);
        require(winnings > 0, 'Nothing to withdraw');
        // doing it this way out of re-entry avoidance habit, not because it's actually possible here
        tokensWon[voterId] = 0;
        token.transfer(owner, winnings);
    }

    // this actually updates the voice credit balance to include the reward
    function updateAccount(uint voterId, uint tournamentId, uint roundId) public {
        IdMetadata storage id = identities[voterId];
        Tournament storage tournament = tournaments[tournamentId];
        bool roundResolved = roundAlreadyResolved(tournamentId, roundId);
        bool shouldSync = isSynced(voterId, tournamentId, roundId) == false;

        if (shouldSync && roundResolved) {
            // idempotent condition, call twice, update once, since this function is public
            syncMap[voterId][tournamentId][roundId] = true; // idempotence

            (uint voiceCreditBonus, uint tokenBonus) = getRoundBonus(voterId, tournamentId, roundId);
            tournament.voiceCredits[voterId] = getVoiceCredits(tournamentId, voterId).plus(voiceCreditBonus);
            tokensWon[voterId] = tokensWon[voterId].plus(tokenBonus);
            id.cumulativeBonus = id.cumulativeBonus.plus(voiceCreditBonus);
            emit AccountSynced(tournamentId, voterId);
        }
    }


/**
====================================== GETTERS ==========================================================
**/
    function getRound(uint tournamentId, uint roundId) public view returns (uint[2] memory) {
        Round storage round = tournaments[tournamentId].rounds[roundId];
        return [round.roundId, round.winningOption];
    }

    // this computes the id of the current round for a given tournament, starting with round 1 on the startTime
    function getCurrentRoundId(uint tournamentId) public view returns (uint) {
        Tournament storage tournament = tournaments[tournamentId];
        uint startTime = tournament.startTime;
        uint roundLengthSeconds = tournament.roundLengthSeconds;
        if (block.timestamp >= startTime) {
            return 1 + ((block.timestamp - startTime) / roundLengthSeconds);
        } else {
            return 0;
        }
    }

    function getVoiceCredits(uint tournamentId, uint voterId) public view returns (uint) {
        Tournament storage tournament = tournaments[tournamentId];
        uint voiceCredits = tournament.voiceCredits[voterId];
        if (voiceCredits > 0) {
            return voiceCredits;
        } else {
            return tournament.voiceUBI;
        }
    }

    function getLastRoundVoted(uint tournamentId, uint voterId) public view returns (uint) {
        return identities[voterId].lastRoundVoted[tournamentId];
    }

    function getVoteTotals(uint tournamentId, uint roundId, uint option) public view returns (uint) {
        return tournaments[tournamentId].rounds[roundId].voteTotals[option];
    }

    function getVoteMetadata(uint tournamentId, uint roundId, uint voterId) public view returns (bytes32) {
        return tournaments[tournamentId].rounds[roundId].votes[voterId].metadataHash;
    }

    function getVoiceUBI(uint tournamentId) public view  returns (uint)  {
        return tournaments[tournamentId].voiceUBI;
    }

    function getRoundResults(uint voterId, uint tournamentId, uint roundId) public view returns (uint, uint) {
        Tournament storage tournament = tournaments[tournamentId];
        Round storage round = tournament.rounds[roundId];
        Vote storage thisVote = round.votes[voterId];
        return (thisVote.weights[round.winningOption], round.voteTotals[round.winningOption]);
    }

    // this actually updates the voice credit balance to include the reward
    function getRoundBonus(uint voterId, uint tournamentId, uint roundId) public view returns (uint, uint) {
        Tournament storage tournament = tournaments[tournamentId];
        (uint voteWeight, uint totalVotes) = getRoundResults(voterId, tournamentId, roundId);
        uint tokenBonus = 0;
        // if this is the first round voterId has voted in, totalVotes will be 0
        if (totalVotes > 0) {
            tokenBonus = tournament.tokenRoundBonus.times(voteWeight) / totalVotes;
        }
        uint voiceCreditBonus = voteWeight.times(voteWeight);
        return (voiceCreditBonus, tokenBonus);
    }

    function isSynced(uint voterId, uint tournamentId, uint roundId) public view returns (bool) {
        return syncMap[voterId][tournamentId][roundId];
    }

    function roundAlreadyResolved(uint tournamentId, uint roundId) public view returns (bool) {
        return tournaments[tournamentId].rounds[roundId].winningOption > 0;
    }

/**
====================================== SETTERS ==========================================================
**/

    // change the site hash
    function setSiteHash(bytes32 newHash) public managementOnly {
        bytes32 oldHash = siteHash;
        siteHash = newHash;
        emit SiteHashUpdated(oldHash, newHash);
    }

    function setRank(uint voterId, uint newRank) public {
        require(msg.sender == rankManager, 'Only rankManager may call this');
        IdMetadata storage id = identities[voterId];
        uint oldRank = id.rank;
        id.rank = newRank;
        emit RankUpdated(voterId, oldRank, newRank);
    }

    function setToken(address tokenAddr) public managementOnly {
        token = IERC20(tokenAddr);
    }

    function updateTournament(uint tournamentId, bytes32 newMetadata, uint newBonus,  uint newMinRank, uint newUBI, bytes32 newTokenList, address newOracle) public managementOnly {
        Tournament storage tournament = tournaments[tournamentId];
        tournament.metadataHash = newMetadata;
        // no changing round length
        tournament.tokenRoundBonus = newBonus;
        tournament.minimumRank = newMinRank;
        tournament.voiceUBI = newUBI;
        tournament.tokenListENS = newTokenList;
        tournament.winnerOracle = newOracle;
        emit TournamentUpdated(tournamentId, newMetadata, newBonus, newMinRank, newUBI, newTokenList, newOracle);
    }

    function setRankManager(address newManager) public managementOnly {
        address oldManager = rankManager;
        rankManager = newManager;
        emit RankManagerUpdated(oldManager, newManager);
    }

    // change the management key
    function setManagement(address newMgmt) public managementOnly {
        address oldMgmt =  management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }


}
