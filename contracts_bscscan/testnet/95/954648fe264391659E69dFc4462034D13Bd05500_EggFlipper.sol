//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./TransferHelper.sol";

contract EggFlipper is Context {
  // mainnet
  // address public constant ANML_TOKEN_ADDRESS = 0x91109c6e2AaF421456aafAb4ba3a122A95b46B28;
  // testnet
  address public constant ANML_TOKEN_ADDRESS = 0x030b97ccD62d07864139c029bE725E677A0bE897;

  // mainnet
  // address public constant ZOO_TOKEN_ADDRESS = 0x19263F2b4693da0991c4Df046E4bAA5386F5735E;
  // testnet
  address public constant ZOO_TOKEN_ADDRESS = 0x34f3F270B85532f32c6F8039B960c569816Fc67a;

  uint256 public constant PERCENTAGE_ZOO_BURN = 7;
  address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  struct Listing {
    uint256 tokenId;
    address seller;
    uint256 zooSellerReward;
    uint256 zooPrice;
  }

  struct Entry {
    uint256 index;
    Listing value;
  }

  event ListingCreated(uint256 indexed tokendId, address indexed seller, uint256 zooPrice);

  event ListingDeleted(uint256 indexed tokendId, address indexed seller, uint256 zooPrice);

  event ListingSold(uint256 indexed tokendId, address indexed seller, uint256 zooPrice, address indexed buyer);

  IERC721 private anmlToken;

  mapping(uint256 => Entry) private map;
  uint256[] private keyList;

  mapping(uint256 => uint256) public lastZooPrice;

  constructor() {
    anmlToken = IERC721(ANML_TOKEN_ADDRESS);
  }

  function unlistAnml(uint256 _tokenId) external {
    Listing memory listing = getListingByTokenId(_tokenId);

    require(listing.seller == _msgSender(), "msg.sender is not seller");
    anmlToken.safeTransferFrom(address(this), _msgSender(), _tokenId);

    emit ListingDeleted(_tokenId, listing.seller, listing.zooPrice);
    remove(_tokenId);
  }

  function listAnml(uint256 _tokenId, uint256 _zooSellerReward) external {
    require(!isTokenListed(_tokenId), "tokenId is already listed");
    require(anmlToken.ownerOf(_tokenId) == _msgSender(), "msg.sender does not own token");
    require(_zooSellerReward > 0, "can't sell token for free");

    anmlToken.safeTransferFrom(_msgSender(), address(this), _tokenId);
    uint256 zooPrice = (_zooSellerReward * (100 + PERCENTAGE_ZOO_BURN)) / 100;
    add(
      _tokenId,
      Listing({ tokenId: _tokenId, seller: _msgSender(), zooSellerReward: _zooSellerReward, zooPrice: zooPrice })
    );

    emit ListingCreated(_tokenId, _msgSender(), zooPrice);
  }

  function buyAnml(uint256 _tokenId) external {
    require(isTokenListed(_tokenId), "tokenId is not listed");

    Listing memory listing = getListingByTokenId(_tokenId);
    require(listing.seller != _msgSender(), "seller can not buy own listing");

    TransferHelper.safeTransferFrom(ZOO_TOKEN_ADDRESS, _msgSender(), address(this), listing.zooPrice);
    TransferHelper.safeTransfer(ZOO_TOKEN_ADDRESS, listing.seller, listing.zooSellerReward);
    TransferHelper.safeTransfer(ZOO_TOKEN_ADDRESS, BURN_ADDRESS, listing.zooPrice - listing.zooSellerReward);

    anmlToken.safeTransferFrom(address(this), _msgSender(), _tokenId);
    lastZooPrice[_tokenId] = listing.zooPrice;

    emit ListingSold(_tokenId, listing.seller, listing.zooPrice, _msgSender());
    remove(_tokenId);
  }

  function add(uint256 _tokenId, Listing memory _value) private {
    Entry storage entry = map[_tokenId];
    entry.value = _value;
    require(entry.index == 0, "anml already listed");
    keyList.push(_tokenId);
    uint256 keyListIndex = keyList.length - 1;
    entry.index = keyListIndex + 1;
  }

  function remove(uint256 _tokenId) private {
    Entry storage entry = map[_tokenId];
    require(entry.index != 0, "animl not listed");
    require(entry.index <= keyList.length, "invalid index value");

    // Move an last element of array into the vacated key slot.
    uint256 keyListIndex = entry.index - 1;
    uint256 keyListLastIndex = keyList.length - 1;
    map[keyList[keyListLastIndex]].index = keyListIndex + 1;
    keyList[keyListIndex] = keyList[keyListLastIndex];
    keyList.pop();
    delete map[_tokenId];
  }

  function numberOfListedToken() public view returns (uint256) {
    return uint256(keyList.length);
  }

  function allListings() public view returns (Listing[] memory) {
    Listing[] memory tempListings = new Listing[](numberOfListedToken());
    for (uint256 i = 0; i < numberOfListedToken(); i++) {
      tempListings[i] = getListingByIndex(i);
    }
    return tempListings;
  }

  function isTokenListed(uint256 _tokenId) public view returns (bool) {
    return map[_tokenId].index > 0;
  }

  function getListingByTokenId(uint256 _tokenId) public view returns (Listing memory) {
    return map[_tokenId].value;
  }

  function getListingByIndex(uint256 _index) public view returns (Listing memory) {
    require(_index >= 0, "index out of range");
    require(_index < keyList.length, "index out of range");
    return map[keyList[_index]].value;
  }

  function getListedTokenIds() external view returns (uint256[] memory) {
    return keyList;
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
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

