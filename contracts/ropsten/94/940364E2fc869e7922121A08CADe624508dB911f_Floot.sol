// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import { BlindDrop } from "./BlindDrop.sol";
import { FlootMetadata } from "./FlootMetadata.sol";

/**
 * @title Floot
 * @author the-torn
 *
 * @notice Floot = Fair Loot. Like Loot, but enforces a fair, random distribution.
 *
 *  Documentation: https://github.com/the-torn/floot/blob/main/README.md
 *
 *  Note: Deliberately choosing not to use ReentrancyGuard, as a gas optimization.
 */
contract Floot is
  FlootMetadata
{
  uint256 public immutable MAX_SUPPLY;
  uint256 public immutable MAX_DISTRIBUTION_DURATION_SECONDS;

  uint256 internal _totalSupply = 0;

  constructor(
    bytes32 guardianHash,
    uint256 guardianWindowDurationSeconds,
    uint256 maxDistributionDurationSeconds,
    uint256 maxSupply
  )
    ERC721("Floot", "FLOOT")
    BlindDrop(guardianHash, guardianWindowDurationSeconds, maxDistributionDurationSeconds)
  {
    MAX_SUPPLY = maxSupply;
    MAX_DISTRIBUTION_DURATION_SECONDS = maxDistributionDurationSeconds;
  }

  /**
   * @notice Claim a token.
   */
  function claim()
    external
  {
    uint256 startingTotalSupply = _totalSupply;
    require(
      startingTotalSupply < MAX_SUPPLY,
      "Max supply exceeded"
    );
    require(
      block.timestamp < DISTRIBUTION_AUTO_END_TIMESTAMP,
      "Distribution has ended"
    );

    // Issue tokens with IDs 1 through MAX_SUPPLY, inclusive.
    uint256 tokenId = startingTotalSupply + 1;

    // IMPORTANT: Update total supply before _safeMint() to avoid reentrancy attacks.
    // (checks-effects-interactions)
    _totalSupply = tokenId;

    // Mint the token. This may trigger a call on the receiver if it is a smart contract.
    _safeMint(msg.sender, tokenId);
  }

  function setAutomaticSeedBlockNumber()
    external
  {
    _setAutomaticSeedBlockNumber(_totalSupply == MAX_SUPPLY);
  }

  function totalSupply()
    public
    view
    override
    returns (uint256)
  {
    return _totalSupply;
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title BlindDrop
 * @author the-torn
 *
 * @notice Securely generate a random seed for use in a random NFT distribution.
 *
 *  Documentation: https://github.com/the-torn/floot/blob/main/README.md
 *
 *  Inspired by Hashmasks.
 */
abstract contract BlindDrop {
  bytes32 public immutable GUARDIAN_HASH;
  uint256 public immutable GUARDIAN_WINDOW_DURATION_SECONDS;
  uint256 public immutable DISTRIBUTION_AUTO_END_TIMESTAMP;

  uint256 private _automaticSeedBlockNumber;
  bytes32 private _automaticSeed;
  uint256 private _guardianWindowEndTimestamp;
  bytes32 private _guardianOrFallbackSeed;
  uint256 private _fallbackSeedBlockNumber;
  bytes32 private _finalSeed;

  event SetSeedBlockNumber(uint256 blockNumber);
  event SetSeed(bytes32 seed);
  event SetFinalSeed(bytes32 seed);

  constructor(
    bytes32 guardianHash,
    uint256 guardianWindowDurationSeconds,
    uint256 maxDistributionDurationSeconds
  ) {
    GUARDIAN_HASH = guardianHash;
    GUARDIAN_WINDOW_DURATION_SECONDS = guardianWindowDurationSeconds;
    DISTRIBUTION_AUTO_END_TIMESTAMP = block.timestamp + maxDistributionDurationSeconds;
  }

  function _setAutomaticSeedBlockNumber(
    bool maxSupplyWasReached
  )
    internal
  {
    require(
      _automaticSeedBlockNumber == 0,
      "Seed block number already set"
    );

    // Anyone can finalize the automatic seed block number once either of the following is true:
    //   1. all tokens were claimed; or
    //   2. we reached the auto-end timestamp.
    require(
      (
        maxSupplyWasReached ||
        block.timestamp >= DISTRIBUTION_AUTO_END_TIMESTAMP
      ),
      "Distribution not over"
    );

    uint256 automaticSeedBlockNumber = block.number + 1;
    _automaticSeedBlockNumber = automaticSeedBlockNumber;
    emit SetSeedBlockNumber(automaticSeedBlockNumber);
  }

  function setAutomaticSeed()
    external
  {
    require(
      _automaticSeed == bytes32(0),
      "Automatic seed already set"
    );

    bytes32 automaticSeed = _getSeedFromBlockNumber(_automaticSeedBlockNumber);
    _automaticSeed = automaticSeed;
    emit SetSeed(automaticSeed);

    // Mark the start of the guardian window, during which the guardian can provide their seed.
    _guardianWindowEndTimestamp = block.timestamp + GUARDIAN_WINDOW_DURATION_SECONDS;
  }

  function setGuardianSeed(
    bytes32 guardianSeed
  )
    external
  {
    require(
      _guardianOrFallbackSeed == bytes32(0),
      "Seed already set"
    );
    require(
      _automaticSeed != bytes32(0),
      "Automatic seed not set"
    );
    require(
      block.timestamp < _guardianWindowEndTimestamp,
      "Guardian window elapsed"
    );
    require(
      keccak256(abi.encodePacked(guardianSeed)) == GUARDIAN_HASH,
      "Guardian seed invalid"
    );
    _guardianOrFallbackSeed = guardianSeed;
    emit SetSeed(guardianSeed);
  }

  function setFallbackSeedBlockNumber()
    external
  {
    require(
      _fallbackSeedBlockNumber == 0,
      "Seed block number already set"
    );
    require(
      _automaticSeed != bytes32(0),
      "Automatic seed not set"
    );
    require(
      block.timestamp >= _guardianWindowEndTimestamp,
      "Guardian window has not ended"
    );

    uint256 fallbackSeedBlockNumber = block.number + 1;
    _fallbackSeedBlockNumber = fallbackSeedBlockNumber;
    emit SetSeedBlockNumber(fallbackSeedBlockNumber);
  }

  function setFallbackSeed()
    external
  {
    require(
      _guardianOrFallbackSeed == bytes32(0),
      "Seed already set"
    );

    bytes32 fallbackSeed = _getSeedFromBlockNumber(_fallbackSeedBlockNumber);
    _guardianOrFallbackSeed = fallbackSeed;
    emit SetSeed(fallbackSeed);
  }

  function setFinalSeed()
    external
  {
    require(
      _finalSeed == bytes32(0),
      "Final seed already set"
    );
    require(
      _guardianOrFallbackSeed != bytes32(0),
      "Guardian/fallback seed not set"
    );

    bytes32 finalSeed = _automaticSeed ^ _guardianOrFallbackSeed;
    _finalSeed = finalSeed;
    emit SetFinalSeed(finalSeed);
  }

  function _getSeedFromBlockNumber(
    uint256 targetBlockNumber
  )
    internal
    view
    returns (bytes32)
  {
    require(
      targetBlockNumber != 0,
      "Block number not set"
    );
    // Important: blockhash(targetBlockNumber) will return zero if the block was not yet mined.
    require(
      targetBlockNumber < block.number,
      "Block number not mined"
    );

    // If the hash for the desired block is unavailable, fall back to the most recent block.
    if (block.number - targetBlockNumber > 256) {
      targetBlockNumber = block.number - 1;
    }

    return blockhash(targetBlockNumber);
  }

  /**
   * @notice Get the blind drop seed which is securely determined after the end of the distribution.
   *
   *  Revert if the seed has not been set.
   */
  function getFinalSeed()
    public
    view
    returns (bytes32)
  {
    bytes32 finalSeed = _finalSeed;
    require(
      finalSeed != bytes32(0),
      "Final seed not set"
    );
    return finalSeed;
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { BlindDrop } from "./BlindDrop.sol";
import { Base64 } from "./Base64.sol";
import { ERC721EnumerableOptimized } from "./ERC721EnumerableOptimized.sol";
import { FlootConstants } from "./FlootConstants.sol";

/**
 * @title FlootMetadata
 * @author the-torn
 *
 * @notice Logic for generating metadata, including the SVG graphic with text.
 *
 *  Based closely on the original Loot implementation (MIT License).
 *  https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1
 */
abstract contract FlootMetadata is
  BlindDrop,
  ERC721EnumerableOptimized
{
  function random(
    string memory input
  )
    internal
    pure
    returns (uint256)
  {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function getWeapon(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, FlootConstants.ListName.WEAPON);
  }

  function getChest(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, FlootConstants.ListName.CHEST);
  }

  function getHead(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, FlootConstants.ListName.HEAD);
  }

  function getWaist(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, FlootConstants.ListName.WAIST);
  }

  function getFoot(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, FlootConstants.ListName.FOOT);
  }

  function getHand(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, FlootConstants.ListName.HAND);
  }

  function getNeck(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, FlootConstants.ListName.NECK);
  }

  function getRing(
    uint256 tokenId
  )
    public
    view
    returns (string memory)
  {
    return pluck(tokenId, FlootConstants.ListName.RING);
  }

  function pluck(
    uint256 tokenId,
    FlootConstants.ListName keyPrefix
  )
    internal
    view
    returns (string memory)
  {
    // Get the blind drop seed. Will revert if the distribution is not complete or if the seed
    // has not yet been finalized.
    bytes32 seed = getFinalSeed();

    // On-chain randomness.
    string memory inputForRandomness = string(abi.encodePacked(
      keyPrefix,
      tokenId, // Note: No need to use toString() here.
      seed
    ));
    uint256 rand = random(inputForRandomness);

    // Determine the item name based on the randomly generated number.
    string memory output = FlootConstants.getItem(rand, keyPrefix);
    uint256 greatness = rand % 21;
    if (greatness > 14) {
      output = string(abi.encodePacked(output, " ", FlootConstants.getItem(rand, FlootConstants.ListName.SUFFIX)));
    }
    if (greatness >= 19) {
      string[2] memory name;
      name[0] = FlootConstants.getItem(rand, FlootConstants.ListName.NAME_PREFIX);
      name[1] = FlootConstants.getItem(rand, FlootConstants.ListName.NAME_SUFFIX);
      if (greatness == 19) {
        output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
      } else {
        output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
      }
    }
    return output;
  }

  function tokenURI(
    uint256 tokenId
  )
    override
    public
    view
    returns (string memory)
  {
    string[17] memory parts;
    parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
    parts[1] = getWeapon(tokenId);
    parts[2] = '</text><text x="10" y="40" class="base">';
    parts[3] = getChest(tokenId);
    parts[4] = '</text><text x="10" y="60" class="base">';
    parts[5] = getHead(tokenId);
    parts[6] = '</text><text x="10" y="80" class="base">';
    parts[7] = getWaist(tokenId);
    parts[8] = '</text><text x="10" y="100" class="base">';
    parts[9] = getFoot(tokenId);
    parts[10] = '</text><text x="10" y="120" class="base">';
    parts[11] = getHand(tokenId);
    parts[12] = '</text><text x="10" y="140" class="base">';
    parts[13] = getNeck(tokenId);
    parts[14] = '</text><text x="10" y="160" class="base">';
    parts[15] = getRing(tokenId);
    parts[16] = '</text></svg>';

    string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
    output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

    string memory json = Base64.encode(bytes(string(abi.encodePacked(
      '{"name": "Bag #',
      FlootConstants.toString(tokenId),
      '", "description": "Floot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Floot in any way you want.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(output)),
      '"}'
    ))));
    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
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

/**
 * @title Base64
 * @author Brecht Devos <[email protected]>
 *
 * @notice Provides a function for encoding some bytes in base64.
 */
library Base64 {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /**
   * @notice Encodes some bytes to the base64 representation.
   */
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title ERC721EnumerableOptimized
 * @author the-torn
 *
 * @notice Implementation of the ERC721Enumerable interface, gas-optimized for NFTs where:
 *   - Minting is sequential, beginning with token ID 1.
 *   - Burning is impossible.
 *
 *  IMPORTANT: Do not use this contract with NFTs where the above two conditions are not guaranteed.
 *
 *  Based on the OpenZeppelin ERC721Enumerable implementation (MIT license).
 *  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/aefcb3e8aa4ee8da8e2b7022ffe4dcb57fbb0fdf/contracts/token/ERC721/extensions/ERC721Enumerable.sol
 */
abstract contract ERC721EnumerableOptimized is
  ERC721,
  IERC721Enumerable
{
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
    return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
    require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   *
   *  As another aggressive gas cost optimization, we leave this to be implemented in the top-level
   *  minting contract.
   */
  function totalSupply() public view virtual override returns (uint256);

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
    require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
    return index + 1;
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
   * - We assume burning is not supported, so `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (
      from != address(0) &&
      from != to
    ) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }

    if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { strings } from "./strings.sol";

/**
 * @title FlootConstants
 * @author the-torn
 *
 * @notice External library for constants used by Floot.
 *
 *  This is an external library in order to keep the main contract within the bytecode limit.
 *
 *  Based closely on the original Loot implementation (MIT License).
 *  https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1
 *  The CSV optimization is owed to zefram.eth.
 */
library FlootConstants {
  using strings for string;
  using strings for strings.slice;

  enum ListName {
    WEAPON,
    CHEST,
    HEAD,
    WAIST,
    FOOT,
    HAND,
    NECK,
    RING,
    SUFFIX,
    NAME_PREFIX,
    NAME_SUFFIX
  }

  string internal constant WEAPONS = "Warhammer,Quarterstaff,Maul,Mace,Club,Katana,Falchion,Scimitar,Long Sword,Short Sword,Ghost Wand,Grave Wand,Bone Wand,Wand,Grimoire,Chronicle,Tome,Book";
  uint256 internal constant WEAPONS_LENGTH = 18;

  string internal constant CHEST_ARMOR = "Divine Robe,Silk Robe,Linen Robe,Robe,Shirt,Demon Husk,Dragonskin Armor,Studded Leather Armor,Hard Leather Armor,Leather Armor,Holy Chestplate,Ornate Chestplate,Plate Mail,Chain Mail,Ring Mail";
  uint256 internal constant CHEST_ARMOR_LENGTH = 15;

  string internal constant HEAD_ARMOR = "Ancient Helm,Ornate Helm,Great Helm,Full Helm,Helm,Demon Crown,Dragon's Crown,War Cap,Leather Cap,Cap,Crown,Divine Hood,Silk Hood,Linen Hood,Hood";
  uint256 internal constant HEAD_ARMOR_LENGTH = 15;

  string internal constant WAIST_ARMOR = "Ornate Belt,War Belt,Plated Belt,Mesh Belt,Heavy Belt,Demonhide Belt,Dragonskin Belt,Studded Leather Belt,Hard Leather Belt,Leather Belt,Brightsilk Sash,Silk Sash,Wool Sash,Linen Sash,Sash";
  uint256 internal constant WAIST_ARMOR_LENGTH = 15;

  string internal constant FOOT_ARMOR = "Holy Greaves,Ornate Greaves,Greaves,Chain Boots,Heavy Boots,Demonhide Boots,Dragonskin Boots,Studded Leather Boots,Hard Leather Boots,Leather Boots,Divine Slippers,Silk Slippers,Wool Shoes,Linen Shoes,Shoes";
  uint256 internal constant FOOT_ARMOR_LENGTH = 15;

  string internal constant HAND_ARMOR = "Holy Gauntlets,Ornate Gauntlets,Gauntlets,Chain Gloves,Heavy Gloves,Demon's Hands,Dragonskin Gloves,Studded Leather Gloves,Hard Leather Gloves,Leather Gloves,Divine Gloves,Silk Gloves,Wool Gloves,Linen Gloves,Gloves";
  uint256 internal constant HAND_ARMOR_LENGTH = 15;

  string internal constant NECKLACES = "Necklace,Amulet,Pendant";
  uint256 internal constant NECKLACES_LENGTH = 3;

  string internal constant RINGS = "Gold Ring,Silver Ring,Bronze Ring,Platinum Ring,Titanium Ring";
  uint256 internal constant RINGS_LENGTH = 5;

  string internal constant SUFFIXES = "of Power,of Giants,of Titans,of Skill,of Perfection,of Brilliance,of Enlightenment,of Protection,of Anger,of Rage,of Fury,of Vitriol,of the Fox,of Detection,of Reflection,of the Twins";
  uint256 internal constant SUFFIXES_LENGTH = 16;

  string internal constant NAME_PREFIXES = "Agony,Apocalypse,Armageddon,Beast,Behemoth,Blight,Blood,Bramble,Brimstone,Brood,Carrion,Cataclysm,Chimeric,Corpse,Corruption,Damnation,Death,Demon,Dire,Dragon,Dread,Doom,Dusk,Eagle,Empyrean,Fate,Foe,Gale,Ghoul,Gloom,Glyph,Golem,Grim,Hate,Havoc,Honour,Horror,Hypnotic,Kraken,Loath,Maelstrom,Mind,Miracle,Morbid,Oblivion,Onslaught,Pain,Pandemonium,Phoenix,Plague,Rage,Rapture,Rune,Skull,Sol,Soul,Sorrow,Spirit,Storm,Tempest,Torment,Vengeance,Victory,Viper,Vortex,Woe,Wrath,Light's,Shimmering";
  uint256 internal constant NAME_PREFIXES_LENGTH = 69;

  string internal constant NAME_SUFFIXES = "Bane,Root,Bite,Song,Roar,Grasp,Instrument,Glow,Bender,Shadow,Whisper,Shout,Growl,Tear,Peak,Form,Sun,Moon";
  uint256 internal constant NAME_SUFFIXES_LENGTH = 18;

  function getItem(
    uint256 rand,
    ListName listName
  )
    external
    pure
    returns (string memory)
  {
    if (listName == ListName.WEAPON) {
      return getItemFromCsv(WEAPONS, rand % WEAPONS_LENGTH);
    }
    if (listName == ListName.CHEST) {
      return getItemFromCsv(CHEST_ARMOR, rand % CHEST_ARMOR_LENGTH);
    }
    if (listName == ListName.HEAD) {
      return getItemFromCsv(HEAD_ARMOR, rand % HEAD_ARMOR_LENGTH);
    }
    if (listName == ListName.WAIST) {
      return getItemFromCsv(WAIST_ARMOR, rand % WAIST_ARMOR_LENGTH);
    }
    if (listName == ListName.FOOT) {
      return getItemFromCsv(FOOT_ARMOR, rand % FOOT_ARMOR_LENGTH);
    }
    if (listName == ListName.HAND) {
      return getItemFromCsv(HAND_ARMOR, rand % HAND_ARMOR_LENGTH);
    }
    if (listName == ListName.NECK) {
      return getItemFromCsv(NECKLACES, rand % NECKLACES_LENGTH);
    }
    if (listName == ListName.RING) {
      return getItemFromCsv(RINGS, rand % RINGS_LENGTH);
    }
    if (listName == ListName.SUFFIX) {
      return getItemFromCsv(SUFFIXES, rand % SUFFIXES_LENGTH);
    }
    if (listName == ListName.NAME_PREFIX) {
      return getItemFromCsv(NAME_PREFIXES, rand % NAME_PREFIXES_LENGTH);
    }
    if (listName == ListName.NAME_SUFFIX) {
      return getItemFromCsv(NAME_SUFFIXES, rand % NAME_SUFFIXES_LENGTH);
    }
    revert("Invalid list name");
  }

  /**
   * @notice Convert an integer to a string.
   *
   * Inspired by OraclizeAPI's implementation (MIT license).
   * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
   */
  function toString(
    uint256 value
  )
    internal
    pure
    returns (string memory)
  {
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
   * @notice Read an item from a string of comma-separated values.
   *
   * Based on zefram.eth's implementation (MIT license).
   * https://etherscan.io/address/0xb9310af43f4763003f42661f6fc098428469adab#code
   */
  function getItemFromCsv(
    string memory str,
    uint256 index
  )
    internal
    pure
    returns (string memory)
  {
    strings.slice memory strSlice = str.toSlice();
    string memory separatorStr = ",";
    strings.slice memory separator = separatorStr.toSlice();
    strings.slice memory item;
    for (uint256 i = 0; i <= index; i++) {
      item = strSlice.split(separator);
    }
    return item.toString();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: Apache-2.0
//
// Retrieved from https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol
// Modified to update Solidity version and include only certain functions.

pragma solidity ^0.8.0;

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */
library strings {
  struct slice {
    uint _len;
    uint _ptr;
  }

  function memcpy(uint dest, uint src, uint len) private pure {
    // Copy word-length chunks while possible
    for(; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint mask = 256 ** (32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  /*
   * @dev Returns a slice containing the entire string.
   * @param self The string to make a slice from.
   * @return A newly allocated slice containing the entire string.
   */
  function toSlice(string memory self) internal pure returns (slice memory) {
    uint ptr;
    assembly {
      ptr := add(self, 0x20)
    }
    return slice(bytes(self).length, ptr);
  }

  /*
   * @dev Copies a slice to a new string.
   * @param self The slice to copy.
   * @return A newly allocated string containing the slice's text.
   */
  function toString(slice memory self) internal pure returns (string memory) {
    string memory ret = new string(self._len);
    uint retptr;
    assembly { retptr := add(ret, 32) }

    memcpy(retptr, self._ptr, self._len);
    return ret;
  }

  // Returns the memory address of the first byte of the first occurrence of
  // `needle` in `self`, or the first byte after `self` if not found.
  function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
    uint ptr = selfptr;
    uint idx;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

        bytes32 needledata;
        assembly { needledata := and(mload(needleptr), mask) }

        uint end = selfptr + selflen - needlelen;
        bytes32 ptrdata;
        assembly { ptrdata := and(mload(ptr), mask) }

        while (ptrdata != needledata) {
          if (ptr >= end)
            return selfptr + selflen;
          ptr++;
          assembly { ptrdata := and(mload(ptr), mask) }
        }
        return ptr;
      } else {
        // For long needles, use hashing
        bytes32 hash;
        assembly { hash := keccak256(needleptr, needlelen) }

        for (idx = 0; idx <= selflen - needlelen; idx++) {
          bytes32 testHash;
          assembly { testHash := keccak256(ptr, needlelen) }
          if (hash == testHash)
            return ptr;
          ptr += 1;
        }
      }
    }
    return selfptr + selflen;
  }

  /*
   * @dev Splits the slice, setting `self` to everything after the first
   *      occurrence of `needle`, and `token` to everything before it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and `token` is set to the entirety of `self`.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @param token An output parameter to which the first token is written.
   * @return `token`.
   */
  function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
    uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
    token._ptr = self._ptr;
    token._len = ptr - self._ptr;
    if (ptr == self._ptr + self._len) {
      // Not found
      self._len = 0;
    } else {
      self._len -= token._len + needle._len;
      self._ptr = ptr + needle._len;
    }
    return token;
  }

  /*
   * @dev Splits the slice, setting `self` to everything after the first
   *      occurrence of `needle`, and returning everything before it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and the entirety of `self` is returned.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @return The part of `self` up to the first occurrence of `delim`.
   */
  function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
    split(self, needle, token);
  }
}