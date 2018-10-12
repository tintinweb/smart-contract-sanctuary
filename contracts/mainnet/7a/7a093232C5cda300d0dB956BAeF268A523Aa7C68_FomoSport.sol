pragma solidity 0.4.25;

/// @title Events used in FomoSport
contract FSEvents {

    event onGameCreated(
        uint256 indexed gameID,
        uint256 timestamp
    );

    event onGameActivated(
        uint256 indexed gameID,
        uint256 startTime,
        uint256 timestamp
    );

    event onGamePaused(
        uint256 indexed gameID,
        bool paused,
        uint256 timestamp
    );

    event onChangeCloseTime(
        uint256 indexed gameID,
        uint256 closeTimestamp,
        uint256 timestamp
    );

    event onPurchase(
        uint256 indexed gameID,
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 teamID,
        uint256 ethIn,
        uint256 keysBought,
        uint256 affID,
        uint256 timestamp
    );

    event onComment(
        uint256 indexed gameID,
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethIn,
        string comment,
        uint256 timestamp
    );

    event onWithdraw(
        uint256 indexed gameID,
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timestamp
    );

    event onGameEnded(
        uint256 indexed gameID,
        uint256 winningTeamID,
        string comment,
        uint256 timestamp
    );

    event onGameCancelled(
        uint256 indexed gameID,
        string comment,
        uint256 timestamp
    );

    event onFundCleared(
        uint256 indexed gameID,
        uint256 fundCleared,
        uint256 timestamp
    );
}


