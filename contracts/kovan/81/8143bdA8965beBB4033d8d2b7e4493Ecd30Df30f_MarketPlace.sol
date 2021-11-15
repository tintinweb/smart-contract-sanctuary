// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IERC721.sol";
import "./libs/DoubleLinkedList.sol";

contract MarketPlace {
    using DoubleLinkedList for DoubleLinkedList.LinkedList;

    struct Image {
        string imageUrl;
        uint256 imagePrice;
        address imageSeller;
        bool isOnActiveSale;
    }

    mapping(uint256 => Image) public imageFromId;
    mapping(address => DoubleLinkedList.LinkedList) public ownedImages;

    IERC721 public imagesContract;

    uint256 public totalIds;

    constructor(address imagesContract_) public {
        imagesContract = IERC721(imagesContract_);
    }

    function sellNewImage(string memory imageUrl, uint256 price) external {
        totalIds += 1;
        Image memory image;

        image.imageUrl = imageUrl;
        image.imagePrice = price;
        image.imageSeller = msg.sender;
        image.isOnActiveSale = true;

        imageFromId[totalIds] = image;

        imagesContract.mint(address(this), totalIds);

        ownedImages[msg.sender].addNode(totalIds);
    }

    function sellExistingImage(uint256 imageId, uint256 price) external {
        require(imagesContract.ownerOf(imageId) == msg.sender, "Can only sell image that you own");

        imageFromId[imageId].imagePrice = price;
        imageFromId[imageId].imageSeller = msg.sender;
        imageFromId[imageId].isOnActiveSale = true;

        imagesContract.safeTransferFrom(msg.sender, address(this), imageId);
    }

    function cancelSellingOfImage(uint256 imageId) external {
        require(imageFromId[imageId].isOnActiveSale, "Cannot cancel if not on sale");
        require(imageFromId[imageId].imageSeller == msg.sender, "Cannot cancel if not the seller");

        imageFromId[imageId].isOnActiveSale = false;

        imagesContract.safeTransferFrom(address(this), msg.sender, imageId);
    }

    function purchaseImage(uint256 imageId) external payable {
        require(msg.value == imageFromId[imageId].imagePrice, "Should have payed just enough");

        imageFromId[imageId].isOnActiveSale = false;
        imageFromId[imageId].imageSeller = msg.sender;

        // Transfer image to purchaser
        imagesContract.safeTransferFrom(address(this), msg.sender, imageId);

        // Transfer ether to seller
        address(uint160(imageFromId[imageId].imageSeller)).transfer(msg.value);

        ownedImages[msg.sender].addNode(imageId);
        ownedImages[imageFromId[imageId].imageSeller].removeNode(imageId);
    }

    function getOwnedImages(address account) external view returns (uint256[] memory) {
        return ownedImages[account].getAllItems();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title Double linked-list
 */
library DoubleLinkedList {
    struct Node {
        uint256 next;
        uint256 previous;
    }

    struct LinkedList {
        uint256 head;
        uint256 tail;
        uint256 size;
        mapping(uint256 => Node) nodes;
    }

    /**
     * @notice Get Head ID
     * @param self the LinkedList
     * @return the first item of the list
     */
    function getHeadId(LinkedList storage self) internal view returns (uint256) {
        return self.head;
    }

    /**
     * @notice Get list size
     * @param self the LinkedList
     * @return the size of the list
     */
    function getSize(LinkedList storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @notice Adds a new node to the list
     * @param self the LinkedList
     * @param id the node to add
     */
    function addNode(LinkedList storage self, uint256 id) internal {
        require(id != 0, "Id should be different from zero");

        //If empty
        if (self.head == 0) {
            self.head = id;
            self.tail = id;
        }
        //Else push in tail
        else {
            uint256 tail = self.tail;
            self.nodes[tail].next = id;
            self.nodes[id] = Node(0, tail);
            self.tail = id;
        }

        self.size += 1;
    }

    /**
     * @notice Removes node from the list
     * @param self the LinkedList
     * @param id the id of the node to remove
     */
    function removeNode(LinkedList storage self, uint256 id) internal {
        require(self.size > 0, "Cannot remove an item from an empty list");
        require(id != 0, "Id should be different from zero");

        uint256 head = self.head;
        uint256 tail = self.tail;

        if (self.size == 1) {
            self.head = 0;
            self.tail = 0;
        } else if (id == head) {
            self.head = self.nodes[head].next;
            // head was updated previously, so we can't use the memory variable here
            self.nodes[self.head].previous = 0;
        } else if (id == tail) {
            self.tail = self.nodes[tail].previous;
            // tail was updated previously, so we can't use the memory variable here
            self.nodes[self.tail].next = 0;
        } else {
            self.nodes[self.nodes[id].next].previous = self.nodes[id].previous;
            self.nodes[self.nodes[id].previous].next = self.nodes[id].next;
        }

        delete self.nodes[id];
        self.size -= 1;
    }

    function getAllItems(LinkedList storage self) internal view returns (uint256[] memory) {
        uint256[] memory items = new uint256[](self.size);
        if (self.size == 0) {
            return items;
        }

        uint256 nodeId = self.head;

        for (uint256 i = 0; i < self.size; i++) {
            items[i] = nodeId;
            nodeId = self.nodes[nodeId].next;
        }

        return items;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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

    function mint(address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

