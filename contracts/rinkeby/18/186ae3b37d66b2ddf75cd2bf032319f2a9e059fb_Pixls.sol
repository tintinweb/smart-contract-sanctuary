pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";

contract Pixls is ERC721, Ownable, IMintedBeforeReveal {

    // This is the original provenance record of all Picklz in existence at the time.
    string public constant ORIGINAL_PROVENANCE = "";

    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 1616886188;

    // Time after which the Pixls are randomized and revealed 7 days from initial launch).
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 7);

    // Maximum amount of Pixls in existance. Ever.
    uint256 public constant MAX_PIXL_SUPPLY = 4269;

    // Truth.
    string public constant R = "To take away our expression, is to empoverish our existence.";

    // The block in which the starting index was created.
    uint256 public startingIndexBlock;

    // The index of the item that will be #1.
    uint256 public startingIndex;

    // Mapping from token ID to whether the Pixl was minted before reveal.
    mapping (uint256 => bool) private _mintedBeforeReveal;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }

    /**
    * @dev Returns if the Pixl was minted before reveal phase. This could come in handy later.
    */
    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }

    /**
    * @dev Gets current Pixl price based on current supply.
    */
    function getPixlMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_PIXL_SUPPLY, "Sale has already ended, no more Pixls left to sell.");

        uint currentSupply = totalSupply();
        
        if (currentSupply >= 1500) {
            return 20; // After 1500, do it per 20.
        }
        else if (currentSupply >= 75) {
            return 10; // From 75 to 1500 - per 10.
        } 
        else {
            return 2; // First 75 can only be bought per 2.
        }
    }

    /**
    * @dev Gets current Pixl price based on current supply.
    */
    function getPixlPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_PIXL_SUPPLY, "Sale has already ended, no more Pixls left to sell.");

        uint currentSupply = totalSupply();

        if (currentSupply >= 8615) {
            return 10000000000000000000; // 8615 - 8618 10 ETH
        } else if (currentSupply >= 8375) {
            return 3000000000000000000; // 8375 - 8614 3.0 ETH
        } else if (currentSupply >= 7875) {
            return 1700000000000000000; // 7875  - 8374 1.7 ETH
        } else if (currentSupply >= 5775) {
            return 900000000000000000; // 5775 - 7874 0.9 ETH
        } else if (currentSupply >= 3675) {
            return 500000000000000000; // 3675 - 5774 0.5 ETH
        } else if (currentSupply >= 1575) {
            return 300000000000000000; // 1575 - 3674 0.3 ETH
        } else if (currentSupply >= 75) {
            return 100000000000000000; // 75 - 1574 0.1 ETH
        } else {
            return 30000000000000000; // 0 - 74 0.03 ETH 
        }
    }

    /**
    * @dev Mints yourself a Pixl. Or more. You do you.
    */
    function mintAPixl(uint256 numberOfPixls) public payable {
        // Some exceptions that need to be handled.
        require(totalSupply() < MAX_PIXL_SUPPLY, "Sale has already ended.");
        require(numberOfPixls > 0, "You cannot mint 0 Pixls.");
        require(numberOfPixls <= getPixlMaxAmount(), "You are not allowed to buy this many Pixls at once in this price tier.");
        require(SafeMath.add(totalSupply(), numberOfPixls) <= MAX_PIXL_SUPPLY, "Exceeds maximum Pixl supply. Please try to mint less Pixls.");
        require(SafeMath.mul(getPixlPrice(), numberOfPixls) == msg.value, "Amount of Ether sent is not correct.");

        // Mint the amount of provided Pixls.
        for (uint i = 0; i < numberOfPixls; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        // Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        // Set the starting block index when the sale concludes either time-wise or the supply runs out.
        if (startingIndexBlock == 0 && (totalSupply() == MAX_PIXL_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_PIXL_SUPPLY;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_PIXL_SUPPLY;
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