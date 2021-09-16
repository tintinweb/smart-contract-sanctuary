/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/tunnel/FxBaseChildTunnel.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

/**
* @notice Mock child tunnel contract to receive and send message from L2
*/
abstract contract FxBaseChildTunnel is IFxMessageProcessor{
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) virtual internal;
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// SPD
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// SPD
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// SPD
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


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]

// SPD
/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
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
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

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


// File @chainlink/contracts/src/v0.8/[email protected]

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


// File @chainlink/contracts/src/v0.8/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

// SPD
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


// File @openzeppelin/contracts/access/[email protected]

// SPD
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


// File contracts/interfaces/IEgg.sol

struct EggInfo {
    uint Maturity;
    uint Bonus; //set at minting, based on parents rarity, and on if parents were from original 8181 number between 0 -> 10000
    uint EventID;
    bool Hatched; //maybe just burn them when they are hatched? So this in not needed?
}

struct Trait {
    string traitName;
    uint rarity;
}

interface IEgg {
    function setCrowMetaData(uint _tokenID, uint32[8] memory _metaData) external;
    function setCrowRNG(uint _tokenID, uint _rng) external;
    function setCrowParents(uint _tokenID, uint[2] memory _parents) external;
    function setEggBonus(uint _tokenID, uint _bonus) external;
    function traitInfo(uint8 _traitID, uint32 _traitIndex) external view returns(Trait memory);
    //function crowMetaData(uint _tokenID) external view returns(uint32[8] memory);
    function getCrowMetaData(uint _tokenID) external view returns(uint32[8] memory);
    function crowRNG(uint _tokenID) external view returns(uint);
    function eventTraitStartingIndex(uint _eventID, uint8 _traitID) external view returns(uint32);
    //function parents(uint _tokenID) external view returns(uint[2] memory);
    function getParents(uint _tokenID) external view returns(uint[2] memory);
    function eggInfo(uint _eggID) external view returns(EggInfo memory);
    function eventTraitSum() external view returns(uint);
    function getRarity(uint8 traitID, uint32 traitIndex) external view returns(uint);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function burnEgg(uint _eggID) external;
    function mintEgg(uint _eggID) external;
    function ownerOf(uint _eggID) external returns(address);
    function hatch(uint _eggID) external;
}


// File contracts/EggCarton.sol








