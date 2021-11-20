/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-19
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]
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


// File @openzeppelin/contracts/access/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;

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


// File contracts/CollectionMarket.sol

pragma solidity ^0.8.7;





abstract contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {}

interface IERC2981Royalties {
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

interface IDistributor {
    function deposit() external payable;
    function isFrozen() external returns (bool);
}

contract CollectionMarket is Ownable, ReentrancyGuard {
    IDistributor distributorInterface;

    IERC721Full[] supportedTokens;
    IERC2981Royalties[] IRoyalties;

    uint256 constant TOTAL_NFTS_COUNT = 10000;

    struct Collection {
        bool active;
        uint256 id;
        uint256[] tokenIds;
        uint256[] tokenTypes;
        uint256 price;
        uint256 activeIndex; // index where the collection id is located on activeCollections
        uint256 userActiveIndex; // index where the collection id is located on userActiveCollections
        address owner;
        string name;
    }

    struct Purchase {
        Collection collection;
        address buyer;
    }

    struct AccountingInfo {
        uint256 totalHolderCut;
        uint256 communityTotalCut;
        uint256 charityAmount;
        uint256 community_cut;
        uint256 market_cut;
    } 

    event AddedCollection(Collection collection);
    event UpdateCollection(Collection collection);
    event FilledCollection(Purchase collection);
    event CanceledCollection(Collection collection);

    Collection[] public collections;
    uint256[] public activeCollections; // list of collectionIDs which are active
    mapping(address => uint256[]) public userActiveCollections; // list of collectionIDs which are active

    uint256 public communityHoldings = 0;
    uint256 public communityFeePercent = 0;
    uint256 public marketFeePercent = 0;

    uint256 public totalVolume = 0;
    uint256 public totalSales = 0;
    uint256 public movedItems = 0;
    uint256 public highestSalePrice = 0;

    bool public isMarketOpen = false;
    bool public emergencyDelisting = false;
    bool public charityEnabled = false;

    address charityAddress;

    constructor(
        address distributorAddress,
        uint256 dist_fee,
        uint256 market_fee
    ) {
        require(dist_fee <= 100, "Give a percentage value from 0 to 100");
        require(market_fee <= 100, "Give a percentage value from 0 to 100");

        distributorInterface = IDistributor(distributorAddress);

        communityFeePercent = dist_fee;
        marketFeePercent = market_fee;
    }

    function addSupportedToken(address token) external onlyOwner {
        supportedTokens.push(IERC721Full(token));
        IRoyalties.push(IERC2981Royalties(token));
    } 

    function openMarket() external onlyOwner {
        isMarketOpen = true;
    }

    function closeMarket() external onlyOwner {
        isMarketOpen = false;
    }

    function allowEmergencyDelisting() external onlyOwner {
        emergencyDelisting = true;
    }

    function enableCharity() external onlyOwner {
        require(charityAddress != address(0x0), "Set charity address first");
        charityEnabled = true;
    }

    function disableCharity() external onlyOwner {
        charityEnabled = false;
    }

    function setCharityAddress(address addr) external onlyOwner {
        require(addr != address(0x0), "Set a valid charity address");
        charityAddress = addr;
    }

    function totalCollections() external view returns (uint256) {
        return collections.length;
    }

    function totalActiveCollections() external view returns (uint256) {
        return activeCollections.length;
    }

    function getActiveCollections(uint256 from, uint256 length)
        external
        view
        returns (Collection[] memory collection)
    {
        uint256 numActive = activeCollections.length;
        if (from + length > numActive) {
            length = numActive - from;
        }

        Collection[] memory _collections = new Collection[](length);
        for (uint256 i = 0; i < length; i++) {
            _collections[i] = collections[activeCollections[from + i]];
        }
        return _collections;
    }

    function removeActiveCollection(uint256 index) internal {
        uint256 numActive = activeCollections.length;

        require(numActive > 0, "There are no active collections");
        require(index < numActive, "Incorrect index");

        activeCollections[index] = activeCollections[numActive - 1];
        collections[activeCollections[index]].activeIndex = index;
        activeCollections.pop();
    }

    function removeOwnerActiveCollection(address owner, uint256 index) internal {
        uint256 numActive = userActiveCollections[owner].length;

        require(numActive > 0, "There are no active collections for this user.");
        require(index < numActive, "Incorrect index");

        userActiveCollections[owner][index] = userActiveCollections[owner][
            numActive - 1
        ];
        collections[userActiveCollections[owner][index]].userActiveIndex = index;
        userActiveCollections[owner].pop();
    }

    function getMyActiveCollectionsCount() external view returns (uint256) {
        return userActiveCollections[msg.sender].length;
    }

    function getMyActiveCollections(uint256 from, uint256 length)
        external
        view
        returns (Collection[] memory collection)
    {
        uint256 numActive = userActiveCollections[msg.sender].length;

        if (from + length > numActive) {
            length = numActive - from;
        }

        Collection[] memory myCollections = new Collection[](length);

        for (uint256 i = 0; i < length; i++) {
            myCollections[i] = collections[userActiveCollections[msg.sender][i + from]];
        }
        return myCollections;
    }

    function addCollection(
        uint256[] memory tokenIds,
        uint256[] memory tokenTypes,
        uint256 price,
        string memory name
    ) external {
        require(isMarketOpen, "Market is closed.");
        require(tokenIds.length > 1, "Minimum 2 tokens must be present.");

        uint256 id = collections.length;
        
        Collection memory collection = Collection(
            true,
            id,
            tokenIds,
            tokenTypes,
            price,
            activeCollections.length, // activeIndex
            userActiveCollections[msg.sender].length, // userActiveIndex
            msg.sender,
            name
        );

        collections.push(collection);
        userActiveCollections[msg.sender].push(id);
        activeCollections.push(id);

        IERC721Full[] memory _supportedTokens = supportedTokens;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _supportedTokens[tokenTypes[i]].transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        emit AddedCollection(collection);

    }

    function updateCollection(uint256 id, uint256 price) external {
        require(id < collections.length, "Invalid Collection");
        require(collections[id].active, "Collection no longer active");
        require(collections[id].owner == msg.sender, "Invalid Owner");

        collections[id].price = price;
        emit UpdateCollection(collections[id]);
    }

    function cancelCollection(uint256 id) external {
        require(id < collections.length, "Invalid Collection");
        Collection memory collection = collections[id];
        require(collection.active, "Collection no longer active");
        require(collection.owner == msg.sender, "Invalid Owner");

        removeActiveCollection(collection.activeIndex);
        removeOwnerActiveCollection(msg.sender, collection.userActiveIndex);

        collections[id].active = false;

        IERC721Full[] memory _supportedTokens = supportedTokens;

        uint256 numTokens = collection.tokenIds.length;
        for (uint256 i = 0; i < numTokens; i++) {
            _supportedTokens[collection.tokenTypes[i]].transferFrom(
                address(this),
                collection.owner,
                collection.tokenIds[i]
            );
        }

        emit CanceledCollection(collection);
    }

    function fulfillCollection(uint256 id, bool isCharityFee) external payable nonReentrant {
        require(id < collections.length, "Invalid Collection");
        Collection memory collection = collections[id];
        require(collection.active, "Collection no longer active");
        require(msg.value >= collection.price, "Value Insufficient");
        require(msg.sender != collection.owner, "Owner cannot buy own collection");

        // Update global stats
        totalVolume += collection.price;
        totalSales += 1;
        movedItems += collection.tokenIds.length;

        if (collection.price > highestSalePrice) {
            highestSalePrice = collection.price;
        }

        // Update active collections
        collections[id].active = false;
        removeActiveCollection(collection.activeIndex);
        removeOwnerActiveCollection(collection.owner, collection.userActiveIndex);

        IERC2981Royalties[] memory _iroyalties = IRoyalties;
        IERC721Full[] memory _supportedTokens = supportedTokens;

        uint256 numTokens = collection.tokenIds.length;
        uint256 perTokenPrice = (collection.price * 1000) / numTokens / 1000;

        AccountingInfo memory info = AccountingInfo({
            totalHolderCut: 0,
            communityTotalCut: (perTokenPrice * communityFeePercent) / 100 * numTokens, 
            charityAmount: 0,
            community_cut: (perTokenPrice * communityFeePercent) / 100 ,
            market_cut: (perTokenPrice * marketFeePercent) / 100
        });


        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = collection.tokenIds[i];
            uint256 tokenType = collection.tokenTypes[i];

            (address originalMinter, uint256 royaltyAmount) = _iroyalties[tokenType]
                .royaltyInfo(tokenId, perTokenPrice);

            uint256 holder_cut = perTokenPrice -
                royaltyAmount -
                info.community_cut -
                info.market_cut;

            info.totalHolderCut += holder_cut;

            if(isCharityFee && charityEnabled) {
                info.charityAmount += royaltyAmount;
            }
            else {
                payable(originalMinter).transfer(royaltyAmount);
            }

            _supportedTokens[tokenType].transferFrom(address(this), msg.sender, tokenId);
        }

        if(info.charityAmount > 0) {
            payable(charityAddress).transfer(info.charityAmount);
        }

        if(!distributorInterface.isFrozen()) {
            distributorInterface.deposit{value: info.communityTotalCut}();
        }
        else {
            communityHoldings += info.communityTotalCut;
        }

        payable(collection.owner).transfer(info.totalHolderCut);

        emit FilledCollection(
            Purchase({collection: collections[id], buyer: msg.sender})
        );
    }

