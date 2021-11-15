import "./IKetherHomepage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library KetherView {
  struct AdView {
    address owner;
    uint x;
    uint y;
    uint width;
    uint height;
    string link;
    string image;
    string title;
    bool NSFW;
    bool forceNSFW;
    bool wrapped;
  }
  /// allAds is a helper view designed to be called from frontends that want to
  /// display all of the ads with their correct NFT owners.
  function allAds(address _instanceAddress, address _nftAddress) external view returns (AdView[] memory) {
    // FIXME: Does this actually enumerate all of the ads, or do we need to paginate?
    AdView[] memory ads_ = new AdView[](IKetherHomepage(_instanceAddress).getAdsLength());

    for (uint idx=0; idx<ads_.length; idx++) {
      (address owner, uint x, uint y, uint width, uint height, string memory link, string memory image, string memory title, bool NSFW, bool forceNSFW) = IKetherHomepage(_instanceAddress).ads(idx);
      bool wrapped = false;

      // Is it an NFT already?
      if (owner == _nftAddress) {
        // Override owner to be the NFT owner
        owner = IERC721(_nftAddress).ownerOf(idx);
        wrapped = true;
      }

      ads_[idx] = AdView(owner, x, y, width, height, link, image, title, NSFW, forceNSFW, wrapped);
    }
    return ads_;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IKetherHomepage {
    struct Ad {
        address owner;
        uint x;
        uint y;
        uint width;
        uint height;
        string link;
        string image;
        string title;
        bool NSFW;
        bool forceNSFW;
    }

    /// Buy is emitted when an ad unit is reserved.
    event Buy(
        uint indexed idx,
        address owner,
        uint x,
        uint y,
        uint width,
        uint height
    );

    /// Publish is emitted whenever the contents of an ad is changed.
    event Publish(
        uint indexed idx,
        string link,
        string image,
        string title,
        bool NSFW
    );

    /// SetAdOwner is emitted whenever the ownership of an ad is transfered
    event SetAdOwner(
        uint indexed idx,
        address from,
        address to
    );

    /// ads are stored in an array, the id of an ad is its index in this array.
    function ads(uint _idx) external view returns (address,uint,uint,uint,uint,string memory,string memory,string memory,bool,bool);

    function buy(uint _x, uint _y, uint _width, uint _height) external payable returns (uint idx);

    function publish(uint _idx, string calldata _link, string calldata _image, string calldata _title, bool _NSFW) external;

    function setAdOwner(uint _idx, address _newOwner) external;

    function forceNSFW(uint _idx, bool _NSFW) external;

    function withdraw() external;

    function getAdsLength() view external returns (uint);
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

