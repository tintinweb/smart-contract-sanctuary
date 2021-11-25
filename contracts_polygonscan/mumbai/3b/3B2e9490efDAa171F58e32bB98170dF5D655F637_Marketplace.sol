// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Marketplace/IERC2981.sol";

/**
 * @title Marketplace contract
 */
contract Marketplace {
    receive() external payable {}
    fallback() external payable {}

    event Post (
        uint256 itemId,
        address nftContract,
        uint256 tokenId,
        address seller,
        address owner,
        uint256 price
    );

    event Cancel (
        uint256 itemId,
        address nftContract,
        uint256 tokenId,
        address owner
    );

    event Sale (
        uint256 itemId,
        address nftContract,
        uint256 tokenId,
        address seller,
        address owner,
        uint256 price
    );

    struct Item {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        bool sold;
        bool cancelled;
    }

    mapping(uint256 => Item) private _tracking;

    uint256 private _itemId;

    bool private constant unlocked = true;
    bool private constant locked = false;
    bool private _gate;

    address management;

    /**
     * @dev Sets initial values for {_gate} to {_itemId}
     */
    constructor(address _management) {
        _gate = unlocked;
        _itemId = 6180339887;
        management = _management;
    }

    /**
     * @dev Posts an item onto the marketplace
     */
    function post(address nftContract, uint256 tokenId, uint256 price) public {
        require(_gate != locked, "Marketplace: reentrancy denied");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Marketplace: caller is not the owner of the token");
        require(IERC721(nftContract).getApproved(tokenId) == address(this), "Marketplace: market has not been approved");
        require(price > 0, "Marketplace: price cannot be zero");

        _gate = locked;

        _itemId += 1;
        uint256 itemId = _itemId;

        _tracking[itemId] = Item (
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            msg.sender,
            price,
            false,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit Post(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            msg.sender,
            price
        );

        _gate = unlocked;
    }

    function cancel(uint256 itemId) public {
        require(_gate != locked, "Marketplace: reentrancy denied");
        require(_tracking[itemId].sold == false, "Marketplace: item already has been sold");
        require(_tracking[itemId].owner == msg.sender, "Marketplace: not an owner");
        require(_tracking[itemId].cancelled == false, "Marketplace: item already cancelled");

        _gate = locked;

        address nftContract = _tracking[itemId].nftContract;
        uint256 tokenId = _tracking[itemId].tokenId;

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        _tracking[itemId].cancelled = true;

        emit Cancel(
            itemId,
            nftContract,
            tokenId,
            msg.sender
        );

        _gate = unlocked;
    }

    /**
     * @dev Fetches an item on the marketplace
     */
    function fetch(uint256 itemId) public view returns (address, uint256, address, address, uint256, bool, bool) {
        return (
            _tracking[itemId].nftContract,
            _tracking[itemId].tokenId,
            _tracking[itemId].seller,
            _tracking[itemId].owner,
            _tracking[itemId].price,
            _tracking[itemId].sold,
            _tracking[itemId].cancelled
        );
    }

    /**
     * @dev Checks for the ERC2981 NFT royalty stanard
     */
    function checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC165(_contract).supportsInterface(0x2a55205a);
        return success;
    }

    /**
     * @dev Sells an item for sale on the marketplace
     */
    function buy(uint256 itemId) public payable {
        require(_gate != locked, "Marketplace: reentrancy denied");
        require(_tracking[itemId].sold == false, "Marketplace: item already has been sold");
        require(_tracking[itemId].cancelled == false, "Marketplace: owner cancelled post");
        require(msg.value >= _tracking[itemId].price, "Marketplace: incorrect asking price");

        _gate = locked;

        address seller = _tracking[itemId].seller;
        address nftContract = _tracking[itemId].nftContract;
        uint256 tokenId = _tracking[itemId].tokenId;
        uint256 price = _tracking[itemId].price;

        address receiverAddress;
        uint256 royaltyFund;

        uint256 amount = msg.value;
        uint256 fee;

        if (checkRoyalties(nftContract) == true) {
            (receiverAddress, royaltyFund) = IERC2981(nftContract).royaltyInfo(tokenId, price);
            amount = price - royaltyFund;
            (bool tx1, ) = payable(receiverAddress).call{value: royaltyFund}("");
            require(tx1, "Marketplace: ether transfer to royalty receiver failed");

            fee = amount / 100;
            amount = amount - fee;
        } else {
            amount = msg.value;

            fee = amount / 100;
            amount = amount - fee;
        }

        (bool tx2, ) = payable(seller).call{value: amount}("");
        require(tx2, "Marketplace: ether transfer to sell failed");

        (bool tx3, ) = payable(management).call{value: fee}("");
        require(tx3, "Marketplace: ether transfer to management failed");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        _tracking[itemId].owner = msg.sender;

        _tracking[itemId].sold = true;

        emit Sale(
            itemId,
            nftContract,
            tokenId,
            seller,
            msg.sender,
            msg.value
        );

        _gate = unlocked;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @dev Interface of the ERC2981 standard as defined in the EIP
 */
interface IERC2981 is IERC721 {
    /**
     * @dev ERC2891 standard functions
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface of the ERC721 standard as defined in the EIP
 */
interface IERC721 is IERC165 {
    /**
     * @dev ERC721 standard functions
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev ERC721 standard events
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard as defined in the EIP
 */
interface IERC165 {
    /**
     * @dev ERC165 standard functions
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}