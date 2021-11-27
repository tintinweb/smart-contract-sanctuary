// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TokenTx/IERC2981.sol";
import "./TokenTx/IERC721Metadata.sol";

/**
 * @title TokenTx contract
 */
contract TokenTx {
    receive() external payable {}
    fallback() external payable {}

    event Post (
        uint256 itemId,
        address nftContract,
        uint256 tokenId,
        string uri,
        address seller,
        uint256 price,
        uint256 timer
    );

    event Cancel (
        uint256 itemId,
        address nftContract,
        uint256 tokenId,
        string uri,
        address owner
    );

    event Purchase (
        uint256 itemId,
        address nftContract,
        uint256 tokenId,
        string uri,
        address seller,
        address owner,
        uint256 price
    );

    struct Item {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        string uri;
        address seller;
        address owner;
        uint256 price;
        uint256 timer;
        uint256 limit;
        address bidder;
        bool available;
    }

    mapping (uint256 => Item) private _tracking;

    uint256 private _itemId;

    bool private constant unlocked = true;
    bool private constant locked = false;
    bool private _gate;

    address management;

    /**
     * @dev Sets values for {_gate} {_itemId} and {management}
     */
    constructor(address _management) {
        _gate = unlocked;
        _itemId = 100;
        management = _management;
    }

    /**
     * @dev Posts an item for sale
     */
    function post(address nftContract, uint256 tokenId, uint256 price, uint256 dayTimer) public {
        require(_gate != locked, "TokenTx: reentrancy denied");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "TokenTx: caller is not the owner of the token");
        require(IERC721(nftContract).getApproved(tokenId) == address(this), "TokenTx: marketplace has not been approved");
        require(price > 0, "TokenTx: price cannot be zero");
        require(dayTimer < 30, "TokenTx: auction cannot be for more than 30 days");

        _gate = locked;

        string memory uri;

        if (IERC165(nftContract).supportsInterface(0x5b5e139f) == true) {
            uri = IERC721Metadata(nftContract).tokenURI(tokenId);
        } else {
            uri = "";
        }

        if (dayTimer >= 1) {
            uint256 timer = dayTimer;
            uint256 limit = block.timestamp + (dayTimer * 86400);

            _itemId += 1;
            uint256 itemId = _itemId * 476;

            _tracking[itemId] = Item (
                itemId,
                nftContract,
                tokenId,
                uri,
                msg.sender,
                msg.sender,
                price,
                timer,
                limit,
                address(0),
                true
            );

            emit Post (
                itemId,
                nftContract,
                tokenId,
                uri,
                msg.sender,
                price,
                timer
            );
        } else {
            uint256 timer = 0;
            uint256 limit = 0;

            _itemId += 1;
            uint256 itemId = _itemId * 476;

            _tracking[itemId] = Item (
                itemId,
                nftContract,
                tokenId,
                uri,
                msg.sender,
                msg.sender,
                price,
                timer,
                limit,
                address(0),
                true
            );

            emit Post (
                itemId,
                nftContract,
                tokenId,
                uri,
                msg.sender,
                price,
                timer
            );
        }

        _gate = unlocked;
    }

    /**
     * @dev Cancels an item from being sold
     */
    function cancel(uint256 itemId) public {
        require(_gate != locked, "TokenTx: reentrancy denied");
        require(_tracking[itemId].available == true, "TokenTx: item is already unavailable");
        require(
            IERC721(_tracking[itemId].nftContract).ownerOf(_tracking[itemId].tokenId) == msg.sender,
            "TokenTx: caller is not the owner of the token"
        );

        _gate = locked;

        address nftContract = _tracking[itemId].nftContract;
        uint256 tokenId = _tracking[itemId].tokenId;
        string memory uri = _tracking[itemId].uri;

        _tracking[itemId].available = false;

        emit Cancel (
            itemId,
            nftContract,
            tokenId,
            uri,
            msg.sender
        );

        _gate = unlocked;
    }

    /**
     * @dev Fetches an item
     */
    function fetch(uint256 itemId) public view returns (address, uint256, string memory, address, address, uint256, bool) {
        return (
            _tracking[itemId].nftContract,
            _tracking[itemId].tokenId,
            _tracking[itemId].uri,
            _tracking[itemId].seller,
            IERC721(_tracking[itemId].nftContract).ownerOf(_tracking[itemId].tokenId),
            _tracking[itemId].price,
            _tracking[itemId].available
        );
    }

    /**
     * @dev Returns claim status for bidder
     */
    function status(uint256 itemId) public view returns (address, uint256, uint256, address, uint256, bool) {
        bool _claimStatus;
        uint256 _timeRemaining;

        if (_tracking[itemId].limit < block.timestamp) {
            _claimStatus = true;
            
            if (_tracking[itemId].available == false) {
                _claimStatus = false;
            } else {
                _claimStatus = true;
            }

            _timeRemaining = 0;
        } else {
            _claimStatus = false;

            _timeRemaining = _tracking[itemId].limit - block.timestamp;
        }
        return (
            _tracking[itemId].nftContract,
            _tracking[itemId].tokenId,
            _tracking[itemId].price,
            _tracking[itemId].bidder,
            _timeRemaining,
            _claimStatus
        );
    }

    /**
     * @dev Bids on an item
     */
    function bid(uint256 itemId, uint256 amount) public {
        require(_gate != locked, "TokenTx: reentrancy denied");
        require(_tracking[itemId].timer >= 1, "TokenTx: not an auctionable item");
        require(_tracking[itemId].limit >= block.timestamp, "TokenTx: auction has expired");
        require(_tracking[itemId].price < amount, "TokenTx: bid must be greater than price");

        _gate = locked;

        uint256 price;
        price = amount;
        address bidder = msg.sender;

        _tracking[itemId] = Item (
            itemId,
            _tracking[itemId].nftContract,
            _tracking[itemId].tokenId,
            _tracking[itemId].uri,
            _tracking[itemId].seller,
            _tracking[itemId].owner,
            price,
            _tracking[itemId].timer,
            _tracking[itemId].limit,
            bidder,
            true
        );

        _gate = unlocked;
    }

    /**
     * @dev Purchases an item
     */
    function purchase(uint256 itemId) public payable {
        require(_gate != locked, "TokenTx: reentrancy denied");
        require(_tracking[itemId].available == true, "TokenTx: item is unavailable");
        require(
            IERC721(_tracking[itemId].nftContract).ownerOf(_tracking[itemId].tokenId) == _tracking[itemId].owner,
            "TokenTx: seller is not the owner of the token anymore"
        );
        require(
            IERC721(_tracking[itemId].nftContract).getApproved(_tracking[itemId].tokenId) == address(this),
            "TokenTx: marketplace has not been approved"
        );
        require(msg.value >= _tracking[itemId].price, "TokenTx: incorrect asking price");

        _gate = locked;

        address tokenReceiver;

        if (_tracking[itemId].timer >= 1) {
            require(_tracking[itemId].limit < block.timestamp, "TokenTx: auction has not completed");
            require(_tracking[itemId].bidder == msg.sender, "TokenTx: caller not the highest bidder");

            tokenReceiver = msg.sender;
        } else {
            require(_tracking[itemId].timer == 0, "TokenTx: access denied");
            require(_tracking[itemId].limit == 0, "TokenTx: access denied");
            require(_tracking[itemId].bidder == address(0), "TokenTx: access denied");

            tokenReceiver = msg.sender;
        }

        address seller = _tracking[itemId].seller;
        address nftContract = _tracking[itemId].nftContract;
        uint256 tokenId = _tracking[itemId].tokenId;
        string memory uri = _tracking[itemId].uri;
        uint256 price = _tracking[itemId].price;

        address receiverAddress;
        uint256 royaltyFund;

        uint256 amount = msg.value;
        uint256 fee;

        if (IERC165(nftContract).supportsInterface(0x2a55205a) == true) {
            (receiverAddress, royaltyFund) = IERC2981(nftContract).royaltyInfo(tokenId, price);
            amount = price - royaltyFund;
            (bool tx1, ) = payable(receiverAddress).call{value: royaltyFund}("");
            require(tx1, "TokenTx: ether transfer to royalty receiver failed");

            fee = amount / 100;
            amount = amount - fee;
        } else {
            amount = msg.value;

            fee = amount / 100;
            amount = amount - fee;
        }

        (bool tx2, ) = payable(seller).call{value: amount}("");
        require(tx2, "TokenTx: ether transfer to sell failed");

        (bool tx3, ) = payable(management).call{value: fee}("");
        require(tx3, "TokenTx: ether transfer to management failed");

        IERC721(nftContract).transferFrom(seller, tokenReceiver, tokenId);

        _tracking[itemId].owner = tokenReceiver;

        _tracking[itemId].available = false;

        emit Purchase (
            itemId,
            nftContract,
            tokenId,
            uri,
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

import "./IERC721.sol";

/**
 * @title ERC721 token metadata extension
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev ERC721 token metadata functions
     */
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
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