/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

pragma solidity >=0.5.0 <0.6.0;

contract BotTestInt {

    struct NFT {
        int integer;
        uint id;
    }

    bool public publicSaleActive = false;
    uint public totalCount;
    NFT[] public nfts;

    function publicMint(int integer) public {
        require(publicSaleActive, "Public sale not open yet.");
        nfts.push(NFT(integer, totalCount));
        totalCount++;
    }

    function startPublicSale() public {
        publicSaleActive = true;
    }

    function stopPublicSale() public {
        publicSaleActive = false;
    }

}