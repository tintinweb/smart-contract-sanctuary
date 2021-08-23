// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract AngryBoars is ERC721, ERC721Enumerable, Ownable {

    string public BOAR_PROVENANCE = ""; // IPFS PROVENANCE TO BE ADDED WHEN SOLD OUT

    string public LICENSE_TEXT = "";

    bool licenseLocked = false;

    uint256 public boarPrice = 40000000000000000; // 0.040 ETH

    uint256 public constant maxBoarPurchase = 15;

    uint256 public constant MAX_BOARS = 10000;

    bool public saleIsActive = false;

    uint256 public boarReserve = 150;

    event licenseisLocked(string _licenseText);

    constructor() ERC721("Angry Boars", "BOARS") {}

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function reserveBoars(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(
            _reserveAmount > 0 && _reserveAmount <= boarReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        boarReserve = boarReserve - _reserveAmount;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        BOAR_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        setBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Returns the license for tokens
    function tokenLicense(uint256 _id) public view returns (string memory) {
        require(_id < totalSupply(), "BOAR NOT FOUND");
        return LICENSE_TEXT;
    }

    // Locks the license to prevent further changes
    function lockLicense() public onlyOwner {
        licenseLocked = true;
        emit licenseisLocked(LICENSE_TEXT);
    }

    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }

    function mintBoar(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active");
        require(
            numberOfTokens > 0 && numberOfTokens <= maxBoarPurchase,
            "Can only mint 15 tokens at a time"
        );
        require(
            totalSupply() + numberOfTokens <= MAX_BOARS - boarReserve,
            "Purchase would exceed max supply of Angry Boars"
        );
        require(
            msg.value >= boarPrice * numberOfTokens,
            "Not enough eth"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_BOARS - boarReserve) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function setBoarPrice(uint256 newPrice) public onlyOwner {
        boarPrice = newPrice;
    }
}