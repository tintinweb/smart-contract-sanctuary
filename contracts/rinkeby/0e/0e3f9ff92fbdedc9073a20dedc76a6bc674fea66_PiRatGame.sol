/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// File: contracts/IPiRatGame.sol



pragma solidity ^0.8.0;

interface IPiRatGame {
}
    
// File: contracts/IBOOTY.sol



pragma solidity ^0.8.0;

interface IBOOTY {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function claimBooty(address owner) external;
    function burnExternal(address from, uint256 amount) external;
    function initTimeStamp(address owner, uint256 timeStamp) external;
    function showPendingClaimable(address owner) external view returns (uint256);
    function crownRewards() external view returns (uint256);
    function claimCrownTax(address _recipient, uint256 amount) external;
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/IPiRats.sol



pragma solidity ^0.8.0;


interface IPiRats is IERC721Enumerable {

    // game data storage
    struct CrewCaptain {
        bool isCrew;
        uint8 body;
        uint8 clothes;
        uint8 face;
        uint8 mouth;
        uint8 eyes;
        uint8 head;
        uint8 legendRank;
    }
    
    function paidTokens() external view returns (uint256);
    function maxTokens() external view returns (uint256);
    function totalPiratsMinted() external view returns (uint16);
    function totalPiratsBurned() external view returns (uint16);
    function mintPiRat(address recipient, uint16 amount, uint256 seed) external;
    function plankPiRat(address recipient, uint16 amount, uint256 seed, uint256 _burnToken) external;
    function getTokenTraits(uint256 tokenId) external view returns (CrewCaptain memory);
    function isCrew(uint256 tokenId) external view returns(bool);
    function getBalanceCrew(address owner) external view returns (uint16);
    function getBalanceCaptain(address owner) external view returns (uint16);
}
// File: contracts/IPOTMTraits.sol



pragma solidity ^0.8.0;


interface IPOTMTraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function selectMintTraits(uint256 seed) external view returns (IPiRats.CrewCaptain memory t);
  function selectPlankTraits(uint256 seed) external view returns (IPiRats.CrewCaptain memory t);
}
// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol


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
  ) internal pure returns (uint256) {
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
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol


pragma solidity ^0.8.0;



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
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

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
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/PiRatGame.sol



pragma solidity ^0.8.0;









contract PiRatGame is IPiRatGame, Ownable, VRFConsumerBase, ReentrancyGuard, Pausable {

    /// GENERAL SETUP ///
    bool public publicSaleStarted;
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public constant PRESALE_PRICE = 0.066 ether;
    uint256 public constant MINT_PRICE = .066 ether;

    uint256 private maxBootyCost = 4000 ether;

    /// WHITELIST SETUP ///
    struct Whitelist {
        bool isWhitelisted;
        uint16 numMinted;
    }
    mapping(address => Whitelist) private _whitelistAddresses;

    /// MINT SETUP ///
    struct MintCommit {
        uint16 amount;
    }

    event MintCommitted(address indexed owner, uint256 indexed amount);
    event MintRevealed(address indexed owner, uint256 indexed amount);

    uint16 public _mintCommitId = 0;
    uint16 public pendingMintAmt;

    mapping(address => mapping(uint16 => MintCommit)) private _mintCommits;   

    mapping(address => uint16) private _pendingMintCommitId;

    /// WALK THE PLANK SETUP ///
    struct PlankCommit {
        uint16 amount;
    }

    event PlankCommitted(address indexed owner, uint256 indexed amount);
    event PlankRevealed(address indexed owner, uint256 indexed amount);

    uint16 private _plankCommitId = 60000;
    uint16 private pendingPlankAmt;

    mapping(uint16 => uint256) private _plankCommitRandoms;
    mapping(address => mapping(uint16 => PlankCommit)) private _plankCommits;
    mapping(address => uint16) private _pendingPlankCommitId;

    /// RANDOM NUMBER SETUP ///
    event requestedRandomSeed(bytes32 indexed requestId, uint16 indexed commitId); 
    event CreatedMintCommitSeed(uint16 indexed commitId, uint256 randomNumber);

    mapping(bytes32 => address) private requestIdToSender;
    mapping(uint256 => uint256) private commitIdToRandomNumber;
    mapping(bytes32 => uint16) private requestIdToCommitId;    

    IPiRats public potm;
    IBOOTY public booty;

    constructor()    
    VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
        _pause();
    }
    /// MODIFIERS ///

    modifier requireContractsSet() {
        require(
            address(booty) != address(0) && 
            address(potm) != address(0), "Contracts not set");
      _;
    }

    /// WHITELIST ///
    
    function addToWhitelist(address[] calldata addressesToAdd) public onlyOwner {
        for (uint256 i = 0; i < addressesToAdd.length; i++) {
            _whitelistAddresses[addressesToAdd[i]] = Whitelist(true, 0);
        }
    }

    function setPublicSaleStart(bool started) external onlyOwner {
        publicSaleStarted = started;
        if(publicSaleStarted) {
        }
    }

    /// MINTING ///

    function commitPirat(uint16 amount) external payable whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(_pendingMintCommitId[msg.sender] == 0, "Already have pending mints");
        uint16 totalPiratsMinted = potm.totalPiratsMinted();
        uint16 totalPending = pendingMintAmt /*+ pendingPlankAmt*/;
        uint256 maxTokens = potm.maxTokens();
        uint256 paidTokens = potm.paidTokens();
        require(totalPiratsMinted + totalPending + amount <= maxTokens, "All tokens minted");
        require(amount > 0 && amount <= 10, "Invalid mint amount");
        if (totalPiratsMinted < paidTokens) {
            require(totalPiratsMinted + totalPending + amount <= paidTokens, "All tokens on-sale already sold");
            if(publicSaleStarted) {
                require(msg.value == amount * MINT_PRICE, "Invalid payment amount");
            } else {
                require(amount * PRESALE_PRICE == msg.value, "Invalid payment amount");
                require(_whitelistAddresses[msg.sender].isWhitelisted, "Not on whitelist");
                require(_whitelistAddresses[msg.sender].numMinted + amount <= 5, "too many mints");
                _whitelistAddresses[msg.sender].numMinted += uint16(amount);
            }
        } else {
            require(msg.value == 0);
        }
        uint256 totalBootyCost = 0;
        for (uint i = 1; i <= amount; i++) {
            totalBootyCost += mintCost(totalPiratsMinted + totalPending + i);
            }
        if (totalBootyCost > 0) {
            booty.burnExternal(msg.sender, totalBootyCost);
        }
        _mintCommitId += 1;
        uint16 commitId = _mintCommitId;
        _mintCommits[msg.sender][commitId] = MintCommit(amount);       
        _pendingMintCommitId[msg.sender] = commitId;
        pendingMintAmt += amount;
        getRandomNumber(commitId);
        emit MintCommitted(msg.sender, amount);
    }

    function mintCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= potm.paidTokens()) return 0;
        if (tokenId <= potm.maxTokens() * 2 / 4) return 1000 ether;  // 50%
        if (tokenId <= potm.maxTokens() * 3 / 4) return 2000 ether;  // 75%
        return maxBootyCost;
    }

    function revealPiRat() public whenNotPaused nonReentrant {
        address recipient = msg.sender;
        uint16 mintCommitIdCur = getMintCommitId(recipient);
        uint256 mintSeedCur = getRandomSeed(mintCommitIdCur);
        require(mintSeedCur > 0, "random seed not set");
        uint16 amount = getPendingMintAmount(recipient);
        potm.mintPiRat(recipient, amount, mintSeedCur);
        pendingMintAmt -= amount;
        delete _mintCommits[recipient][_mintCommitId];        
        delete _pendingMintCommitId[recipient];
        emit MintRevealed(recipient, amount);
    }

    /// WALK THE PLANK ///

    function walkPlank() external whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(_pendingPlankCommitId[msg.sender] == 0, "Already have pending mints");
        uint16 totalPiratsMinted = potm.totalPiratsMinted();
        uint16 totalPending = pendingMintAmt + pendingPlankAmt;
        uint256 maxTokens = potm.maxTokens();
        require(totalPiratsMinted + totalPending + 1 <= maxTokens, "All tokens minted");
        uint256 totalBootyCost = 0;
        for (uint i = 1; i <= 1; i++) {
            totalBootyCost += mintCost(totalPiratsMinted + totalPending + i);
            }
        if (totalBootyCost > 0) {
            booty.burnExternal(msg.sender, totalBootyCost);
        }
        _plankCommitId += 1;
        uint16 commitId = _plankCommitId;
        _plankCommits[msg.sender][commitId] = PlankCommit(1);       
        _pendingPlankCommitId[msg.sender] = commitId;
        pendingPlankAmt += 1;
        getRandomNumber(commitId);
        emit PlankCommitted(msg.sender, 1);
    }

    function plankCost(uint256 tokenId) public view returns (uint256) {
        if (tokenId <= potm.paidTokens()) return 2000 ether;
        if (tokenId <= potm.maxTokens() * 2 / 4) return 4000 ether;  // 50%
        if (tokenId <= potm.maxTokens() * 3 / 4) return 6000 ether;  // 75%
        return (maxBootyCost * 2);
    }

    function revealPlankPiRat(uint256 tokenId) public whenNotPaused nonReentrant {
        require(potm.isCrew(tokenId), "Only Crew can Walk The Plank");
        address recipient = msg.sender;
        booty.claimBooty(recipient);
        uint16 plankCommitIdCur = getPlankCommitId(recipient);
        uint256 plankSeedCur = getRandomSeed(plankCommitIdCur);
        require(plankSeedCur > 0, "random seed not set");
        uint16 amount = 1;
        potm.plankPiRat(recipient, amount, plankSeedCur, tokenId);
        pendingPlankAmt -= amount;
        delete _plankCommits[recipient][_plankCommitId];        
        delete _pendingPlankCommitId[recipient];
        emit PlankRevealed(recipient, amount);
    }

    /// CLAIMING $BOOTY /// 

    function claimBooty() public {
        require(tx.origin == msg.sender, "Only EOA");
        booty.claimBooty(msg.sender);
    }

    function showBootyClaimable(address owner) external view returns(uint256 owed) {
        require(tx.origin == msg.sender, "Only EOA");
        owed = booty.showPendingClaimable(owner);
    }

    /// CROWN TAXES ///

    function balanceCrownTax() public view onlyOwner returns(uint256) {
         return booty.crownRewards(); 
    }

    function giveCrownTax(address _recipient, uint256 amount) public onlyOwner{
        require(booty.crownRewards() - amount >= 0);
        booty.claimCrownTax(_recipient, amount);
	}

    /// EXTERNAL ///

    function getPendingMintAmount(address addr) public view returns (uint16 amount) {
        uint16 mintCommitIdCur = _pendingMintCommitId[addr];
        require(mintCommitIdCur > 0, "No pending commit");
        MintCommit memory mintCommit = _mintCommits[addr][mintCommitIdCur];
        amount = mintCommit.amount;
    }

    function getMintCommitId(address addr) public view returns (uint16) {
        require(_pendingMintCommitId[addr] != 0, "no pending commits");
        return _pendingMintCommitId[addr];
    }

    function hasMintPending(address addr) public view returns (bool) {
        return _pendingMintCommitId[addr] != 0;
    }

    function readyToRevealMint(address addr) public view returns (bool) {
        uint16 mintCommitIdCur = _pendingMintCommitId[addr];
        return getRandomSeed(mintCommitIdCur) !=0;
    }

    function getPendingPlankAmount(address addr) public view returns (uint16 amount) {
        uint16 plankCommitIdCur = _pendingPlankCommitId[addr];
        require(plankCommitIdCur > 0, "No pending commit");
        PlankCommit memory plankCommit = _plankCommits[addr][plankCommitIdCur];
        amount = plankCommit.amount;
    }

    function getPlankCommitId(address addr) public view returns (uint16) {
        require(_pendingPlankCommitId[addr] != 0, "no pending commits");
        return _pendingPlankCommitId[addr];
    }

    function hasPlankPending(address addr) public view returns (bool) {
        return _pendingPlankCommitId[addr] != 0;
    }

    function readyToRevealPlank(address addr) public view returns (bool) {
        uint16 plankCommitIdCur = _pendingPlankCommitId[addr];
        return getRandomSeed(plankCommitIdCur) !=0;
    }

    /// OWNER ///

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setContracts(address _booty, address _potm) external onlyOwner {
        booty = IBOOTY(_booty);       
        potm = IPiRats(_potm);

    }

    /// READ ///

    /// WORKING TEMPORARY ///

    function _rand(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, seed)));
    }

    function withdrawLINK() external onlyOwner {
        uint256 tokenSupply = LINK.balanceOf(address(this));
        LINK.transfer(msg.sender
        , tokenSupply);
    }

    /// CHAINLINK VRF ///
    function getRandomNumber(uint16 commitId) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender; 
        requestIdToCommitId[requestId] = commitId;
        emit requestedRandomSeed(requestId, commitId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        uint16 commitId = requestIdToCommitId[requestId];
        commitIdToRandomNumber[commitId] = randomNumber;
        emit CreatedMintCommitSeed(commitId, randomNumber);
    }

    function getRandomSeed(uint16 commitId) public view returns (uint256 randomNumber) {
        randomNumber = commitIdToRandomNumber[commitId];
    }
}

    /**
    * Constructor inherits VRFConsumerBase
     
    * Network: Mainnet
    * Chainlink VRF Coordinator address: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
    * LINK token address:                0x514910771AF9Ca656af840dff83E8264EcF986CA
    * Key Hash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
    * fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)

    * Network: Rinkeby
    * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
    * LINK token address:                0x01BE23585060835E02B77ef475b0Cc51aA1e0709
    * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
    * fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)

     */