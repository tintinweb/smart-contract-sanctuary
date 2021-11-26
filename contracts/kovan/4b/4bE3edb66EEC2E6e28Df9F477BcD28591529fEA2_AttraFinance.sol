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

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
import "./FundManager.sol";
import "./Lottery.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol

/**
 * Public face of a campaign.
 * Campaign State Machine.
 * Public proxies to FundManager functions.
 * Lottery implementation.
 *
 * Balance during the AttraCampaign / FundManager lifecycle:
 *
 * As funds are being collected, they are kept in the CrowdFund contract.
 * When lottery completes, in a single TX:
 * - funds are withdrawn from the crowdfund & distributed to winners
 * - fees are retained and transferred to the treasury
 * - the remaining balance stays in the AttraCampaign
 * A subsequent call to settleBeneficiaryAndTokens() is then made by the
 * beneficiary; it triggers the distribution of tokens and leaves the
 * campaign with an empty balance.
 *
 *
 */
contract AttraCampaign is KeeperCompatibleInterface, FundManager, Lottery {
    enum campaignState {
        FRESH,
        OPEN,
        SUCCESS_PREPARE_LOTTERY,
        SUCCESS_READY_FOR_LOTTERY,
        SUCCESS_SETTLED_WINNERS,
        SUCCESS_SETTLED_BENEFICIARY,
        FAIL_SETTLED
    }

    // flags for the concluding state machine
    campaignState public state;

    string public name;
    uint256 public start; // seconds since epoch according to current block
    uint256 public duration; // duration of the current campaign in seconds

    event StartCampaign(
        uint256 timestamp,
        uint256 indexed id,
        string indexed name,
        uint256 duration,
        address beneficiary,
        uint16 prizeBasisPoints,
        uint256 minContributionUSD,
        uint256 targetUSD
    );

    event Advanced(uint256 id, campaignState newState);

    constructor(
        uint256 _id,
        string memory _name,
        address _priceFeed,
        address payable _treasury,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _vrfFee,
        address _tokenFactoryAddr
    )
        FundManager(_id, _priceFeed, _treasury, _tokenFactoryAddr)
        Lottery(_vrfCoordinator, _link, _keyHash, _vrfFee)
    {
        require(bytes(_name).length > 0, "A campaign must have a name");
        name = _name;
        state = campaignState.FRESH;
    }

    function id() public view returns (uint256) {
        return _myId;
    }

    function _advanceState(campaignState newState) private {
        state = newState;
        emit Advanced(_myId, state);
    }

    // -------------- CAMPAIGN MANAGEMENT -----------

    // TODO tokenURI nice to have but not essential now
    function startCampaign(
        uint256 _duration,
        address payable _beneficiary,
        uint16 _prize,
        uint8 _numberOfPicks,
        uint256 _minContributionUsd,
        uint256 _targetUsd,
        uint16 _ownerFee,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public onlyOwner {
        require(_duration != 0, "The campaign duration cannot be 0");
        require(_ownerFee < 5000, "The owner fee must be lower than 50%");
        _advanceState(campaignState.OPEN);

        //console.log("* * * STARTING CAMPAIGN");

        start = block.timestamp;
        duration = _duration;
        numberOfPicks = _numberOfPicks;
        ownerFee = _ownerFee;

        openFund(
            _beneficiary,
            _prize,
            _minContributionUsd,
            _targetUsd,
            _tokenName,
            _tokenSymbol
        );

        emit StartCampaign(
            block.timestamp,
            _myId,
            name,
            _duration,
            _beneficiary,
            _prize,
            _minContributionUsd,
            _targetUsd
        );
    }

    function _isDurationEllapsed()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return (block.timestamp - start) > duration;
    }

    // ------- CONCLUDING ------- //

    function _isTargetAchieved() private view returns (bool) {
        return crowdFund.balanceInUSD() >= minTotalAmountUsd;
    }

    /**
     * As a safety measure anyone can call this.
     * In case the Keeper doesn't have LINK / is not available anymore.
     * Or in case the owner has lost control over the keeper.
     */
    function conclude() public {
        if (state == campaignState.OPEN) {
            require(_canClose(), "Campaign is still open for contributions");
            _closeCampaign();
        } else if (state == campaignState.SUCCESS_PREPARE_LOTTERY) {
            revert("waiting for randomness from Chainlink VRF");
            // TODO add safety function: after x duration of being in this state it should be possible to just trigger refunds
        } else if (state == campaignState.SUCCESS_READY_FOR_LOTTERY) {
            _completeLottery();
        } else if (state == campaignState.SUCCESS_SETTLED_WINNERS) {
            // TODO add safety function: after x duration of being in this state it should be possible to trigger refunds (multisig?)
        }
    }

    function _canClose() private view returns (bool) {
        return _isDurationEllapsed() || _isTargetAchieved();
    }

    function _closeCampaign() private {
        closeFund();
        bool successful = _isTargetAchieved();
        //console.log("CAMPAIGN CLOSED. Successful: ", successful);
        if (successful) {
            // make VRF request, finalize on VRF callback
            startLottery(_myId);
            state = campaignState.SUCCESS_PREPARE_LOTTERY;
        } else {
            // finalize immediately with refunds
            //console.log(" * * * Refunding...");
            _refundAll();
            _advanceState(campaignState.FAIL_SETTLED);
        }
    }

    function _onReceivedRandomness() internal virtual override {
        _advanceState(campaignState.SUCCESS_READY_FOR_LOTTERY);
        //console.log("received randomness, now ready for lottery");
    }

    function _completeLottery() private {
        _pickWinner(receivedRandomness);
        //console.log(" * * * Lottery complete. Wrapping up campaign.");
        _proceedAfterLottery();
        _advanceState(campaignState.SUCCESS_SETTLED_WINNERS);
    }

    /**
     * Pick winning tickets considering contributed amounts.
     *
     * The method resembles a procedure where players have numbered tickets,
     * some of them having more tickets than others, therefore higher chances of winning.
     * When there are several picks, the same person may hold several of the winning tickets.
     *
     * The prize is distributed among winners, so the multi-winner gets more of the prize.
     *
     * We form an array of accumulated contribution amounts corresponding to each
     * contributor together with all the ones that came before them.
     * The winning tickets correspond to particular accumulation bins.
     */
    function _pickWinner(uint256 _randomness) internal {
        uint256[] memory rands = _expand(_randomness, numberOfPicks);
        uint256[] memory winnerPicks = new uint256[](numberOfPicks);
        uint256 _totalCollected = address(crowdFund).balance;
        for (uint8 i = 0; i < numberOfPicks; i++) {
            winnerPicks[i] = rands[i] % _totalCollected;
        }
        // find the contributor indexes corresponding to the winnerPicks
        uint256 _poolSize = crowdFund.lengthContributors();
        uint256 acc = 0;
        uint256 prevLimit = 0;
        for (
            uint256 contributorIdx = 0;
            contributorIdx < _poolSize;
            contributorIdx++
        ) {
            // creating the bin corresponding to this contributor
            uint256 amt = crowdFund.contributionAtIdx(contributorIdx);
            acc += amt;
            // check if any of the winnerPicks is this contributor's bin
            for (uint8 j = 0; j < numberOfPicks; j++) {
                if (acc > winnerPicks[j] && winnerPicks[j] >= prevLimit) {
                    winnerIdxs.push(contributorIdx);
                }
            }
            prevLimit = acc;
        }
    }

    /**
     * Beneficiary gets paid,
     * Non-winning contributors get their participation tokens.
     * Restricting this to be called only by the beneficiary.
     *
     * NOT AUTOMATED:
     * We don't call this via the keeper (for now), since it makes sense fore
     * the beneficiary to support the costs of minting all the tokens. It's more
     * transparent this way, and also technically simpler.
     * Should it become obvious that automating this step is the better way to go,
     * this function can be removed.
     *
     * NOT COMPLETELY PUBLIC:
     * In case the beneficiary loses access to their keys, the funds cannot be accidentally
     * sent to them by any public person.
     */
    function settleBeneficiaryAndTokens() public {
        require(msg.sender == beneficiary, "Only the beneficiary");
        _settleBenAndTokens();
        _advanceState(campaignState.SUCCESS_SETTLED_BENEFICIARY);
    }

    // ------------ AUTOMATION with KEEPERS

    /**
     * Returns true also in cases of target achieved && duration not ellapsed.
     *  -> a campaign with no registered upkeep may remain open for contributions
     *     all the way until duration ellapsed, allowing for way more than is set
     *     as a target
     *  -> a campaign with upkeep will conveniently close as soon as target is meat
     */
    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory)
    {
        bool needsLink = state == campaignState.OPEN &&
            _canClose() &&
            _isTargetAchieved();
        if (needsLink && !hasEnoughLink()) {
            upkeepNeeded = false;
        } else {
            upkeepNeeded =
                (state == campaignState.OPEN && _canClose()) || // first conclude - refunds on fail / VRF request on success
                state == campaignState.SUCCESS_READY_FOR_LOTTERY; // use VRF result - pick winners, pay them

            // beneficiary payout goes with participation token minting and should be triggered by beneficiary
        }
    }

    function performUpkeep(bytes calldata) external override {
        conclude();
    }

    // ----------------------------------

    // -------------- LINK funds management

    function fundWithLink(uint256 _amt) public {
        LINK.transferFrom(msg.sender, address(this), _amt);
    }

    function linkBalance() public view returns (uint256) {
        return LINK.balanceOf(address(this));
    }

    function withdrawLink() public onlyOwner {
        LINK.transfer(owner(), linkBalance());
    }

    // ----------------------------------
}

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "./AttraCampaign.sol";
import "./Treasury.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