/// @title A raffle system for sports betting, designed with FOMO elements
/// @notice This contract manages multiple games. Owner(s) can create games and
/// assign winning team for each game. Players can withdraw their winnings before
/// the deadline set by the owner(s). If there&#39;s no winning team, the owner(s)
/// can also cancel a game so the players get back their bettings (minus fees).
/// @dev The address of the forwarder, player book, and owner(s) are hardcoded.
/// Check &#39;TODO&#39; before deploy.
contract FomoSport is FSEvents {
    using FSKeyCalc for *;
    using SafeMath for *;

    // TODO: check address!!
    FSInterfaceForForwarder constant private FSKingCorp = FSInterfaceForForwarder(0x3a2321DDC991c50518969B93d2C6B76bf5309790);
    FSBookInterface constant private FSBook = FSBookInterface(0xb440cF08BC2C78C33f3D29726d6c8ba5cBaA4B91);

    string constant public name_ = "FomoSport";
    uint256 public gameIDIndex_;
    
    // (gameID => gameData)
    mapping(uint256 => FSdatasets.Game) public game_;

    // (gameID => gameStatus)
    mapping(uint256 => FSdatasets.GameStatus) public gameStatus_;

    // (gameID => (teamID => teamData))
    mapping(uint256 => mapping(uint256 => FSdatasets.Team)) public teams_;

    // (playerID => (gameID => playerData))
    mapping(uint256 => mapping(uint256 => FSdatasets.Player)) public players_;

    // (playerID => (gameID => (teamID => playerTeamData)))
    mapping(uint256 => mapping(uint256 => mapping(uint256 => FSdatasets.PlayerTeam))) public playerTeams_;

    // (gameID => (commentID => commentData))
    mapping(uint256 => mapping(uint256 => FSdatasets.PlayerComment)) public playerComments_;

    // (gameID => numberOfComments)
    mapping(uint256 => uint256) public playerCommentsIndex_;


    constructor() public {
        gameIDIndex_ = 1;
    }


    /// @notice Create a game. Only owner(s) can call this function.
    /// Emits "onGameCreated" event.
    /// @param _name Name of the new game.
    /// @param _teamNames Array consisting names of all teams in the game.
    /// The size of the array indicates the number of teams in this game.
    /// @return Game ID of the newly created game.
    function createGame(string _name, bytes32[] _teamNames)
        external
        isHuman()
        isOwner()
        returns(uint256)
    {
        uint256 _gameID = gameIDIndex_;
        gameIDIndex_++;

        // initialize game
        game_[_gameID].name = _name;

        // initialize each team
        uint256 _nt = _teamNames.length;
        require(_nt > 0, "number of teams must be larger than 0");

        game_[_gameID].numberOfTeams = _nt;
        for (uint256 i = 0; i < _nt; i++) {
            teams_[_gameID][i] = FSdatasets.Team(_teamNames[i], 0, 0, 0, 0);
        }

        emit onGameCreated(_gameID, now);

        return _gameID;
    }


    /// @notice Activate a game. Only owner(s) can do this.
    /// Players can start buying keys after start time.
    /// Emits "onGameActivated" event.
    /// @param _gameID Game ID of the game.
    /// @param _startTime Timestamp of the start time.
    function activate(uint256 _gameID, uint256 _startTime)
        external
        isHuman()
        isOwner()
    {
        require(_gameID < gameIDIndex_, "incorrect game id");
        require(game_[_gameID].gameStartTime == 0, "already activated");
        
        // TODO: do some initialization
        game_[_gameID].gameStartTime = _startTime;

        emit onGameActivated(_gameID, _startTime, now);
    }


    /// @notice Buy keys for each team.
    /// Emits "onPurchase" for each team with a purchase.
    /// Emits "onComment" if there&#39;s a valid comment.
    /// @param _gameID Game ID of the game to buy tickets.
    /// @param _teamEth Array consisting amount of ETH for each team to buy tickets.
    /// The size of the array must be the same as the number of teams.
    /// The paid ETH along with this function call must be the same as the sum of all
    /// ETH in this array.
    /// @param _affCode Affiliate code used for this transaction. Use 0 if no affiliate
    /// code is used.
    /// @param _comment A string comment passed along with this transaction. Only
    /// valid when paid more than 0.001 ETH.
    function buysXid(uint256 _gameID, uint256[] memory _teamEth, uint256 _affCode, string memory _comment)
        public
        payable
        isActivated(_gameID)
        isOngoing(_gameID)
        isNotPaused(_gameID)
        isNotClosed(_gameID)
        isHuman()
        isWithinLimits(msg.value)
    {
        // fetch player id
        uint256 _pID = FSBook.getPlayerID(msg.sender);
        
        uint256 _affID;
        if (_affCode != 0 && _affCode != _pID) {
            // update last affiliate 
            FSBook.setPlayerLAff(_pID, _affCode);
            _affID = _affCode;
        } else {
            _affID = FSBook.getPlayerLAff(_pID);
        }
        
        // purchase keys for each team
        buysCore(_gameID, _pID, _teamEth, _affID);

        // handle comment
        handleComment(_gameID, _pID, _comment);
    }


    /// @notice Pause a game. Only owner(s) can do this.
    /// Players can&#39;t buy tickets if a game is paused.
    /// Emits "onGamePaused" event.
    /// @param _gameID Game ID of the game.
    /// @param _paused "true" to pause this game, "false" to unpause.
    function pauseGame(uint256 _gameID, bool _paused)
        external
        isActivated(_gameID)
        isOngoing(_gameID)
        isOwner()
    {
        game_[_gameID].paused = _paused;

        emit onGamePaused(_gameID, _paused, now);
    }


    /// @notice Set a closing time for betting. Only owner(s) can do this.
    /// Players can&#39;t buy tickets for this game once the closing time is passed.
    /// Emits "onChangeCloseTime" event.
    /// @param _gameID Game ID of the game.
    /// @param _closeTime Timestamp of the closing time.
    function setCloseTime(uint256 _gameID, uint256 _closeTime)
        external
        isActivated(_gameID)
        isOngoing(_gameID)
        isOwner()
    {
        game_[_gameID].closeTime = _closeTime;

        emit onChangeCloseTime(_gameID, _closeTime, now);
    }


    /// @notice Select a winning team. Only owner(s) can do this.
    /// Players can&#39;t no longer buy tickets for this game once a winning team is selected.
    /// Players who bought tickets for the winning team are able to withdraw winnings.
    /// Emits "onGameEnded" event.
    /// @param _gameID Game ID of the game.
    /// @param _team Team ID of the winning team.
    /// @param _comment A closing comment to describe the conclusion of the game.
    /// @param _deadline Timestamp of the withdraw deadline of the game
    function settleGame(uint256 _gameID, uint256 _team, string _comment, uint256 _deadline)
        external
        isActivated(_gameID)
        isOngoing(_gameID)
        isValidTeam(_gameID, _team)
        isOwner()
    {
        // TODO: check deadline limit
        require(_deadline >= now + 86400, "deadline must be more than one day later.");

        game_[_gameID].ended = true;
        game_[_gameID].winnerTeam = _team;
        game_[_gameID].gameEndComment = _comment;
        game_[_gameID].withdrawDeadline = _deadline;

        if (teams_[_gameID][_team].keys == 0) {
            // no one bought winning keys, send pot to community
            uint256 _totalPot = (gameStatus_[_gameID].winningVaultInst).add(gameStatus_[_gameID].winningVaultFinal);
            gameStatus_[_gameID].totalWithdrawn = _totalPot;
            if (_totalPot > 0) {
                FSKingCorp.deposit.value(_totalPot)();
            }
        }

        emit FSEvents.onGameEnded(_gameID, _team, _comment, now);
    }


    /// @notice Cancel a game. Only owner(s) can do this.
    /// Players can&#39;t no longer buy tickets for this game once a winning team is selected.
    /// Players who bought tickets can get back 95% of the ETH paid.
    /// Emits "onGameCancelled" event.
    /// @param _gameID Game ID of the game.
    /// @param _comment A closing comment to describe the conclusion of the game.
    /// @param _deadline Timestamp of the withdraw deadline of the game
    function cancelGame(uint256 _gameID, string _comment, uint256 _deadline)
        external
        isActivated(_gameID)
        isOngoing(_gameID)
        isOwner()
    {
        // TODO: check deadline limit
        require(_deadline >= now + 86400, "deadline must be more than one day later.");

        game_[_gameID].ended = true;
        game_[_gameID].canceled = true;
        game_[_gameID].gameEndComment = _comment;
        game_[_gameID].withdrawDeadline = _deadline;

        emit FSEvents.onGameCancelled(_gameID, _comment, now);
    }


    /// @notice Withdraw winnings. Only available after a game is ended
    /// (winning team selected or game canceled).
    /// Emits "onWithdraw" event.
    /// @param _gameID Game ID of the game.
    function withdraw(uint256 _gameID)
        external
        isHuman()
        isActivated(_gameID)
        isEnded(_gameID)
    {
        require(now < game_[_gameID].withdrawDeadline, "withdraw deadline already passed");
        require(gameStatus_[_gameID].fundCleared == false, "fund already cleared");

        uint256 _pID = FSBook.pIDxAddr_(msg.sender);

        require(_pID != 0, "player has not played this game");
        require(players_[_pID][_gameID].withdrawn == false, "player already cashed out");

        players_[_pID][_gameID].withdrawn = true;

        if (game_[_gameID].canceled) {
            // game is canceled
            // withdraw 95% of the original payments
            uint256 _totalInvestment = players_[_pID][_gameID].eth.mul(95) / 100;
            if (_totalInvestment > 0) {
                // send to player
                FSBook.getPlayerAddr(_pID).transfer(_totalInvestment);
                gameStatus_[_gameID].totalWithdrawn = _totalInvestment.add(gameStatus_[_gameID].totalWithdrawn);
            }

            emit FSEvents.onWithdraw(_gameID, _pID, msg.sender, FSBook.getPlayerName(_pID), _totalInvestment, now);
        } else {
            uint256 _totalWinnings = getPlayerInstWinning(_gameID, _pID, game_[_gameID].winnerTeam).add(getPlayerPotWinning(_gameID, _pID, game_[_gameID].winnerTeam));
            if (_totalWinnings > 0) {
                // send to player
                FSBook.getPlayerAddr(_pID).transfer(_totalWinnings);
                gameStatus_[_gameID].totalWithdrawn = _totalWinnings.add(gameStatus_[_gameID].totalWithdrawn);
            }

            emit FSEvents.onWithdraw(_gameID, _pID, msg.sender, FSBook.getPlayerName(_pID), _totalWinnings, now);
        }
    }


    /// @notice Clear funds of a game. Only owner(s) can do this, after withdraw deadline
    /// is passed.
    /// Emits "onFundCleared" event.
    /// @param _gameID Game ID of the game.
    function clearFund(uint256 _gameID)
        external
        isHuman()
        isEnded(_gameID)
        isOwner()
    {
        require(now >= game_[_gameID].withdrawDeadline, "withdraw deadline not passed yet");
        require(gameStatus_[_gameID].fundCleared == false, "fund already cleared");

        gameStatus_[_gameID].fundCleared = true;

        // send remaining fund to community
        uint256 _totalPot = (gameStatus_[_gameID].winningVaultInst).add(gameStatus_[_gameID].winningVaultFinal);
        uint256 _amount = _totalPot.sub(gameStatus_[_gameID].totalWithdrawn);
        if (_amount > 0) {
            FSKingCorp.deposit.value(_amount)();
        }

        emit onFundCleared(_gameID, _amount, now);
    }


    /// @notice Get a player&#39;s current instant pot winnings.
    /// @param _gameID Game ID of the game.
    /// @param _pID Player ID of the player.
    /// @param _team Team ID of the team.
    /// @return Instant pot winnings of the player for this game and this team.
    function getPlayerInstWinning(uint256 _gameID, uint256 _pID, uint256 _team)
        public
        view
        isActivated(_gameID)
        isValidTeam(_gameID, _team)
        returns(uint256)
    {
        return ((((teams_[_gameID][_team].mask).mul(playerTeams_[_pID][_gameID][_team].keys)) / (1000000000000000000)).sub(playerTeams_[_pID][_gameID][_team].mask));
    }


    /// @notice Get a player&#39;s current final pot winnings.
    /// @param _gameID Game ID of the game.
    /// @param _pID Player ID of the player.
    /// @param _team Team ID of the team.
    /// @return Final pot winnings of the player for this game and this team.
    function getPlayerPotWinning(uint256 _gameID, uint256 _pID, uint256 _team)
        public
        view
        isActivated(_gameID)
        isValidTeam(_gameID, _team)
        returns(uint256)
    {
        if (teams_[_gameID][_team].keys > 0) {
            return gameStatus_[_gameID].winningVaultFinal.mul(playerTeams_[_pID][_gameID][_team].keys) / teams_[_gameID][_team].keys;
        } else {
            return 0;
        }
    }


    /// @notice Get current game status.
    /// @param _gameID Game ID of the game.
    /// @return (number of teams, names, keys, eth, current key price for 1 key)
    function getGameStatus(uint256 _gameID)
        public
        view
        isActivated(_gameID)
        returns(uint256, bytes32[] memory, uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint256 _nt = game_[_gameID].numberOfTeams;
        bytes32[] memory _names = new bytes32[](_nt);
        uint256[] memory _keys = new uint256[](_nt);
        uint256[] memory _eth = new uint256[](_nt);
        uint256[] memory _keyPrice = new uint256[](_nt);
        uint256 i;

        for (i = 0; i < _nt; i++) {
            _names[i] = teams_[_gameID][i].name;
            _keys[i] = teams_[_gameID][i].keys;
            _eth[i] = teams_[_gameID][i].eth;
            _keyPrice[i] = getBuyPrice(_gameID, i, 1000000000000000000);
        }

        return (_nt, _names, _keys, _eth, _keyPrice);
    }


    /// @notice Get player status of a game.
    /// @param _gameID Game ID of the game.
    /// @param _pID Player ID of the player.
    /// @return (name, eth for each team, keys for each team, inst win for each team, pot win for each team)
    function getPlayerStatus(uint256 _gameID, uint256 _pID)
        public
        view
        isActivated(_gameID)
        returns(bytes32, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint256 _nt = game_[_gameID].numberOfTeams;
        uint256[] memory _eth = new uint256[](_nt);
        uint256[] memory _keys = new uint256[](_nt);
        uint256[] memory _instWin = new uint256[](_nt);
        uint256[] memory _potWin = new uint256[](_nt);
        uint256 i;

        for (i = 0; i < _nt; i++) {
            _eth[i] = playerTeams_[_pID][_gameID][i].eth;
            _keys[i] = playerTeams_[_pID][_gameID][i].keys;
            _instWin[i] = getPlayerInstWinning(_gameID, _pID, i);
            _potWin[i] = getPlayerPotWinning(_gameID, _pID, i);
        }
        
        return (FSBook.getPlayerName(_pID), _eth, _keys, _instWin, _potWin);
    }


    /// @notice Get the price buyer have to pay for next keys.
    /// @param _gameID Game ID of the game.
    /// @param _team Team ID of the team.
    /// @param _keys Number of keys (in wei).
    /// @return Price for the number of keys to buy (in wei).
    function getBuyPrice(uint256 _gameID, uint256 _team, uint256 _keys)
        public 
        view
        isActivated(_gameID)
        isValidTeam(_gameID, _team)
        returns(uint256)
    {                  
        return ((teams_[_gameID][_team].keys.add(_keys)).ethRec(_keys));
    }


    /// @notice Get the prices buyer have to pay for next keys for all teams.
    /// @param _gameID Game ID of the game.
    /// @param _keys Array of number of keys (in wei) for all teams.
    /// @return (total eth, array of prices in wei).
    function getBuyPrices(uint256 _gameID, uint256[] memory _keys)
        public
        view
        isActivated(_gameID)
        returns(uint256, uint256[])
    {
        uint256 _totalEth = 0;
        uint256 _nt = game_[_gameID].numberOfTeams;
        uint256[] memory _eth = new uint256[](_nt);
        uint256 i;

        require(_nt == _keys.length, "Incorrect number of teams");

        for (i = 0; i < _nt; i++) {
            if (_keys[i] > 0) {
                _eth[i] = getBuyPrice(_gameID, i, _keys[i]);
                _totalEth = _totalEth.add(_eth[i]);
            }
        }

        return (_totalEth, _eth);
    }
    

    /// @notice Get the number of keys can be bought with an amount of ETH.
    /// @param _gameID Game ID of the game.
    /// @param _team Team ID of the team.
    /// @param _eth Amount of ETH in wei.
    /// @return Number of keys can be bought (in wei).
    function getKeysfromETH(uint256 _gameID, uint256 _team, uint256 _eth)
        public 
        view
        isActivated(_gameID)
        isValidTeam(_gameID, _team)
        returns(uint256)
    {                  
        return (teams_[_gameID][_team].eth).keysRec(_eth);
    }


    /// @notice Get all numbers of keys can be bought with amounts of ETH.
    /// @param _gameID Game ID of the game.
    /// @param _eths Array of amounts of ETH in wei.
    /// @return (total keys, array of number of keys in wei).
    function getKeysFromETHs(uint256 _gameID, uint256[] memory _eths)
        public
        view
        isActivated(_gameID)
        returns(uint256, uint256[])
    {
        uint256 _totalKeys = 0;
        uint256 _nt = game_[_gameID].numberOfTeams;
        uint256[] memory _keys = new uint256[](_nt);
        uint256 i;

        require(_nt == _eths.length, "Incorrect number of teams");

        for (i = 0; i < _nt; i++) {
            if (_eths[i] > 0) {
                _keys[i] = getKeysfromETH(_gameID, i, _eths[i]);
                _totalKeys = _totalKeys.add(_keys[i]);
            }
        }

        return (_totalKeys, _keys);
    }


    /// @dev Handle comments.
    /// @param _gameID Game ID of the game.
    /// @param _pID Player ID of the player.
    /// @param _comment Comment to be used.
    function handleComment(uint256 _gameID, uint256 _pID, string memory _comment)
        private
    {
        bytes memory _commentBytes = bytes(_comment);
        // comment is empty, do nothing
        if (_commentBytes.length == 0) {
            return;
        }

        // only handle comments when eth >= 0.001
        uint256 _totalEth = msg.value;
        if (_totalEth >= 1000000000000000) {
            require(_commentBytes.length <= 64, "comment is too long");
            bytes32 _name = FSBook.getPlayerName(_pID);

            playerComments_[_gameID][playerCommentsIndex_[_gameID]] = FSdatasets.PlayerComment(_pID, _name, _totalEth, _comment);
            playerCommentsIndex_[_gameID] ++;

            emit onComment(_gameID, _pID, msg.sender, _name, _totalEth, _comment, now);
        }
    }


    /// @dev Buy keys for all teams.
    /// @param _gameID Game ID of the game.
    /// @param _pID Player ID of the player.
    /// @param _teamEth Array of eth paid for each team.
    /// @param _affID Affiliate ID
    function buysCore(uint256 _gameID, uint256 _pID, uint256[] memory _teamEth, uint256 _affID)
        private
    {
        uint256 _nt = game_[_gameID].numberOfTeams;
        uint256[] memory _keys = new uint256[](_nt);
        bytes32 _name = FSBook.getPlayerName(_pID);
        uint256 _totalEth = 0;
        uint256 i;

        require(_teamEth.length == _nt, "Number of teams is not correct");

        // for all teams...
        for (i = 0; i < _nt; i++) {
            if (_teamEth[i] > 0) {
                // compute total eth
                _totalEth = _totalEth.add(_teamEth[i]);

                // compute number of keys to buy
                _keys[i] = (teams_[_gameID][i].eth).keysRec(_teamEth[i]);

                // update player data
                playerTeams_[_pID][_gameID][i].eth = _teamEth[i].add(playerTeams_[_pID][_gameID][i].eth);
                playerTeams_[_pID][_gameID][i].keys = _keys[i].add(playerTeams_[_pID][_gameID][i].keys);

                // update team data
                teams_[_gameID][i].eth = _teamEth[i].add(teams_[_gameID][i].eth);
                teams_[_gameID][i].keys = _keys[i].add(teams_[_gameID][i].keys);

                emit FSEvents.onPurchase(_gameID, _pID, msg.sender, _name, i, _teamEth[i], _keys[i], _affID, now);
            }
        }

        // check assigned ETH for each team is the same as msg.value
        require(_totalEth == msg.value, "Total ETH is not the same as msg.value");        
            
        // update game data and player data
        gameStatus_[_gameID].totalEth = _totalEth.add(gameStatus_[_gameID].totalEth);
        players_[_pID][_gameID].eth = _totalEth.add(players_[_pID][_gameID].eth);

        distributeAll(_gameID, _pID, _affID, _totalEth, _keys);
    }


    /// @dev Distribute paid ETH to different pots.
    /// @param _gameID Game ID of the game.
    /// @param _pID Player ID of the player.
    /// @param _affID Affiliate ID used for this transasction.
    /// @param _totalEth Total ETH paid.
    /// @param _keys Array of keys bought for each team.
    function distributeAll(uint256 _gameID, uint256 _pID, uint256 _affID, uint256 _totalEth, uint256[] memory _keys)
        private
    {
        // community 2%
        uint256 _com = _totalEth / 50;

        // distribute 3% to aff
        uint256 _aff = _totalEth.mul(3) / 100;
        _com = _com.add(handleAffiliate(_pID, _affID, _aff));

        // instant pot (15%)
        uint256 _instPot = _totalEth.mul(15) / 100;

        // winning pot (80%)
        uint256 _pot = _totalEth.mul(80) / 100;

        // Send community to forwarder
        if (!address(FSKingCorp).call.value(_com)(abi.encode("deposit()"))) {
            // if unable to deposit, add to pot
            _pot = _pot.add(_com);
        }

        gameStatus_[_gameID].winningVaultInst = _instPot.add(gameStatus_[_gameID].winningVaultInst);
        gameStatus_[_gameID].winningVaultFinal = _pot.add(gameStatus_[_gameID].winningVaultFinal);

        // update masks for instant winning vault
        uint256 _nt = _keys.length;
        for (uint256 i = 0; i < _nt; i++) {
            uint256 _newPot = _instPot.add(teams_[_gameID][i].dust);
            uint256 _dust = updateMasks(_gameID, _pID, i, _newPot, _keys[i]);
            teams_[_gameID][i].dust = _dust;
        }
    }


    /// @dev Handle affiliate payments.
    /// @param _pID Player ID of the player.
    /// @param _affID Affiliate ID used for this transasction.
    /// @param _aff Amount of ETH for affiliate payment.
    /// @return The amount remained for the community (if there&#39;s no affiliate payment)
    function handleAffiliate(uint256 _pID, uint256 _affID, uint256 _aff)
        private
        returns (uint256)
    {
        uint256 _com = 0;

        if (_affID == 0 || _affID == _pID) {
            _com = _aff;
        } else if(FSBook.getPlayerHasAff(_affID)) {
            FSBook.depositAffiliate.value(_aff)(_affID);
        } else {
            _com = _aff;
        }

        return _com;
    }


    /// @dev Updates masks for instant pot.
    /// @param _gameID Game ID of the game.
    /// @param _pID Player ID of the player.
    /// @param _team Team ID of the team.
    /// @param _gen Amount of ETH to be added into instant pot.
    /// @param _keys Number of keys bought.
    /// @return Dust left over.
    function updateMasks(uint256 _gameID, uint256 _pID, uint256 _team, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
        /* MASKING NOTES
            earnings masks are a tricky thing for people to wrap their minds around.
            the basic thing to understand here.  is were going to have a global
            tracker based on profit per share for each round, that increases in
            relevant proportion to the increase in share supply.
            
            the player will have an additional mask that basically says "based
            on the rounds mask, my shares, and how much i&#39;ve already withdrawn,
            how much is still owed to me?"
        */
        
        // calc profit per key & round mask based on this buy:  (dust goes to pot)
        if (teams_[_gameID][_team].keys > 0) {
            uint256 _ppt = (_gen.mul(1000000000000000000)) / (teams_[_gameID][_team].keys);
            teams_[_gameID][_team].mask = _ppt.add(teams_[_gameID][_team].mask);

            updatePlayerMask(_gameID, _pID, _team, _ppt, _keys);

            // calculate & return dust
            return(_gen.sub((_ppt.mul(teams_[_gameID][_team].keys)) / (1000000000000000000)));
        } else {
            return _gen;
        }
    }


    /// @dev Updates masks for the player.
    /// @param _gameID Game ID of the game.
    /// @param _pID Player ID of the player.
    /// @param _team Team ID of the team.
    /// @param _ppt Amount of unit ETH.
    /// @param _keys Number of keys bought.
    /// @return Dust left over.
    function updatePlayerMask(uint256 _gameID, uint256 _pID, uint256 _team, uint256 _ppt, uint256 _keys)
        private
    {
        if (_keys > 0) {
            // calculate player earning from their own buy (only based on the keys
            // they just bought).  & update player earnings mask
            uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
            playerTeams_[_pID][_gameID][_team].mask = (((teams_[_gameID][_team].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(playerTeams_[_pID][_gameID][_team].mask);
        }
    }


    /// @dev Check if a game is activated.
    /// @param _gameID Game ID of the game.
    modifier isActivated(uint256 _gameID) {
        require(game_[_gameID].gameStartTime > 0, "Not activated yet");
        require(game_[_gameID].gameStartTime <= now, "game not started yet");
        _;
    }


    /// @dev Check if a game is not paused.
    /// @param _gameID Game ID of the game.
    modifier isNotPaused(uint256 _gameID) {
        require(game_[_gameID].paused == false, "game is paused");
        _;
    }


    /// @dev Check if a game is not closed.
    /// @param _gameID Game ID of the game.
    modifier isNotClosed(uint256 _gameID) {
        require(game_[_gameID].closeTime == 0 || game_[_gameID].closeTime > now, "game is closed");
        _;
    }


    /// @dev Check if a game is not settled.
    /// @param _gameID Game ID of the game.
    modifier isOngoing(uint256 _gameID) {
        require(game_[_gameID].ended == false, "game is ended");
        _;
    }


    /// @dev Check if a game is settled.
    /// @param _gameID Game ID of the game.
    modifier isEnded(uint256 _gameID) {
        require(game_[_gameID].ended == true, "game is not ended");
        _;
    }


    /// @dev Check if caller is not a smart contract.
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin, "Human only");

        uint256 _codeLength;
        assembly { _codeLength := extcodesize(_addr) }
        require(_codeLength == 0, "Human only");
        _;
    }


    // TODO: Check address!!!
    /// @dev Check if caller is one of the owner(s).
    modifier isOwner() {
        require(
            msg.sender == 0xE3FF68fB79FEE1989FB67Eb04e196E361EcAec3e ||
            msg.sender == 0xb914843D2E56722a2c133Eff956d1F99b820D468 ||
            msg.sender == 0xE0b005384dF8F4D80e9a69B6210eC1929A935D97 ||
            msg.sender == 0xc52FA2C9411fCd4f58be2d6725094689C46242f2
            , "Only owner can do this");
        _;
    }


    /// @dev Check if purchase is within limits.
    /// (between 0.000000001 ETH and 100000 ETH)
    /// @param _eth Amount of ETH
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "too little money");
        require(_eth <= 100000000000000000000000, "too much money");
        _;    
    }


    /// @dev Check if team ID is valid.
    /// @param _gameID Game ID of the game.
    /// @param _team Team ID of the team.
    modifier isValidTeam(uint256 _gameID, uint256 _team) {
        require(_team < game_[_gameID].numberOfTeams, "there is no such team");
        _;
    }
}

