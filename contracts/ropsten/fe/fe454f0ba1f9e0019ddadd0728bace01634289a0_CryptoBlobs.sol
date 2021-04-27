// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721EnumerableSimple.sol";

contract CryptoBlobs is ERC721EnumerableSimple, Ownable {
    
    // Maximum number of CryptoBlobs.
    uint256 public constant MAX_CRYPTOBLOBS = 12500;

    // Provenance hash.
    string public METADATA_PROVENANCE_HASH = "";

    // Text.
    string public constant R = "Discover the world of CryptoBlobs and adopt yours on CryptoBlobs.com!";

    // CryptoBlobs Adoption Center open/closed.
    bool public isAdoptable = false;

    // Metadata.
    string private baseURI;
    
    // Token name and symbol.
    constructor() ERC721("CryptoBlobs", unicode"✦") {}

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0); // Return an empty array.
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function calculatePrice() public view returns (uint256) {
        require(isAdoptable, "The CryptoBlobs Adoption Center is closed.");
        return calculatePriceForToken(totalSupply());
    }

    function calculatePriceForToken(uint256 _id) public pure returns (uint256) {
        require(_id < MAX_CRYPTOBLOBS, "All CryptoBlobs have been adopted!");
        if (_id >= 12400) {
            return 1.00 ether;      // index 0 12400-12499      index 1 12401-12500     1.00 ETH
        } else if (_id >= 12200) {
            return 0.95 ether;      // index 0 12200-12399      index 1 12201-12400     0.95 ETH
        } else if (_id >= 12000) {
            return 0.90 ether;      // index 0 12000-12199      index 1 12001-12200     0.90 ETH
        } else if (_id >= 11800) {
            return 0.80 ether;      // index 0 11800-11999      index 1 11801-12000     0.80 ETH
        } else if (_id >= 10200) {
            return 0.64 ether;      // index 0 10200-11799      index 1 10201-11800     0.64 ETH
        } else if (_id >= 10000) {
            return 0.48 ether;      // index 0 10000-10199      index 1 10001-10200     0.48 ETH
        } else if (_id >= 9800) {
            return 0.40 ether;      // index 0 9800-9999        index 1 9801-10000      0.40 ETH
        } else if (_id >= 8200) {
            return 0.32 ether;      // index 0 8200-9799        index 1 8201-9800       0.32 ETH
        } else if (_id >= 8000) {
            return 0.24 ether;      // index 0 8000-8199        index 1 8001-8200       0.24 ETH
        } else if (_id >= 7800) {
            return 0.20 ether;      // index 0 7800-7999        index 1 7801-8000       0.20 ETH
        } else if (_id >= 6200) {
            return 0.16 ether;      // index 0 6200-7799        index 1 6201-7800       0.16 ETH
        } else if (_id >= 6000) {
            return 0.12 ether;      // index 0 6000-6199        index 1 6001-6200       0.12 ETH
        } else if (_id >= 5800) {
            return 0.10 ether;      // index 0 5800-5999        index 1 5801-6000       0.10 ETH
        } else if (_id >= 4200) {
            return 0.08 ether;      // index 0 4200-5799        index 1 4201-5800       0.08 ETH
        } else if (_id >= 4000) {
            return 0.06 ether;      // index 0 4000-4199        index 1 4001-4200       0.06 ETH
        } else if (_id >= 3800) {
            return 0.05 ether;      // index 0 3800-3999        index 1 3801-4000       0.05 ETH
        } else if (_id >= 2200) {
            return 0.04 ether;      // index 0 2200-3799        index 1 2201-3800       0.04 ETH
        } else if (_id >= 2000) {
            return 0.03 ether;      // index 0 2000-2199        index 1 2001-2200       0.03 ETH
        } else if (_id >= 1800) {
            return 0.025 ether;     // index 0 1800-1999        index 1 1801-2000       0.025 ETH
        } else if (_id >= 200) {
            return 0.020 ether;     // index 0 200-1799         index 1 201-1800        0.020 ETH
        } else if (_id >= 100) {
            return 0.015 ether;     // index 0 100-199          index 1 101-200         0.015 ETH
        } else {
            return 0.010 ether;     // index 0 0-99             index 1 1-100           0.010 ETH
        }
    }
    
    function adopt(uint256 numCryptoBlobs) public payable {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_CRYPTOBLOBS, "All CryptoBlobs have been adopted!");
        require(_totalSupply + numCryptoBlobs <= MAX_CRYPTOBLOBS, "Exceeds the maximum amount of CryptoBlobs that can exist.");
        require(numCryptoBlobs > 0 && numCryptoBlobs <= 100, "You can adopt a minimum of 1 CryptoBlob and a maximum of 100 CryptoBlobs.");
        require(msg.value >= calculatePrice() * numCryptoBlobs, "The adoption fee is higher than what was sent.");

        for (uint256 i = 0; i < numCryptoBlobs; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory __baseURI) public onlyOwner {
        baseURI = __baseURI;
    }

    function adoptioncenterOpen() public onlyOwner {
        isAdoptable = true;
    }

    function adoptioncenterClosed() public onlyOwner {
        isAdoptable = false;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function contractBalanceWithdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    // Reserved for developers, friends, giveaways, etc.
    function claimReserved(uint256 numCryptoBlobs) public onlyOwner {
        uint256 currentSupply = totalSupply();
        require(currentSupply + numCryptoBlobs <= 25, "Exceeds the claimable reserved limit of 25 CryptoBlobs.");
        for (uint256 index = 0; index < numCryptoBlobs; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}