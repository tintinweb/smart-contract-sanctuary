pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";

contract Hotdog is ERC721, Ownable, IMintedBeforeReveal {

    string public constant ORIGINAL_PROVENANCE = "";

    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 1617202800;


    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 7);

    // Maximum amount of hotdogs in existance.
    uint256 public constant MAX_HOTDOG_SUPPLY = 10000;

    // Truth.
    string public constant R = "Some shitty hotdogs, breh";

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

 
    function getHotdogMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_HOTDOG_SUPPLY, "Sale has already ended, no more left to sell.");

        uint currentSupply = totalSupply();
        

            return 500; // 500 max per transaction
 
    }

    function getHotdogPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_HOTDOG_SUPPLY, "Sale has already ended, no more left to sell.");

        uint currentSupply = totalSupply();

  
            return 10000000000000000;  //   0.01 ETH
 
    }

    function mintAHotdog(uint256 numberOfHotdog) public payable {
        // Some exceptions that need to be handled.
        require(totalSupply() < MAX_HOTDOG_SUPPLY, "Sale has already ended.");
        require(numberOfHotdog > 0, "You cannot mint 0 Hotdogs.");
        require(numberOfHotdog <= getHotdogMaxAmount(), "You are not allowed to buy this many Hotdog at once in this price tier.");
        require(SafeMath.add(totalSupply(), numberOfHotdog) <= MAX_HOTDOG_SUPPLY, "Exceeds maximum Hotdog supply. Please try to mint less Hotdog.");
        require(SafeMath.mul(getHotdogPrice(), numberOfHotdog) == msg.value, "Amount of Ether sent is not correct.");

        for (uint i = 0; i < numberOfHotdog; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        // Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        // Set the starting block index when the sale concludes either time-wise or the supply runs out.
        if (startingIndexBlock == 0 && (totalSupply() == MAX_HOTDOG_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_HOTDOG_SUPPLY;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_HOTDOG_SUPPLY;
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
      function reserveGiveaway(uint256 numHotdog) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numHotdog <= 100, "1% for Giveaways and Stuff");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numHotdog; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}