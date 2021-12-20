/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-19
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
// File: contracts/APAGovernor.sol



pragma solidity >=0.7.0 <0.9.0;



contract APAGovernor {
    IERC721Enumerable immutable apaContract;
    Market immutable apaMkt;

    enum BallotType {perAPA, perAddress}
    enum Status { Accepted, Rejected, Active }
    enum Votes { Yes, No }

    struct Proposal {
        uint id;
        address author;
        string name;
        string description;
        uint end;
        uint votesYes;
        uint votesNo;
        BallotType ballotType;  // 0 = perAPA   1= perAddress
        Status status;
    }
 
    address public manager;
    uint public proposerApas; 
    uint public nextPropId;
    Proposal[] public proposals;
    mapping(uint => mapping(address => bool)) public voters;
    mapping(uint => mapping(uint => bool)) public votedAPAs;
    address public apaToken = 0x9E491465BbD22B62D7d27E0Ff35d4e263228ba5C;
    address public apaMarket = 0xc7BE0807843396c22f5B3D550872D0Cb9f113165;

    constructor() {
        manager = msg.sender;
        apaContract = IERC721Enumerable(apaToken);
        apaMkt = Market(apaMarket);
        proposerApas =30;
    }

    modifier onlyManager() {
        require(msg.sender == manager, 'only manager can execute this function');
        _;
    } 

    modifier verifyNumApas() {
        // Check if sender has minimum number of APAs
        require(apaContract.balanceOf(msg.sender) >= proposerApas, 'Need more APAs');
        _;
    }

    function setProposerApas(uint minApas) public onlyManager() {
        require (minApas != 0, "set minimum to at least one APA ");
        proposerApas = minApas;
    }

    function createProposal(
        string memory _name, 
        string memory _desc,
        uint duration, //in days
        BallotType _ballotType //0=perAPA 1=perAddress
        ) external verifyNumApas()  {
            proposals.push( Proposal({
                id: nextPropId,
                author: msg.sender,
                name: _name,
                description: _desc,
                end: block.timestamp + duration * 1 days,
                votesYes: 0,
                votesNo: 0,
                ballotType: _ballotType,
                status: Status.Active
                })
            );
            nextPropId+=1;

    }

    function vote(uint proposalId , Votes _vote) external {
        uint voterBalance = apaContract.balanceOf(msg.sender);
        require(voterBalance != 0, "Need at least one APA to cast a vote");
        require(block.timestamp <= proposals[proposalId].end, "Proposal has Expired");
        require(proposals[proposalId].status == Status.Active, "Proposal does not exist");

        uint currentAPA;
        uint ineligibleCount=0;
        uint userActListings=0;

        Market.Listing[] memory activeListings;
        uint totalListings =apaMkt.totalActiveListings();
        activeListings =apaMkt.getActiveListings(0,totalListings);

        uint iterations;
        if (voterBalance >= totalListings){
            iterations = voterBalance;
        }
        else iterations = totalListings;

        //get user Apas from wallet
        for(uint i=0; i <= iterations-1; i++){

            if(i <= voterBalance - 1){
                //get current APA
                currentAPA = apaContract.tokenOfOwnerByIndex(msg.sender, i);
                //check if APA has already voted
                if(!votedAPAs[proposalId][currentAPA]){
                    //count APA as voted
                    votedAPAs[proposalId][currentAPA] = true;
                    //check Ballot Type
                    if(proposals[proposalId].ballotType == BallotType.perAddress){
                        require(!voters[proposalId][msg.sender], "Voter has already voted");
                        break;//break if one vote per address, 
                    }
                }
                else ineligibleCount+=1;
            }
        
            //get user Apas from Market (will be skipped if no market apas)
            if(i <= totalListings - 1){

                if (activeListings[i].owner == msg.sender){
                    currentAPA = activeListings[i].tokenId;
                    //check if APA has already voted
                    if(!votedAPAs[proposalId][currentAPA]){
                        //count APA as voted
                        votedAPAs[proposalId][currentAPA] = true;
                        userActListings++;
                        //check Ballot Type
                        if(proposals[proposalId].ballotType == BallotType.perAddress){
                            require(!voters[proposalId][msg.sender], "Voter has already voted");
                            break;//break if one vote per address, 
                        }
                    }              
                }
            }
        }
        int eligibleVotes = int(voterBalance) + int(userActListings) - int(ineligibleCount);

      
        //1 vote per APA 
       if(proposals[proposalId].ballotType == BallotType.perAPA){
            require(eligibleVotes >= 1, "All APA's have voted");

            if (_vote == Votes.Yes){
                proposals[proposalId].votesYes += uint(eligibleVotes);
            }
            else {
                proposals[proposalId].votesNo += uint(eligibleVotes);
            }
            
        }

        //1 vote per address
        if(proposals[proposalId].ballotType == BallotType.perAddress){
            if (_vote == Votes.Yes){
                proposals[proposalId].votesYes += 1;
            }
            if (_vote == Votes.No){
                proposals[proposalId].votesNo += 1;
            }
            //mark voter as voted
            voters[proposalId][msg.sender] = true;
        }
         
    }
  
    function certifyResults(uint proposalId) external onlyManager() returns(Status) {
            //make sure proposal has ended
            require(block.timestamp >= proposals[proposalId].end, "Proposal has not yet ended");
            if(proposals[proposalId].votesYes - proposals[proposalId].votesNo >= 1) {
                proposals[proposalId].status = Status.Accepted;
            }
            else proposals[proposalId].status = Status.Rejected;
        return proposals[proposalId].status;
    }

    function getProposals() view external returns(Proposal[] memory){
        return proposals;
    }
}