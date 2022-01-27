// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./mixin/MixinOwnable.sol";
import "./HashBaseV2.sol";
import "./HashRegistryV2.sol";
import "./ERC1155Mintable.sol";

contract HashV2 is HashBaseV2 {
    uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;
    
    HashRegistryV2 public hashRegistry;
    ERC1155Mintable public immutable originalHash;

    mapping(uint => uint) public tokenTypeToSupply;
    mapping(uint => uint) public tokenTypeToMaxSupply;
    mapping(address => bool) public minters;

    constructor (
      string memory name_,
      string memory symbol_,
      address exchangesProxy_,
      address originalHash_
    ) HashBaseV2(name_, symbol_, exchangesProxy_) {
      originalHash = ERC1155Mintable(originalHash_);
    }

  modifier onlyMinter() {
    require(minters[msg.sender] == true, "msg.sender is not minter");
    _;
  }

  function _getNonFungibleBaseType(uint256 id) pure internal returns (uint256) {
    return id & TYPE_MASK;
  }

  modifier onlyUnderMaxSupply(uint tokenType, uint mintAmount) {
    require(tokenTypeToSupply[tokenType] + mintAmount <= tokenTypeToMaxSupply[tokenType], 'max supply minted');
    _;
  }

  function setHashRegistry(address _hashRegistry) public onlyOwner {
    hashRegistry = HashRegistryV2(_hashRegistry);
  }
  
  function setMinterStatus(address _minter, bool status) public onlyOwner {
    minters[_minter] = status;
  }

  function createNewSeason(uint _tokenType, uint maxSupply) public onlyOwner {
    require(tokenTypeToMaxSupply[_tokenType] == 0, "can't modify already created season");
    tokenTypeToMaxSupply[_tokenType] = maxSupply;
  }

  function mint(address to, uint tokenType, uint[] calldata txHashes) public onlyMinter onlyUnderMaxSupply(tokenType, txHashes.length) {
    uint256[] memory tokenIds = new uint256[](txHashes.length);
    for (uint256 i = 0; i < txHashes.length; ++i) {
      uint256 index = tokenTypeToSupply[tokenType] + 1 + i;
      uint256 tokenId  = tokenType | index;
      tokenIds[i] = tokenId;
      _safeMint(to, tokenId);
    }
    hashRegistry.writeToRegistry(tokenIds, txHashes);
    tokenTypeToSupply[tokenType] = tokenTypeToSupply[tokenType] + txHashes.length;
  }

  function migrate(address to, uint[] calldata ids) public {
    for (uint i = 0; i < ids.length; ++i) {
      // burn original hash erc1155
      originalHash.safeTransferFrom(to, address(0xdead), ids[i], 1, "");
      _safeMint(to, ids[i]);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./interface/IERC721.sol";
import "./interface/IERC721Receiver.sol";
import "./interface/IERC721Metadata.sol";
import "./utils/Address.sol";
import "./utils/Context.sol";
import "./utils/Strings.sol";
import "./ERC165.sol";

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
pragma solidity ^0.7.3;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./WhitelistExchangesProxy.sol";
import "./mixin/MixinOwnable.sol";

contract HashBaseV2 is Ownable, ERC721 {

    WhitelistExchangesProxy public immutable exchangesProxy;
    string public baseMetadataURI;
    string public contractURI;

    constructor (
      string memory name_,
      string memory symbol_,
      address exchangesProxy_
    ) ERC721(name_, symbol_) {
      exchangesProxy = WhitelistExchangesProxy(exchangesProxy_);
    }

    function setBaseMetadataURI(string memory _baseMetadataURI) public onlyOwner {
      baseMetadataURI = _baseMetadataURI;
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    function _baseURI() override internal view virtual returns (string memory) {
      return baseMetadataURI;
    }

    function isApprovedForAllExchangesProxy(address spender) public view returns (bool) {
      return exchangesProxy.isAddressWhitelisted(spender);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) override internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender)) || isApprovedForAllExchangesProxy(spender);
    } 
}

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./library/LibSafeMath.sol";
import "./mixin/MixinOwnable.sol";
import "./ERC721.sol";
import "./mixin/MixinOwnable.sol";
import "./HashRegistry.sol";
import "./ERC1155Mintable.sol";
import "./HashV2.sol";

contract HashRegistryV2 is Ownable {
  uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;

  HashV2 public immutable hashV2;
  ERC1155Mintable public immutable originalHash;
  HashRegistry public immutable originalHashRegistry;

  mapping(uint256 => uint256) private tokenIdToTxHash_;
  mapping(uint256 => uint256) private txHashToTokenId_;
  mapping(address => bool) public permissedWriters;

  constructor(
    address originalHashRegistry_,
    address originalHash_,
    address hashV2_
  ) {
    originalHashRegistry = HashRegistry(originalHashRegistry_);
    originalHash = ERC1155Mintable(originalHash_);
    hashV2 = HashV2(hashV2_);
  }

  event UpdatedRegistry(
      uint256 tokenId,
      uint256 txHash
  );

  modifier onlyIfPermissed(address writer) {
    require(permissedWriters[writer] == true, "writer can't write to registry");
    _;
  }

  function updatePermissedWriterStatus(address _writer, bool status) public onlyOwner {
    permissedWriters[_writer] = status;
  }

  function writeToRegistry(uint256[] memory tokenIds, uint256[] memory txHashes) public onlyIfPermissed(msg.sender) {
    require(tokenIds.length == txHashes.length, "tokenIds and txHashes size mismatch");
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];
      uint256 txHash = txHashes[i];
      require(txHashToTokenId_[txHash] == 0, 'txHash already exists');
      require(tokenIdToTxHash_[tokenId] == 0, 'tokenId already exists');
      tokenIdToTxHash_[tokenId] = txHash;
      txHashToTokenId_[txHash] = tokenId;
      emit UpdatedRegistry(tokenId, txHash); 
    }
  }

  function tokenIdToTxHash(uint id) public view returns (uint256) {
    if (tokenIdToTxHash_[id] == 0 && originalHashRegistry.tokenIdToTxHash(id) != 0) {
      return originalHashRegistry.tokenIdToTxHash(id); 
    }
    return tokenIdToTxHash_[id]; 
  }

  function txHashToTokenId(uint txHash) public view returns (uint256) {
    if (txHashToTokenId_[txHash] == 0 && originalHashRegistry.txHashToTokenId(txHash) != 0) {
      return originalHashRegistry.txHashToTokenId(txHash); 
    }
    return txHashToTokenId_[txHash]; 
  }

  function _getNonFungibleBaseType(uint256 id) pure internal returns (uint256) {
    return id & TYPE_MASK;
  }

  function isMigrated(uint id) public view returns (bool) {
    uint tokenType = _getNonFungibleBaseType(id);
    try hashV2.ownerOf(id) returns (address owner) {
      return owner != address(0) && (originalHash.ownerOf(id) == address(0xdead));
    }
    catch (bytes memory _err) {
      return false;
    }
  }

  function ownerOf(uint id) public view returns (address) {
    uint tokenType = _getNonFungibleBaseType(id);
    address oldOwner = originalHash.ownerOf(id);
    try hashV2.ownerOf(id) returns (address owner) {
      if (owner == address(0) && oldOwner != address(0)) {
        return oldOwner;
      }
      return owner;
    }
    catch (bytes memory _err) {
      return oldOwner;
    }
  }

  function ownerOfByTxHash(uint txHash) public view returns (address) {
    uint id = txHashToTokenId(txHash);
    return ownerOf(id);
  } 
}

