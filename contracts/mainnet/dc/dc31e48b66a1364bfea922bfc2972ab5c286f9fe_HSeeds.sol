pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
//import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

// did it for the gas


contract HSeeds is ERC721Enumerable, Ownable, ReentrancyGuard {
    //using SafeMath for uint256; 
    //see: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2465
    
    // ===============================================================

    
    // This is the provenance record of all artwork in existence
    string public constant ENTROPYSEEDS_PROVENANCE = "51aab9a30a64f0b1f8325ccfa7e80cbcc20b9dbab4b4e6765c3e5178e507d210";

    // opens Mar 11 2021 15:00:00 GMT+0000
    uint256 public constant SALE_START_TIMESTAMP = 1615474800;


    // Time after which we randomly assign and allotted (s*m*h*d)
    // sale lasts for 21 days
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (60*60*24*21);

    uint256 public constant MAX_NFT_SUPPLY = 8275;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    // Mapping from token ID to whether the Entropyseed was minted before reveal
    mapping (uint256 => bool) private _mintedBeforeReveal;
    
    
    // ===============================================================
    constructor() public ERC721("EntropySeeds", "HSED") {}


    /**
     * @dev Returns if the NFT has been minted before reveal phase
     */
    function isMintedBeforeReveal(uint256 index) public view returns (bool) {
        return _mintedBeforeReveal[index];
    }
    
    /**
     * @dev Gets current price level
     */
    function getNFTPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");

        uint256 currentSupply = totalSupply();

        if (currentSupply >= 8270) {
            return 100000000000000000000; // 8270 - 8275 100 ETH
        } else if (currentSupply >= 7885) {
            return 5000000000000000000; // 7885 - 8269 5.0 ETH
        } else if (currentSupply >= 7300) {
            return 3400000000000000000; // 7300  - 7884 3.4 ETH
        } else if (currentSupply >= 5400) {
            return 1800000000000000000; // 5400 - 7399 1.8 ETH
        } else if (currentSupply >= 3400) {
            return 1000000000000000000; // 3400 - 5399 1.0 ETH
        } else if (currentSupply >= 1500) {
            return 600000000000000000; // 1500 - 3399 0.6 ETH
        } else {
            return 200000000000000000; // 0 - 1499 0.2 ETH 
        }
    }
    
    /**
    * @dev Mints numberOfNfts Entropyseeds
    * Price slippage is okay between levels. Known "bug".
    */
    function mintNFT(uint256 numberOfNfts) public payable nonReentrant {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 5, "You may not buy more than 5 NFTs at once");
        require((totalSupply() + numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require((getNFTPrice() * numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            uint256 mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        /**
        * Source of "randomness". Theoretically miners could influence this but not worried for the scope of this project
        */
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }
    
    /**
     * @dev Called after the sale ends or reveal period is over
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        

        uint256 _start = uint256(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        if ((block.number - _start) > 255) {
            _start = uint256(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        if (_start == 0) {
            _start = _start + 1;
        }
        
        startingIndex = _start;
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}