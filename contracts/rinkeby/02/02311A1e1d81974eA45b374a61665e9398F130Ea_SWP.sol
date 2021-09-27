/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;

contract IERC20 {
    function balanceOf(address account) public view virtual returns (uint256) {}
    function transfer(address _to, uint256 _value) public returns (bool) {}
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {}
}

contract IERC721Enumerable {
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {}
    function safeTransferFrom(address from, address to, uint256 tokenId) public {}
    function approve(address to, uint256 tokenId) public {}
}


contract SWP {
    struct NFT_offer {
        address nft_address;
        uint256 token_id;
        address trader;
    }

    mapping (address => mapping (uint256 => NFT_offer)) swap_offers;

    constructor () {}

    function offer_swap(address nft_in, uint256 token_in, address nft_out, uint256 token_out) public {
        uint8   verified = 0;
        uint256 j = 0;
        uint256 owned;
        while (verified < 1) {
            owned = IERC721Enumerable(nft_in).tokenOfOwnerByIndex(msg.sender, j);
            if (owned==token_in) verified++;
            j++;
        }
        require(verified==1);
        IERC721Enumerable(nft_in).approve(address(this), token_in);
        swap_offers[nft_in][token_in] = NFT_offer(nft_out, token_out, msg.sender);
    }

    function make_swap(address nft_in, uint256 token_in, address nft_out, uint256 token_out) public {
        IERC721Enumerable(nft_in).approve(address(this), token_in);
        NFT_offer memory offer = swap_offers[nft_out][token_out];
        require(offer.nft_address==nft_in && offer.token_id==token_in);
        IERC721Enumerable(nft_out).safeTransferFrom(offer.trader, msg.sender, token_out);
        IERC721Enumerable(nft_in ).safeTransferFrom(msg.sender, offer.trader, token_in);
    }

}