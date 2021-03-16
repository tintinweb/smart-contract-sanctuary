/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity ^0.8.0;


contract AuctionFactory  {
    struct Nft {
        address contractAddress;
        uint256 nftId;
    }
    
    struct Slot {
        uint256 currentNft;
        mapping(uint256 => Nft) nfts;
    }

    struct Auction {
       address owner;
       uint256 numberOfSlots;
       mapping(uint256 => Slot) slots;
    }

    uint256 public totalAuctions;
     
    mapping(uint256 => Auction) public auctionsOf;
    
    
    function createAuction(uint256 numberOfSlots) external {
        Auction storage auction = auctionsOf[totalAuctions++];
        
        auction.numberOfSlots = numberOfSlots;
        auction.owner = msg.sender;
    }
    
    function depositERC721(uint256 auctionIdx, uint256 slotIdx, uint256 nftId, address contractAddress) external {
        Slot storage slot = auctionsOf[auctionIdx].slots[slotIdx];
        
        slot.currentNft++;
        
        slot.nfts[slot.currentNft].nftId = nftId;
        slot.nfts[slot.currentNft].contractAddress = contractAddress;
    }
    
}