// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import './RandomColor.sol';
import './utils/Base64.sol';
import './IPalette.sol';
import './opensea/BaseOpensea.sol';
import './@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol';
import './@rarible/royalties/contracts/LibPart.sol';
import './@rarible/royalties/contracts/LibRoyaltiesV2.sol';

contract Palette is
  IPalette,
  RandomColor,
  ReentrancyGuard,
  Ownable,
  ERC721,
  BaseOpenSea,
  RoyaltiesV2Impl
{
  using Strings for uint256;
  using Counters for Counters.Counter;

  uint256 public MAX_SUPPLY;
  bool public FAIR_MINT;
  uint96 public ROYALTY = 1000; // 10%

  Counters.Counter private _totalSupply;
  mapping(address => bool) private _minters;
  bytes32 private _lastSeed;
  mapping(uint256 => bytes32[]) private _tokenSeeds;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor(
    uint256 maxSupply,
    bool fairMint,
    address owner,
    address openSeaProxyRegistry
  ) ERC721('PaletteOnChain', 'PALETTE') Ownable() {
    MAX_SUPPLY = maxSupply;
    FAIR_MINT = fairMint;

    if (owner != _msgSender()) {
      transferOwnership(owner);
    }

    if (openSeaProxyRegistry != address(0)) {
      _setOpenSeaRegistry(openSeaProxyRegistry);
    }
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply.current();
  }

  function remainingSupply() external view override returns (uint256) {
    return MAX_SUPPLY - _totalSupply.current();
  }

  function mint() external override nonReentrant {
    require(_totalSupply.current() < MAX_SUPPLY, 'Mint would exceed max supply');

    address operator = _msgSender();
    if (FAIR_MINT) {
      require(!_minters[operator], 'Mint only once');
    }

    _minters[operator] = true;

    bytes32 seed = _lastSeed;
    bytes32 blockHash = blockhash(block.number - 1);
    uint256 timestamp = block.timestamp;

    uint256 paletteCount = 5;
    bytes32[] memory seeds = new bytes32[](paletteCount);
    for (uint256 i = 0; i < paletteCount; i++) {
      seed = _nextSeed(seed, timestamp, operator, blockHash);
      seeds[i] = seed;
    }
    _lastSeed = seed;

    _totalSupply.increment();
    uint256 tokenId = _totalSupply.current();

    _tokenSeeds[tokenId] = seeds;
    _safeMint(operator, tokenId);
    _setRoyalties(tokenId, payable(owner()), ROYALTY);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string[5] memory palette = _getPalette(tokenId);

    string[8] memory parts;
    string[5] memory attributeParts;

    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" width="800" height="800" viewBox="0 0 10 10"><g transform="rotate(-90 5 5)">';

    for (uint256 i = 0; i < palette.length; i++) {
      parts[i + 1] = string(
        abi.encodePacked(
          '<rect x="0" y="',
          (i * 2).toString(),
          '" width="10" height="2" fill="',
          palette[i],
          '" />'
        )
      );

      attributeParts[i] = string(
        abi.encodePacked(
          '{"trait_type": "Color',
          (i + 1).toString(),
          '", "value": "',
          palette[i],
          '"}',
          i + 1 == palette.length ? '' : ', '
        )
      );
    }

    parts[7] = '</g></svg>';

    string memory output = string(
      abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
    );
    output = string(abi.encodePacked(output, parts[5], parts[6], parts[7]));

    string memory attributes = string(
      abi.encodePacked(
        attributeParts[0],
        attributeParts[1],
        attributeParts[2],
        attributeParts[3],
        attributeParts[4]
      )
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Palette #',
            tokenId.toString(),
            '", "description": "PaletteOnChain is randomly generated color palette and stored on chain. This palette can be used as a color base by others to create new collectable art.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '", "attributes": [',
            attributes,
            '], "license": { "type": "CC0", "url": "https://creativecommons.org/publicdomain/zero/1.0/" }}'
          )
        )
      )
    );
    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
  }

  function getRandomColorCode(uint256 seed) external view override returns (string memory) {
    return _getColorCode(uint256(seed));
  }

  function getColorCodeFromHSV(
    uint256 hue,
    uint256 saturation,
    uint256 brightness
  ) external pure override returns (string memory) {
    return _getColorCode(hue, saturation, brightness);
  }

  function getPalette(uint256 tokenId) external view override returns (string[5] memory) {
    return _getPalette(tokenId);
  }

  function _getPalette(uint256 tokenId) private view returns (string[5] memory) {
    require(_exists(tokenId), 'getPalette query for nonexistent token');

    bytes32[] memory seeds = _tokenSeeds[tokenId];

    string[5] memory palette;

    for (uint256 i = 0; i < seeds.length; i++) {
      palette[i] = _getColorCode(uint256(seeds[i]));
    }

    return palette;
  }

  function _nextSeed(
    bytes32 currentSeed,
    uint256 timestamp,
    address operator,
    bytes32 blockHash
  ) private view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          currentSeed,
          timestamp,
          operator,
          blockHash,
          block.coinbase,
          block.difficulty,
          tx.gasprice
        )
      );
  }

  /// @notice Allows gas-less trading on OpenSea by safelisting the Proxy of the user
  /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
  /// @inheritdoc	ERC721
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    // allows gas less trading on OpenSea
    if (isOwnersOpenSeaProxy(owner, operator)) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  function _setRoyalties(
    uint256 _tokenId,
    address payable _royaltiesReceipientAddress,
    uint96 _percentageBasisPoints
  ) private {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesReceipientAddress;
    _saveRoyalties(_tokenId, _royalties);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    LibPart.Part[] memory _royalties = royalties[_tokenId];
    if (_royalties.length > 0) {
      return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
    }
    return (address(0), 0);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721)
    returns (bool)
  {
    if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
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
     * by making the `nonReentrant` function external, and make it call a
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//inspired by David Merfield's randomColor.js
//https://github.com/davidmerfield/randomColor

import '@openzeppelin/contracts/utils/Strings.sol';
import {ColorStrings} from './utils/ColorStrings.sol';
import './utils/Randomize.sol';

abstract contract RandomColor {
  using Strings for uint256;
  using ColorStrings for uint256;
  using Randomize for Randomize.Random;

  struct HueRange {
    string _name;
    uint256 _min;
    uint256 _max;
  }

  struct Range {
    uint256 _min;
    uint256 _max;
  }

  struct LowerBound {
    uint256 _saturation;
    uint256 _brightness;
  }

  HueRange[] private _hueRanges;

  mapping(string => LowerBound[]) private _lowerBounds;
  mapping(string => Range) private _saturationRanges;
  mapping(string => Range) private _brightnessRanges;

  constructor() {
    _hueRangeSetup();
    _lowerBoundMapping();
    _saturationRangeMapping();
    _brightnessRangeMapping();
  }

  function _hueRangeSetup() private {
    _hueRanges.push(HueRange('red', 0, 18));
    _hueRanges.push(HueRange('orange', 18, 46));
    _hueRanges.push(HueRange('yellow', 46, 62));
    _hueRanges.push(HueRange('green', 62, 178));
    _hueRanges.push(HueRange('blue', 178, 257));
    _hueRanges.push(HueRange('purple', 257, 282));
    _hueRanges.push(HueRange('pink', 282, 334));
  }

  function _lowerBoundMapping() private {
    _lowerBounds['red'].push(LowerBound(20, 100));
    _lowerBounds['red'].push(LowerBound(30, 92));
    _lowerBounds['red'].push(LowerBound(40, 89));
    _lowerBounds['red'].push(LowerBound(50, 85));
    _lowerBounds['red'].push(LowerBound(60, 78));
    _lowerBounds['red'].push(LowerBound(70, 70));
    _lowerBounds['red'].push(LowerBound(80, 60));
    _lowerBounds['red'].push(LowerBound(90, 55));
    _lowerBounds['red'].push(LowerBound(100, 50));

    _lowerBounds['orange'].push(LowerBound(20, 100));
    _lowerBounds['orange'].push(LowerBound(30, 93));
    _lowerBounds['orange'].push(LowerBound(40, 88));
    _lowerBounds['orange'].push(LowerBound(50, 86));
    _lowerBounds['orange'].push(LowerBound(60, 85));
    _lowerBounds['orange'].push(LowerBound(70, 70));
    _lowerBounds['orange'].push(LowerBound(100, 70));

    _lowerBounds['yellow'].push(LowerBound(25, 100));
    _lowerBounds['yellow'].push(LowerBound(40, 94));
    _lowerBounds['yellow'].push(LowerBound(50, 89));
    _lowerBounds['yellow'].push(LowerBound(60, 86));
    _lowerBounds['yellow'].push(LowerBound(70, 84));
    _lowerBounds['yellow'].push(LowerBound(80, 82));
    _lowerBounds['yellow'].push(LowerBound(90, 80));
    _lowerBounds['yellow'].push(LowerBound(100, 75));

    _lowerBounds['green'].push(LowerBound(30, 100));
    _lowerBounds['green'].push(LowerBound(40, 90));
    _lowerBounds['green'].push(LowerBound(50, 85));
    _lowerBounds['green'].push(LowerBound(60, 81));
    _lowerBounds['green'].push(LowerBound(70, 74));
    _lowerBounds['green'].push(LowerBound(80, 64));
    _lowerBounds['green'].push(LowerBound(90, 50));
    _lowerBounds['green'].push(LowerBound(100, 40));

    _lowerBounds['blue'].push(LowerBound(20, 100));
    _lowerBounds['blue'].push(LowerBound(30, 86));
    _lowerBounds['blue'].push(LowerBound(40, 80));
    _lowerBounds['blue'].push(LowerBound(50, 74));
    _lowerBounds['blue'].push(LowerBound(60, 60));
    _lowerBounds['blue'].push(LowerBound(70, 52));
    _lowerBounds['blue'].push(LowerBound(80, 44));
    _lowerBounds['blue'].push(LowerBound(90, 39));
    _lowerBounds['blue'].push(LowerBound(100, 35));

    _lowerBounds['purple'].push(LowerBound(20, 100));
    _lowerBounds['purple'].push(LowerBound(30, 87));
    _lowerBounds['purple'].push(LowerBound(40, 79));
    _lowerBounds['purple'].push(LowerBound(50, 70));
    _lowerBounds['purple'].push(LowerBound(60, 65));
    _lowerBounds['purple'].push(LowerBound(70, 59));
    _lowerBounds['purple'].push(LowerBound(80, 52));
    _lowerBounds['purple'].push(LowerBound(90, 45));
    _lowerBounds['purple'].push(LowerBound(100, 42));

    _lowerBounds['pink'].push(LowerBound(20, 100));
    _lowerBounds['pink'].push(LowerBound(30, 90));
    _lowerBounds['pink'].push(LowerBound(40, 86));
    _lowerBounds['pink'].push(LowerBound(60, 84));
    _lowerBounds['pink'].push(LowerBound(80, 80));
    _lowerBounds['pink'].push(LowerBound(90, 75));
    _lowerBounds['pink'].push(LowerBound(100, 73));
  }

  function _saturationRangeMapping() private {
    _saturationRanges['red'] = Range(20, 100);
    _saturationRanges['orange'] = Range(20, 100);
    _saturationRanges['yellow'] = Range(25, 100);
    _saturationRanges['green'] = Range(30, 100);
    _saturationRanges['blue'] = Range(20, 100);
    _saturationRanges['purple'] = Range(20, 100);
    _saturationRanges['pink'] = Range(30, 100);
  }

  function _brightnessRangeMapping() private {
    _brightnessRanges['red'] = Range(50, 100);
    _brightnessRanges['orange'] = Range(70, 100);
    _brightnessRanges['yellow'] = Range(75, 100);
    _brightnessRanges['green'] = Range(40, 100);
    _brightnessRanges['blue'] = Range(35, 100);
    _brightnessRanges['purple'] = Range(42, 100);
    _brightnessRanges['pink'] = Range(73, 100);
  }

  function _pickHue(Randomize.Random memory random) private pure returns (uint256) {
    return random.next(0, 360);
  }

  function _pickSaturation(Randomize.Random memory random, uint256 hue)
    private
    view
    returns (uint256)
  {
    string memory colorName = _getColorName(hue);
    require(keccak256(bytes(colorName)) != keccak256(bytes('not_found')), 'Color name not found');

    Range memory saturationRange = _saturationRanges[colorName];
    return random.next(saturationRange._min, saturationRange._max);
  }

  function _pickBrightness(
    Randomize.Random memory random,
    uint256 hue,
    uint256 saturation
  ) private view returns (uint256) {
    string memory colorName = _getColorName(hue);
    require(keccak256(bytes(colorName)) != keccak256(bytes('not_found')), 'Color name not found');

    uint256 minBrightness = _getMinimumBrightness(hue, saturation);
    uint256 maxBrightness = 100;

    if (minBrightness == maxBrightness) {
      return minBrightness;
    }

    return random.next(minBrightness, maxBrightness);
  }

  function _getMinimumBrightness(uint256 hue, uint256 saturation) private view returns (uint256) {
    string memory colorName = _getColorName(hue);
    require(keccak256(bytes(colorName)) != keccak256(bytes('not_found')), 'Color name not found');

    LowerBound[] memory lowerBounds = _lowerBounds[colorName];
    uint256 len = lowerBounds.length;
    for (uint256 i = 0; i < len - 1; i++) {
      uint256 s1 = lowerBounds[i]._saturation;
      uint256 v1 = lowerBounds[i]._brightness;

      uint256 s2 = lowerBounds[i + 1]._saturation;
      uint256 v2 = lowerBounds[i + 1]._brightness;

      if (saturation >= s1 && saturation <= s2) {
        int256 m = ((int256(v2) - int256(v1)) * 10) / int256(s2 - s1);
        int256 b = int256(v1 * 10) - (m * int256(s1));

        return uint256((m * int256(saturation) + b) / 10);
      }
    }
    return 0;
  }

  function _getColorName(uint256 hue) private view returns (string memory) {
    if (hue >= 334 && hue <= 360) {
      hue = 0;
    }

    uint256 len = _hueRanges.length;
    for (uint256 i = 0; i < len; i++) {
      if (hue >= _hueRanges[i]._min && hue <= _hueRanges[i]._max) {
        return _hueRanges[i]._name;
      }
    }
    return 'not_found';
  }

  /// @dev this function is not accurate due to rounding errors, and may have an error of 1 for each value of rgb.
  function _hsvToRgb(
    uint256 hue,
    uint256 saturation,
    uint256 value
  ) private pure returns (uint256[3] memory) {
    if (hue == 0) {
      hue = 1;
    }
    if (hue == 360) {
      hue = 359;
    }

    uint256 multiplier = 10000;
    uint256 h = (hue * multiplier) / 360;
    uint256 s = (saturation * multiplier) / 100;
    uint256 v = (value * multiplier) / 100;

    uint256 h_i = (h * 6);
    uint256 f = h_i % multiplier;
    uint256 p = (v * (1 * multiplier - s)) / multiplier;
    uint256 q = (v * (1 * multiplier - ((f * s) / multiplier))) / multiplier;
    uint256 t = (v * (1 * multiplier - (((1 * multiplier - f) * s) / multiplier))) / multiplier;
    uint256 r = 256;
    uint256 g = 256;
    uint256 b = 256;

    if (h_i < 1 * multiplier) {
      r = v;
      g = t;
      b = p;
    } else if (h_i < 2 * multiplier) {
      r = q;
      g = v;
      b = p;
    } else if (h_i < 3 * multiplier) {
      r = p;
      g = v;
      b = t;
    } else if (h_i < 4 * multiplier) {
      r = p;
      g = q;
      b = v;
    } else if (h_i < 5 * multiplier) {
      r = t;
      g = p;
      b = v;
    } else if (h_i < 6 * multiplier) {
      r = v;
      g = p;
      b = q;
    }

    return [(r * 255) / multiplier, (g * 255) / multiplier, (b * 255) / multiplier];
  }

  function _rgbToHexString(uint256[3] memory rgb) private pure returns (string memory) {
    string memory colorCode = string(
      abi.encodePacked(
        '#',
        rgb[0].toHexColorString(),
        rgb[1].toHexColorString(),
        rgb[2].toHexColorString()
      )
    );
    return colorCode;
  }

  function _getColorCode(uint256 seed) internal view returns (string memory) {
    Randomize.Random memory random = Randomize.Random({seed: seed, offsetBit: 0});
    uint256 hue = _pickHue(random);
    uint256 saturation = _pickSaturation(random, hue);
    uint256 brightness = _pickBrightness(random, hue, saturation);

    uint256[3] memory rgb = _hsvToRgb(hue, saturation, brightness);

    return _rgbToHexString(rgb);
  }

  function _getColorCode(
    uint256 hue,
    uint256 saturation,
    uint256 brightness
  ) internal pure returns (string memory) {
    require(hue <= 360, 'Max hue is 360');
    require(saturation <= 100, 'Max saturation is 100');
    require(brightness <= 100, 'Max brightness is 100');

    uint256[3] memory rgb = _hsvToRgb(hue, saturation, brightness);
    return _rgbToHexString(rgb);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// This is a copy of Base64 from LOOT.
// https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1609

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
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
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPalette {
  /// @dev Returns the total amount of tokens stored by the contract.
  function totalSupply() external view returns (uint256);

  /// @dev Returns the remaining amount of tokens.
  function remainingSupply() external view returns (uint256);

  /// @dev Mints new token and transfers it to msgSender.
  function mint() external;

  /// @dev tokenId is from 1 to MAX_SUPPLY.
  function getPalette(uint256 tokenId) external view returns (string[5] memory);

  /// @dev specifying a multiple of 16 for seed will change the color code.
  function getRandomColorCode(uint256 seed) external view returns (string memory);

  /**
   * @dev hue: 0 ~ 360
   *      saturation: 0 ~ 100
   *      brightness: 0 ~ 100
   */
  function getColorCodeFromHSV(
    uint256 hue,
    uint256 saturation,
    uint256 brightness
  ) external pure returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This is a copy of BaseOpenSea.sol.
// https://gist.github.com/dievardump/483eb43bc6ed30b14f01e01842e3339b#file-baseopensea-sol

/// @title OpenSea contract helper that defines a few things
/// @author Simon Fremaux (@dievardump)
/// @dev This is a contract used to add OpenSea's
///      gas-less trading and contractURI support
contract BaseOpenSea {
  string private _contractURI;
  address private _proxyRegistry;

  /// @notice Returns the contract URI function. Used on OpenSea to get details
  //          about a contract (owner, royalties etc...)
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /// @notice Returns the current OS proxyRegistry address registered
  function proxyRegistry() public view returns (address) {
    return _proxyRegistry;
  }

  /// @notice Helper allowing OpenSea gas-less trading by verifying who's operator
  ///         for owner
  /// @dev Allows to check if `operator` is owner's OpenSea proxy on eth mainnet / rinkeby
  ///      or to check if operator is OpenSea's proxy contract on Polygon and Mumbai
  /// @param owner the owner we check for
  /// @param operator the operator (proxy) we check for
  function isOwnersOpenSeaProxy(address owner, address operator) public view returns (bool) {
    address proxyRegistry_ = _proxyRegistry;

    // if we have a proxy registry
    if (proxyRegistry_ != address(0)) {
      // on ethereum mainnet or rinkeby use "ProxyRegistry" to
      // get owner's proxy
      if (block.chainid == 1 || block.chainid == 4) {
        return address(ProxyRegistry(proxyRegistry_).proxies(owner)) == operator;
      } else if (block.chainid == 137 || block.chainid == 80001) {
        // on Polygon and Mumbai just try with OpenSea's proxy contract
        // https://docs.opensea.io/docs/polygon-basic-integration
        return proxyRegistry_ == operator;
      }
    }

    return false;
  }

  /// @dev Internal function to set the _contractURI
  /// @param contractURI_ the new contract uri
  function _setContractURI(string memory contractURI_) internal {
    _contractURI = contractURI_;
  }

  /// @dev Internal function to set the _proxyRegistry
  /// @param proxyRegistryAddress the new proxy registry address
  function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
    _proxyRegistry = proxyRegistryAddress;
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './AbstractRoyalties.sol';
import '../RoyaltiesV2.sol';

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {
  function getRaribleV2Royalties(uint256 id)
    external
    view
    override
    returns (LibPart.Part[] memory)
  {
    return royalties[id];
  }

  function _onRoyaltiesSet(uint256 _id, LibPart.Part[] memory _royalties) internal override {
    emit RoyaltiesSet(_id, _royalties);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibPart {
  bytes32 public constant TYPE_HASH = keccak256('Part(address account,uint96 value)');

  struct Part {
    address payable account;
    uint96 value;
  }

  function hash(Part memory part) internal pure returns (bytes32) {
    return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibRoyaltiesV2 {
  /*
   * bytes4(keccak256('getRoyalties(LibAsset.AssetType)')) == 0x44c74bcc
   */
  bytes4 constant _INTERFACE_ID_ROYALTIES = 0x44c74bcc;
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

library ColorStrings {
  bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

  function toHexColorString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return '00';
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexColorString(value, length);
  }

  function toHexColorString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length);
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i - 2] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, 'Strings: hex length insufficient');
    return string(buffer);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// This is a copy of Randomize.sol from SSGS#0.
// https://etherscan.io/address/0x5d4683ba64ee6283bb7fdb8a91252f6aab32a110#code#F21#L5

// small library to randomize using (min, max, seed, offsetBit etc...)
library Randomize {
  struct Random {
    uint256 seed;
    uint256 offsetBit;
  }

  /// @notice get an random number between (min and max) using seed and offseting bits
  ///         this function assumes that max is never bigger than 0xffffff (hex color with opacity included)
  /// @dev this function is simply used to get random number using a seed.
  ///      if does bitshifting operations to try to reuse the same seed as much as possible.
  ///      should be enough for anyth
  /// @param random the randomizer
  /// @param min the minimum
  /// @param max the maximum
  /// @return result the resulting pseudo random number
  function next(
    Random memory random,
    uint256 min,
    uint256 max
  ) internal pure returns (uint256 result) {
    uint256 newSeed = random.seed;
    uint256 newOffset = random.offsetBit + 3;

    uint256 maxOffset = 4;
    uint256 mask = 0xf;
    if (max > 0xfffff) {
      mask = 0xffffff;
      maxOffset = 24;
    } else if (max > 0xffff) {
      mask = 0xfffff;
      maxOffset = 20;
    } else if (max > 0xfff) {
      mask = 0xffff;
      maxOffset = 16;
    } else if (max > 0xff) {
      mask = 0xfff;
      maxOffset = 12;
    } else if (max > 0xf) {
      mask = 0xff;
      maxOffset = 8;
    }

    // if offsetBit is too high to get the max number
    // just get new seed and restart offset to 0
    if (newOffset > (256 - maxOffset)) {
      newOffset = 0;
      newSeed = uint256(keccak256(abi.encode(newSeed)));
    }

    uint256 offseted = (newSeed >> newOffset);
    uint256 part = offseted & mask;
    result = min + (part % (max - min));

    random.seed = newSeed;
    random.offsetBit = newOffset;
  }

  function nextInt(
    Random memory random,
    uint256 min,
    uint256 max
  ) internal pure returns (int256 result) {
    result = int256(Randomize.next(random, min, max));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../LibPart.sol';

abstract contract AbstractRoyalties {
  mapping(uint256 => LibPart.Part[]) public royalties;

  function _saveRoyalties(uint256 _id, LibPart.Part[] memory _royalties) internal {
    for (uint256 i = 0; i < _royalties.length; i++) {
      require(_royalties[i].account != address(0x0), 'Recipient should be present');
      require(_royalties[i].value != 0, 'Royalty value should be positive');
      royalties[_id].push(_royalties[i]);
    }
    _onRoyaltiesSet(_id, _royalties);
  }

  function _updateAccount(
    uint256 _id,
    address _from,
    address _to
  ) internal {
    uint256 length = royalties[_id].length;
    for (uint256 i = 0; i < length; i++) {
      if (royalties[_id][i].account == _from) {
        royalties[_id][i].account = payable(address(uint160(_to)));
      }
    }
  }

  function _onRoyaltiesSet(uint256 _id, LibPart.Part[] memory _royalties) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './LibPart.sol';

interface RoyaltiesV2 {
  event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

  function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}