// key calculation
library FSKeyCalc {
    using SafeMath for *;
    
    /// @dev calculates number of keys received given X eth 
    /// @param _curEth current amount of eth in contract 
    /// @param _newEth eth being spent
    /// @return amount of ticket purchased
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }


    /// @dev calculates amount of eth received if you sold X keys 
    /// @param _curKeys current amount of keys that exist 
    /// @param _sellKeys amount of keys you wish to sell
    /// @return amount of eth received
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

    /// @dev calculates how many keys would exist with given an amount of eth
    /// @param _eth eth "in contract"
    /// @return number of keys that would exist
    function keys(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(3125000000000000000000000000)).add(562498828125610351562500000000000000000000000000000000000000000000)).sqrt()).sub(749999218750000000000000000000000)) / (1562500000);
    }
    
    /// @dev calculates how much eth would be in contract given a number of keys
    /// @param _keys number of keys "in contract" 
    /// @return eth that would exists
    function eth(uint256 _keys) 
        internal
        pure
        returns(uint256)
    {
        return ((781250000).mul(_keys.sq()).add(((1499998437500000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}


// datasets
library FSdatasets {

    struct Game {
        string name;                     // game name
        uint256 numberOfTeams;           // number of teams
        uint256 gameStartTime;           // game start time (> 0 means activated)

        bool paused;                     // game paused
        bool ended;                      // game ended
        bool canceled;                   // game canceled
        uint256 winnerTeam;              // winner team        
        uint256 withdrawDeadline;        // deadline for withdraw fund
        string gameEndComment;           // comment for game ending or canceling
        uint256 closeTime;               // betting close time
    }

    struct GameStatus {
        uint256 totalEth;                // total eth invested
        uint256 totalWithdrawn;          // total withdrawn by players
        uint256 winningVaultInst;        // current "instant" winning vault
        uint256 winningVaultFinal;       // current "final" winning vault        
        bool fundCleared;                // fund already cleared
    }

    struct Team {
        bytes32 name;       // team name
        uint256 keys;       // number of keys
        uint256 eth;        // total eth for the team
        uint256 mask;       // mask of this team
        uint256 dust;       // dust for winning vault
    }

    struct Player {
        uint256 eth;        // total eth for the game
        bool withdrawn;     // winnings already withdrawn
    }

    struct PlayerTeam {
        uint256 keys;       // number of keys
        uint256 eth;        // total eth for the team
        uint256 mask;       // mask for this team
    }

    struct PlayerComment {
        uint256 playerID;
        bytes32 playerName;
        uint256 ethIn;
        string comment;
    }
}


interface FSInterfaceForForwarder {
    function deposit() external payable returns(bool);
}


interface FSBookInterface {
    function pIDxAddr_(address _addr) external returns (uint256);
    function pIDxName_(bytes32 _name) external returns (uint256);

    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerName(uint256 _pID) external view returns (bytes32);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function setPlayerLAff(uint256 _pID, uint256 _lAff) external;
    function getPlayerAffT2(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getPlayerHasAff(uint256 _pID) external view returns (bool);
    function getNameFee() external view returns (uint256);
    function getAffiliateFee() external view returns (uint256);
    function depositAffiliate(uint256 _pID) external payable;
}


/// @title SafeMath v0.1.9
/// @dev Math operations with safety checks that throw on error
/// change notes: original SafeMath library from OpenZeppelin modified by Inventor
/// - added sqrt
/// - added sq
/// - added pwr 
/// - changed asserts to requires with error log outputs
/// - removed div, its useless
library SafeMath {
    
    /// @dev Multiplies two numbers, throws on overflow.
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }


    /// @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }


    /// @dev Adds two numbers, throws on overflow.
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    

    /// @dev gives square root of given x.
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z), z)) / 2);
        }
    }


    /// @dev gives square. multiplies x by x
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }


    /// @dev x to the power of y 
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x == 0) {
            return (0);
        } else if (y == 0) {
            return (1);
        } else {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++) {
                z = mul(z,x);
            }
            return (z);
        }
    }
}