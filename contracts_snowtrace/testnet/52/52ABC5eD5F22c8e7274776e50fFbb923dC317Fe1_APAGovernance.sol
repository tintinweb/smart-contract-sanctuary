/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-19
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Market.sol



pragma solidity ^0.8.7;





abstract contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {}

interface IERC2981Royalties {
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

contract Market is Ownable {
    IERC721Full nftContract;
    IERC2981Royalties royaltyInterface;

    uint256 constant TOTAL_NFTS_COUNT = 10000;

    struct Listing {
        bool active;
        uint256 id;
        uint256 tokenId;
        uint256 price;
        uint256 activeIndex; // index where the listing id is located on activeListings
        uint256 userActiveIndex; // index where the listing id is located on userActiveListings
        address owner;
        string tokenURI;
    }

    struct Purchase {
        Listing listing;
        address buyer;
    }

    event AddedListing(Listing listing);
    event UpdateListing(Listing listing);
    event FilledListing(Purchase listing);
    event CanceledListing(Listing listing);

    Listing[] public listings;
    uint256[] public activeListings; // list of listingIDs which are active
    mapping(address => uint256[]) public userActiveListings; // list of listingIDs which are active

    mapping(uint256 => uint256) public communityRewards;

    uint256 public communityHoldings = 0;
    uint256 public communityFeePercent = 0;
    uint256 public marketFeePercent = 0;

    uint256 public totalVolume = 0;
    uint256 public totalSales = 0;
    uint256 public highestSalePrice = 0;
    uint256 public totalGivenRewardsPerToken = 0;

    bool public isMarketOpen = false;
    bool public emergencyDelisting = false;

    constructor(
        address nft_address,
        uint256 dist_fee,
        uint256 market_fee
    ) {
        require(dist_fee <= 100, "Give a percentage value from 0 to 100");
        require(market_fee <= 100, "Give a percentage value from 0 to 100");

        nftContract = IERC721Full(nft_address);
        royaltyInterface = IERC2981Royalties(nft_address);

        communityFeePercent = dist_fee;
        marketFeePercent = market_fee;
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

    function totalListings() external view returns (uint256) {
        return listings.length;
    }

    function totalActiveListings() external view returns (uint256) {
        return activeListings.length;
    }

    function getActiveListings(uint256 from, uint256 length)
        external
        view
        returns (Listing[] memory listing)
    {
        uint256 numActive = activeListings.length;
        if (from + length > numActive) {
            length = numActive - from;
        }

        Listing[] memory _listings = new Listing[](length);
        for (uint256 i = 0; i < length; i++) {
            Listing memory _l = listings[activeListings[from + i]];
            _l.tokenURI = nftContract.tokenURI(_l.tokenId);
            _listings[i] = _l;
        }
        return _listings;
    }

    function removeActiveListing(uint256 index) internal {
        uint256 numActive = activeListings.length;

        require(numActive > 0, "There are no active listings");
        require(index < numActive, "Incorrect index");

        activeListings[index] = activeListings[numActive - 1];
        listings[activeListings[index]].activeIndex = index;
        activeListings.pop();
    }

    function removeOwnerActiveListing(address owner, uint256 index) internal {
        uint256 numActive = userActiveListings[owner].length;

        require(numActive > 0, "There are no active listings for this user.");
        require(index < numActive, "Incorrect index");

        userActiveListings[owner][index] = userActiveListings[owner][
            numActive - 1
        ];
        listings[userActiveListings[owner][index]].userActiveIndex = index;
        userActiveListings[owner].pop();
    }

    function getMyActiveListingsCount() external view returns (uint256) {
        return userActiveListings[msg.sender].length;
    }

    function getMyActiveListings(uint256 from, uint256 length)
        external
        view
        returns (Listing[] memory listing)
    {
        uint256 numActive = userActiveListings[msg.sender].length;

        if (from + length > numActive) {
            length = numActive - from;
        }

        Listing[] memory myListings = new Listing[](length);

        for (uint256 i = 0; i < length; i++) {
            Listing memory _l = listings[
                userActiveListings[msg.sender][i + from]
            ];
            _l.tokenURI = nftContract.tokenURI(_l.tokenId);
            myListings[i] = _l;
        }
        return myListings;
    }

    function addListing(uint256 tokenId, uint256 price) external {
        require(isMarketOpen, "Market is closed.");
        require(
            tokenId < TOTAL_NFTS_COUNT,
            "Honorary APAs are not accepted in the marketplace"
        );
        require(msg.sender == nftContract.ownerOf(tokenId), "Invalid owner");

        uint256 id = listings.length;
        Listing memory listing = Listing(
            true,
            id,
            tokenId,
            price,
            activeListings.length, // activeIndex
            userActiveListings[msg.sender].length, // userActiveIndex
            msg.sender,
            ""
        );

        listings.push(listing);
        userActiveListings[msg.sender].push(id);
        activeListings.push(id);

        emit AddedListing(listing);

        nftContract.transferFrom(msg.sender, address(this), tokenId);
    }

    function updateListing(uint256 id, uint256 price) external {
        require(id < listings.length, "Invalid Listing");
        require(listings[id].active, "Listing no longer active");
        require(listings[id].owner == msg.sender, "Invalid Owner");

        listings[id].price = price;
        emit UpdateListing(listings[id]);
    }

    function cancelListing(uint256 id) external {
        require(id < listings.length, "Invalid Listing");
        Listing memory listing = listings[id];
        require(listing.active, "Listing no longer active");
        require(listing.owner == msg.sender, "Invalid Owner");

        removeActiveListing(listing.activeIndex);
        removeOwnerActiveListing(msg.sender, listing.userActiveIndex);

        listings[id].active = false;

        emit CanceledListing(listing);

        nftContract.transferFrom(address(this), listing.owner, listing.tokenId);
    }

    function fulfillListing(uint256 id) external payable {
        require(id < listings.length, "Invalid Listing");
        Listing memory listing = listings[id];
        require(listing.active, "Listing no longer active");
        require(msg.value >= listing.price, "Value Insufficient");
        require(msg.sender != listing.owner, "Owner cannot buy own listing");

        (address originalMinter, uint256 royaltyAmount) = royaltyInterface
            .royaltyInfo(listing.tokenId, listing.price);
        uint256 community_cut = (listing.price * communityFeePercent) / 100;
        uint256 market_cut = (listing.price * marketFeePercent) / 100;
        uint256 holder_cut = listing.price -
            royaltyAmount -
            community_cut -
            market_cut;

        listings[id].active = false;

        // Update active listings
        removeActiveListing(listing.activeIndex);
        removeOwnerActiveListing(listing.owner, listing.userActiveIndex);

        // Update global stats
        totalVolume += listing.price;
        totalSales += 1;

        if (listing.price > highestSalePrice) {
            highestSalePrice = listing.price;
        }

        uint256 perToken = community_cut / TOTAL_NFTS_COUNT;
        totalGivenRewardsPerToken += perToken;
        communityHoldings += perToken * TOTAL_NFTS_COUNT;

        emit FilledListing(
            Purchase({listing: listings[id], buyer: msg.sender})
        );

        payable(listing.owner).transfer(holder_cut);
        payable(originalMinter).transfer(royaltyAmount);
        nftContract.transferFrom(address(this), msg.sender, listing.tokenId);
    }

    function getRewards() external view returns (uint256 amount) {
        uint256 numTokens = nftContract.balanceOf(msg.sender);
        uint256 rewards = 0;

        // Rewards of tokens owned by the sender
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = nftContract.tokenOfOwnerByIndex(msg.sender, i);
            if (tokenId < TOTAL_NFTS_COUNT) {
                rewards +=
                    totalGivenRewardsPerToken -
                    communityRewards[tokenId];
            }
        }

        // Rewards of tokens owned by the sender, but listed on this marketplace
        uint256[] memory myListings = userActiveListings[msg.sender];
        for (uint256 i = 0; i < myListings.length; i++) {
            uint256 tokenId = listings[myListings[i]].tokenId;
            if (tokenId < TOTAL_NFTS_COUNT) {
                rewards +=
                    totalGivenRewardsPerToken -
                    communityRewards[tokenId];
            }
        }

        return rewards;
    }

    function claimListedRewards(uint256 from, uint256 length) external {
        require(
            from + length <= userActiveListings[msg.sender].length,
            "Out of index"
        );

        uint256 rewards = 0;
        uint256 newCommunityHoldings = communityHoldings;

        // Rewards of tokens owned by the sender, but listed on this marketplace
        uint256[] memory myListings = userActiveListings[msg.sender];
        for (uint256 i = 0; i < myListings.length; i++) {
            uint256 tokenId = listings[myListings[i]].tokenId;
            if (tokenId < TOTAL_NFTS_COUNT) {
                uint256 tokenReward = totalGivenRewardsPerToken -
                    communityRewards[tokenId];
                rewards += tokenReward;
                newCommunityHoldings -= tokenReward;
                communityRewards[tokenId] = totalGivenRewardsPerToken;
            }
        }

        communityHoldings = newCommunityHoldings;
        payable(msg.sender).transfer(rewards);
    }

    function claimOwnedRewards(uint256 from, uint256 length) external {
        uint256 numTokens = nftContract.balanceOf(msg.sender);
        require(from + length <= numTokens, "Out of index");

        uint256 rewards = 0;
        uint256 newCommunityHoldings = communityHoldings;

        // Rewards of tokens owned by the sender
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = nftContract.tokenOfOwnerByIndex(
                msg.sender,
                i + from
            );
            if (tokenId < TOTAL_NFTS_COUNT) {
                uint256 tokenReward = totalGivenRewardsPerToken -
                    communityRewards[tokenId];
                rewards += tokenReward;
                newCommunityHoldings -= tokenReward;
                communityRewards[tokenId] = totalGivenRewardsPerToken;
            }
        }

        communityHoldings = newCommunityHoldings;
        payable(msg.sender).transfer(rewards);
    }

