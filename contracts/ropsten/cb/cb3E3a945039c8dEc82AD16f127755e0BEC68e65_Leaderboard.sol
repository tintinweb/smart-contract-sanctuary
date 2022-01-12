/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Leaderboard
{
    enum ResetPeriod
    {
        Eternal,
        Yearly,
        Monthly,
        Weekly,
        Daily
    }

    uint8 constant MAX_NICKNAME_LENGTH = 16;

    struct LeaderboardData
    {
        ResetPeriod resetPeriod;
        bool canScoresDecrease;
        uint256 maxSize;
        bytes32[] players;
        uint256[] scores;
        string[] nicknames;
        uint256 firstTimestamp;
    }

    LeaderboardData[] leaderboards;
    uint256 nextLeaderboardId;

    mapping(uint256 => address) leaderboardOwners;
    mapping(bytes32 => string) playerNicknames;

    // A value of 0 means the player does not have a score on that leaderboard
    mapping(uint256 => mapping(bytes32 => uint256)) playerIndexOneBased;

    /**
     * @dev Creates a brand-new leaderboard. The address that calls this is set as the owner of the new leaderboard.
     * 
     * @return uint256 Returns the ID of a new leaderboard. Use this number in future calls.
     */
    function createLeaderboard() public returns(uint256)
    {
        uint256 id = nextLeaderboardId;
        nextLeaderboardId++;

        LeaderboardData memory newBoard;
        newBoard.maxSize = 100000;
        leaderboards.push(newBoard);

        leaderboardOwners[id] = msg.sender;

        return id;
    }

    /**
     * @dev Returns a table of players and scores, in the form of two arrays of equal size, sorted in descending order, from best to worst score.
     * 
     * @param leaderboardId number of the leaderboard to be returned.
     * 
     * @return string[] Nicknames of the players. Anonymous mini-hashes are used instead, for players who have not registered their nicknames.
     * @return unit256[] The high-scores for each of the players.
     */
    function getLeaderboard(uint256 leaderboardId) public view returns(string[] memory, uint256[] memory)
    {
        LeaderboardData memory board = leaderboards[leaderboardId];
        return (board.nicknames, board.scores);
    }

    /**
     * @dev Clears a specific leaderboard. Restricted to the caller of createLeaderboard().
     * 
     * @param leaderboardId number of the leaderboard to be cleared.
     */
    function clearLeaderboard(uint256 leaderboardId) public
    {
        _checkAuthority(leaderboardId);
        _clearLeaderboard(leaderboardId);
    }

    /**
     * @dev Returns the frequency at which a specific leaderboard auto-clears. Default is 'Eternal'.
     * 
     * @param leaderboardId number of the leaderboard to be inspected.
     * 
     * @return ResetPeriod one of: Eternal (0), Yearly (1), Monthly (2), Weekly (3) or Daily (4).
     */
    function getResetPeriod(uint256 leaderboardId) public view returns(ResetPeriod)
    {
        LeaderboardData memory board = leaderboards[leaderboardId];
        return board.resetPeriod;
    }

    /**
     * @dev Set the frequency at which a specific leaderboard auto-clears.
     * 
     * @param leaderboardId number of the leaderboard to be configured.
     * @param _resetPeriod one of: Eternal (0), Yearly (1), Monthly (2), Weekly (3) or Daily (4).
     */
    function setResetPeriod(uint256 leaderboardId, ResetPeriod _resetPeriod) public
    {
        _checkAuthority(leaderboardId);

        LeaderboardData storage board = leaderboards[leaderboardId];
        board.resetPeriod = _resetPeriod;
    }

    /**
     * @dev Returns a specific leaderboard's "canScoresDecrease" property.
     * This defines the behavior of new scores passed in by submitScore().
     * 
     * @param leaderboardId number of the leaderboard to be inspected.
     * 
     * @return bool Returns `true` if lower scores for existing players are saved. `false` otherwise.
     */
    function getCanScoresDecrease(uint256 leaderboardId) public view returns(bool)
    {
        LeaderboardData memory board = leaderboards[leaderboardId];
        return board.canScoresDecrease;
    }

    /**
     * @dev Changes a specific leaderboard's "canScoresDecrease" property.
     * If set to `true`, then a new player's score always replaces their previous score.
     * If set to `false`, then a new score is compared to that player's previous score and is only accepted if it's better.
     * 
     * @param leaderboardId number of the leaderboard to be configured.
     * @param _canScoresDecrease boolean value specifying the behavior of new scores that are lower than previous scores.
     */
    function setCanScoresDecrease(uint256 leaderboardId, bool _canScoresDecrease) public
    {
        _checkAuthority(leaderboardId);

        LeaderboardData storage board = leaderboards[leaderboardId];
        board.canScoresDecrease = _canScoresDecrease;
    }

    /**
     * @dev Returns the maximum number of entries for a given leaderboard. Default is 10,000.
     * 
     * @param leaderboardId number of the leaderboard to be inspected.
     * 
     * @return unit256 The maximum size of the leaderboard.
     */
    function getMaxSize(uint256 leaderboardId) public view returns(uint256)
    {
        LeaderboardData memory board = leaderboards[leaderboardId];
        return board.maxSize;
    }

    /**
     * @dev Sets the maximum number of entries on a leaderboard. Restricted to the caller of createLeaderboard().
     * 
     * @param leaderboardId number of the leaderboard to be configured.
     * @param _maxSize the new size limit.
     */
    function setMaxSize(uint256 leaderboardId, uint256 _maxSize) public
    {
        _checkAuthority(leaderboardId);

        LeaderboardData storage board = leaderboards[leaderboardId];
        board.maxSize = _maxSize;

        while (board.scores.length > _maxSize)
        {
            bytes32 lastPlayerId = board.players[board.scores.length - 1];
            playerIndexOneBased[leaderboardId][lastPlayerId] = 0;
            board.players.pop();
            board.scores.pop();
            board.nicknames.pop();
        }
    }

    /**
     * @dev Returns the leaderboard data about the calling player: msg.sender is used as the player to lookup.
     * 
     * @param leaderboardId number of the leaderboard to be inspected.
     * 
     * @return string nickname of the calling player, or empty string if they are not present on this leaderboard.
     * @return unit256 score of the calling player, or zero if they are not present on this leaderboard.
     */
    function getEntry(uint256 leaderboardId) public view returns(string memory, uint256)
    {
        address player = msg.sender;

        bytes32 playerId = _getPlayerId(player);
        uint256 playerIndex = playerIndexOneBased[leaderboardId][playerId];
        if (playerIndex > 0)
        {
            playerIndex--;
            LeaderboardData memory board = leaderboards[leaderboardId];
            if (playerIndex < board.scores.length)
            {
                return (board.nicknames[playerIndex], board.scores[playerIndex]);
            }
        }
        return ("", 0);
    }

    /**
     * @dev Given an arbitrary score value, estimates what position on the leaderboard it would appear, if submitted.
     * 
     * @param leaderboardId number of the leaderboard to be inspected.
     * @param newScore the hypothetical score to evaluate.
     * 
     * @return unit256 zero-index position on the leaderboard where the score would appear, if submitted.
     */
    function getPositionForScore(uint256 leaderboardId, uint256 newScore) public view returns(uint256)
    {
        LeaderboardData storage board = leaderboards[leaderboardId];

        for (uint256 i = 0; i < board.scores.length; i++)
        {
            if (newScore >= board.scores[i])
            {
                return i;
            }
        }
        return board.scores.length;
    }

    /**
     * @dev Submits a new score for a player. Restricted to the caller of createLeaderboard().
     * 
     * @param leaderboardId number of the leaderboard to be modified.
     * @param player address of the player who earned the score.
     * @param newScore numeric value of the score earned.
     */
    function submitScore(uint256 leaderboardId, address player, uint256 newScore) public
    {
        _checkAuthority(leaderboardId);

        LeaderboardData storage board = leaderboards[leaderboardId];

        if (board.maxSize == 0)
        {
            return;
        }

        bytes32 playerId = _getPlayerId(player);
        
        // Clear leaderboard if the period has reset
        if (_checkResetPeriod(leaderboardId))
        {
            _clearLeaderboard(leaderboardId);
        }

        // The leaderboard is empty, receiving its first score
        if (board.scores.length == 0)
        {
            board.firstTimestamp = block.timestamp;

            playerIndexOneBased[leaderboardId][playerId] = 1;
            board.players.push(playerId);
            board.scores.push(newScore);
            board.nicknames.push(_getNickname(playerId));

            return;
        }

        // Check if this player already has a score on this leaderboard
        uint256 playerIndex = playerIndexOneBased[leaderboardId][playerId];
        bool hasPreviousScore = false;
        if (playerIndex > 0 && playerIndex < board.maxSize)
        {
            hasPreviousScore = true;
            playerIndex--;
        }

        // Player that is already on this leaderboard
        if (hasPreviousScore)
        {
            // Same score. No change
            if (newScore == board.scores[playerIndex])
            {
                return;
            }
            // The new score is better than this player's old score. Search and insert
            if (newScore > board.scores[playerIndex])
            {
                while (playerIndex > 0)
                {
                    if (newScore < board.scores[playerIndex - 1])
                    {
                        break;
                    }
                    // Move other scores down by 1
                    playerIndexOneBased[leaderboardId][board.players[playerIndex - 1]]++;
                    board.players[playerIndex] = board.players[playerIndex - 1];
                    board.scores[playerIndex] = board.scores[playerIndex - 1];
                    board.nicknames[playerIndex] = board.nicknames[playerIndex - 1];

                    playerIndex--;
                }
            }
            else // The new score is lower than the previous score
            {
                // However, the leaderboard may be configured to not allow saving worse scores
                if ( !board.canScoresDecrease )
                {
                    return;
                }
                // Search
                while (playerIndex < board.scores.length - 1)
                {
                    uint256 i = playerIndex + 1;
                    if (newScore >= board.scores[i])
                    {
                        break;
                    }

                    // Move other scores up by 1
                    playerIndexOneBased[leaderboardId][board.players[i]]--;
                    board.players[playerIndex] = board.players[i];
                    board.scores[playerIndex] = board.scores[i];
                    board.nicknames[playerIndex] = board.nicknames[i];

                    playerIndex++;
                }
            }
        }
        // New player, with worst score of all
        else if (newScore < board.scores[board.scores.length - 1])
        {
            if (board.scores.length < board.maxSize)
            {
                board.players.push(playerId);
                board.scores.push(newScore);
                board.nicknames.push(_getNickname(playerId));
                playerIndexOneBased[leaderboardId][playerId] = board.scores.length;
            }
            return;
        }
        // New player, inserted in the middle somewhere
        else
        {
            playerIndex = 0;
            for ( ; playerIndex < board.scores.length; playerIndex++)
            {
                // Search for the index to insert at
                if (newScore >= board.scores[playerIndex])
                {
                    // Adjust the score at the bottom of the leaderboard
                    uint256 i = board.scores.length - 1;
                    if (board.scores.length < board.maxSize)
                    {
                        playerIndexOneBased[leaderboardId][board.players[i]]++;
                        board.players.push(board.players[i]);
                        board.scores.push(board.scores[i]);
                        board.nicknames.push(board.nicknames[i]);
                    }
                    else {
                        playerIndexOneBased[leaderboardId][board.players[i]] = 0;
                    }
                    // Move other scores down by 1
                    while (i > playerIndex)
                    {
                        playerIndexOneBased[leaderboardId][board.players[i - 1]]++;
                        board.players[i] = board.players[i - 1];
                        board.scores[i] = board.scores[i - 1];
                        board.nicknames[i] = board.nicknames[i - 1];
                        i--;
                    }
                    break;
                }
            }
        }
        // Emplace
        playerIndexOneBased[leaderboardId][playerId] = playerIndex + 1;
        board.players[playerIndex] = playerId;
        board.scores[playerIndex] = newScore;
        board.nicknames[playerIndex] = _getNickname(playerId);
    }

    /**
     * @dev Returns the timestamp when the leaderboard will auto-clear, in seconds since unix epoch.
     * 
     * @param leaderboardId number of the leaderboard to be inspected.
     * 
     * @return unit256 the time at which reset will occur, in the form of seconds since unix epoch.
     * Returns zero if the leaderboard's `resetPeriod` is set to `Eternal`.
     */
    function getResetTimestamp(uint256 leaderboardId) public view returns(uint256)
    {
        LeaderboardData storage board = leaderboards[leaderboardId];

        if (board.resetPeriod == ResetPeriod.Eternal)
        {
            return 0;
        }
        uint256 expireTime = board.firstTimestamp;
        
        if (board.resetPeriod == ResetPeriod.Daily)
        {
            expireTime += 60 * 60 * 24; // 24 hours
        }
        else if (board.resetPeriod == ResetPeriod.Weekly)
        {
            expireTime += 60 * 60 * 24 * 7; // 7 days
        }
        else if (board.resetPeriod == ResetPeriod.Monthly)
        {
            expireTime += 60 * 60 * 24 * 30; // 30 days
        }
        else if (board.resetPeriod == ResetPeriod.Yearly)
        {
            expireTime += 60 * 60 * 24 * 365; // 1 year
        }
        return expireTime;
    }

    /**
     * @dev Allows a player to register their nickname with all leaderboards created with the contract.
     * Local only: The contract uses `msg.sender` to register the nickname.
     * Player addresses are hashed before storage.
     * 
     * @param _nickname the desired nickname, up to a 16 byte limit. Nicknames larger than the limit are cropped.
     */
    function registerNickname(string memory _nickname) public
    {
        // Limit the size
        bytes memory strBytes = bytes(_nickname);
        if (strBytes.length > MAX_NICKNAME_LENGTH)
        {
            bytes memory result = new bytes(MAX_NICKNAME_LENGTH);
            for(uint i = 0; i < MAX_NICKNAME_LENGTH; i++) {
                result[i] = strBytes[i];
            }
            _nickname = string(result);
        }

        // Save nickname
        bytes32 playerId = _getPlayerId(msg.sender);
        _nickname = string(abi.encodePacked(_nickname, " ", _getPlayerIdAbbreviation(playerId)));
        playerNicknames[playerId] = _nickname;

        // Update existing entries for this player across all leaderboards
        for (uint256 id = 0; id < nextLeaderboardId; id++)
        {
            uint256 playerIndex = playerIndexOneBased[id][playerId];
            if (playerIndex > 0)
            {
                playerIndex--;
                LeaderboardData storage board = leaderboards[id];
                board.nicknames[playerIndex] = _nickname;
            }
        }
    }

    /**
     * @dev Returns the nickname for the caller.
     * Local only: The contract uses `msg.sender` to lookup the nickname.
     * 
     * @return string the nickname previously set by calls to registerNickname().
     */
    function getNickname() public view returns(string memory)
    {
        bytes32 playerId = _getPlayerId(msg.sender);
        return _getNickname(playerId);
    }

    function _getNickname(bytes32 playerId) internal view returns(string memory)
    {
        if (bytes(playerNicknames[playerId]).length > 0)
        {
            return playerNicknames[playerId];
        }
        return _getPlayerIdAbbreviation(playerId);
    }

    function _getPlayerIdAbbreviation(bytes32 playerId) internal pure returns(string memory)
    {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(5);
        str[0] = "#";
        uint n = 1;
        uint i = 0;
        while (n < str.length)
        {
            str[n] = alphabet[uint(uint8(playerId[i] >> 4))];
            str[n+1] = alphabet[uint(uint8(playerId[i] & 0x0f))];
            n += 2;
            i++;
        }
        return string(str);
    }

    function _clearLeaderboard(uint256 leaderboardId) internal
    {
        LeaderboardData storage board = leaderboards[leaderboardId];

        while (board.scores.length > 0)
        {
            bytes32 lastPlayerId = board.players[board.scores.length - 1];
            playerIndexOneBased[leaderboardId][lastPlayerId] = 0;
            board.players.pop();
            board.scores.pop();
            board.nicknames.pop();
        }
    }

    function _checkAuthority(uint256 leaderboardId) internal view
    {
        require(leaderboardOwners[leaderboardId] == msg.sender, "No permission to change leaderboard.");
    }

    function _getPlayerId(address player) internal pure returns(bytes32)
    {
        return keccak256(abi.encodePacked(player));
    }

    function _checkResetPeriod(uint256 leaderboardId) internal view returns(bool)
    {
        LeaderboardData storage board = leaderboards[leaderboardId];

        if (board.resetPeriod == ResetPeriod.Eternal)
        {
            return false;
        }
        return getResetTimestamp(leaderboardId) >= block.timestamp;
    }
}