pragma solidity ^0.7.3;

import "./library/LibSafeMath.sol";
import "./library/LibAddress.sol";
import "./ERC1155.sol";
import "./interface/IERC1155Mintable.sol";
import "./mixin/MixinOwnable.sol";
import "./mixin/MixinContractURI.sol";
import "./mixin/MixinTokenURI.sol";

/// @dev Mintable form of ERC1155
/// Shows how easy it is to mint new items
contract ERC1155Mintable is
    IERC1155Mintable,
    ERC1155,
    MixinContractURI,
    MixinTokenURI
{
    using LibSafeMath for uint256;
    using LibAddress for address;

    uint256 internal nonce;

    /// mapping from token to max index
    mapping (uint256 => uint256) public maxIndex;

    mapping (uint256 => mapping(address => bool)) internal creatorApproval;

    modifier onlyCreator(uint256 _id) {
        require(creatorApproval[_id][msg.sender], "not an approved creator of id");
        _;
    }

    function setCreatorApproval(uint256 id, address creator, bool status) external onlyCreator(id) {
        creatorApproval[id][creator] = status;
    }

    /// @dev creates a new token
    /// @param isNF is non-fungible token
    /// @return type_ of token (a unique identifier)
    function create(
        bool isNF
    )
        external
        override
        onlyOwner()
        returns (uint256 type_)
    {
        // Store the type in the upper 128 bits
        type_ = (++nonce << 128);

        // Set a flag if this is an NFI.
        if (isNF) {
            type_ = type_ | TYPE_NF_BIT;
        }

        creatorApproval[type_][msg.sender] = true;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(
            msg.sender,
            address(0x0),
            address(0x0),
            type_,
            0
        );

        emit URI(uri(type_), type_);
    }

    /// @dev creates a new token
    /// @param type_ of token
    function createWithType(
        uint256 type_
    )
        external
        onlyOwner()
    {

        creatorApproval[type_][msg.sender] = true;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(
            msg.sender,
            address(0x0),
            address(0x0),
            type_,
            0
        );

        emit URI(uri(type_), type_);
    }

    /// @dev mints fungible tokens
    /// @param id token type
    /// @param to beneficiaries of minted tokens
    /// @param quantities amounts of minted tokens
    function mintFungible(
        uint256 id,
        address[] calldata to,
        uint256[] calldata quantities
    )
        external
        override
        onlyCreator(id)
    {
        // sanity checks
        require(
            isFungible(id),
            "TRIED_TO_MINT_FUNGIBLE_FOR_NON_FUNGIBLE_TOKEN"
        );

        // mint tokens
        for (uint256 i = 0; i < to.length; ++i) {
            // cache to reduce number of loads
            address dst = to[i];
            uint256 quantity = quantities[i];

            // Grant the items to the caller
            balances[id][dst] = quantity.safeAdd(balances[id][dst]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(
                msg.sender,
                address(0x0),
                dst,
                id,
                quantity
            );

            // if `to` is a contract then trigger its callback
            if (dst.isContract()) {
                bytes4 callbackReturnValue = IERC1155Receiver(dst).onERC1155Received(
                    msg.sender,
                    msg.sender,
                    id,
                    quantity,
                    ""
                );
                require(
                    callbackReturnValue == ERC1155_RECEIVED,
                    "BAD_RECEIVER_RETURN_VALUE"
                );
            }
        }
    }

    /// @dev mints a non-fungible token
    /// @param type_ token type
    /// @param to beneficiaries of minted tokens
    function mintNonFungible(
        uint256 type_,
        address[] calldata to
    )
        external
        override
        onlyCreator(type_)
    {
        require(
            isNonFungible(type_),
            "TRIED_TO_MINT_NON_FUNGIBLE_FOR_FUNGIBLE_TOKEN"
        );

        // Index are 1-based.
        uint256 index = maxIndex[type_] + 1;

        for (uint256 i = 0; i < to.length; ++i) {
            // cache to reduce number of loads
            address dst = to[i];
            uint256 id  = type_ | index + i;

            nfOwners[id] = dst;

            // You could use base-type id to store NF type balances if you wish.
            balances[type_][dst] = balances[type_][dst].safeAdd(1);

            emit TransferSingle(msg.sender, address(0x0), dst, id, 1);

            // if `to` is a contract then trigger its callback
            if (dst.isContract()) {
                bytes4 callbackReturnValue = IERC1155Receiver(dst).onERC1155Received(
                    msg.sender,
                    msg.sender,
                    id,
                    1,
                    ""
                );
                require(
                    callbackReturnValue == ERC1155_RECEIVED,
                    "BAD_RECEIVER_RETURN_VALUE"
                );
            }
        }

        // record the `maxIndex` of this nft type
        // this allows us to mint more nft's of this type in a subsequent call.
        maxIndex[type_] = to.length.safeAdd(maxIndex[type_]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IERC165.sol";

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

pragma solidity ^0.7.3;

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

pragma solidity ^0.7.3;

import "./IERC721.sol";

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

pragma solidity ^0.7.3;

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

pragma solidity ^0.7.3;

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

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

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

pragma solidity ^0.7.3;

import "./interface/IERC165.sol";

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

pragma solidity ^0.7.3;

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

pragma solidity ^0.7.3;

import "./mixin/MixinOwnable.sol";

contract WhitelistExchangesProxy is Ownable {
    mapping(address => bool) internal proxies;

    bool public paused = true;
    
    function setPaused(bool newPaused) external onlyOwner() {
        paused = newPaused;
    }

    function updateProxyAddress(address proxy, bool status) external onlyOwner() {
        proxies[proxy] = status;
    }

    function isAddressWhitelisted(address proxy) external view returns (bool) {
        if (paused) {
            return false;
        } else {
            return proxies[proxy];
        }
    }
}

pragma solidity ^0.7.3;

import "./LibRichErrors.sol";
import "./LibSafeMathRichErrors.sol";

library LibSafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b == 0) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b > a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                a,
                b
            ));
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

pragma solidity ^0.7.3;

import "./library/LibSafeMath.sol";
import "./ERC1155Mintable.sol";
import "./mixin/MixinOwnable.sol";

contract HashRegistry is Ownable {
  using LibSafeMath for uint256;

  ERC1155Mintable public mintableErc1155;

  mapping(uint256 => uint256) public tokenIdToTxHash;
  mapping(uint256 => uint256) public txHashToTokenId;
  mapping(address => bool) public permissedWriters;

  constructor(
    address _mintableErc1155
  ) {
    permissedWriters[msg.sender] = true;
    mintableErc1155 = ERC1155Mintable(_mintableErc1155);
  }

  event UpdatedRegistry(
      uint256 tokenId,
      uint256 txHash
  );

  modifier onlyIfPermissed(address writer) {
    require(permissedWriters[writer] == true, "writer can't write to registry");
    _;
  }

  function updatePermissedWriterStatus(address _writer, bool status) public onlyIfPermissed(msg.sender) {
    permissedWriters[_writer] = status;
  }

  function writeToRegistry(uint256[] memory tokenIds, uint256[] memory txHashes) public onlyIfPermissed(msg.sender) {
    require(tokenIds.length == txHashes.length, "tokenIds and txHashes size mismatch");
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      uint256 tokenId = tokenIds[i];
      uint256 txHash = txHashes[i];
      require(mintableErc1155.ownerOf(tokenId) != address(0), 'token does not exist');
      require(txHashToTokenId[txHash] == 0, 'txHash already exists');
      require(tokenIdToTxHash[tokenId] == 0, 'tokenId already exists');
      tokenIdToTxHash[tokenId] = txHash;
      txHashToTokenId[txHash] = tokenId;
      emit UpdatedRegistry(tokenId, txHash); 
    }
  }
}

