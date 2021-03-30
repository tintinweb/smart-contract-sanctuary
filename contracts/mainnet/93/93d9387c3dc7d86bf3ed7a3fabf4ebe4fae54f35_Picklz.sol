pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";

contract Picklz is ERC721, Ownable, IMintedBeforeReveal {

    // This is the original provenance record of all Picklz in existence at the time.
    string public constant ORIGINAL_PROVENANCE = "";

    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 1617202800;

    // Time after which the Picklz are randomized and revealed 7 days from initial launch).
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 7);

    // Maximum amount of Picklz in existance.
    uint256 public constant MAX_PICKLZ_SUPPLY = 4269;

    // Truth.
    string public constant R = "Some of our pickles are looking for love, others just want to watch the world burn.";

    // The block in which the starting index was created.
    uint256 public startingIndexBlock;

    // The index of the item that will be #1.
    uint256 public startingIndex;

    mapping (uint256 => bool) private _mintedBeforeReveal;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }

    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }

 
    function getPicklzMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_PICKLZ_SUPPLY, "Sale has already ended, no more Picklz left to sell.");

        uint currentSupply = totalSupply();
        
        if (currentSupply >= 201) {
            return 20; // After 200, do it per 20.
       } else {
            return 5; // First 200 can only be bought per 5.
        }
    }

    function getPicklzPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_PICKLZ_SUPPLY, "Sale has already ended, no more Picklz left to sell.");

        uint currentSupply = totalSupply();

        if (currentSupply > 4200) {
            return 690000000000000000; // 4200-4269: 0.69 ETH
        } else if (currentSupply > 4000) {
            return 500000000000000000; // 4000-4200: 0.50 ETH
        } else if (currentSupply > 3200) {
            return 400000000000000000; // 3200-4000: 0.40 ETH
        } else if (currentSupply > 2200) {
            return 300000000000000000; // 2200-3200: 0.30 ETH
        } else if (currentSupply > 1200) {
            return 200000000000000000; // 1200-2200: 0.20 ETH
        } else if (currentSupply > 200) {
            return 100000000000000000; // 200-1200:  0.10 ETH
        } else {
            return 50000000000000000;  // 0 - 200:   0.05 ETH
        }
    }

    function mintAPicklz(uint256 numberOfPicklz) public payable {
        // Some exceptions that need to be handled.
        require(totalSupply() < MAX_PICKLZ_SUPPLY, "Sale has already ended.");
        require(numberOfPicklz > 0, "You cannot mint 0 Picklz.");
        require(numberOfPicklz <= getPicklzMaxAmount(), "You are not allowed to buy this many Picklz at once in this price tier.");
        require(SafeMath.add(totalSupply(), numberOfPicklz) <= MAX_PICKLZ_SUPPLY, "Exceeds maximum Picklz supply. Please try to mint less Picklz.");
        require(SafeMath.mul(getPicklzPrice(), numberOfPicklz) == msg.value, "Amount of Ether sent is not correct.");

        for (uint i = 0; i < numberOfPicklz; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        // Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        // Set the starting block index when the sale concludes either time-wise or the supply runs out.
        if (startingIndexBlock == 0 && (totalSupply() == MAX_PICKLZ_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_PICKLZ_SUPPLY;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_PICKLZ_SUPPLY;
        }

        // Prevent default sequence because that would be a bit boring.
        if (startingIndex == 0) {
            startingIndex = SafeMath.add(startingIndex, 1);
        }
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function changeBaseURI(string memory baseURI) onlyOwner public {
       _setBaseURI(baseURI);
    }
       /**
    * @dev Reserved for people who helped this project and giveaways. Max 10
    */
      function reserveGiveaway(uint256 numPicklz) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numPicklz <= 10, "Exceeded giveaway supply");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numPicklz; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}