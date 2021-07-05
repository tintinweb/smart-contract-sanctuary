// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract Ciphersquares is ERC721, Ownable {
    using SafeMath for uint256;

    string public CIPHERSQUARES_PROVENANCE = "";

    // Maximum amount of NFTs in existance.
    uint256 public constant MAX_NFT_SUPPLY = 3623;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    uint256 public REVEAL_TIMESTAMP;

    address payable private constant _tFirst =
        payable(0x31ED6272EE42493E0D898a595D15e9FB55196F32);
    address payable private constant _tSecond =
        payable(0xBE97e949A89a45F7c141A4d686864dA501cD0664);

    bool public saleIsActive = false;

    constructor() ERC721("Ciphersquares", "CSQR") {}

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
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
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function getNFTPrice() public view returns (uint256) {
        uint256 cipherSupply = totalSupply();

        if (cipherSupply >= MAX_NFT_SUPPLY) {
            return 0;
        } else if (cipherSupply >= 3613) {
            return 3.5 ether;
        } else if (cipherSupply >= 3463) {
            return 1.9 ether;
        } else if (cipherSupply >= 3213) {
            return 1.2 ether;
        } else if (cipherSupply >= 2813) {
            return 0.7 ether;
        } else if (cipherSupply >= 2163) {
            return 0.3 ether;
        } else if (cipherSupply >= 1263) {
            return 0.17 ether;
        } else if (cipherSupply >= 663) {
            return 0.09 ether;
        } else if (cipherSupply >= 213) {
            return 0.04 ether;
        } else {
            return 0.01 ether;
        }
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        CIPHERSQUARES_PROVENANCE = _provenance;
    }

    /**
     * @dev Mints yourself NFTs.
     */
    function mintNFTs(uint256 count) external payable {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(count > 0, "numberOfNfts cannot be 0");
        require(count <= 20, "You may not buy more than 20 NFTs at once");
        require(
            SafeMath.add(totalSupply(), count) <= MAX_NFT_SUPPLY,
            "Exceeds MAX_NFT_SUPPLY"
        );
        require(
            SafeMath.mul(getNFTPrice(), count) == msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < count; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_NFT_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (
            startingIndexBlock == 0 &&
            (totalSupply() == MAX_NFT_SUPPLY ||
                block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * @dev send eth to treasuryFirst and treasurySecond.
     */
    function withdraw() external onlyOwner {
        uint256 total = address(this).balance;
        uint256 amount = total.div(4);
        _tFirst.transfer(amount);
        _tSecond.transfer(total.sub(amount));
    }

    function startSale() external onlyOwner {
        saleIsActive = true;
        if (REVEAL_TIMESTAMP == 0) {
            REVEAL_TIMESTAMP = block.timestamp + (86400 * 28);
        }
    }

    function pauseSale() external onlyOwner {
        saleIsActive = false;
    }

    /**
     * Set the reveal timestamp index for the collection
     */
    function setRevealTimestamp(uint256 revealTimeStamp) external onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() external {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex =
                uint256(blockhash(block.number - 1)) %
                MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }
}