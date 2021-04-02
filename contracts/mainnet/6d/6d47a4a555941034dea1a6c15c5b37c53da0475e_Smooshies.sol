pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";

contract Smooshies is ERC721, Ownable, IMintedBeforeReveal {

    // This will be the provenance record of all Smooshies in existence at the time once revealed.
    string public constant ORIGINAL_PROVENANCE = "";

    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 1617480000;

    // Time after which the Smooshies are gathered up, randomized, and revealed 5 days from initial launch).
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 5);

    // Maximum amount of Smooshies in existance ever to be minted. Spooky.
    uint256 public constant MAX_SMOOSHIES_SUPPLY = 10000;

    // Facts.
    string public constant R = "They are squeezable, they are squishable. They are Smooshies!";

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

 
    function getSmooshiesMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Pre-Sale has not started yet!");
        require(totalSupply() < MAX_SMOOSHIES_SUPPLY, "Sale has ended, no more Smooshies left to sell :(. Head over to opensea to trade the post-sale market!");

        uint currentSupply = totalSupply();
        
            return 50; // Always allow up to 50 mint
        }

    function getSmooshiesPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Pre-Sale has not started yet!");
        require(totalSupply() < MAX_SMOOSHIES_SUPPLY, "Sale has ended, no more Smooshies left to sell :(. Head over to opensea to trade the post-sale market!");

        uint currentSupply = totalSupply();

        if (currentSupply > 9950) {
            return 1000000000000000000; // 9951-1000: 1.00 ETH
        } else if (currentSupply > 9500) {
            return 800000000000000000; // 9501-9950: 0.80 ETH
        } else if (currentSupply > 8000) {
            return 400000000000000000; // 8001-9500: 0.40 ETH
        } else if (currentSupply > 5000) {
            return 200000000000000000; // 5001-8000: 0.20 ETH
        } else if (currentSupply > 2000) {
            return 150000000000000000; // 2001-5000: 0.15 ETH
        } else if (currentSupply > 500) {
            return 50000000000000000; // 500-2000:  0.05 ETH
        } else {
            return 20000000000000000;  // 1 - 499:   0.02 ETH
        }
    }

    function mintSmooshie(uint256 numberOfSmooshies) public payable {
        require(totalSupply() < MAX_SMOOSHIES_SUPPLY, "Sale has ended, no more Smooshies left to sell :(. Head over to opensea to trade the post-sale market!");
        require(numberOfSmooshies > 0, "You have to mint at least 1 Smooshie");
        require(numberOfSmooshies <= getSmooshiesMaxAmount(), "Woah there Whale! You are not allowed to buy more than 50 Smooshies at once. Please mint 50 and then do another transaction!");
        require(SafeMath.add(totalSupply(), numberOfSmooshies) <= MAX_SMOOSHIES_SUPPLY, "Exceeds maximum Smooshies supply. We are near the end of the sale! Please check the supply remaining and try to mint less Smooshies.");
        require(SafeMath.mul(getSmooshiesPrice(), numberOfSmooshies) == msg.value, "Amount of Ether sent is not correct, please try again");

        for (uint i = 0; i < numberOfSmooshies; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        // Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        // Set the starting block index when the sale concludes either time-wise or the supply runs out.
        if (startingIndexBlock == 0 && (totalSupply() == MAX_SMOOSHIES_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_SMOOSHIES_SUPPLY;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_SMOOSHIES_SUPPLY;
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
      function reserveGiveaway(uint256 numSmooshies) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numSmooshies <= 10, "Exceeded the max giveaway mint of 10. Play fair!");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numSmooshies; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}