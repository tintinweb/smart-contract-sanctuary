// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { CBORChainlink } from "./vendor/CBORChainlink.sol";
import { BufferChainlink } from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  )
    internal
    pure
    returns (
      Chainlink.Request memory
    )
  {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(
    Request memory self,
    bytes memory data
  )
    internal
    pure
  {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import { ENSResolver as ENSResolver_Chainlink } from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 constant internal LINK_DIVISIBILITY = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ORACLE_ARGS_VERSION = 1;
  uint256 constant private OPERATOR_ARGS_VERSION = 2;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  OperatorInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(
    bytes32 indexed id
  );
  event ChainlinkFulfilled(
    bytes32 indexed id
  );
  event ChainlinkCancelled(
    bytes32 indexed id
  );

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddress The callback address that the response will be sent to
   * @param callbackFunctionSignature The callback function signature to use for the callback address
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionSignature
  )
    internal
    pure
    returns (
      Chainlink.Request memory
    )
  {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddress, callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32
    )
  {
    return sendChainlinkRequestTo(address(oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    return rawRequest(oracleAddress, req, payment, ORACLE_ARGS_VERSION, oracle.oracleRequest.selector);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `requestOracleDataFrom` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function requestOracleData(
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32
    )
  {
    return requestOracleDataFrom(address(oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function requestOracleDataFrom(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    return rawRequest(oracleAddress, req, payment, OPERATOR_ARGS_VERSION, oracle.requestOracleData.selector);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @param argsVersion The version of data support (single word, multi word)
   * @return requestId The request ID
   */
  function rawRequest(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment,
    uint256 argsVersion,
    bytes4 funcSelector
  )
    private
    returns (
      bytes32 requestId
    )
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    req.nonce = requestCount;
    pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    bytes memory encodedData = abi.encodeWithSelector(
      funcSelector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackAddress,
      req.callbackFunctionId,
      req.nonce,
      argsVersion,
      req.buf.buf);
    require(link.transferAndCall(oracleAddress, payment, encodedData), "unable to transferAndCall to oracle");
    requestCount += 1;
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  )
    internal
  {
    OperatorInterface requested = OperatorInterface(pendingRequests[requestId]);
    delete pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(
    address oracleAddress
  )
    internal
  {
    oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(
    address linkAddress
  )
    internal
  {
    link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() 
    internal
  {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress()
    internal
    view
    returns (
      address
    )
  {
    return address(link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress()
    internal
    view
    returns (
      address
    )
  {
    return address(oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(
    address oracleAddress,
    bytes32 requestId
  )
    internal
    notPendingRequest(requestId)
  {
    pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(
    address ensAddress,
    bytes32 node
  )
    internal
  {
    ens = ENSInterface(ensAddress);
    ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS()
    internal
  {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(
    bytes32 requestId
  )
    internal
    recordChainlinkFulfillment(requestId)
    // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(
    bytes32 requestId
  )
  {
    require(msg.sender == pendingRequests[requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(
    bytes32 requestId
  )
  {
    require(pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(
    bytes32 indexed node,
    bytes32 indexed label,
    address owner
  );

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(
    bytes32 indexed node,
    address owner
  );

  // Logged when the resolver for a node changes.
  event NewResolver(
    bytes32 indexed node,
    address resolver
  );

  // Logged when the TTL of a node changes
  event NewTTL(
    bytes32 indexed node,
    uint64 ttl
  );


  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(
    bytes32 node,
    address resolver
  ) external;

  function setOwner(
    bytes32 node,
    address owner
  ) external;

  function setTTL(
    bytes32 node,
    uint64 ttl
  ) external;

  function owner(
    bytes32 node
  )
    external
    view
    returns (
      address
    );

  function resolver(
    bytes32 node
  )
    external
    view
    returns (
      address
    );

  function ttl(
    bytes32 node
  )
    external
    view
    returns (
      uint64
    );

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

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {

  function requestOracleData(
    address sender,
    uint256 payment,
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  )
    external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  )
    external
    returns (
      bool
    );

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function distributeFunds(
    address payable[] calldata receivers,
    uint[] calldata amounts
  )
    external
    payable;

  function getAuthorizedSenders()
    external
    returns (
      address[] memory
    );

  function setAuthorizedSenders(
    address[] calldata senders
  ) external;

  function getForwarder()
    external
    returns (
      address
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  )
    external
    returns (
      bool
    );

  function isAuthorizedSender(
    address node
  )
    external
    view
    returns (
      bool
    );

  function withdraw(
    address recipient,
    uint256 amount
  ) external;

  function withdrawable()
    external
    view
    returns (
      uint256
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  
  function getAddress()
    external
    view
    returns (
      address
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library BufferChainlink {
  /**
  * @dev Represents a mutable buffer. Buffers have a current value (buf) and
  *      a capacity. The capacity may be longer than the current value, in
  *      which case it can be extended without the need to allocate more memory.
  */
  struct buffer {
    bytes buf;
    uint capacity;
  }

  /**
  * @dev Initializes a buffer with an initial capacity.
  * @param buf The buffer to initialize.
  * @param capacity The number of bytes of space to allocate the buffer.
  * @return The buffer, for chaining.
  */
  function init(
    buffer memory buf,
    uint capacity
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
  * @dev Initializes a new buffer from an existing bytes object.
  *      Changes to the buffer may mutate the original value.
  * @param b The bytes object to initialize the buffer with.
  * @return A new buffer.
  */
  function fromBytes(
    bytes memory b
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(
    buffer memory buf,
    uint capacity
  )
    private
    pure
  {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(
    uint a,
    uint b
  )
    private
    pure
    returns(
      uint
    )
  {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
  * @dev Sets buffer length to 0.
  * @param buf The buffer to truncate.
  * @return The original buffer, for chaining..
  */
  function truncate(
    buffer memory buf
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
  * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The start offset to write to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function write(
    buffer memory buf,
    uint off,
    bytes memory data,
    uint len
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint dest;
    uint src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint mask = 256 ** (32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }

    return buf;
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function append(
    buffer memory buf,
    bytes memory data,
    uint len
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, len);
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function append(
    buffer memory buf,
    bytes memory data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
  * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write the byte at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeUint8(
    buffer memory buf,
    uint off,
    uint8 data
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
  * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendUint8(
    buffer memory buf,
    uint8 data
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
  * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
  *      exceed the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (left-aligned).
  * @return The original buffer, for chaining.
  */
  function write(
    buffer memory buf,
    uint off,
    bytes32 data,
    uint len
  )
    private
    pure
    returns(
      buffer memory
    )
  {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    // Right-align data
    data = data >> (8 * (32 - len));
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + off + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
  * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeBytes20(
    buffer memory buf,
    uint off,
    bytes20 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, off, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chhaining.
  */
  function appendBytes20(
    buffer memory buf,
    bytes20 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendBytes32(
    buffer memory buf,
    bytes32 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
  * @dev Writes an integer to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (right-aligned).
  * @return The original buffer, for chaining.
  */
  function writeInt(
    buffer memory buf,
    uint off,
    uint data,
    uint len
  )
    private
    pure
    returns(
      buffer memory
    )
  {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
    * @dev Appends a byte to the end of the buffer. Resizes if doing so would
    * exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer.
    */
  function appendInt(
    buffer memory buf,
    uint data,
    uint len
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.19;

import { BufferChainlink } from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeType(
    BufferChainlink.buffer memory buf,
    uint8 major,
    uint value
  )
    private
    pure
  {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if(value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if(value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if(value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else if(value <= 0xFFFFFFFFFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(
    BufferChainlink.buffer memory buf,
    uint8 major
  )
    private
    pure
  {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(
    BufferChainlink.buffer memory buf,
    uint value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_INT, value);
  }

  function encodeInt(
    BufferChainlink.buffer memory buf,
    int value
  )
    internal
    pure
  {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else if(value >= 0) {
      encodeType(buf, MAJOR_TYPE_INT, uint(value));
    } else {
      encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
    }
  }

  function encodeBytes(
    BufferChainlink.buffer memory buf,
    bytes memory value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_BYTES, value.length);
    buf.append(value);
  }

  function encodeBigNum(
    BufferChainlink.buffer memory buf,
    int value
  )
    internal
    pure
  {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(uint(value)));
  }

  function encodeSignedBigNum(
    BufferChainlink.buffer memory buf,
    int input
  )
    internal
    pure
  {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint(-1 - input)));
  }

  function encodeString(
    BufferChainlink.buffer memory buf,
    string memory value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
    buf.append(bytes(value));
  }

  function startArray(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(
    bytes32 node
  )
    public
    view
    virtual
    returns (
      address
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
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
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IFlipCoinGenerator {
    function generateRandom() external view returns (uint8);
}

interface ISyntheticNFT is IERC721Metadata {

    function setMetadata(uint256 tokenId,string memory metadata) external;

    function isVerified(uint256 tokenId) external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

    function safeMint(
        address to,
        uint256 tokenId
    ) external;

    function safeBurn(uint256 tokenId) external;
}

interface ICollectionManagerFactory {
    function deploy(
        address originalCollectionAddress_,
        string memory name_,
        string memory symbol_
    ) external returns (address);
}

interface IJot is IERC20 {
    function uniswapV2Pair() external view returns (address);

    function safeMint(address account, uint256 amount) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IOwnable {
    event ChangeController(address oldController, address newController);

    function controller() external view returns (address);

    function setNewController(address newController) external;

    function claimNewController() external;
}


interface IMigratable is IOwnable {
    event PrepareMigration(uint256 migrationTimestamp, address source, address target);

    event ExecuteMigration(uint256 migrationTimestamp, address source, address target);

    function migrationTimestamp() external view returns (uint256);

    function migrationDestination() external view returns (address);

    function prepareMigration(address target, uint256 graceDays) external;

    function approveMigration() external;

    function executeMigration(address source) external;
}

interface IPerpetualPoolLite is IMigratable {
    struct SymbolInfo {
        uint256 symbolId;
        string symbol;
        address oracleAddress;
        int256 multiplier;
        int256 feeRatio;
        int256 fundingRateCoefficient;
        int256 price;
        int256 cumulativeFundingRate;
        int256 tradersNetVolume;
        int256 tradersNetCost;
    }

    struct SignedPrice {
        uint256 symbolId;
        uint256 timestamp;
        uint256 price;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event AddLiquidity(address indexed account, uint256 lShares, uint256 bAmount);

    event RemoveLiquidity(address indexed account, uint256 lShares, uint256 bAmount);

    event AddMargin(address indexed account, uint256 bAmount);

    event RemoveMargin(address indexed account, uint256 bAmount);

    event Trade(address indexed account, uint256 indexed symbolId, int256 tradeVolume, uint256 price);

    event Liquidate(address indexed account, address indexed liquidator, uint256 reward);

    event ProtocolFeeCollection(address indexed collector, uint256 amount);

    function getParameters()
        external
        view
        returns (
            int256 minPoolMarginRatio,
            int256 minInitialMarginRatio,
            int256 minMaintenanceMarginRatio,
            int256 minLiquidationReward,
            int256 maxLiquidationReward,
            int256 liquidationCutRatio,
            int256 protocolFeeCollectRatio
        );

    function getAddresses()
        external
        view
        returns (
            address bTokenAddress,
            address lTokenAddress,
            address pTokenAddress,
            address liquidatorQualifierAddress,
            address protocolFeeCollector
        );

    function getSymbol(uint256 symbolId) external view returns (SymbolInfo memory);

    function getLiquidity() external view returns (int256);

    function getLastUpdateBlock() external view returns (uint256);

    function getProtocolFeeAccrued() external view returns (int256);

    function collectProtocolFee() external;

    function addSymbol(
        uint256 symbolId,
        string memory symbol,
        address oracleAddress,
        uint256 multiplier,
        uint256 feeRatio,
        uint256 fundingRateCoefficient
    ) external;

    function removeSymbol(uint256 symbolId) external;

    function toggleCloseOnly(uint256 symbolId) external;

    function setSymbolParameters(
        uint256 symbolId,
        address oracleAddress,
        uint256 feeRatio,
        uint256 fundingRateCoefficient
    ) external;

    function addLiquidity(uint256 bAmount) external;

    function removeLiquidity(uint256 lShares) external;

    function addMargin(uint256 bAmount) external;

    function removeMargin(uint256 bAmount) external;

    function trade(uint256 symbolId, int256 tradeVolume) external;

    function liquidate(address account) external;

    function addLiquidity(uint256 bAmount, SignedPrice[] memory prices) external;

    function removeLiquidity(uint256 lShares, SignedPrice[] memory prices) external;

    function addMargin(uint256 bAmount, SignedPrice[] memory prices) external;

    function removeMargin(uint256 bAmount, SignedPrice[] memory prices) external;

    function trade(
        uint256 symbolId,
        int256 tradeVolume,
        SignedPrice[] memory prices
    ) external;

    function liquidate(address account, SignedPrice[] memory prices) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev collections struct
 */
struct SyntheticCollection {
    uint256 collectionID;
    address collectionManagerAddress;
    address jotAddress;
    address jotPoolAddress;
    address syntheticNFTAddress;
    string originalName;
    string originalSymbol;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./chainlink/RandomNumberConsumer.sol";
import "./chainlink/PolygonValidatorOracle.sol";
import "./implementations/SyntheticCollectionManager.sol";
import "./implementations/Jot.sol";
import "./implementations/JotPool.sol";
import "./implementations/SyntheticNFT.sol";
import "./auctions/AuctionsManager.sol";
import "./Structs.sol";
import "./governance/ProtocolParameters.sol";

contract SyntheticProtocolRouter is AccessControl, Ownable {
    using Counters for Counters.Counter;

    bytes32 public constant ORACLE = keccak256("ORACLE");

    /**
     * @dev implementation addresses for proxies
     */
    address private _jot;
    address private _jotPool;
    address private _collectionManager;
    address private _syntheticNFT;
    address private _auctionManager;

    address private _protocol;
    address private _fundingTokenAddress;
    address private _randomConsumerAddress;
    address private _validatorAddress;
    address private _perpetualPoolLiteAddress;

    address public oracleAddress;
    /**
     * @dev collections map.
     * collection address => collection data
     */
    mapping(address => SyntheticCollection) private _collections;

    /**
     * @dev get collection address from ID
     */
    mapping(uint256 => address) private _collectionIdToAddress;

    /**
     * @notice number of registered collections
     */
    Counters.Counter public protocolVaults;

    /**
     * @notice QuickSwap address
     */
    address public swapAddress;

    // a new Synthetic NFT collection manager is registered
    event CollectionManagerRegistered(
        uint256 collectionManagerID,
        address collectionManagerAddress,
        address jotAddress,
        address jotPoolAddress,
        address syntheticNFTAddress,
        address quickSwapAddress,
        address auctionAddress
    );

    event TokenRegistered(
        address collectionManagerAddress,
        uint256 collectionManagerID,
        uint256 syntheticTokenId
    );

    event TokenChanged(
        address collectionAddress,
        uint256 syntheticID,
        uint256 previousID,
        uint256 newID
    );

    constructor(
        address swapAddress_,
        address jot_,
        address jotPool_,
        address collectionManager_,
        address syntheticNFT_,
        address auctionManager_,
        address protocol_,
        address fundingTokenAddress_,
        address randomConsumerAddress_,
        address validatorAddress_,
        address perpetualPoolLiteAddress_,
        address oracleAddress_
    ) {
        swapAddress = swapAddress_;
        _jot = jot_;
        _jotPool = jotPool_;
        _collectionManager = collectionManager_;
        _syntheticNFT = syntheticNFT_;
        _auctionManager = auctionManager_;
        _protocol = protocol_;
        _fundingTokenAddress = fundingTokenAddress_;
        _randomConsumerAddress = randomConsumerAddress_;
        _validatorAddress = validatorAddress_;
        _perpetualPoolLiteAddress = perpetualPoolLiteAddress_;
        oracleAddress = oracleAddress_;
        _setupRole(ORACLE, oracleAddress_);
    }

    /**
     *  @notice register an NFT collection
     *  @param collection the address of the synthetic collection
     *  @param tokenId the token id
     *  @param supplyToKeep supply to keep
     *  @param priceFraction the price for a fraction
     *  @param originalName the original collection name
     *  @param originalSymbol the original collection symbol
     */
    function registerNFT(
        address collection,
        uint256 tokenId,
        uint256 supplyToKeep,
        uint256 priceFraction,
        string memory originalName,
        string memory originalSymbol
    ) public {
        require(collection != address(0), "Invalid collection");

        address collectionAddress;
        uint256 collectionID = protocolVaults.current();
        // Checks whether a collection is registered or not
        // If not registered, then register it and increase the Vault counter
        if (!isSyntheticCollectionRegistered(collection)) {
            // deploys a minimal proxy contract from the jot contract implementation
            address jotAddress = Clones.clone(_jot);
            Jot(jotAddress).initialize(
                string(abi.encodePacked("Privi Jot ", originalName)),
                string(abi.encodePacked("JOT_", originalSymbol)),
                swapAddress,
                _fundingTokenAddress
            );

            // deploys a minimal proxy contract from the jotPool contract implementation
            address jotPoolAddress = Clones.clone(_jotPool);
            JotPool(jotPoolAddress).initialize(jotAddress);

            address syntheticNFTAddress = Clones.clone(_syntheticNFT);

            // deploys a minimal proxy contract from the collectionManager contract implementation
            collectionAddress = Clones.clone(_collectionManager);
            SyntheticCollectionManager collectionContract = SyntheticCollectionManager(collectionAddress);
            collectionContract.initialize(
                jotAddress,
                collection,
                syntheticNFTAddress,
                _auctionManager,
                _protocol,
                _fundingTokenAddress,
                jotPoolAddress
            );

            AuctionsManager(_auctionManager).grantRole(
                AuctionsManager(_auctionManager).COLLECTION_MANAGER(),
                collectionAddress
            );

            collectionContract.grantRole(collectionContract.RANDOM_ORACLE(), _randomConsumerAddress);
            collectionContract.grantRole(collectionContract.VALIDATOR_ORACLE(), _validatorAddress);
            Jot(jotAddress).grantRole(Jot(jotAddress).MINTER(), collectionAddress);

            // set the manager to allow control over the funds
            Jot(jotAddress).setManager(collectionAddress, jotPoolAddress);

            SyntheticNFT(syntheticNFTAddress).initialize(
                string(abi.encodePacked("Privi Synthetic ", originalName)),
                string(abi.encodePacked("pS_", originalSymbol)),
                collectionAddress
            );

            _collections[collection] = SyntheticCollection({
                collectionID: collectionID,
                collectionManagerAddress: collectionAddress,
                jotAddress: jotAddress,
                jotPoolAddress: jotPoolAddress,
                syntheticNFTAddress: syntheticNFTAddress,
                originalName: originalName,
                originalSymbol: originalSymbol
            });

            _collectionIdToAddress[collectionID] = collectionAddress;

            initPerpetualPoolLite(collectionID, originalName);

            // whitelist the new collection contract on the random number consumer and the validator
            RandomNumberConsumer(_randomConsumerAddress).whitelistCollection(collectionAddress);
            PolygonValidatorOracle(_validatorAddress).whitelistCollection(collectionAddress);

            emit CollectionManagerRegistered(
                collectionID,
                collectionAddress,
                jotAddress,
                jotPoolAddress,
                syntheticNFTAddress,
                swapAddress,
                _auctionManager
            );

            protocolVaults.increment();

            //TODO: addSymbol with ”address” to the NFTPerpetualFutures
        } else {
            collectionAddress = _collections[collection].collectionManagerAddress;
        }

        SyntheticCollectionManager collectionManager = SyntheticCollectionManager(collectionAddress);

        uint256 syntheticID = collectionManager.register(tokenId, supplyToKeep, priceFraction);

        emit TokenRegistered(collectionAddress, collectionID, syntheticID);
    }

    /**
     * @notice change an NFT for another one
     */
    function changeNFT(
        address collection,
        uint256 syntheticID,
        uint256 newOriginalTokenID
    ) public {
        address collectionManager = getCollectionManagerAddress(collection);
        SyntheticCollectionManager manager = SyntheticCollectionManager(collectionManager);
        uint256 originalTokenID = manager.getOriginalID(syntheticID);
        manager.change(syntheticID, newOriginalTokenID, msg.sender);

        emit TokenChanged(
            collection,
            syntheticID,
            originalTokenID,
            newOriginalTokenID
        );
    }

    /**
     * @dev init Perpetual Pool Lite for a specific collection
     */

    function initPerpetualPoolLite(uint256 collectionID, string memory name) internal {
        ProtocolParameters protocol = ProtocolParameters(_protocol);
        address futuresOracleAddress = protocol.futuresOracleAddress();
        uint256 futuresMultiplier = protocol.futuresMultiplier();
        uint256 futuresFeeRatio = protocol.futuresFeeRatio();
        uint256 futuresFundingRateCoefficient = protocol.futuresFundingRateCoefficient();

        IPerpetualPoolLite futures = IPerpetualPoolLite(_perpetualPoolLiteAddress);

        futures.addSymbol(
            collectionID,
            name,
            futuresOracleAddress,
            futuresMultiplier,
            futuresFeeRatio,
            futuresFundingRateCoefficient
        );
    }

    /**
     * @notice checks whether a collection is registered or not
     */
    function isSyntheticCollectionRegistered(address collection) public view returns (bool) {
        return _collections[collection].collectionManagerAddress != address(0);
    }

    /**
     * @notice checks whether a Synthetic NFT has been created for a given NFT or not
     */
    function isSyntheticNFTCreated(address collection, uint256 tokenId) public view returns (bool) {
        // Collection must be registered first
        require(isSyntheticCollectionRegistered(collection), "Collection not registered");

        // connect to collection manager
        address collectionAddress = _collections[collection].collectionManagerAddress;
        address syntheticNFTAddress = SyntheticCollectionManager(collectionAddress).erc721address();

        // check whether a given id was minted or not
        return ISyntheticNFT(syntheticNFTAddress).exists(tokenId);
    }

    /**
     * @notice checks whether a Synthetic has been verified or not
     */
    function isNFTVerified(address collection, uint256 tokenId) public view returns (bool) {
        require(isSyntheticNFTCreated(collection, tokenId), "NFT not registered");
        address collectionManager = getCollectionManagerAddress(collection);
        return SyntheticCollectionManager(collectionManager).isVerified(tokenId);
    }

    /**
     * @notice verify a synthetic NFT
     */
    function verifyNFT(address collection, uint256 tokenId) public onlyRole(ORACLE) {
        require(isSyntheticNFTCreated(collection, tokenId), "NFT not registered");
        address collectionManager = getCollectionManagerAddress(collection);
        SyntheticCollectionManager(collectionManager).verify(tokenId);
    }

    /**
     * @notice getter for Jot Address of a collection
     */
    function getJotsAddress(address collection) public view returns (address) {
        return _collections[collection].jotAddress;
    }

    /**
     * @notice getter for Jot Pool Address of a collection
     */
    function getJotPoolAddress(address collection) public view returns (address) {
        return _collections[collection].jotPoolAddress;
    }

    /**
     * @notice get collection manager address from collection address
     */
    function getCollectionManagerAddress(address collection) public view returns (address) {
        return _collections[collection].collectionManagerAddress;
    }

    /**
     * @notice get collection manager address from collection ID
     */
    function getCollectionManagerAddress(uint256 collectionID) public view returns (address) {
        address collectionAddress = _collectionIdToAddress[collectionID];
        return _collections[collectionAddress].collectionManagerAddress;
    }

    /**
     * @notice get collection ID from collection address
     */
    function getCollectionID(address collection) public view returns (uint256) {
        return _collections[collection].collectionID;
    }

    /**
     * @notice get collection address from collection ID
     */
    function getOriginalCollectionAddress(uint256 collectionID) public view returns (address) {
        return _collectionIdToAddress[collectionID];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../governance/ProtocolParameters.sol";
import "../implementations/SyntheticCollectionManager.sol";
import "../SyntheticProtocolRouter.sol";
import "./NFTAuction.sol";

contract AuctionsManager is AccessControl, Initializable {
    bytes32 public constant COLLECTION_MANAGER = keccak256("COLLECTION_MANAGER");
    bytes32 public constant DEPLOYER = keccak256("DEPLOYER");
    bytes32 public constant AUCTION = keccak256("AUCTION");

    /**
     * @dev the implementation to deploy through minimal proxies
     */
    address private immutable _nftAuctionImplementation;

    ProtocolParameters public protocol;
    SyntheticProtocolRouter public router;

    mapping(address => mapping(uint256 => bool)) private _whitelistedTokens;

    event AuctionStarted(
        address indexed collection,
        uint256 indexed nftId,
        address auctionContract,
        uint256 openingBid
    );

    constructor(address nftAuction_) {
        _nftAuctionImplementation = nftAuction_;

        _setupRole(DEPLOYER, msg.sender);
    }

    function initialize(address protocol_, address router_) external initializer onlyRole(DEPLOYER) {
        protocol = ProtocolParameters(protocol_);
        router = SyntheticProtocolRouter(router_);

        _setupRole(DEFAULT_ADMIN_ROLE, router_);
    }

    function whitelistNFT(uint256 nftId_) external onlyRole(COLLECTION_MANAGER) {
        _whitelistedTokens[msg.sender][nftId_] = true;
    }

    /**
     * @dev we need to pass the jobSupply here to work well even when the governance
     *      changes this protocol parameter in the middle of the auction
     */
    function reassignNFT(
        address collection_,
        uint256 nftId_,
        address newOwner_,
        uint256 jotsSupply_
    ) external onlyRole(AUCTION) {
        SyntheticCollectionManager(collection_).reassignNFT(nftId_, newOwner_, jotsSupply_);
    }

    function startAuction(
        address collection_,
        uint256 nftId_,
        uint256 openingBid_
    ) external {
        uint256 jotsSupply = protocol.jotsSupply();
        require(_whitelistedTokens[collection_][nftId_], "Token can't be auctioned");
        require(openingBid_ >= jotsSupply, "Opening bid too low");
        require(router.isSyntheticNFTCreated(collection_, nftId_), "Non registered token");

        // blacklist the nft to avoid start a new auction
        _whitelistedTokens[collection_][nftId_] = false;

        address jotToken = router.getJotsAddress(collection_);

        // deploys a minimal proxy contract from privi nft auction implementation
        address auctionAddress = Clones.clone(_nftAuctionImplementation);
        NFTAuction(auctionAddress).initialize(
            nftId_,
            jotToken,
            router.getJotPoolAddress(collection_),
            router.getCollectionManagerAddress(collection_),
            jotsSupply,
            openingBid_,
            protocol.auctionDuration(),
            msg.sender
        );

        // give the AUCTION role to allow blacklisting
        _setupRole(AUCTION, auctionAddress);

        // transfer funds to the auction contract
        require(
            IERC20(jotToken).transferFrom(msg.sender, auctionAddress, openingBid_),
            "Unable to transfer jots"
        );

        emit AuctionStarted(collection_, nftId_, auctionAddress, openingBid_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AuctionsManager.sol";

contract NFTAuction is Initializable {
    // parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    uint256 public auctionEndTime;

    // current state of the auction.
    address public highestBidder;
    uint256 public highestBid;

    // getters
    uint256 public nftId;
    address public jot;
    address public jotPool;
    address public syntheticCollection;
    address public auctionsManager;

    // allowed withdrawals of previous bids
    mapping(address => uint256) private _pendingReturns;

    // set to true at the end, disallows any change.
    // by default initialized to `false`.
    bool private _claimed;

    uint256 private _jotSupply;

    // events that will be emitted on changes.
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    /// create a simple auction
    function initialize(
        uint256 nftId_,
        address jot_,
        address jotPool_,
        address syntheticCollection_,
        uint256 jotSupply_,
        uint256 initialBid_,
        uint256 auctionDuration_,
        address initialBidder_
    ) external initializer {
        nftId = nftId_;
        auctionEndTime = block.timestamp + auctionDuration_; // solhint-disable-line
        highestBid = initialBid_;
        _jotSupply = jotSupply_;
        jot = jot_;
        jotPool = jotPool_;
        syntheticCollection = syntheticCollection_;
        highestBidder = initialBidder_;
        auctionsManager = msg.sender;
    }

    /// bid on the auction.
    /// the value will only be refunded if the
    /// auction is not won.
    function bid(uint256 amount_) public payable {
        // revert the call if the bidding
        // period is over.
        // solhint-disable-next-line
        require(block.timestamp <= auctionEndTime, "Auction already ended");

        // if the bid is not higher revert
        require(amount_ > highestBid, "There already is a higher bid");

        // if the allowance is not enough or transfer fails revert
        require(IERC20(jot).transferFrom(msg.sender, address(this), amount_), "Unable to transfer jots");

        if (highestBid != 0) {
            // sending back the money by simply using
            // highestBidder.send(highestBid) is a security risk
            // because it could execute an untrusted contract.
            // it is always safer to let the recipients
            // withdraw their money themselves.
            _pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = amount_;

        emit HighestBidIncreased(msg.sender, amount_);
    }

    /// withdraw a bid that was overbid.
    function withdraw() public {
        uint256 amount = _pendingReturns[msg.sender];
        if (amount > 0) {
            // avoid reentrancy
            _pendingReturns[msg.sender] = 0;

            require(IERC20(jot).transfer(msg.sender, amount), "Unable to transfer jots");
        }
    }

    /// winner can claim the token after auction end time
    function endAuction() public {
        // solhint-disable-next-line
        require(block.timestamp >= auctionEndTime, "Auction not yet ended");
        require(!_claimed, "Token has already been claimed");

        _claimed = true;

        // transfer the jots
        require(IERC20(jot).transfer(jot, _jotSupply), "Unable to transfer jots");

        if (highestBid - _jotSupply > 0) {
            require(IERC20(jot).transfer(jotPool, highestBid - _jotSupply), "Unable to transfer jots");
        }

        // reassign the NFT in the synthetic collection
        AuctionsManager(auctionsManager).reassignNFT(syntheticCollection, nftId, highestBidder, _jotSupply);

        emit AuctionEnded(highestBidder, highestBid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct APIOracleInfo {
    address linkToken;
    address chainlinkNode;
    string jobId;
    uint256 nodeFee;
}

struct VRFOracleInfo {
    address vrfCoordinator;
    address linkToken;
    bytes32 keyHash;
    uint256 vrfFee;
}

struct VerifyRequest {
    address originalCollection;
    address syntheticCollection;
    uint256 tokenId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../implementations/SyntheticCollectionManager.sol";
import "./OracleStructs.sol";

/**
 * @dev the ownership will be transferred after deployment to the router contract
 */
contract PolygonValidatorOracle is ChainlinkClient, Ownable {
    /**
     * @dev oracle configuration parameters
     */
    string public token;
    string public apiURL;
    address public chainlinkNode;
    bytes32 public jobId;
    uint256 public nodeFee;
    address public linkToken;

    mapping(bytes32 => VerifyRequest) private _verifyRequests;
    mapping(address => bool) private _whitelistedCollections;

    event ResponseReceived(
        bytes32 indexed requestId,
        address originalCollection,
        address syntheticCollection,
        uint256 tokenId,
        bool verified
    );

    constructor(APIOracleInfo memory _oracleInfo) {
        linkToken = _oracleInfo.linkToken;
        chainlinkNode = _oracleInfo.chainlinkNode;
        jobId = stringToBytes32(_oracleInfo.jobId);
        nodeFee = (_oracleInfo.nodeFee * LINK_DIVISIBILITY) / 1000;
        apiURL = "SHOULD BE DEPLOYED YET";

        setChainlinkToken(linkToken);
    }

    /**
     * @dev call to verify if a token is locked in ethereum vault,
     * this method can be called only from the collection manager contract
     * @param ethereumCollection the collection address in ethereum
     * @param tokenId the id of the nft in the collection
     * @return requestId the id of the request to the Chainlink oracle
     */
    function verifyTokenInCollection(address ethereumCollection, uint256 tokenId)
        external
        returns (bytes32 requestId)
    {
        require(_whitelistedCollections[msg.sender], "Invalid requester");

        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.processResponse.selector
        );

        // set the request params
        Chainlink.add(
            request,
            "get",
            string(
                abi.encodePacked(apiURL, "?collection=", ethereumCollection, "&tokenId=", uint2str(tokenId))
            )
        );
        Chainlink.add(request, "path", "locked");

        // Send the request
        requestId = sendChainlinkRequestTo(chainlinkNode, request, nodeFee);

        _verifyRequests[requestId] = VerifyRequest({
            tokenId: tokenId,
            originalCollection: ethereumCollection,
            syntheticCollection: msg.sender
        });
    }

    /**
     * @dev function to process the oracle response (only callable from oracle)
     * @param requestId the id of the request to the Chainlink oracle
     * @param verified wether the nft is locked or not on ethereum
     */
    function processResponse(bytes32 requestId, bool verified) public recordChainlinkFulfillment(requestId) {
        VerifyRequest memory requestData = _verifyRequests[requestId];

        // only call the synthetic collection contract if is locked
        if (verified) {
            SyntheticCollectionManager(requestData.syntheticCollection).processSuccessfulVerify(
                requestData.tokenId
            );
        }

        emit ResponseReceived(
            requestId,
            requestData.originalCollection,
            requestData.syntheticCollection,
            requestData.tokenId,
            verified
        );
    }

    /**
     * @dev whitelist collections in order to allow calling this contract
     * (only router can whitelist after deploying the proxy, the router contract owns this one)
     * @param collectionId the collection manager (sythetic collection from polygon)
     */
    function whitelistCollection(address collectionId) external onlyOwner {
        _whitelistedCollections[collectionId] = true;
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(add(source, 32))
        }
    }

    function uint2str(uint256 _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../implementations/SyntheticCollectionManager.sol";

/**
 * @dev the ownership will be transferred after deployment to the router contract
 */
contract RandomNumberConsumer is VRFConsumerBase, Ownable {
    bytes32 internal immutable keyHash;
    uint256 internal immutable fee;

    mapping(bytes32 => address) private _requestIdToCollection;
    mapping(address => bool) private _whitelistedCollections;

    /**
     * @dev constructor inherits VRFConsumerBase
     */
    constructor(VRFOracleInfo memory _oracleInfo)
        VRFConsumerBase(_oracleInfo.vrfCoordinator, _oracleInfo.linkToken)
    {
        keyHash = _oracleInfo.keyHash;
        fee = _oracleInfo.vrfFee;
    }

    /**
     * @dev requests randomness
     */
    function getRandomNumber() external returns (bytes32 requestId) {
        require(_whitelistedCollections[msg.sender], "Invalid requester");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");

        requestId = requestRandomness(keyHash, fee);
        _requestIdToCollection[requestId] = msg.sender;
    }

    /**
     * @dev callback function used by VRF Coordinator (only 200k gas allowed and should not revert)
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        SyntheticCollectionManager(_requestIdToCollection[requestId]).processFlipResult(
            randomness % 2,
            requestId
        );
    }

    /**
     * @dev whitelist collections to get random from this contract
     */
    function whitelistCollection(address collectionId) external onlyOwner {
        _whitelistedCollections[collectionId] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev allows to send funds from a managed account (infinite allowance)
 */
interface IERC20ManagedAccounts {
    function transferFromManaged(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title parameters controlled by governance
 * @notice the owner of this contract is the timelock controller of the governance feature
 */
contract ProtocolParameters is Ownable {
    // this is the number of Jots minted when a new single NFT is synthetic fractionalised
    uint256 public jotsSupply;

    // interval in seconds between the one flip to another in one lock contract
    uint256 public flippingInterval;

    // amount of reward that the flipper gets if he is right on the outcome
    uint256 public flippingReward;

    // amount of jots into play in each flip
    uint256 public flippingAmount;

    // the duration of an NFT auction in seconds
    uint256 public auctionDuration;


    // the implementation of FlipCoinGenerator
    address public flipCoinGenerator;

    // futures variables 
    address public futuresOracleAddress;
    uint256 public futuresMultiplier;
    uint256 public futuresFeeRatio;
    uint256 public futuresFundingRateCoefficient;

    event JotsSupplyUpdated(uint256 value);
    event FlippingIntervalUpdated(uint256 value);
    event FlippingRewardUpdated(uint256 value);
    event FlippingAmountUpdated(uint256 value);
    event AuctionDurationUpdated(uint256 value);
    event FlipCoinGeneratorUpdated(address value);
    event FuturesOracleAddressUpdated(address value);
    event FuturesMultiplierUpdated(uint256 value);
    event FuturesFeeRatioUpdated(uint256 value);
    event FuturesFundingRateCoefficientUpdated(uint256 value);

    /**
     * @dev sets the default (initial) values of the parameters
     *      also transfers the ownership to the governance
     */
    constructor(
        uint256 jotsSupply_,
        uint256 flippingInterval_,
        uint256 flippingReward_,
        uint256 flippingAmount_,
        uint256 auctionDuration_,
        address governanceContractAddress_,
        address futuresOracleAddress_,
        uint256 futuresMultiplier_,
        uint256 futuresFeeRatio_,
        uint256 futuresFundingRateCoefficient_
    ) {
        require(flippingReward_ > 0, "Invalid Reward");
        require(flippingAmount_ > 0, "Invalid Amount");
        require(flippingReward_ < flippingAmount_, "Reward should be lower than Amount");
        require(jotsSupply_ > 0, "Invalid Jots Supply");
        require(flippingInterval_ > 15 minutes, "Flipping Interval should be greater than 15 minutes");
        require(auctionDuration_ > 1 hours, "Auction duration should be greater than 1 hour");
        require(futuresOracleAddress_ != address(0), "Oracle address can't be zero");
        require(futuresMultiplier_ > 0, "Invalid futures multiplier");
        require(futuresFeeRatio_> 0, "Invalid futures fee ratio");
        require(futuresFundingRateCoefficient_ > 0, "Invalid futures funding rate coefficient");

        jotsSupply = jotsSupply_;
        flippingInterval = flippingInterval_;
        flippingReward = flippingReward_;
        flippingAmount = flippingAmount_;
        auctionDuration = auctionDuration_;

        futuresOracleAddress = futuresOracleAddress_;
        futuresMultiplier = futuresMultiplier_;
        futuresFeeRatio = futuresFeeRatio_;
        futuresFundingRateCoefficient = futuresFundingRateCoefficient_;

        // transfer ownership
        transferOwnership(governanceContractAddress_);
    }

    function setJotsSupply(uint256 jotsSupply_) external onlyOwner {
        require(jotsSupply_ > 0, "Invalid Jots Supply");
        jotsSupply = jotsSupply_;
        emit JotsSupplyUpdated(jotsSupply_);
    }

    function setFlippingInterval(uint256 flippingInterval_) external onlyOwner {
        require(flippingInterval_ > 15 minutes, "Flipping Interval should be greater than 15 minutes");
        flippingInterval = flippingInterval_;
        emit FlippingIntervalUpdated(flippingInterval_);
    }

    function setFlippingReward(uint256 flippingReward_) external onlyOwner {
        require(flippingReward_ > 0, "Invalid Reward");
        require(flippingReward_ < flippingAmount, "Reward should be lower than Amount");
        flippingReward = flippingReward_;
        emit FlippingRewardUpdated(flippingReward_);
    }

    function setFlippingAmount(uint256 flippingAmount_) external onlyOwner {
        require(flippingAmount_ > 0, "Invalid Amount");
        require(flippingReward < flippingAmount_, "Reward should be lower than Amount");
        flippingAmount = flippingAmount_;
        emit FlippingAmountUpdated(flippingAmount_);
    }

    function setAuctionDuration(uint256 auctionDuration_) external onlyOwner {
        require(auctionDuration_ > 1 hours, "Auction duration should be greater than 1 hour");
        auctionDuration = auctionDuration_;
        emit AuctionDurationUpdated(auctionDuration_);
    }

    function setFuturesOracleAddress(address futuresOracleAddress_) external onlyOwner {
        require(futuresOracleAddress_ != address(0), "Oracle address can't be zero");
        futuresOracleAddress = futuresOracleAddress_;
        emit FuturesOracleAddressUpdated(futuresOracleAddress_);
    }

    function setFuturesMultiplier(uint256 futuresMultiplier_) external onlyOwner {
        require(futuresMultiplier_ > 1 hours, "Invalid futures multiplier");
        futuresMultiplier = futuresMultiplier_;
        emit FuturesMultiplierUpdated(futuresMultiplier_);
    }

    function setFuturesFeeRatio(uint256 futuresFeeRatio_) external onlyOwner {
        require(futuresFeeRatio_ > 1 hours, "Invalid futures fee ratio");
        futuresFeeRatio = futuresFeeRatio_;
        emit FuturesFeeRatioUpdated(futuresFeeRatio_);
    }

    function setFuturesFundingRateCoefficient(uint256 futuresFundingRateCoefficient_) external onlyOwner {
        require(futuresFundingRateCoefficient_ > 1 hours, "Invalid futures funding rate coefficient");
        futuresFundingRateCoefficient = futuresFundingRateCoefficient_;
        emit FuturesFundingRateCoefficientUpdated(futuresFundingRateCoefficient_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../extensions/IERC20ManagedAccounts.sol";
import "../Interfaces.sol";

contract Jot is ERC20, IERC20ManagedAccounts, AccessControl, Initializable {
    bytes32 public constant ROUTER = keccak256("ROUTER");
    bytes32 public constant MINTER = keccak256("MINTER");

    // proxied values for the erc20 attributes
    string private _proxiedName;
    string private _proxiedSymbol;

    /**
     * @notice *swap address
     */
    IUniswapV2Router02 public uniswapV2Router;

    /**
     * @notice pair address
     */
    address public uniswapV2Pair;

    mapping(address => address) private _managers;

    // solhint-disable-next-line
    constructor() ERC20("Privi Jot Token Implementation", "pJOTI") {}

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address swapAddress,
        address fundingTokenAddress
    ) external initializer {
        _proxiedName = _name;
        _proxiedSymbol = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ROUTER, msg.sender);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swapAddress);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            fundingTokenAddress
        );
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER) {
        _mint(account, amount);
    }

    /**
     * @dev allows to send funds from a managed account (infinite allowance)
     */
    function transferFromManaged(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override {
        require(_managers[sender] == msg.sender, "The caller is not the manager of this account");
        _transfer(sender, recipient, amount);
    }

    function setManager(address manager, address account) external onlyRole(ROUTER) {
        _managers[account] = manager;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _proxiedName;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _proxiedSymbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract JotPool is Initializable {
    using SafeERC20 for IERC20;

    uint256 public totalLiquidity;

    mapping(address => uint256) private liquidity;

    address public jot;

    event LiquidityAdded(address provider, uint256 amount, uint256 mintedLiquidity);
    event LiquidityRemoved(address provider, uint256 amount, uint256 liquidityBurnt);

    function initialize(address _jot) external initializer {
        require(_jot != address(0), "Invalid Jot token");
        jot = _jot;
    }

    function addLiquidity(uint256 amount) external {
        require(amount > 0, "Invalid amount");
        uint256 mintedLiquidity = totalLiquidity > 0
            ? (totalLiquidity * amount) / IERC20(jot).balanceOf(address(this))
            : 100;
        liquidity[msg.sender] += mintedLiquidity;
        totalLiquidity += mintedLiquidity;
        emit LiquidityAdded(msg.sender, amount, mintedLiquidity);
        IERC20(jot).safeTransferFrom(msg.sender, address(this), amount);
    }

    function removeLiquidity(uint256 amount) external {
        require(liquidity[msg.sender] >= amount, "Remove amount exceeds balance");
        uint256 liquidityBurnt = (IERC20(jot).balanceOf(address(this)) * amount) / totalLiquidity;
        if (totalLiquidity - amount > 0) {
            liquidity[msg.sender] -= amount;
            totalLiquidity -= amount;
        } else {
            liquidity[msg.sender] = 100;
            totalLiquidity = 100;
        }

        emit LiquidityRemoved(msg.sender, amount, liquidityBurnt);

        IERC20(jot).safeTransfer(msg.sender, liquidityBurnt);
    }

    function balance() external view returns (uint256) {
        return liquidity[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct TokenData {
    uint256 originalTokenID;
    uint256 ownerSupply;
    uint256 sellingSupply;
    uint256 soldSupply;
    uint256 liquiditySupply;
    uint256 liquiditySold;
    uint256 fractionPrices;
    uint256 lastFlipTime;
    bool verified;
    uint256 originalID;
}

struct Flip {
    uint256 tokenId;
    uint256 prediction;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../extensions/IERC20ManagedAccounts.sol";
import "../auctions/AuctionsManager.sol";
import "../chainlink/RandomNumberConsumer.sol";
import "../chainlink/PolygonValidatorOracle.sol";
import "../SyntheticProtocolRouter.sol";
import "../Interfaces.sol";
import "../governance/ProtocolParameters.sol";
import "./Jot.sol";
import "./Structs.sol";

contract SyntheticCollectionManager is AccessControl, Initializable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    bytes32 public constant ROUTER = keccak256("ROUTER");
    bytes32 public constant AUCTION_MANAGER = keccak256("AUCTION_MANAGER");
    bytes32 public constant RANDOM_ORACLE = keccak256("RANDOM_ORACLE");
    bytes32 public constant VALIDATOR_ORACLE = keccak256("VALIDATOR_ORACLE");

    address private immutable _randomConsumerAddress;
    address private immutable _validatorAddress;
    address private _auctionsManagerAddress;

    /**
     * @dev ERC20 totalSupply (governance) parameter
     * TODO: get from governance
     */
    uint256 private _jotsSupply;

    /**
     * @dev mapping the request id with the flip input data
     */
    mapping(bytes32 => Flip) private _flips;

    mapping(uint256 => uint256) private _originalToSynthetic;

    Counters.Counter public tokenCounter;

    /**
     * @notice the address of the Protocol Router
     */
    address public syntheticProtocolRouterAddress;

    ProtocolParameters public protocol;

    /**
     * @notice address of the original collection
     */
    address public originalCollectionAddress;

    /**
     * @notice jot Address for this collection
     */
    address public jotAddress;

    /**
     * @notice funding token address
     */
    address public fundingTokenAddress;

    /**
     * @notice data for each token
     */
    mapping(uint256 => TokenData) public tokens;

    /**
     * @notice the nft should be auctioned to unlock it
     */
    mapping(uint256 => bool) public lockedNFTs;

    /**
     * @notice Synthetic NFT Address  for this collection
     */
    address public erc721address;

    IUniswapV2Router02 public uniswapV2Router;

    address public jotPool;

    event CoinFlipped(
        bytes32 indexed requestId,
        address indexed player,
        uint256 indexed tokenId,
        uint256 prediction
    );
    event FlipProcessed(
        bytes32 indexed requestId,
        uint256 indexed tokenId,
        uint256 prediction,
        uint256 randomResult
    );

    constructor(address randomConsumerAddress, address validatorAddress) {
        _randomConsumerAddress = randomConsumerAddress;
        _validatorAddress = validatorAddress;
    }

    function initialize(
        address _jotAddress,
        address originalCollectionAddress_,
        address _erc721address,
        address auctionManagerAddress,
        address protocol_,
        address fundingTokenAddress_,
        address jotPool_
    ) external initializer {
        jotAddress = _jotAddress;
        erc721address = _erc721address;
        originalCollectionAddress = originalCollectionAddress_;
        syntheticProtocolRouterAddress = msg.sender;
        _auctionsManagerAddress = auctionManagerAddress;
        protocol = ProtocolParameters(protocol_);
        jotPool = jotPool_;

        _jotsSupply = protocol.jotsSupply();
        fundingTokenAddress = fundingTokenAddress_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ROUTER, msg.sender);
        _setupRole(AUCTION_MANAGER, auctionManagerAddress);
    }

    /**
     * @dev we need to pass the jobSupply here to work well even when the governance
     *      changes this protocol parameter in the middle of the auction
     */
    function reassignNFT(
        uint256 nftId_,
        address newOwner_,
        uint256 jotsSupply_
    ) external onlyRole(AUCTION_MANAGER) {
        TokenData storage data = tokens[nftId_];

        // the auction could only be started if ownerSupply is 0
        assert(data.ownerSupply == 0);

        // TODO: implement this logic

        // data.ownerSupply = jotsSupply_;
        // data.sellingSupply = 0;
        // data.soldSupply = 0;
        // data.liquiditySupply = 0;
        // data.liquiditySold = 0;
        // data.fractionPrices = 0;
    }

    /**
     * @notice change an NFT for another one of the same collection
     */
    function change(
        uint256 syntheticID,
        uint256 newOriginalTokenID,
        address caller
    ) public onlyRole(ROUTER) {
        // Token must be registered
        require(ISyntheticNFT(erc721address).exists(syntheticID), "token not registered!");

        // Caller must be token owner
        address tokenOwner = IERC721(erc721address).ownerOf(syntheticID);
        require(tokenOwner == caller, "You are not the owner of the NFT!");
        
        // Change original token ID and set verified = false
        uint256 originalID = tokens[syntheticID].originalID;

        _originalToSynthetic[originalID] = 0;
        _originalToSynthetic[newOriginalTokenID] = syntheticID;
        
        tokens[syntheticID].originalID = newOriginalTokenID;
        tokens[syntheticID].verified = false;
        
    }

    /**
     * @notice Get the owner of the NFT
     */
    function getSyntheticNFTOwner(uint256 tokenId) private view returns (address) {
        //TODO: get owner from Oracle
        return IERC721(erc721address).ownerOf(tokenId);
    }

    /**
     * @notice returns the Quickswap pool address
     */
    function poolAddress() public view returns (address) {
        //TODO: check if pool is initiated
        return IJot(jotAddress).uniswapV2Pair();
    }

    /**
     * @notice public function. Checks if an NFT has
     * been already fractionalized
     */
    function isSyntheticNFTCreated(uint256 tokenId) public view returns (bool) {
        return _originalToSynthetic[tokenId] != 0;
    }

    /**
     * @notice public function. Checks if an NFT has
     * been already fractionalised.
     */
    function isSyntheticNFTFractionalised(uint256 tokenId) public view returns (bool) {
        return tokens[tokenId].ownerSupply != 0;
    }

    /**
     * @notice Checks isSyntheticNFTCreated(address, id) is False.
     * Then it mints a new NFT with: ”to”, ”id” and ”metadata”
     */
    function generateSyntheticNFT(
        address to, 
        uint256 tokenId
    ) private {
        ISyntheticNFT(erc721address).safeMint(to, tokenId);
    }

    /**
     * @notice First
     * it updates counter syntheticID++. Then:
     * • generateSyntheticNFT(address, id)
     * • Interacts with JOT contract for that address and:
     * (a) Mints JotSupply (governance parameter)
     * (b) Register ownerSupply (DO NOT SEND HIM/HER)
     * (c) Register sellingSupply = (JotSupply-supplyToKeep)/2
     * (d) Register soldSupply = 0
     * (e) Register liquiditySupply = (JotSupply-supplyToKeep)/2.
     * (f) Register liquiditySold = 0
     *
     */
    function register(
        uint256 tokenId,
        uint256 supplyToKeep,
        uint256 priceFraction
    ) public onlyRole(ROUTER) returns (uint256) {
        require(priceFraction > 0, "priceFraction can't be zero");
        require(isSyntheticNFTCreated(tokenId) == false, "Synthetic NFT already generated!");
        
        uint256 syntheticID = tokenCounter.current();

        generateSyntheticNFT(msg.sender, syntheticID);
 
        Jot(jotAddress).mint(address(this), _jotsSupply);

        uint256 sellingSupply = (_jotsSupply - supplyToKeep) / 2;
        uint256 liquiditySupply = (_jotsSupply - supplyToKeep) / 2;

        TokenData memory data = TokenData(
            tokenId,
            supplyToKeep,
            sellingSupply,
            0,
            liquiditySupply,
            0,
            priceFraction,
            0,
            false,
            0
        );

        tokens[syntheticID] = data;

        tokenCounter.increment(); 

        return syntheticID;
    }

    /**
     * @notice allows the caller to buy jots using the Funding token
     */
    function buyJotTokens(uint256 tokenId, uint256 buyAmount) public {
        require(ISyntheticNFT(erc721address).exists(tokenId), "Token not registered");
        require(tokens[tokenId].fractionPrices > 0, "Token price not set");
        uint256 amount = (buyAmount * tokens[tokenId].fractionPrices) / 10**18;
        require(amount > 0, "Amount can't be zero!");

        // Calculate amount left
        uint256 amountLeft = tokens[tokenId].sellingSupply - tokens[tokenId].soldSupply;

        // If amount left is lesser than buying amount
        // then buying amount = amount left

        if (amountLeft < amount) {
            amount = amountLeft;
        }

        // Can't sell zero tokens
        require(amount != 0, "No tokens left!");

        // Transfer funding tokens
        IERC20(fundingTokenAddress).transferFrom(msg.sender, address(this), amount);

        // Transfer Jots
        IJot(jotAddress).transferFrom(address(this), msg.sender, buyAmount);

        //Increase sold supply (amount in token) and liquidity sold (amount in ether)
        tokens[tokenId].soldSupply += buyAmount;
        tokens[tokenId].liquiditySold += amount;

        //If all jots have been sold, then add liquidity
        if (amount == amountLeft) {
            addLiquidityToPool(tokenId);
        }
    }

    /**
     * @notice increase selling supply for a given NFT
     * caller must be the owner of the NFT
     */

    function increaseSellingSupply(uint256 tokenId, uint256 amount) public {
        require(msg.sender == getSyntheticNFTOwner(tokenId), "You are not the owner of the NFT!");
        require(tokens[tokenId].ownerSupply >= amount, "You do not have enough tokens left");
        tokens[tokenId].ownerSupply -= amount;
        tokens[tokenId].sellingSupply += amount / 2;
        tokens[tokenId].liquiditySupply += amount / 2;
    }

    /**
     * @notice decrease selling supply for a given NFT
     * caller must be the owner of the NFT
     */
    function decreaseSellingSupply(uint256 tokenId, uint256 amount) public {
        require(msg.sender == getSyntheticNFTOwner(tokenId), "You are not the owner of the NFT!");
        require(tokens[tokenId].liquiditySupply >= amount / 2, "You do not have enough liquidity left");
        require(tokens[tokenId].sellingSupply >= amount / 2, "You do not have enough selling supply left");

        tokens[tokenId].ownerSupply += amount;
        tokens[tokenId].sellingSupply -= amount / 2;
        tokens[tokenId].liquiditySupply -= amount / 2;
    }

    /**
     * @notice update the price of a fraction for a given NFT
     * caller must be the owner
     */
    function updatePriceFraction(uint256 tokenId, uint256 newFractionPrice) public {
        require(ISyntheticNFT(erc721address).exists(tokenId), "Token not registered");
        require(msg.sender == getSyntheticNFTOwner(tokenId), "You are not the owner of the NFT!");
        tokens[tokenId].fractionPrices = newFractionPrice;
    }

    /**
     * @notice add available liquidity for a given token to UniSwap pool
     */
    function addLiquidityToPool(uint256 tokenId) public {
        uint256 liquiditySupply = tokens[tokenId].liquiditySupply;
        uint256 liquiditySold = tokens[tokenId].liquiditySold;

        // approve token transfer to cover all possible scenarios
        IJot(jotAddress).approve(address(uniswapV2Router), liquiditySupply);

        IERC20(fundingTokenAddress).approve(address(uniswapV2Router), liquiditySold);

        // add the liquidity
        uniswapV2Router.addLiquidity(
            jotAddress,
            fundingTokenAddress,
            liquiditySupply,
            liquiditySold,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp // solhint-disable-line
        );
    }

    function isAllowedToFlip(uint256 tokenId) public view returns (bool) {
        require(ISyntheticNFT(erc721address).exists(tokenId), "Token not registered");
        return
            // solhint-disable-next-line
            block.timestamp - tokens[tokenId].lastFlipTime >= protocol.flippingInterval() &&
            IERC20(jotAddress).balanceOf(jotPool) > 0 &&
            isSyntheticNFTFractionalised(tokenId);
    }

    function flipJot(uint256 tokenId, uint256 prediction) external {
        require(isAllowedToFlip(tokenId), "Flip is not allowed yet");
        tokens[tokenId].lastFlipTime = block.timestamp; // solhint-disable-line

        bytes32 requestId = RandomNumberConsumer(_randomConsumerAddress).getRandomNumber();
        _flips[requestId] = Flip({tokenId: tokenId, prediction: prediction});

        emit CoinFlipped(requestId, msg.sender, tokenId, prediction);
    }

    function processFlipResult(uint256 randomNumber, bytes32 requestId) external onlyRole(RANDOM_ORACLE) {
        uint256 poolAmount;
        uint256 fAmount = protocol.flippingAmount();
        uint256 fReward = protocol.flippingReward();

        Flip memory flip = _flips[requestId];
        uint256 ownerSupply = tokens[flip.tokenId].ownerSupply;

        // avoid underflow in math operations
        if (fAmount > ownerSupply) {
            fAmount = ownerSupply;
        }
        if (fReward > fAmount) {
            fReward = fAmount;
        }

        if (randomNumber == 0) {
            tokens[flip.tokenId].ownerSupply -= fAmount;
            if (randomNumber != flip.prediction) {
                poolAmount = fAmount;
            } else {
                poolAmount = fAmount - fReward;
                IERC20(jotAddress).safeTransfer(msg.sender, fReward);
            }
            if (poolAmount > 0) {
                IERC20(jotAddress).safeTransfer(jotPool, poolAmount);
            }
        } else {
            tokens[flip.tokenId].ownerSupply += fAmount;
            if (randomNumber != flip.prediction) {
                poolAmount = fAmount;
            } else {
                poolAmount = fAmount - fReward;
                IERC20(jotAddress).safeTransfer(msg.sender, fReward);
            }
            if (poolAmount > 0) {
                IERC20ManagedAccounts(jotAddress).transferFromManaged(jotPool, address(this), poolAmount);
            }
        }

        // lock the nft and make it auctionable
        if (tokens[flip.tokenId].ownerSupply == 0) {
            lockedNFTs[flip.tokenId] = true;
            AuctionsManager(_auctionsManagerAddress).whitelistNFT(flip.tokenId);
        }

        emit FlipProcessed(requestId, flip.tokenId, flip.prediction, randomNumber);
    }

    /**
     * @notice This method calls chainlink oracle and
     * verifies if the NFT has been locked on NFTVaultManager. In addition
     * gets the metadata of the NFT
     */
    function verify(uint256 tokenId) external {
        require(ISyntheticNFT(erc721address).exists(tokenId), "Token not registered");
        require(!tokens[tokenId].verified, "Token already verified");
        PolygonValidatorOracle(_validatorAddress).verifyTokenInCollection(originalCollectionAddress, tokenId);
    }

    function processSuccessfulVerify(uint256 tokenId) external onlyRole(VALIDATOR_ORACLE) {
        tokens[tokenId].verified = true;
    }

    /**
     * @dev burn a token
     */
    function safeBurn(uint256 tokenId) public onlyRole(ROUTER) {
        ISyntheticNFT(erc721address).safeBurn(tokenId);
        tokenCounter.decrement();
    }

    function getRemainingSupply(uint256 tokenId) public view returns (uint256) {
        return tokens[tokenId].ownerSupply;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function isVerified(uint256 tokenId) public view returns (bool) {
        require(ISyntheticNFT(erc721address).exists(tokenId), "NFT not minted");
        return tokens[tokenId].verified;
    }

    function getOriginalID(uint256 tokenId) public view returns (uint256) {
        require(ISyntheticNFT(erc721address).exists(tokenId));
        return tokens[tokenId].originalID;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../Interfaces.sol";
import "./SyntheticCollectionManager.sol";
import "./Structs.sol";

contract SyntheticNFT is ERC721, Initializable, AccessControl {
    bytes32 public constant MANAGER = keccak256("MANAGER");    

    // token metadata
    mapping(uint256 => string) private _tokenMetadata;

    // proxied values for the erc721 attributes
    string private _proxiedName;
    string private _proxiedSymbol;

    address private _collectionManager;

    // solhint-disable-next-line
    constructor() ERC721("Privi Collection Token", "PCT") {}

    function initialize(
        string memory name_,
        string memory symbol_,
        address collectionManager_
    ) external initializer {
        _proxiedName = name_;
        _proxiedSymbol = symbol_;
        _collectionManager = collectionManager_;

        _setupRole(MANAGER, collectionManager_);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _proxiedName;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _proxiedSymbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenMetadata[tokenId];
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId
    ) public onlyRole(MANAGER) {
        _mint(to, tokenId);
    }

    function setMetadata(
        uint256 tokenId,
        string memory metadata
    ) public onlyRole(MANAGER) {
        _tokenMetadata[tokenId] = metadata;
    }

    function safeBurn(uint256 tokenId) public onlyRole(MANAGER) {
        _burn(tokenId);
        _tokenMetadata[tokenId] = "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev override the before transfer hook to allow locking the nft
     */
    function _beforeTokenTransfer(
        address,
        address,
        uint256 tokenId
    ) internal view override {
        require(
            !SyntheticCollectionManager(_collectionManager).lockedNFTs(tokenId),
            "Token is locked and auctionable"
        );
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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