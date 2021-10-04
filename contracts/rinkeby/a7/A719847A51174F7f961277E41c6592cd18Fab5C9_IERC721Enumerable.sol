/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;

contract SWP {
    struct NFT_offer {
        address nft_address;
        uint256 token_id;
        address trader;
    }
    
    address constant JULIA = 0xdd665AFF8C98ee39e4D581caB1e48A1DbE8B055d; // TEST NET
    //address constant JULIA = 0x6e845bE4ea601B4Dbe98ED1f52b371dca1Dbb2b6;
    address constant nft_in  = JULIA;
    address constant nft_out = JULIA;

    mapping (address => mapping (uint256 => NFT_offer)) swap_offers;

    event OfferMade(uint256 offered, uint256 requested, address trader);

    constructor () {}

    /*
      One has to approve this contract to use his/her `token_offered` before calling the function
    */
    function offer_swap(uint256 token_offered, uint256 token_requested) public {
        require(IERC721Enumerable(nft_in).ownerOf(token_offered)==msg.sender);
        require(IERC721Enumerable(nft_in).getApproved(token_offered)==address(this) || IERC721Enumerable(nft_in).isApprovedForAll(msg.sender, address(this)) );
        swap_offers[nft_in][token_offered] = NFT_offer(nft_out, token_requested, msg.sender);
        emit OfferMade(token_offered, token_requested, msg.sender);
    }

    /*
      One has to approve this contract to use his/her `token_you_give` before calling this.
      `token_you_get` is the token that is required by the offer maker and should be held by the party accepting the offer.
      `token_you_give` is the token that is offered by the offer maker and will be given to the party accepting the offer.
    */
    function make_swap(uint256 token_you_give, uint256 token_you_get) public {
        NFT_offer memory offer = swap_offers[nft_out][token_you_get];
        require(offer.nft_address==nft_in && offer.token_id==token_you_give);
        IERC721Enumerable(nft_out).transferFrom(offer.trader, msg.sender, token_you_get);
        IERC721Enumerable(nft_in ).transferFrom(msg.sender, offer.trader, token_you_give);
    }

    /*
      Checks if an offer to swap `token_offered` for `token_requested` is available and approved
      (just to avoid wasting gas in case `make_swap` would fail)
    */
    function check_offer(uint256 token_offered, uint256 token_requested) public view returns (bool) {
        NFT_offer memory offer = swap_offers[nft_out][token_offered];
        bool approved = IERC721Enumerable(nft_out).getApproved(token_offered)==address(this) || IERC721Enumerable(nft_out).isApprovedForAll(offer.trader, address(this));
        return (offer.nft_address==nft_in && offer.token_id==token_requested && approved);
    }

}

contract IERC721Enumerable {
    function transferFrom(address from, address to, uint256 tokenId) public {}
    function getApproved(uint256 tokenId) external view returns (address operator) {}
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {}
    function ownerOf(uint256 tokenId) external view returns (address owner) {}
}