//TODO in breeder, function to mint owner a crow so we can make promotional crows
contract EggCarton is FxBaseChildTunnel, VRFConsumerBase, Ownable, ERC721Holder {
    bytes32 public constant MAKE_EGG = keccak256("MAKE_EGG");
    bytes32 public constant FIND_TRAITS = keccak256("FIND_TRAITS");
    bytes32 internal keyHash;
    uint256 internal fee;
    uint public maxMaturity = 10000;
    uint public minMaturity = 5000;//min required maturity to hatch an egg
    uint public maturityMultiplier = 20000;//if an egg is max maturity then this is the times bonus they get for rare traits 
    uint public bonusMultipler = 20000; //changes how fast an egg matures
    uint public baseMultiplier = 10000;//used as the base for multipliers
    uint public gen0Bonus = 500; //5% bonus
    uint public bonusDifficulty = 8;//makes it more difficult to be assigned a high bonus
    IEgg Egg;

    struct Message{
        address caller;
        uint mom;
        uint dad;
        bool done;
        bool rngSet;
    }
    mapping(uint => Message) public messages;

    mapping(uint => address) public eggsToDispense;

    mapping(bytes32 => uint) public requestIDtoTokenID;

    constructor(address _fxChild, address egg) FxBaseChildTunnel(_fxChild) VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        )
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 100000000000000; // 0.0001 LINK
        Egg = IEgg(egg);
    }

    function setParameters(uint _maxMaturity, uint _minMaturity, uint _maturityMultiplier, uint _bonusMultiplier, uint _baseMultiplier, uint _gen0Bonus, uint _bonusDifficulty) external onlyOwner{
        require(_maxMaturity/2 == _minMaturity, 'minMaturity must equal half of the maxMaturity');
        require(_maturityMultiplier/_baseMultiplier > 0, 'Incorrect Parameters');
        require(_bonusMultiplier/_baseMultiplier > 0, 'Incorrect Parameters');
        maxMaturity = _maxMaturity;
        minMaturity = _minMaturity;
        maturityMultiplier = _maturityMultiplier;
        bonusMultipler = _bonusMultiplier;
        baseMultiplier = _baseMultiplier;
        gen0Bonus = _gen0Bonus;
        bonusDifficulty = _bonusDifficulty;
    }

    function findRarest(uint _mom, uint _dad) public view returns(uint32[8] memory metaData){
        //run algo to find parents rarest traits
        uint8 momRarest = 0;
        uint8 mom2ndRarest = 0;
        uint8 dadRarest = 0;
        uint8 dad2ndRarest = 0;

        uint32[8] memory mom = Egg.getCrowMetaData(_mom);
        uint32[8] memory dad = Egg.getCrowMetaData(_dad); 
        
        //set the rarest and 2ndRarest for mom and dad
        if(Egg.getRarity(0, mom[0]) < Egg.getRarity(1, mom[1])){
            momRarest = 0;
            mom2ndRarest = 1;
        }
        else{
            momRarest = 1;
            mom2ndRarest = 0;
        }
        if(Egg.getRarity(0, dad[0]) < Egg.getRarity(1, dad[1])){
            dadRarest = 0;
            dad2ndRarest = 1;
        }
        else{
            dadRarest = 1;
            dad2ndRarest = 0;
        }
        
        for(uint8 i=2; i < 8; i++){
            //check to see if the current trait is rarer than the moms rarest trait
            if(Egg.getRarity(i, mom[i]) < Egg.getRarity(momRarest, mom[momRarest])){
                mom2ndRarest = momRarest;//set 2nd rarest equal to old rarest trait
                momRarest = i;//set new rarest trait
            }
            else{//check if the current traits is rarer than the second rarest and replace it if it is
                if(Egg.getRarity(i, mom[i]) < Egg.getRarity(mom2ndRarest, mom[mom2ndRarest])){
                    mom2ndRarest = i;
                }
            }
            //check to see if the current trait is rarer than the dads rarest trait
            if(Egg.getRarity(i, dad[i]) < Egg.getRarity(dadRarest, dad[dadRarest])){
                dad2ndRarest = dadRarest;//set 2nd rarest equal to old rarest trait
                dadRarest = i;//set new rarest trait
            }
            else{//check if the current traits is rarer than the second rarest and replace it if it is
                if(Egg.getRarity(i, dad[i]) < Egg.getRarity(dad2ndRarest, dad[dad2ndRarest])){
                    dad2ndRarest = i;
                }
            }
        }
    
        if(dadRarest == momRarest){//if the Trait IDs are the same
            //then use whichever rarer one is rarer, and use the other ones backup
            if(Egg.getRarity(dadRarest, dad[dadRarest]) < Egg.getRarity(momRarest, mom[momRarest])){
                metaData[dadRarest] = dad[dadRarest];//use the dads rarest
                if(dadRarest == mom2ndRarest){
                    metaData[dad2ndRarest] = dad[dad2ndRarest];//use dads second rarest
                }
                else{
                    metaData[mom2ndRarest] = mom[mom2ndRarest];//use the moms seconds rarest
                }
            }
            else{
                metaData[momRarest] = mom[momRarest];//use moms rarest
                if(momRarest == dad2ndRarest){
                    metaData[mom2ndRarest] = mom[mom2ndRarest];//use the moms seconds rarest
                }
                else{
                    metaData[dad2ndRarest] = dad[dad2ndRarest];//use dads second rarest
                }
            }
        }
        else{//use rarest from both parents
            metaData[dadRarest] = dad[dadRarest];//use the dads rarest
            metaData[momRarest] = mom[momRarest];//use moms rarest
        }
        
    }

    function setEggContract(address _egg) external onlyOwner{
        require(_egg != address(0), 'Cannot set zero address as egg');
        Egg = IEgg(_egg);
    }

    //validateSender checks to make sure the message was sent by the Breeder
    function _processMessageFromRoot(uint256 stateId, address sender, bytes memory message) override internal validateSender(sender){
        // decode incoming data
        (bytes32 syncType, bytes memory syncData) = abi.decode(message, (bytes32, bytes));

        if(syncType == MAKE_EGG){
            _makeEgg(syncData);
        }
        else if(syncType == FIND_TRAITS){
            _findTraits(syncData);
        }
        else {
            revert("FxERC721ChildTunnel: INVALID_SYNC_TYPE");
        }
    }

    function _makeEgg(bytes memory message) internal {
        (address caller, uint baby, uint mom, uint dad) = abi.decode(message, (address, uint, uint, uint));

        Egg.mintEgg(baby);
        eggsToDispense[baby] = caller;
        uint[2] memory parents;
        parents[0] = mom;
        parents[1] = dad;
        Egg.setCrowParents(baby, parents);
    }

    function sendEggToCaller(uint baby) external{
        require(eggsToDispense[baby] != address(0), 'Forbidden');
        uint[2] memory parents = Egg.getParents(baby);
        uint bonus = findEggBonus(parents[0], parents[1]);
        Egg.setEggBonus(baby, bonus);

        Egg.safeTransferFrom(address(this), eggsToDispense[baby],  baby);
        eggsToDispense[baby] = address(0);
    }

    function _findTraits(bytes memory message) internal {
        (address caller, uint tID, uint mom, uint dad) = abi.decode(message, (address, uint, uint, uint));
        messages[tID].caller = caller;
        messages[tID].mom = mom;
        messages[tID].dad = dad;

        requestIDtoTokenID[_getRandomNumber()] = tID;
    }

    function findEggBonus(uint _mom, uint _dad) public view returns(uint bonus){
        uint momSum = 0;
        uint dadSum = 0;
        uint32[8] memory mom = Egg.getCrowMetaData(_mom);
        uint32[8] memory dad = Egg.getCrowMetaData(_dad); 
        bonus = 0;
        for(uint8 i=0; i < 8; i++){
            momSum += Egg.getRarity(i, mom[i]);
            dadSum += Egg.getRarity(i, dad[i]);
        }
        uint avgRarity = (momSum + dadSum)/16;
        if(avgRarity <= (Egg.eventTraitSum()/bonusDifficulty)){
            bonus = (baseMultiplier * ((Egg.eventTraitSum()/bonusDifficulty) - avgRarity)) / (Egg.eventTraitSum()/bonusDifficulty);
        }
        else{
            bonus = 0;
        }

        //Apply gen 0 bonuses
        if(_mom < 8181){
            bonus += gen0Bonus;
        }
        if(_dad < 8181){
            bonus += gen0Bonus;
        }
        //cap it at baseMultiplier
        if(bonus > baseMultiplier){
            bonus = baseMultiplier;
        }
    }

    function findTraits(uint tokenID) external {
        require(messages[tokenID].rngSet, 'RNG not set');
        require(!messages[tokenID].done, 'Traits already calculated for tokenID');
        require(messages[tokenID].mom > 0 || messages[tokenID].dad > 0, 'Messages is not set');//should stop people from calling findTraits on a hatched egg
        uint mom = messages[tokenID].mom;
        uint dad = messages[tokenID].dad;

        uint32[8] memory metaData = findRarest(mom, dad);
        Egg.setCrowMetaData(tokenID, metaData);

        uint32[8] memory newCrow = calculateMadHouseTraits(tokenID, Egg.crowRNG(tokenID));
        Egg.setCrowMetaData(tokenID, newCrow);
        messages[tokenID].done = true;
    }

    function hatchEgg(uint eggID) external {
        //first make sure caller owns egg
        require(Egg.ownerOf(eggID) == msg.sender, 'Caller does not own egg');

        //make sure egg rarity multiplier is greater than 1
        require(Egg.eggInfo(eggID).Maturity >= minMaturity, 'Egg is not mature enough');

        //call Chainlink VRF
        requestIDtoTokenID[_getRandomNumber()] = eggID;

        Egg.hatch(eggID);//checks to see if egg is already hatched

    }

    function sendHatchedEggToMainnet(uint eggID) external {
        //make sure caller owns the egg
        require(Egg.ownerOf(eggID) == msg.sender, 'Caller does not own egg');
        //make sure egg was hatched
        require(Egg.eggInfo(eggID).Hatched, 'Egg is not hatched yet, call hatchEgg');
        //make sure chainlink has set the random number for this egg
        require(messages[eggID].rngSet, 'Random number is not set yet');

        uint32[8] memory newCrow = calculateEggBreedingTraits(eggID, Egg.crowRNG(eggID));
        Egg.setCrowMetaData(eggID, newCrow);
        //Send egg to the EggCarton
        Egg.safeTransferFrom(msg.sender, address(this), eggID);
        //burn the egg
        Egg.burnEgg(eggID);

        //send message to root
        _sendMessageToRoot(abi.encode(msg.sender, eggID));        
    }

    //This should emit an event that we can watch for so we can create the image and meta data
    function calculateMadHouseTraits(uint tokenID, uint randomNumber) public view returns(uint32[8] memory newCrow){
        //uses the eggs rarity multiplier, and random seed to calculate the traits
        //if crowMetaData[tokenID][0-7] != 0 then don't touch it because the trait is already set
        uint256[] memory expandedRandomness = expand(randomNumber, 8);
        uint sum;
        //Set the initial traits
        newCrow = Egg.getCrowMetaData(tokenID);
        for (uint8 i=0; i<8; i++){
            if(newCrow[i] == 0){//means this trait is not set
                sum = 0;
                uint rng = expandedRandomness[i] % Egg.eventTraitSum();
                for(uint32 j=Egg.eventTraitStartingIndex(0, i); j<Egg.eventTraitStartingIndex(1, i); j++){
                    sum += uint256(Egg.getRarity(i, j));
                    if(rng <= sum){
                        newCrow[i] = j;
                        break;
                    }
                }
            }
        }
    }

    function calculateEggBreedingTraits(uint tokenID, uint randomNumber) public view returns(uint32[8] memory newCrow){
        //uses the eggs rarity multiplier, and random seed to calculate the traits
        
        uint maturity = Egg.eggInfo(tokenID).Maturity;
        if(maturity > maxMaturity){
            maturity = maxMaturity;
        }
        uint amountToDiminishBy;

        
        uint256[] memory expandedRandomness = expand(randomNumber, 16);
        uint sum;
        uint startingMaturity = maturity;
        //Set the initial traits
        newCrow = Egg.getCrowMetaData(tokenID);
        for (uint8 i=0; i<8; i++){
            if(newCrow[i] == 0){//means this trait is not set
                maturity = startingMaturity;
                amountToDiminishBy = (maturity - minMaturity) / (Egg.eventTraitStartingIndex(1, i) - Egg.eventTraitStartingIndex(0, i));
                sum = 0;
                uint rng = expandedRandomness[i] % Egg.eventTraitSum();
                for(uint32 j=Egg.eventTraitStartingIndex(0, i); j<Egg.eventTraitStartingIndex(1, i); j++){
                    sum += maturityMultiplier * maturity * uint256(Egg.getRarity(i, j)) / (maxMaturity * baseMultiplier);
                    maturity -= amountToDiminishBy;
                    if(rng <= sum){
                        newCrow[i] = j;
                        break;
                    }
                }
            }
        }
        
        //check if egg was in a special event and if it was then re run trait setting script
        if(Egg.eggInfo(tokenID).EventID != 0){
            uint eventID = Egg.eggInfo(tokenID).EventID;
            for (uint8 i=0; i<8; i++){
                maturity = startingMaturity;
                amountToDiminishBy = (maturity - minMaturity) / (Egg.eventTraitStartingIndex(eventID + 1, i) - Egg.eventTraitStartingIndex(eventID, i));
                sum = 0;
                uint rng = expandedRandomness[i+8] % Egg.eventTraitSum();
                for(uint32 j=Egg.eventTraitStartingIndex(eventID, i); j<Egg.eventTraitStartingIndex(eventID + 1, i) - 1; j++){//don't check the last address bc if it is in that, then the traits should not change
                    sum += maturityMultiplier * maturity * uint256(Egg.getRarity(i, j)) / (maxMaturity * baseMultiplier);
                    maturity -= amountToDiminishBy;
                    if(rng <= sum){
                        newCrow[i] = j;
                        break;
                    }
                }
            }
        }
        
    }

    function _getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint tokenId = requestIDtoTokenID[requestId];
        Egg.setCrowRNG(tokenId, randomness);//save the random number for the crow
        messages[tokenId].rngSet = true;
    }

function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
    expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
    }
    return expandedValues;
}

}