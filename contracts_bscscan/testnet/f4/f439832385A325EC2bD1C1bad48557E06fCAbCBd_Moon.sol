// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Moon
 * @dev Moon is a NFT Marketplace.
 */
contract Moon is Initializable{
    address governance; // address of the governance contract
    address payable treasury; // address of the treasury contract
    uint256 salesTax; // percentage
    
    struct auctionNFT {
        uint256 id;
        address token;
        uint256 tokenID;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    auctionNFT[] public nftsForSale;
    mapping(address => mapping(uint256 => bool)) activeAuctions;

    event ItemForSale(uint256 id, address token, uint256 tokenID, address seller, uint256 price);
    event ItemSold(uint256 id, address token, uint256 tokenID, address seller, uint256 price);

    function init(address _governance, address payable _treasury, uint256 _salesTax) public initializer {
        governance = _governance;
        treasury = _treasury;
        salesTax = _salesTax;
    }

    /**
     * @dev Creates a new item for sale.
     * @param _tokenAddress Address of the token contract.
     * @param _tokenID ID of the token.
     * @param _price Price of the item in wei.
     * @return ID of the new item.
     */
    function createItemForSale(
        address _tokenAddress,
        uint256 _tokenID,
        uint256 _price
    ) public onlySeller(_tokenAddress, _tokenID) returns (uint256) {
        uint256 id = nftsForSale.length;
        nftsForSale.push(
            auctionNFT({
                id: id,
                token: _tokenAddress,
                tokenID: _tokenID,
                seller: payable(msg.sender),
                price: _price,
                isSold: false
            })
        );
        activeAuctions[_tokenAddress][_tokenID] = true;
        emit ItemForSale(id, _tokenAddress, _tokenID, msg.sender, _price);
        return id;
    }

    function buyItem(uint256 id) public payable itemExists(id) itemIsForSale(id) {
        require((msg.value >= nftsForSale[id].price + calculateSalesTax(nftsForSale[id].price)), "Not enough ETH");
        require(msg.sender != nftsForSale[id].seller, "Cannot buy your own item");

        nftsForSale[id].isSold = true;
        activeAuctions[nftsForSale[id].token][nftsForSale[id].tokenID] = false;
        IERC721(nftsForSale[id].token).safeTransferFrom(nftsForSale[id].seller, msg.sender, nftsForSale[id].tokenID);
        nftsForSale[id].seller.transfer(nftsForSale[id].price);
        treasury.transfer(address(this).balance);

        emit ItemSold(
            id,
            nftsForSale[id].token,
            nftsForSale[id].tokenID,
            nftsForSale[id].seller,
            nftsForSale[id].price
        );
    }

    function calculateSalesTax(uint256 _price) public view returns (uint256) {
        return (_price * salesTax) / 100;
    }

    // -------------------- Modifiers --------------------

    modifier onlySeller(address tokenAddress, uint256 tokenID) {
        IERC721 token = IERC721(tokenAddress);
        require(msg.sender == token.ownerOf(tokenID));
        _;
    }

    modifier marketHasApproval(address tokenAddress, uint256 tokenID) {
        IERC721 token = IERC721(tokenAddress);
        require(token.getApproved(tokenID) == address(this));
        _;
    }

    modifier itemExists(uint256 id) {
        require(id < nftsForSale.length, "Item does not exist");
        _;
    }

    modifier itemIsForSale(uint256 id) {
        require(nftsForSale[id].isSold == false, "Item is not for sale");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}