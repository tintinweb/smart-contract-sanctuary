/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: contracts/Holiday Apes/SnowballGame.sol


pragma solidity ^0.8.10;




// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IGiftyToken is IERC20 {
    function approvedMint(address, uint256) external;

    function approvedBurn(address, uint256) external;
}

interface IHolidayApes is IERC721Enumerable {
    function approvedTransfer(
        address,
        address,
        uint256
    ) external;
}

contract SnowballGame is Ownable, VRFConsumerBase {
    // =================================== CONSTANTS ===================================

    event SurvivedHard(uint256 indexed randomNumber);
    event CrashedHard(uint256 indexed randomNumber);
    event SurvivedFlake(uint256 indexed randomNumber);
    event CrashedFlake(uint256 indexed randomNumber);

    address public stakeAddress = 0x02931a2c64AD02e9B6A1c45c8501C2dF39142C45; // Dummy address for compile check

    IHolidayApes IApes =
        IHolidayApes(0x52567ca65f18632e5232349f83820A7C0cCb93A7); // Dummy address for compile check
    IGiftyToken IGifty =
        IGiftyToken(0x768A51e7d847F10F66299738AA1eF2CdF323Ad4e); // Dummy address for compile check

    // Percentages - for overview only
    uint256 public constant HARD_MULTIPLIER_INCREASE = 135; // 35%
    uint256 public constant FLAKE_MULTIPLIER_INCREASE = 115; // 15%

    // Percentages
    uint256 public constant HARD_CRASH_ODDS = 20; // 20%
    uint256 public constant FLAKE_CRASH_ODDS = 10; // 10%

    // Chainlink VRF

    // https://docs.chain.link/docs/vrf-contracts/

    /* Ethereum Mainnet
     * LINK Token: 0x514910771AF9Ca656af840dff83E8264EcF986CA
     * VRF Coordinator: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * Key Hash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     * Fee: 2 LINK
     */

    /* Rinkeby
     * LINK Token: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * VRF Coordinator: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     * Fee: 0.1 LINK
     */

    bytes32 internal constant KEY_HASH =
        0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311; // Rinkeby
    uint256 internal constant LINK_FEE = 10**17; // 0.1 LINK

    // =================================== Variables ===================================

    // Shared between game modes, saved in results mapping and gets overwritten on every call
    uint256 public randomResult; // between 1 and 100, including both ends
    bool public refreshedRandom; // locks proceeding before processing randomness call

    bool public canJoinHard = true;
    bool public canJoinFlake = true;

    bool public canWithdrawHard = true;
    bool public canWithdrawFlake = true;

    uint256 public hardGameId = 1; // 0 is reserved for unstaking
    uint256 public flakeGameId = 1;

    uint256 public hardMulCounter;
    uint256 public flakeMulCounter;

    mapping (uint256 => mapping (address => uint256)) public hardAddressTokens;
    mapping (uint256 => mapping (address => uint256)) public flakeAddressTokens;

    mapping (uint256 => uint256) public hardTotalTokens;
    mapping (uint256 => uint256) public flakeTotalTokens;

    uint256 public currentlyStaked;

    mapping (uint256 => uint256) public hardTotalStakedPerGame;
    mapping (uint256 => uint256) public flakeTotalStakedPerGame;

    // Mapping for claimed initial $GIFTY tokens
    // Every holiday ape comes with 10,000 $GIFTY to be claimed
    mapping(uint256 => bool) public claimedInitial;

    mapping(uint256 => address) public stakedMap; // tokenId => address

    // tokenId: gameId when staked (needs to be less than current gameId to claim crash)
    mapping(uint256 => uint256) public stakedHardIdMap;
    mapping(uint256 => uint256) public stakedFlakeIdMap;

    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // Rinkeby
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // Rinkeby
        )
    {}

    /**
     * Requests randomness (https://docs.chain.link/docs/get-a-random-number/)
     */
    function requestRandomnessHard() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= LINK_FEE, "Not enough LINK!");
        canWithdrawHard = false;
        // If previous round was crash
        if (canJoinHard) {
            canJoinHard = false;
        }
        return requestRandomness(KEY_HASH, LINK_FEE);
    }

    function requestRandomnessFlake() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= LINK_FEE, "Not enough LINK!");
        canWithdrawFlake = false;
        // If previous round was crash
        if (canJoinFlake) {
            canJoinFlake = false;
        }
        return requestRandomness(KEY_HASH, LINK_FEE);
    }

    /**
     * Callback function used by VRF Coordinator (https://docs.chain.link/docs/get-a-random-number/)
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = (randomness % 100) + 1; // convert to a number between 1 and 100, including both ends
        refreshedRandom = true;
    }

    // !!! This will be removed in final version !!!
    function simulateRandomnessHard(uint256 result) external onlyOwner {
        randomResult = result;
        canWithdrawHard = false;
        // If previous round was crash
        if (canJoinHard) {
            canJoinHard = false;
        }
        refreshedRandom = true;
    }

    // !!! This will be removed in final version !!!
    function simulateRandomnessFlake(uint256 result) external onlyOwner {
        randomResult = result;
        canWithdrawFlake = false;
        // If previous round was crash
        if (canJoinFlake) {
            canJoinFlake = false;
        }
        refreshedRandom = true;
    }


    function processHard() external onlyOwner {
        require(refreshedRandom, "Still waiting for Chainlink VRF!");
        if (randomResult <= HARD_CRASH_ODDS) {
            // Crashed!
            emit CrashedHard(randomResult);
            hardMulCounter = 0;
            canJoinHard = true;
            // freeze amount of holiday apes that were staked
            hardTotalStakedPerGame[hardGameId] = currentlyStaked;
            hardGameId++;
                        
        } else {
            emit SurvivedHard(randomResult);
            hardMulCounter++;
            canWithdrawHard = true;
        }

        refreshedRandom = false;
    }

    function processFlake() external onlyOwner {
        require(refreshedRandom, "Still waiting for Chainlink VRF!");
        if (randomResult <= FLAKE_CRASH_ODDS) {
            // Crashed!
            emit CrashedFlake(randomResult);
            flakeMulCounter = 0;
            canJoinFlake = true;
            // freeze amount of holiday apes that were staked
            flakeTotalStakedPerGame[flakeGameId] = currentlyStaked;
            flakeGameId++;
                        
        } else {
            emit SurvivedFlake(randomResult);
            flakeMulCounter++;
            canWithdrawFlake = true;
        }

        refreshedRandom = false;
    }

    function withdrawLink(uint256 amount) external onlyOwner {
        LINK.transfer(owner(), amount);
    }

    function claimInitial(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IApes.ownerOf(tokenIds[i]) == msg.sender || stakedMap[tokenIds[i]] == msg.sender,
                "Token not owned!"
            );
            require(
                !claimedInitial[tokenIds[i]],
                "Tokens already claimed for this one!"
            );
            // 10,000 tokens = 10^4*10^18 = 10^22
            IGifty.approvedMint(msg.sender, 1e22);
            claimedInitial[tokenIds[i]] = true;
        }
    }

    function stake(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IApes.ownerOf(tokenIds[i]) == msg.sender,
                "Token not owned!"
            );
            IApes.approvedTransfer(msg.sender, stakeAddress, tokenIds[i]);
            stakedMap[tokenIds[i]] = msg.sender;
            stakedHardIdMap[tokenIds[i]] = hardGameId;
            stakedFlakeIdMap[tokenIds[i]] = flakeGameId;
        }
        currentlyStaked += tokenIds.length;
    }

    function unstake(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(stakedMap[tokenIds[i]] == msg.sender, "Token not owned!");
            IApes.approvedTransfer(stakeAddress, msg.sender, tokenIds[i]);
            delete stakedMap[tokenIds[i]];
            delete stakedHardIdMap[tokenIds[i]]; // sets to 0 which is reserved for none (first gameId is 1)
            delete stakedFlakeIdMap[tokenIds[i]];
        }
        currentlyStaked -= tokenIds.length;
    }

    function claimHardCrashes(uint256 tokenId, uint256[] calldata hardGameIds) external {
        // This is very gas inefficient lmao, O(n^2) for all tokens

        for (uint256 i = 0; i < hardGameIds.length; i++) {
            // Check if the token was staked during those times
            require(stakedHardIdMap[tokenId] != 0, "Token not staked!");
            require(stakedHardIdMap[tokenId] < hardGameIds[i], "Token wasn't staked at that time!");
            // 30% of pool is burned, rest is divided into shares 
            IGifty.approvedMint(msg.sender, hardTotalTokens[hardGameIds[i]] * 70 / (100 * hardTotalStakedPerGame[hardGameIds[i]]) );
        }

    }

    function claimFlakeCrashes(uint256 tokenId, uint256[] calldata flakeGameIds) external {
        // This is very gas inefficient lmao, O(n^2) for all tokens

        for (uint256 i = 0; i < flakeGameIds.length; i++) {
            // Check if the token was staked during those times
            require(stakedFlakeIdMap[tokenId] != 0, "Token not staked!");
            require(stakedFlakeIdMap[tokenId] < flakeGameIds[i]);
            // 30% of pool is burned, rest is divided into shares 
            IGifty.approvedMint(msg.sender, flakeTotalTokens[flakeGameIds[i]] * 70 / (100 * flakeTotalStakedPerGame[flakeGameIds[i]]) );
        }

    }


    function flipJoinHard() public onlyOwner {
        canJoinHard = !canJoinHard;
    }

    function flipJoinFlake() public onlyOwner {
        canJoinFlake = !canJoinFlake;
    }

    function flipWithdrawHard() public onlyOwner {
        canWithdrawHard = !canWithdrawHard;
    }

    function flipWithdrawFlake() public onlyOwner {
        canWithdrawFlake = !canWithdrawFlake;
    }


    function enterHard(uint256 tokenAmount) external {
        require(canJoinHard, "Join period closed!");
        require(
            IGifty.balanceOf(msg.sender) >= tokenAmount,
            "Token amount exceeds current balance!"
        );
        IGifty.approvedBurn(msg.sender, tokenAmount);

        hardAddressTokens[hardGameId][msg.sender] += tokenAmount;
        hardTotalTokens[hardGameId] += tokenAmount;
    }

    function enterFlake(uint256 tokenAmount) external {
        require(canJoinFlake, "Join period closed!");
        require(
            IGifty.balanceOf(msg.sender) >= tokenAmount,
            "Token amount exceeds current balance!"
        );
        IGifty.approvedBurn(msg.sender, tokenAmount);

        flakeAddressTokens[flakeGameId][msg.sender] += tokenAmount;
        flakeTotalTokens[flakeGameId] += tokenAmount;
    }


    function withdrawHard(uint256 initialTokenAmount) external {
        require(canWithdrawHard, "Withdrawals currently disabled!");
        require(hardAddressTokens[hardGameId][msg.sender] >= initialTokenAmount, "You don't have that amount of initial (unmultiplied) tokens!");

        IGifty.approvedMint(msg.sender, initialTokenAmount * getHardMulx100(hardMulCounter) / 100);
        hardAddressTokens[hardGameId][msg.sender] -= initialTokenAmount;
        hardTotalTokens[hardGameId] -= initialTokenAmount;
    }

    function withdrawFlake(uint256 initialTokenAmount) external {
        require(canWithdrawFlake, "Withdrawals currently disabled!");
        require(flakeAddressTokens[flakeGameId][msg.sender] >= initialTokenAmount, "You don't have that amount of initial (unmultiplied) tokens!");

        IGifty.approvedMint(msg.sender, initialTokenAmount * getHardMulx100(hardMulCounter) / 100);
        flakeAddressTokens[flakeGameId][msg.sender] -= initialTokenAmount;
        flakeTotalTokens[flakeGameId] -= initialTokenAmount;
    }


    // Hardcoded
    function getFlakeMulx100(uint256 counter) public pure returns (uint256) {
        if (counter == 0) return 100;
        else if (counter == 1) return 115;
        else if (counter == 2) return 132;
        else if (counter == 3) return 152;
        else if (counter == 4) return 175;
        else if (counter == 5) return 201;
        else if (counter == 6) return 231;
        else if (counter == 7) return 266;
        else if (counter == 8) return 306;
        else if (counter == 9) return 352;
        else if (counter == 10) return 405;
        else if (counter == 11) return 465;
        else if (counter == 12) return 535;
        else if (counter == 13) return 615;
        else if (counter == 14) return 708;
        else if (counter == 15) return 814;
        else if (counter == 16) return 936;
        else if (counter == 17) return 1076;
        else if (counter == 18) return 1238;
        else if (counter == 19) return 1423;
        else if (counter == 20) return 1637;
        else if (counter == 21) return 1882;
        else if (counter == 22) return 2164;
        else if (counter == 23) return 2489;
        else if (counter == 24) return 2863;
        else if (counter == 25) return 3292;
        else if (counter == 26) return 3786;
        else if (counter == 27) return 4354;
        else if (counter == 28) return 5007;
        else if (counter == 29) return 5758;
        else if (counter == 30) return 6621;
        else return 6621;
    }

    function getHardMulx100(uint256 counter) public pure returns (uint256) {
        if (counter == 0) return 100;
        else if (counter == 1) return 135;
        else if (counter == 2) return 182;
        else if (counter == 3) return 246;
        else if (counter == 4) return 332;
        else if (counter == 5) return 448;
        else if (counter == 6) return 605;
        else if (counter == 7) return 817;
        else if (counter == 8) return 1103;
        else if (counter == 9) return 1489;
        else if (counter == 10) return 2011;
        else if (counter == 11) return 2714;
        else if (counter == 12) return 3664;
        else if (counter == 13) return 4947;
        else if (counter == 14) return 6678;
        else if (counter == 15) return 9016;
        else if (counter == 16) return 12171;
        else if (counter == 17) return 16431;
        else if (counter == 18) return 22182;
        else if (counter == 19) return 29946;
        else if (counter == 20) return 40427;
        else if (counter == 21) return 54577;
        else if (counter == 22) return 73679;
        else if (counter == 23) return 99466;
        else if (counter == 24) return 13428;
        else if (counter == 25) return 181278;
        else if (counter == 26) return 244725;
        else if (counter == 27) return 330378;
        else if (counter == 28) return 446011;
        else if (counter == 29) return 602115;
        else if (counter == 30) return 812855;
        else return 812855;
    }
}