// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "sol-temple/src/tokens/ERC721.sol";
import "sol-temple/src/utils/Auth.sol";
import "sol-temple/src/utils/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Loodles
 * @author naomsa <https://twitter.com/naomsa666>
 */
contract Loodles is Auth, Pausable, ERC721("Loodles", "LOODLE") {
  using Strings for uint256;
  using MerkleProof for bytes32[];

  /// @notice Max supply.
  uint256 public constant LOODLES_MAX = 5000;
  /// @notice Max amount per claim (not whitelist).
  uint256 public constant LOODLES_PER_TX = 10;
  /// @notice Max amount per whitelist claim.
  uint256 public constant LOODLES_PER_WHITELIST = 2;
  /// @notice Claim price.
  uint256 public constant LOODLES_PRICE = 0.045 ether;
  /// @notice Claim price for Doodles and Lemon Friends holders.
  uint256 public constant LOODLES_PRICE_HOLDER = 0.035 ether;

  /// @notice 0 = CLOSED, 1 = WHITELIST, 2 = PUBLIC.
  uint256 public saleState;

  /// @notice Metadata base URI.
  string public baseURI;
  /// @notice Metadata URI extension.
  string public baseExtension;
  /// @notice Unrevealed metadata URI.
  string public unrevealedURI;

  /// @notice Whitelist merkle root.
  bytes32 public merkleRoot;
  /// @notice Whitelist mints per address.
  mapping(address => uint256) public whitelistMinted;

  /// @notice OpenSea proxy registry.
  ProxyRegistry public opensea;
  /// @notice LooksRare marketplace transfer manager.
  address public looksrare;
  /// @notice Check if marketplaces pre-approve is enabled.
  bool public marketplacesApproved = true;

  constructor(
    string memory unrevealedURI_,
    bytes32 merkleRoot_,
    ProxyRegistry opensea_,
    address looksrare_
  ) {
    unrevealedURI = unrevealedURI_;
    merkleRoot = merkleRoot_;
    opensea = opensea_;
    looksrare = looksrare_;

    _safeMint(msg.sender, 0);
  }

  /// @notice Claim one or more tokens.
  function claim(uint256 amount_) external payable {
    uint256 supply = totalSupply();
    require(supply + amount_ <= LOODLES_MAX, "Max supply exceeded");
    if (msg.sender != owner()) {
      require(saleState == 2, "Public sale is not open");
      require(amount_ > 0 && amount_ <= LOODLES_PER_TX, "Invalid claim amount");
      require(msg.value == claimCost(msg.sender) * amount_, "Invalid ether amount");
    }

    for (uint256 i = 0; i < amount_; i++) _safeMint(msg.sender, supply++);
  }

  /// @notice Claim one or more tokens for whitelisted user.
  function claimWhitelist(uint256 amount_, bytes32[] memory proof_) external payable {
    uint256 supply = totalSupply();
    require(supply + amount_ <= LOODLES_MAX, "Max supply exceeded");
    if (msg.sender != owner()) {
      require(saleState == 1, "Whitelist sale is not open");
      require(amount_ > 0 && amount_ + whitelistMinted[msg.sender] <= LOODLES_PER_WHITELIST, "Invalid claim amount");
      require(msg.value == claimCost(msg.sender) * amount_, "Invalid ether amount");
      require(isWhitelisted(msg.sender, proof_), "Invalid proof");
    }

    whitelistMinted[msg.sender] += amount_;
    for (uint256 i = 0; i < amount_; i++) _safeMint(msg.sender, supply++);
  }

  /// @notice Check users claim price based on their Doodles and Lemon Friends balance.
  function claimCost(address user_) public view returns (uint256) {
    if (
      ERC721(0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e).balanceOf(user_) > 0 ||
      ERC721(0x0B22fE0a2995C5389AC093400e52471DCa8BB48a).balanceOf(user_) > 0
    ) return LOODLES_PRICE_HOLDER;
    else return LOODLES_PRICE;
  }

  /// @notice Retrieve if `user_` is whitelisted based on his `proof_`.
  function isWhitelisted(address user_, bytes32[] memory proof_) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(user_));
    return proof_.verify(merkleRoot, leaf);
  }

  /**
   * @notice See {IERC721-tokenURI}.
   * @dev In order to make a metadata reveal, there must be an unrevealedURI string, which
   * gets set on the constructor and, for optimization purposes, when the owner() sets a new
   * baseURI, the unrevealedURI gets deleted, saving gas and triggering a reveal.
   */
  function tokenURI(uint256 tokenId_) public view override returns (string memory) {
    if (bytes(unrevealedURI).length > 0) return unrevealedURI;
    return string(abi.encodePacked(baseURI, tokenId_.toString(), baseExtension));
  }

  /// @notice Set baseURI to `baseURI_`, baseExtension to `baseExtension_` and deletes unrevealedURI, triggering a reveal.
  function setBaseURI(string memory baseURI_, string memory baseExtension_) external onlyOwner {
    baseURI = baseURI_;
    baseExtension = baseExtension_;
    delete unrevealedURI;
  }

  /// @notice Set unrevealedURI to `unrevealedURI_`.
  function setUnrevealedURI(string memory unrevealedURI_) external onlyAuthorized {
    unrevealedURI = unrevealedURI_;
  }

  /// @notice Set unrevealedURI to `unrevealedURI_`.
  function setSaleState(uint256 saleState_) external onlyAuthorized {
    saleState = saleState_;
  }

  /// @notice Set merkleRoot to `merkleRoot_`.
  function setMerkleRoot(bytes32 merkleRoot_) external onlyAuthorized {
    merkleRoot = merkleRoot_;
  }

  /// @notice Set opensea to `opensea_`.
  function setOpensea(ProxyRegistry opensea_) external onlyAuthorized {
    opensea = opensea_;
  }

  /// @notice Set looksrare to `looksrare_`.
  function setLooksrare(address looksrare_) external onlyAuthorized {
    looksrare = looksrare_;
  }

  /// @notice Toggle pre-approve feature state for sender.
  function toggleMarketplacesApproved() external onlyAuthorized {
    marketplacesApproved = !marketplacesApproved;
  }

  /// @notice Toggle paused state.
  function togglePaused() external onlyAuthorized {
    _togglePaused();
  }

  /**
   * @notice Withdraw `amount_` of ether to msg.sender.
   * @dev Combined with the Auth util, this function can be called by
   * anyone with the authorization from the owner, so a team member can
   * get his shares with a permissioned call and exact data.
   */
  function withdraw(uint256 amount_) external onlyAuthorized {
    payable(msg.sender).transfer(amount_);
  }

  /// @notice Withdraw `amount_` of `token_` to the sender.
  function withdrawERC20(IERC20 token_, uint256 amount_) external onlyAuthorized {
    token_.transfer(msg.sender, amount_);
  }

  /// @notice Withdraw `tokenId_` of `token_` to the sender.
  function withdrawERC721(IERC721 token_, uint256 tokenId_) external onlyAuthorized {
    token_.safeTransferFrom(address(this), msg.sender, tokenId_);
  }

  /// @notice Withdraw `tokenId_` with amount of `value_` from `token_` to the sender.
  function withdrawERC1155(
    IERC1155 token_,
    uint256 tokenId_,
    uint256 value_
  ) external onlyAuthorized {
    token_.safeTransferFrom(address(this), msg.sender, tokenId_, value_, "");
  }

  /// @dev Modified for opensea and looksrare pre-approve so users can make truly gasless sales.
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    if (!marketplacesApproved) return super.isApprovedForAll(owner, operator);

    return
      operator == address(opensea.proxies(owner)) || operator == looksrare || super.isApprovedForAll(owner, operator);
  }

  /// @dev Edited in order to block transfers while paused unless msg.sender is the owner().
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    require(msg.sender == owner() || paused() == false, "Pausable: contract paused");
    super._beforeTokenTransfer(from, to, tokenId);
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ERC721
 * @author naomsa <https://twitter.com/naomsa666>
 * @notice A complete ERC721 implementation including metadata and enumerable
 * functions. Completely gas optimized and extensible.
 */
