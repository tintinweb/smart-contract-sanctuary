// contracts/NFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract BroJobs is ERC721, Ownable {
    using SafeMath for uint256;
    uint256 public constant MAX_BROS = 2;
    bool public hasSaleStarted = false;

    // Mapping from token ID to name
    mapping(uint256 => string) private _tokenName;

    string public constant R = "BRO JOB BRO JOB";

    // Events
    event NameChange(uint256 indexed maskIndex, string newName);

    constructor(string memory baseURI) ERC721("Bro Jobs", "BJ") {
        setBaseURI(baseURI);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
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

    function claimBro() public payable {
        require(hasSaleStarted, "Sale paused");
        require(totalSupply() < MAX_BROS, "No more bros left");

        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }

    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "only owner can change name");
        require(validateName(newName) == true, "Not a valid new name");
        require(
            sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])),
            "New name is same as the current one"
        );

        _tokenName[tokenId] = newName;

        emit NameChange(tokenId, newName);
    }

    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length > 1) return false;

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            // A-Z only
            if (!(char >= 0x41 && char <= 0x5A)) return false;
        }

        return true;
    }

    // God Mode
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}