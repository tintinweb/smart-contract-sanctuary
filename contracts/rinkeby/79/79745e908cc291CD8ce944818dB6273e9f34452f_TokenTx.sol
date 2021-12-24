// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TokenTx/IERC2981.sol";
import "./TokenTx/IERC721Metadata.sol";
import "./TokenTx/IManagement.sol";

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

    event Bid (
        uint256 itemId,
        address nftContract,
        uint256 tokenId,
        string uri,
        address bidder,
        address seller,
        uint256 price
    );

    event Swap (
        address nftContract1,
        uint256 tokenId1,
        address initialOwner1,
        address newOwner1,
        address nftContract2,
        uint256 tokenId2,
        address initialOwner2,
        address newOwner2
    );

    struct Item {
        uint256 saleId;
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
    mapping (address => address) private _contractTrace;
    mapping (address => uint256) private _tokenTrace;
    mapping (address => uint256) private _addressTrace;

    uint256 private _saleId;

    bool private constant unlocked = true;
    bool private constant locked = false;
    bool private _gate;

    address treasury;

    IManagement Management;

    /**
     * @dev Sets values for {_gate} {_itemId} and {treasury}
     */
    constructor(address _treasury, address _management) {
        _gate = unlocked;
        _saleId = 100;
        treasury = _treasury;
        Management = IManagement(_management);
    }

    modifier gate() {
        require(_gate != locked, "TokenTx: reentrancy denied");

        _gate = locked;
        _;
        _gate = unlocked;
    }

    /**
     * @dev ERC721 token search for entire blockchain
     */
    function networkTokenSearch(address nftContract, uint256 tokenId) public view returns (string memory, string memory, string memory, address) {
        string memory name;
        string memory symbol;
        string memory uri;
        address owner;

        if (IERC165(nftContract).supportsInterface(0x5b5e139f) == true) {
            name = IERC721Metadata(nftContract).name();
            symbol = IERC721Metadata(nftContract).symbol();
            uri = IERC721Metadata(nftContract).tokenURI(tokenId);
        } else {
            name = "";
            symbol = "";
            uri = "";
        }

        owner = IERC2981(nftContract).ownerOf(tokenId);

        return (
            name,
            symbol,
            uri,
            owner
        );
    }

    /**
     * @dev Posts an item for sale
     */
    function sellToken(address nftContract, uint256 tokenId, uint256 price, uint256 dayTimer) public gate() {
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "TokenTx: caller is not the owner of the token");
        require(IERC721(nftContract).getApproved(tokenId) == address(this), "TokenTx: marketplace has not been approved");
        require(price > 0, "TokenTx: price cannot be zero");
        require(dayTimer < 30, "TokenTx: auction cannot be for more than 30 days");

        string memory uri;

        if (IERC165(nftContract).supportsInterface(0x5b5e139f) == true) {
            uri = IERC721Metadata(nftContract).tokenURI(tokenId);
        } else {
            uri = "";
        }

        if (dayTimer >= 1) {
            uint256 timer = dayTimer;
            uint256 limit = block.timestamp + (dayTimer * 86400);

            _saleId += 1;
            uint256 saleId = _saleId * 476;

            _addressTrace[msg.sender] = saleId;

            _tracking[saleId] = Item (
                saleId,
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
                saleId,
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

            _saleId += 1;
            uint256 saleId = _saleId * 476;

            _addressTrace[msg.sender] = saleId;

            _tracking[saleId] = Item (
                saleId,
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
                saleId,
                nftContract,
                tokenId,
                uri,
                msg.sender,
                price,
                timer
            );
        }
    }

    /**
     * @dev Cancels an item from being sold
     */
    function getMySaleId() public view returns (uint256) {
        return (_addressTrace[msg.sender]);
    }

    /**
     * @dev Cancels an item from being sold
     */
    function cancelSale(uint256 saleId) public gate() {
        require(_tracking[saleId].available == true, "TokenTx: item is already unavailable");
        require(
            IERC721(_tracking[saleId].nftContract).ownerOf(_tracking[saleId].tokenId) == msg.sender,
            "TokenTx: caller is not the owner of the token"
        );

        address nftContract = _tracking[saleId].nftContract;
        uint256 tokenId = _tracking[saleId].tokenId;
        string memory uri = _tracking[saleId].uri;

        _tracking[saleId].available = false;

        emit Cancel (
            saleId,
            nftContract,
            tokenId,
            uri,
            msg.sender
        );
    }

    /**
     * @dev Fetches a token in the marketplace
     */
    function fetchToken(uint256 saleId) public view returns (address, uint256, string memory, address, address, uint256, bool) {
        return (
            _tracking[saleId].nftContract,
            _tracking[saleId].tokenId,
            _tracking[saleId].uri,
            _tracking[saleId].seller,
            IERC721(_tracking[saleId].nftContract).ownerOf(_tracking[saleId].tokenId),
            _tracking[saleId].price,
            _tracking[saleId].available
        );
    }

    /**
     * @dev Returns status for auction sale
     */
    function auctionStatus(uint256 saleId) public view returns (address, uint256, uint256, address, uint256, bool) {
        require(_tracking[saleId].timer >= 1, "TokenTx: not an auctionable item");
        
        bool _claimStatus;
        uint256 _timeRemaining;

        if (_tracking[saleId].limit < block.timestamp) {
            if (_tracking[saleId].available == false) {
                _claimStatus = false;
            } else {
                if (_tracking[saleId].limit == 0) {
                    _claimStatus = false;
                } else {
                    _claimStatus = true;
                    _timeRemaining = 0;
                }
            }
        } else {
            _claimStatus = false;
            _timeRemaining = _tracking[saleId].limit - block.timestamp;
        }
        return (
            _tracking[saleId].nftContract,
            _tracking[saleId].tokenId,
            _tracking[saleId].price,
            _tracking[saleId].bidder,
            _timeRemaining,
            _claimStatus
        );
    }

    /**
     * @dev Swaps NFTs
     */
    function swapToken(address nftContract, uint256 tokenId, address nftContractSwap, uint256 tokenIdSwap) public payable gate() {
        require(msg.value >= Management.fee());
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "TokenTx: caller is not the owner of the token");
        require(IERC721(nftContract).getApproved(tokenId) == address(this), "TokenTx: marketplace has not been approved");

        _contractTrace[msg.sender] = nftContractSwap;
        _tokenTrace[msg.sender] = tokenIdSwap;

        address requestSwapOwner = IERC721(nftContractSwap).ownerOf(tokenIdSwap);

        if (_contractTrace[requestSwapOwner] == nftContract && _tokenTrace[requestSwapOwner] == tokenId) {
            require(IERC721(nftContractSwap).getApproved(tokenIdSwap) == address(this), "TokenTx: marketplace has not been approved");
            IERC721(nftContractSwap).transferFrom(requestSwapOwner, msg.sender, tokenIdSwap);
            IERC721(nftContract).transferFrom(msg.sender, requestSwapOwner, tokenId);

            emit Swap (
                nftContractSwap,
                tokenIdSwap,
                requestSwapOwner,
                msg.sender,
                nftContract,
                tokenId,
                msg.sender,
                requestSwapOwner
            );
        } else {}
    }

    /**
     * @dev Bids on token in the marketplace
     */
    function bid(uint256 saleId, uint256 amount) public gate() {
        require(_tracking[saleId].timer >= 1, "TokenTx: not an auctionable item");
        require(_tracking[saleId].limit >= block.timestamp, "TokenTx: auction has expired");
        require(_tracking[saleId].price < amount, "TokenTx: bid must be greater than price");

        uint256 price;
        price = amount;
        address bidder = msg.sender;

        _tracking[saleId] = Item (
            saleId,
            _tracking[saleId].nftContract,
            _tracking[saleId].tokenId,
            _tracking[saleId].uri,
            _tracking[saleId].seller,
            _tracking[saleId].owner,
            price,
            _tracking[saleId].timer,
            _tracking[saleId].limit,
            bidder,
            true
        );

        emit Bid (
            saleId,
            _tracking[saleId].nftContract,
            _tracking[saleId].tokenId,
            _tracking[saleId].uri,
            msg.sender,
            _tracking[saleId].seller,
            price
        );
    }

    /**
     * @dev Purchases a token from the marketplace
     */
    function buyToken(uint256 saleId) public payable gate() {
        require(_tracking[saleId].available == true, "TokenTx: item is unavailable");
        require(
            IERC721(_tracking[saleId].nftContract).ownerOf(_tracking[saleId].tokenId) == _tracking[saleId].owner,
            "TokenTx: seller is not the owner of the token anymore"
        );
        require(
            IERC721(_tracking[saleId].nftContract).getApproved(_tracking[saleId].tokenId) == address(this),
            "TokenTx: marketplace has not been approved"
        );
        require(msg.value >= _tracking[saleId].price, "TokenTx: incorrect asking price");

        address tokenReceiver;

        if (_tracking[saleId].timer >= 1) {
            require(_tracking[saleId].limit < block.timestamp, "TokenTx: auction has not completed");
            require(_tracking[saleId].bidder == msg.sender, "TokenTx: caller not the highest bidder");

            tokenReceiver = msg.sender;
        } else {
            require(_tracking[saleId].timer == 0, "TokenTx: access denied");
            require(_tracking[saleId].limit == 0, "TokenTx: access denied");
            require(_tracking[saleId].bidder == address(0), "TokenTx: access denied");

            tokenReceiver = msg.sender;
        }

        address seller = _tracking[saleId].seller;
        address nftContract = _tracking[saleId].nftContract;
        uint256 tokenId = _tracking[saleId].tokenId;
        string memory uri = _tracking[saleId].uri;
        uint256 price = _tracking[saleId].price;

        address receiverAddress;
        uint256 royaltyFund;

        uint256 amount = msg.value;
        uint256 fee;

        if (IERC165(nftContract).supportsInterface(0x2a55205a) == true) {
            (receiverAddress, royaltyFund) = IERC2981(nftContract).royaltyInfo(tokenId, price);
            amount = price - royaltyFund;
            (bool tx1, ) = payable(receiverAddress).call{value: royaltyFund}("");
            require(tx1, "TokenTx: ether transfer to royalty receiver failed");

            fee = amount / Management.percent();
            amount = amount - fee;
        } else {
            amount = msg.value;

            fee = amount / Management.percent();
            amount = amount - fee;
        }

        (bool tx2, ) = payable(seller).call{value: amount}("");
        require(tx2, "TokenTx: ether transfer to sell failed");

        (bool tx3, ) = payable(treasury).call{value: fee}("");
        require(tx3, "TokenTx: ether transfer to management failed");

        IERC721(nftContract).transferFrom(seller, tokenReceiver, tokenId);

        _tracking[saleId].owner = tokenReceiver;

        _tracking[saleId].available = false;

        emit Purchase (
            saleId,
            nftContract,
            tokenId,
            uri,
            seller,
            msg.sender,
            msg.value
        );
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

/**
 * @dev Interface for fee and percent returns
 */
interface IManagement {
    /**
     * @dev Returns fee and percent
     */
    function fee() external view returns (uint256);

    function percent() external view returns (uint256);
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