/**
 * Attra Platform
 *
 * Creates campaigns, keeps track of them.
 * Manages defaults for chainlink integration. (VRF, Price Feed)
 * Owns a Treasury and passes it to any created campaign.
 */
contract AttraFinance is Ownable {
    address payable[] campaigns;
    Treasury treasury;

    address priceFeed;
    address vrfCoordinator;
    address link;
    bytes32 keyHash;
    uint256 vrfFee;
    address tokenFactoryAddr;

    event CreateCampaign(uint256 timestamp, uint256 indexed campaignId);

    constructor(
        address _priceFeed,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _vrfFee,
        address _tokenFactory
    ) {
        priceFeed = _priceFeed;
        vrfCoordinator = _vrfCoordinator;
        link = _link;
        keyHash = _keyHash;
        vrfFee = _vrfFee;
        tokenFactoryAddr = _tokenFactory;

        treasury = new Treasury();
    }

    // should be multisig instead of onlyOwner
    function withdrawFromTreasury(uint256 amt, address payable receiver)
        public
        onlyOwner
    {
        treasury.withdrawTo(amt, receiver);
    }

    // --------------------- CAMPAIGNS --------------------

    function createCampaign(string memory _name, bool _doTransferOwnership)
        public
    {
        uint256 id = campaigns.length;
        AttraCampaign newCamp = new AttraCampaign(
            id,
            _name,
            priceFeed,
            payable(treasury),
            vrfCoordinator,
            link,
            keyHash,
            vrfFee,
            tokenFactoryAddr
        );
        campaigns.push(payable(newCamp));
        if (_doTransferOwnership) {
            newCamp.transferOwnership(msg.sender);
        }
        emit CreateCampaign(block.timestamp, id);
    }

    function createAndStartCampaign(
        string memory _name,
        uint256 _duration,
        address payable _beneficiary,
        uint16 _prize,
        uint8 _numberOfPicks,
        uint256 _minContributionUsd,
        uint256 _targetUsd,
        uint16 _ownerFee,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public {
        createCampaign(_name, false);
        AttraCampaign camp = AttraCampaign(campaigns[campaigns.length - 1]);
        camp.startCampaign(
            _duration,
            _beneficiary,
            _prize,
            _numberOfPicks,
            _minContributionUsd,
            _targetUsd,
            _ownerFee,
            _tokenName,
            _tokenSymbol
        );
        camp.transferOwnership(msg.sender);
    }

    // ------------------------------------------

    function setPriceFeed(address _priceFeed) public {
        priceFeed = _priceFeed;
    }

    // ------------- PUBLIC INTEREST -------------

    function totalCampaigns() public view returns (uint256) {
        return campaigns.length;
    }

    function campaignById(uint256 _id) public view returns (address) {
        return address(campaigns[_id]);
    }

    function treasuryAddress() public view returns (address) {
        return address(treasury);
    }
}

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
import "@openzeppelin/contracts/access/Ownable.sol"; // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract AttraToken is ERC721, Ownable {
    uint256 campaignId;
    uint256[] _amounts;

    // TODO tokenURI nice to have but not essential for POC

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 _campaignId
    ) ERC721(name_, symbol_) {
        campaignId = _campaignId;
    }

    function mintForContribution(address _contributor, uint256 _amount)
        external
        onlyOwner
    {
        uint256 id = _amounts.length;
        _amounts.push(_amount);
        _safeMint(_contributor, id);
    }

    function contributionAmount(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return _amounts[_tokenId];
    }
}

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import "hardhat/console.sol";

