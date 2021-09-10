import "./ERC721.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title NFT contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract NFT is ERC721, AccessControl{
    using SafeMath for uint256;

    bytes32 private constant whiteListedRole = keccak256("wl");

    uint public constant maxNftPurchase = 20;
    uint public constant maxNftPurchaseOnPresale = 1;

    address[] private presaled;

    uint256 private count = 0;
    uint256 private testCount = 1 * (10 ** 10);
    uint256 private nftPrice = 0.069 * (10 ** 18);
    uint256 private NUMBER_OF_GIVEAWAY = 0;
    uint256 private MAX_NFTS = 10000;
    uint256 private NUMBER_OF_KOLRON = 1;
    uint256 private kolroneMintedCount = 0;
    bool private saleIsActive = false;

    event SafeMinted(address who, uint64 timestamp, uint256[] tokenIds, bool isTestMint);
    event GiveawaySafeMinted(address who);
    event KolronSafeMinted(address who);

    constructor() ERC721("Dragons of Zobrotera", "DOZ") {

    }

    function initialMint() private {
        _safeMint(msg.sender, 0);
        count += 1;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function reserveNumberOfGiveaway(uint256 numberOfGiveaway) public onlyOwner {
        NUMBER_OF_GIVEAWAY = numberOfGiveaway;
    }

    function whitelistAddressToPresale(address[] memory addresses) public onlyOwner{
        for(uint32 i = 0; i < addresses.length; i++){
            grantRole(whiteListedRole, msg.sender);
        }
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Mint worthless nft fro integration testing 
    // Permite the admin/owner to test all applications ecosystem integration validity
    function adminTestMint(uint64 timeStamp, uint64 numberOfToken) public payable onlyOwner{
        uint256[] memory output = new uint256[](numberOfToken);

        for(uint32 i = 0; i < numberOfToken; i++){
            uint mintIndex = testCount;
            _safeMint(msg.sender, mintIndex);
            output[i] = mintIndex;
            testCount += 1;
        }

        emit SafeMinted(msg.sender, timeStamp, output, true);
    }

    function mintAllPresaledNft() public onlyOwner{
        uint256 numberOfMint = presaled.length;
        for(uint32 i = 0; i < numberOfMint; i++){
            _safeMint(presaled[i], i);
        }
    }

    function buyNftOnPresale() public payable onlyRole(whiteListedRole) {
        require(totalSupply().add(1) <= MAX_NFTS, "Purchase would exceed max supply of Nfts");
        require(nftPrice.mul(1) <= msg.value, "Ether value sent is not correct");
        require(balanceOf(msg.sender).add(1) <= maxNftPurchaseOnPresale, "You can't mint more than 1 token with the same account");

        presaled.push(msg.sender);
        count += 1;
    }

    function mintNft(uint64 timeStamp, uint64 numberOfToken) public payable {
        require(saleIsActive, "Sale must be active to mint Nft");
        require(totalSupply().add(numberOfToken) <= MAX_NFTS, "Purchase would exceed max supply of Nfts");
        require(nftPrice.mul(numberOfToken) <= msg.value, "Ether value sent is not correct");
        require(balanceOf(msg.sender).add(numberOfToken) <= maxNftPurchase, "You can't mint more than 20 token with the same account");

        uint256[] memory output = new uint256[](numberOfToken);

        for(uint32 i = 0; i < numberOfToken; i++){
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            output[i] = mintIndex;
            count += 1;
        }

        emit SafeMinted(msg.sender, timeStamp, output, false);
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