pragma solidity ^0.7.3;

library LibRichErrors {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR =
        0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(
        string memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

pragma solidity ^0.7.3;


library LibSafeMathRichErrors {

    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR =
        0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR =
        0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_BINOP_ERROR_SELECTOR,
            errorCode,
            a,
            b
        );
    }

    function Uint256DowncastError(
        DowncastErrorCodes errorCode,
        uint256 a
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_DOWNCAST_ERROR_SELECTOR,
            errorCode,
            a
        );
    }
}

pragma solidity ^0.7.3;


/**
 * Utility library of inline functions on addresses
 */
library LibAddress {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

pragma solidity ^0.7.3;

import "./library/LibSafeMath.sol";
import "./library/LibAddress.sol";
import "./interface/IERC1155.sol";
import "./interface/IERC1155Receiver.sol";
import "./mixin/MixinNonFungibleToken.sol";
import "./mixin/MixinOwnable.sol";
import "./WhitelistExchangesProxy.sol";

contract ERC1155 is
    IERC1155,
    MixinNonFungibleToken,
    Ownable
{
    using LibAddress for address;
    using LibSafeMath for uint256;

    // selectors for receiver callbacks
    bytes4 constant public ERC1155_RECEIVED       = 0xf23a6e61;
    bytes4 constant public ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

    address public exchangesRegistry;

    function setExchangesRegistry(address newExchangesRegistry) external onlyOwner() {
        exchangesRegistry = newExchangesRegistry;
    }

    /// @notice Transfers value amount of an _id from the _from address to the _to address specified.
    /// @dev MUST emit TransferSingle event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if balance of sender for token `_id` is lower than the `_value` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155Received` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
    /// @param from    Source address
    /// @param to      Target address
    /// @param id      ID of the token type
    /// @param value   Transfer amount
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        override
        external
    {
        // sanity checks
        require(
            to != address(0x0),
            "CANNOT_TRANSFER_TO_ADDRESS_ZERO"
        );
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "INSUFFICIENT_ALLOWANCE"
        );

        // perform transfer
        if (isNonFungible(id)) {
            require(
                    value == 1,
                    "AMOUNT_EQUAL_TO_ONE_REQUIRED"
            );
            require(
                nfOwners[id] == from,
                "NFT_NOT_OWNED_BY_FROM_ADDRESS"
            );
            nfOwners[id] = to;
            // You could keep balance of NF type in base type id like so:
            // uint256 baseType = getNonFungibleBaseType(_id);
            // balances[baseType][_from] = balances[baseType][_from].safeSub(_value);
            // balances[baseType][_to]   = balances[baseType][_to].safeAdd(_value);
        } else {
            balances[id][from] = balances[id][from].safeSub(value);
            balances[id][to] = balances[id][to].safeAdd(value);
        }
        emit TransferSingle(msg.sender, from, to, id, value);

        // if `to` is a contract then trigger its callback
        if (to.isContract()) {
            bytes4 callbackReturnValue = IERC1155Receiver(to).onERC1155Received(
                msg.sender,
                from,
                id,
                value,
                data
            );
            require(
                callbackReturnValue == ERC1155_RECEIVED,
                "BAD_RECEIVER_RETURN_VALUE"
            );
        }
    }

    /// @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
    /// @dev MUST emit TransferBatch event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if length of `_ids` is not the same as length of `_values`.
    ///  MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_values` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
    /// @param from    Source addresses
    /// @param to      Target addresses
    /// @param ids     IDs of each token type
    /// @param values  Transfer amounts per token type
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        override
        external
    {
        // sanity checks
        require(
            to != address(0x0),
            "CANNOT_TRANSFER_TO_ADDRESS_ZERO"
        );
        require(
            ids.length == values.length,
            "TOKEN_AND_VALUES_LENGTH_MISMATCH"
        );

        // Only supporting a global operator approval allows us to do
        // only 1 check and not to touch storage to handle allowances.
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "INSUFFICIENT_ALLOWANCE"
        );

        // perform transfers
        for (uint256 i = 0; i < ids.length; ++i) {
            // Cache value to local variable to reduce read costs.
            uint256 id = ids[i];
            uint256 value = values[i];

            if (isNonFungible(id)) {
                require(
                    value == 1,
                    "AMOUNT_EQUAL_TO_ONE_REQUIRED"
                );
                require(
                    nfOwners[id] == from,
                    "NFT_NOT_OWNED_BY_FROM_ADDRESS"
                );
                nfOwners[id] = to;
            } else {
                balances[id][from] = balances[id][from].safeSub(value);
                balances[id][to] = balances[id][to].safeAdd(value);
            }
        }
        emit TransferBatch(msg.sender, from, to, ids, values);

        // if `to` is a contract then trigger its callback
        if (to.isContract()) {
            bytes4 callbackReturnValue = IERC1155Receiver(to).onERC1155BatchReceived(
                msg.sender,
                from,
                ids,
                values,
                data
            );
            require(
                callbackReturnValue == ERC1155_BATCH_RECEIVED,
                "BAD_RECEIVER_RETURN_VALUE"
            );
        }
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator  Address to add to the set of authorized operators
    /// @param approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external override {
        operatorApproval[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param owner     The owner of the Tokens
    /// @param operator  Address of authorized operator
    /// @return           True if the operator is approved, false if not
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        bool approved = operatorApproval[owner][operator];
        if (!approved && exchangesRegistry != address(0)) {
            return WhitelistExchangesProxy(exchangesRegistry).isAddressWhitelisted(operator) == true;
        }
        return approved;
    }

    /// @notice Get the balance of an account's Tokens.
    /// @param owner  The address of the token holder
    /// @param id     ID of the Token
    /// @return        The _owner's balance of the Token type requested
    function balanceOf(address owner, uint256 id) external override view returns (uint256) {
        if (isNonFungibleItem(id)) {
            return nfOwners[id] == owner ? 1 : 0;
        }
        return balances[id][owner];
    }

    /// @notice Get the balance of multiple account/token pairs
    /// @param owners The addresses of the token holders
    /// @param ids    ID of the Tokens
    /// @return balances_       The _owner's balance of the Token types requested
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external override view returns (uint256[] memory balances_) {
        // sanity check
        require(
            owners.length == ids.length,
            "OWNERS_AND_IDS_MUST_HAVE_SAME_LENGTH"
        );

        // get balances
        balances_ = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; ++i) {
            uint256 id = ids[i];
            if (isNonFungibleItem(id)) {
                balances_[i] = nfOwners[id] == owners[i] ? 1 : 0;
            } else {
                balances_[i] = balances[id][owners[i]];
            }
        }

        return balances_;
    }

    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
        return true;
        }
        return false;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.7.3;

