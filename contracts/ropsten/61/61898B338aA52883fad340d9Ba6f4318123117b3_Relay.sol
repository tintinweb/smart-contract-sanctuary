// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/proxy/Initializable.sol";

import "./Blake2b.sol";
import "./common/Ownable.sol";
import "./common/Pausable.sol";
import "./common/ECDSA.sol";
import "./common/Hash.sol";
import "./common/SafeMath.sol";
import "./common/Input.sol";
import "./MMR.sol";
import "./common/Scale.sol";
import "./SimpleMerkleProof.sol";

pragma experimental ABIEncoderV2;

contract Relay is Ownable, Pausable, Initializable {
    event SetRootEvent(address relayer, bytes32 root, uint256 index);
    event SetAuthoritiesEvent(uint32 nonce, address[] authorities, bytes32 beneficiary);
    event ResetRootEvent(address owner, bytes32 root, uint256 index);
    event ResetAuthoritiesEvent(uint32 nonce, address[] authorities);

    struct Relayers {
        // Each time the relay set is updated, the nonce is incremented
        // After the first "updateRelayer" call, the nonce value is equal to 1, 
        // which is different from the field "Term" at the node.
        uint32 nonce;
        // mapping(address => bool) member;
        address[] member;
        uint8 threshold;
    }

    Relayers relayers;

    // 'Crab', 'Darwinia', 'Pangolin'
    bytes private networkPrefix;

    // index => mmr root
    // In the Darwinia Network, the mmr root of block 1000 
    // needs to be queried in Log-Other of block 1001.
    mapping(uint32 => bytes32) public mmrRootPool;

    // _MMRIndex - mmr index or block number corresponding to mmr root
    // _genesisMMRRoot - mmr root
    // _relayers - Keep the same as the "ethereumRelayAuthorities" module in darwinia network
    // _nonce - To prevent replay attacks
    // _threshold - The threshold for a given level can be set to any number from 0-100. This threshold is the amount of signature weight required to authorize an operation at that level.
    // _prefix - The known values are: "Pangolin", "Crab", "Darwinia"
    function initialize(
        uint32 _MMRIndex,
        bytes32 _genesisMMRRoot,
        address[] memory _relayers,
        uint32 _nonce,
        uint8 _threshold,
        bytes memory _prefix
    ) public initializer {
        ownableConstructor();
        pausableConstructor();
        
        _appendRoot(_MMRIndex, _genesisMMRRoot);
        _resetRelayer(_nonce, _relayers);
        _setNetworkPrefix(_prefix);
        _setRelayThreshold(_threshold);
    }

    /// ==== Getters ==== 
    function getRelayerCount() public view returns (uint256) {
        return relayers.member.length;
    }

    function getRelayerNonce() public view returns (uint32) {
        return relayers.nonce;
    }

    function getRelayer() public view returns (address[] memory) {
        return relayers.member;
    }

    function getNetworkPrefix() public view returns (bytes memory) {
        return networkPrefix;
    }

    function getRelayerThreshold() public view returns (uint8) {
        return relayers.threshold;
    }

    function getMMRRoot(uint32 index) public view returns (bytes32) {
        return mmrRootPool[index];
    }

    function getLockTokenReceipt(bytes32 root, bytes memory eventsProofStr, bytes memory key)
        public
        view
        whenNotPaused
        returns (bytes memory)
    {
        Input.Data memory data = Input.from(eventsProofStr);

        bytes[] memory proofs = Scale.decodeReceiptProof(data);
        bytes memory result = SimpleMerkleProof.getEvents(root, key, proofs);
        
        return result;
    }

    function isRelayer(address addr) public view returns (bool) {
        for (uint256 i = 0; i < relayers.member.length; i++) {
            if (addr == relayers.member[i]) {
                return true;
            }
        }
        return false;
    }

    function checkNetworkPrefix(bytes memory prefix) view public returns (bool) {
      return assertBytesEq(getNetworkPrefix(), prefix);
    }

    function checkRelayerNonce(uint32 nonce) view public returns (bool) {
      return nonce == getRelayerNonce();
    }

    /// ==== Setters ==== 

    // When the darwinia network authorities set is updated, bridger or other users need to submit the new authorities set to the reporter contract by calling this method.
    // message - prefix + nonce + [...relayers]
    // struct{vec<u8>, u32, vec<EthereumAddress>}
    // signatures - signed by personal_sign
    // beneficiary - Keeping the authorities set up-to-date is advocated between the relay contract contract and the darwinia network, and the darwinia network will give partial rewards to the benifit account. benifit is the public key of a darwinia network account
    function updateRelayer(
        bytes memory message,
        bytes[] memory signatures,
        bytes32 beneficiary
    ) public whenNotPaused {
        // verify hash, signatures (The number of signers must be greater than _threshold)
        require( 
            _checkSignature(message, signatures),
            "Relay: Bad relayer signature"
        );

        // decode message, check nonce and relayer
        Input.Data memory data = Input.from(message);
        (bytes memory prefix, uint32 nonce, address[] memory authorities) = Scale.decodeAuthorities(
            data
        );

        require(checkNetworkPrefix(prefix), "Relay: Bad network prefix");
        require(checkRelayerNonce(nonce), "Relay: Bad relayer set nonce");

        // update nonce,relayer
        _updateRelayer(nonce, authorities, beneficiary);
    }

    // Add a mmr root to the mmr root pool
    // message - bytes4 prefix + uint32 mmr-index + bytes32 mmr-root
    // struct{vec<u8>, u32, H256}
    // encode by scale codec
    // signatures - The signature for message
    // https://github.com/darwinia-network/darwinia-common/pull/381
    function appendRoot(
        bytes memory message,
        bytes[] memory signatures
    ) public whenNotPaused {
        // verify hash, signatures
        require(
            _checkSignature(message, signatures),
            "Relay: Bad relayer signature"
        );

        // decode message, check nonce and relayer
        Input.Data memory data = Input.from(message);
        (bytes memory prefix, uint32 index, bytes32 root) = Scale.decodeMMRRoot(data);

        require(checkNetworkPrefix(prefix), "Relay: Bad network prefix");

        // append index, root
        _appendRoot(index, root);
    }

    function verifyRootAndDecodeReceipt(
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr,
        bytes memory key
    ) public view whenNotPaused returns (bytes memory){
        // verify block proof
        require(
            verifyBlockProof(root, MMRIndex, blockNumber, blockHeader, peaks, siblings),
            "Relay: Block header proof varification failed"
        );

        // get state root
        bytes32 stateRoot = Scale.decodeStateRootFromBlockHeader(blockHeader);

        return getLockTokenReceipt(stateRoot, eventsProofStr, key);
    }

    function verifyBlockProof(
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public view whenNotPaused returns (bool) {
        require(
            getMMRRoot(MMRIndex) != bytes32(0),
            "Relay: Not registered under this index"
        );
        require(
            getMMRRoot(MMRIndex) == root,
            "Relay: Root is different from the root pool"
        );

        return MMR.inclusionProof(root, MMRIndex + 1, blockNumber, blockHeader, peaks, siblings);
    }


    /// ==== onlyOwner ==== 
    function resetRoot(uint32 index, bytes32 root) public onlyOwner {
        _setRoot(index, root);
        emit ResetRootEvent(_msgSender(), root, index);
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function resetNetworkPrefix(bytes memory _prefix) public onlyOwner {
        _setNetworkPrefix(_prefix);
    }

    function resetRelayerThreshold(uint8 _threshold) public onlyOwner {
        _setRelayThreshold(_threshold);
    }

    function resetRelayer(uint32 nonce, address[] memory accounts) public onlyOwner {
        _resetRelayer(nonce, accounts);
    }

    /// ==== Internal ==== 
    function _updateRelayer(uint32 nonce, address[] memory accounts, bytes32 beneficiary) internal {
        require(accounts.length > 0, "Relay: accounts is empty");

        emit SetAuthoritiesEvent(nonce, accounts, beneficiary);

        relayers.member = accounts;
        relayers.nonce = getRelayerNonce() + 1;    
    }

    function _resetRelayer(uint32 nonce, address[] memory accounts) internal {
        require(accounts.length > 0, "Relay: accounts is empty");
        relayers.member = accounts;
        relayers.nonce = nonce;

        emit ResetAuthoritiesEvent(nonce, accounts);
    }

    function _appendRoot(uint32 index, bytes32 root) internal {
        require(getMMRRoot(index) == bytes32(0), "Relay: Index has been set");

        _setRoot(index, root);
    }

    function _setRoot(uint32 index, bytes32 root) internal {
        mmrRootPool[index] = root;
        emit SetRootEvent(_msgSender(), root, index);
    }

    function _setNetworkPrefix(bytes memory prefix) internal {
        networkPrefix = prefix;
    }

    function _setRelayThreshold(uint8 _threshold) internal {
        require(_threshold > 0, "Relay:: _setRelayThreshold: _threshold equal to 0");
        relayers.threshold = _threshold;
    }

    // This method verifies the content of msg by verifying the existing authority collection in the contract. 
    // Ecdsa.recover can recover the signer’s address. 
    // If the signer is matched "isRelayer", it will be counted as a valid signature 
    // and all signatures will be restored. 
    // If the number of qualified signers is greater than Equal to threshold, 
    // the verification is considered successful, otherwise it fails
    function _checkSignature(
        bytes memory message,
        bytes[] memory signatures
    ) internal view returns (bool) {
        require(signatures.length != 0, "Relay:: _checkSignature: signatures is empty");
        bytes32 hash = keccak256(message);
        uint256 count;
        address[] memory signers = new address[](signatures.length);
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(hash);

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = ECDSA.recover(ethSignedMessageHash, signatures[i]);
            signers[i] = signer;
        }

        require(!hasDuplicate(signers), "Relay:: hasDuplicate: Duplicate entries in list");
        
        for (uint256 i = 0; i < signatures.length; i++) {
            if (isRelayer(signers[i])) {
               count++;
            }
        }
        
        uint8 threshold = uint8(
            SafeMath.div(SafeMath.mul(count, 100), getRelayerCount())
        );

        return threshold >= getRelayerThreshold();
    }

    function assertBytesEq(bytes memory a, bytes memory b) internal pure returns (bool){
        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    return false;
                }
            }
        } else {
            return false;
        }
        return true;
    }

    /**
    * Returns whether or not there's a duplicate. Runs in O(n^2).
    * @param A Array to search
    * @return Returns true if duplicate, false otherwise
    */
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        if (A.length == 0) {
            return false;
        }
        for (uint256 i = 0; i < A.length - 1; i++) {
            for (uint256 j = i + 1; j < A.length; j++) {
                if (A[i] == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


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
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

/*
 * Blake2b library in Solidity using EIP-152
 *
 * Copyright (C) 2019 Alex Beregszaszi
 *
 * License: Apache 2.0
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

library Blake2b {
    struct Instance {
        // This is a bit misleadingly called state as it not only includes the Blake2 state,
        // but every field needed for the "blake2 f function precompile".
        //
        // This is a tightly packed buffer of:
        // - rounds: 32-bit BE
        // - h: 8 x 64-bit LE
        // - m: 16 x 64-bit LE
        // - t: 2 x 64-bit LE
        // - f: 8-bit
        bytes state;
        // Expected output hash length. (Used in `finalize`.)
        uint out_len;
        // Data passed to "function F".
        // NOTE: this is limited to 24 bits.
        uint input_counter;
    }

    // Initialise the state with a given `key` and required `out_len` hash length.
    function init(bytes memory key, uint out_len)
        internal
        view
        returns (Instance memory instance)
    {
        // Safety check that the precompile exists.
        // TODO: remove this?
        // assembly {
        //    if eq(extcodehash(0x09), 0) { revert(0, 0) }
        //}

        reset(instance, key, out_len);
    }

    // Initialise the state with a given `key` and required `out_len` hash length.
    function reset(Instance memory instance, bytes memory key, uint out_len)
        internal
        view
    {
        instance.out_len = out_len;
        instance.input_counter = 0;

        // This is entire state transmitted to the precompile.
        // It is byteswapped for the encoding requirements, additionally
        // the IV has the initial parameter block 0 XOR constant applied, but
        // not the key and output length.
        instance.state = hex"0000000c08c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        bytes memory state = instance.state;

        // Update parameter block 0 with key length and output length.
        uint key_len = key.length;
        assembly {
            let ptr := add(state, 36)
            let tmp := mload(ptr)
            let p0 := or(shl(240, key_len), shl(248, out_len))
            tmp := xor(tmp, p0)
            mstore(ptr, tmp)
        }

        // TODO: support salt and personalization

        if (key_len > 0) {
            require(key_len == 64);
            // FIXME: the key must be zero padded
            assert(key.length == 128);
            update(instance, key, key_len);
        }
    }

    // This calls the blake2 precompile ("function F of the spec").
    // It expects the state was updated with the next block. Upon returning the state will be updated,
    // but the supplied block data will not be cleared.
    function call_function_f(Instance memory instance)
        private
        view
    {
        bytes memory state = instance.state;
        assembly {
            let state_ptr := add(state, 32)
            if iszero(staticcall(not(0), 0x09, state_ptr, 0xd5, add(state_ptr, 4), 0x40)) {
                revert(0, 0)
            }
        }
    }

    // This function will split blocks correctly and repeatedly call the precompile.
    // NOTE: this is dumb right now and expects `data` to be 128 bytes long and padded with zeroes,
    //       hence the real length is indicated with `data_len`
    function update_loop(Instance memory instance, bytes memory data, uint data_len, bool last_block)
        private
        view
    {
        bytes memory state = instance.state;
        uint input_counter = instance.input_counter;

        // This is the memory location where the "data block" starts for the precompile.
        uint state_ptr;
        assembly {
            // The `rounds` field is 4 bytes long and the `h` field is 64-bytes long.
            // Also adjust for the size of the bytes type.
            state_ptr := add(state, 100)
        }

        // This is the memory location where the input data resides.
        uint data_ptr;
        assembly {
            data_ptr := add(data, 32)
        }

        uint len = data.length;
        while (len > 0) {
            if (len >= 128) {
                assembly {
                    mstore(state_ptr, mload(data_ptr))
                    data_ptr := add(data_ptr, 32)

                    mstore(add(state_ptr, 32), mload(data_ptr))
                    data_ptr := add(data_ptr, 32)

                    mstore(add(state_ptr, 64), mload(data_ptr))
                    data_ptr := add(data_ptr, 32)

                    mstore(add(state_ptr, 96), mload(data_ptr))
                    data_ptr := add(data_ptr, 32)
                }

                len -= 128;
                // FIXME: remove this once implemented proper padding
                if (data_len < 128) {
                    input_counter += data_len;
                } else {
                    data_len -= 128;
                    input_counter += 128;
                }
            } else {
                // FIXME: implement support for smaller than 128 byte blocks
                revert();
            }

            // Set length field (little-endian) for maximum of 24-bits.
            assembly {
                mstore8(add(state, 228), and(input_counter, 0xff))
                mstore8(add(state, 229), and(shr(8, input_counter), 0xff))
                mstore8(add(state, 230), and(shr(16, input_counter), 0xff))
            }

            // Set the last block indicator.
            // Only if we've processed all input.
            if (len == 0) {
                assembly {
                    // Writing byte 212 here.
                    mstore8(add(state, 244), last_block)
                }
            }

            // Call the precompile
            call_function_f(instance);
        }

        instance.input_counter = input_counter;
    }

    // Update the state with a non-final block.
    // NOTE: the input must be complete blocks.
    function update(Instance memory instance, bytes memory data, uint data_len)
        internal
        view
    {
        require((data.length % 128) == 0);
        update_loop(instance, data, data_len, false);
    }

    // Update the state with a final block and return the hash.
    function finalize(Instance memory instance, bytes memory data)
        internal
        view
        returns (bytes memory output)
    {
        // FIXME: support incomplete blocks (zero pad them)
        uint input_length = data.length;
        if (input_length == 0 || (input_length % 128) != 0) {
            data = concat(data, new bytes(128 - (input_length % 128)));
        }
        assert((data.length % 128) == 0);
        update_loop(instance, data, input_length, true);

        // FIXME: support other lengths
        // assert(instance.out_len == 64);

        bytes memory state = instance.state;
        output = new bytes(instance.out_len);
        if(instance.out_len == 32) {
            assembly {
                mstore(add(output, 32), mload(add(state, 36)))
            }
        } else {
            assembly {
                mstore(add(output, 32), mload(add(state, 36)))
                mstore(add(output, 64), mload(add(state, 68)))
            }
        }
    }

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function ownableConstructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    function pausableConstructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal whenNotPaused {
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
    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

// import "./Memory.sol";
import "../Blake2b.sol";

library Hash {

    using Blake2b for Blake2b.Instance;

    // function hash(bytes memory src) internal view returns (bytes memory des) {
    //     return Memory.toBytes(keccak256(src));
        // Blake2b.Instance memory instance = Blake2b.init(hex"", 32);
        // return instance.finalize(src);
    // }

    function blake2bHash(bytes memory src) internal view returns (bytes32 des) {
        // return keccak256(src);
        Blake2b.Instance memory instance = Blake2b.init(hex"", 32);
        return abi.decode(instance.finalize(src), (bytes32));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Bytes.sol";

library Input {
    using Bytes for bytes;

    struct Data {
        uint256 offset;
        bytes raw;
    }

    function from(bytes memory data) internal pure returns (Data memory) {
        return Data({offset: 0, raw: data});
    }

    modifier shift(Data memory data, uint256 size) {
        require(data.raw.length >= data.offset + size, "Input: Out of range");
        _;
        data.offset += size;
    }

    function finished(Data memory data) internal pure returns (bool) {
        return data.offset == data.raw.length;
    }

    function peekU8(Data memory data) internal pure returns (uint8 v) {
        return uint8(data.raw[data.offset]);
    }

    function decodeU8(Data memory data)
        internal
        pure
        shift(data, 1)
        returns (uint8 value)
    {
        value = uint8(data.raw[data.offset]);
    }

    function decodeU16(Data memory data) internal pure returns (uint16 value) {
        value = uint16(decodeU8(data));
        value |= (uint16(decodeU8(data)) << 8);
    }

    function decodeU32(Data memory data) internal pure returns (uint32 value) {
        value = uint32(decodeU16(data));
        value |= (uint32(decodeU16(data)) << 16);
    }

    function decodeBytesN(Data memory data, uint256 N)
        internal
        pure
        shift(data, N)
        returns (bytes memory value)
    {
        value = data.raw.substr(data.offset, N);
    }

    function decodeBytes32(Data memory data) internal pure shift(data, 32) returns(bytes32 value) {
        bytes memory raw = data.raw;
        uint256 offset = data.offset;

        assembly {
            value := mload(add(add(raw, 32), offset))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import { Hash } from "./common/Hash.sol";

/**
 * @title Merkle Mountain Range solidity library
 *
 * @dev The index of this MMR implementation starts from 1 not 0.
 *      And it uses Blake2bHash for its hash function instead of blake2b
 */
library MMR {
    function bytes32Concat(bytes32 b1, bytes32 b2) public pure returns (bytes memory)
    {
        bytes memory result = new bytes(64);
        assembly {
            mstore(add(result, 32), b1)
            mstore(add(result, 64), b2)
        }
        return result;
    }

    function getSize(uint width) public pure returns (uint256) {
        return (width << 1) - numOfPeaks(width);
    }

    function peakBagging(uint256 width, bytes32[] memory peaks) view public returns (bytes32) {
        // peaks may be merged
        // require(numOfPeaks(width) == peaks.length, "Received invalid number of peaks");
        bytes32 mergeHash = peaks[0];
        for(uint i = peaks.length-1; i >= 1; i = i - 1) {
            bytes32 r;
            if(i == peaks.length-1) {
                r = peaks[i];
            } else {
                r = mergeHash;
            }
            bytes32 l = peaks[i-1];
            mergeHash = hashBranch(r, l);
        }

        return mergeHash;
    }

    /** Pure functions */

    /**
     * @dev It returns true when the given params verifies that the given value exists in the tree or reverts the transaction.
     */
    function inclusionProof(
        bytes32 root,
        uint256 width,
        uint256 blockNumber,
        bytes memory value,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) view internal returns (bool) {
        require(width >= blockNumber + 1, "blockNumber is out of range");
        uint index = getSize(blockNumber) + 1;
        // Check the root equals the peak bagging hash
        require(root == peakBagging(width, peaks), "Invalid root hash from the peaks");

        // Find the mountain where the target index belongs to
        uint256 cursor;
        bytes32 targetPeak;
        uint256[] memory peakIndexes = getPeakIndexes(width);
        for (uint i = 0; i < peakIndexes.length; i++) {
            if (peakIndexes[i] >= index) {
                targetPeak = peaks[i];
                cursor = peakIndexes[i];
                break;
            }
        }
        require(targetPeak != bytes32(0), "Target is not found");

        // Find the path climbing down
        uint256[] memory path = new uint256[](siblings.length + 1);
        uint256 left;
        uint256 right;
        uint8 height = uint8(siblings.length) + 1;
        while (height > 0) {
            // Record the current cursor and climb down
            path[--height] = cursor;
            if (cursor == index) {
                // On the leaf node. Stop climbing down
                break;
            } else {
                // On the parent node. Go left or right
                (left, right) = getChildren(cursor);
                cursor = index > left ? right : left;
                continue;
            }
        }

        // Calculate the summit hash climbing up again
        bytes32 node;
        while (height < path.length) {
            // Move cursor
            cursor = path[height];
            if (height == 0) {
                // cursor is on the leaf
                node = hashLeaf(value);
                // node = valueHash;
            } else if (cursor - 1 == path[height - 1]) {
                // cursor is on a parent and a sibling is on the left
                node = hashBranch(siblings[height - 1], node);
            } else {
                // cursor is on a parent and a sibling is on the right
                node = hashBranch(node, siblings[height - 1]);
            }
            // Climb up
            height++;
        }

        // Computed hash value of the summit should equal to the target peak hash
        require(node == targetPeak, "Hashed peak is invalid");
        return true;
    }


    /**
     * @dev It returns the hash a parent node with hash(M | Left child | Right child)
     *      M is the index of the node
     */
    function hashBranch(bytes32 left, bytes32 right) view public returns (bytes32) {
        // return Blake2bHash(abi.encodePacked(index, left, right));
        return Hash.blake2bHash(bytes32Concat(left, right));
    }

    /**
     * @dev it returns the hash of a leaf node with hash(M | DATA )
     *      M is the index of the node
     */
    function hashLeaf(bytes memory data) view public returns (bytes32) {
        return Hash.blake2bHash(data);
        // return Blake2bHash(abi.encodePacked(index, dataHash));
    }

    /**
     * @dev It returns the height of the highest peak
     */
    function mountainHeight(uint256 size) internal pure returns (uint8) {
        uint8 height = 1;
        while (uint256(1) << height <= size + height) {
            height++;
        }
        return height - 1;
    }

    /**
     * @dev It returns the height of the index
     */
    function heightAt(uint256 index) public pure returns (uint8 height) {
        uint256 reducedIndex = index;
        uint256 peakIndex;
        // If an index has a left mountain subtract the mountain
        while (reducedIndex > peakIndex) {
            reducedIndex -= (uint256(1) << height) - 1;
            height = mountainHeight(reducedIndex);
            peakIndex = (uint256(1) << height) - 1;
        }
        // Index is on the right slope
        height = height - uint8((peakIndex - reducedIndex));
    }

    /**
     * @dev It returns the children when it is a parent node
     */
    function getChildren(uint256 index) public pure returns (uint256 left, uint256 right) {
        left = 0;
        right = 0;
        left = index - (uint256(1) << (heightAt(index) - 1));
        right = index - 1;
        require(left != right, "Not a parent");
        return (left, right);
    }

    /**
     * @dev It returns all peaks of the smallest merkle mountain range tree which includes
     *      the given index(size)
     */
    function getPeakIndexes(uint256 width) public pure returns (uint256[] memory peakIndexes) {
        peakIndexes = new uint256[](numOfPeaks(width));
        uint count;
        uint size;
        for(uint i = 255; i > 0; i--) {
            if(width & (1 << (i - 1)) != 0) {
                // peak exists
                size = size + (1 << i) - 1;
                peakIndexes[count++] = size;
            }
        }
        require(count == peakIndexes.length, "Invalid bit calculation");
    }

    function numOfPeaks(uint256 width) public pure returns (uint num) {
        uint256 bits = width;
        while(bits > 0) {
            if(bits % 2 == 1) num++;
            bits = bits >> 1;
        }
        return num;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Input.sol";
import "./Bytes.sol";
import { ScaleStruct } from "./Scale.struct.sol";

pragma experimental ABIEncoderV2;

library Scale {
    using Input for Input.Data;
    using Bytes for bytes;

    // Vec<Event>    Event = <index, Data>   Data = {accountId, EthereumAddress, types, Balance}
    // bytes memory hexData = hex"102403d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27ddac17f958d2ee523a2206206994597c13d831ec700000e5fa31c00000000000000000000002404d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27ddac17f958d2ee523a2206206994597c13d831ec70100e40b5402000000000000000000000024038eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48b20bd5d04be54f870d5c0d3ca85d82b34b8364050000d0b72b6a000000000000000000000024048eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48b20bd5d04be54f870d5c0d3ca85d82b34b8364050100c817a8040000000000000000000000";
    function decodeLockEvents(Input.Data memory data)
        internal
        pure
        returns (ScaleStruct.LockEvent[] memory)
    {
        uint32 len = decodeU32(data);
        ScaleStruct.LockEvent[] memory events = new ScaleStruct.LockEvent[](len);

        for(uint i = 0; i < len; i++) {
            events[i] = ScaleStruct.LockEvent({
                index: data.decodeBytesN(2).toBytes2(0),
                sender: decodeAccountId(data),
                recipient: decodeEthereumAddress(data),
                token: decodeEthereumAddress(data),
                value: decodeBalance(data)
            });
        }

        return events;
    }

    function decodeStateRootFromBlockHeader(
        bytes memory header
    ) internal pure returns (bytes32 root) {
        uint8 offset = decodeCompactU8aOffset(header[32]);
        assembly {
            root := mload(add(add(header, 0x40), offset))
        }
        return root;
    }

    // little endian
    function decodeMMRRoot(Input.Data memory data) 
        internal
        pure
        returns (bytes memory prefix, uint32 width, bytes32 root)
    {
        prefix = decodePrefix(data);
        width = decodeU32(data);
        root = data.decodeBytes32();
    }

    function decodeAuthorities(Input.Data memory data)
        internal
        pure
        returns (bytes memory prefix, uint32 nonce, address[] memory authorities)
    {
        prefix = decodePrefix(data);
        nonce = decodeU32(data);

        uint authoritiesLength = decodeU32(data);

        authorities = new address[](authoritiesLength);
        for(uint i = 0; i < authoritiesLength; i++) {
            authorities[i] = decodeEthereumAddress(data);
        }
    }

    // decode authorities prefix
    // (crab, darwinia)
    function decodePrefix(Input.Data memory data) 
        internal
        pure
        returns (bytes memory prefix) 
    {
        prefix = decodeByteArray(data);
    }

    // decode authorities nonce
    // little endian
    function decodeAuthoritiesNonce(Input.Data memory data) 
        internal
        pure
        returns (uint32) 
    {
        bytes memory nonce = data.decodeBytesN(4);
        return uint32(nonce.toBytes4(0));
    }

    // decode Ethereum address
    function decodeEthereumAddress(Input.Data memory data) 
        internal
        pure
        returns (address addr) 
    {
        bytes memory bys = data.decodeBytesN(20);
        assembly {
            addr := mload(add(bys,20))
        } 
    }

    // decode Balance
    function decodeBalance(Input.Data memory data) 
        internal
        pure
        returns (uint128) 
    {
        bytes memory accountId = data.decodeBytesN(16);
        return uint128(reverseBytes16(accountId.toBytes16(0)));
    }

    // decode darwinia network account Id
    function decodeAccountId(Input.Data memory data) 
        internal
        pure
        returns (bytes32 accountId) 
    {
        accountId = data.decodeBytes32();
    }

    // decodeReceiptProof receives Scale Codec of Vec<Vec<u8>> structure, 
    // the Vec<u8> is the proofs of mpt
    // returns (bytes[] memory proofs)
    function decodeReceiptProof(Input.Data memory data) 
        internal
        pure
        returns (bytes[] memory proofs) 
    {
        proofs = decodeVecBytesArray(data);
    }

    // decodeVecBytesArray accepts a Scale Codec of type Vec<Bytes> and returns an array of Bytes
    function decodeVecBytesArray(Input.Data memory data)
        internal
        pure
        returns (bytes[] memory v) 
    {
        uint32 vecLenght = decodeU32(data);
        v = new bytes[](vecLenght);
        for(uint i = 0; i < vecLenght; i++) {
            uint len = decodeU32(data);
            v[i] = data.decodeBytesN(len);
        }
        return v;
    }

    // decodeByteArray accepts a byte array representing a SCALE encoded byte array and performs SCALE decoding
    // of the byte array
    function decodeByteArray(Input.Data memory data)
        internal
        pure
        returns (bytes memory v)
    {
        uint32 len = decodeU32(data);
        if (len == 0) {
            return v;
        }
        v = data.decodeBytesN(len);
        return v;
    }

    // decodeU32 accepts a byte array representing a SCALE encoded integer and performs SCALE decoding of the smallint
    function decodeU32(Input.Data memory data) internal pure returns (uint32) {
        uint8 b0 = data.decodeU8();
        uint8 mode = b0 & 3;
        require(mode <= 2, "scale decode not support");
        if (mode == 0) {
            return uint32(b0) >> 2;
        } else if (mode == 1) {
            uint8 b1 = data.decodeU8();
            uint16 v = uint16(b0) | (uint16(b1) << 8);
            return uint32(v) >> 2;
        } else if (mode == 2) {
            uint8 b1 = data.decodeU8();
            uint8 b2 = data.decodeU8();
            uint8 b3 = data.decodeU8();
            uint32 v = uint32(b0) |
                (uint32(b1) << 8) |
                (uint32(b2) << 16) |
                (uint32(b3) << 24);
            return v >> 2;
        }
    }

    // encodeByteArray performs the following:
    // b -> [encodeInteger(len(b)) b]
    function encodeByteArray(bytes memory src)
        internal
        pure
        returns (bytes memory des, uint256 bytesEncoded)
    {
        uint256 n;
        (des, n) = encodeU32(uint32(src.length));
        bytesEncoded = n + src.length;
        des = abi.encodePacked(des, src);
    }

    // encodeU32 performs the following on integer i:
    // i  -> i^0...i^n where n is the length in bits of i
    // if n < 2^6 write [00 i^2...i^8 ] [ 8 bits = 1 byte encoded  ]
    // if 2^6 <= n < 2^14 write [01 i^2...i^16] [ 16 bits = 2 byte encoded  ]
    // if 2^14 <= n < 2^30 write [10 i^2...i^32] [ 32 bits = 4 byte encoded  ]
    function encodeU32(uint32 i) internal pure returns (bytes memory, uint256) {
        // 1<<6
        if (i < 64) {
            uint8 v = uint8(i) << 2;
            bytes1 b = bytes1(v);
            bytes memory des = new bytes(1);
            des[0] = b;
            return (des, 1);
            // 1<<14
        } else if (i < 16384) {
            uint16 v = uint16(i << 2) + 1;
            bytes memory des = new bytes(2);
            des[0] = bytes1(uint8(v));
            des[1] = bytes1(uint8(v >> 8));
            return (des, 2);
            // 1<<30
        } else if (i < 1073741824) {
            uint32 v = uint32(i << 2) + 2;
            bytes memory des = new bytes(4);
            des[0] = bytes1(uint8(v));
            des[1] = bytes1(uint8(v >> 8));
            des[2] = bytes1(uint8(v >> 16));
            des[3] = bytes1(uint8(v >> 24));
            return (des, 4);
        } else {
            revert("scale encode not support");
        }
    }

    // convert BigEndian to LittleEndian 
    function reverseBytes16(bytes16 input) internal pure returns (bytes16 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = (v >> 64) | (v << 64);
    }

    function decodeCompactU8aOffset(bytes1 input0) public pure returns (uint8) {
        bytes1 flag = input0 & bytes1(hex"03");
        if (flag == hex"00") {
            return 1;
        } else if (flag == hex"01") {
            return 2;
        } else if (flag == hex"02") {
            return 4;
        }
        uint8 offset = (uint8(input0) >> 2) + 4 + 1;
        return offset;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./common/Input.sol";
import "./common/Bytes.sol";
import "./common/Hash.sol";
import "./common/Nibble.sol";
import "./common/Node.sol";

/**
 * @dev Simple Verification of compact proofs for Modified Merkle-Patricia tries.
 */
library SimpleMerkleProof {
    using Bytes for bytes;
    using Input for Input.Data;

    uint8 internal constant NODEKIND_NOEXT_EMPTY = 0;
    uint8 internal constant NODEKIND_NOEXT_LEAF = 1;
    uint8 internal constant NODEKIND_NOEXT_BRANCH_NOVALUE = 2;
    uint8 internal constant NODEKIND_NOEXT_BRANCH_WITHVALUE = 3;

    struct Item {
        bytes32 key;
        bytes value;
    }

    /**
     * @dev Returns `values` if `keys` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, is a sequence of the subset
     * of nodes in the trie traversed while performing lookups on all keys.
     */
    function verify(
        bytes32 root,
        bytes[] memory proof,
        bytes[] memory keys
    ) internal view returns (bytes[] memory) {
        require(proof.length > 0, "no proof");
        require(keys.length > 0, "no keys");
        Item[] memory db = new Item[](proof.length);
        for (uint256 i = 0; i < proof.length; i++) {
            bytes memory v = proof[i];
            Item memory item = Item({key: Hash.blake2bHash(v), value: v});
            db[i] = item;
        }
        return verify_proof(root, keys, db);
    }

    /**
     * @dev Returns `values` if `keys` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, is a sequence of the subset
     * of nodes in the trie traversed while performing lookups on all keys.
     */
    function getEvents(
        bytes32 root,
        bytes memory key,
        bytes[] memory proof
    ) internal view returns (bytes memory value) {
        bytes memory k = Nibble.keyToNibbles(key);

        Item[] memory db = new Item[](proof.length);
        for (uint256 i = 0; i < proof.length; i++) {
            bytes memory v = proof[i];
            Item memory item = Item({key: Hash.blake2bHash(v), value: v});
            db[i] = item;
        }

        value = lookUp(root, k, db);
    }

    function verify_proof(
        bytes32 root,
        bytes[] memory keys,
        Item[] memory db
    ) internal view returns (bytes[] memory values) {
        values = new bytes[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            bytes memory k = Nibble.keyToNibbles(keys[i]);
            bytes memory v = lookUp(root, k, db);
            values[i] = v;
        }
        return values;
    }

    /// Look up the given key. the value returns if it is found
    function lookUp(
        bytes32 root,
        bytes memory key,
        Item[] memory db
    ) internal view returns (bytes memory v) {
        bytes32 hash = root;
        bytes memory partialKey = key;
        while (true) {
            bytes memory nodeData = getNodeData(hash, db);
            if (nodeData.length == 0) {
                return hex"";
            }
            while (true) {
                Input.Data memory data = Input.from(nodeData);
                uint8 header = data.decodeU8();
                uint8 kind = header >> 6;
                if (kind == NODEKIND_NOEXT_LEAF) {
                    //Leaf
                    Node.Leaf memory leaf = Node.decodeLeaf(data, header);
                    if (leaf.key.equals(partialKey)) {
                        return leaf.value;
                    } else {
                        return hex"";
                    }
                } else if (
                    kind == NODEKIND_NOEXT_BRANCH_NOVALUE ||
                    kind == NODEKIND_NOEXT_BRANCH_WITHVALUE
                ) {
                    //BRANCH_WITHOUT_MASK_NO_EXT  BRANCH_WITH_MASK_NO_EXT
                    Node.Branch memory branch = Node.decodeBranch(data, header);
                    uint256 sliceLen = branch.key.length;
                    if (startsWith(partialKey, branch.key)) {
                        if (partialKey.length == sliceLen) {
                            return branch.value;
                        } else {
                            uint8 index = uint8(partialKey[sliceLen]);
                            Node.NodeHandle memory child = branch
                                .children[index];
                            if (child.exist) {
                                partialKey = partialKey.substr(sliceLen + 1);
                                if (child.isInline) {
                                    nodeData = child.data;
                                } else {
                                    hash = abi.decode(child.data, (bytes32));
                                    break;
                                }
                            } else {
                                return hex"";
                            }
                        }
                    } else {
                        return hex"";
                    }
                } else if (kind == NODEKIND_NOEXT_EMPTY) {
                    return hex"";
                } else {
                    revert("not support node type");
                }
            }
        }
    }

    function getNodeData(bytes32 hash, Item[] memory db)
        internal
        pure
        returns (bytes memory)
    {
        for (uint256 i = 0; i < db.length; i++) {
            Item memory item = db[i];
            if (hash == item.key) {
                return item.value;
            }
        }
        return hex"";
    }

    function startsWith(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        if (a.length < b.length) {
            return false;
        }
        for (uint256 i = 0; i < b.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

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
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import {Memory} from "./Memory.sol";

library Bytes {
    uint256 internal constant BYTES_HEADER_SIZE = 32;

    // Checks if two `bytes memory` variables are equal. This is done using hashing,
    // which is much more gas efficient then comparing each byte individually.
    // Equality means that:
    //  - 'self.length == other.length'
    //  - For 'n' in '[0, self.length)', 'self[n] == other[n]'
    function equals(bytes memory self, bytes memory other) internal pure returns (bool equal) {
        if (self.length != other.length) {
            return false;
        }
        uint addr;
        uint addr2;
        assembly {
            addr := add(self, /*BYTES_HEADER_SIZE*/32)
            addr2 := add(other, /*BYTES_HEADER_SIZE*/32)
        }
        equal = Memory.equals(addr, addr2, self.length);
    }

    // Copies a section of 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that 'startIndex <= self.length'
    // The length of the substring is: 'self.length - startIndex'
    function substr(bytes memory self, uint256 startIndex)
        internal
        pure
        returns (bytes memory)
    {
        require(startIndex <= self.length);
        uint256 len = self.length - startIndex;
        uint256 addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIndex, len);
    }

    // Copies 'len' bytes from 'self' into a new array, starting at the provided 'startIndex'.
    // Returns the new copy.
    // Requires that:
    //  - 'startIndex + len <= self.length'
    // The length of the substring is: 'len'
    function substr(
        bytes memory self,
        uint256 startIndex,
        uint256 len
    ) internal pure returns (bytes memory) {
        require(startIndex + len <= self.length);
        if (len == 0) {
            return "";
        }
        uint256 addr = Memory.dataPtr(self);
        return Memory.toBytes(addr + startIndex, len);
    }

    // Combines 'self' and 'other' into a single array.
    // Returns the concatenated arrays:
    //  [self[0], self[1], ... , self[self.length - 1], other[0], other[1], ... , other[other.length - 1]]
    // The length of the new array is 'self.length + other.length'
    function concat(bytes memory self, bytes memory other)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory ret = new bytes(self.length + other.length);
        uint256 src;
        uint256 srcLen;
        (src, srcLen) = Memory.fromBytes(self);
        uint256 src2;
        uint256 src2Len;
        (src2, src2Len) = Memory.fromBytes(other);
        uint256 dest;
        (dest, ) = Memory.fromBytes(ret);
        uint256 dest2 = dest + srcLen;
        Memory.copy(src, dest, srcLen);
        Memory.copy(src2, dest2, src2Len);
        return ret;
    }

    function toBytes32(bytes memory self)
        internal
        pure
        returns (bytes32 out)
    {
        require(self.length >= 32, "Bytes:: toBytes32: data is to short.");
        assembly {
            out := mload(add(self, 32))
        }
    }

    function toBytes16(bytes memory self, uint256 offset)
        internal
        pure
        returns (bytes16 out)
    {
        for (uint i = 0; i < 16; i++) {
            out |= bytes16(byte(self[offset + i]) & 0xFF) >> (i * 8);
        }
    }

    function toBytes4(bytes memory self, uint256 offset)
        internal
        pure
        returns (bytes4)
    {
        bytes4 out;

        for (uint256 i = 0; i < 4; i++) {
            out |= bytes4(self[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function toBytes2(bytes memory self, uint256 offset)
        internal
        pure
        returns (bytes2)
    {
        bytes2 out;

        for (uint256 i = 0; i < 2; i++) {
            out |= bytes2(self[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

library Memory {

    uint internal constant WORD_SIZE = 32;

	// Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(uint addr, uint addr2, uint len) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'

    function equals(uint addr, uint len, bytes memory bts) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint addr2;
        assembly {
            addr2 := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        return equals(addr, addr2, len);
    }
	// Returns a memory pointer to the data portion of the provided bytes array.
	function dataPtr(bytes memory bts) internal pure returns (uint addr) {
		assembly {
			addr := add(bts, /*BYTES_HEADER_SIZE*/32)
		}
	}

	// Creates a 'bytes memory' variable from the memory address 'addr', with the
	// length 'len'. The function will allocate new memory for the bytes array, and
	// the 'len bytes starting at 'addr' will be copied into that new memory.
	function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
		bts = new bytes(len);
		uint btsptr;
		assembly {
			btsptr := add(bts, /*BYTES_HEADER_SIZE*/32)
		}
		copy(addr, btsptr, len);
	}
	
	// Copies 'self' into a new 'bytes memory'.
	// Returns the newly created 'bytes memory'
	// The returned bytes will be of length '32'.
	function toBytes(bytes32 self) internal pure returns (bytes memory bts) {
		bts = new bytes(32);
		assembly {
			mstore(add(bts, /*BYTES_HEADER_SIZE*/32), self)
		}
	}

	// Copy 'len' bytes from memory address 'src', to address 'dest'.
	// This function does not check the or destination, it only copies
	// the bytes.
	function copy(uint src, uint dest, uint len) internal pure {
		// Copy word-length chunks while possible
		for (; len >= WORD_SIZE; len -= WORD_SIZE) {
			assembly {
				mstore(dest, mload(src))
			}
			dest += WORD_SIZE;
			src += WORD_SIZE;
		}

		// Copy remaining bytes
		uint mask = 256 ** (WORD_SIZE - len) - 1;
		assembly {
			let srcpart := and(mload(src), not(mask))
			let destpart := and(mload(dest), mask)
			mstore(dest, or(destpart, srcpart))
		}
	}

	// This function does the same as 'dataPtr(bytes memory)', but will also return the
	// length of the provided bytes array.
	function fromBytes(bytes memory bts) internal pure returns (uint addr, uint len) {
		len = bts.length;
		assembly {
			addr := add(bts, /*BYTES_HEADER_SIZE*/32)
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

library ScaleStruct {
    struct LockEvent {
        bytes2 index;
        bytes32 sender;
        address recipient;
        address token;
        uint128 value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

library Nibble {
    // keyToNibbles turns bytes into nibbles, assumes they are already ordered in LE
    function keyToNibbles(bytes memory src)
        internal
        pure
        returns (bytes memory des)
    {
        if (src.length == 0) {
            return des;
        } else if (src.length == 1 && uint8(src[0]) == 0) {
            return hex"0000";
        }
        uint256 l = src.length * 2;
        des = new bytes(l);
        for (uint256 i = 0; i < src.length; i++) {
            des[2 * i] = bytes1(uint8(src[i]) / 16);
            des[2 * i + 1] = bytes1(uint8(src[i]) % 16);
        }
    }

    // nibblesToKeyLE turns a slice of nibbles w/ length k into a little endian byte array, assumes nibbles are already LE
    function nibblesToKeyLE(bytes memory src)
        internal
        pure
        returns (bytes memory des)
    {
        uint256 l = src.length;
        if (l % 2 == 0) {
            des = new bytes(l / 2);
            for (uint256 i = 0; i < l; i += 2) {
                uint8 a = uint8(src[i]);
                uint8 b = uint8(src[i + 1]);
                des[i / 2] = bytes1(((a << 4) & 0xF0) | (b & 0x0F));
            }
        } else {
            des = new bytes(l / 2 + 1);
            des[0] = src[0];
            for (uint256 i = 2; i < l; i += 2) {
                uint8 a = uint8(src[i - 1]);
                uint8 b = uint8(src[i]);
                des[i / 2] = bytes1(((a << 4) & 0xF0) | (b & 0x0F));
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Input.sol";
import "./Nibble.sol";
import "./Bytes.sol";
import "./Hash.sol";
import "./Scale.sol";

library Node {
    using Input for Input.Data;
    using Bytes for bytes;

    uint8 internal constant NODEKIND_NOEXT_LEAF = 1;
    uint8 internal constant NODEKIND_NOEXT_BRANCH_NOVALUE = 2;
    uint8 internal constant NODEKIND_NOEXT_BRANCH_WITHVALUE = 3;

    struct NodeHandle {
        bytes data;
        bool exist;
        bool isInline;
    }

    struct Branch {
        bytes key; //partialkey
        NodeHandle[16] children;
        bytes value;
    }

    struct Leaf {
        bytes key; //partialkey
        bytes value;
    }

    // decodeBranch decodes a byte array into a branch node
    function decodeBranch(Input.Data memory data, uint8 header)
        internal
        pure
        returns (Branch memory)
    {
        Branch memory b;
        b.key = decodeNodeKey(data, header);
        uint8[2] memory bitmap;
        bitmap[0] = data.decodeU8();
        bitmap[1] = data.decodeU8();
        uint8 nodeType = header >> 6;
        if (nodeType == NODEKIND_NOEXT_BRANCH_WITHVALUE) {
            //BRANCH_WITH_MASK_NO_EXT
            b.value = Scale.decodeByteArray(data);
        }
        for (uint8 i = 0; i < 16; i++) {
            if (((bitmap[i / 8] >> (i % 8)) & 1) == 1) {
                bytes memory childData = Scale.decodeByteArray(data);
                bool isInline = true;
                if (childData.length == 32) {
                    isInline = false;
                }
                b.children[i] = NodeHandle({
                    data: childData,
                    isInline: isInline,
                    exist: true
                });
            }
        }
        return b;
    }

    // decodeLeaf decodes a byte array into a leaf node
    function decodeLeaf(Input.Data memory data, uint8 header)
        internal
        pure
        returns (Leaf memory)
    {
        Leaf memory l;
        l.key = decodeNodeKey(data, header);
        l.value = Scale.decodeByteArray(data);
        return l;
    }

    function decodeNodeKey(Input.Data memory data, uint8 header)
        internal
        pure
        returns (bytes memory key)
    {
        uint256 keyLen = header & 0x3F;
        if (keyLen == 0x3f) {
            while (keyLen < 65536) {
                uint8 nextKeyLen = data.decodeU8();
                keyLen += uint256(nextKeyLen);
                if (nextKeyLen < 0xFF) {
                    break;
                }
                require(
                    keyLen < 65536,
                    "Size limit reached for a nibble slice"
                );
            }
        }
        if (keyLen != 0) {
            key = data.decodeBytesN(keyLen / 2 + (keyLen % 2));
            key = Nibble.keyToNibbles(key);
            if (keyLen % 2 == 1) {
                key = key.substr(1);
            }
        }
        return key;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}