    function claimRewards() external {
        uint256 numTokens = nftContract.balanceOf(msg.sender);
        uint256 rewards = 0;
        uint256 newCommunityHoldings = communityHoldings;

        // Rewards of tokens owned by the sender
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = nftContract.tokenOfOwnerByIndex(msg.sender, i);
            if (tokenId < TOTAL_NFTS_COUNT) {
                uint256 tokenReward = totalGivenRewardsPerToken -
                    communityRewards[tokenId];
                rewards += tokenReward;
                newCommunityHoldings -= tokenReward;
                communityRewards[tokenId] = totalGivenRewardsPerToken;
            }
        }

        // Rewards of tokens owned by the sender, but listed on this marketplace
        uint256[] memory myListings = userActiveListings[msg.sender];
        for (uint256 i = 0; i < myListings.length; i++) {
            uint256 tokenId = listings[myListings[i]].tokenId;
            if (tokenId < TOTAL_NFTS_COUNT) {
                uint256 tokenReward = totalGivenRewardsPerToken -
                    communityRewards[tokenId];
                rewards += tokenReward;
                newCommunityHoldings -= tokenReward;
                communityRewards[tokenId] = totalGivenRewardsPerToken;
            }
        }

        communityHoldings = newCommunityHoldings;

        payable(msg.sender).transfer(rewards);
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

