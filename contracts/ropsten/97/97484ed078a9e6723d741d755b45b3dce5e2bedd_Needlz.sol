pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";

contract Needlz is ERC721, Ownable, IMintedBeforeReveal {

    // This is the original provenance record of all Needlz in existence at the time.
    string public constant ORIGINAL_PROVENANCE = "1c62a14aa7ca18ace1edf889b668bc22e156d890d9d00f085e63e4f3b7c0d394";

    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 1616101922;

    // Time after which the Needlz are randomized and revealed (1 day from initial launch).
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 1);

    // Maximum amount of Needlz in existance. Ever.
    uint256 public constant MAX_NEEDLZ_SUPPLY = 5;

    // The block in which the starting index was created.
    uint256 public startingIndexBlock;

    // The index of the item that will be #1.
    uint256 public startingIndex;

    // Mapping from token ID to whether the Needlz was minted before reveal.
    mapping (uint256 => bool) private _mintedBeforeReveal;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }

    /**
    * @dev Returns if the Needlz was minted before reveal phase. This could come in handy later.
    */
    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }

    /**
    * @dev Gets current Needlz price based on current supply.
    */
    function getNeedlzMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_NEEDLZ_SUPPLY, "Sale has already ended, no more Needlz left to sell.");

        uint currentSupply = totalSupply();
        
        if (currentSupply >= 2) {
            return 2; // After 1500, do it per 20.
        }
        else if (currentSupply >= 1) {
            return 1; // From 75 to 1500 - per 10.
        } 
        else {
            return 1; // First 75 can only be bought per 2.
        }
    }

    /**
    * @dev Gets current Needlz price based on current supply.
    */
    function getNeedlzPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_NEEDLZ_SUPPLY, "Sale has already ended, no more Needlz left to sell.");

        uint currentSupply = totalSupply();

        if (currentSupply >= 3) {
            return 10000000000000; // 0 - 3 .0001 ETH
        } else {
            return 30000000000000; // 3 - 5 0.03 ETH 
        }
    }

    /**
    * @dev Mints yourself a Needlz. Or more. You do you.
    */
    function mintANeedlz(uint256 numberOfNeedlz) public payable {
        // Some exceptions that need to be handled.
        require(totalSupply() < MAX_NEEDLZ_SUPPLY, "Sale has already ended.");
        require(numberOfNeedlz > 0, "You cannot mint 0 Needlz.");
        require(numberOfNeedlz <= getNeedlzMaxAmount(), "You are not allowed to buy this many Needlz at once in this price tier.");
        require(SafeMath.add(totalSupply(), numberOfNeedlz) <= MAX_NEEDLZ_SUPPLY, "Exceeds maximum Needlz supply. Please try to mint less Needlz.");
        require(SafeMath.mul(getNeedlzPrice(), numberOfNeedlz) == msg.value, "Amount of Ether sent is not correct.");

        // Mint the amount of provided Needlz.
        for (uint i = 0; i < numberOfNeedlz; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        // Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        // Set the starting block index when the sale concludes either time-wise or the supply runs out.
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NEEDLZ_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NEEDLZ_SUPPLY;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_NEEDLZ_SUPPLY;
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
}