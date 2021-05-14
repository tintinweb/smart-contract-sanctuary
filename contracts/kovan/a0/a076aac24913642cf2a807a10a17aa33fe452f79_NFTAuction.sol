/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;



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
contract NFTAuction {

    uint public numSamplesBeforeSale;
    uint public secondsPerSample;
    uint public startingPrice;
    uint public startTime;
    uint public lastBid = 0;
    uint public lastBidTime = 0;
    uint public tokenForSale;
    // uint public constant priceFactor = 2;

    bool public auctionStarted = false;
    bool public auctionConcluded = false;

    address payable public beneficiary;
    address payable public lastBidder;
    IERC721 public nftContract;

    mapping (address => uint) public accounts;

    constructor(uint _numSamplesBeforeSale,
                uint _secondsPerSample,
                uint _startingPrice,
                uint _startTime,
                address payable _beneficiary,
                address _nftContract,
                uint _tokenForSale) {
        numSamplesBeforeSale = _numSamplesBeforeSale;
        secondsPerSample = _secondsPerSample;
        startingPrice = _startingPrice;
        startTime = _startTime;
        beneficiary = _beneficiary;
        nftContract = IERC721(_nftContract);
        tokenForSale = _tokenForSale;
    }

    function canStart() public view returns (bool) {
        return block.timestamp > startTime && nftContract.ownerOf(tokenForSale) == address(this);
    }

    function startAuction() public {
        require(canStart(), 'Check time and that contract owns nft for sale');
        auctionStarted = true;
    }

    function getSamplesSinceLastBid() public view returns (uint) {
        if (lastBidTime == 0) {
            return 0;
        }
        uint timeDiff = block.timestamp - lastBidTime;
        uint samplesDiff = timeDiff / secondsPerSample;

        return samplesDiff;
    }

    function getCurrentPrice() public view returns (uint) {
        if (lastBid == 0) {
            return startingPrice;
        } else if (auctionConcluded) {
            return 0;
        } else {
            uint samplesDiff = getSamplesSinceLastBid();
            return lastBid + (lastBid / (1 << samplesDiff));
        }
    }

    function bid() public payable {
        require(auctionStarted, 'Not started yet');
        require(auctionConcluded == false, 'Auction concluded');
        uint price = getCurrentPrice();
        require(price <= msg.value, 'Please send more ETH');
        if (lastBidder != address(0)) {
            lastBidder.transfer(lastBid);
        }
        lastBid = price;
        lastBidTime = block.timestamp;
        lastBidder = msg.sender;
    }

    function canConclude() public view returns (bool) {
        return auctionConcluded == false && getSamplesSinceLastBid() >= numSamplesBeforeSale;
    }

    function concludeAuction() public {
        require(canConclude(), 'Contract already concluded or not enough samples passed');
        auctionConcluded = true;
        accounts[lastBidder] = 0;
        beneficiary.transfer(lastBid);
        nftContract.transferFrom(address(this), lastBidder, tokenForSale);
    }

}