abstract contract ERC721 {
  /*         _           _            */
  /*        ( )_        ( )_          */
  /*    ___ | ,_)   _ _ | ,_)   __    */
  /*  /',__)| |   /'_` )| |   /'__`\  */
  /*  \__, \| |_ ( (_| || |_ (  ___/  */
  /*  (____/`\__)`\__,_)`\__)`\____)  */

  /// @dev This emits when ownership of any NFT changes by any mechanism.
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

  /// @dev This emits when the approved address for an NFT is changed or
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  /// @dev This emits when an operator is enabled or disabled for an owner.
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /// @notice See {IERC721Metadata-name}.
  string public name;

  /// @notice See {IERC721Metadata-symbol}.
  string public symbol;

  /// @notice Array of all owners.
  address[] private _owners;

  /// @notice Mapping of all balances.
  mapping(address => uint256) private _balanceOf;

  /// @notice Mapping from token ID to approved address.
  mapping(uint256 => address) private _tokenApprovals;

  /// @notice Mapping of approvals between owner and operator.
  mapping(address => mapping(address => bool)) private _isApprovedForAll;

  /*   _                            */
  /*  (_ )                _         */
  /*   | |    _      __  (_)   ___  */
  /*   | |  /'_`\  /'_ `\| | /'___) */
  /*   | | ( (_) )( (_) || |( (___  */
  /*  (___)`\___/'`\__  |(_)`\____) */
  /*              ( )_) |           */
  /*               \___/'           */

  constructor(string memory name_, string memory symbol_) {
    name = name_;
    symbol = symbol_;
  }

  /// @notice See {IERC721-balanceOf}.
  function balanceOf(address owner) public view virtual returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balanceOf[owner];
  }

  /// @notice See {IERC721-ownerOf}.
  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    require(_exists(tokenId), "ERC721: query for nonexistent token");
    address owner = _owners[tokenId];
    return owner;
  }

  /// @notice See {IERC721Metadata-tokenURI}.
  function tokenURI(uint256) public view virtual returns (string memory);

  /// @notice See {IERC721-approve}.
  function approve(address to, uint256 tokenId) public virtual {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      msg.sender == owner || _isApprovedForAll[owner][msg.sender],
      "ERC721: caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /// @notice See {IERC721-getApproved}.
  function getApproved(uint256 tokenId) public view virtual returns (address) {
    require(_exists(tokenId), "ERC721: query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  /// @notice See {IERC721-setApprovalForAll}.
  function setApprovalForAll(address operator, bool approved) public virtual {
    _setApprovalForAll(msg.sender, operator, approved);
  }

  /// @notice See {IERC721-isApprovedForAll}
  function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
    return _isApprovedForAll[owner][operator];
  }

  /// @notice See {IERC721-transferFrom}.
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
  }

  /// @notice See {IERC721-safeTransferFrom}.
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    safeTransferFrom(from, to, tokenId, "");
  }

  /// @notice See {IERC721-safeTransferFrom}.
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data_
  ) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, data_);
  }

  /// @notice See {IERC721Enumerable.tokenOfOwnerByIndex}.
  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId) {
    require(index < balanceOf(owner), "ERC721Enumerable: Index out of bounds");
    uint256 count;
    for (uint256 i; i < _owners.length; ++i) {
      if (owner == _owners[i]) {
        if (count == index) return i;
        else count++;
      }
    }
    revert("ERC721Enumerable: Index out of bounds");
  }

  /// @notice See {IERC721Enumerable.totalSupply}.
  function totalSupply() public view virtual returns (uint256) {
    return _owners.length;
  }

  /// @notice See {IERC721Enumerable.tokenByIndex}.
  function tokenByIndex(uint256 index) public view virtual returns (uint256) {
    require(index < _owners.length, "ERC721Enumerable: Index out of bounds");
    return index;
  }

  /// @notice Returns a list of all token Ids owned by `owner`.
  function tokensOfOwner(address owner) public view returns (uint256[] memory) {
    uint256 balance = balanceOf(owner);
    uint256[] memory ids = new uint256[](balance);
    for (uint256 i = 0; i < balance; i++) {
      ids[i] = tokenOfOwnerByIndex(owner, i);
    }
    return ids;
  }

  /*             _                               _    */
  /*   _        ( )_                            (_ )  */
  /*  (_)  ___  | ,_)   __   _ __   ___     _ _  | |  */
  /*  | |/' _ `\| |   /'__`\( '__)/' _ `\ /'_` ) | |  */
  /*  | || ( ) || |_ (  ___/| |   | ( ) |( (_| | | |  */
  /*  (_)(_) (_)`\__)`\____)(_)   (_) (_)`\__,_)(___) */

  /**
   * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `data_` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
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
    bytes memory data_
  ) internal virtual {
    _transfer(from, to, tokenId);
    _checkOnERC721Received(from, to, tokenId, data_);
  }

  /**
   * @notice Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return tokenId < _owners.length && _owners[tokenId] != address(0);
  }

  /**
   * @notice Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    require(_exists(tokenId), "ERC721: query for nonexistent token");
    address owner = _owners[tokenId];
    return (spender == owner || getApproved(tokenId) == spender || _isApprovedForAll[owner][spender]);
  }

  /**
   * @notice Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @notice Same as {_safeMint}, but with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory data_
  ) internal virtual {
    _mint(to, tokenId);
    _checkOnERC721Received(address(0), to, tokenId, data_);
  }

  /**
   * @notice Mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    require(!_exists(tokenId), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to, tokenId);

    _owners.push(to);
    unchecked {
      _balanceOf[to]++;
    }

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @notice Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);
    delete _owners[tokenId];
    _balanceOf[owner]--;

    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @notice Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(_owners[tokenId] == from, "ERC721: transfer of token that is not own");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _owners[tokenId] = to;
    unchecked {
      _balanceOf[from]--;
      _balanceOf[to]++;
    }

    emit Transfer(from, to, tokenId);
  }

  /**
   * @notice Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(_owners[tokenId], to, tokenId);
  }

  /**
   * @notice Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "ERC721: approve to caller");
    _isApprovedForAll[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @notice Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private {
    if (to.code.length > 0) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 returned) {
        require(returned == 0x150b7a02, "ERC721: safe transfer to non ERC721Receiver implementation");
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: safe transfer to non ERC721Receiver implementation");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  /**
   * @notice Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /*    ___  _   _  _ _      __   _ __  */
  /*  /',__)( ) ( )( '_`\  /'__`\( '__) */
  /*  \__, \| (_) || (_) )(  ___/| |    */
  /*  (____/`\___/'| ,__/'`\____)(_)    */
  /*               | |                  */
  /*               (_)                  */

  /// @notice See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return
      interfaceId == 0x80ac58cd || // ERC721
      interfaceId == 0x5b5e139f || // ERC721Metadata
      interfaceId == 0x780e9d63 || // ERC721Enumerable
      interfaceId == 0x01ffc9a7; // ERC165
  }
}

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Auth
 * @author naomsa <https://twitter.com/naomsa666>
 * @notice Authing system where the `owner` can authorize function calls
 * to other addresses as well as control the contract by his own.
 */
