// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Withdrawable.sol";
import "./Lockable.sol";
import "./Payable.sol";
import "./String.sol";
import "./ExternalActor.sol";
import "./GetMetadata.sol";
import { Utils } from "./Utils.sol";

contract Gems is ERC1155, Ownable, VRFConsumerBase, ExternalActor, Withdrawable, Lockable, Payable {
  // Rules
  uint256 public mintCap = 1000; // NOTE: Set before release
  uint256 public mintPrice = 0.1 ether; // NOTE: Set before release
  uint256 public limitPerTransaction = 10; // NOTE: Set before release
  uint256 public amountMinted = 0;
  uint256 public numColors = 7;
  uint256 public lusterChance = 5; // Out of 100
  uint256[4] public levelWeights = [95, 88, 77, 66];

  // VRF
  bytes32 internal keyHash;
  uint256 internal fee;

  struct Gem {
    uint256 color;
    uint256 level;
    uint256 luster;
  }

  struct RequestData {
    address sender;
    uint256 amount;
  }

  mapping(uint256 => Gem) public _gemDetails;
  mapping(bytes32 => RequestData) private _requestToData;

  constructor(
    string memory _uri,
    address _LinkToken,
    address _VRFCoordinator,
    bytes32 _keyhash,
    uint256 _fee
  ) ERC1155(_uri) VRFConsumerBase(_VRFCoordinator, _LinkToken) {
    keyHash = _keyhash;
    fee = _fee;
  }

  function requestNewGems(address sender, uint256 amount) private {
    require(LINK.balanceOf(address(this)) >= fee, "NO_LINK");
    bytes32 requestId = requestRandomness(keyHash, fee);
    _requestToData[requestId] = RequestData(sender, amount);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomBase) internal override {
    uint256 amount = _requestToData[requestId].amount;

    for (uint256 i = 0; i < amount; i++) {
      uint256 level = Utils.getWeightedLevel(randomBase, i + 1, levelWeights);
      uint256 luster = Utils.getWeightedLuster(randomBase, i + 3, lusterChance);
      uint256 color = Utils.getRandomColor(randomBase, i + 2, numColors);
      uint256 tokenId = Utils.getTokenId(color, level, luster);

      _gemDetails[tokenId] = Gem(color, level, luster);
      _mint(_requestToData[requestId].sender, tokenId, 1, "");

      amountMinted++;
    }
  }

  function mintMany(uint256 amount) public payable {
    require(isActive, "SALE_CLOSED");
    require(amount <= limitPerTransaction, "TX_LIMIT");

    uint256 totalPrice = (amount * mintPrice);
    require(msg.value == totalPrice, "WRONG_AMOUNT");

    safeMintMany(amount);
  }

  function mintManyWithToken(uint256 amount, address tokenAddress) public {
    require(isActive, "SALE_CLOSED");
    require(amount <= limitPerTransaction, "TX_LIMIT");

    payWithToken(amount, tokenAddress);
    safeMintMany(amount);
  }

  function safeMintMany(uint256 amount) internal {
    uint256 newAmount = amountMinted + amount;
    require(newAmount <= mintCap, "CAP_REACHED");
    requestNewGems(msg.sender, amount);
  }

  function mintGem(
    uint256 color,
    uint256 level,
    uint256 luster,
    uint256 amount
  ) public {
    // FIXME: private !!!!
    uint256 tokenId = Utils.getTokenId(color, level, luster);
    _gemDetails[tokenId] = Gem(color, level, luster);
    _mint(msg.sender, tokenId, amount, "");
  }

  function burn(
    address sender,
    uint256 tokenId,
    uint256 amount
  ) external onlyAllowedBurners {
    _burn(sender, tokenId, amount);
  }

  function mint(
    address sender,
    uint256 tokenId,
    uint256 amount
  ) external onlyAllowedMinters {
    _mint(sender, tokenId, amount, "");
  }

  function mintRandom(address sender, uint256 amount) external onlyAllowedMinters {
    requestNewGems(sender, amount);
  }

  function getGemDetails(uint256 tokenId) public view returns (Gem memory) {
    return _gemDetails[tokenId];
  }

  function setRules(
    uint256 _mintCap,
    uint256 _mintPrice,
    uint256 _limitPerTransaction,
    uint256 _numColors
  ) public onlyOwner {
    require(!rulesLocked, "RULES_LOCKED");

    mintCap = _mintCap;
    mintPrice = _mintPrice;
    limitPerTransaction = _limitPerTransaction;
    numColors = _numColors;
  }

  function reserveGems(uint256 amount) public onlyOwner {
    safeMintMany(amount);
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    return
      GetMetadata.getMetadata(
        tokenId,
        _gemDetails[tokenId].color,
        _gemDetails[tokenId].level,
        _gemDetails[tokenId].luster
      );
  }

  function withdrawLink(uint256 amount) public onlyOwner {
    LINK.transfer(msg.sender, amount * 10**18);
  }

  function setLinkFee(uint256 _fee) public onlyOwner {
    fee = _fee;
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

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Withdrawable is Ownable {
  function withdraw(address payable _to) public onlyOwner {
    (bool sent, ) = _to.call{ value: address(this).balance }("");
    require(sent, "FAIL");
  }

  function withdrawToken(uint256 amount, address _tokenContract) public onlyOwner {
    IERC20 tokenContract = IERC20(_tokenContract);
    tokenContract.transfer(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Lockable is Ownable {
  bool public isActive = true;
  bool public interactionLocked = false;
  bool public rulesLocked = false;

  function flipState() public onlyOwner {
    require(!interactionLocked, "LOCKED");
    isActive = !isActive;
  }

  function lockState(uint256 confirm) public onlyOwner {
    require(!interactionLocked, "LOCKED");

    if (confirm == 100) {
      interactionLocked = true;
    }
  }

  function lockRules(uint256 confirm) public onlyOwner {
    if (!rulesLocked && confirm == 100) {
      rulesLocked = true;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Payable is Ownable {
  struct PaymentToken {
    uint256 mintPrice;
    bool enabled;
    IERC20 tokenContract;
  }

  mapping(address => PaymentToken) public _paymentTokens;

  function addPaymentToken(uint256 mintPrice, address tokenAddress) public onlyOwner {
    _paymentTokens[tokenAddress] = PaymentToken(mintPrice, true, IERC20(tokenAddress));
  }

  function removePaymentToken(address tokenAddress) public onlyOwner {
    _paymentTokens[tokenAddress].enabled = false;
  }

  function payWithToken(uint256 amount, address tokenAddress) internal {
    require(_paymentTokens[tokenAddress].enabled);

    uint256 price = amount * _paymentTokens[tokenAddress].mintPrice;

    _paymentTokens[tokenAddress].tokenContract.transferFrom(msg.sender, address(this), price);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library String {
  function toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return '0';
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ExternalActor is Ownable {
  mapping(address => bool) allowedMinters;
  mapping(address => bool) allowedBurners;

  bool locked = false;

  modifier onlyAllowedMinters() {
    _isAuthorizedMinter();
    _;
  }

  modifier onlyAllowedBurners() {
    _isAuthorizedBurner();
    _;
  }

  function authorize(
    address actor,
    bool allowMint,
    bool allowBurn
  ) public onlyOwner {
    require(!locked, "LOCKED_FOREVER");
    allowedMinters[actor] = allowMint;
    allowedBurners[actor] = allowBurn;
  }

  function _isAuthorizedMinter() internal view {
    require(allowedMinters[msg.sender], "UNAUTHORIZED");
  }

  function _isAuthorizedBurner() internal view {
    require(allowedBurners[msg.sender], "UNAUTHORIZED");
  }

  function lockActors() public onlyOwner {
    locked = true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './base64.sol';
import './String.sol';
import { Utils } from './Utils.sol';

library GetMetadata {
  function getMetadata(
    uint256 tokenId,
    uint256 color,
    uint256 level,
    uint256 luster
  ) external pure returns (string memory) {
    string[6] memory parts;

    (string memory colorCode, string memory colorName) = Utils.getColor(color);
    string memory shapeName = Utils.getShape(level);

    parts[
      0
    ] = '<svg width="512" height="512" viewBox="0 0 512 512" fill="none" xmlns="http://www.w3.org/2000/svg">';

    if (level == 1) {
      parts[
        1
      ] = '<path d="M256.32 105L82.6909 405.762H429.968L256.32 105Z" fill="';
      parts[
        3
      ] = '"/><path d="M256.32 221.617L183.668 347.462H328.973L256.32 221.617Z" fill="url(#paint0_linear_104_62)" fill-opacity="0.3"/><path d="M256.32 221.617V105L429.968 405.762L328.972 347.463L292.646 284.549L256.32 221.617Z" fill="white" fill-opacity="0.5"/><path d="M82.6909 405.762L183.668 347.463H328.973L429.968 405.762H82.6909Z" fill="url(#paint1_linear_104_62)" fill-opacity="0.6"/><path d="M82.6909 405.762L256.32 105V221.617L183.668 347.463L82.6909 405.762Z" fill="url(#paint2_linear_104_62)" fill-opacity="0.4"/><defs><linearGradient id="paint0_linear_104_62" x1="256.32" y1="221.617" x2="256.32" y2="347.462" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint1_linear_104_62" x1="256.329" y1="347.463" x2="256.329" y2="405.762" gradientUnits="userSpaceOnUse"><stop stop-opacity="0.75"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear_104_62" x1="256.021" y1="49.2817" x2="72.7168" y2="40.6628" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-color="#E2E2E2" stop-opacity="0"/></linearGradient></defs>';
    } else if (level == 2) {
      parts[
        1
      ] = '<path d="M448 255.713L255.705 63.4119L63.4105 255.713L255.705 448.013L448 255.713Z" fill="';
      parts[
        3
      ] = '"/><path d="M348.352 255.723L255.705 163.074L163.059 255.723L255.705 348.373L348.352 255.723Z" fill="url(#paint0_linear_104_68)" fill-opacity="0.3"/><path d="M255.714 163.07V63.4265L447.993 255.726H348.352L255.714 163.07Z" fill="white" fill-opacity="0.6"/><path d="M348.352 255.727H447.993L255.714 448.011V348.367L348.352 255.727Z" fill="url(#paint1_linear_104_68)" fill-opacity="0.4"/><path d="M255.714 348.367V448.011L63.4204 255.727H163.061L255.714 348.367Z" fill="url(#paint2_linear_104_68)" fill-opacity="0.6"/><path d="M163.061 255.726H63.4202L255.714 63.4261V163.07L163.061 255.726Z" fill="url(#paint3_linear_104_68)" fill-opacity="0.4"/><defs><linearGradient id="paint0_linear_104_68" x1="302.029" y1="209.399" x2="209.379" y2="302.045" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint1_linear_104_68" x1="239" y1="412" x2="360" y2="256" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear_104_68" x1="159.567" y1="255.727" x2="159.567" y2="448.011" gradientUnits="userSpaceOnUse"><stop stop-opacity="0.75"/><stop offset="1"/></linearGradient><linearGradient id="paint3_linear_104_68" x1="159.567" y1="63.4261" x2="311.69" y2="135.193" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient></defs>';
    } else if (level == 3) {
      parts[
        1
      ] = '<path d="M255.582 78.4375L69.1797 213.875L140.379 433.026H370.784L442 213.875L255.582 78.4375Z" fill="';
      parts[
        3
      ] = '"/><path d="M255.581 164.725L151.221 240.538L191.081 363.228H320.082L359.942 240.538L255.581 164.725Z" fill="url(#paint0_linear_104_75)" fill-opacity="0.4"/><path d="M255.582 78.4375V164.725L359.942 240.538L442 213.875L255.582 78.4375Z" fill="white" fill-opacity="0.6"/><path d="M69.1797 213.875L151.221 240.538L255.581 164.725V78.4375L69.1797 213.875Z" fill="url(#paint1_linear_104_75)" fill-opacity="0.4"/><path d="M442 213.875L359.942 240.538L320.082 363.228L370.784 433.026L442 213.875Z" fill="url(#paint2_linear_104_75)" fill-opacity="0.4"/><path d="M370.784 433.026L320.082 363.228H191.081L140.379 433.026H370.784Z" fill="black" fill-opacity="0.45"/><path d="M140.379 433.026L191.081 363.228L151.221 240.538L69.1797 213.875L140.379 433.026Z" fill="black" fill-opacity="0.3"/><defs><linearGradient id="paint0_linear_104_75" x1="255.581" y1="164.725" x2="255.581" y2="363.228" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint1_linear_104_75" x1="162.381" y1="78.4375" x2="301.668" y2="154.003" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear_104_75" x1="381.041" y1="213.875" x2="430.275" y2="332.088" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient></defs>';
    } else if (level == 4) {
      parts[
        1
      ] = '<path d="M403.669 147.671V364.994L255.834 473.665L108 364.994V147.671L255.834 39L403.669 147.671Z" fill="';
      parts[
        3
      ] = '"/><path d="M343.78 191.681V320.984L255.834 385.626L167.889 320.984V191.681L255.834 127.039L343.78 191.681Z" fill="url(#paint0_linear_104_84)" fill-opacity="0.4"/><path d="M255.834 127.039V39L403.669 147.671L343.78 191.681L255.834 127.039Z" fill="white" fill-opacity="0.6"/><path d="M343.78 320.984L403.669 364.994V147.671L343.78 191.681V320.984Z" fill="url(#paint1_linear_104_84)" fill-opacity="0.4"/><path d="M255.834 385.626L343.78 320.984L403.669 364.994L255.834 473.665V385.626Z" fill="url(#paint2_linear_104_84)" fill-opacity="0.4"/><path d="M167.871 320.984L255.834 385.626V473.665L108 364.994L167.871 320.984Z" fill="black" fill-opacity="0.4"/><path d="M167.871 191.681V320.984L108 364.994V147.671L167.871 191.681Z" fill="black" fill-opacity="0.3"/><path d="M255.834 39V127.039L167.871 191.681L108 147.671L255.834 39Z" fill="url(#paint3_linear_104_84)" fill-opacity="0.4"/><defs><linearGradient id="paint0_linear_104_84" x1="255.834" y1="127.039" x2="255.834" y2="385.626" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint1_linear_104_84" x1="363" y1="365" x2="263.328" y2="270.966" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear_104_84" x1="329.752" y1="320.984" x2="351.626" y2="412.393" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint3_linear_104_84" x1="181.917" y1="39" x2="300.213" y2="93.0385" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient></defs>';
    } else if (level == 5) {
      parts[
        1
      ] = '<path d="M255.81 35L391.95 194.9L425.64 342.42L365.83 443.35L255.81 477.8L145.81 443.37L86 342.42L119.64 194.9L255.81 35Z" fill="';
      parts[
        3
      ] = '"/><g style="mix-blend-mode:multiply"><path fill-rule="evenodd" clip-rule="evenodd" d="M255.81 171.04L183.18 256.31L165.24 334.92L197.15 388.8L255.82 407.14L314.49 388.8L346.39 334.96L328.46 256.35L255.81 171.06V171.04Z" fill="url(#paint0_linear_104_94)"/></g><path d="M255.81 35V171.04L328.46 256.33L391.96 194.9L255.81 35Z" fill="white" fill-opacity="0.6"/><path d="M328.46 256.33L391.96 194.9L425.63 342.41L346.39 334.94L328.46 256.33Z" fill="url(#paint1_linear_104_94)" fill-opacity="0.4"/><path d="M314.49 388.78L346.39 334.94L425.63 342.41L365.83 443.35L314.49 388.78Z" fill="url(#paint2_linear_104_94)" fill-opacity="0.4"/><g style="mix-blend-mode:multiply"><path d="M255.82 407.15L255.81 477.77L365.83 443.35L314.49 388.78L255.82 407.15Z" fill="#9F9F9F"/></g><path d="M197.15 388.81L145.81 443.35L255.81 477.77L255.82 407.15L197.15 388.81Z" fill="black" fill-opacity="0.5"/><g style="mix-blend-mode:multiply"><path d="M165.24 334.91L86 342.41L145.81 443.35L197.15 388.81L165.24 334.91Z" fill="#979797"/></g><path d="M119.68 194.9L86 342.41L165.24 334.91L183.18 256.31L119.68 194.9Z" fill="black" fill-opacity="0.3"/><path d="M255.81 35L119.68 194.9L183.18 256.31L255.81 171.04V35Z" fill="url(#paint3_linear_104_94)" fill-opacity="0.4"/><defs><linearGradient id="paint0_linear_104_94" x1="282" y1="129" x2="226" y2="407" gradientUnits="userSpaceOnUse"><stop stop-color="#838383"/><stop offset="1" stop-color="white"/></linearGradient><linearGradient id="paint1_linear_104_94" x1="377" y1="373" x2="362.51" y2="181.996" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear_104_94" x1="440" y1="297" x2="418.759" y2="468.012" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint3_linear_104_94" x1="77" y1="176" x2="240.447" y2="82.2632" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient></defs>';
    }

    parts[2] = colorCode;

    if (luster == 1) {
      parts[4] = '<path d="M224.402 34.0894L200.579 155.386L317.536 195.402L196.24 171.579L156.224 288.536L180.047 167.24L63.0895 127.223L184.386 151.047L224.402 34.0894Z" fill="url(#paint0_diamond_120_81)"/><path d="M401.974 158.055L389.557 234.555L462.017 262.052L385.516 249.634L358.02 322.094L370.437 245.594L297.977 218.097L374.478 230.515L401.974 158.055Z" fill="url(#paint1_diamond_120_81)"/><path d="M217.778 285.781L201.486 376.518L288.213 407.778L197.476 391.486L166.216 478.213L182.508 387.476L95.781 356.216L186.518 372.508L217.778 285.781Z" fill="url(#paint2_diamond_120_81)"/><defs><radialGradient id="paint0_diamond_120_81" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(190.313 161.313) rotate(-75.0206) scale(126.042)"><stop stop-color="white"/><stop offset="1" stop-color="white" stop-opacity="0"/></radialGradient><radialGradient id="paint1_diamond_120_81" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(379.997 240.075) rotate(-75.0206) scale(81.2582)"><stop stop-color="white"/><stop offset="1" stop-color="white" stop-opacity="0"/></radialGradient><radialGradient id="paint2_diamond_120_81" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(191.997 381.997) rotate(-75.0206) scale(95.3225)"><stop stop-color="white"/><stop offset="1" stop-color="white" stop-opacity="0"/></radialGradient></defs>';
    } else {
      parts[4] = '';
    }

    if (tokenId == 0) {
      parts[1] = '<path d="M222.316 73.8155L214.734 143.86L279.185 172.315L209.14 164.733L180.685 229.184L188.267 159.14L123.816 130.684L193.86 138.266L222.316 73.8155Z" fill="url(#paint0_diamond_2_165)"/><path d="M372.974 159.977L364.969 233.93L433.017 263.974L359.064 255.969L329.02 324.017L337.025 250.064L268.977 220.02L342.93 228.025L372.974 159.977Z" fill="url(#paint1_diamond_2_165)"/><path d="M227.778 241.781L218.387 328.534L298.213 363.778L211.46 354.387L176.216 434.213L185.607 347.46L105.781 312.216L192.534 321.607L227.778 241.781Z" fill="url(#paint2_diamond_2_165)"/><defs><radialGradient id="paint0_diamond_2_165" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(201.5 151.5) rotate(-75.0206) scale(76.9632)"><stop stop-color="white"/><stop offset="1"/></radialGradient><radialGradient id="paint1_diamond_2_165" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(350.997 241.997) rotate(-75.0206) scale(81.2582)"><stop stop-color="white"/><stop offset="1"/></radialGradient><radialGradient id="paint2_diamond_2_165" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(201.997 337.997) rotate(-75.0206) scale(95.3225)"><stop stop-color="white"/><stop offset="1"/></radialGradient></defs>';
      parts[2] = '';
      parts[3] = '';
      parts[4] = '';
    }

    parts[5] = '</svg>';

    string memory output = string(
      abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5])
    );

    string memory name;
    string memory description;
    string memory jsonString;

    if (tokenId == 0) {
      name = 'Gem dust';
      description = 'Used to craft gems.';

      jsonString = string(
        abi.encodePacked(
          '{"name": "',
          name,
          '", "description": "',
          description,
          '", "background_color" : "101922", "image": "data:image/svg+xml;base64,',
          Base64.encode(bytes(output)),
          '"}'
        )
      );
    } else {
      name = string(abi.encodePacked(luster == 1 ? 'Shiny ' : '', shapeName, ' ', colorName));

      // TODO: review copy
      if (color == 8 && level == 5 && luster == 1) {
        description = 'The rarest gem in existence.';
      } else if (color == 8 && level == 5) {
        description = 'A rare gem obtained only by the worthy.';
      } else if (color == 8) {
        description = 'A rare gem.';
      } else {
        description = 'A beautiful gem.';
      }

      // TODO: luster attribute (other type?)
      jsonString = string(
        abi.encodePacked(
          '{"name": "',
          name,
          '", "attributes": [ { "trait_type": "Level",  "value": ',
          String.toString(level),
          ' }, { "trait_type": "Luster",  "value": "',
          luster == 1 ? 'Shiny' : 'Common',
          '" }, { "trait_type": "Color",  "value": "',
          colorName,
          '" } ], "description": "',
          description,
          '", "background_color" : "101922", "image": "data:image/svg+xml;base64,',
          Base64.encode(bytes(output)),
          '"}'
        )
      );
    }

    string memory json = Base64.encode(bytes(jsonString));
    output = string(abi.encodePacked('data:application/json;base64,', json));
    return output;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Utils {
    function getColor(uint256 color)
    internal
    pure
    returns (string memory, string memory)
  {
    string memory colorName;
    string memory colorCode;

    if (color == 1) {
      colorCode = '#EBFF00'; // Yellow
      colorName = 'Topaz';
    } else if (color == 2) {
      colorCode = '#FFA800'; // Orange
      colorName = 'Amber';
    } else if (color == 3) {
      colorCode = '#EB1138'; // Red
      colorName = 'Ruby';
    } else if (color == 4) {
      colorCode = '#FA00FF'; // Purple
      colorName = 'Amethyst';
    } else if (color == 5) {
      colorCode = '#00C2FF'; // Blue
      colorName = 'Sapphire';
    } else if (color == 6) {
      colorCode = '#00FFFF'; // Teal
      colorName = 'Aquamarine';
    } else if (color == 7) {
      colorCode = '#00EE98'; // Green
      colorName = 'Emerald';
    } else if (color == 8) {
      colorCode = '#FFFFFF'; // White
      colorName = 'Diamond';
    } else {
      colorCode = '#000000'; // Void
      colorName = 'Bedrock';
    }

    return (colorCode, colorName);
  }

   function getShape(uint256 level)
    internal
    pure
    returns (string memory)
  {
    string memory shape;

    if (level == 1) {
      shape = 'Triangle';
    } else if (level == 2) {
      shape = 'Square';
    } else if (level == 3) {
      shape = 'Penta';
    } else if (level == 4) {
      shape = 'Hex';
    } else if (level == 5) {
      shape = 'Tear';
    }

    return shape;
  }

  function getTokenId(uint256 color, uint256 level, uint256 luster)
    internal
    pure
    returns (uint256)
  {
    return (100 * color) + (10 * level) + luster;
  }

  function getRandomSafe(uint256 randomNumber, uint256 salt) private pure returns(uint256) {
    return (uint256( keccak256(abi.encode(randomNumber, salt)) ) % 100) + 1;
  }

  function getFoundGem(uint256 randomNumber, uint256 salt, uint256 elapsed) internal pure returns (bool) {
    uint256 chances = elapsed / (7 * 3600 * 24 * 10);
    uint256 foundBase = getRandomSafe(randomNumber, salt);
    return foundBase < (chances * 100);
  }

  function getRandomColor(uint256 randomNumber, uint256 salt, uint256 numColors) internal pure returns (uint256) {
    uint256 colorBase = getRandomSafe(randomNumber, salt);
    return (colorBase % (numColors - 1)) + 1;
  }

  function getWeightedLevel(uint256 randomNumber, uint256 salt,  uint256[4] memory weights) internal pure returns (uint256) {
    uint256 level = getRandomSafe(randomNumber, salt);

    if (level > weights[0]) {
      level = 5;
    } else if (level > weights[1]) {
      level = 4;
    } else if (level > weights[2]) {
      level = 3;
    } else if (level > weights[3]) {
      level = 2;
    } else {
      level = 1;
    }

    return level;
  }

  function getWeightedLuster(uint256 randomNumber, uint256 salt, uint256 chance) internal pure returns (uint256) {
    return getRandomSafe(randomNumber, salt) > (100 - chance) ? 1 : 0;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/*
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

pragma solidity ^0.8.0;

library Base64 {
  bytes internal constant TABLE =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return '';

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}