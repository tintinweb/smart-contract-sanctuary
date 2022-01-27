/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

pragma solidity >=0.5.0 <0.6.0;

contract BotTest {

    struct NFT {
        string name;
        uint id;
    }

    bool public publicSaleActive = false;
    uint public totalCount;
    NFT[] public nfts;

    function publicMint(string memory _name) public {
        require(publicSaleActive, "Public sale not open yet.");
        nfts.push(NFT(_name, totalCount));
        totalCount++;
    }

    function startPublicSale() public {
        publicSaleActive = true;
    }

    function stopPublicSale() public {
        publicSaleActive = false;
    }

}