contract ContributionFilter {
    AggregatorV3Interface internal priceFeed;
    uint256 public minAmountUsd;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    modifier onlyMinAmount() {
        //console.log(" ---- Min amount check ----");
        //console.log("WEI: ", msg.value);
        uint256 usdAmount = toUSD(msg.value);
        //console.log("USD: ", usdAmount);
        require(
            usdAmount >= minAmountUsd,
            "contribution is below the minimum required, as currently valued in USD"
        );
        _;
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function precision() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function toUSD(uint256 _weiValue) internal view returns (uint256) {
        return (getLatestPrice() * _weiValue) / 10**8 / 10**18;
    }

    /**
     * Returns current conversion rate according to the on-chain price feed.
     * Useful for amount validation in the frontend UI when contributing
     */
    function ethPrice() public view returns (uint256) {
        return getLatestPrice();
    }

    function minAmountWei() public view returns (uint256) {
        uint256 minUSD = minAmountUsd * 10**18;
        uint256 price = getLatestPrice(); // usd per eth
        uint256 precisionFactor = 10**precision();
        return ((minUSD * precisionFactor) / price);
    }
}

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
import "./ContributionFilter.sol";
import "./AttraToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

/**
 * Takes contributions, keeps track of them.
 */
contract CrowdFund is ContributionFilter, Ownable {
    bool private isOpen;

    struct AggregateContribution {
        uint256 contributorIdx;
        uint256 amount;
    }
    mapping(address => AggregateContribution) private aggregateContributions;
    address payable[] public contributors; // ensure is a SET (array of unique addresses)

    event Contribution(
        uint256 timestamp,
        uint256 campaignId,
        uint256 amount,
        address contributor
    );

    event FundWithdrawal(uint256 timestamp, uint256 amount);

    constructor(address _priceFeed) ContributionFilter(_priceFeed) {}

    function lengthContributors() public view returns (uint256) {
        return contributors.length;
    }

    function contributionOf(address contributor) public view returns (uint256) {
        return aggregateContributions[contributor].amount;
    }

    function contributionAtIdx(uint256 contributorIdx)
        external
        view
        onlyOwner
        returns (uint256)
    {
        return contributionOf(contributors[contributorIdx]);
    }

    function open(uint256 _minAmountUsd) external onlyOwner {
        isOpen = true;
        minAmountUsd = _minAmountUsd;
    }

    function close() external onlyOwner {
        isOpen = false;
    }

    function addContribution(address payable _contributor, uint256 _campaignId)
        external
        payable
        onlyMinAmount
    {
        require(isOpen, "Fund collection is over");
        //console.log("Adding contribution by ", _contributor);

        uint256 amount = msg.value;

        if (aggregateContributions[_contributor].amount == 0) {
            contributors.push(_contributor);
            aggregateContributions[_contributor] = AggregateContribution({
                amount: msg.value,
                contributorIdx: contributors.length - 1
            });
        } else {
            aggregateContributions[_contributor].amount += msg.value;
        }

        emit Contribution(block.timestamp, _campaignId, msg.value, msg.sender);
    }

    function withdraw() external onlyOwner {
        //console.log("Withdrawing collected funds");
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
        emit FundWithdrawal(block.timestamp, amount);
    }

    function balanceInUSD() external view onlyOwner returns (uint256) {
        return toUSD(address(this).balance);
    }
}

pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";

/**
 * Manages fees, keeps track of collected fees and transfers them to the treasury when needed.
 *
 * This solution is programatically more complex than just transferring fees to the owner on each contribution.
 * But it saves gas if we only transfer once per campaign.
 */
contract FeeCollector {
    address payable internal _treasuryAddr; // treasury is a singleton and receives fees from all campaigns

    uint256 public contractCreationFee; // FIXED: token contract creation
    uint256 public lotteryFee; // FIXED: randomness request, winner pick calculation

    uint256 public mintFee; // FIXED PER CONTRIBUTION: for tokens minted on successful campaign

    uint256 public refundFee; // % of each contribution failed campaign refunds
    // fees are given as basis points (2 decimal precision)
    // e.g.
    // fee == 265
    // means 2.65%
    uint256 public minRefundFee; // refund to each contributor

    uint16 public ownerFee; // basis points

    uint256 internal _collectedFees;

    event FeesToTreasury(uint256 timestamp, uint256 campaignId, uint256 total);

    constructor(address payable _treasury) {
        _treasuryAddr = _treasury;
        refundFee = 100; // == 1 %
        minRefundFee = 5000000000000000; // 0.005 ETH
        lotteryFee = 100000000000000000; // 0.1 ETH
    }

    /**
     * Calculates the fee on given amount.
     * Amounts too low for a precise calculation cause revert.
     * Returns amount after fee deduction
     */
    function deductRefundFee(uint256 _amount)
        internal
        returns (uint256 amountAfterFees)
    {
        // iterate over each
        //console.log(" ---- Refund fee ----");
        uint256 f = _calcFee(_amount, refundFee);
        //console.log(" --- Apply percentage");
        //console.log("Contribution amount:   ", _amount);
        //console.log("Contribution fee:      ", f);

        //console.log(" --- Minimum required");
        //console.log("Fee:       ", minRefundFee);

        f = f > minRefundFee ? f : minRefundFee;

        _collectedFees += f;
        return _amount - f;
    }

    function deductLotteryFee() internal {
        //console.log(" ---- Lottery fee ----");
        //console.log(lotteryFee);
        _collectedFees += lotteryFee;
    }

    function deductOwnerFee() internal {
        //console.log(" ---- Owner fee ----");
        uint256 f = _calcFee(address(this).balance, ownerFee);
        //console.log(f);
        _collectedFees += f;
    }

    function _calcFee(uint256 _amount, uint256 _fee)
        private
        pure
        returns (uint256)
    {
        require(
            (_amount / 10000) * 10000 == _amount,
            "amount too small to accurately apply the fee"
        );
        return (_amount * _fee) / 10000; // 100 for percentage and 100 for 2-decimal precision
    }

    function _transferFeesToTreasury(uint256 _campaignId) internal {
        _treasuryAddr.transfer(_collectedFees);
        emit FeesToTreasury(block.timestamp, _campaignId, _collectedFees);
        _collectedFees = 0;
    }
}

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
import "./CrowdFund.sol";
import "./FeeCollector.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
import "./IAttraTokenFactory.sol";
import "./IAttraToken.sol";

/**
 * Takes care of settlements
 * - refunds
 * - payments
 * - participation token emissions
 *
 * Is a FeeCollector: triggers the accounting of fees while it settles payments.
 * After a post-lottery settlement (transfers to winners) all retained fees are transferred
 * to the treasury.
 *
 * To be extended by AttraCampaign.
 *
 * Owns a CrowdFund which handles fund contribution management.
 *
 */
abstract contract FundManager is FeeCollector, Ownable {
    uint256 internal _myId;
    bytes32 private requestId; // TODO set visibility to private in production
    CrowdFund crowdFund; // manages collection of funds
    IAttraTokenFactory tokenFactory;

    address payable public beneficiary; // who gets the funds of the current campaign (if successful)

    uint256[] public winnerIdxs;

    uint16 public prizePercentage; // basis points (0 .. 10000) how much of the total contributed is the prize of the lottery winner
    uint256 public minTotalAmountUsd; // target for total amount for current campaign. must be meat for campaign to be valid
    uint256 public minContAmountUsd; // amount per contribution during current campaign

    // properties of the contribution token
    string public tokenName;
    string public tokenSymbol;
    address public tokenAddress;

    event Refund(
        uint256 timestamp,
        uint256 campaignId,
        uint256 amount,
        address contributor
    );

    event PayBeneficiary(
        uint256 timestamp,
        uint256 campaignId,
        uint256 amount,
        address beneficiary
    );

    modifier onEmptyBalance() {
        require(
            address(this).balance == 0,
            "FundManager should have an empty balance before settlements"
        );
        _;
    }

    constructor(
        uint256 _id,
        address _priceFeed,
        address payable _treasury,
        address _tokenFactoryAddr
    ) FeeCollector(_treasury) {
        _myId = _id;
        crowdFund = new CrowdFund(_priceFeed);
        tokenFactory = IAttraTokenFactory(_tokenFactoryAddr);
    }

    // ----------- FUND MANAGEMENT ---------------

    function openFund(
        address payable _beneficiary,
        uint16 _prizePercentage,
        uint256 _minAmountUsd,
        uint256 _targetAmountUsd,
        string memory _tokenName,
        string memory _tokenSymbol
    ) internal {
        require(_prizePercentage > 0, "The prize must be non-zero");
        require(_prizePercentage <= 3300, "The prize must be lower than 33%");
        require(_targetAmountUsd != 0, "Target amount must be non-zero.");
        require(_minAmountUsd != 0, "Minimum contribution must be non-zero.");
        require(
            _minAmountUsd * 2 < _targetAmountUsd,
            "Min contribution must be lower than half the target"
        );

        beneficiary = _beneficiary;
        prizePercentage = _prizePercentage;
        minContAmountUsd = _minAmountUsd;
        minTotalAmountUsd = _targetAmountUsd;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;

        crowdFund.open(_minAmountUsd);

        //console.log("min contribution USD : ", minContAmountUsd);
        //console.log("campaign target USD :  ", minTotalAmountUsd);
    }

    function closeFund() internal {
        crowdFund.close();
    }

    // --------------- CONTRIBUTIONS

    function contribute() public payable {
        require(!_isDurationEllapsed(), "Fund collection is over");
        crowdFund.addContribution{value: msg.value}(payable(msg.sender), _myId);
    }

    function _isDurationEllapsed() internal view virtual returns (bool);

    function ethPrice() public view returns (uint256) {
        return crowdFund.ethPrice();
    }

    /**
     * For correct conversion rate in the UI for contributors
     */
    function minAmountInWei() public view returns (uint256) {
        return crowdFund.minAmountWei();
    }

    // --------------------------------------------

    // ----- ABLE TO RECEIVE fund withdrawals -----

    receive() external payable {
        require(
            msg.sender == address(crowdFund),
            "Can only receive from my crowdfund"
        );
    }

    // ------------------------------------

    // ----------------- SETTLEMENTS -----------

    /**
     * Refund contributors while applying & retaining fees
     */
    function _refundAll() internal onEmptyBalance {
        crowdFund.withdraw();
        for (uint256 i = 0; i < crowdFund.lengthContributors(); i++) {
            address payable contributor = payable(crowdFund.contributors(i));
            uint256 contribAmt = crowdFund.contributionOf(contributor);
            uint256 refundAmt = deductRefundFee(contribAmt); // side effects - fees being accounted
            contributor.transfer(refundAmt);
            emit Refund(block.timestamp, _myId, refundAmt, contributor);
        }
        _transferFeesToTreasury(_myId); // accounted fees go into the protocol treasury
    }

    function _proceedAfterLottery() internal onEmptyBalance {
        //console.log("* * * Settle Funding Round");
        // uint256 totalContributions = address(crowdFund).balance;
        //console.log("Total funds:   ", totalContributions);
        crowdFund.withdraw();
        // -- MY FEES (no transfers, only accounting)
        deductOwnerFee(); // fee applied on total collected funds
        deductLotteryFee(); // fixed fee

        // -- WINNER PAYMENT (operates on total collected amount)
        _payWinners(); // non-winner funds remain
        //console.log(
        // "After winners payout (refunds + prize) : ",
        // address(this).balance
        // );
        // -- FEES PAYMENT
        _transferFeesToTreasury(_myId);
    }

    /**
     * refunds + prizes, no fees
     *
     * Fair split: each winner receives a part of the prize
     * that is proportional to their own contribution
     * in relation to the other winners' contribution
     */
    function _payWinners() private {
        //console.log(" * * winners payout");
        address[] memory winners = new address[](winnerIdxs.length);
        uint256[] memory refunds = new uint256[](winnerIdxs.length);
        uint256 totalRefund;

        for (uint8 i = 0; i < winnerIdxs.length; i++) {
            // refunds & no fees
            winners[i] = crowdFund.contributors(winnerIdxs[i]);
            refunds[i] = crowdFund.contributionAtIdx(winnerIdxs[i]);
            totalRefund += refunds[i];
        }
        //console.log("totalRefund ", totalRefund);

        // prizes & no fees
        uint256 nonWinnerContributions = address(this).balance - totalRefund;
        //console.log(
        //     "Non-winner contrib total (WEI):  ",
        //     nonWinnerContributions
        // );
        // console.log("Prize % :                        ", prizePercentage);
        uint256 prize = (nonWinnerContributions * prizePercentage) / 10000;
        // console.log("Prize (WEI) :                    ", prize);
        // console.log("Left after payout: ", nonWinnerContributions - prize);

        // console.log("winner idxs: ");
        // printArrayUint256(winnerIdxs);
        for (uint8 i = 0; i < winnerIdxs.length; i++) {
            // INITIAL
            // uint256 prizePart = (prize * crowdFund.contributionAtIdx(i)) /
            //     totalRefund;

            // CORRECTED - helps prevent whale abuse
            // split prize evenly among winners regardless of their contributions
            uint256 prizePart = prize / winnerIdxs.length;

            // console.log("Prize part (WEI)   : ", prizePart, " to ", winners[i]);
            // console.log(
            //     "Amount: REFUNDS: ",
            //     refunds[i],
            //     " + PRIZEPART: ",
            //     prizePart
            // );
            // console.log("Total to transfer: ", refunds[i] + prizePart);
            // console.log("           Available: ", address(this).balance);
            payable(winners[i]).transfer(refunds[i] + prizePart);
            // console.log(
            //     "           left with balance: ",
            //     address(this).balance
            // );
        }
    }

    function _settleBenAndTokens() internal {
        _issueTokens();
        uint256 amount = address(this).balance;
        // console.log(" * * Beneficiary payment. Balance: ", amount);
        beneficiary.transfer(amount);
        emit PayBeneficiary(block.timestamp, _myId, amount, beneficiary);
    }

    /**
     * Create token contract & mint tokens to contributors.
     */
    function _issueTokens() private {
        //console.log(" * * Distributing Tokens");
        // create token specific to this round
        IAttraToken tk = IAttraToken(
            tokenFactory.createToken(tokenName, tokenSymbol, _myId)
        );

        // mint to all contributors except the winners
        uint256 howMany = crowdFund.lengthContributors();
        for (uint256 i = 0; i < howMany; i++) {
            address payable contributor = crowdFund.contributors(i);
            if (_isWinningIdx(i)) {
                continue;
            }
            uint256 amount = crowdFund.contributionOf(contributor);
            // emit an amount of tokens equal to the contribution (wei)
            // console.log(
            //     "mint token: receiver / amount: ",
            //     contributor,
            //     "/",
            //     amount
            // );
            tk.mintForContribution(contributor, amount);
        }
        //console.log("Tokens minted.");
        tokenAddress = address(tk);
    }

    function _isWinningIdx(uint256 idx) private view returns (bool) {
        for (uint8 i = 0; i < winnerIdxs.length; i++) {
            if (winnerIdxs[i] == idx) {
                return true;
            }
        }
        return false;
    }

    // ------------------------------------

    // -------------- MY MONEY ------------

    function withdraw(uint256 _amount) public onlyOwner {
        require(
            address(this).balance >= _amount,
            "balance too low for this withdrawal"
        );
        payable(owner()).transfer(_amount);
    }

    // ------------------------------------

    // ============== DEBUGGING / PUBLIC INTEREST

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function fundBalance() public view returns (uint256) {
        return address(crowdFund).balance;
    }

    function fundBalanceInUSD() public view returns (uint256) {
        return crowdFund.balanceInUSD();
    }

    function fundAddress() public view returns (address) {
        return address(crowdFund);
    }

    function ethPriceDecimals() public view returns (uint8) {
        return crowdFund.precision();
    }

    // function printArrayUint256(uint256[] memory _arr) private view {
    //     //console.log("LENGTH: ", _arr.length);
    //     for (uint256 i = 0; i < _arr.length; i++) {
    //         //console.log("[", i, "]:   ", _arr[i]);
    //     }
    // }

    // function printArrayAddresses(address[] memory _arr) private view {
    //     //console.log("LENGTH: ", _arr.length);
    //     for (uint256 i = 0; i < _arr.length; i++) {
    //         //console.log("[", i, "]:   ", _arr[i]);
    //     }
    // }
}

pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

interface IAttraToken {
    function mintForContribution(address _contributor, uint256 _amount)
        external;
}

pragma solidity ^0.8.7;

// SPDX-License-Identifier: MIT

interface IAttraTokenFactory {
    function createToken(
        string memory _name,
        string memory _symbol,
        uint256 _id
    ) external returns (address);
}

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol"; // https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/LinkTokenInterface.sol

/**
 * Manages details regarding the campaign lottery setup.
 * Interacts with Chainlink VRF
 * Base contract for an AttraCampaign, but has no implementation
 * for the raffle procedure itself.
 */
abstract contract Lottery is VRFConsumerBase {
    uint8 numberOfPicks;
    bytes32 keyHash;
    uint256 vrfFee;
    bytes32 public reqId; // for debugging only, TODO remove in production
    uint256 receivedRandomness;

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _vrfFee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyHash;
        vrfFee = _vrfFee;
    }

    function startLottery(uint256 _campaignId) internal {
        require(
            LINK.balanceOf(address(this)) >= vrfFee,
            "Not enough LINK to perform the lottery"
        );
        //console.log("Requested VRF randomness for campaign ", _campaignId);
        reqId = requestRandomness(keyHash, vrfFee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual
        override
    {
        receivedRandomness = randomness;
        _onReceivedRandomness();
    }

    function _onReceivedRandomness() internal virtual;

    function _expand(uint256 randomValue, uint8 n)
        internal
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint8 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function hasEnoughLink() internal view returns (bool) {
        return LINK.balanceOf(address(this)) >= vrfFee;
    }

    // ------------- SETTERS -------------

    function setKeyHash(bytes32 _keyHash) public {
        keyHash = _keyHash;
    }

    function setVrfFee(uint256 _vrfFee) public {
        vrfFee = _vrfFee;
    }
}

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * Keeps Attra balances cleaner and payments management less error-prown.
 * Any AttraCampaign knows the treasury and transfers collected fees to it.
 */
contract Treasury is Ownable {
    event TreasuryDeposit(uint256 timestamp, uint256 amount);
    event TreasuryWithdrawal(uint256 timestamp, uint256 amount);

    function withdrawTo(uint256 _amount, address payable receiver)
        public
        onlyOwner
    {
        require(
            address(this).balance >= _amount,
            "balance too low for this withdrawal"
        );
        receiver.transfer(_amount);
        emit TreasuryWithdrawal(block.timestamp, _amount);
    }

    receive() external payable {
        emit TreasuryDeposit(block.timestamp, msg.value);
    }
}