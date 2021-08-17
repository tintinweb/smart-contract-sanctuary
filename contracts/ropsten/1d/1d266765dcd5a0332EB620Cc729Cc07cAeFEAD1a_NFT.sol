import "./ERC721.sol";
import "./Ownable.sol";

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

/**
 * @title NFT contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract NFT is ERC721, Ownable {
    uint256 public count = 0;
    
    event Increment(address who);

    using SafeMath for uint256;
    uint256 public nftPrice = 0.00000001 * (10 ** 18);
    uint public constant maxNftPurchase = 100;
    uint256 public MAX_NFTS = 100;
    bool public saleIsActive = true;

    constructor() public ERC721("Cartoon dragons", "DRAG") {
        _setBaseURI("");
        _safeMint(msg.sender, MAX_NFTS);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function discoverNft(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Nft");
        require(numberOfTokens <= maxNftPurchase, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_NFTS, "Purchase would exceed max supply of Nfts");
        require(nftPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_NFTS) {
                _safeMint(msg.sender, mintIndex);
                count += 1;
            }
        }

        emit Increment(msg.sender);
    }

    function getCount() public view returns(uint256) {
        return count;
    }

    // Emergency: can be changed to account for large fluctuations in ETH price
    function emergencyChangePrice(uint256 newPrice) public onlyOwner {
        nftPrice = newPrice;
    }
}