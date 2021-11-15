// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

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
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StarSystemData is Ownable {

    struct SysData {
        bytes32 map;
        address owner;
    }

    uint public numSystems;
    mapping(uint => SysData) public sysData; // [sysId]
    mapping(address => bool) public dataEditors;

    event StarSystemMapSet(uint indexed _sysId, bytes32 _newMap);
    event StarSystemOwnerSet(uint indexed _sysId, address indexed _owner);
    event StarSystemDataCleared(uint indexed _sysId);

    modifier onlyDataEditor {
        require(dataEditors[msg.sender], "Unauthorised to change system data");
        _;
    }

    function ownerOf(uint _sysId) public view returns (address) { return sysData[_sysId].owner; }
    function mapOf(uint _sysId) external view returns (bytes32) { return sysData[_sysId].map; }

    function setDataEditor(address _editor, bool _added) external onlyOwner { 
        dataEditors[_editor] = _added; 
    }

    function setOwner(uint _sysId, address _owner) public onlyDataEditor {
        require(_owner != address(0), "_owner cannot be null");
        if(ownerOf(_sysId) == address(0)) {
            numSystems++;
        }
        sysData[_sysId].owner = _owner;
        emit StarSystemOwnerSet(_sysId, _owner);
    }

    function setMap(uint _sysId, bytes32 _sysMap) public onlyDataEditor {
        require(_sysMap > 0 && uint(_sysMap) < 2**253, "Invalid system map"); // _sysMap must be smaller than snark scalar field (=> have first 3 bits empty)
        sysData[_sysId].map = _sysMap;
        emit StarSystemMapSet(_sysId, _sysMap);
    }

    function setSystemData(uint _sysId, address _owner, bytes32 _sysMap) external onlyDataEditor {
        setOwner(_sysId, _owner);
        setMap(_sysId, _sysMap);
    }

    function clearSystemData(uint _sysId) external onlyDataEditor {
        require(ownerOf(_sysId) != address(0), "system data not set");
        numSystems--;
        delete sysData[_sysId];
        emit StarSystemDataCleared(_sysId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Utils {
    using SafeERC20 for IERC20;

    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function pullToken(address _token, uint256 _wei) internal {
        if (_token == ETH_TOKEN_ADDRESS) {
            require(msg.value == _wei, "Incorrect value sent");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _wei);
        }
    }

    function pushToken(address _token, uint256 _wei) internal {
        if (_token == ETH_TOKEN_ADDRESS) {
            // `msg.sender.transfer(_wei)` should be avoided, see https://diligence.consensys.net/blog/2019/09/stop-using-soliditys-transfer-now/
            // solium-disable-next-line security/no-call-value
            (bool success,) = msg.sender.call{value: _wei}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(_token).safeTransfer(msg.sender, _wei);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2; // required for blockscout verification

import "../Utils.sol";
import "./StarSystemConfigs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract GameBase {
    enum ActionType {NONE, CREDIT, NUKE, INTERCEPTOR, JUMP, GAIN}

    struct Game {
        uint8 numPlayers;
        uint64 startTime;
        bytes32 configId;
        bytes32 sysMap;
        uint256 pot;
        uint256 numPotClaims;
    }

    struct Ransom {
        uint16 requested;
        uint16 paid;
        uint64 destructionTime;
    }

    uint16 constant internal TICKS = 10000; // The budget, in credits; also the maximum qty of any item.
    
    StarSystemConfigs public configs;

    mapping(uint256 => Game) public games; // [gameId]
    mapping(uint256 => uint256) public lastGameIds; // [sysId]

    mapping(uint256 => mapping(address => uint256)) public commitments; // [gameId][player]
    mapping(uint256 => mapping(address => uint256)) public playerIds; // [gameId][player]
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Ransom))) public ransoms; // [gameId][targetId][playerId]
    // Player gains in ticks (stake unit)
    mapping(uint256 => mapping(uint256 => uint256)) public gains; // [gameId][playerId]

    constructor(StarSystemConfigs _cfg) {
        configs = _cfg;
    }

    function sponsor(uint256 _gameId, uint256 _amount) external payable {
        Game storage game = games[_gameId];
        (address stakeToken,) = configs.stakeConfigs(game.configId);
        Utils.pullToken(stakeToken, _amount);
        game.pot += _amount;
    }

    function verifyTargetIsPlanet(uint256 _targetId, bytes32 _sysMap)
        internal
        pure
    {
        require((uint(_sysMap) >> (_targetId * 16)) & 3 > 0, "No planet at target");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2; // required for blockscout verification

import "../Utils.sol";
import "./GameBase.sol";
import "./Hasher.sol";
import "./GameFee.sol";
import "./Owned.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract GameExit is GameBase, Hasher, Owned, GameFee {

    IERC721 public starSystems;

    event StakeExited(uint indexed _gameId, address indexed _player, uint _amount);
    event PotExited(uint indexed _gameId, address indexed _player, uint _amount);

    constructor(IERC721 _sys) {
        starSystems = _sys;
    }

    function exitStake(
        uint _gameId,
        uint _itemsLeft,
        uint _planetId,
        uint _secret
    )
        external
    {
        Game storage game = games[_gameId];
        bytes32 configId = game.configId;
        {
            (, uint64 playPeriod, uint64 exitPeriod,,) = configs.timeConfigs(configId);
            uint64 startTime = game.startTime;
            (uint minPlayers,) = configs.playerConfigs(configId);
            require(
                game.numPlayers >= minPlayers && block.timestamp >= startTime + playPeriod && block.timestamp < startTime + playPeriod + exitPeriod,
                "Should be during exit");
        }
        {
            (address stakeToken, uint stakeInWei) = configs.stakeConfigs(configId);
            require(hash3(_itemsLeft, uint(_planetId), _secret) == commitments[_gameId][msg.sender], "Invalid secret param(s)");
            verifyTargetIsPlanet(_planetId, game.sysMap); // _planetId could have been nuked
            uint playerId = playerIds[_gameId][msg.sender];
            uint credits = (_itemsLeft >> 16 * uint(ActionType.CREDIT)) & 65535;
            uint withdrawn = (credits + gains[_gameId][playerId]) * stakeInWei / TICKS;
            game.pot -= withdrawn;
            playerIds[_gameId][msg.sender] += 256; // mark the player as a survivor
            game.numPotClaims++;
            delete commitments[_gameId][msg.sender];
            delete gains[_gameId][playerId];
            Utils.pushToken(stakeToken, withdrawn);
            emit StakeExited(_gameId, msg.sender, withdrawn);
        }
    }

    function exitPot(
        uint _gameId
        // could take player address as argument
    )
        external
    {
        Game storage game = games[_gameId];
        bytes32 configId = game.configId;
        (, uint64 playPeriod, uint64 exitPeriod,,) = configs.timeConfigs(configId);
        (address stakeToken,) = configs.stakeConfigs(configId);
         (uint minPlayers,) = configs.playerConfigs(configId);

        require(game.numPlayers >= minPlayers && block.timestamp >= game.startTime + playPeriod + exitPeriod,
            "Should be after exit");
        require(playerIds[_gameId][msg.sender] > 256, "Not a survivor");
        uint potShare = game.pot / game.numPotClaims;
        uint creatorGain = potShare * configs.feesPer10000(configId) / 20000;
        uint withdrawn = potShare - 2 * creatorGain;
        require(withdrawn > 0, "Empty pot");
        feeBalances[owner][stakeToken] += creatorGain;
        uint sysId = (_gameId >> 128) & 0xFFFFFFFFFFFFFFFFFFFFFFFF; // gameId = {chainId:32}{sysId:96}{gameCount:128}
        feeBalances[starSystems.ownerOf(sysId)][stakeToken] += creatorGain;
        playerIds[_gameId][msg.sender] += 256; // mark the player as having claimed his pot share
        Utils.pushToken(stakeToken, withdrawn);
        emit PotExited(_gameId, msg.sender, withdrawn);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2; // required for blockscout verification

import "../Utils.sol";
abstract contract GameFee {

    mapping(address => mapping(address => uint)) feeBalances; // [recipient][token]

    function withdrawFeeBalance(address _token) external
    {
        uint withdrawn = feeBalances[msg.sender][_token];
        feeBalances[msg.sender][_token] = 0;
        Utils.pushToken(_token, withdrawn);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2; // required for blockscout verification

import "./GameBase.sol";
import "../Utils.sol";
import "../StarSystemData.sol";

abstract contract GameJoin is GameBase {

    StarSystemData public starSystemData;

    event GameJoined(address indexed _player, uint indexed _gameId, uint _commitment);
    event GameUnjoined(address indexed _player, uint indexed _gameId);

    constructor(StarSystemData _data) {
        starSystemData = _data;
    }

    function joinGame(
        uint _sysId,
        uint _gameId,
        uint _commitment
    )
        external
        payable
    {
        require(_commitment > 0, "Commitment cannot be 0");

        uint lastGameIdInSys = lastGameIds[_sysId];
        Game storage lastGame = games[lastGameIdInSys];
        bytes32 configId = lastGame.configId;
        (uint minPlayers, uint maxPlayers) = configs.playerConfigs(configId);

        // solium-disable-next-line security/no-block-members
        if(lastGameIdInSys == 0 || (block.timestamp >= lastGame.startTime && lastGame.numPlayers >= minPlayers)) {
            // lastGame has already started, so let's create a new game to join
            // gameId = {chainId:32}{sysId:96}{gameCount:128}
            lastGameIdInSys = (lastGameIdInSys == 0) ? ((getChainId() << 224) | (_sysId << 128)) : lastGameIdInSys + 1;
            lastGameIds[_sysId] = lastGameIdInSys;
            configId = configs.configIds(_sysId);
            (minPlayers, maxPlayers) = configs.playerConfigs(configId);
            lastGame = games[lastGameIdInSys];
            lastGame.configId = configId;
            lastGame.sysMap = starSystemData.mapOf(_sysId);
            (uint64 joinPeriod,,,,) = configs.timeConfigs(configId);
            // solium-disable-next-line security/no-block-members
            lastGame.startTime = uint64(block.timestamp) + joinPeriod;
        }

        // If _gameId is specified, make sure that it maches the id of the game
        // that the player is about to join.
        require(_gameId == 0 || _gameId == lastGameIdInSys, "wrong gameId");

        if(commitments[lastGameIdInSys][msg.sender] == 0) {
            (address stakeToken, uint stakeInWei) = configs.stakeConfigs(configId);
            Utils.pullToken(stakeToken, stakeInWei);
            lastGame.pot += stakeInWei;
            lastGame.numPlayers++;
            playerIds[lastGameIdInSys][msg.sender] = lastGame.numPlayers;
            if(
                // condition1: we are past the join time but were waiting for one more player to join
                // condition2: this is the last player that can join
                // in both case, we wish to start the game right block.timestamp.
                // solium-disable-next-line security/no-block-members
                (block.timestamp >= lastGame.startTime && lastGame.numPlayers == minPlayers) ||
                lastGame.numPlayers == maxPlayers
            ) {
                // solium-disable-next-line security/no-block-members
                lastGame.startTime = uint64(block.timestamp);
            }
        } else {
            require(msg.value == 0, "Shouldn't pay");
        }

        commitments[lastGameIdInSys][msg.sender] = _commitment;
        emit GameJoined(msg.sender, lastGameIdInSys, _commitment);
    }

    function cancelJoinGame(
        uint _sysId
    )
        external
    {
        uint lastGameIdInSys = lastGameIds[_sysId];
        Game storage lastGame = games[lastGameIdInSys];
        bytes32 configId = lastGame.configId;
        (uint minPlayers,) = configs.playerConfigs(configId);
        require(
            // solium-disable-next-line security/no-block-members
            lastGame.numPlayers < minPlayers || block.timestamp < lastGame.startTime,
            "Should be before play");
        require(commitments[lastGameIdInSys][msg.sender] > 0, "Player hasn't joined");
        delete commitments[lastGameIdInSys][msg.sender];
        (address stakeToken, uint stakeInWei) = configs.stakeConfigs(configId);
        lastGame.pot -= stakeInWei;
        lastGame.numPlayers--;
        emit GameUnjoined(msg.sender, lastGameIdInSys);
        Utils.pushToken(stakeToken, stakeInWei);
    }

    function getChainId() internal view returns (uint256 _id) {
        // solium-disable-next-line security/no-inline-assembly
        assembly { _id := chainid() }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

import "./Verifier.sol";
import "./GameBase.sol";

abstract contract GamePlay is GameBase, Verifier {

    event ActionsPerformed(
        uint indexed _gameId,
        address indexed _player,
        uint _commitment,
        uint _newCommitment,
        uint _actions,
        uint _targetFuels,
        uint _items,
        bool _success,
        string _errorReason
    );

    event TargetsDetonated(
        uint indexed _gameId,
        address indexed _player,
        uint _targetIds,
        bool _success,
        string _errorReason
    );

    // Used to avoid stack too deep error
    struct ActionsInfo {
        uint gameId;
        bytes32 sysMap;
        uint actions;
        uint targetIds;
        uint targetFuels;
        uint items;
        uint commitment;
        uint newCommitment;
    }

    // External

    function performActions(
        uint _gameId,
        bytes32 _sysMap,
        uint _actions,
        uint _targetIds,
        uint _targetFuels,
        uint _items,
        uint _commitment,
        uint _newCommitment,
        uint[8] calldata _proof
    )
        external
    {
        {
            Game storage game = games[_gameId];
            bytes32 configId = game.configId;
            uint64 startTime = game.startTime;
            (uint minPlayers,) = configs.playerConfigs(configId);
            (, uint playPeriod,,,) = configs.timeConfigs(game.configId);
            require(game.numPlayers >= minPlayers, "less than minPlayers");
            // solium-disable-next-line security/no-block-members
            require(block.timestamp >= startTime, "before startTime");
            // solium-disable-next-line security/no-block-members
            require(block.timestamp < startTime + playPeriod, "after playPeriod");
        }
        {
            bool success;
            string memory errorReason = "";
            ActionsInfo memory actionsInfo;
            actionsInfo.gameId = _gameId;
            actionsInfo.sysMap = _sysMap;
            actionsInfo.actions = _actions;
            actionsInfo.targetIds = _targetIds;
            actionsInfo.targetFuels = _targetFuels;
            actionsInfo.items = _items;
            actionsInfo.commitment = _commitment;
            actionsInfo.newCommitment = _newCommitment;

            try this.verifyProofAndPerformActions(_proof, actionsInfo, msg.sender) {
                success = true;
            } catch Error(string memory reason) {
                errorReason = reason;
            } catch (bytes memory) {}
            emit ActionsPerformed(_gameId, msg.sender, _commitment, _newCommitment, _actions, _targetFuels, _items, success, errorReason);
        }
    }

    function verifyProofAndPerformActions(
        uint[8] calldata _proof,
        ActionsInfo calldata actionsInfo,
        address _sender
    )
        external
    {
        require(msg.sender == address(this), "Caller should be this");
        require(actionsInfo.commitment == commitments[actionsInfo.gameId][_sender], "Incorrect commitment");
        require(actionsInfo.sysMap == games[actionsInfo.gameId].sysMap, "Incorrect system map");
        // verify proof
        _verifyProof(
            actionsInfo.gameId, actionsInfo.sysMap, actionsInfo.targetIds, actionsInfo.targetFuels,
            actionsInfo.items, actionsInfo.commitment, actionsInfo.newCommitment, _proof
        );
        // use items
        _performActions(actionsInfo.gameId, actionsInfo.sysMap, actionsInfo.actions, actionsInfo.targetIds, actionsInfo.items, _sender);
        // update commitment
        commitments[actionsInfo.gameId][_sender] = actionsInfo.newCommitment;
    }

    function detonate(
        uint _gameId,
        uint _targetIds
    )
        external
    {
        {
            Game storage game = games[_gameId];
            (, uint playPeriod,,,) = configs.timeConfigs(game.configId);
            require(
                // solium-disable-next-line security/no-block-members
                block.timestamp < game.startTime + playPeriod,
                "Should be before exit"
            );
        }
        {
            bool success;
            string memory errorReason = "";
            try this.verifyTargetAndApplyDamages(
                _gameId, _targetIds, msg.sender
            ) {
                success = true;
            } catch Error(string memory reason) {
                errorReason = reason;
            } catch (bytes memory) {}
            emit TargetsDetonated(_gameId, msg.sender, _targetIds, success, errorReason);
        }
    }

    function verifyTargetAndApplyDamages(
        uint _gameId, 
        uint _targetIds, 
        address _sender
    ) 
        external
    {
        require(msg.sender == address(this), "Caller should be this");
        Game storage game = games[_gameId];
        uint playerId = playerIds[_gameId][_sender];
        uint numTargets = _targetIds & 255;  // the first byte in _targetIds is the number of targets
        uint damages;
        for(uint t = 1; t <= numTargets; t++) {
            uint targetId = (_targetIds >> 8*t) & 255;
            verifyTargetIsPlanet(targetId, game.sysMap); // targetId could have been destroyed by another player
            Ransom storage ransom = ransoms[_gameId][targetId][playerId];
            uint64 destructionTime = ransom.destructionTime;
            require(
                // solium-disable-next-line security/no-block-members
                destructionTime > 0 && block.timestamp >= destructionTime &&
                (ransom.requested == 0 || ransom.paid < ransom.requested),
                "Detonating too soon or target ransomed"
            );
            delete ransoms[_gameId][targetId][playerId];
            damages += uint(1) << 16 * targetId;
        }
        // apply damages to targets
        game.sysMap = bytes32(uint(game.sysMap) - damages);
    }

    // Internal

    function getTargetPositions(uint _targetIds, bytes32 _sysMap) internal pure returns (uint _targetPositions) {
        uint numTargets = _targetIds & 255;  // the first byte in _targetIds is the number of targets
        require(numTargets <= 8, "Too many targets");
        _targetPositions = uint(numTargets);
        for(uint t = 1; t <= numTargets; t++) {
            uint targetId = (_targetIds >> 8*t) & 255;
            uint targetPos = (uint(_sysMap) >> (16*targetId + 8)) & 255;
            _targetPositions += uint(targetPos) << 8*t;
        }
    }

    function _verifyProof(
        uint _gameId,
        bytes32 _sysMap,
        uint _targetIds,
        uint _targetFuels,
        uint _items,
        uint _commitment,
        uint _newCommitment,
        uint[8] memory _proof
    )
        internal
        view
    {
        bytes32 configId = games[_gameId].configId;
        (uint itemPrices, uint itemMaxQuantities) = configs.itemConfigs(configId);

        uint[9] memory snark_input;
        snark_input[0] = _commitment;
        snark_input[1] = _newCommitment;
        snark_input[2] = uint(_sysMap);
        snark_input[3] = itemPrices;
        snark_input[4] = TICKS;
        snark_input[5] = itemMaxQuantities;
        snark_input[6] = _items;
        snark_input[7] = getTargetPositions(_targetIds, _sysMap);
        snark_input[8] = _targetFuels;
        require(verifyProof(_proof, snark_input), "Proof Verification Failed");
    }

    // solium-disable-next-line security/no-assign-params
    function _performActions(
        uint _gameId,
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
            // (_actions >> offset) & (2**32-1) == {ransom:8}{playerId:8}{targetId:8}{actionType:8}
            ActionType actionType = ActionType((_actions >> offset) & 255);
            if(actionType == ActionType.NONE) break; // no action left

            uint targetId = (_actions >> offset+8) & 255;
            if(actionType == ActionType.NUKE || actionType == ActionType.INTERCEPTOR || actionType == ActionType.JUMP) {
                require(numTargetsLeft-- > 0, "Too few targets");
                require(_targetIds & 255 == targetId, "Invalid target");
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
                require(qtyUsed <= qtyLeft, "Insufficient item amounts provided");
                _items -= qtyUsed * (256 ** uint(actionType));
            }

            if(actionType != ActionType.JUMP) {
                _performAction(_gameId, _sysMap, actionType, targetId, playerId, ransom, _sender);
            }
        }
        require(numTargetsLeft == 0, "Too many targets");
    }

    // solium-disable-next-line security/no-assign-params
    function _performAction(
        uint _gameId,
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
        if(_playerId == 0) _playerId = playerIds[_gameId][sender];
        Ransom storage ransom = ransoms[_gameId][_targetId][_playerId];

        if(_actionType == ActionType.CREDIT || _actionType == ActionType.GAIN) {
            // solium-disable-next-line security/no-block-members
            require(block.timestamp < ransom.destructionTime && ransom.paid < ransom.requested, "No ransom to pay");
            require(_ransom <= ransom.requested - ransom.paid, "Trying to pay too much ransom");
            if(_actionType == ActionType.GAIN) {
                require(gains[_gameId][playerIds[_gameId][sender]] >= _ransom, "Too few gains");
                gains[_gameId][playerIds[_gameId][sender]] -= _ransom;
            }
            gains[_gameId][_playerId] += _ransom;
            ransom.paid += _ransom;
        }
        else if(_actionType == ActionType.NUKE) {
            (, uint64 playPeriod,, uint64 ransomPeriod, uint64 gracePeriod) = configs.timeConfigs(game.configId);
            uint64 destructionTime = ransom.destructionTime;
            require(
                destructionTime == 0 || (
                    // solium-disable-next-line security/no-block-members
                    block.timestamp >= destructionTime + gracePeriod &&
                    ransom.requested > 0 &&
                    ransom.paid == ransom.requested
                ),
                "Attacking too soon or target already detonable"
            );
            // solium-disable-next-line security/no-block-members
            require(block.timestamp + ransomPeriod < game.startTime + playPeriod,
                "Should leave more time for defense");
            // solium-disable-next-line security/no-block-members
            ransom.destructionTime = uint64(block.timestamp) + ransomPeriod;
            ransom.requested = _ransom;
            ransom.paid = 0;
        }
        else if (_actionType == ActionType.INTERCEPTOR) {
            // solium-disable-next-line security/no-block-members
            require(block.timestamp < ransom.destructionTime &&
                (ransom.requested == 0 ||
                ransom.paid < ransom.requested), "Nothing to counter");
            delete ransoms[_gameId][_targetId][_playerId];
        }
        else {
            revert("Unsupported actionType");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2; // required for blockscout verification

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
pragma solidity ^0.8.3;

library MiMC {
    // The code of this function is generated in assembly by circomlib/src/mimcsponge_gencontract.js
    function MiMCSponge(uint256 in_xL, uint256 in_xR, uint256 in_k) public pure returns (uint256 xL, uint256 xR) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2; // required for blockscout verification

/********************************************************************************
This contract is (roughly) similar to @openzeppelin/contracts/access/Ownable.sol
but adds a 'pragma experimental ABIEncoderV2', to help blockscout verification
*********************************************************************************/

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

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

    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(uint => bytes32) public configIds; // [sysId] => [configId]
    mapping(bytes32 => TimeConfig) public timeConfigs; // [configId]
    mapping(bytes32 => uint16) public feesPer10000; // [configId]
    mapping(bytes32 => StakeConfig) public stakeConfigs; // [configId]
    mapping(bytes32 => ItemConfig) public itemConfigs; // [configId]
    mapping(bytes32 => PlayerConfig) public playerConfigs; // [configId]

    event ConfigCreated(address _creator, bytes32 _configId);
    event ConfigSelected(uint indexed _sysId, bytes32 _configId);

    constructor(StarSystemData _starSystemData) StarSystemMapEditor(_starSystemData) {}

    function createConfig(
        uint256 _sysId,
        bytes32 _sysMap,
        PlayerConfig memory _players,
        TimeConfig memory _times,
        ItemConfig memory _items,
        StakeConfig memory _stake,
        uint16 _feePer10000
    )
        public
    {
        bytes32 configId = keccak256(abi.encodePacked(
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

        if(_sysId > 0) {
            changeConfigId(_sysId, configId);
            if(_sysMap > 0) {
                changeMap(_sysId, _sysMap);
            }
        }
    }

    function changeConfigId(uint _sysId, bytes32 _configId) public {
        require(starSystemData.ownerOf(_sysId) == msg.sender, "Should be system owner");
        require(playerConfigs[_configId].minPlayers > 0, "Invalid config");
        configIds[_sysId] = _configId;
        emit ConfigSelected(_sysId, _configId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "../StarSystemData.sol";
import "../../common/PlanetCounter.sol";

abstract contract StarSystemMapEditor {
    using PlanetCounter for bytes32;

    StarSystemData public immutable starSystemData;

    constructor(StarSystemData _starSystemData) { 
        starSystemData = _starSystemData;
    }

    function changeMap(uint _sysId, bytes32 _sysMap) public {
        require(msg.sender == starSystemData.ownerOf(_sysId), "sender should be system owner");
        require(_sysMap.planetCount() == starSystemData.mapOf(_sysId).planetCount(), "Map should keep same planet count");
        starSystemData.setMap(_sysId, _sysMap);
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
pragma experimental ABIEncoderV2; // required for blockscout verification

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
contract Verifier {
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
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(17855420873365690298265639338768426341437908943174548478443750013534499456391,10739740892529684450630703052085452303316573147852110552817924908202391491515);
        vk.beta2 = Pairing.G2Point([1678579998498212382158409813895165686496953421011523452008564866336144076838,8432466975306913768334083185748762032178525028605835646997458683050598708972], [19246446188315810307242302251036404501042323216943087994570095176991275849482,16613451748500201960355928938232947015058889080754223807357676746598064688665]);
        vk.gamma2 = Pairing.G2Point([9919563946190952557259697204305680204092282684505675063900523728439719826510,10926659560639254167058199980952042006681562030053927131819077109891475292538], [21013588849697386916482760517893020849569981813402280081046748948645378056508,11479288026153172033792431434263248238095838884815997632744520599365471308323]);
        vk.delta2 = Pairing.G2Point([13218026278264193365168580313224951440250775485621686921761398122990726193890,9622561087966079097459596446428573212012431365461840605703753362550177124953], [14327190329780317687376593953736398661065823120271086352845273325094718574976,1594887632619976525876708515073407282081465123151039891800349045299525030350]);
        vk.IC = new Pairing.G1Point[](10);
        vk.IC[0] = Pairing.G1Point(10929661146442482393197882970530343529059022205251970871020160702816398836051,20701018041457771276988002158203708426510890334336786347193755966284351712078);
        vk.IC[1] = Pairing.G1Point(10823831896579438231602314013201755043281989202567852652100151920694332819382,17160706939958906437997717153355144015328171401917197062056830456053318071774);
        vk.IC[2] = Pairing.G1Point(1959360590651220908099778022871829170793175333957607378830730160640209342029,5532279938419235533945093758189862406099103154023951547261419071309533535942);
        vk.IC[3] = Pairing.G1Point(16282574892460153587345736689009550923828482993670249597045738648703182121296,11969948686183370615081518887490403777652822588716104909525965606111264088156);
        vk.IC[4] = Pairing.G1Point(1478157300982583566018562191565782970787464131381493164432370835018178337311,18488546386000162707616740747887312411912271519693645950761698702066332343545);
        vk.IC[5] = Pairing.G1Point(18229597231421254273914691887076373222979795535136931363758291035726002402792,1891338222454863731358823477059924586825182364702555893082142327846648000558);
        vk.IC[6] = Pairing.G1Point(9573819874629296989341684656328875632598759571250889032026667935795522304679,408608413030235165914488390312308387068352252993191447878465487221803631418);
        vk.IC[7] = Pairing.G1Point(725390664711027000314611032606730499403976168023154104272926623055799910829,6328630493685838088307996794259292365111227849382545839415328459150777303494);
        vk.IC[8] = Pairing.G1Point(16858344111835383319596730181125273161392276254873882486837890082681779106401,10742473442001422195941992439972117727428185799206347772560807513360481428263);
        vk.IC[9] = Pairing.G1Point(18084550531273455661129988204088061074841215462048370573814394462786865372229,8414380790567496520982255365669701072734205202420067954247677659848387531846);

    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
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
            uint[9] memory input
        ) public view returns (bool r) {
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
    function verifyProof(uint[8] memory proof, uint[9] memory inputs) public view returns (bool r) {
        return verifyProof(
            [proof[0], proof[1]],
            [[proof[2], proof[3]], [proof[4], proof[5]]],
            [proof[6], proof[7]],
            inputs);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

import "./GameJoin.sol";
import "./GamePlay.sol";
import "./GameExit.sol";

contract ZkNukes is GameJoin, GamePlay, GameExit {
    constructor(
        IERC721 _sys,
        StarSystemConfigs _configs,
        StarSystemData _data
    )
        GameBase(_configs)
        GameJoin(_data)
        GameExit(_sys)
    {
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