    function emergencyDelist(uint256 listingID) external {
        require(emergencyDelisting && !isMarketOpen, "Only in emergency.");
        require(listingID < listings.length, "Invalid Listing");
        Listing memory listing = listings[listingID];

        nftContract.transferFrom(address(this), listing.owner, listing.tokenId);
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
// File: contracts/APAGovernance.sol



pragma solidity >=0.7.0 <0.9.0;



contract APAGovernance {
    IERC721Enumerable immutable apaContract;
    Market immutable apaMkt;
    address immutable apaToken;
    address immutable apaMarket;//new testnet market address

    enum BallotType {perAPA, perAddress}
    enum Status { Active, Certified, FailedQuorum}
    
    struct Proposal {
        uint id;
        uint end;
        uint quorum;
        address author;
        string name;
        string description;
        BallotType ballotType;  // 0 = perAPA   1= perAddress
        Status status;
        Option[] options;
    }

    struct Option {
        uint id;
        uint numVotes;
        string name;
    }
 
    address public manager;
    uint public proposerApas; 
    uint public quorumPerAPA;
    uint public quorumPerAddress;
    uint public nextPropId;
    //Proposal[] public proposals;
    mapping(uint => Proposal) public proposals;
    mapping(address => bool) public certifiers;
    mapping(uint => mapping(address => bool)) public voters;
    mapping(uint => mapping(uint => bool)) public votedAPAs;
    
   
    constructor(
        address _apaToken, 
        address _apaMarket, 
        uint _proposerAPAs, 
        uint _quorumPerAddress, 
        uint _quorumPerAPA
    ) {
        manager = msg.sender;
        apaToken = _apaToken;
        apaMarket = _apaMarket;
        apaContract = IERC721Enumerable(_apaToken);
        apaMkt = Market(_apaMarket);
        proposerApas =_proposerAPAs;
        quorumPerAPA = _quorumPerAPA;
        quorumPerAddress = _quorumPerAddress;
    }

    modifier onlyManager() {
        require(msg.sender == manager, 'only manager can execute this function');
        _;
    } 

    function setProposerApas(uint minApas) public onlyManager() {
        require (minApas != 0, "set minimum to at least one APA ");
        proposerApas = minApas;
    }

    function createProposal(
        string memory _name, 
        string memory _desc,
        string[] memory _optionNames,
        uint duration, //in days
        BallotType _ballotType //0=perAPA 1=perAddress
    ) external {

        address proposer = msg.sender;
        uint numAPAs = apaContract.balanceOf(proposer);
        require((numAPAs >= proposerApas || isLegendary(proposer)), 'Need more APAs');

        proposals[nextPropId].id = nextPropId;
        proposals[nextPropId].author = proposer;
        proposals[nextPropId].name = _name;
        proposals[nextPropId].description = _desc;
        proposals[nextPropId].end = block.timestamp + duration * 1 days;
        proposals[nextPropId].ballotType = _ballotType;
        proposals[nextPropId].status = Status.Active;   
        for(uint i = 0; i <= _optionNames.length - 1; i++){
            proposals[nextPropId].options.push(Option(i, 0, _optionNames[i]));
        }

        if(_ballotType == BallotType.perAPA){
            proposals[nextPropId].quorum = quorumPerAPA;
        } else {
            proposals[nextPropId].quorum = quorumPerAddress;
        }
        nextPropId+=1;
    }

    function isLegendary(address _proposer) internal view returns (bool) {
        for(uint i=9980; i <= 9999; i++){
            if(apaContract.ownerOf(i) == _proposer){
                return true;
            } 
        }
        return false;        
    }

    function countRegularVotes(
        uint256 proposalId, 
        uint _voterBalance, 
        address _voter, 
        BallotType ballotType
    ) internal returns(uint256) {
        uint256 numOfVotes = 0;
        uint currentAPA;

        for(uint256 i=0; i < _voterBalance; i++){
                //get current APA
            currentAPA = apaContract.tokenOfOwnerByIndex(_voter, i);
            //check if APA has already voted
            if(!votedAPAs[proposalId][currentAPA]){
                //count APA as voted
                if (ballotType == BallotType.perAddress) {
                    require(!voters[proposalId][_voter], "Voter has already voted");
                    return 1;
                }
                votedAPAs[proposalId][currentAPA] = true;
                numOfVotes++;
            }
        }
        return numOfVotes;
    }

    function countMarketVotes(uint256 proposalId, address _voter, BallotType ballotType) internal returns(uint256) {
        Market.Listing[] memory activeListings;
        uint256 totalListings =apaMkt.totalActiveListings();
        activeListings =apaMkt.getActiveListings(0,totalListings);
        //uint256 activeListingCount = apaMkt.getMyActiveListingsCount();
        //activeListings = apaMkt.getMyActiveListings(0, activeListingCount);
        uint256 numOfVotes = 0;
        uint currentAPA;
        
        for(uint256 i=0; i < totalListings; i++){
            //get user Apas from Market (will be skipped if no market apas)
            if (activeListings[i].owner == _voter){
                currentAPA = activeListings[i].tokenId;
                //check if APA has already voted
                if(!votedAPAs[proposalId][currentAPA]){

                    if (ballotType == BallotType.perAddress) {
                        require(!voters[proposalId][_voter], "Voter has already voted");
                        return 1;
                    }
                    //count APA as voted
                    votedAPAs[proposalId][currentAPA] = true;
                    numOfVotes++;
                }              
            }
        }
        return numOfVotes;
    }
    function vote(uint256 proposalId, uint256 optionId) external {
        address voter = msg.sender;
        uint256 voterBalance = apaContract.balanceOf(voter);
        require(proposals[proposalId].status == Status.Active, "Not an Active Proposal");
        require(block.timestamp <= proposals[proposalId].end, "Proposal has Expired");
        require(voterBalance != 0, "Need at least one APA to cast a vote");
        BallotType ballotType = proposals[proposalId].ballotType;
        
        //1 vote per APA 
        if(ballotType == BallotType.perAPA){
            uint256 eligibleVotes = countRegularVotes(proposalId, voterBalance, voter, ballotType) + countMarketVotes(proposalId, voter, ballotType);
            require(eligibleVotes >= 1, "Vote count is zero");
            //count votes
            proposals[proposalId].options[optionId].numVotes += eligibleVotes;
        }

        //1 vote per address
        if(ballotType == BallotType.perAddress){
            if(countRegularVotes(proposalId, voterBalance, voter, ballotType) > 0  || countMarketVotes(proposalId, voter, ballotType) > 0  ){ // if countRegularVotes() is true countMarketVotes() wont be evaluated
                proposals[proposalId].options[optionId].numVotes += 1;
                voters[proposalId][voter] = true;
            }
        }
         
    }

    function certifyResults(uint proposalId) external returns(Status) {
        require(certifiers[msg.sender], "must be certifier to certify results");
        require(block.timestamp >= proposals[proposalId].end, "Proposal has not yet ended");
        require(proposals[proposalId].status == Status.Active, "Not an Active Proposal");
        bool quorumMet;

        for(uint i=0; i <= proposals[proposalId].options.length; i++){
            if(proposals[proposalId].options[i].numVotes >= proposals[nextPropId].quorum) 
                quorumMet = true;
        }

        if(!quorumMet) 
            proposals[proposalId].status = Status.FailedQuorum;
        else 
            proposals[proposalId].status = Status.Certified;

        return proposals[proposalId].status;
    }

    function getVoteCount(uint proposalId) external view returns(Option[] memory){
        return proposals[proposalId].options;
    }

    function addCertifier(address newCertifier) external onlyManager(){
        certifiers[newCertifier] = true;
    }

    function removeCertifier(address newCertifier) external onlyManager(){
        certifiers[newCertifier] = false;
    }

    function setManager(address newManager) external onlyManager(){
        manager = newManager;
    }

    function setQuorumPerAPA(uint newQuorum) external onlyManager(){
        require(newQuorum >= 1, "must have at least one winning vote");
        quorumPerAPA = newQuorum;
    }

    function setQuorumPerAddress(uint newQuorum) external onlyManager(){
        require(newQuorum >= 1, "must have at least one winning vote");
        quorumPerAddress = newQuorum;
    }

    function setQuorumByProposal(uint proposalId, uint newQuorum) external onlyManager(){
        require(proposals[proposalId].status == Status.Active, "Not an Active Proposal");
        require(newQuorum >= 1, "must have at least one winning vote");
        proposals[proposalId].quorum = newQuorum;
    }

    function getProposals()
        external
        view
        returns (Proposal[] memory _proposals)
    {
        Proposal[] memory _props = new Proposal[](nextPropId);
        for (uint256 i = 0; i <= nextPropId-1; i++) {  
            _props[i] = proposals[i];
        }

        return _props;
    }
}