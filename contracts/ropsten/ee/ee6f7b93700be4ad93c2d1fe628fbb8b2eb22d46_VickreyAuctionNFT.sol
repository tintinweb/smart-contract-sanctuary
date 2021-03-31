/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

/**
 * An implementation of vickrey auction on ERC-721 token (NFT)
 * Adapted by Nangos
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


//
// --------------------------------------------------------------------------------------------
//

pragma solidity >=0.6.0 <0.8.0;
/**
 * Reference: https://programtheblockchain.com/posts/2018/04/03/writing-a-vickrey-auction-contract/
 * Modified by Nangos to support ERC-721 NFT tokens
 */


/* Vickrey Auction Rules (Blockchain ver.) 
------------------------------------------------
STAGE I -- Bid:
- A bidder cannot be the seller.
- A bidder should bid only one price. The price must be at least the `reservePrice`.
- Bidders submit encrypted bids so that no one else knows it until they reveal.
- Along with the bid, a bidder must deposit some value (note that deposit is not bid -- the deposit is not a secret!)
- Don't miss the bid deadline.

STAGE II -- Reveal:
- A bidder cannot reveal until the bid deadline, but please don't miss the reveal deadline either.
- The bid revealed must match the encrypted version (and no more than the deposit for sure) to be considered valid.
- If a bidder do not reveal their bid in time, their deposit will be locked forever. So please always reveal!!

STAGE III -- Decide the Winner:
- The bidder with the highest price wins the auction, but only pays the seller for the second highest price.
- After the reveal deadline, everyone who revealed can withdraw the overpayed part of their deposit.
- Corner case 1: When there's a tie, the bidder who reveals first wins. So I would say reveal as soon as you can!
- Corner case 2: When there's only one valid bidder, they wins and pays for the `reservePrice`.
- Corner case 3: When there's no valid bidder, nobody wins. The seller can then withdraw their item.
*/

contract VickreyAuctionNFT {
    address public seller;
    bool public started;

    IERC721 public tokenAddress;
    uint256 public tokenID;
    uint256 public reservePrice;
    uint256 public endOfBidding;
    uint256 public endOfRevealing;

    address public highBidder;
    uint256 public highBid;
    uint256 public secondBid;
    mapping(address => bool) public revealed;
    
    function winner() public view returns (address) {
        require(block.timestamp >= endOfRevealing, "Auction is still going on!");
        require(highBidder != seller, "No winner!");
        return highBidder;
    }
    
    mapping(address => uint256) public balanceOf; // store the deposits of players
    mapping(address => bytes32) public hashedBidOf; // store the hashed bids of players


    constructor(
        IERC721 _tokenAddress,
        uint256 _tokenID,
        uint256 _reservePrice, // in wei !!
        uint256 biddingPeriod, // in seconds !!
        uint256 revealingPeriod // in seconds !!
    ){
        require(_reservePrice > 0, "Reserve price cannot be zero");
        require(_tokenAddress.ownerOf(_tokenID) == msg.sender, "The seller must own the NFT!");

        tokenAddress = _tokenAddress;
        tokenID = _tokenID;
        reservePrice = _reservePrice;

        started = false;
        endOfBidding = biddingPeriod; // assuming the time now is "zero"
        endOfRevealing = endOfBidding + revealingPeriod; // assuming the time now is "zero"

        seller = msg.sender;

        highBidder = seller;
        highBid = reservePrice;
        secondBid = reservePrice;

        // the seller can't bid, but this simplifies withdrawal logic
        revealed[seller] = true;
    }
    
    modifier onlyStarted {
        require(started, "Auction is not started yet!");
        _;
    }
    
    
    // Only the seller can call this function to start the auction.
    //
    // Before starting, the seller must approve this contract to lock seller's NFT into this address.
    // (This operation can only be done in the NFT contract, not here.)
    function startAuction() public {
        require(!started, "Auction is already started!");
        require(msg.sender == seller, "Only seller can start the auction!");
        require(tokenAddress.getApproved(tokenID) == address(this), "The seller have not approved this contract!");
        
        tokenAddress.transferFrom(msg.sender, address(this), tokenID); // seller has to lock in their token during the auction
        endOfBidding += block.timestamp;
        endOfRevealing += block.timestamp;
        
        started = true;
    }

    
    // Bid with a deposit. Note that the deposit is not the bid.
    // You can bid multiple times. Deposit accumulates, and your bid overwrites.
    function bid(bytes32 hash) public payable onlyStarted {
        require(block.timestamp < endOfBidding, "It's not time to bid!");
        require(msg.sender != seller, "Seller cannot bid!");

        hashedBidOf[msg.sender] = hash;
        balanceOf[msg.sender] += msg.value;
        require(balanceOf[msg.sender] >= reservePrice, "Deposit is too low!");
    }

 
    function transfer(address from, address to, uint256 amount) internal {
        balanceOf[to] += amount;
        balanceOf[from] -= amount;
    }


    function reveal(uint256 amount, uint256 nonce) public onlyStarted {
        require(block.timestamp >= endOfBidding && block.timestamp < endOfRevealing, "It's not time to reveal!");
        require(keccak256(abi.encodePacked(amount, nonce)) == hashedBidOf[msg.sender], "Hash mismatch!");
        require(amount <= balanceOf[msg.sender], "Amount too large!");
        require(amount >= reservePrice, "Amount too small!");
        require(!revealed[msg.sender], "You had revealed!");
        revealed[msg.sender] = true;

        // We are doing so because we do not know which reveal is final.
        // Nothing will be auto-triggered at the deadline moment, so we maintain the winner info to be up-to-date.
        
        // Well we must make this clear: upon a tie, the early bird wins.
        if (highBidder == seller || amount > highBid) {
            // undo the previous escrow
            transfer(seller, highBidder, secondBid);

            // update the highest and second highest bids
            secondBid = highBid;
            highBid = amount;
            highBidder = msg.sender;

            // escrow an amount equal to the second highest bid
            transfer(highBidder, seller, secondBid);
        } else if (amount > secondBid) {
            // undo the previous escrow
            transfer(seller, highBidder, secondBid);

            // update the second highest bid
            secondBid = amount;

            // escrow an amount equal to the second highest bid
            transfer(highBidder, seller, secondBid);
       }
    }
    
    // NOTE: the seller also calls this function to withdraw their token if not sold.
    function claim() public onlyStarted {
        require(block.timestamp >= endOfRevealing, "Auction is still going on!");
        tokenAddress.transferFrom(address(this), highBidder, tokenID);
    }

    // NOTE: the seller also calls this function to claim their money.
    function withdraw() public onlyStarted {
        require(block.timestamp >= endOfRevealing, "Auction is still going on!");
        require(revealed[msg.sender], "You did not reveal, so cannot withdraw!");

        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}