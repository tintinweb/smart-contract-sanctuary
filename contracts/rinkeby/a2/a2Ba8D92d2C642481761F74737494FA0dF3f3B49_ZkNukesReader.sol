// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

library PlanetCounter {
    function planetCount(bytes32 _sysMap) internal pure returns (uint _count) {
        uint prevPosition;
        while(_sysMap > 0) {
            require(uint(_sysMap) & 255 == 5, "Invalid planet {type}{color}{hp}");
            uint position = (uint(_sysMap) >> 8) & 255;
            require(_count == 0 || position < prevPosition, "Invalid planet position");
            prevPosition = position;
            _count++;
            _sysMap >>= 16;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./StarSystems.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StarSystemData is Ownable {

    StarSystems public starSystems;
    mapping(address => bool) public mapEditors;
    mapping(uint => bytes32) public maps; // [sysId]

    event MapSet(uint indexed _sysId, bytes32 indexed _prevMap, bytes32 indexed _sysMap);

    constructor(StarSystems _starSystems) {
        starSystems = _starSystems;
    }

    function numSystems() public view returns (uint256) {
        return starSystems.numSystems();
    }

    function ownerOf(uint _sysId) public view returns (address) { 
        return starSystems.ownerOf(_sysId); 
    } 

    function mapOf(uint _sysId) external view returns (bytes32) { 
        return maps[_sysId]; 
    }

    function setMap(uint _sysId, bytes32 _sysMap) external {
        require(mapEditors[msg.sender], "Unauthorised to change system map");
        require(_sysMap > 0 && uint(_sysMap) < 2**253, "Invalid system map"); // _sysMap must be smaller than snark scalar field (=> have first 3 bits empty)
        bytes32 prevMap = maps[_sysId];
        maps[_sysId] = _sysMap;
        emit MapSet(_sysId, prevMap, _sysMap);
    }

    function setMapEditor(address _editor, bool _added) external onlyOwner { 
        mapEditors[_editor] = _added; 
    }

    function setStarSystems(StarSystems _starSystems) external onlyOwner { 
        starSystems = _starSystems; 
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StarSystems is ERC721("Star System", "STARSYS"), Ownable {

    uint public numSystems;
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter can mint");
        _;
    }

    function setMinter(address _minter) external onlyOwner { minter = _minter; }

    function mint(address _recipient) external onlyMinter returns (uint _sysId) {
        _sysId = ++numSystems;
        _mint(_recipient, _sysId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Utils {
    using SafeERC20 for IERC20;

    address constant internal ETH_TOKEN_ADDRESS = address(0);

    function pullToken(address _token, uint256 _wei) internal {
        if (_token == ETH_TOKEN_ADDRESS) {
            require(msg.value == _wei, "Incorrect value sent");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _wei);
        }
    }

    function pushToken(address _to, address _token, uint256 _wei) internal {
        if (_token == ETH_TOKEN_ADDRESS) {
            // `_to.transfer(_wei)` should be avoided, see https://diligence.consensys.net/blog/2019/09/stop-using-soliditys-transfer-now/
            // solium-disable-next-line security/no-call-value
            (bool success,) = _to.call{value: _wei}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(_token).safeTransfer(_to, _wei);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface INftAuthoriser {
    function isAuthorised(address _token, uint _tokenId, address _delegate, address _to, bytes calldata _data) external view returns (bool authorised);
    function isAuthorisedByOwner(address _token, uint _tokenId, address _delegate, address _to, bytes calldata _data) external view returns (bool authorised);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract EmergencyShutdown is Ownable {
    bool public isShutdown;

    event Shutdown();

    function shutdown() external onlyOwner {
        isShutdown = true;
        emit Shutdown();
    }

    modifier whenNotShutdown() {
        require(!isShutdown, "shutdown");
        _;
    }

    modifier whenShutdown() {
        require(isShutdown, "!shutdown");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../Utils.sol";
import "./StarSystemConfigs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract GameBase is Ownable {
    enum ActionType { NONE, CREDIT, NUKE, INTERCEPTOR, JUMP, GAIN, DETONATE, DEFUSE }
    enum Withdrawal { NONE, CREDITS, POT }

    struct Game {
        uint8 numPlayers;
        uint8 numPotClaims;
        uint24 pot; // total amount of credits held by this contract for the game
        uint64 startTime;
        bytes32 configId;
        bytes32 sysMap;
    }

    struct Ransom {
        uint16 requested;
        uint16 paid;
        uint64 destructionTime;
    }

    struct PlayerInfo {
        address account;
        Withdrawal withdrawal; // phase of withdrawal
        uint24 withdrawn; // total amount withdrawn, in credits
    }

    // {contractId:64} = {chainId:32}{versionId:32}
    bytes4 constant internal version = 0x00000001; // v0.0.1
    bytes8 immutable internal contractId = bytes8(bytes32(block.chainid << 224)) | (bytes8(version) >> 32);

    uint16 constant internal TICKS = 10000; // The budget, in credits; also the maximum qty of any item.
    uint256 constant internal NUM_ACTIONS = 7; // Total number of possible ActionTypes, excluding ActionType.NONE
    
    StarSystemConfigs internal configs;

    mapping(bytes32 => Game) public games; // [gameId]
    mapping(uint256 => bytes32) public lastGameIds; // [sysId]

    mapping(bytes32 => mapping(address => uint256)) public commitments; // [gameId][player]
    mapping(bytes32 => mapping(address => uint256)) public playerIds; // [gameId][player]
    mapping(bytes32 => mapping(uint256 => PlayerInfo)) public players; // [gameId][playerId]
    mapping(bytes32 => mapping(uint256 => mapping(uint256 => Ransom))) public ransoms; // [gameId][targetId][playerId]
    // Player gains in ticks (stake unit)
    mapping(bytes32 => mapping(uint256 => uint256)) public gains; // [gameId][playerId]

    constructor(StarSystemConfigs _cfg) {
        configs = _cfg;
    }

    function getGameId(uint _sysId, uint _gameCount) public view returns (bytes32 _gameId) {
        return bytes32(bytes32(contractId) | bytes32(_sysId << 128) | bytes32(_gameCount)); // {gameId:256} = {chainId:32}{versionId:32}{sysId:64}{gameCount:128}
    }

    function getSysId(bytes32 _gameId) internal pure returns (uint _sysId) {
        return uint(_gameId >> 128) & 0xFFFFFFFFFFFFFFFF;  // {gameId:256} = {chainId:32}{versionId:32}{sysId:64}{gameCount:128}
    }

    function verifyTargetIsPlanet(uint256 _targetId, bytes32 _sysMap)
        internal
        pure
    {
        require((uint(_sysMap) >> (_targetId * 16)) & 3 > 0, "!planet"); // Check if there is a planet at target
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../Utils.sol";
import "./GameBase.sol";
import "./Hasher.sol";
import "./EmergencyShutdown.sol";
import "../auth/INftAuthoriser.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract GameExit is GameBase, Hasher, EmergencyShutdown {

    IERC721 internal immutable starSystems;
    INftAuthoriser internal immutable authoriser;
    // Fee balances of system owners and governance
    mapping(address => mapping(address => uint)) public feeBalances; // [recipient][token]
    mapping(uint => address) feeCollectors; // [sysId]
    mapping(bytes32 => bool) feePaid; // [gameId]

    event FeeCollectorSet(uint indexed _sysId, address _collector);
    event CreditsWithdrawn(bytes32 indexed _gameId, address indexed _player, address indexed _token, uint _amount);
    event PotShareWithdrawn(bytes32 indexed _gameId, address indexed _player, address indexed _token, uint _amount);
    event EmergencyWithdrawn(bytes32 indexed _gameId, address indexed _player, address indexed _token, uint _amount);
    event FeeReceived(bytes32 indexed _gameId, address indexed _recipient, address indexed _token, uint _amount);
    event FeeWithdrawn(address indexed _recipient, address indexed _token, uint _amount);

    constructor(IERC721 _sys, INftAuthoriser _auth) {
        starSystems = _sys;
        authoriser = _auth;
    }

    function setFeeCollector(
        uint _sysId,
        address _collector
    ) external {
        require(authoriser.isAuthorisedByOwner(address(starSystems), _sysId, msg.sender, address(this), msg.data), "!auth");
        feeCollectors[_sysId] = _collector;
        emit FeeCollectorSet(_sysId, _collector);
    }

    function getFeeCollector(
        uint _sysId
    ) public view returns (address feeCollector) {
        feeCollector = feeCollectors[_sysId];
        if(feeCollector == address(0)) {
            feeCollector = (_sysId == 0) ? owner() : starSystems.ownerOf(_sysId);
        }
    }

    function withdrawFeeBalance(
        address _recipient,
        address _token
    ) external {
        uint withdrawn = feeBalances[_recipient][_token];
        if (withdrawn > 0) {
            feeBalances[_recipient][_token] = 0;
            Utils.pushToken(_recipient, _token, withdrawn);
            emit FeeWithdrawn(_recipient, _token, withdrawn);
        }
    }

    function withdrawCredits(
        bytes32 _gameId,
        uint _itemsLeft,
        uint _planetId,
        uint _secret
    )
        external
        whenNotShutdown
    {
        Game memory game = games[_gameId];
        _verifyDuringExit(game);
        uint playerId = playerIds[_gameId][msg.sender];
        require(playerId > 0 && players[_gameId][playerId].withdrawal == Withdrawal.NONE, "!player");
        require(hash3(_itemsLeft, uint(_planetId), _secret) == commitments[_gameId][msg.sender], "!secret");
        verifyTargetIsPlanet(_planetId, game.sysMap); // _planetId could have been nuked
        uint credits = (_itemsLeft >> 16 * uint(ActionType.CREDIT)) & 65535;
        (address stakeToken, uint stakeInWei) = configs.stakeConfigs(game.configId);
        uint withdrawn = credits + gains[_gameId][playerId];
        games[_gameId].numPotClaims = game.numPotClaims + 1;
        games[_gameId].pot = game.pot - uint24(withdrawn);
        uint withdrawnInWei = withdrawn * stakeInWei / TICKS;
        if(withdrawnInWei > 0) {
            Utils.pushToken(msg.sender, stakeToken, withdrawnInWei);
        }
        // delete gains[_gameId][playerId];
        // delete commitments[_gameId][msg.sender];
        players[_gameId][playerId].withdrawal = Withdrawal.CREDITS; // mark the player as a survivor
        players[_gameId][playerId].withdrawn += uint24(withdrawn);
        emit CreditsWithdrawn(_gameId, msg.sender, stakeToken, withdrawnInWei);
    }

    function withdrawPotShareOnBehalf(
        bytes32 _gameId,
        address _player
    )
        public
        whenNotShutdown
    {
        Game memory game = games[_gameId];
        _verifyAfterExit(game);
        (address stakeToken, uint stakeInWei) = configs.stakeConfigs(game.configId);
        (uint newPot, uint potShare) = _collectFees(_gameId, game, stakeToken, stakeInWei);
        if(_player != address(0)) {
            _payPotShare(_gameId, potShare, _player, stakeToken, stakeInWei);
            games[_gameId].numPotClaims = game.numPotClaims - 1;
            games[_gameId].pot = uint24(newPot - potShare);
        }
    }

    function withdrawPotShare(
        bytes32 _gameId
    )
        external
    {
        withdrawPotShareOnBehalf(_gameId, msg.sender);
    }

    function withdrawPotShareForAll(
        bytes32 _gameId
    )
        external
        whenNotShutdown
    {
        Game memory game = games[_gameId];
        _verifyAfterExit(game);
        (address stakeToken, uint stakeInWei) = configs.stakeConfigs(game.configId);
        (uint newPot, uint potShare) = _collectFees(_gameId, game, stakeToken, stakeInWei);
        uint8 numWithdrawals;
        for(uint playerId = 1; playerId <= game.numPlayers; playerId++) {
            PlayerInfo memory player = players[_gameId][playerId];
            if(player.withdrawal == Withdrawal.CREDITS) {
                _payPotShare(_gameId, potShare, player.account, stakeToken, stakeInWei);
                numWithdrawals++;
            }
        }
        games[_gameId].numPotClaims = game.numPotClaims - numWithdrawals;
        games[_gameId].pot = uint24(newPot - (numWithdrawals * potShare));
    }

    function withdrawInEmergency(
        bytes32 _gameId
    )
        external 
        whenShutdown 
    {
        uint playerId = playerIds[_gameId][msg.sender];
        require(playerId > 0, "!player");

        Game memory game = games[_gameId];
        uint share = game.pot / game.numPlayers;
        uint withdrawn = players[_gameId][playerId].withdrawn;

        if(withdrawn < share) {
            (address stakeToken, uint stakeInWei) = configs.stakeConfigs(games[_gameId].configId);
            uint refundInWei = (share - withdrawn) * stakeInWei / TICKS;
            Utils.pushToken(msg.sender, stakeToken, refundInWei);
            players[_gameId][playerId].withdrawn = uint24(share);
            // players[_gameId][playerId].withdrawal = Withdrawal.POT;
            // delete players[_gameId][playerId];
            // delete playerIds[_gameId][msg.sender];
            emit EmergencyWithdrawn(_gameId, msg.sender, stakeToken, refundInWei);
        }
    }

    ///////////////////////////////////
    // Private/Internal functions
    ///////////////////////////////////

    function _verifyDuringExit(
        Game memory _game
    ) 
        private
        view
    {
        (, uint64 playPeriod, uint64 exitPeriod,,) = configs.timeConfigs(_game.configId);
        (uint minPlayers,) = configs.playerConfigs(_game.configId);
        require(
            _game.numPlayers >= minPlayers && block.timestamp >= _game.startTime + playPeriod &&
            block.timestamp < _game.startTime + playPeriod + exitPeriod,
            "!during exit"
        );
    }

    function _verifyAfterExit(
        Game memory _game
    ) 
        private
        view
    {
        (, uint64 playPeriod, uint64 exitPeriod,,) = configs.timeConfigs(_game.configId);
         (uint minPlayers,) = configs.playerConfigs(_game.configId);
        require(_game.numPlayers >= minPlayers && block.timestamp >= _game.startTime + playPeriod + exitPeriod, "!post exit");
    }

    function _collectFees(
        bytes32 _gameId,
        Game memory _game,
        address _stakeToken,
        uint _stakeInWei
    )
        private     
        returns (uint newPot, uint potShare)
    {
        newPot = _game.pot;
        if(!feePaid[_gameId]) {
            uint govFee = newPot * ((_game.numPotClaims == 0) ? 10000 : configs.feesPer10000(_game.configId)) / 20000;
            uint dust = (_game.numPotClaims == 0) ? (_game.pot - 2 * govFee) : ((_game.pot - 2 * govFee) % _game.numPotClaims);
            uint sysFee = govFee + dust;
            if(govFee > 0) {
                address feeCollector = getFeeCollector(0);
                uint govFeeInWei = govFee * _stakeInWei / TICKS;
                feeBalances[feeCollector][_stakeToken] += govFeeInWei;
                emit FeeReceived(_gameId, feeCollector, _stakeToken, govFeeInWei);
            }
            if(sysFee > 0) {
                address feeCollector = getFeeCollector(getSysId(_gameId));
                uint sysFeeInWei = sysFee * _stakeInWei / TICKS;
                feeBalances[feeCollector][_stakeToken] += sysFeeInWei ;
                emit FeeReceived(_gameId, feeCollector, _stakeToken, sysFeeInWei);
            }
            newPot -= (govFee + sysFee);
            feePaid[_gameId] = true;
        }
        potShare = (_game.numPotClaims > 0) ? (newPot / _game.numPotClaims) : 0;
    }

    function _payPotShare(
        bytes32 _gameId,
        uint _potShare,
        address _player,
        address _stakeToken,
        uint _stakeInWei
    ) 
        private     
    {
        uint potShareInWei = _potShare * _stakeInWei / TICKS;
        uint256 playerId = playerIds[_gameId][_player];
        require(players[_gameId][playerId].withdrawal == Withdrawal.CREDITS, "!player"); // Check player is eligible to claim pot share
        if(potShareInWei > 0) {
            Utils.pushToken(_player, _stakeToken, potShareInWei);    
        }
        players[_gameId][playerId].withdrawal = Withdrawal.POT; // Mark the player as having claimed their pot share
        players[_gameId][playerId].withdrawn += uint24(_potShare);
        emit PotShareWithdrawn(_gameId, _player, _player, potShareInWei);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./GameBase.sol";
import "../Utils.sol";
import "../StarSystemData.sol";

abstract contract GameJoin is GameBase, Pausable {

    StarSystemData internal starSystemData;
    IERC721 internal tags;

    event GameJoined(address indexed _player, bytes32 indexed _gameId, uint _playerId, uint _commitment, bytes32 _tagId);
    event GameUnjoined(address indexed _player, bytes32 indexed _gameId);

    constructor(StarSystemData _data, IERC721 _tags) {
        starSystemData = _data;
        tags = _tags;
    }

    function pause(bool _enabled) external onlyOwner {
        if(_enabled) _pause();
        else _unpause();
    }

    function joinGame(
        uint _sysId,
        bytes32 _gameId,
        uint _commitment,
        uint _tagId
    )
        external
        payable
        whenNotPaused
    {
        require(_commitment > 0, "!comm");
        require(_tagId == 0 || tags.ownerOf(_tagId) == msg.sender, "!tag");

        bytes32 lastGameIdInSys = lastGameIds[_sysId];
        Game storage lastGame = games[lastGameIdInSys];
        uint8 numPlayers = lastGame.numPlayers;
        bytes32 configId = lastGame.configId;
        (uint minPlayers, uint maxPlayers) = configs.playerConfigs(configId);

        // solium-disable-next-line security/no-block-members
        if(lastGameIdInSys == 0 || (block.timestamp >= lastGame.startTime && numPlayers >= minPlayers)) {
            // lastGame has already started, so let's create a new game to join
            lastGameIdInSys = (lastGameIdInSys == 0) ? getGameId(_sysId, 0) : bytes32(uint(lastGameIdInSys) + 1); // {gameId:256} = {chainId:32}{versionId:32}{sysId:64}{gameCount:128}
            lastGameIds[_sysId] = lastGameIdInSys;
            configId = configs.configIds(_sysId);
            (minPlayers, maxPlayers) = configs.playerConfigs(configId);
            numPlayers = 0;
            lastGame = games[lastGameIdInSys];
            lastGame.configId = configId;
            lastGame.sysMap = starSystemData.mapOf(_sysId);
            (uint64 joinPeriod,,,,) = configs.timeConfigs(configId);
            // solium-disable-next-line security/no-block-members
            lastGame.startTime = uint64(block.timestamp) + joinPeriod;
        }

        // If _gameId is specified, make sure that it maches the id of the game
        // that the player is about to join.
        require(_gameId == 0 || _gameId == lastGameIdInSys, "!gameId");

        uint8 playerId;
        if(commitments[lastGameIdInSys][msg.sender] == 0) {
            (address stakeToken, uint stakeInWei) = configs.stakeConfigs(configId);
            Utils.pullToken(stakeToken, stakeInWei);
            assert(numPlayers < maxPlayers && maxPlayers <= 255);
            playerId = ++numPlayers;
            lastGame.numPlayers = numPlayers;
            lastGame.pot += TICKS;
            playerIds[lastGameIdInSys][msg.sender] = playerId;
            players[lastGameIdInSys][playerId].account = msg.sender;
            if(
                // condition1: we are past the join time but were waiting for one more player to join
                // condition2: this is the last player that can join
                // in both case, we wish to start the game right now.
                // solium-disable-next-line security/no-block-members
                (block.timestamp >= lastGame.startTime && numPlayers == minPlayers) || numPlayers == maxPlayers
            ) {
                // solium-disable-next-line security/no-block-members
                lastGame.startTime = uint64(block.timestamp);
            }
        } else {
            require(msg.value == 0, "!value");
            playerId = uint8(playerIds[lastGameIdInSys][msg.sender]);
        }

        commitments[lastGameIdInSys][msg.sender] = _commitment;
        emit GameJoined(msg.sender, lastGameIdInSys, playerId, _commitment, bytes32(_tagId));
    }

    function cancelJoinGame(
        uint _sysId
    )
        external
    {
        bytes32 lastGameIdInSys = lastGameIds[_sysId];
        Game storage lastGame = games[lastGameIdInSys];
        uint8 numPlayers = lastGame.numPlayers;
        bytes32 configId = lastGame.configId;
        (uint minPlayers,) = configs.playerConfigs(configId);
        require(
            // solium-disable-next-line security/no-block-members
            numPlayers < minPlayers || block.timestamp < lastGame.startTime,
            "!pre start");

        require(commitments[lastGameIdInSys][msg.sender] > 0, "!joined");
        delete commitments[lastGameIdInSys][msg.sender];

        uint256 playerId = playerIds[lastGameIdInSys][msg.sender];
        if(playerId < numPlayers) { // swap lastJoiner and msg.sender
            PlayerInfo memory lastJoiner = players[lastGameIdInSys][numPlayers];
            playerIds[lastGameIdInSys][lastJoiner.account] = playerId;
            players[lastGameIdInSys][playerId] = lastJoiner;
        }
        delete playerIds[lastGameIdInSys][msg.sender];
        delete players[lastGameIdInSys][numPlayers];

        (address stakeToken, uint stakeInWei) = configs.stakeConfigs(configId);
        lastGame.numPlayers--;
        lastGame.pot -= TICKS;
        Utils.pushToken(msg.sender, stakeToken, stakeInWei);
        emit GameUnjoined(msg.sender, lastGameIdInSys);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Verifier.sol";
import "./GameBase.sol";

abstract contract GamePlay is GameBase {

    event ActionsPerformed(
        bytes32 indexed _gameId,
        address indexed _player,
        uint _commitment,
        uint _newCommitment,
        uint _actions,
        uint _targetFuels,
        uint _items,
        bool _success,
        string _errorReason
    );

    // Used to avoid stack too deep error
    struct ActionsInfo {
        bytes32 gameId;
        bytes32 sysMap;
        uint actions;
        uint targetIds;
        uint targetFuels;
        uint items;
        uint commitment;
        uint newCommitment;
        uint[8] proof;
    }

    // External

    function performActions(
        ActionsInfo calldata actionsInfo
    )
        external
    {
        {
            Game memory game = games[actionsInfo.gameId];
            (uint minPlayers,) = configs.playerConfigs(game.configId);
            (, uint playPeriod,,,) = configs.timeConfigs(game.configId);
            // solium-disable-next-line security/no-block-members
            require(game.numPlayers >= minPlayers && block.timestamp >= game.startTime && block.timestamp < game.startTime + playPeriod, "!during play");
        }
        {
            bool success;
            string memory errorReason = "";

            try this.verifyProofAndPerformActions(actionsInfo, msg.sender) {
                success = true;
            } catch Error(string memory reason) {
                errorReason = reason;
            } catch (bytes memory) {}
            emit ActionsPerformed(actionsInfo.gameId, msg.sender, actionsInfo.commitment, actionsInfo.newCommitment, actionsInfo.actions, actionsInfo.targetFuels, actionsInfo.items, success, errorReason);
        }
    }

    function verifyProofAndPerformActions(
        ActionsInfo calldata actionsInfo,
        address _sender
    )
        external
    {
        require(msg.sender == address(this), "!this");
        require(actionsInfo.commitment == commitments[actionsInfo.gameId][_sender], "!comm");
        require(actionsInfo.sysMap == games[actionsInfo.gameId].sysMap, "!map");
        // verify proof
        _verifyProof(actionsInfo);
        // use items
        _performActions(actionsInfo.gameId, actionsInfo.sysMap, actionsInfo.actions, actionsInfo.targetIds, actionsInfo.items, _sender);
        // update commitment
        commitments[actionsInfo.gameId][_sender] = actionsInfo.newCommitment;
    }

    // Internal

    function getTargetPositions(uint _targetIds, bytes32 _sysMap) internal pure returns (uint _targetPositions) {
        uint numTargets = _targetIds & 255;  // the first byte in _targetIds is the number of targets
        require(numTargets <= 8, "!targets"); // Check whether the number of targets provided is too large
        _targetPositions = uint(numTargets);
        for(uint t = 1; t <= numTargets; t++) {
            uint targetId = (_targetIds >> 8*t) & 255;
            uint targetPos = (uint(_sysMap) >> (16*targetId + 8)) & 255;
            _targetPositions += uint(targetPos) << 8*t;
        }
    }

    function _verifyProof(
        ActionsInfo calldata actionsInfo
    )
        internal
        view
    {
        bytes32 configId = games[actionsInfo.gameId].configId;
        (uint itemPrices, uint itemMaxQuantities) = configs.itemConfigs(configId);

        uint[10] memory snark_input;
        snark_input[0] = actionsInfo.commitment;
        snark_input[1] = actionsInfo.newCommitment;
        snark_input[2] = uint(actionsInfo.sysMap);
        snark_input[3] = itemPrices;
        snark_input[4] = TICKS;
        snark_input[5] = itemMaxQuantities;
        snark_input[6] = actionsInfo.items;
        snark_input[7] = 0; // itemsReceived
        snark_input[8] = getTargetPositions(actionsInfo.targetIds, actionsInfo.sysMap);
        snark_input[9] = actionsInfo.targetFuels;
        require(Verifier.verifyProof(actionsInfo.proof, snark_input), "!proof");
    }

    // solium-disable-next-line security/no-assign-params
    function _performActions(
        bytes32 _gameId,
        bytes32 _sysMap,
        uint _actions,
        uint _targetIds,
        uint _items,
        address _sender
    )
        internal
    {
        uint numTargetsLeft = _targetIds & 255; // the first byte is the number of reached targets
        _targetIds >>= 8; // skip the first byte
        for(uint offset = 0; offset < 256 ; offset += 32) {
            // (_actions >> offset) & (2**32-1) == {ransom:8}{playerId:8}{targetId:8}{actionTypeId:8}
            uint actionTypeId = (_actions >> offset) & 255;
            if(actionTypeId > NUM_ACTIONS) revert("!actionType"); // Unsupported actionType
            ActionType actionType = ActionType(actionTypeId);
            if(actionType == ActionType.NONE) break; // no action left

            uint targetId = (_actions >> offset+8) & 255;
            if(actionType == ActionType.NUKE || actionType == ActionType.INTERCEPTOR || actionType == ActionType.JUMP) {
                // "Consume" next target. Note: detonations & defusions don't require fuel => don't consume targets from _targetIds for these two actions
                require(numTargetsLeft-- > 0, "!tgt0"); // Check whether the number of targets provided was too small
                require(_targetIds & 255 == targetId, "!tgt1"); // Check that there is no mismatch between the target id in the action and the next target provided
                _targetIds >>= 8;
            }

            uint playerId = (_actions >> offset+16) & 255;
            uint16 ransom = uint16((_actions >> offset+24) & 255) * 100; // "* 100" to convert ransom from credits to cents ("credit weis")

            uint qtyUsed; // Quantity of item used
            if(actionType == ActionType.CREDIT) {
                qtyUsed = ransom;
            } else if(actionType == ActionType.NUKE || actionType == ActionType.INTERCEPTOR || actionType == ActionType.JUMP) {
                qtyUsed = 1;
            }
            if(qtyUsed > 0) {
                uint qtyLeft = (_items >> 16 * uint(actionType)) & 65535;
                require(qtyUsed <= qtyLeft, "!items"); // Check whether sufficient item amounts are provided
                _items -= qtyUsed * (256 ** uint(actionType));
            }

            if(actionType != ActionType.JUMP) {
                _performAction(_gameId, _sysMap, actionType, targetId, playerId, ransom, _sender);
            }
        }
        require(numTargetsLeft == 0, "!tgt2"); // Check whether the number of targets provided is too large
    }

    // solium-disable-next-line security/no-assign-params
    function _performAction(
        bytes32 _gameId,
        bytes32 _sysMap,
        ActionType _actionType,
        uint _targetId,
        uint _playerId,
        uint16 _ransom,
        address sender
    )
        internal
    {
        Game storage game = games[_gameId];
        verifyTargetIsPlanet(_targetId, _sysMap);
        Ransom memory ransom = ransoms[_gameId][_targetId][_playerId];

        if(_actionType == ActionType.CREDIT || _actionType == ActionType.GAIN) {
            // solium-disable-next-line security/no-block-members
            require( // Check that there is a ransom to pay and check that we are not trying to pay too much ransom
                block.timestamp < ransom.destructionTime && ransom.paid < ransom.requested &&
                _ransom <= ransom.requested - ransom.paid, "!ransom"
            );
            if(_actionType == ActionType.GAIN) {
                // Check that we have enough gains
                uint senderId = playerIds[_gameId][sender];
                require(gains[_gameId][senderId] >= _ransom, "!gains");
                gains[_gameId][senderId] -= _ransom;
            }
            gains[_gameId][_playerId] += _ransom;
            ransoms[_gameId][_targetId][_playerId].paid += _ransom;
        }
        else if(_actionType == ActionType.NUKE) {
            require(_playerId == playerIds[_gameId][sender], "!nukerId");
            (, uint64 playPeriod,, uint64 ransomPeriod, uint64 gracePeriod) = configs.timeConfigs(game.configId);
            require( // Check that we are not attacking too soon or that the target is not already detonable
                ransom.destructionTime == 0 || (
                    // solium-disable-next-line security/no-block-members
                    ransom.requested > 0 &&
                    ransom.paid == ransom.requested &&
                    block.timestamp >= ransom.destructionTime + gracePeriod
                ),
                "!nukable"
            );
            // Check that there is enough time left to defend
            // solium-disable-next-line security/no-block-members
            require(block.timestamp + ransomPeriod < game.startTime + playPeriod, "!timeleft");
            // solium-disable-next-line security/no-block-members
            ransoms[_gameId][_targetId][_playerId].destructionTime = uint64(block.timestamp) + ransomPeriod;
            ransoms[_gameId][_targetId][_playerId].requested = _ransom;
            ransoms[_gameId][_targetId][_playerId].paid = 0;
        }
        else if (_actionType == ActionType.INTERCEPTOR) {
            // Check that there is something to counter
            // solium-disable-next-line security/no-block-members
            require(block.timestamp < ransom.destructionTime &&
                (ransom.requested == 0 ||
                ransom.paid < ransom.requested), "!attack");
            delete ransoms[_gameId][_targetId][_playerId];
        }
        else if (_actionType == ActionType.DETONATE) {
            require(_playerId == playerIds[_gameId][sender], "!detonatorId");
            require( // Check that we are not detonating too soon and that the target hasn't paid ransom
                // solium-disable-next-line security/no-block-members
                ransom.destructionTime > 0 && block.timestamp >= ransom.destructionTime &&
                (ransom.requested == 0 || ransom.paid < ransom.requested),
                "!detonable"
            );
            delete ransoms[_gameId][_targetId][_playerId];
            // apply damage to target
            games[_gameId].sysMap = bytes32(uint(_sysMap) - (uint(1) << 16 * _targetId));
        }
        else if (_actionType == ActionType.DEFUSE) {
            require(_playerId == playerIds[_gameId][sender], "!defuserId");
            require( // Check that we are not defusing a target that paid its ransom
                ransom.destructionTime > 0 && (ransom.requested == 0 || ransom.paid < ransom.requested),
                "!defusable"
            );
            delete ransoms[_gameId][_targetId][_playerId];
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./MiMC.sol";

contract Hasher {
    function hash3(uint256 _a, uint256 _b, uint256 _c) public pure returns (uint256 out) {
        uint256 k = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        uint256 R;
        uint256 C;

        R = addmod(R, _a, k);
        (R, C) = MiMC.MiMCSponge(R, C, 0);

        R = addmod(R, _b, k);
        (R, C) = MiMC.MiMCSponge(R, C, 0);

        R = addmod(R, _c, k);
        (R, C) = MiMC.MiMCSponge(R, C, 0);

        out = R;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

library MiMC {
    // The code of this function is generated in assembly by circomlib/src/mimcsponge_gencontract.js
    function MiMCSponge(uint256 in_xL, uint256 in_xR, uint256 in_k) public pure returns (uint256 xL, uint256 xR) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./StarSystemMapEditor.sol";

contract StarSystemConfigs is StarSystemMapEditor {
    struct PlayerConfig {
        uint8 minPlayers; // >= 2, <= 255
        uint8 maxPlayers; // >= 2, <= 255
    }

    struct ItemConfig {
        uint256 itemPrices;
        uint256 itemMaxQuantities;
    }

    struct TimeConfig {
        uint64 joinPeriod;
        uint64 playPeriod;
        uint64 exitPeriod;
        uint64 ransomPeriod;
        uint64 gracePeriod;
    }

    struct StakeConfig {
        address stakeToken;
        uint256 stakeInWei; // amount of tokens (in wei) staked by each player
    }

    mapping(uint => bytes32) public configIds; // [sysId] => [configId]
    mapping(bytes32 => TimeConfig) public timeConfigs; // [configId]
    mapping(bytes32 => uint16) public feesPer10000; // [configId]
    mapping(bytes32 => StakeConfig) public stakeConfigs; // [configId]
    mapping(bytes32 => ItemConfig) public itemConfigs; // [configId]
    mapping(bytes32 => PlayerConfig) public playerConfigs; // [configId]

    event ConfigCreated(address indexed _creator, bytes32 indexed _configId);
    event ConfigSet(uint indexed _sysId, bytes32 indexed _prevConfigId, bytes32 indexed _configId);

    constructor(StarSystemData _starSystemData, INftAuthoriser _authoriser) StarSystemMapEditor(_starSystemData, _authoriser) {}

    function createConfig(
        PlayerConfig memory _players,
        TimeConfig memory _times,
        ItemConfig memory _items,
        StakeConfig memory _stake,
        uint16 _feePer10000
    )
        public 
        returns (bytes32 configId)
    {
        configId = keccak256(abi.encodePacked(
            _stake.stakeToken, _stake.stakeInWei, 
            _times.joinPeriod, _times.playPeriod, _times.exitPeriod, _times.ransomPeriod, _times.gracePeriod,
            _items.itemPrices, _items.itemMaxQuantities,
            _players.minPlayers, _players.maxPlayers,
            _feePer10000
        ));

        if(playerConfigs[configId].minPlayers == 0) {
            require(_players.minPlayers >= 2 && _players.maxPlayers <= 255 && _players.minPlayers <= _players.maxPlayers, "bad player limit");
            require(_feePer10000 <= 10000, "fee too big");
            require(_times.playPeriod > _times.ransomPeriod, "playPeriod too small");
            require(_items.itemPrices <= 2**253 && _items.itemMaxQuantities <= 2**253, "item param too big"); // need to be < than snark field

            stakeConfigs[configId].stakeToken = _stake.stakeToken;
            stakeConfigs[configId].stakeInWei = _stake.stakeInWei;

            timeConfigs[configId].joinPeriod = _times.joinPeriod;
            timeConfigs[configId].playPeriod = _times.playPeriod;
            timeConfigs[configId].exitPeriod = _times.exitPeriod;
            timeConfigs[configId].ransomPeriod = _times.ransomPeriod;
            timeConfigs[configId].gracePeriod = _times.gracePeriod;

            itemConfigs[configId].itemPrices = _items.itemPrices;
            itemConfigs[configId].itemMaxQuantities = _items.itemMaxQuantities;

            playerConfigs[configId].minPlayers = _players.minPlayers;
            playerConfigs[configId].maxPlayers = _players.maxPlayers;

            feesPer10000[configId] = _feePer10000;

            emit ConfigCreated(msg.sender, configId);
        }
    }

    function setConfigId(
        uint _sysId, 
        bytes32 _configId
    ) 
        public 
        onlyAuthorised(_sysId)
    {
        require(playerConfigs[_configId].minPlayers > 0, "Invalid config");
        bytes32 prevConfigId = configIds[_sysId];
        configIds[_sysId] = _configId;
        emit ConfigSet(_sysId, prevConfigId, _configId);
    }

    function setConfig(
        uint _sysId, 
        PlayerConfig memory _players,
        TimeConfig memory _times,
        ItemConfig memory _items,
        StakeConfig memory _stake,
        uint16 _feePer10000
    ) 
        public 
        onlyAuthorised(_sysId)
    {
        bytes32 configId = createConfig(_players, _times, _items, _stake, _feePer10000);
        bytes32 prevConfigId = configIds[_sysId];
        configIds[_sysId] = configId;
        emit ConfigSet(_sysId, prevConfigId, configId);
    }

    function setMapAndConfigId(
        uint _sysId,
        bytes32 _sysMap,
        bytes32 _configId
    ) external {
        setConfigId(_sysId, _configId);
        setMap(_sysId, _sysMap);
    }

    function setMapAndConfig(
        uint _sysId,
        bytes32 _sysMap,
        PlayerConfig memory _players,
        TimeConfig memory _times,
        ItemConfig memory _items,
        StakeConfig memory _stake,
        uint16 _feePer10000
    ) external {
        setConfig(_sysId, _players, _times, _items, _stake, _feePer10000);
        setMap(_sysId, _sysMap);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../StarSystemData.sol";
import "../PlanetCounter.sol";
import "../auth/INftAuthoriser.sol";

abstract contract StarSystemMapEditor {
    using PlanetCounter for bytes32;

    StarSystemData public immutable starSystemData;
    StarSystems public immutable starSystems;
    INftAuthoriser public immutable authoriser;
    address immutable THIS = address(this);

    event MapSet(uint indexed _sysId, bytes32 indexed _prevMap, bytes32 indexed _sysMap);

    modifier onlyAuthorised(uint _sysId) {
        require(authoriser.isAuthorised(address(starSystems), _sysId, msg.sender, THIS, msg.data), "Unauthorised by system owner");
        _;
    }

    constructor(StarSystemData _starSystemData, INftAuthoriser _authoriser) { 
        starSystemData = _starSystemData;
        starSystems = _starSystemData.starSystems();
        authoriser = _authoriser;
    }

    function setMap(
        uint _sysId,
        bytes32 _sysMap
    ) 
        public 
        onlyAuthorised(_sysId)
    {
        require(_sysMap.planetCount() == starSystemData.mapOf(_sysId).planetCount(), "Map should keep same planet count");
        bytes32 prevMap = starSystemData.mapOf(_sysId);
        starSystemData.setMap(_sysId, _sysMap);
        emit MapSet(_sysId, prevMap, _sysMap);
    }
}

// SPDX-License-Identifier: UNLICENSED
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.5
//      fixed linter warnings
//      added requiere error messages
//
pragma solidity ^0.8.0;


library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

library Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() private pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(1872749200550459026557617531136303879001840460137015501273613269123933217224,3139653496956989378581690247931632345886614909325020086654699409326231309662);
        vk.beta2 = Pairing.G2Point([15647207464320270257541331782045103450759927353332528674874552677477240341540,17385825744853347032435272773528015675854907982676130368518330154617878018030], [21287097942804397481215486315401969341382925242332033055370141427860220084153,19560458014692109835511086215791320918430918510015603558586989341925227357139]);
        vk.gamma2 = Pairing.G2Point([12009571114618593786908111206842846178421201526592767157025383737732667112965,13573396023446860776713109364162426566679580718224691682087214034080230434238], [14751806744288470592434648823245265461609822707630708290054456849076771864288,10935645630695735502587005807838318049431589567123039525906087598800053174743]);
        vk.delta2 = Pairing.G2Point([20797352571216301048511085952152390966335638257871798432078130636660932641582,2680795829142070071858017051040641824246052911012431412994488837384839517503], [2908871942388252240202735756210041290549927860094542608970616502623048952147,9339134096061773870778938247312359986686491956591337991148912657421813254331]);
        vk.IC = new Pairing.G1Point[](11);
        vk.IC[0] = Pairing.G1Point(8002383693414650594394574035598188561164221770734133891839188121876145499737,6944660515822308570079751021545327794540332574178406164006010828710779453325);
        vk.IC[1] = Pairing.G1Point(19869938636480802207812560729473357842984687281936778511926713028273645293549,4580830726320258266158655380464406931376575176735242058934580149448143097383);
        vk.IC[2] = Pairing.G1Point(11877980370912123127925327306810981931726057340084255317532263594566573589369,6711211465734172926411145468091443890708570598013035998171987730635438050922);
        vk.IC[3] = Pairing.G1Point(1827529386603354228537485432189069156513848852372113134666180052230524854272,17985945715797035862654123735535854003025735045999753148266271015135081854527);
        vk.IC[4] = Pairing.G1Point(7757435047965532836765842947129568956221208923359033143443448845134177919706,842626523168875393502439890280584825499386956605915837860094841227678589231);
        vk.IC[5] = Pairing.G1Point(16477423357620429421983557854434067006893127226494245693176252185133548862478,11528322350505320396932221627438976069518294816772004871141847087647601676714);
        vk.IC[6] = Pairing.G1Point(2326790165779977099437552670927372171104405713029170653677002915339426835290,729374671375581936869816464166693647484979257530795615205446443260968007544);
        vk.IC[7] = Pairing.G1Point(1097547935400473031622101494623863831616176215943219418239290417111187633958,17945778542297349816602156170445141411001193663351343580950719119366256829261);
        vk.IC[8] = Pairing.G1Point(5500550678369205422742387120298285249725169080829167081256888049978857243764,5762962640807428467049764337413554799830662215440028925435755755337189959108);
        vk.IC[9] = Pairing.G1Point(17743461083730034148922086314231817821775235478953988702985475785869502658554,17663345386736354244914744111373043274559794755030804159494933819701576615144);
        vk.IC[10] = Pairing.G1Point(4807581899190642209359792770127534521370646769504460032506318935699809779581,222068516012082425816803145435076482931067227347044535057682089106662513053);
    }

    function verify(uint[] memory input, Proof memory proof) private view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }

    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[10] memory input
    ) private view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }

    function verifyProof(uint[8] memory proof, uint[10] memory inputs) public view returns (bool r) {
        return verifyProof(
            [proof[0], proof[1]],
            [[proof[2], proof[3]], [proof[4], proof[5]]],
            [proof[6], proof[7]],
            inputs);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./GameJoin.sol";
import "./GamePlay.sol";
import "./GameExit.sol";

contract ZkNukes is GameJoin, GamePlay, GameExit {
    constructor(
        IERC721 _tags,
        IERC721 _sys,
        StarSystemConfigs _configs,
        StarSystemData _data,
        INftAuthoriser _auth
    )
        GameBase(_configs)
        GameJoin(_data, _tags)
        GameExit(_sys, _auth)
    {
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./ZkNukes.sol";
import "../StarSystemData.sol";
import "../tags/Tags.sol";

// This is only used by the client to reduce the number of contract calls required
contract ZkNukesReader {
    ZkNukes public zk;
    StarSystemConfigs public configs;
    StarSystemData public ssd;
    Tags public tags;

    struct LobbyInfo {
        uint8 numPlayers;
        uint64 startTime;
        bytes32 configId;
        bytes32 sysMap;
        bytes32 gameId;
        address sysOwner;

        address stakeToken;
        uint256 stakeInWei;

        uint64 joinPeriod;
        uint64 playPeriod;
        uint64 exitPeriod;
        uint64 ransomPeriod;
        uint64 gracePeriod;

        uint8 minPlayers;
        uint8 maxPlayers;

        uint256 itemPrices;
        uint256 itemMaxQuantities;

        uint256 playerId;

        uint16 feePer10000;
        uint256 commitment;

        bytes32[] tags;
    }

    constructor(ZkNukes _zk, StarSystemConfigs _configs, StarSystemData _ssd, Tags _tags) {
        zk = _zk;
        configs = _configs;
        ssd = _ssd;
        tags = _tags;
    }

    function lobbyInfo(
        uint _sysId,
        address _account,
        bool _beforeLastGameStartTime
    )
        external
        view
        returns (
            LobbyInfo memory out
        )
    {
        out.gameId = zk.lastGameIds(_sysId);
        (out.numPlayers,,, out.startTime, out.configId, out.sysMap) = zk.games(out.gameId);
        (out.minPlayers, out.maxPlayers) = configs.playerConfigs(out.configId);

        // solium-disable-next-line security/no-block-members
        // if(out.gameId > 0 && (out.numPlayers < out.minPlayers || block.timestamp < out.startTime)) {
        if(out.gameId > 0 && out.numPlayers < out.maxPlayers && (
            out.numPlayers < out.minPlayers || _beforeLastGameStartTime
        )) {
            out.commitment = zk.commitments(out.gameId, _account);
        } else {
            out.gameId = (out.gameId == 0) ? zk.getGameId(_sysId, 0) : bytes32(uint(out.gameId) + 1);
            out.configId = configs.configIds(_sysId);
            (out.minPlayers, out.maxPlayers) = configs.playerConfigs(out.configId);
            out.sysMap = ssd.mapOf(_sysId);
            out.numPlayers = 0;
            out.startTime = 0;
        }

        (out.stakeToken, out.stakeInWei) = configs.stakeConfigs(out.configId);
        (out.joinPeriod, out.playPeriod, out.exitPeriod, out.ransomPeriod, out.gracePeriod) = configs.timeConfigs(out.configId);
        (out.itemPrices, out.itemMaxQuantities) = configs.itemConfigs(out.configId);
        out.feePer10000 = configs.feesPer10000(out.configId);
        out.sysOwner = ssd.ownerOf(_sysId);

        if(_account != address(0)) {
            uint numTags = tags.balanceOf(_account);
            out.tags = new bytes32[](numTags);
            for(uint i; i < numTags; i++) {
                out.tags[i] = bytes32(tags.tokenOfOwnerByIndex(_account, i));
            }

            uint playerId = zk.playerIds(out.gameId, _account);
            out.playerId = (playerId > 0) ? playerId : (out.numPlayers + 1);
        }
    }

    struct RansomInfo {
        uint targetId;
        uint playerId;
        uint16 requested;
        uint16 paid;
        uint64 destructionTime;
    }

    struct GameInfo {
        uint8 numPlayers;
        uint8 numPotClaims;
        uint24 pot;
        uint64 startTime;
        bytes32 configId;
        bytes32 sysMap;

        address stakeToken;
        uint256 stakeInWei;

        uint64 playPeriod;
        uint64 exitPeriod;
        uint64 ransomPeriod;
        uint64 gracePeriod;

        uint8 minPlayers;
        uint8 maxPlayers;

        uint256 itemPrices;
        uint256 itemMaxQuantities;

        uint256 playerId;
        uint256 gain;
        GameBase.Withdrawal withdrawStage;

        uint16 feePer10000;

        RansomInfo[] ransoms;
    }

    function gameInfo(
        bytes32 _gameId,
        uint _firstPlayerId,
        address _account
    )
        external
        view
        returns (
            GameInfo memory out
        )
    {
        (out.numPlayers, out.numPotClaims, out.pot, out.startTime, out.configId, out.sysMap) = zk.games(_gameId);
        (, out.playPeriod, out.exitPeriod, out.ransomPeriod, out.gracePeriod) = configs.timeConfigs(out.configId);
        (out.minPlayers, out.maxPlayers) = configs.playerConfigs(out.configId);
        (out.itemPrices, out.itemMaxQuantities) = configs.itemConfigs(out.configId);
        (out.stakeToken, out.stakeInWei) = configs.stakeConfigs(out.configId);
        out.playerId = zk.playerIds(_gameId, _account);
        (, out.withdrawStage,) = zk.players(_gameId, out.playerId);
        out.gain = zk.gains(_gameId, out.playerId);
        out.feePer10000 = configs.feesPer10000(out.configId);

        if(_firstPlayerId >= 1 && _firstPlayerId <= out.numPlayers) {
            uint numPlanets;
            for(uint targetId = 0; targetId < 16; targetId++)
                if((uint(out.sysMap) >> targetId * 16) & 3 > 0) numPlanets++;

            uint numPlayersRetrieved = (out.numPlayers <= 8 ? out.numPlayers : 8) - (_firstPlayerId - 1);
            RansomInfo[] memory ransoms = new RansomInfo[](numPlanets * numPlayersRetrieved);

            uint i;
            for(uint targetId = 0; targetId < 16; targetId++) {
                if((uint(out.sysMap) >> targetId * 16) & 3 > 0) { // targetId is a planet
                    for(uint playerId = _firstPlayerId; playerId < _firstPlayerId + numPlayersRetrieved; playerId++) {
                        (   ransoms[i].requested,
                            ransoms[i].paid,
                            ransoms[i].destructionTime
                        ) = zk.ransoms(_gameId, targetId, playerId);
                        if(ransoms[i].destructionTime > 0) {
                            (ransoms[i].targetId, ransoms[i].playerId) = (targetId, playerId);
                            i++;
                        }
                    }
                }
            }

            out.ransoms = new RansomInfo[](i);
            for(uint j; j < i; j++) {
                out.ransoms[j] = ransoms[j];
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Utils.sol";
import "./ITagPricer.sol";

abstract contract ERC721Buyable is ERC721 {
    using SafeERC20 for IERC20;

    // These need to be set by a child contract
    ITagPricer public pricer;
    address public issuer;

    mapping(uint => ITagPricer.Price) public requestedPrices;
    mapping(uint => ITagPricer.Price) public paidPrices;
    mapping(address => mapping(address => uint96)) public owed;

    event Purchased(uint indexed _tokenId, address indexed _from, address indexed _to, address _token, uint96 _price);
    event PriceChanged(uint indexed _tokenId, address _newToken, uint96 _paid, uint96 _newPrice);

    function priceOf(uint256 _tokenId, address _quoteToken) public view returns (ITagPricer.Price memory price) {
        if(!_exists(_tokenId)) {
            price = pricer.getMintPrice(_tokenId, _quoteToken);
        } else {
            price = requestedPrices[_tokenId];
        }
    }

    function buy(
        uint _tokenId,
        ITagPricer.Price calldata _paid,
        ITagPricer.Price calldata _newPrice
    ) 
        external
        payable 
    {
        buyFor(_tokenId, _paid, _newPrice, msg.sender);
    }

    function buyFor(
        uint _tokenId,
        ITagPricer.Price calldata _paid,
        ITagPricer.Price calldata _newPrice,
        address _recipient
    ) 
        public 
        payable 
    {
        require(pricer.isValidPrice(_newPrice, _paid), "!newPrice");
        ITagPricer.Price memory price;
        address prevOwner = _exists(_tokenId) ? ownerOf(_tokenId) : address(0);
        uint96 toPrevOwner;
        if(prevOwner == address(0)) {
            price = pricer.getMintPrice(_tokenId, _paid.token);
        } else {
            price = requestedPrices[_tokenId];
            toPrevOwner = price.amount;
        }
        require(price.amount > 0 && price.amount < type(uint96).max, "!price");
        require(_paid.token == price.token && _paid.amount >= price.amount, "!paid");

        // pay for tag
        Utils.pullToken(price.token, _paid.amount);
        if(toPrevOwner > 0) {
            owed[prevOwner][price.token] += toPrevOwner;
        }
        if(_paid.amount > toPrevOwner) {
            owed[issuer][price.token] += _paid.amount - toPrevOwner;
        }

        // transfer tag ownership
        if(prevOwner == address(0)) {
            _safeMint(_recipient, _tokenId);
        } else {
            _transfer(prevOwner, _recipient, _tokenId);
        }

        requestedPrices[_tokenId] = _newPrice;
        paidPrices[_tokenId] = _paid;

        emit Purchased(_tokenId, prevOwner, _recipient, price.token, price.amount);
        emit PriceChanged(_tokenId, _newPrice.token, _paid.amount, _newPrice.amount);
    }

    function changePrice(
        uint _tokenId,
        ITagPricer.Price calldata _newPaid,
        ITagPricer.Price calldata _newPrice
    ) external payable {
        require(ownerOf(_tokenId) == msg.sender, "!owner");
        require(pricer.isValidPrice(_newPrice, _newPaid), "!newPrice");

        // update paidPrices
        ITagPricer.Price memory paid = paidPrices[_tokenId];
        uint96 paidAmount;
        if(paid.token != _newPaid.token) {
            paidAmount = pricer.convert(paid, _newPaid.token);
            paidPrices[_tokenId].token = _newPaid.token;
        } else {
            paidAmount = paid.amount;
        }
        if(_newPaid.amount > paidAmount) {
            Utils.pullToken(_newPaid.token, _newPaid.amount - paidAmount);
            owed[issuer][_newPaid.token] += _newPaid.amount - paidAmount;
            paidAmount = _newPaid.amount;
        }
        if(paid.amount != paidAmount) {
            paidPrices[_tokenId].amount =  paidAmount;
        }

        // update requestedPrices
        requestedPrices[_tokenId] = _newPrice;

        emit PriceChanged(_tokenId, _newPrice.token, paidAmount, _newPrice.amount);
    }

    function withdrawProceeds(address _token, uint96 _amount) external {
        uint96 available = owed[msg.sender][_token];
        require(available > 0, "!owed");
        uint96 withdrawn = _amount >= available ? available : _amount;
        owed[msg.sender][_token] -= withdrawn;
        Utils.pushToken(msg.sender, _token, withdrawn);
    }
}

//SPDX-License-Identifier: Unlicense
// ref: https://github.com/ProjectOpenSea/meta-transactions/blob/main/contracts/ERC721MetaTransactionMaticSample.sol

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/ContextMixin.sol
 */
abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/EIP712Base.sol
 */
contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    
    bytes32 internal domainSeparator;

    // supposed to be called once while initializing.
    function _initializeEIP712(
        string memory name
    )
        internal
    {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(block.chainid)
            )
        );
    }

    function getDomainSeparator() public view returns (bytes32) {
        return domainSeparator;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash)
            );
    }
}

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/NativeMetaTransaction.sol
 */
contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] += 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

contract ERC721MetaTransaction is ERC721, ContextMixin, NativeMetaTransaction {
    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _initializeEIP712(_name);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./ITags.sol";

interface ITagDescriptor {
    function tokenURI(ITags _tags, uint _tokenId) external view returns (string memory);
    function contractURI(ITags _tags) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface ITagPricer {

    struct Price {
        address token;
        uint96 amount;
    }

    function getMintPrice(uint _tokenId, address /*_preferredPaymentToken*/) external view returns (Price memory price);
    function isValidPrice(Price calldata _price, Price calldata _paid) external view returns (bool);
    function convert(Price calldata _paid, address _toToken) external returns (uint96);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface ITags {
    function tagOf(uint _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "./ERC721Buyable.sol";
import "./ERC721MetaTransaction.sol";
import "./ITagDescriptor.sol";

contract Tags is
    ITags,
    Ownable,
    ERC721MetaTransaction("Tags", "TAG"),
    ERC721Enumerable,
    ERC721Pausable,
    ERC721Buyable
{

    ITagDescriptor public descriptor;

    constructor(ITagPricer _pricer, ITagDescriptor _descriptor, address _issuer) {
        issuer = _issuer;
        pricer = _pricer;
        descriptor = _descriptor;
    }

    /**
     * This is used instead of msg.sender as transactions won't necessarily be sent by the original token owner
     */
    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        // whitelist OpenSea Polygon proxy
        return (_operator == 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE) || super.isApprovedForAll(_owner, _operator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function ownerOf(uint256 _tokenId) public view override returns (address owner) {
        return _exists(_tokenId) ? super.ownerOf(_tokenId) : address(0);
    }

    function tagOf(uint256 _tokenId) external view override returns (string memory tag) {
        require(_exists(_tokenId), "Tags::tagOf: !tokenId");
        bytes32 tag32 = bytes32(_tokenId); // e.g. 0x0000000000000000000000000000000000000000000000000000000000414141
        uint len;
        while(tag32[31-len] > 0) len++;

        bytes memory tagBytes = new bytes(len);
        for(uint i; i < len; i++) {
           tagBytes[i] = tag32[32-len+i]; 
        }
        tag = string(tagBytes);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory metadata) {
        require(_exists(_tokenId), "Tags::tokenURI: !tokenId");
        return descriptor.tokenURI(this, _tokenId);
    }

    function contractURI() public view returns (string memory metadata) {
        return descriptor.contractURI(this);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function setPricer(ITagPricer _pricer) external onlyOwner {
        pricer = _pricer;
    }

    function setDescriptor(ITagDescriptor _descriptor) external onlyOwner {
        descriptor = _descriptor;
    }

    function setIssuer(address _issuer) external onlyOwner {
        issuer = _issuer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        return _owners[tokenId] != address(0);
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}