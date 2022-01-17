//SPDX-License-Identifier: MIT


// ░█████╗░██████╗░██╗░░░██╗████████╗░█████╗░██████╗░░██████╗
// ██╔══██╗██╔══██╗╚██╗░██╔╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝
// ██║░░╚═╝██████╔╝░╚████╔╝░░░░██║░░░███████║██████╔╝╚█████╗░
// ██║░░██╗██╔══██╗░░╚██╔╝░░░░░██║░░░██╔══██║██╔══██╗░╚═══██╗
// ╚█████╔╝██║░░██║░░░██║░░░░░░██║░░░██║░░██║██║░░██║██████╔╝
// ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Crytars is ERC721URIStorage, Ownable {
    uint256 public tokenCount;
    uint256 public proposalsCount;
    bool public proposalsPaused = true;
    bool public paused = false;

    struct Bid {
        bool open;
        address user;
        uint256 amount;
    }

    struct Offer {
        bool open;
        address seller;
        uint256 amount;
        address offeredTo;
    }

    struct Proposal {
        string proposalURI;
        uint256 ID;
        uint256 status;
        address user;
        uint256 escrowAmount;
        uint256 crytarAssigned;
    }

    uint256 public proposalCost = 0.02 ether;
    uint256 public listingCharge = 0.001 ether;
    uint256 public proposalWithdrawalCharge = 0.01 ether;
    uint256 public percentCutTenths = 5;
    uint256 public floorPrice = 0.0001 ether;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) private addressToPendingWithdrawalAmount;
    mapping(uint256 => Bid) public idToHighestBid;
    mapping(uint256 => Offer) public idToCurrentOffer;

    mapping(uint256 => Proposal) public idToProposal;

    event OfferedForSale(uint256 indexed tokenId, address indexed caller, uint256 price, address indexed to);
    event RemovedForSale(uint256 indexed tokenId, address indexed caller);
    event Sold(uint256 indexed tokenId, address indexed from, address indexed caller, uint256 price);
    event BidEntered(uint256 indexed tokenId, address indexed caller, uint256 price);
    event BidWithdrawn(uint256 indexed tokenId, address indexed caller);
    event BidAccepted(uint256 indexed tokenId, address indexed caller);
    event Withdrawal(address indexed caller, uint256 amount);

    constructor() ERC721("Crytars", "CRYTAR") {}

    function createToken(string memory tokenURI, uint256 price) public onlyOwner {
        require(!paused, "Contract is paused");
        tokenCount++;

        uint256 newTokenId = tokenCount;

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        idToCurrentOffer[newTokenId] = Offer(false, msg.sender, price, address(0));
    }

    function offerCrytarForSale(
        uint256 ID,
        uint256 price,
        address offeredTo
    ) public {
        require(!paused, "Contract is paused");
        require(ID <= tokenCount && ID != 0, "Invalid token ID");
        require(ownerOf(ID) == msg.sender, "Only owner can offer crytar for sale");
        require(!idToCurrentOffer[ID].open, "Crytar is already available for sale");
        require(price >= floorPrice, "Price has to greater than or equal to floor price");

        idToCurrentOffer[ID] = Offer(true, msg.sender, price, offeredTo);

        approve(address(this), ID);

        emit OfferedForSale(ID, msg.sender, price, offeredTo);
    }

    function removeCrytarForSale(uint256 ID) public payable {
        require(!paused, "Contract is paused");
        require(ID <= tokenCount && ID != 0, "Invalid token ID");
        require(msg.value == listingCharge, "Please send the listing fees");

        require(ownerOf(ID) == msg.sender, "Only owner can offer crytar for sale");
        require(idToCurrentOffer[ID].open, "Crytar is already not available for sale");

        idToCurrentOffer[ID].open = false;

        approve(address(0), ID);
        emit RemovedForSale(ID, msg.sender);
        addressToPendingWithdrawalAmount[owner()] += listingCharge;
    }

    function createCrytarSale(uint256 ID) public payable {
        require(!paused, "Contract is paused");
        require(ID <= tokenCount && ID != 0, "Invalid token ID");
        require(idToCurrentOffer[ID].open, "Crytar is not for sale");
        require(ownerOf(ID) != msg.sender, "Offerer cant be the buyer");
        require(idToCurrentOffer[ID].amount == msg.value, "Please send the correct buy amount");

        if (idToCurrentOffer[ID].offeredTo != address(0)) {
            require(idToCurrentOffer[ID].offeredTo == msg.sender, "Transaction sender has not been offered this token");
        }

        address newOwner = msg.sender;
        address oldOwner = idToCurrentOffer[ID].seller;
        uint256 totalPrice = idToCurrentOffer[ID].amount;
        uint256 fees;
        if (oldOwner != owner()) {
            fees = (totalPrice * percentCutTenths) / 1000;
        }

        uint256 effectiveTransferAmount = totalPrice - fees;

        idToCurrentOffer[ID] = Offer(false, newOwner, msg.value, address(0));
        addressToPendingWithdrawalAmount[oldOwner] += effectiveTransferAmount;
        addressToPendingWithdrawalAmount[owner()] += fees;

        if (idToHighestBid[ID].open && idToHighestBid[ID].user == newOwner) {
            idToHighestBid[ID].open = false;
            addressToPendingWithdrawalAmount[newOwner] += idToHighestBid[ID].amount;
        }

        this.safeTransferFrom(oldOwner, newOwner, ID);

        emit Sold(ID, oldOwner, newOwner, totalPrice);
    }

    function enterBidOnCrytar(uint256 ID) public payable {
        require(!paused, "Contract is paused");
        require(ID <= tokenCount && ID != 0, "Invalid token ID");
        address newBidder = msg.sender;
        uint256 newBidAmount = msg.value;
        require(newBidder != ownerOf(ID), "Owner cant bid on their Crytar");
        require(newBidAmount >= floorPrice, "Bid amount has to be greater than the floor price");
        if (idToHighestBid[ID].open) {
            address currentBidder = idToHighestBid[ID].user;
            uint256 currentBidAmount = idToHighestBid[ID].amount;
            require(currentBidder != newBidder, "Bid already open for this user");
            require(newBidAmount > currentBidAmount, "Bid amount lower than current bid");

            addressToPendingWithdrawalAmount[currentBidder] += currentBidAmount;
        }
        idToHighestBid[ID] = Bid(true, newBidder, newBidAmount);
        emit BidEntered(ID, newBidder, newBidAmount);
    }

    function withdrawBidOnCrytar(uint256 ID) public {
        require(ID <= tokenCount && ID != 0, "Invalid token ID");
        bool isBidOpen = idToHighestBid[ID].open;
        address currentHighestBidder = idToHighestBid[ID].user;
        uint256 currentHighestBid = idToHighestBid[ID].amount;
        require(isBidOpen, "No active bid on this crytar");
        require(currentHighestBidder == msg.sender, "Only bidder can withdraw");

        idToHighestBid[ID].open = false;

        uint256 affectiveWithdrawalAmount = currentHighestBid;

        addressToPendingWithdrawalAmount[currentHighestBidder] += affectiveWithdrawalAmount;

        emit BidWithdrawn(ID, msg.sender);
    }

    function acceptBidOnCrytar(uint256 ID) public {
        require(!paused, "Contract is paused");
        require(ID <= tokenCount && ID != 0, "Invalid token ID");
        address currentOwner = msg.sender;
        address currentHighestBidder = idToHighestBid[ID].user;
        uint256 currentHighestBid = idToHighestBid[ID].amount;
        require(idToHighestBid[ID].open, "No Bid open");
        require(idToCurrentOffer[ID].seller == currentOwner, "Only owner can accept bid");

        idToHighestBid[ID] = Bid(false, address(0), 0);

        if (idToCurrentOffer[ID].open) {
            this.safeTransferFrom(currentOwner, currentHighestBidder, ID);
        } else {
            safeTransferFrom(currentOwner, currentHighestBidder, ID);
        }

        uint256 fees;
        if (currentOwner != owner()) {
            fees = (currentHighestBid * percentCutTenths) / 1000;
        }

        uint256 effectiveTransferAmount = currentHighestBid - fees;

        addressToPendingWithdrawalAmount[currentOwner] += effectiveTransferAmount;
        addressToPendingWithdrawalAmount[owner()] += fees;

        idToCurrentOffer[ID] = Offer(false, currentHighestBidder, currentHighestBid, address(0));

        emit BidAccepted(ID, currentOwner);
    }

    function createProposal(string memory URI) public payable returns (uint256) {
        require(!proposalsPaused, "Proposals are paused");
        require(msg.value == proposalCost, "Please send proposal listing cost");
        proposalsCount++;
        Proposal memory newProposal = Proposal(URI, proposalsCount, 0, msg.sender, msg.value, 0);
        idToProposal[proposalsCount] = newProposal;
        addressToPendingWithdrawalAmount[owner()] += proposalCost;

        return proposalsCount;
    }

    function acceptProposal(uint256 proposalID, uint256 crytarAssigned) public onlyOwner {
        require(proposalID <= proposalsCount && proposalID != 0, "Invalid Proposal ID");
        require(idToProposal[proposalID].status == 0, "Proposal is not open, withdrawn or rejected");
        idToProposal[proposalID].status = 1;
        idToProposal[proposalID].crytarAssigned = crytarAssigned;
        addressToPendingWithdrawalAmount[owner()] += idToProposal[proposalID].escrowAmount;
    }

    function rejectProposal(uint256 proposalID) public onlyOwner {
        require(proposalID <= proposalsCount && proposalID != 0, "Invalid Proposal ID");
        require(idToProposal[proposalID].status == 0, "Proposal is not open, withdrawn or rejected");
        idToProposal[proposalID].status = 3;
        addressToPendingWithdrawalAmount[idToProposal[proposalID].user] += idToProposal[proposalID].escrowAmount;
    }

    function withdrawProposal(uint256 proposalID) public {
        require(!proposalsPaused, "Proposals are paused");
        require(proposalID <= proposalsCount && proposalID != 0, "Invalid Proposal ID");
        require(idToProposal[proposalID].status == 0, "Proposal is not open, withdrawn or rejected");
        require(idToProposal[proposalID].user == msg.sender, "Only the proposal owner can withdraw it");
        idToProposal[proposalID].status = 2;
        uint256 effectiveRefundAmount = idToProposal[proposalID].escrowAmount - proposalWithdrawalCharge;
        addressToPendingWithdrawalAmount[idToProposal[proposalID].user] += effectiveRefundAmount;
        addressToPendingWithdrawalAmount[owner()] += proposalWithdrawalCharge;
    }

    function getWithdrawalBalance(address account) public view returns (uint256) {
        return addressToPendingWithdrawalAmount[account];
    }

    function getOwnedTokens(address ownerAddress) public view returns (uint256[] memory) {
        require(ownerAddress != address(0), "Invalid address supplied");
        uint256 totalTokens = tokenCount;
        uint256 userOwnedTokenCount = 0;
        for (uint256 i = 1; i <= totalTokens; i++) {
            if (ownerOf(i) == ownerAddress) {
                userOwnedTokenCount++;
            }
        }

        uint256[] memory tokenURIArray = new uint256[](userOwnedTokenCount);
        uint256 currentArrayIdx = 0;

        for (uint256 i = 1; i <= totalTokens; i++) {
            if (ownerOf(i) == ownerAddress) {
                tokenURIArray[currentArrayIdx] = i;
                currentArrayIdx++;
            }
        }
        return tokenURIArray;
    }

    function getUserBids(address bidder) public view returns (uint256[] memory) {
        uint256 totalTokens = tokenCount;
        uint256 userOpenBidsCount = 0;
        for (uint256 i = 1; i <= totalTokens; i++) {
            if (idToHighestBid[i].user == bidder && idToHighestBid[i].open) {
                userOpenBidsCount++;
            }
        }

        uint256[] memory tokenIdArray = new uint256[](userOpenBidsCount);
        uint256 currentArrayIdx = 0;

        for (uint256 i = 1; i <= totalTokens; i++) {
            if (idToHighestBid[i].user == bidder && idToHighestBid[i].open) {
                tokenIdArray[currentArrayIdx] = i;
                currentArrayIdx++;
            }
        }

        return tokenIdArray;
    }

    function getUserOffers(address offerer) public view returns (uint256[] memory) {
        uint256 totalTokens = tokenCount;
        uint256 userOpenOffersCount = 0;
        for (uint256 i = 1; i <= totalTokens; i++) {
            if (idToCurrentOffer[i].seller == offerer && idToCurrentOffer[i].open) {
                userOpenOffersCount++;
            }
        }

        uint256[] memory tokenIdArray = new uint256[](userOpenOffersCount);
        uint256 currentArrayIdx = 0;

        for (uint256 i = 1; i <= totalTokens; i++) {
            if (idToCurrentOffer[i].seller == offerer && idToCurrentOffer[i].open) {
                tokenIdArray[currentArrayIdx] = i;
                currentArrayIdx++;
            }
        }

        return tokenIdArray;
    }

    function getUserProposals(address user) public view returns (Proposal[] memory) {
        uint256 userProposalsCount = 0;
        for (uint256 i = 1; i <= proposalsCount; i++) {
            if (idToProposal[i].user == user) {
                userProposalsCount++;
            }
        }

        Proposal[] memory proposalData = new Proposal[](userProposalsCount);
        uint256 currentArrayIdx = 0;

        for (uint256 i = 1; i <= proposalsCount; i++) {
            if (idToProposal[i].user == user) {
                proposalData[currentArrayIdx] = idToProposal[i];
                currentArrayIdx++;
            }
        }

        return proposalData;
    }

    function getOpenProposals() public view returns (Proposal[] memory) {
        uint256 openProposalsCount = 0;
        for (uint256 i = 1; i <= proposalsCount; i++) {
            if (idToProposal[i].status == 0) {
                openProposalsCount++;
            }
        }

        Proposal[] memory proposalData = new Proposal[](openProposalsCount);
        uint256 currentArrayIdx = 0;

        for (uint256 i = 1; i <= proposalsCount; i++) {
            if (idToProposal[i].status == 0) {
                proposalData[currentArrayIdx] = idToProposal[i];
                currentArrayIdx++;
            }
        }

        return proposalData;
    }

    function withdrawFunds() public {
        uint256 amount = addressToPendingWithdrawalAmount[msg.sender];
        require(amount > 0, "No amount left to withdraw");
        addressToPendingWithdrawalAmount[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function updateProposalCost(uint256 newCost) public onlyOwner {
        proposalCost = newCost;
    }

    function updateListingCharge(uint256 newCost) public onlyOwner {
        listingCharge = newCost;
    }

    function updateProposalWithrawalCharge(uint256 newCost) public onlyOwner {
        proposalWithdrawalCharge = newCost;
    }

    function updatePercentCutTenths(uint256 newCost) public onlyOwner {
        percentCutTenths = newCost;
    }

    function updateFloorPrice(uint256 newFloorPrice) public onlyOwner {
        floorPrice = newFloorPrice;
    }

    function pause() public onlyOwner {
        require(!paused, "Already paused");
        paused = true;
    }

    function unpause() public onlyOwner {
        require(paused, "Already un-paused");
        paused = false;
    }

    function pauseProposals() public onlyOwner {
        require(!proposalsPaused, "Already paused");
        proposalsPaused = true;
    }

    function unpauseProposals() public onlyOwner {
        require(proposalsPaused, "Already un-paused");
        proposalsPaused = false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
        idToCurrentOffer[tokenId].seller = to;
        idToCurrentOffer[tokenId].open = false;
        idToCurrentOffer[tokenId].offeredTo = address(0);

        if (idToHighestBid[tokenId].open) {
            require(to != idToHighestBid[tokenId].user, "Cant directly transfer to highest bidder with open bid");
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId);
        idToCurrentOffer[tokenId].seller = to;
        idToCurrentOffer[tokenId].open = false;
        idToCurrentOffer[tokenId].offeredTo = address(0);

        if (idToHighestBid[tokenId].open) {
            require(to != idToHighestBid[tokenId].user, "Cant directly transfer to highest bidder with open bid");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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