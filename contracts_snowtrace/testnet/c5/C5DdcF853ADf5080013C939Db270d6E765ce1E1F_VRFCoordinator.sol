// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./VRF.sol";
import "./VRFRequestIDBase.sol";
import "./VRFConsumerBase.sol";

/**
 * @title VRFCoordinator coordinates on-chain verifiable-randomness requests
 * @title with off-chain responses
 */
contract VRFCoordinator is
  Context,
  Ownable,
  VRF,
  VRFRequestIDBase
{
  using EnumerableSet for EnumerableSet.AddressSet;


  // Set this maximum to 200 to give us a 56 block window to fulfill
  // the request before requiring the block hash feeder.
  uint16 public constant MAX_REQUEST_CONFIRMATIONS = 200;

  struct Callback {
    address consumer;
    bytes32 seedAndBlockNum;
  }

  mapping(bytes32 => Callback) public callbacks;
  mapping(bytes32 => mapping(address => uint256)) private nonces;

  mapping(bytes32 => address) private provingKeys;
  bytes32[] private provingKeyHashes;
  event ProvingKeyRegistered(bytes32 keyHash, address indexed oracle);
  event ProvingKeyDeregistered(bytes32 keyHash, address indexed oracle);

  EnumerableSet.AddressSet private acceptedConsumers;

  event RandomnessRequest(
    bytes32 keyHash,
    uint256 seed,
    address sender,
    bytes32 requestID
  );
  event RandomnessRequestFulfilled(bytes32 requestId, uint256 output);

  function addConsumer(address consumer) external onlyOwner {
    require(consumer != address(0), "consumer's address is zero");
    acceptedConsumers.add(consumer);
  }

  function removeConsumer(address consumer) external onlyOwner {
    acceptedConsumers.remove(consumer);
  }

  /**
   * @notice Registers a proving key to an oracle.
   * @param oracle address of the oracle.
   * @param publicProvingKey key that oracle can use to submit vrf fulfillments.
   */
  function registerProvingKey(address oracle, uint256[2] calldata publicProvingKey) external onlyOwner {
    require(oracle != address(0), "oracle's address is zero");
    bytes32 kh = hashOfKey(publicProvingKey);
    require(provingKeys[kh] == address(0), "proving key already registered");
    provingKeys[kh] = oracle;
    provingKeyHashes.push(kh);
    emit ProvingKeyRegistered(kh, oracle);
  }

  /**
   * @notice Deregisters a proving key to an oracle.
   * @param publicProvingKey key that oracle can use to submit vrf fulfillments.
   */
  function deregisterProvingKey(uint256[2] calldata publicProvingKey) external onlyOwner {
    bytes32 kh = hashOfKey(publicProvingKey);
    address oracle = provingKeys[kh];
    require(oracle != address(0), "proving key not registered");
    delete provingKeys[kh];
    for (uint256 i = 0; i < provingKeyHashes.length; i++) {
      if (provingKeyHashes[i] == kh) {
        bytes32 last = provingKeyHashes[provingKeyHashes.length - 1];
        provingKeyHashes[i] = last;
        provingKeyHashes.pop();
	break;
      }
    }
    emit ProvingKeyDeregistered(kh, oracle);
  }

  /**
   * @notice Returns the proving key hash key associated with this public key.
   * @param publicKey the key to return the hash of.
   */
  function hashOfKey(uint256[2] memory publicKey) public pure returns (bytes32) {
    return keccak256(abi.encode(publicKey));
  }

  /**
   * @notice Creates a request for randomness.
   * @param keyHash ID of the VRF public key against which to generate output.
   * @param consumer address of consumer contract.
   *
   * @dev the requestID used to store the request data is constructed from the
   * @dev preSeed and keyHash.
   */
  function randomnessRequest(bytes32 keyHash, address consumer) external returns (bytes32) {
    uint256 nonce = nonces[keyHash][consumer];
    uint256 preSeed = makeVRFInputSeed(keyHash, consumer, nonce);
    bytes32 requestId = makeRequestId(keyHash, preSeed);
    // Cryptographically guaranteed by preSeed including an increasing nonce.
    assert(callbacks[requestId].consumer == address(0));
    callbacks[requestId].consumer = consumer;
    callbacks[requestId].seedAndBlockNum = keccak256(abi.encodePacked(preSeed, block.number));
    nonces[keyHash][consumer]++;
    emit RandomnessRequest(keyHash, preSeed, consumer, requestId);
    return requestId;
  }

  // Offset into fulfillRandomnessRequest's proof of various values
  //
  // Public key. Skips byte array's length prefix.
  uint256 public constant PUBLIC_KEY_OFFSET = 0x20;
  // Seed is 7th word in proof, plus word length, (6+1)*0x20=0xe0
  uint256 public constant PRESEED_OFFSET = 0xe0;

  /**
   * @notice Called by the oracle to fulfill requests
   *
   * @param proof the proof of randomness. Actual random output built from this.
   *
   * @dev The structure of proof corresponds to vrf.MarshaledOnChainResponse,
   * @dev in the node source code. I.e., it is a vrf.MarshaledProof with the
   * @dev seed replaced by preSeed, followed by the hash of the requesting block.
   */
  function fulfillRandomnessRequest(bytes memory proof) external {
    bytes32 hashKey;
    Callback memory callback;
    uint256 randomness;
    bytes32 requestId;
    (hashKey, callback, requestId, randomness) = getRandomnessFromProof(proof);

    // Forget request. Must precede callback (prevents reentrancy)
    delete callbacks[requestId];
    emit RandomnessRequestFulfilled(requestId, randomness);
    callbackWithRandomness(callback.consumer, requestId, randomness);
  }

  function callbackWithRandomness(address consumer, bytes32 requestId, uint256 randomness) internal {
    // Dummy variable; allows access to method selector in next line. See
    // https://github.com/ethereum/solidity/issues/3506#issuecomment-553727797
    VRFConsumerBase v;
    bytes memory resp = abi.encodeWithSelector(v.rawFulfillRandomness.selector, requestId, randomness);
    // The bound b here comes from https://eips.ethereum.org/EIPS/eip-150. The
    // actual gas available to the consuming contract will be b-floor(b/64).
    // This is chosen to leave the consuming contract ~200k gas, after the cost
    // of the call itself.
    uint256 b = 206000;
    require(gasleft() >= b, "not enough gas for consumer");
    // A low-level call is necessary, here, because we don't want the consuming
    // contract to be able to revert this execution, and thus deny the oracle
    // payment for a valid randomness response. This also necessitates the above
    // check on the gasleft, as otherwise there would be no indication if the
    // callback method ran out of gas.
    //
    // solhint-disable-next-line avoid-low-level-calls
    (bool success,) = consumer.call(resp);
    // Avoid unused-local-variable warning. (success is only present to prevent
    // a warning that the return values of consumer.call is unused.)
    (success);
  }

  function getRandomnessFromProof(bytes memory proof)
    internal
    view
    returns
  (
    bytes32 keyHash,
    Callback memory callback,
    bytes32 requestId,
    uint256 randomness
  ) {
    // blocknum follows proof, which follows length word (only direct-number
    // constants are allowed in assembly, so have to compute this in code)
    uint256 BLOCKNUM_OFFSET = 0x20 + PROOF_LENGTH;
    // proof.length skips the initial length word, so not include the
    // blocknum in this length check balances out.
    require(proof.length == BLOCKNUM_OFFSET, "wrong proof length");
    uint256[2] memory publicKey;
    uint256 preSeed;
    uint256 blockNum;
    assembly { // solhint-disable-line no-inline-assembly
      publicKey := add(proof, PUBLIC_KEY_OFFSET)
      preSeed := mload(add(proof, PRESEED_OFFSET))
      blockNum := mload(add(proof, BLOCKNUM_OFFSET))
    }
    keyHash = hashOfKey(publicKey);
    requestId = makeRequestId(keyHash, preSeed);
    callback = callbacks[requestId];
    require(callback.consumer != address(0), "no such request");
    require(
      callback.seedAndBlockNum == keccak256(abi.encodePacked(preSeed, blockNum)),
      "wrong preSeed or block number"
    );

    bytes32 blockHash = blockhash(blockNum);
    require(blockHash != bytes32(0), "please prove blockhash");
    // The seed actually used by the VRF machinery, mixing in the blockhash
    uint256 actualSeed = uint256(keccak256(abi.encodePacked(preSeed, blockHash)));
    // solhint-disable-next-line no-inline-assembly
    assembly { // Construct the actual proof from the remain of proof.
      mstore(add(proof, PRESEED_OFFSET), actualSeed)
      mstore(proof, PROOF_LENGTH)
    }
    randomness = VRF.randomValueFromVRFProof(proof); // Reverts on failure
  }
}