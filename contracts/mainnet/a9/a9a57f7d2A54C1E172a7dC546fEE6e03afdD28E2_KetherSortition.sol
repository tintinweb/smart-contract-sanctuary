//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

interface IKetherHomepage {
  function ads(uint _idx) external view returns (address,uint,uint,uint,uint,string memory,string memory,string memory,bool,bool);
  function getAdsLength() view external returns (uint);
}

interface IERC721 {
  function ownerOf(uint256) external view returns (address);
  function balanceOf(address) external view returns (uint256);
  function tokenOfOwnerByIndex(address, uint256) external view returns (uint256);
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

library Errors {
  string constant MustOwnToken = "must own token";
  string constant OnlyMagistrate = "only active magistrate can do this";
  string constant MustHaveEntropy = "waiting for entropy";
  string constant MustHaveNominations = "must have nominations";
  string constant AlreadyStarted = "election already started";
  string constant NotExecuted = "election not executed";
  string constant TermNotExpired = "term not expired";
  string constant NotEnoughLink = "not enough LINK";
  string constant NotNominated = "token is not nominated";
}

contract KetherSortition is Ownable, VRFConsumerBase {
  event Nominated(
      uint256 indexed termNumber,
      address nominator,
      uint256 pixels
  );

  event ElectionExecuting(
    uint256 indexed termNumber
  );

  event ElectionCompleted(
    uint256 indexed termNumber,
    uint256 magistrateToken,
    address currentTokenOwner
  );

  event StepDown(
    uint256 indexed termNumber,
    uint256 magistrateToken,
    address currentTokenOwner
  );

  event ReceivedPayment(
    uint256 indexed termNumber,
    uint256 value
  );

  struct Nomination{
    uint256 termNumber;
    uint256 nominatedToken;
  }
  uint256 constant PIXELS_PER_CELL = 100;

  /// @notice tokenId of an NFT whose owner controls the royalties purse for this term.
  uint256 public magistrateToken;
  /// @notice length of magistrate term
  uint256 public termDuration;
  /// @notice minimum time period for new nominations (e.g. if a magistrate steps down)
  uint256 public minElectionDuration;
  /// @notice timestamp of start of current term
  uint256 public termStarted;
  /// @notice timestamp of end of current term
  uint256 public termExpires;
  /// @notice current term
  uint256 public termNumber = 0;

  IERC721 ketherNFTContract;
  IKetherHomepage ketherContract;

  /// @dev tokenIDs nominated in the current term
  uint256[] public nominatedTokens;
  /// @dev count of pixels nominated in the current term
  uint256 public nominatedPixels = 0;
  mapping(uint256 => Nomination) nominations; // mapping of tokenId => {termNumber, nominatedToken}

  /// @dev provided by Chainlink
  uint256 public electionEntropy;

  // nominating -[term expired & startElection() calls]> waitingForEntropy -[Chainlink calls into fulfillrandomness()]> gotEntropy -[completeElection()] -> nominating
  enum StateMachine { NOMINATING, WAITING_FOR_ENTROPY, GOT_ENTROPY }
  StateMachine public state = StateMachine.NOMINATING;

  // Chainlink values
  bytes32 private s_keyHash;
  uint256 private s_fee;

  constructor(address _ketherNFTContract, address _ketherContract, address vrfCoordinator, address link, bytes32 keyHash, uint256 fee, uint256 _termDuration, uint256 _minElectionDuration ) VRFConsumerBase(vrfCoordinator, link) {
    s_keyHash = keyHash;
    s_fee = fee;

    ketherNFTContract = IERC721(_ketherNFTContract);
    ketherContract = IKetherHomepage(_ketherContract);

    termDuration = _termDuration;
    minElectionDuration = _minElectionDuration;
    termExpires = block.timestamp + _termDuration;
  }

  receive() external payable {
    emit ReceivedPayment(termNumber, msg.value);
  }

  // Internal helpers:

  /**
   * @notice Only callable by Chainlink VRF, async triggered via startElection().
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    require(state == StateMachine.WAITING_FOR_ENTROPY, Errors.NotExecuted);
    electionEntropy = randomness;
    state = StateMachine.GOT_ENTROPY;
  }

  /// @dev _nominate does not check token ownership, must already be checked.
  /// @param _ownedTokenId Token to nominate from
  /// @param _nominateTokenId Token to nominate to.
  function _nominate(uint256 _ownedTokenId, uint256 _nominateTokenId) internal returns (uint256 pixels) {
    // Only push the ad and update pixel count if it's not been nominated before
    if (!isNominated(_ownedTokenId)) {
      pixels += getAdPixels(_ownedTokenId);
      nominatedTokens.push(_ownedTokenId);
    }

    nominations[_ownedTokenId] = Nomination(termNumber + 1, _nominateTokenId);

    return pixels;
  }

  /// @dev _nominate does not check token ownership, must already be checked.
  /// @param _nominateSelf if true each token nominates itself
  /// @param _nominateTokenId if nominateSelf is false, token to nominate to. Must be a NFT-wrapped token
  function _nominateAll(bool _nominateSelf, uint256 _nominateTokenId) internal returns (uint256) {
    require(state == StateMachine.NOMINATING, Errors.AlreadyStarted);
    address sender = _msgSender();
    require(ketherNFTContract.balanceOf(sender) > 0, Errors.MustOwnToken);
    // This checks that the _nominateTokenId is minted, will revert otherwise
    require(_nominateSelf || ketherNFTContract.ownerOf(_nominateTokenId) != address(0));


    uint256 pixels = 0;
    for (uint256 i = 0; i < ketherNFTContract.balanceOf(sender); i++) {
      uint256 idx = ketherNFTContract.tokenOfOwnerByIndex(sender, i);
      if (_nominateSelf) {
        pixels += _nominate(idx, idx);
      } else {
        pixels += _nominate(idx, _nominateTokenId);
      }
    }

    nominatedPixels += pixels;

    // Note this is emitted in the helper while `nominate` emits the event in the public function
    emit Nominated(termNumber+1, sender, pixels);
    return pixels;
  }


  // Views:

  function getMagistrate() public view returns (address) {
    return getAdOwner(magistrateToken);
  }

  function getAdOwner(uint256 _idx) public view returns (address) {
    return ketherNFTContract.ownerOf(_idx);
  }

  function getAdPixels(uint256 _idx) public view returns (uint256) {
    (,,,uint width,uint height,,,,,) = ketherContract.ads(_idx);
    return width * height * PIXELS_PER_CELL;
  }

  function isNominated(uint256 _idx) public view returns (bool) {
    return nominations[_idx].termNumber > termNumber;
  }

  function getNominatedToken(uint256 _idx) public view returns (uint256) {
    require(isNominated(_idx), Errors.NotNominated);

    return nominations[_idx].nominatedToken;
  }

  function getNextMagistrateToken() public view returns (uint256) {
    require(state == StateMachine.GOT_ENTROPY, Errors.MustHaveEntropy);
    require(nominatedTokens.length > 0, Errors.MustHaveNominations);

    uint256 pixelChosen = electionEntropy % nominatedPixels;
    uint256 curPixel = 0;

    for(uint256 i = 0; i < nominatedTokens.length; i++) {
      uint256 idx = nominatedTokens[i];
      curPixel += getAdPixels(idx);
      if (curPixel > pixelChosen) {
        return getNominatedToken(idx);
      }
    }
    return 0;
  }

  // External interface:

  /**
   * @notice Nominate tokens held by the sender as candidates for magistrate in the next term.
   *      Nominations of tokens are independent of their owner.
   * @param _ownedTokenId Token to nominate from
   * @param _nominateTokenId tokenId to count nominations towards. Must be an NFT-wrapped token.
   * @return Number of nominated pixels.
   *
   * Emits {Nominated} event.
   */
  function nominate(uint256 _ownedTokenId, uint256 _nominateTokenId) external returns (uint256) {
    require(state == StateMachine.NOMINATING, Errors.AlreadyStarted);
    address sender = _msgSender();
    require(ketherNFTContract.ownerOf(_ownedTokenId) == sender, Errors.MustOwnToken);
    // This checks that the _nominateTokenId is minted, will revert otherwise
    require(ketherNFTContract.ownerOf(_nominateTokenId) != address(0));
    uint256 pixels = _nominate(_ownedTokenId, _nominateTokenId);

    // Note this is emitted in the public function while `_nominateAll` emits the event in the helper
    emit Nominated(termNumber+1, sender, pixels);

    return pixels;
  }

  /**
   * @notice Nominate tokens held by the sender as candidates towards a specific `_nominateTokenId` as magistrate in the next term
   * @param _nominateTokenId tokenId to count nominations towards. Must be an NFT-wrapped token.
   * @return Number of nominated pixels.
   *
   * Emits {Nominated} event.
   */
  function nominateAll(uint256 _nominateTokenId) public returns (uint256) {
    return _nominateAll(false, _nominateTokenId);
  }

  /**
   * @notice Nominate tokens held by the sender as candidates towards a specific `_nominateTokenId` as magistrate in the next term
   * @return Number of nominated pixels.
   *
   * Emits {Nominated} event.
   */
  function nominateSelf() public returns (uint256) {
    return _nominateAll(true, 0);
  }

  /**
   * @notice Stop accepting nominations, start election.
   *
   * Emits {ElectionExecuting} event.
   */
  function startElection() external {
    require(state == StateMachine.NOMINATING, Errors.AlreadyStarted);
    require(nominatedTokens.length > 0, Errors.MustHaveNominations);
    require(termExpires <= block.timestamp, Errors.TermNotExpired);
    require(LINK.balanceOf(address(this)) >= s_fee, Errors.NotEnoughLink);

    state = StateMachine.WAITING_FOR_ENTROPY;
    requestRandomness(s_keyHash, s_fee);

    emit ElectionExecuting(termNumber);
  }

  /**
   * @notice Assign new magistrate and open up for nominations for next election.
   *
   * Emits {ElectionCompleted} event.
   */
  function completeElection() external {
    require(state == StateMachine.GOT_ENTROPY, Errors.MustHaveEntropy);
    magistrateToken = getNextMagistrateToken();

    termNumber += 1;
    termStarted = block.timestamp;
    termExpires = termStarted + termDuration;

    delete nominatedTokens;
    nominatedPixels = 0;
    state = StateMachine.NOMINATING;

    emit ElectionCompleted(termNumber, magistrateToken, getMagistrate());
  }


  // Only magistrate:

  /// @notice Transfer balance controlled by magistrate.
  /// @notice Magistrate has exclusive rights to withdraw until the end of term.
  /// @notice Remaining balance after the next election is rolled over to the next magistrate.
  function withdraw(address payable to) public {
    require(_msgSender() == getMagistrate(), Errors.OnlyMagistrate);
    // TODO: Someday, would it be fun if this required having a >2 LINK balance to
    // withdraw? If we wanna be super cute, could automagically buy LINK from
    // the proceeds before transferring the remaining balance.

    to.transfer(address(this).balance);
  }

  /// @notice Cut the term short, leaving enough time for new nominations.
  /// Emits {StepDown} event.
  function stepDown() public {
    require(_msgSender() == getMagistrate(), Errors.OnlyMagistrate);

    uint256 timeRemaining = termExpires - block.timestamp;
    if (timeRemaining > minElectionDuration) {
      termExpires = block.timestamp + minElectionDuration;
    }

    emit StepDown(termNumber, magistrateToken, _msgSender());
  }

  // Only owner (admin helpers):

  /**
   * @notice Withdraw ERC20 tokens, primarily for rescuing remaining LINK once the experiment is over.
   */
  function adminWithdrawToken(IERC20 token, address to) external onlyOwner {
    token.transfer(to, token.balanceOf(address(this)));
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