import "./IERC1155.sol";


/// @dev Mintable form of ERC1155
/// Shows how easy it is to mint new items
interface IERC1155Mintable is
    IERC1155
{

    /// @dev creates a new token
    /// @param isNF is non-fungible token
    /// @return type_ of token (a unique identifier)
    function create(
        bool isNF
    )
        external
        returns (uint256 type_);

    /// @dev mints fungible tokens
    /// @param id token type
    /// @param to beneficiaries of minted tokens
    /// @param quantities amounts of minted tokens
    function mintFungible(
        uint256 id,
        address[] calldata to,
        uint256[] calldata quantities
    )
        external;

    /// @dev mints a non-fungible token
    /// @param type_ token type
    /// @param to beneficiaries of minted tokens
    function mintNonFungible(
        uint256 type_,
        address[] calldata to
    )
        external;
}

pragma solidity ^0.7.3;

import "./MixinOwnable.sol";

contract MixinContractURI is Ownable {
    string public contractURI;

    function setContractURI(string calldata newContractURI) external onlyOwner() {
        contractURI = newContractURI;
    }
}

pragma solidity ^0.7.3;

import "./MixinOwnable.sol";
import "../library/LibString.sol";

contract MixinTokenURI is Ownable {
    using LibString for string;

    string public baseMetadataURI = "";

    function setBaseMetadataURI(string memory newBaseMetadataURI) public onlyOwner() {
        baseMetadataURI = newBaseMetadataURI;
    }

    function uri(uint256 _id) public view returns (string memory) {
        return LibString.strConcat(
        baseMetadataURI,
        LibString.uint2hexstr(_id)
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.7.3;

/// @title ERC-1155 Multi Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
/// Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 {

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    /// Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define a token ID with no initial balance, the contract SHOULD emit the TransferSingle event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    ///Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /// @dev MUST emit when an approval is updated.
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /// @dev MUST emit when the URI is updated for a token ID.
    /// URIs are defined in RFC 3986.
    /// The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema".
    event URI(
        string _value,
        uint256 indexed _id
    );

    /// @notice Transfers value amount of an _id from the _from address to the _to address specified.
    /// @dev MUST emit TransferSingle event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if balance of sender for token `_id` is lower than the `_value` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155Received` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
    /// @param from    Source address
    /// @param to      Target address
    /// @param id      ID of the token type
    /// @param value   Transfer amount
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external;

    /// @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
    /// @dev MUST emit TransferBatch event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if length of `_ids` is not the same as length of `_values`.
    ///  MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_values` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
    /// @param from    Source addresses
    /// @param to      Target addresses
    /// @param ids     IDs of each token type
    /// @param values  Transfer amounts per token type
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external;

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator  Address to add to the set of authorized operators
    /// @param approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param owner     The owner of the Tokens
    /// @param operator  Address of authorized operator
    /// @return           True if the operator is approved, false if not
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Get the balance of an account's Tokens.
    /// @param owner  The address of the token holder
    /// @param id     ID of the Token
    /// @return        The _owner's balance of the Token type requested
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /// @notice Get the balance of multiple account/token pairs
    /// @param owners The addresses of the token holders
    /// @param ids    ID of the Tokens
    /// @return balances_ The _owner's balance of the Token types requested
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    )
        external
        view
        returns (uint256[] memory balances_);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.7.3;


interface IERC1155Receiver {

    /// @notice Handle the receipt of a single ERC1155 token type
    /// @dev The smart contract calls this function on the recipient
    /// after a `safeTransferFrom`. This function MAY throw to revert and reject the
    /// transfer. Return of other than the magic value MUST result in the
    ///transaction being reverted
    /// Note: the contract address is always the message sender
    /// @param operator  The address which called `safeTransferFrom` function
    /// @param from      The address which previously owned the token
    /// @param id        An array containing the ids of the token being transferred
    /// @param value     An array containing the amount of tokens being transferred
    /// @param data      Additional data with no specified format
    /// @return          `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /// @notice Handle the receipt of multiple ERC1155 token types
    /// @dev The smart contract calls this function on the recipient
    /// after a `safeTransferFrom`. This function MAY throw to revert and reject the
    /// transfer. Return of other than the magic value MUST result in the
    /// transaction being reverted
    /// Note: the contract address is always the message sender
    /// @param operator  The address which called `safeTransferFrom` function
    /// @param from      The address which previously owned the token
    /// @param ids       An array containing ids of each token being transferred
    /// @param values    An array containing amounts of each token being transferred
    /// @param data      Additional data with no specified format
    /// @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

pragma solidity ^0.7.3;


contract MixinNonFungibleToken {
    uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;

    uint256 constant internal NF_INDEX_MASK = uint128(~0);

    uint256 constant internal TYPE_NF_BIT = 1 << 255;

    mapping (uint256 => address) internal nfOwners;

    /// @dev Returns true if token is non-fungible
    function isNonFungible(uint256 id) public pure returns(bool) {
        return id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    /// @dev Returns true if token is fungible
    function isFungible(uint256 id) public pure returns(bool) {
        return id & TYPE_NF_BIT == 0;
    }

    /// @dev Returns index of non-fungible token
    function getNonFungibleIndex(uint256 id) public pure returns(uint256) {
        return id & NF_INDEX_MASK;
    }

    /// @dev Returns base type of non-fungible token
    function getNonFungibleBaseType(uint256 id) public pure returns(uint256) {
        return id & TYPE_MASK;
    }

    /// @dev Returns true if input is base-type of a non-fungible token
    function isNonFungibleBaseType(uint256 id) public pure returns(bool) {
        // A base type has the NF bit but does not have an index.
        return (id & TYPE_NF_BIT == TYPE_NF_BIT) && (id & NF_INDEX_MASK == 0);
    }

    /// @dev Returns true if input is a non-fungible token
    function isNonFungibleItem(uint256 id) public pure returns(bool) {
        // A base type has the NF bit but does has an index.
        return (id & TYPE_NF_BIT == TYPE_NF_BIT) && (id & NF_INDEX_MASK != 0);
    }

    /// @dev returns owner of a non-fungible token
    function ownerOf(uint256 id) public view returns (address) {
        return nfOwners[id];
    }
}

pragma solidity ^0.7.3;

library LibString {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function uint2hexstr(uint i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            uint curr = (i & mask);
            bstr[k--] = curr > 9 ? byte(uint8(55 + curr)) : byte(uint8(48 + curr));
            i = i >> 4;
        }
        return string(bstr);
    }
}