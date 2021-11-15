// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/dev/VRFConsumerBase.sol";
import "./helpers/DexRNG.sol";

import { IProtocolControl, IRNGReceiver } from "./Interfaces.sol";

contract RNG is DexRNG, VRFConsumerBase {

  /// @dev The pack protocol admin contract.
  IProtocolControl internal controlCenter;

  /// @dev Pack protocol module names.
  string public constant PACK = "PACK";
  
  /// @dev tokenId => whether and external RNG service is used for opening the pack.
  mapping(uint => bool) public usingExternalService;

  /// @dev Chainlink VRF requirements.
  uint internal fees;
  bytes32 internal keyHash;

  /// @dev Increments by one. Acts as a human readable request ID for each external RNG request.
  uint public currentRequestId;

  /// @dev bytes request ID => human readable integer request ID.
  mapping(bytes32 => uint) public requestIds;

  /// @dev Events.
  event ExternalServiceRequest(address indexed requestor, uint requestId);
  event RandomNumberExternal(uint randomNumber);

  modifier onlyPack() {
    require(msg.sender == address(pack()), "RNG: Only the pack token contract can call this function.");
    _;
  }

  modifier onlyProtocolAdmin() {
    require(
      controlCenter.hasRole(controlCenter.PROTOCOL_ADMIN(), msg.sender), 
      "RNG: Only a pack protocol admin can call this function."
    );
    _;
  }

  constructor(
    address _controlCenter,

    address _vrfCoordinator,
    address _linkToken,
    bytes32 _keyHash,
    uint _fees

  ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
    controlCenter = IProtocolControl(_controlCenter);

    keyHash = _keyHash;
    fees = _fees;
  }

  /**
   *  Chainlink VRF functions
  **/
  
  /// @dev Sends a random number request to the Chainlink VRF system.
  function requestRandomNumber() external onlyPack returns (uint requestId) {
    require(LINK.balanceOf(address(this)) >= fees, "Not enough LINK to fulfill randomness request.");
    
    // Send random number request.
    bytes32 bytesId = requestRandomness(keyHash, fees, seed);
    
    // Return an integer Id instead of a bytes Id for convenience.
    requestId = currentRequestId;
    requestIds[bytesId] = requestId;

    currentRequestId++;

    emit ExternalServiceRequest(msg.sender, requestId);
  }

  /// @dev Called by Chainlink VRF random number provider.
  function fulfillRandomness(bytes32 requestId, uint randomness) internal override {

    // Call the pack token contract with the retrieved random number.
    pack().fulfillRandomness(requestIds[requestId], randomness);

    emit RandomNumberExternal(randomness);
  }

  /// @dev Returns the fee amount and token to pay fees in.
  function getRequestFee() external view returns(address feeToken, uint feeAmount) {
    return (address(LINK), fees);
  }

  /// @dev Changes the `fees` required by Chainlink VRF.
  function setFees(uint _fees) external onlyProtocolAdmin {    
    fees = _fees;
  }

  /// @notice Lets a pack owner decide whether to use Chainlink VRF to open packs.
  function useExternalService(uint _packId, bool _use) external {
    require(pack().creator(_packId) == msg.sender, "RNG: Only the pack creator can change the use of the RNG.");

    uint totalSupply = pack().totalSupply(_packId);

    if(_use) {
      require(
        LINK.allowance(msg.sender, address(this)) >= fees * totalSupply,
        "RNG: not allowed to transfer the expected fee amount."
      );
      require(
        LINK.transferFrom(msg.sender, address(this), fees * totalSupply),
        "RNG: Failed to transfer the fee amount to RNG."
      );
    }

    usingExternalService[_packId] = _use;
  }

  /**
   *  DEX RNG functions.
  **/

  /// @dev Returns a random number within the given range.s
  function getRandomNumber(uint range) public override onlyPack returns (uint randomNumber, bool acceptableEntropy) {
    super.getRandomNumber(range);
  }

  /// @dev Add a UniswapV2/Sushiswap pair to draw randomness from.
  function addPair(address _pair) public override onlyProtocolAdmin {
    super.addPair(_pair);
  }

  /// @dev Sets whether a UniswapV2 pair is actively used as a source of randomness.
  function changePairStatus(address _pair, bool _activeStatus) public override onlyProtocolAdmin {
    super.changePairStatus(_pair, _activeStatus);
  }

  /**
   *  View functions
  **/

  /// @dev Returns pack protocol's `Pack`
  function pack() internal view returns (IRNGReceiver) {
    return IRNGReceiver(controlCenter.getModule(PACK));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/LinkTokenInterface.sol";

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
   * @param _seed seed mixed into the input of the VRF.
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee,
    uint256 _seed
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract DexRNG {

  /// @dev Number of pairs added.
  uint public currentPairIndex;
  /// @dev Updates on every RNG request.
  uint internal seed;

  /// @dev Uniswap v2 / Sushiswap pairs.
  struct PairAddresses {
    address tokenA;
    address tokenB;
    address pair;

    uint lastUpdateTimeStamp;
  }

  /// @dev Pair index => Pair info.
  mapping(uint => PairAddresses) public pairs;

  /// @dev Pair address => pair index.
  mapping(address => uint) public pairIndex;

  /// @dev Pair address => whether the pair is used by the RNG.
  mapping(address => bool) public active;

  /// @dev Block number => whether at least one pair updated in that block.
  mapping(uint => bool) public blockEntropy;
  
  /// @dev Events.
  event RandomNumber(address indexed requester, uint randomNumber);
  event PairAdded(address pair, address tokenA, address tokenB);
  event PairStatusUpdated(address pair, bool active);

  /**
   *  External functions
  **/

  /// @dev Add a UniswapV2/Sushiswap pair to draw randomness from.
  function addPair(address _pair) public virtual {
    require(IUniswapV2Pair(_pair).MINIMUM_LIQUIDITY() == 1000, "DEX RNG:Invalid pair address provided.");
    require(pairIndex[_pair] == 0, "DEX RNG: This pair already exists as a randomness source.");
    
    // Update pair index.
    currentPairIndex += 1;

    // Store pair.
    pairs[currentPairIndex] = PairAddresses({
      tokenA: IUniswapV2Pair(_pair).token0(),
      tokenB: IUniswapV2Pair(_pair).token1(),
      pair: _pair,
      lastUpdateTimeStamp: 0
    });

    pairIndex[_pair] = currentPairIndex;
    active[_pair] = true;

    emit PairAdded(_pair, pairs[currentPairIndex].tokenA, pairs[currentPairIndex].tokenB);
  }

  /// @dev Sets whether a UniswapV2 pair is actively used as a source of randomness.
  function changePairStatus(address _pair, bool _activeStatus) public virtual {
    require(pairIndex[_pair] != 0, "DEX RNG: Cannot change the status of a pair that does not exist.");

    active[_pair] = _activeStatus;
    
    emit PairStatusUpdated(_pair, _activeStatus);
  }

  /// @dev Returns a random number within the given range.s
  function getRandomNumber(uint range) public virtual returns (uint randomNumber, bool acceptableEntropy) {
    require(currentPairIndex > 0, "DEX RNG: No Uniswap pairs available to draw randomness from.");

    // Check whether pairs have already updated in this block.
    acceptableEntropy = blockEntropy[block.number];
    
    uint blockSignature = uint(keccak256(abi.encodePacked(tx.origin, seed, uint(blockhash(block.number - 1)))));

    for(uint i = 1; i <= currentPairIndex; i++) {

      if(!active[pairs[i].pair]) {
        continue;
      }

      (uint reserveA, uint reserveB, uint lastUpdateTimeStamp) = getReserves(pairs[i].pair, pairs[i].tokenA, pairs[i].tokenB);
      
      uint randomMod = seed == 0 ? (reserveA + reserveB) % range : (reserveA + reserveB) % (seed % range);
      blockSignature += randomMod;

      if(lastUpdateTimeStamp > pairs[i].lastUpdateTimeStamp) {

        if(!acceptableEntropy) {
          acceptableEntropy = true;
          blockEntropy[block.number] = true;
        }

        pairs[i].lastUpdateTimeStamp = lastUpdateTimeStamp;
      }
    }

    randomNumber = blockSignature % range;
    seed = uint(keccak256(abi.encodePacked(tx.origin, randomNumber)));
    
    emit RandomNumber(tx.origin, randomNumber);
  }

  /**
   *  Internal functions
  **/

  /// @notice See `UniswapV2Library.sol`
  function getReserves(
    address pair, 
    address tokenA, 
    address tokenB
  ) internal view returns (uint reserveA, uint reserveB, uint lastUpdateTimeStamp) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1, uint blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
    (reserveA, reserveB, lastUpdateTimeStamp) = tokenA == token0 ? (reserve0, reserve1, blockTimestampLast) : (reserve1, reserve0, blockTimestampLast);
  }

  /// @notice See `UniswapV2Library.sol`
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "DEX RNG: UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "DEX RNG: UniswapV2Library: ZERO_ADDRESS");
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface IProtocolControl {
  /// @dev Returns whether the pack protocol is paused.
  function systemPaused() external view returns (bool);
  
  /// @dev Returns the address of the pack protocol treasury.
  function treasury() external view returns(address treasuryAddress);

  /// @dev Returns the address of pack protocol's module.
  function getModule(string memory _moduleName) external view returns (address);

  /// @dev Returns true if account has been granted role.
  function hasRole(bytes32 role, address account) external returns (bool);

  /// @dev Returns true if account has been granted role.
  function PROTOCOL_ADMIN() external view returns (bytes32);
}

interface IListingAsset {
  function creator(uint _tokenId) external view returns (address _creator);
}

interface IRNG {
  /// @dev Returns whether the RNG is using an external service for randomness.
  function usingExternalService(uint _packId) external view returns (bool);

  /**
   * @dev Sends a request for random number to an external.
   *      Returns the unique request Id of the request, and the block number of the request.
  **/ 
  function requestRandomNumber() external returns (uint requestId, uint lockBlock);

  /// @notice Gets the Fee for making a Request against an RNG service
  function getRequestFee() external view returns (address feeToken, uint requestFee);

  /// @notice Returns a random number and whether the random number was generated with enough entropy.
  function getRandomNumber(uint range) external returns (uint randomNumber, bool acceptableEntropy);
}

/// @dev Interface for pack protocol's `Pack.sol` as a random number receiver.
interface IRNGReceiver {
  function fulfillRandomness(uint requestId, uint randomness) external;
  
  function creator(uint _packId) external view returns (address _creator);
  
  function totalSupply(uint _packId) external view returns (uint totalSupplyOfToken);
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

