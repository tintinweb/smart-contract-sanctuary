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
    
    event SafeMinted(address who, uint64 timestamp, uint256 tokenId);

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

    function discoverNft(uint64 timeStamp) public payable {
        uint256 ownedTokensCount = balanceOf(msg.sender) + 1;
        require(saleIsActive, "Sale must be active to mint Nft");
        require(ownedTokensCount <= maxNftPurchase, "Can only mint 20 tokens per address");
        require(totalSupply().add(1) <= MAX_NFTS, "Purchase would exceed max supply of Nfts");
        require(nftPrice.mul(1) <= msg.value, "Ether value sent is not correct");
        
        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
        count += 1;

        emit SafeMinted(msg.sender, timeStamp, mintIndex);
    }

    function getCount() public view returns(uint256) {
        return count;
    }

    // Emergency: can be changed to account for large fluctuations in ETH price
    function emergencyChangePrice(uint256 newPrice) public onlyOwner {
        nftPrice = newPrice;
    }
}