import "./ERC721.sol";
import "./SafeMath.sol";

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title NFT contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract NFT is ERC721 {
    using SafeMath for uint256;

    uint256 public count = 0;
    uint256 public nftPrice = 0.00000001 * (10 ** 18);
    uint public constant maxNftPurchase = 20;
    uint256 public MAX_NFTS = 10000;
    uint256 public NUMBER_OF_GIVEAWAY = 100;
    uint256 public NUMBER_OF_KOLRON = 1;
    uint256 public kolroneMintedCount = 0;
    bool public saleIsActive = false;

    event SafeMinted(address who, uint64 timestamp, uint256[] tokenIds);
    event GiveawaySafeMinted(address who);
    event KolronSafeMinted(address who);

    constructor() ERC721("Dragons of Zobrotera", "DOZ") {
        _setBaseURI("");
        initialMint();
    }

    function initialMint() private {
        _safeMint(msg.sender, 0);
        count += 1;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function discoverNft(uint64 timeStamp, uint64 numberOfToken) public payable {
        require(saleIsActive, "Sale must be active to mint Nft");
        require(totalSupply().add(numberOfToken) <= MAX_NFTS, "Purchase would exceed max supply of Nfts");
        require(nftPrice.mul(numberOfToken) <= msg.value, "Ether value sent is not correct");

        uint256[] memory output = new uint256[](numberOfToken);

        for(uint32 i = 0; i < numberOfToken; i++){
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            output[i] = mintIndex;
            count += 1;
        }

        emit SafeMinted(msg.sender, timeStamp, output);
    }

    function giveAway(address winner) public onlyOwner {
        require(totalSupply().add(1) <= MAX_NFTS.add(NUMBER_OF_GIVEAWAY), "The number of givaway has reached its maximum");
        require(winner != owner(), "Owner cannot receive giveaway");
        uint mintIndex = totalSupply();
        _safeMint(winner, mintIndex);
        count += 1;
        emit GiveawaySafeMinted(winner);
    }

    function mintKolron(address winner) public onlyOwner {
        require(kolroneMintedCount < NUMBER_OF_KOLRON, "Kolrone as already been minted");
        require(winner != owner(), "Kolrone cannot be minted by the owner");
        _safeMint(
            winner, 
            MAX_NFTS.add(
                NUMBER_OF_GIVEAWAY.add(
                    kolroneMintedCount.add(1)
                )
            )
        );
        kolroneMintedCount++;
        emit KolronSafeMinted(winner);
    }

    function getCount() public view returns(uint256) {
        return count;
    }

    // Emergency: price can be changed in case of large fluctuations in ETH price.
    // This feature is here to prevent nft from having prices that are too different from each other.
    // WITH A MAXIMUM OF 0.1 ETH
    function emergencyChangePrice(uint256 newPrice) public onlyOwner {
        require(newPrice <= 0.1 * (10 ** 18), "Price can't exceed 0.1 ETH");
        nftPrice = newPrice;
    }

    function totalSupply() public view returns (uint256) {
        return getCount();
    }

    function isSaleActive() public view returns (bool) {
        return saleIsActive;
    }
}