// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

import "./CryptoPunksInterface.sol";
import "./GachaSetting.sol";
import "./GachaState.sol";

contract PunkGacha is GachaSetting, GachaState, KeeperCompatibleInterface, VRFConsumerBase {
  CryptoPunksInterface private _cryptopunks;
  uint16 private _cryptopunksTotalSupply = 10000;

  uint256 private _withdrawableBalance;
  uint256 private _randomness;

  enum RoundStatus {
    OPEN,
    DRAW,
    CLOSE
  }

  struct Round {
    uint256 minValue;
    uint200 id;
    uint16 punkIndex;
    RoundStatus status;
  }

  Round public currentRound;

  event RoundClose(uint200 indexed roundId, address indexed winner, uint16 punkIndex);
  event PlayerBet(uint200 indexed roundId, address indexed player, uint96 amount);
  event PlayerRefund(uint200 indexed roundId, address indexed player, uint96 amount);

  constructor(
    address vrfCoordinator, // Chainlink VRF Coordinator address
    address link, // LINK token address
    bytes32 keyHash, // Public key against which randomness is generated
    uint256 fee, // Fee required to fulfill a VRF request, in wei
    address cryptopunks // CryptoPunks contract address
  ) VRFConsumerBase(vrfCoordinator, link) {
    setKeyHash(keyHash);
    setFee(fee);
    _cryptopunks = CryptoPunksInterface(cryptopunks);
    currentRound.status = RoundStatus.CLOSE;
  }

  function bet() external payable {
    require(currentRound.status == RoundStatus.OPEN, "round not open");
    require(msg.value >= minimumBetValue, "bet too less");
    require(msg.value < (1 << 96), "bet too much");

    emit PlayerBet(currentRound.id, msg.sender, uint96(msg.value));
    _stake(Chip(msg.sender, uint96(msg.value)));
  }

  function refund(uint256[] calldata chipIndexes) external {
    require(currentRound.status != RoundStatus.DRAW, "round is drawing");

    address payable sender = payable(msg.sender);
    uint256 refundAmount = _refund(msg.sender, chipIndexes);
    require(refundAmount > 0, "nothing to refund");
    sender.transfer(refundAmount);
    emit PlayerRefund(currentRound.id, msg.sender, uint96(refundAmount));
  }

  function checkUpkeep(bytes calldata checkData)
    external
    view
    override
    returns (bool upkeepNeeded, bytes memory performData)
  {
    if (currentRound.status == RoundStatus.OPEN) {
      if (_checkMaintainSegment(0)) {
        return (true, checkData);
      }
      (bool isForSale, , , uint256 minValue, address onlySellTo) = _cryptopunks.punksOfferedForSale(
        currentRound.punkIndex
      );
      if (
        minValue > currentRound.minValue ||
        !isForSale ||
        (onlySellTo != address(0) && onlySellTo != address(this))
      ) {
        return (true, checkData);
      }
      if (
        totalAmount >= (currentRound.minValue * (1000 + serviceFeeThousandth)) / 1000 &&
        LINK.balanceOf(address(this)) >= _fee
      ) {
        return (true, checkData);
      }
      return (false, checkData);
    }
    if (currentRound.status == RoundStatus.DRAW) {
      return (_randomness != 0, checkData);
    }
    return (false, checkData);
  }

  // NOTE: can be called by anyone
  function performUpkeep(bytes calldata) external override {
    if (currentRound.status == RoundStatus.OPEN) {
      if (_checkMaintainSegment(0)) {
        _performMaintainSegment();
        return;
      }
      (bool isForSale, , , uint256 minValue, address onlySellTo) = _cryptopunks.punksOfferedForSale(
        currentRound.punkIndex
      );
      if (
        minValue > currentRound.minValue ||
        !isForSale ||
        (onlySellTo != address(0) && onlySellTo != address(this))
      ) {
        emit RoundClose(currentRound.id, address(0), currentRound.punkIndex);
        currentRound.status = RoundStatus.CLOSE;
        return;
      }
      if (
        totalAmount >= (currentRound.minValue * (1000 + serviceFeeThousandth)) / 1000 &&
        LINK.balanceOf(address(this)) >= _fee
      ) {
        _cryptopunks.buyPunk{value: minValue}(currentRound.punkIndex);
        _withdrawableBalance += totalAmount - minValue;
        requestRandomness(_keyHash, _fee);
        currentRound.status = RoundStatus.DRAW;
        return;
      }
      revert("not enough LINK or ETH");
    }
    if (currentRound.status == RoundStatus.DRAW) {
      require(_randomness != 0, "randomness not fulfilled");
      address winner = _pick(_randomness);
      delete _randomness;
      require(winner != address(0), "cannot pick winner");
      _cryptopunks.offerPunkForSaleToAddress(currentRound.punkIndex, 0, winner);
      emit RoundClose(currentRound.id, winner, currentRound.punkIndex);
      currentRound.status = RoundStatus.CLOSE;
      _reset();
      return;
    }
    revert("unknown status");
  }

  // NOTE: max 200,000 gas
  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    require(currentRound.status == RoundStatus.DRAW, "round not drawing");
    _randomness = randomness;
  }

  function nextRound(uint256 _punkIndex) external {
    require(!isPaused, "is paused");
    require(currentRound.status == RoundStatus.CLOSE, "round not close");
    require(_punkIndex < _cryptopunksTotalSupply, "invalid punk index");
    require(
      msg.sender == owner() || msg.sender == _cryptopunks.punkIndexToAddress(_punkIndex),
      "no permission"
    );
    (bool isForSale, , , uint256 minValue, address onlySellTo) = _cryptopunks.punksOfferedForSale(
      _punkIndex
    );
    require(
      isForSale && (onlySellTo == address(0) || onlySellTo == address(this)),
      "punk not for sale"
    );
    require(minValue <= maximumPunkValue, "punk too expensive");

    currentRound = Round(minValue, currentRound.id + 1, uint16(_punkIndex), RoundStatus.OPEN);
  }

  function withdrawLink() external onlyOwner {
    require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "unable to withdraw LINK");
  }

  function withdraw() external onlyOwner {
    require(currentRound.status == RoundStatus.CLOSE, "round not close");
    address payable _owner = payable(owner());
    _owner.transfer(_withdrawableBalance);
  }

  function destory() external onlyOwner {
    selfdestruct(payable(owner()));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

abstract contract CryptoPunksInterface {
  uint256 public totalSupply;

  struct Offer {
    bool isForSale;
    uint256 punkIndex;
    address seller;
    uint256 minValue; // in ether
    address onlySellTo; // specify to sell only to a specific person
  }

  // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
  mapping(uint256 => Offer) public punksOfferedForSale;

  mapping(uint256 => address) public punkIndexToAddress;

  function offerPunkForSaleToAddress(
    uint256 punkIndex,
    uint256 minSalePriceInWei,
    address toAddress
  ) external virtual;

  function buyPunk(uint256 punkIndex) external payable virtual;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GachaSetting is Ownable {
  uint256 public serviceFeeThousandth = 100; // 10%

  uint256 public minimumBetValue = 0.01 ether;

  uint256 public maximumPunkValue = 200 ether;

  bool public isPaused = false;

  bytes32 internal _keyHash;

  uint256 internal _fee;

  function setServiceFeeThousandth(uint256 _serviceFeeThousandth) public onlyOwner {
    serviceFeeThousandth = _serviceFeeThousandth;
  }

  function setMinimumBetValue(uint256 _minimumBetValue) public onlyOwner {
    minimumBetValue = _minimumBetValue;
  }

  function setMaximumPunkValue(uint256 _maximumPunkValue) public onlyOwner {
    maximumPunkValue = _maximumPunkValue;
  }

  function setIsPaused(bool _isPaused) public onlyOwner {
    isPaused = _isPaused;
  }

  function setKeyHash(bytes32 keyHash) public onlyOwner {
    _keyHash = keyHash;
  }

  function setFee(uint256 fee) public onlyOwner {
    _fee = fee;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

/**
 * example:
 * 256 chips:   0 .. 99 , 100 .. 199 , 200 .. 255
 * 2 segments: |   0    |      1     |
 */
contract GachaState {
  mapping(uint256 => uint256) public segments;
  uint256 public segmentsCount;
  uint256 private _perSegmentSize = 100;
  uint256 private _playerMaintainSegmentOffset = 10;

  struct Chip {
    address player;
    uint96 amount;
  }
  mapping(uint256 => Chip) public chips;
  uint256 public chipsCount;

  uint256 public totalAmount;
  uint256 private _previousAmount;

  /**
   * stake ether without check amount
   */
  function _stake(Chip memory chip) internal {
    if (_checkMaintainSegment(_playerMaintainSegmentOffset)) {
      _performMaintainSegment();
    }

    chips[chipsCount] = chip;
    chipsCount += 1;
    totalAmount += chip.amount;
  }

  /**
   * refund all staked ether without check
   */
  function _refund(address sender, uint256[] calldata chipIndexes) internal returns (uint256) {
    uint128 currentRefundAmount;
    uint128 previousRefundAmount;

    for (uint256 i = 0; i < chipIndexes.length; i++) {
      uint256 chipIndex = chipIndexes[i];
      if (chips[chipIndex].player == sender) {
        currentRefundAmount += chips[chipIndex].amount;
        uint256 segmentIndex = chipIndex / _perSegmentSize;
        if (segmentIndex < segmentsCount) {
          segments[segmentIndex] -= chips[chipIndex].amount;
          previousRefundAmount += chips[chipIndex].amount;
        }
        delete chips[chipIndex];
      }
    }

    totalAmount -= currentRefundAmount;
    _previousAmount -= previousRefundAmount;
    return currentRefundAmount;
  }

  /**
   * pick a player to win punk
   */
  function _pick(uint256 randomness) internal view returns (address) {
    uint256 counter = 0;
    uint256 threshold = randomness % totalAmount;

    uint256 i = 0;
    for (; i < segmentsCount; i++) {
      if (counter + segments[i] > threshold) {
        break;
      }
      counter += segments[i];
    }
    for (uint256 j = i * _perSegmentSize; j < (i + 1) * _perSegmentSize; j++) {
      if (counter + chips[j].amount > threshold) {
        return chips[j].player;
      }
      counter += chips[j].amount;
    }

    return address(0);
  }

  /**
   * reset all states
   */
  function _reset() internal {
    delete chipsCount;
    delete segmentsCount;
    delete _previousAmount;
    delete totalAmount;
  }

  function _checkMaintainSegment(uint256 offset) internal view returns (bool) {
    return chipsCount > offset && ((chipsCount - offset) / _perSegmentSize > segmentsCount);
  }

  function _performMaintainSegment() internal {
    uint256 overflow;
    for (uint256 i = (chipsCount / _perSegmentSize) * _perSegmentSize; i < chipsCount; i++) {
      overflow += chips[i].amount;
    }
    segments[segmentsCount] = totalAmount - _previousAmount - overflow;
    segmentsCount += 1;
    _previousAmount = totalAmount;
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/CryptoPunksInterface.sol";

abstract contract XCryptoPunksInterface is CryptoPunksInterface {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/GachaSetting.sol";

contract XGachaSetting is GachaSetting {
    constructor() {}

    function x_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function x_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function x_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/GachaState.sol";

contract XGachaState is GachaState {
    constructor() {}

    function x_stake(GachaState.Chip calldata chip) external {
        return super._stake(chip);
    }

    function x_refund(address sender,uint256[] calldata chipIndexes) external returns (uint256) {
        return super._refund(sender,chipIndexes);
    }

    function x_pick(uint256 randomness) external view returns (address) {
        return super._pick(randomness);
    }

    function x_reset() external {
        return super._reset();
    }

    function x_checkMaintainSegment(uint256 offset) external view returns (bool) {
        return super._checkMaintainSegment(offset);
    }

    function x_performMaintainSegment() external {
        return super._performMaintainSegment();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/PunkGacha.sol";

contract XPunkGacha is PunkGacha {
    constructor(address vrfCoordinator, address link, bytes32 keyHash, uint256 fee, address cryptopunks) PunkGacha(vrfCoordinator, link, keyHash, fee, cryptopunks) {}

    function xfulfillRandomness(bytes32 arg0,uint256 randomness) external {
        return super.fulfillRandomness(arg0,randomness);
    }

    function xrequestRandomness(bytes32 _keyHash,uint256 _fee) external returns (bytes32) {
        return super.requestRandomness(_keyHash,_fee);
    }

    function xmakeVRFInputSeed(bytes32 _keyHash,uint256 _userSeed,address _requester,uint256 _nonce) external pure returns (uint256) {
        return super.makeVRFInputSeed(_keyHash,_userSeed,_requester,_nonce);
    }

    function xmakeRequestId(bytes32 _keyHash,uint256 _vRFInputSeed) external pure returns (bytes32) {
        return super.makeRequestId(_keyHash,_vRFInputSeed);
    }

    function x_stake(GachaState.Chip calldata chip) external {
        return super._stake(chip);
    }

    function x_refund(address sender,uint256[] calldata chipIndexes) external returns (uint256) {
        return super._refund(sender,chipIndexes);
    }

    function x_pick(uint256 randomness) external view returns (address) {
        return super._pick(randomness);
    }

    function x_reset() external {
        return super._reset();
    }

    function x_checkMaintainSegment(uint256 offset) external view returns (bool) {
        return super._checkMaintainSegment(offset);
    }

    function x_performMaintainSegment() external {
        return super._performMaintainSegment();
    }

    function x_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function x_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function x_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}