abstract contract Auth {
  /*         _           _            */
  /*        ( )_        ( )_          */
  /*    ___ | ,_)   _ _ | ,_)   __    */
  /*  /',__)| |   /'_` )| |   /'__`\  */
  /*  \__, \| |_ ( (_| || |_ (  ___/  */
  /*  (____/`\__)`\__,_)`\__)`\____)  */

  /// @notice Emited when the ownership is transfered.
  event OwnershipTransfered(address indexed from, address indexed to);

  /// @notice Emited a new call with `data` is authorized to `to`.
  event AuthorizationGranted(address indexed to, bytes data);

  /// @notice Emited a new call with `data` is forbidden to `to`.
  event AuthorizationForbidden(address indexed to, bytes data);

  /// @notice Contract's owner address.
  address private _owner;

  /// @notice A mapping to retrieve if a call data was authed and is valid for the address.
  mapping(address => mapping(bytes => bool)) private _isAuthorized;

  /**
   * @notice A modifier that requires the user to be the owner or authorization to call.
   * After the call, the user loses it's authorization if he's not the owner.
   */
  modifier onlyAuthorized() {
    require(isAuthorized(msg.sender, msg.data), "Auth: sender is not the owner or authorized to call");
    _;
    if (msg.sender != _owner) _isAuthorized[msg.sender][msg.data] = false;
  }

  /// @notice A simple modifier just to check whether the sender is the owner.
  modifier onlyOwner() {
    require(msg.sender == _owner, "Auth: sender is not the owner");
    _;
  }

  /*   _                            */
  /*  (_ )                _         */
  /*   | |    _      __  (_)   ___  */
  /*   | |  /'_`\  /'_ `\| | /'___) */
  /*   | | ( (_) )( (_) || |( (___  */
  /*  (___)`\___/'`\__  |(_)`\____) */
  /*              ( )_) |           */
  /*               \___/'           */

  constructor() {
    _transferOwnership(msg.sender);
  }

  /// @notice Returns the current contract owner.
  function owner() public view returns (address) {
    return _owner;
  }

  /// @notice Retrieves whether `user_` is authorized to call with `data_`.
  function isAuthorized(address user_, bytes memory data_) public view returns (bool) {
    return user_ == _owner || _isAuthorized[user_][data_];
  }

  /// @notice Set the owner address to `owner_`.
  function transferOwnership(address owner_) public onlyOwner {
    require(_owner != owner_, "Auth: transfering ownership to current owner");
    _transferOwnership(owner_);
  }

  /// @notice Set the owner address to `owner_`. Does not require anything
  function _transferOwnership(address owner_) internal {
    address oldOwner = _owner;
    _owner = owner_;

    emit OwnershipTransfered(oldOwner, owner_);
  }

  /// @notice Authorize a call with `data_` to the address `to_`.
  function auth(address to_, bytes memory data_) public onlyOwner {
    require(to_ != _owner, "Auth: authorizing call to the owner");
    require(!_isAuthorized[to_][data_], "Auth: authorized calls cannot be authed");
    _isAuthorized[to_][data_] = true;

    emit AuthorizationGranted(to_, data_);
  }

  /// @notice Authorize a call with `data_` to the address `to_`.
  function forbid(address to_, bytes memory data_) public onlyOwner {
    require(_isAuthorized[to_][data_], "Auth: unauthorized calls cannot be forbidden");
    delete _isAuthorized[to_][data_];

    emit AuthorizationForbidden(to_, data_);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Pausable
 * @author naomsa <https://twitter.com/naomsa666>
 * @notice Freeze your contract with a secure paused mechanism.
 */
abstract contract Pausable {
  /*         _           _            */
  /*        ( )_        ( )_          */
  /*    ___ | ,_)   _ _ | ,_)   __    */
  /*  /',__)| |   /'_` )| |   /'__`\  */
  /*  \__, \| |_ ( (_| || |_ (  ___/  */
  /*  (____/`\__)`\__,_)`\__)`\____)  */

  /// @notice Emited when the contract is paused.
  event Paused(address indexed by);

  /// @notice Emited when the contract is unpaused.
  event Unpaused(address indexed by);

  /// @notice Read-only pause state.
  bool private _paused;

  /// @notice A modifier to be used when the contract must be paused.
  modifier onlyWhenPaused() {
    require(_paused, "Pausable: contract not paused");
    _;
  }

  /// @notice A modifier to be used when the contract must be unpaused.
  modifier onlyWhenUnpaused() {
    require(!_paused, "Pausable: contract paused");
    _;
  }

  /*   _                            */
  /*  (_ )                _         */
  /*   | |    _      __  (_)   ___  */
  /*   | |  /'_`\  /'_ `\| | /'___) */
  /*   | | ( (_) )( (_) || |( (___  */
  /*  (___)`\___/'`\__  |(_)`\____) */
  /*              ( )_) |           */
  /*               \___/'           */

  /// @notice Retrieve contracts pause state.
  function paused() public view returns (bool) {
    return _paused;
  }

  /// @notice Inverts pause state. Declared internal so it can be combined with the Auth contract.
  function _togglePaused() internal {
    _paused = !_paused;
    if (_paused) emit Unpaused(msg.sender);
    else emit Paused(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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