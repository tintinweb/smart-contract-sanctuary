/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;

contract SWP {
    struct NFT_offer {
        address nft_address;
        uint256 token_id;
        address trader;
    }
    
    address constant JULIA = 0x6e845bE4ea601B4Dbe98ED1f52b371dca1Dbb2b6; // MAIN NET
    address nft_in  = JULIA;
    address nft_out = JULIA;

    mapping (address => mapping (uint256 => NFT_offer)) swap_offers;

    constructor () {}

    /*
      One has to approve this contract to use his/her `token_offered` before calling this
    */
    function offer_swap(uint256 token_offered, uint256 token_requested) public {
        uint8   verified = 0;
        uint256 j = 0;
        uint256 owned;
        while (verified < 1) {
            owned = IERC721Enumerable(nft_in).tokenOfOwnerByIndex(msg.sender, j);
            if (owned==token_offered) verified++;
            j++;
        }
        require(verified==1);
        require(IERC721Enumerable(nft_in).getApproved(token_offered)==address(this));
        swap_offers[nft_in][token_offered] = NFT_offer(nft_out, token_requested, msg.sender);
    }

    /*
      One has to approve this contract to use his/her `token_in` before calling this.
      `token_in` is the token that is required by the offer maker 
      and should be held by the party accepting the offer.
      `tokwen_out` is the token that is offered by the offer maker 
      and will be given to the party accepting the offer.
    */
    function make_swap(uint256 token_in,uint256 token_out) public {
        NFT_offer memory offer = swap_offers[nft_out][token_out];
        require(offer.nft_address==nft_in && offer.token_id==token_in);
        IERC721Enumerable(nft_out).safeTransferFrom(offer.trader, msg.sender, token_out);
        IERC721Enumerable(nft_in ).safeTransferFrom(msg.sender, offer.trader, token_in);
    }

    /*
      Checks if an offer to swap `token_offered` for `token_requested` is available and approved
      (just to avoid wasting gas in case `make_swap` would fail)
    */
    function check_offer(uint256 token_offered, uint256 token_requested) public view returns (bool) {
        NFT_offer memory offer = swap_offers[nft_out][token_offered];
        bool approved = IERC721Enumerable(nft_out).getApproved(token_offered)==address(this);
        return (offer.nft_address==nft_in && offer.token_id==token_requested && approved);
    }

}

contract IERC721Enumerable {
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {}
    function safeTransferFrom(address from, address to, uint256 tokenId) public {}
    function getApproved(uint256 tokenId) external view returns (address operator) {}
}