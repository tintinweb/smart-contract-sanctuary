// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Toddler is Ownable, ERC721Enumerable {
    uint256 public mintPrice = 0.01 ether;
    uint256 public constant mintLimit = 20;

    uint256 public supplyLimit = 6969;

    string public baseURI;

    bool public claimActive = true;
    bool public saleActive = true;

    bool[10001] private claimedInfants;
    mapping(address => bool) private claimedAddresses;

    constructor(string memory _initBaseURI) ERC721("Toddler", "TODDLER") {
        setBaseURI(_initBaseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseUri) public onlyOwner {
        baseURI = newBaseUri;
    }

    function setSaleActive(bool newSaleActive) external onlyOwner {
        saleActive = newSaleActive;
    }

    function getSaleActive() public view returns (bool) {
        return saleActive == true;
    }

    function setClaimActive(bool newClaimActive) external onlyOwner {
        claimActive = newClaimActive;
    }

    function getClaimActive() public view returns (bool) {
        return claimActive == true;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function mintToddler(uint256 numberOfTokens) external payable {
        require(getSaleActive(), "Sale is not active");
        require(
            numberOfTokens <= mintLimit,
            "Too many tokens for one transaction"
        );
        require(
            msg.value >= mintPrice * numberOfTokens,
            "Insufficient payment"
        );

        _mintToddler(msg.sender, numberOfTokens);
    }

    function _mintToddler(address to, uint256 numberOfTokens) private {
        require(getSaleActive(), "Sale is not active");
        require(
            totalSupply() + numberOfTokens <= supplyLimit,
            "Not enough tokens left"
        );

        uint256 newId = totalSupply();
        for (uint256 i = 0; i < numberOfTokens; i++) {
            newId += 1;
            _safeMint(to, newId);
        }
    }

    function claimToddler() external {
        IERC721Enumerable infant = IERC721Enumerable(address(0x045c0d8Ba345fed4709aAD90d620c82E5A765c13));

        uint256 tokenCount = infant.balanceOf(msg.sender);
        require(tokenCount > 0, "Claim prerequisite not satisfied");

        require(
            claimedAddresses[msg.sender] == false,
            "Claim prerequisite not satisfied"
        );
        claimedAddresses[msg.sender] = true;

        uint256 tokenId;
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenId = infant.tokenOfOwnerByIndex(msg.sender, i);
            require(
                claimedInfants[tokenId] == false,
                "Claim prerequisite not satisfied"
            );
            claimedInfants[tokenId] = true;
        }

        _mintToddler(msg.sender, 1);
    }

    function infantEligibleForClaim(uint256 tokenId) external view returns (bool) {
        return !claimedInfants[tokenId];
    }

    function addressEligibleForClaim(address _address)
        external
        view
        returns (bool)
    {
        return !claimedAddresses[_address];
    }

    function reserve(address to, uint256 numberOfTokens) external onlyOwner {
        _mintToddler(to, numberOfTokens);
    }

    function tokensOwnedBy(address wallet)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(wallet);

        uint256[] memory ownedTokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            ownedTokenIds[i] = tokenOfOwnerByIndex(wallet, i);
        }

        return ownedTokenIds;
    }

    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(payable(0x873A32007e674d9A6b877d7f627c3d4eA5e8aBCb).send((contractBalance * 25) / 100), "Withdraw failed 1");
        require(payable(0x873A32007e674d9A6b877d7f627c3d4eA5e8aBCb).send(address(this).balance), "Withdraw failed 2"); // remaining
    }
}