// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./Office.sol";
import "./Helpers.sol";

contract Pixxiti is Office, Helpers {
  //cursors
  uint16 public currentIndex;
  uint16 public lastIndex;
  uint16 public chiefIndex;
  uint16 private nextIndex;

  // conditions
  uint16 public totalLength;
  uint16 public blockCount;
  uint16 public rate;

  // price
  uint public startPrice;
  uint public currentPrice;

  // restarts
  uint public endBlockNumber;

  struct Track {
    uint16 lastIndex;
    uint16 length;
    address owner;
    address nft;
    uint value;
    uint blockNumber;
    uint tokenId;
    string tokenUri;
  }

  mapping(uint => Track) tracks;

  event Record(
    uint16 _lastIndex,
    uint16 _length,
    address indexed _owner,
    address indexed _nft,
    uint _value,
    uint _blockNumber,
    uint _tokenId,
    string _tokenUri
  );

  constructor(
    uint16 _totalLength,
    uint _startPrice,
    uint16 _rate,
    uint16 _blockCount
  ) {
    totalLength = _totalLength;
    startPrice = _startPrice;
    currentPrice = _startPrice;
    nextIndex = 0;
    rate = _rate;
    blockCount = _blockCount;
    endBlockNumber = block.number + blockCount;
  }

  function getNextTrackIndex(
    uint16 _currentIndex,
    uint16 _length,
    uint16 _totalLength
  ) private pure returns (uint16) {
    return (_currentIndex + _length) % _totalLength;
  }

  function returnTrack(
    uint _index
  ) internal view returns (
    uint16,
    uint16,
    address,
    address,
    uint,
    uint,
    uint,
    string memory
  ) {
    Track memory track = tracks[_index];
    return (
      track.lastIndex,
      track.length,
      track.owner,
      track.nft,
      track.value,
      track.blockNumber,
      track.tokenId,
      track.tokenUri
    );
  }

  function nthPreviousTrack(
    uint _index,
    uint _n
  ) internal view returns (
    uint16,
    uint16,
    address,
    address,
    uint,
    uint,
    uint,
    string memory
  ) {
    if (_n == 0) {
      return returnTrack(_index);
    }
    return nthPreviousTrack(tracks[_index].lastIndex, _n - 1);
  }

  function getNthLastTrack(
    uint _n
  ) public view returns (
    uint16,
    uint16,
    address,
    address,
    uint,
    uint,
    uint,
    string memory
  ) {
    return nthPreviousTrack(currentIndex, _n);
  }

  function getCurrentTrack() public view returns (
    uint16,
    uint16,
    address,
    address,
    uint,
    uint,
    uint,
    string memory
  ) {
    return returnTrack(currentIndex);
  }

  function getLastTrack() public view returns (
    uint16,
    uint16,
    address,
    address,
    uint,
    uint,
    uint,
    string memory
  ) {
    return returnTrack(lastIndex);
  }

  function getChiefTrack() public view returns (
    uint16,
    uint16,
    address,
    address,
    uint,
    uint,
    uint,
    string memory
  ) {
    return returnTrack(chiefIndex);
  }

  function getTrackByIndex(uint16 _index) public view returns (
    uint16,
    uint16,
    address,
    address,
    uint,
    uint,
    uint,
    string memory
  ) {
    return returnTrack(_index);
  }

  function moveCursor(uint16 _length) private {
    uint16 newIndex = getNextTrackIndex(nextIndex, _length, totalLength);
    // if we wrap around
    if (newIndex < nextIndex || totalLength <= _length) {
      chiefIndex = nextIndex;
    }
    lastIndex = currentIndex;
    currentIndex = nextIndex;
    nextIndex = newIndex;
  }

  function addTrack(
    uint16 _length,
    address _nft,
    uint _tokenId,
    string memory _tokenUri
  ) private {
    Track storage newTrack = tracks[currentIndex];
    newTrack.lastIndex = lastIndex;
    newTrack.length = _length;
    newTrack.owner = msg.sender;
    newTrack.nft = _nft;
    newTrack.value = msg.value;
    newTrack.blockNumber = block.number;
    newTrack.tokenId = _tokenId;
    newTrack.tokenUri = _tokenUri;

    emit Record(
      lastIndex,
      _length,
      msg.sender,
      _nft,
      msg.value,
      block.number,
      _tokenId,
      _tokenUri
    );
  }

  function restartRound() private {
    currentPrice = startPrice;
    endBlockNumber = block.number + blockCount;
  }

  function setNewPrice(uint newPrice) private {
    if (block.number >= endBlockNumber) {
      restartRound();
    } else {
      currentPrice = newPrice;
    }
  }

  function record(
    IERC721Metadata _addy,
    uint256 _tokenId,
    uint16 _trackLength
  ) public payable {

    string memory tokenUri = getTokenURI(_addy, _tokenId);

    uint unitPrice = getUnitPrice(
      rate,
      _trackLength,
      totalLength,
      msg.value,
      currentPrice
    );

    moveCursor(_trackLength);
    addTrack(
      _trackLength,
      address(_addy),
      _tokenId,
      tokenUri
    );
    setNewPrice(unitPrice);
  }
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

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";

// Welcome to the office (rip)
// Business logic can be found here

contract Office is Ownable {
  // thank you supporting our project! <3
  function ownerWithdraw() public onlyOwner {
    address payable addr = payable(owner());
    (bool success, ) = addr.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

abstract contract Helpers {
  function getTokenURI(IERC721Metadata addy, uint256 tokenId)
  internal view returns (string memory) {
    require(
        addy.supportsInterface(type(IERC721Metadata).interfaceId),
        "Address is not supported."
    );
    require(
      addy.ownerOf(tokenId) == msg.sender,
      "Must be owner to place ERC721"
    );
    return addy.tokenURI(tokenId);
  }

  function getUnitPrice(
    uint16 _rate,
    uint16 _frameLength,
    uint16 _totalLength,
    uint _value,
    uint _currentPrice
  ) internal pure returns (uint) {
    require(_frameLength >= 1 && _frameLength <= _totalLength);
    uint minPrice =
      _currentPrice + mulScale(
        _currentPrice,
        _rate,
        10000
      );
    uint unitPrice = mulScale(_value, 1, _frameLength);

    require(
      unitPrice >= minPrice,
      "Value does not meet placement requirements"
    );

    return unitPrice;
  }

  function mulScale(uint x, uint16 y, uint16 scale)
    internal pure returns (uint)
  {
    uint a = x / scale;
    uint b = x % scale;
    uint c = y / scale;
    uint d = y % scale;

    return a * c * scale + a * d + b * c + b * d / scale;
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}