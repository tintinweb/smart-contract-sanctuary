// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "./../interfaces/IBridge.sol";
import "./../libraries/ECDSA.sol";

import "./../utils/Cache.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


/// @title Ethereum Bridge contract
/// @author https://github.com/broxus
/// @dev Stores relays for each round, implements slashing, helps in validating TON-ETH events
contract Bridge is OwnableUpgradeable, PausableUpgradeable, Cache, IBridge {
    using ECDSA for bytes32;

    // NOTE: round number -> address -> is relay?
    mapping (uint32 => mapping(address => bool)) public relays;

    // NOTE: is relay banned or not
    mapping (address => bool) public blacklist;

    // NOTE: round meta data
    mapping (uint32 => Round) public rounds;

    // NOTE: signature verifications always fails is emergency is on
    bool public emergencyShutdown;

    // NOTE: The required signatures per round can't be less than this
    uint32 public minimumRequiredSignatures;

    // NOTE: how long round signatures are considered valid after the end of the round
    uint32 public roundTTL;

    // NOTE: initial round number
    uint32 public initialRound;

    // NOTE: last round with known relays
    uint32 public lastRound;

    // NOTE: special address, can set up rounds without relays's signatures
    address public roundSubmitter;

    // NOTE: Broxus Bridge TON-ETH configuration address, that emits event with round relays
    TONAddress public roundRelaysConfiguration;

    /**
        @notice
            Bridge initializer
        @dev
            `roundRelaysConfiguration` should be specified later.
        @param _owner Bridge owner
        @param _roundSubmitter Round submitter
        @param _minimumRequiredSignatures Minimum required signatures per round.
        @param _roundTTL Round TTL after round ends.
        @param _initialRound Initial round number. Useful in case new EVM network is connected to the bridge.
        @param _initialRoundEnd Initial round end timestamp.
        @param _relays Initial set of relays. Encode addresses as uint160
    */
    function initialize(
        address _owner,
        address _roundSubmitter,
        uint32 _minimumRequiredSignatures,
        uint32 _roundTTL,
        uint32 _initialRound,
        uint32 _initialRoundEnd,
        uint160[] calldata _relays
    ) external initializer {
        __Pausable_init();
        __Ownable_init();
        transferOwnership(_owner);

        roundSubmitter = _roundSubmitter;
        emit UpdateRoundSubmitter(_roundSubmitter);

        minimumRequiredSignatures = _minimumRequiredSignatures;
        emit UpdateMinimumRequiredSignatures(minimumRequiredSignatures);

        roundTTL = _roundTTL;
        emit UpdateRoundTTL(roundTTL);

        require(
            _initialRoundEnd >= block.timestamp,
            "Bridge: initial round end should be in the future"
        );

        initialRound = _initialRound;
        _setRound(initialRound, _relays, _initialRoundEnd);

        lastRound = initialRound;
    }

    /**
        @notice
            Update address of configuration, that emits event with next round relays.
        @param _roundRelaysConfiguration TON address of configuration
    */
    function updateRoundRelaysConfiguration(
        TONAddress calldata _roundRelaysConfiguration
    ) external override onlyOwner {
        emit UpdateRoundRelaysConfiguration(_roundRelaysConfiguration);

        roundRelaysConfiguration = _roundRelaysConfiguration;
    }

    /**
        @notice
            Pause Bridge contract.
        @dev
            When Bridge paused, signature verification fails.
    */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
        @notice
            Unpause Bridge contract.
    */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
        @notice
            Update minimum amount of required signatures per round
        @param _minimumRequiredSignatures New value
    */
    function updateMinimumRequiredSignatures(
        uint32 _minimumRequiredSignatures
    ) external override onlyOwner {
        minimumRequiredSignatures = _minimumRequiredSignatures;

        emit UpdateMinimumRequiredSignatures(_minimumRequiredSignatures);
    }

    /**
        @notice
            Update round TTL
        @dev
            This affects only future rounds. Rounds, that were already set,
            keep their current TTL.
        @param _roundTTL New TTL value
    */
    function updateRoundTTL(
        uint32 _roundTTL
    ) external override onlyOwner {
        roundTTL = _roundTTL;

        emit UpdateRoundTTL(_roundTTL);
    }

    /// @dev Check if relay is banned.
    /// Ban is global. If the relay is banned it means it lost
    /// relay power in all rounds, past and future.
    /// @param candidate Address to check
    function isBanned(
        address candidate
    ) override public view returns(bool) {
        return blacklist[candidate];
    }

    /// @dev Check if some address is relay at specific round
    /// @param round Round id
    /// @param candidate Address to check
    function isRelay(
        uint32 round,
        address candidate
    ) override public view returns (bool) {
        return relays[round][candidate];
    }

    /// @dev Check if round is rotten
    /// @param round Round id
    function isRoundRotten(
        uint32 round
    ) override public view returns (bool) {
        return block.timestamp > rounds[round].ttl;
    }

    /**
        @notice
            Verify payload signatures.
        @dev
            Signatures should be sorted by the ascending signers.
            Error codes:
                0. Verification passed (no error)
                1. Specified round is less than `initialRound`
                2. Specified round is more than `lastRound`
                3. Not enough correct signatures. Possible reasons:
                    - Some of the signers are not relays at the specified round
                    - Some of the signers are banned
                4. Round is rotten.
                5. Everything is correct, but bridge is in "paused" state

        @param payload Bytes encoded TONEvent structure
        @param signatures Payload signatures
        @return errorCode Error code
    */
    function verifySignedTonEvent(
        bytes memory payload,
        bytes[] memory signatures
    )
        override
        public
        view
    returns (
        uint32 errorCode
    ) {
        (TONEvent memory tonEvent) = abi.decode(payload, (TONEvent));

        uint32 round = tonEvent.round;

        // Check round is not less than initial round
        if (round < initialRound) return 1;

        // Check round is not more than last initialized round
        if (round > lastRound) return 2;

        // Check there are enough correct signatures
        uint32 count = _countRelaySignatures(payload, signatures, round);
        if (count < rounds[round].requiredSignatures) return 3;

        // Check round rotten
        if (isRoundRotten(round)) return 4;

        // Check bridge has been paused
        if (paused()) return 5;

        return 0;
    }

    /**
        @notice
            Recover signer from the payload and signature
        @param payload Payload
        @param signature Signature
    */
    function recoverSignature(
        bytes memory payload,
        bytes memory signature
    ) public pure returns (address signer) {
        signer = keccak256(payload)
            .toBytesPrefixed()
            .recover(signature);
    }

    /**
        @notice Forced set of next round relays
        @dev Can be called only by `roundSubmitter`
        @param _relays Next round relays
        @param roundEnd Round end
    */
    function forceRoundRelays(
        uint160[] calldata _relays,
        uint32 roundEnd
    ) override external {
        require(msg.sender == roundSubmitter, "Bridge: sender not round submitter");

        _setRound(lastRound + 1, _relays, roundEnd);

        lastRound++;
    }

    /**
        @notice Set round submitter
        @dev Can be called only by owner
        @param _roundSubmitter New round submitter address
    */
    function setRoundSubmitter(
        address _roundSubmitter
    ) override external onlyOwner {
        roundSubmitter = _roundSubmitter;

        emit UpdateRoundSubmitter(roundSubmitter);
    }

    /**
        @dev Grant relay permission for set of addresses at specific round
        @param payload Bytes encoded TONEvent structure
        @param signatures Payload signatures
    */
    function setRoundRelays(
        bytes calldata payload,
        bytes[] calldata signatures
    ) override external notCached(payload) {
        require(
            verifySignedTonEvent(
                payload,
                signatures
            ) == 0,
            "Bridge: signatures verification failed"
        );

        (TONEvent memory tonEvent) = abi.decode(payload, (TONEvent));

        require(
            tonEvent.configurationWid == roundRelaysConfiguration.wid &&
            tonEvent.configurationAddress == roundRelaysConfiguration.addr,
            "Bridge: wrong event configuration"
        );

        (uint32 round, uint160[] memory _relays, uint32 roundEnd) = decodeRoundRelaysEventData(payload);

        require(round == lastRound + 1, "Bridge: wrong round");

        _setRound(round, _relays, roundEnd);

        lastRound++;
    }

    function decodeRoundRelaysEventData(
        bytes memory payload
    ) public pure returns(
        uint32 round,
        uint160[] memory _relays,
        uint32 roundEnd
    ) {
        (TONEvent memory tonEvent) = abi.decode(payload, (TONEvent));

        (round, _relays, roundEnd) = abi.decode(
            tonEvent.eventData,
            (uint32, uint160[], uint32)
        );
    }

    function decodeTonEvent(
        bytes memory payload
    ) external pure returns (TONEvent memory tonEvent) {
        (tonEvent) = abi.decode(payload, (TONEvent));
    }

    /**
        @notice
            Ban relays
        @param _relays List of relay addresses to ban
    */
    function banRelays(
        address[] calldata _relays
    ) override external onlyOwner {
        for (uint i=0; i<_relays.length; i++) {
            blacklist[_relays[i]] = true;

            emit BanRelay(_relays[i], true);
        }
    }

    /**
        @notice
            Unban relays
        @param _relays List of relay addresses to unban
    */
    function unbanRelays(
        address[] calldata _relays
    ) override external onlyOwner {
        for (uint i=0; i<_relays.length; i++) {
            blacklist[_relays[i]] = false;

            emit BanRelay(_relays[i], false);
        }
    }

    function _setRound(
        uint32 round,
        uint160[] memory _relays,
        uint32 roundEnd
    ) internal {
        uint32 requiredSignatures = uint32(_relays.length * 2 / 3) + 1;

        rounds[round] = Round(
            roundEnd,
            roundEnd + roundTTL,
            uint32(_relays.length),
            requiredSignatures < minimumRequiredSignatures ? minimumRequiredSignatures : requiredSignatures
        );

        emit NewRound(round, rounds[round]);

        for (uint i=0; i<_relays.length; i++) {
            address relay = address(_relays[i]);

            relays[round][relay] = true;

            emit RoundRelay(round, relay);
        }
    }

    function _countRelaySignatures(
        bytes memory payload,
        bytes[] memory signatures,
        uint32 round
    ) internal view returns (uint32) {
        address lastSigner = address(0);
        uint32 count = 0;

        for (uint i=0; i<signatures.length; i++) {
            address signer = recoverSignature(payload, signatures[i]);

            require(signer > lastSigner, "Bridge: signatures sequence wrong");
            lastSigner = signer;

            if (isRelay(round, signer) && !isBanned(signer)) {
                count++;
            }
        }

        return count;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;


interface IBridge {
    struct TONEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }

    struct Round {
        uint32 end;
        uint32 ttl;
        uint32 relays;
        uint32 requiredSignatures;
    }

    struct TONAddress {
        int8 wid;
        uint256 addr;
    }

    function updateMinimumRequiredSignatures(uint32 _minimumRequiredSignatures) external;
    function updateRoundRelaysConfiguration(TONAddress calldata _roundRelaysConfiguration) external;
    function updateRoundTTL(uint32 _roundTTL) external;

    function isRelay(
        uint32 round,
        address candidate
    ) external view returns(bool);

    function isBanned(
        address candidate
    ) external view returns(bool);

    function isRoundRotten(
        uint32 round
    ) external view returns(bool);

    function verifySignedTonEvent(
        bytes memory payload,
        bytes[] memory signatures
    ) external view returns(uint32);

    function setRoundRelays(
        bytes calldata payload,
        bytes[] calldata signatures
    ) external;

    function forceRoundRelays(
        uint160[] calldata _relays,
        uint32 roundEnd
    ) external;

    function banRelays(
        address[] calldata _relays
    ) external;

    function unbanRelays(
        address[] calldata _relays
    ) external;

    function pause() external;
    function unpause() external;

    function setRoundSubmitter(address _roundSubmitter) external;

    event EmergencyShutdown(bool active);

    event UpdateMinimumRequiredSignatures(uint32 value);
    event UpdateRoundTTL(uint32 value);
    event UpdateRoundRelaysConfiguration(TONAddress configuration);
    event UpdateRoundSubmitter(address _roundSubmitter);

    event NewRound(uint32 indexed round, Round meta);
    event RoundRelay(uint32 indexed round, address indexed relay);
    event BanRelay(address indexed relay, bool status);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

library ECDSA {

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
      * toBytesPrefixed
      * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
      * and hash the result
      */
    function toBytesPrefixed(bytes32 hash)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;


contract Cache {
    mapping (bytes32 => bool) public cache;

    modifier notCached(bytes memory payload) {
        bytes32 hash_ = keccak256(abi.encode(payload));

        require(cache[hash_] == false, "Cache: payload already seen");

        _;

        cache[hash_] = true;
    }
}