    function adjustFees(uint256 newDistFee, uint256 newMarketFee)
        external
        onlyOwner
    {
        require(newDistFee <= 100, "Give a percentage value from 0 to 100");
        require(newMarketFee <= 100, "Give a percentage value from 0 to 100");

        communityFeePercent = newDistFee;
        marketFeePercent = newMarketFee;
    }

    function emergencyDelist(uint256[] memory collectionIDs) external {
        require(emergencyDelisting && !isMarketOpen, "Only in emergency.");
        uint256 numCollections = collectionIDs.length;
        for(uint256 j = 0; j < numCollections; j++){

            uint256 collectionID = collectionIDs[j];
            require(collectionID < collections.length, "Invalid Collection");

            Collection memory collection = collections[collectionID];
            uint256[] memory tokens = collection.tokenIds;
            uint256[] memory tokenTypes = collection.tokenTypes;
            IERC721Full[] memory _supportedTokens = supportedTokens;

            uint256 numTokens = collection.tokenIds.length;
            for(uint256 i = 0; i < numTokens; i++) {
                _supportedTokens[tokenTypes[i]].transferFrom(address(this), collection.owner, tokens[i]);
            }
        }
    }

    function setNewDistributor(address addr) external onlyOwner {
        distributorInterface = IDistributor(addr);
    }

    function collectDistributorShare() external onlyOwner {
        require(address(this).balance >= communityHoldings);
        distributorInterface.deposit{value: communityHoldings}();
    }

    function withdrawableBalance() public view returns (uint256 value) {
        if (address(this).balance <= communityHoldings) {
            return 0;
        }
        return address(this).balance - communityHoldings;
    }

    function withdrawBalance() external onlyOwner {
        uint256 withdrawable = withdrawableBalance();
        payable(_msgSender()).transfer(withdrawable);
    }

    function emergencyWithdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}