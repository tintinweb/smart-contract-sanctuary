//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./QuestingTimeKeeper.sol";

contract Questing is Initializable, QuestingTimeKeeper {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize() external initializer {
        QuestingTimeKeeper.__QuestingTimeKeeper_init();
    }

    function startQuests(
        uint256[] calldata _tokenIds,
        QuestDifficulty[] calldata _difficulties,
        uint256[] calldata _questLoops)
    external
    nonZeroLength(_tokenIds)
    contractsAreSet
    whenNotPaused
    onlyEOA
    {
        require(_tokenIds.length == _difficulties.length
            && _questLoops.length == _difficulties.length, "Bad number of difficulties");

        require(treasury.isBridgeWorldPowered(), "Bridge World not powered.");

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            LegionMetadata memory _legionMetadata = legionMetadataStore.metadataForLegion(_tokenIds[i]);

            if(_legionMetadata.legionGeneration == LegionGeneration.RECRUIT) {
                _startQuestRecruit(_tokenIds[i], _difficulties[i], _questLoops[i]);
            } else {
                _startQuest(_tokenIds[i], _difficulties[i], _questLoops[i], _legionMetadata);
            }
        }
    }

    function _startQuestRecruit(
        uint256 _tokenId,
        QuestDifficulty _difficulty,
        uint256 _numberLoops)
    private
    {
        require(_numberLoops == 1, "Max 1 loop for recruit legion");
        require(_difficulty == QuestDifficulty.EASY, "Easy only for recruit");

        userToQuestsInProgress[msg.sender].add(_tokenId);
        _startQuestTime(_tokenId);

        uint256 _requestId = randomizer.requestRandomNumber();
        tokenIdToRequestId[_tokenId] = _requestId;

        tokenIdToQuestDifficulty[_tokenId] = _difficulty;
        tokenIdToNumberLoops[_tokenId] = _numberLoops;

        // Transfer the legion to be staked in this contract. This will handle
        // cases when the user doesn't own the tokens
        legion.adminSafeTransferFrom(msg.sender, address(this), _tokenId);

        emit QuestStarted(msg.sender, _tokenId, _requestId, block.timestamp + difficultyToQuestLength[_difficulty]);
    }

    function _startQuest(
        uint256 _tokenId,
        QuestDifficulty _difficulty,
        uint256 _numberLoops,
        LegionMetadata memory _legionMetadata)
    private
    {
        uint256 _lpStaked = 0;

        // 1 loop does not require any staked LP
        if(_numberLoops != 1) {
            require(availableAutoQuestLoops.contains(_numberLoops), "Invalid number of loops");

            _lpStaked = difficultyToLPNeeded[_difficulty] * _numberLoops;
            if(_lpStaked > 0) {
                bool _lpSuccess = lp.transferFrom(msg.sender, address(this), _lpStaked);
                require(_lpSuccess, "LP transfer failed");
            }
        }

        uint8 _levelNeededForDifficulty = difficultyToLevelUnlocked[_difficulty];
        require(_legionMetadata.questLevel >= _levelNeededForDifficulty, "Difficult not unlocked.");

        userToQuestsInProgress[msg.sender].add(_tokenId);
        _startQuestTime(_tokenId);

        uint256 _requestId = randomizer.requestRandomNumber();
        tokenIdToRequestId[_tokenId] = _requestId;

        tokenIdToQuestDifficulty[_tokenId] = _difficulty;
        tokenIdToLPStaked[_tokenId] = _lpStaked;
        tokenIdToNumberLoops[_tokenId] = _numberLoops;

        // Transfer the legion to be staked in this contract. This will handle
        // cases when the user doesn't own the tokens
        legion.adminSafeTransferFrom(msg.sender, address(this), _tokenId);

        emit QuestStarted(msg.sender, _tokenId, _requestId, block.timestamp + difficultyToQuestLength[_difficulty]);
    }

    function revealTokensQuests(uint256[] calldata _tokenIds)
    external
    contractsAreSet
    whenNotPaused
    nonZeroLength(_tokenIds)
    onlyEOA
    {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(userToQuestsInProgress[msg.sender].contains(_tokenIds[i]), "Not owned by user");

            _revealQuest(_tokenIds[i]);
        }
    }

    function revealQuests()
    external
    contractsAreSet
    whenNotPaused
    onlyEOA
    {
        uint256[] memory _tokenIds = userToQuestsInProgress[msg.sender].values();

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            _revealQuest(_tokenId);
        }
    }

    function _revealQuest(uint256 _tokenId) private {
        uint256 _requestId = tokenIdToRequestId[_tokenId];
        if(_requestId == 0) {
            // Already revealed, just in the waiting period.
            return;
        }

        if(!randomizer.isRandomReady(_requestId)) {
            return;
        }

        QuestDifficulty _difficulty = tokenIdToQuestDifficulty[_tokenId];
        uint256 _randomNumber = randomizer.revealRandomNumber(_requestId);
        LegionMetadata memory _legionMetadata = legionMetadataStore.metadataForLegion(_tokenId);

        for(uint256 i = 0; i < tokenIdToNumberLoops[_tokenId]; i++) {
            // Ensure each loop has a different random number.
            _randomNumber = uint256(keccak256(abi.encode(_randomNumber, i)));

            if(_legionMetadata.legionGeneration == LegionGeneration.RECRUIT) {
                _calculateAndDistributeRewardRecruit(_tokenId, _randomNumber);
            } else {
                _calculateAndDistributeReward(_tokenId, _difficulty, _randomNumber);
                 // Process QP gain/level up.
                _processQPGainAndLevelUp(_tokenId, _legionMetadata.questLevel);
            }
        }

        delete tokenIdToRequestId[_tokenId];
        delete tokenIdToNumberLoops[_tokenId];
    }

    function _calculateAndDistributeRewardRecruit(
        uint256 _tokenId,
        uint256 _randomNumber)
    private {
        require(starlightId != 0
            && shardId != 0
            && universalLockId != 0, "Consumable ID not set");

        // Recruits are guaranteed starlight.
        uint8 _starlightAmount = recruitNumberOfStarlight;
        if(_starlightAmount > 0) {
            consumable.mint(msg.sender, starlightId, _starlightAmount);
        }

        uint8 _shardAmount = 0;

        if(recruitNumberOfCrystalShards > 0) {
            uint256 _shardResult = _randomNumber % 100000;

            _randomNumber = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

            if(_shardResult < recruitCrystalShardsOdds) {
                _shardAmount = recruitNumberOfCrystalShards;
                consumable.mint(msg.sender, shardId, _shardAmount);
            }
        }

        uint256 _universalLockResult = _randomNumber % 100000;
        uint8 _universalLockAmount = 0;
        if(_universalLockResult < recruitUniversalLockOdds) {
            consumable.mint(msg.sender, universalLockId, 1);
            _universalLockAmount = 1;
        }

        emit QuestRevealed(
            msg.sender,
            _tokenId,
            QuestReward(
                _starlightAmount,
                _shardAmount,
                _universalLockAmount,
                0
            )
        );
    }

    function _calculateAndDistributeReward(
        uint256 _tokenId,
        QuestDifficulty _difficulty,
        uint256 _randomNumber)
    private {
        require(starlightId != 0
            && shardId != 0
            && universalLockId != 0, "Consumable ID not set");

        // Every user is guaranteed 2 rewards per quest.
        uint8 _starlightAmount = difficultyToStarlightAmount[_difficulty];
        uint8 _shardAmount = difficultyToShardAmount[_difficulty];

        if(_starlightAmount > 0) {
            consumable.mint(msg.sender, starlightId, _starlightAmount);
        }
        if(_shardAmount > 0) {
            consumable.mint(msg.sender, shardId, _shardAmount);
        }

        uint256 _rewardedTreasureId = 0;

        uint256 _treasureResult = _randomNumber % 100000;
        if(_treasureResult < treasureDropOdds) {
            _randomNumber = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

            uint256 _treasureTierResult = _randomNumber % 100000;

            uint256[5] memory _tierOdds = difficultyToTierOdds[_difficulty];
            uint256 _topRange = 0;
            for(uint256 i = 0; i < _tierOdds.length; i++) {
                _topRange += _tierOdds[i];
                if(_treasureTierResult < _topRange) {
                    _randomNumber = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

                    // Tiers are 1 index based.
                    _rewardedTreasureId = treasureMetadataStore.getRandomTreasureForTier(uint8(i + 1), _randomNumber);

                    treasure.mint(msg.sender, _rewardedTreasureId, 1);
                }
            }
        }

        _randomNumber = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

        uint256 _universalLockResult = _randomNumber % 100000;
        uint8 _universalLockAmount = 0;
        if(_universalLockResult < universalLockDropOdds) {
            consumable.mint(msg.sender, universalLockId, 1);
            _universalLockAmount = 1;
        }

        emit QuestRevealed(
            msg.sender,
            _tokenId,
            QuestReward(
                _starlightAmount,
                _shardAmount,
                _universalLockAmount,
                _rewardedTreasureId
            )
        );
    }

    function _processQPGainAndLevelUp(uint256 _tokenId, uint8 _currentQuestLevel) private {
        // No need to do anything if they're at the max level.
        if(_currentQuestLevel >= maxQuestLevel) {
            return;
        }

        // Add QP relative to their current level.
        tokenIdToQP[_tokenId] += levelToQPGainedPerQuest[_currentQuestLevel];

        // While the user is not max level
        // and they have enough to go to the next level.
        while(_currentQuestLevel < maxQuestLevel
            && tokenIdToQP[_tokenId] >= levelToQPNeeded[_currentQuestLevel])
        {
            tokenIdToQP[_tokenId] -= levelToQPNeeded[_currentQuestLevel];
            legionMetadataStore.increaseQuestLevel(_tokenId);
            _currentQuestLevel++;
        }
    }

    function finishTokenQuests(uint256[] calldata _tokenIds)
    external
    contractsAreSet
    whenNotPaused
    nonZeroLength(_tokenIds)
    onlyEOA
    {
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(userToQuestsInProgress[msg.sender].contains(_tokenIds[i]), "Not owned by user");

            _finishQuest(_tokenIds[i]);
        }
    }

    function finishQuests()
    external
    contractsAreSet
    whenNotPaused
    onlyEOA
    {
        uint256[] memory _tokenIds = userToQuestsInProgress[msg.sender].values();

        for(uint256 i = 0; i < _tokenIds.length; i++) {
            _finishQuest(_tokenIds[i]);
        }
    }

    function _finishQuest(uint256 _tokenId) private {
        uint256 _requestId = tokenIdToRequestId[_tokenId];
        if(_requestId != 0) {
            // Has not revealed rewards yet!!
            return;
        }

        // Check if quest is done
        if(!_isQuestCooldownDone(_tokenId)) {
            return;
        }

        uint256 _lpStakedAmount = tokenIdToLPStaked[_tokenId];

        userToQuestsInProgress[msg.sender].remove(_tokenId);
        delete tokenIdToQuestDifficulty[_tokenId];
        delete tokenIdToQuestStartTime[_tokenId];
        delete tokenIdToLPStaked[_tokenId];

        legion.adminSafeTransferFrom(address(this), msg.sender, _tokenId);

        if(_lpStakedAmount > 0) {
            bool _lpSucceed = lp.transferFrom(address(this), msg.sender, _lpStakedAmount);
            require(_lpSucceed, "LP transfer failed");
        }

        emit QuestFinished(msg.sender, _tokenId);
    }

    function isQuestReadyToReveal(uint256 _tokenId) external view returns(bool) {
        uint256 _requestId = tokenIdToRequestId[_tokenId];
        require(_requestId > 0, "Not active or already revealed");

        return randomizer.isRandomReady(_requestId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./QuestingSettings.sol";

abstract contract QuestingTimeKeeper is Initializable, QuestingSettings {

    function __QuestingTimeKeeper_init() internal initializer {
        QuestingSettings.__QuestingSettings_init();
    }

    function _startQuestTime(uint256 _tokenId) internal {
        tokenIdToQuestStartTime[_tokenId] = block.timestamp;
    }

    function _isQuestCooldownDone(uint256 _tokenId) internal view returns(bool) {
        uint256 _startTime = tokenIdToQuestStartTime[_tokenId];
        QuestDifficulty _questDifficulty = tokenIdToQuestDifficulty[_tokenId];
        uint256 _cooldown = difficultyToQuestLength[_questDifficulty];
        return block.timestamp >= _startTime + _cooldown;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./QuestingContracts.sol";

abstract contract QuestingSettings is Initializable, QuestingContracts {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function __QuestingSettings_init() internal initializer {
        QuestingContracts.__QuestingContracts_init();
    }

    function setQuestLengths(
        uint256 _easyLength,
        uint256 _mediumLength,
        uint256 _hardLength)
    external
    onlyAdminOrOwner
    {
        difficultyToQuestLength[QuestDifficulty.EASY] = _easyLength;
        difficultyToQuestLength[QuestDifficulty.MEDIUM] = _mediumLength;
        difficultyToQuestLength[QuestDifficulty.HARD] = _hardLength;
    }

    function setLevelDifficultyUnlocks(
        uint8 _easyLevel,
        uint8 _mediumLevel,
        uint8 _hardLevel)
    external
    onlyAdminOrOwner
    {
        difficultyToLevelUnlocked[QuestDifficulty.EASY] = _easyLevel;
        difficultyToLevelUnlocked[QuestDifficulty.MEDIUM] = _mediumLevel;
        difficultyToLevelUnlocked[QuestDifficulty.HARD] = _hardLevel;
    }

    function setLevelSteps(
        uint8 _maxQuestLevel,
        uint256[] calldata _qpNeededForEachLevel,
        uint256[] calldata _qpGainedAtEachLevel
    )
    external
    onlyAdminOrOwner
    {
        require(_maxQuestLevel > 0, "Bad max level");
        require(_qpNeededForEachLevel.length == _maxQuestLevel - 1, "Not enough QP steps");
        require(_qpGainedAtEachLevel.length == _maxQuestLevel - 1, "Not enough QP gained steps");

        maxQuestLevel = _maxQuestLevel;

        delete levelToQPNeeded;
        delete levelToQPGainedPerQuest;

        levelToQPNeeded.push(0);
        levelToQPGainedPerQuest.push(0);

        for(uint256 i = 0; i < _maxQuestLevel - 1; i++) {
            levelToQPNeeded.push(_qpNeededForEachLevel[i]);
            levelToQPGainedPerQuest.push(_qpGainedAtEachLevel[i]);
        }
    }

    // Should be provided in order Easy, Medium, and Hard.
    function setGuaranteedDropAmounts(
        uint8[3] calldata _shardAmounts,
        uint8[3] calldata _starlightAmounts)
    external
    onlyAdminOrOwner
    {
        difficultyToStarlightAmount[QuestDifficulty.EASY] = _shardAmounts[0];
        difficultyToStarlightAmount[QuestDifficulty.MEDIUM] = _shardAmounts[1];
        difficultyToStarlightAmount[QuestDifficulty.HARD] = _shardAmounts[2];

        difficultyToShardAmount[QuestDifficulty.EASY] = _starlightAmounts[0];
        difficultyToShardAmount[QuestDifficulty.MEDIUM] = _starlightAmounts[1];
        difficultyToShardAmount[QuestDifficulty.HARD] = _starlightAmounts[2];
    }

    function setTreasureSettings(
        uint256 _treasureDropOdds,
        uint256 _universalLockDropOdds,
        uint256 _starlightId,
        uint256 _shardId,
        uint256 _universalLockId)
    external
    onlyAdminOrOwner {
        treasureDropOdds = _treasureDropOdds;
        starlightId = _starlightId;
        shardId = _shardId;
        universalLockDropOdds = _universalLockDropOdds;
        universalLockId = _universalLockId;
    }

    function setLPNeeded(uint256[3] calldata _lpNeeded) external onlyAdminOrOwner {
        difficultyToLPNeeded[QuestDifficulty.EASY] = _lpNeeded[0];
        difficultyToLPNeeded[QuestDifficulty.MEDIUM] = _lpNeeded[1];
        difficultyToLPNeeded[QuestDifficulty.HARD] = _lpNeeded[2];
    }

    function setAutoQuestLoops(uint256[] calldata _availableLoops) external onlyAdminOrOwner {
        uint256[] memory _oldValues = availableAutoQuestLoops.values();
        for(uint256 i = 0; i < _oldValues.length; i++) {
            availableAutoQuestLoops.remove(_oldValues[i]);
        }

        for(uint256 i = 0; i < _availableLoops.length; i++) {
            availableAutoQuestLoops.add(_availableLoops[i]);
        }
    }

    function setRecruitSettings(
        uint8 _recruitNumberOfStarlight,
        uint8 _recruitNumberOfCrystalShards,
        uint256 _recruitCrystalShardsOdds,
        uint256 _recruitUniversalLockOdds)
    external
    onlyAdminOrOwner
    {
        recruitNumberOfStarlight = _recruitNumberOfStarlight;
        recruitNumberOfCrystalShards = _recruitNumberOfCrystalShards;
        recruitCrystalShardsOdds = _recruitCrystalShardsOdds;
        recruitUniversalLockOdds = _recruitUniversalLockOdds;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./QuestingState.sol";

abstract contract QuestingContracts is Initializable, QuestingState {

    function __QuestingContracts_init() internal initializer {
        QuestingState.__QuestingState_init();
    }

    function setContracts(
        address _randomizerAddress,
        address _treasureAddress,
        address _legionAddress,
        address _treasureMetadataStoreAddress,
        address _legionMetadataStoreAddress,
        address _lpAddress,
        address _consumableAddress,
        address _treasuryAddress)
    external onlyAdminOrOwner
    {
        randomizer = IRandomizer(_randomizerAddress);
        treasure = ITreasure(_treasureAddress);
        legion = ILegion(_legionAddress);
        treasureMetadataStore = ITreasureMetadataStore(_treasureMetadataStoreAddress);
        legionMetadataStore = ILegionMetadataStore(_legionMetadataStoreAddress);
        lp = ILP(_lpAddress);
        consumable = IConsumable(_consumableAddress);
        treasury = ITreasury(_treasuryAddress);
    }

    modifier contractsAreSet() {
        require(address(randomizer) != address(0)
            && address(treasure) != address(0)
            && address(legion) != address(0)
            && address(treasureMetadataStore) != address(0)
            && address(legionMetadataStore) != address(0)
            && address(consumable) != address(0)
            && address(treasury) != address(0)
            && address(lp) != address(0), "Contracts aren't set");

        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";

import "../../shared/randomizer/IRandomizer.sol";
import "./IQuesting.sol";
import "../../shared/AdminableUpgradeable.sol";
import "../external/ITreasure.sol";
import "../external/ILP.sol";
import "../legion/ILegion.sol";
import "../consumable/IConsumable.sol";
import "../treasuremetadatastore/ITreasureMetadataStore.sol";
import "../legionmetadatastore/ILegionMetadataStore.sol";
import "../treasury/ITreasury.sol";

abstract contract QuestingState is Initializable, IQuesting, ERC721HolderUpgradeable, ERC1155HolderUpgradeable, AdminableUpgradeable {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    event QuestStarted(address indexed _owner, uint256 indexed _tokenId, uint256 indexed _requestId, uint256 _finishTime);
    event QuestRevealed(address indexed _owner, uint256 indexed _tokenId, QuestReward _reward);
    event QuestFinished(address indexed _owner, uint256 indexed _tokenId);

    IRandomizer public randomizer;
    ITreasure public treasure;
    ILegion public legion;
    IConsumable public consumable;
    ITreasureMetadataStore public treasureMetadataStore;
    ILegionMetadataStore public legionMetadataStore;
    ILP public lp;

    mapping(QuestDifficulty => uint256) public difficultyToQuestLength;
    mapping(QuestDifficulty => uint8) public difficultyToLevelUnlocked;
    mapping(QuestDifficulty => uint8) public difficultyToStarlightAmount;
    mapping(QuestDifficulty => uint8) public difficultyToShardAmount;
    // Ordered from tier 1 (index 0) -> tier 5 (index 4)
    mapping(QuestDifficulty => uint256[5]) public difficultyToTierOdds;
    mapping(QuestDifficulty => uint256) public difficultyToLPNeeded;

    uint8 public maxQuestLevel;
    uint256[] public levelToQPNeeded;
    uint256[] public levelToQPGainedPerQuest;

    mapping(address => EnumerableSetUpgradeable.UintSet) internal userToQuestsInProgress;

    mapping(uint256 => uint256) public tokenIdToQP;
    mapping(uint256 => uint256) public tokenIdToQuestStartTime;
    mapping(uint256 => uint256) public tokenIdToRequestId;
    mapping(uint256 => QuestDifficulty) public tokenIdToQuestDifficulty;
    mapping(uint256 => uint256) public tokenIdToLPStaked;
    mapping(uint256 => uint256) public tokenIdToNumberLoops;

    uint256 public treasureDropOdds;
    uint256 public universalLockDropOdds;
    uint256 public starlightId;
    uint256 public shardId;
    uint256 public universalLockId;

    EnumerableSetUpgradeable.UintSet internal availableAutoQuestLoops;

    uint8 public recruitNumberOfStarlight;
    uint8 public recruitNumberOfCrystalShards;
    // Out of 100,000
    uint256 public recruitCrystalShardsOdds;
    uint256 public recruitUniversalLockOdds;

    ITreasury public treasury;

    function __QuestingState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();
        ERC1155HolderUpgradeable.__ERC1155Holder_init();

        difficultyToQuestLength[QuestDifficulty.EASY] = 8 hours;
        difficultyToQuestLength[QuestDifficulty.MEDIUM] = 12 hours;
        difficultyToQuestLength[QuestDifficulty.HARD] = 16 hours;

        difficultyToLevelUnlocked[QuestDifficulty.EASY] = 1;
        difficultyToLevelUnlocked[QuestDifficulty.MEDIUM] = 3;
        difficultyToLevelUnlocked[QuestDifficulty.HARD] = 5;

        maxQuestLevel = 6;

        // Level starts at 1
        levelToQPNeeded.push(0);
        levelToQPNeeded.push(100);
        levelToQPNeeded.push(200);
        levelToQPNeeded.push(600);
        levelToQPNeeded.push(1500);
        levelToQPNeeded.push(2000);

        // Level starts at 1
        levelToQPGainedPerQuest.push(0);
        levelToQPGainedPerQuest.push(10);
        levelToQPGainedPerQuest.push(10);
        levelToQPGainedPerQuest.push(20);
        levelToQPGainedPerQuest.push(20);
        levelToQPGainedPerQuest.push(40);

        treasureDropOdds = 15000;
        universalLockDropOdds = 10;

        difficultyToTierOdds[QuestDifficulty.EASY] = [0, 2500, 5000, 15000, 77500];
        difficultyToTierOdds[QuestDifficulty.MEDIUM] = [1500, 5000, 7000, 17000, 69500];
        difficultyToTierOdds[QuestDifficulty.HARD] = [2500, 9000, 8000, 22000, 58500];

        availableAutoQuestLoops.add(3);
        availableAutoQuestLoops.add(9);
        availableAutoQuestLoops.add(15);

        difficultyToLPNeeded[QuestDifficulty.EASY] = 100 ether;
        difficultyToLPNeeded[QuestDifficulty.MEDIUM] = 200 ether;
        difficultyToLPNeeded[QuestDifficulty.HARD] = 300 ether;

        difficultyToStarlightAmount[QuestDifficulty.EASY] = 3;
        difficultyToStarlightAmount[QuestDifficulty.MEDIUM] = 4;
        difficultyToStarlightAmount[QuestDifficulty.HARD] = 5;

        difficultyToShardAmount[QuestDifficulty.EASY] = 3;
        difficultyToShardAmount[QuestDifficulty.MEDIUM] = 4;
        difficultyToShardAmount[QuestDifficulty.HARD] = 5;

        recruitNumberOfStarlight = 1;
        recruitNumberOfCrystalShards = 1;
        recruitCrystalShardsOdds = 50000;
        recruitUniversalLockOdds = 1;
    }
}

enum QuestDifficulty {
    EASY,
    MEDIUM,
    HARD
}

// This is okay to modify, as it used in an event rather than in state.
struct QuestReward {
    uint8 starlightAmount;
    uint8 crystalShardAmount;
    uint8 universalLockAmount;
    // The ID of the treasure received. Will be 0 if no treasure received.
    uint256 treasureId;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomizer {

    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns(uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuesting {

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasure {
    // Transfers the treasure at the given ID of the given amount.
    // Requires that the legions are pre-approved.
    //
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes memory data) external;

    // Transfers the treasure at the given ID of the given amount.
    //
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory data) external;

    // Admin only.
    //
    function mint(address _account, uint256 _tokenId, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILP {

    // Transfers the given amount to the recipient's wallet. Returns a boolean indicating if it was
    // successful or not.
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns(bool);

    // Transfer the given amount to the recipient's wallet. The sender is the caller of this function.
    // Returns a boolean indicating if it was successful or not.
    function transfer(address _recipient, uint256 _amount) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface ILegion is IERC721MetadataUpgradeable {

    // Mints a legion to the given address. Returns the token ID.
    // Admin only.
    function safeMint(address _to) external returns(uint256);

    // Sets the URI for the given token id. Token must exist.
    // Admin only.
    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;

    // Transfers the token to the given address. Does not need approval. _from still must be the owner of the token.
    // Admin only.
    function adminSafeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IConsumable is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    function adminSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external;

    function adminSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TreasureMetadataStoreState.sol";

interface ITreasureMetadataStore {
    // Sets the metadata for the given Ids.
    // Admin only.
    function setMetadataForIds(uint256[] calldata _ids, TreasureMetadata[] calldata _metadatas) external;

    // Returns if the given ID has metadata set.
    function hasMetadataForTreasureId(uint256 _treasureId) external view returns(bool);

    // Returns the metadata for the given ID. Reverts if no metadata for the ID is set.
    function getMetadataForTreasureId(uint256 _treasureId) external view returns(TreasureMetadata memory);

    // For the given tier, gets a random MINTABLE treasure id.
    function getRandomTreasureForTier(uint8 _tier, uint256 _randomNumber) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LegionMetadataStoreState.sol";

interface ILegionMetadataStore {
    // Sets the intial metadata for a token id.
    // Admin only.
    function setInitialMetadataForLegion(address _owner, uint256 _tokenId, LegionGeneration _generation, LegionClass _class, LegionRarity _rarity) external;

    // Increases the quest level by one. It is up to the calling contract to regulate the max quest level. No validation.
    // Admin only.
    function increaseQuestLevel(uint256 _tokenId) external;

    // Increases the craft level by one. It is up to the calling contract to regulate the max craft level. No validation.
    // Admin only.
    function increaseCraftLevel(uint256 _tokenId) external;

    // Increases the rank of the given constellation to the given number. It is up to the calling contract to regulate the max constellation rank. No validation.
    // Admin only.
    function increaseConstellationRank(uint256 _tokenId, Constellation _constellation, uint8 _to) external;

    // Returns the metadata for the given legion.
    function metadataForLegion(uint256 _tokenId) external view returns(LegionMetadata memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury {

    function isBridgeWorldPowered() external view returns(bool);

    function forwardCoinsToMine(uint256 _totalMagicSent) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../shared/AdminableUpgradeable.sol";
import "./ITreasureMetadataStore.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract TreasureMetadataStoreState is AdminableUpgradeable {

    mapping(uint8 => EnumerableSetUpgradeable.UintSet) internal tierToMintableTreasureIds;
    mapping(uint256 => TreasureMetadata) internal treasureIdToMetadata;

    function __TreasureMetadataStoreState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
    }
}

// Do not change. Stored in state.
struct TreasureMetadata {
    TreasureCategory category;
    uint8 tier;
    // Out of 100,000
    uint32 craftingBreakOdds;
    bool isMintable;
    uint256 consumableIdDropWhenBreak;
}

enum TreasureCategory {
    ALCHEMY,
    ARCANA,
    BREWING,
    ENCHANTER,
    LEATHERWORKING,
    SMITHING
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../shared/AdminableUpgradeable.sol";
import "./ILegionMetadataStore.sol";

abstract contract LegionMetadataStoreState is Initializable, AdminableUpgradeable {

    event LegionQuestLevelUp(uint256 indexed _tokenId, uint8 _questLevel);
    event LegionCraftLevelUp(uint256 indexed _tokenId, uint8 _craftLevel);
    event LegionConstellationRankUp(uint256 indexed _tokenId, Constellation indexed _constellation, uint8 _rank);
    event LegionCreated(address indexed _owner, uint256 indexed _tokenId, LegionGeneration _generation, LegionClass _class, LegionRarity _rarity);

    mapping(uint256 => LegionGeneration) internal idToGeneration;
    mapping(uint256 => LegionClass) internal idToClass;
    mapping(uint256 => LegionRarity) internal idToRarity;
    mapping(uint256 => uint8) internal idToQuestLevel;
    mapping(uint256 => uint8) internal idToCraftLevel;
    mapping(uint256 => uint8[6]) internal idToConstellationRanks;

    function __LegionMetadataStoreState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
    }
}

// As this will likely change in the future, this should not be used to store state, but rather
// as parameters and return values from functions.
struct LegionMetadata {
    LegionGeneration legionGeneration;
    LegionClass legionClass;
    LegionRarity legionRarity;
    uint8 questLevel;
    uint8 craftLevel;
    uint8[6] constellationRanks;
}

enum Constellation {
    FIRE,
    EARTH,
    WIND,
    WATER,
    LIGHT,
    DARK
}

enum LegionRarity {
    LEGENDARY,
    RARE,
    SPECIAL,
    UNCOMMON,
    COMMON,
    RECRUIT
}

enum LegionClass {
    RECRUIT,
    SIEGE,
    FIGHTER,
    ASSASSIN,
    RANGED,
    SPELLCASTER,
    RIVERMAN,
    NUMERAIRE,
    ALL_CLASS,
    ORIGIN
}

enum LegionGeneration {
    GENESIS,
    AUXILIARY,
    RECRUIT
}