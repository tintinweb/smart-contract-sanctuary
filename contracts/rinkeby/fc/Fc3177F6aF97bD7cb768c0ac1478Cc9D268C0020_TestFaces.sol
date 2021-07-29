pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";

contract TestFaces is ERC721, Ownable, IMintedBeforeReveal {

    // This is the provenance record of all Items in existence. The provenance will be updated once metadata is live at launch.
    string public constant ORIGINAL_PROVENANCE = "";

    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 10;

    // Time after which the Items are randomized and revealed 7 days from instantly after initial launch).
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP;

    // Maximum amount of Items in existance.
    uint256 public constant MAX_Item_SUPPLY = 24;

    // The block in which the starting index was created.
    uint256 public startingIndexBlock;

    // The index of the item that will be #1.
    uint256 public startingIndex;

    mapping (uint256 => bool) private _mintedBeforeReveal;
    
    bool public saleActive = false;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }

    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }
 
    function getItemMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_Item_SUPPLY, "Sale has already ended and all sold out, no more left to sell.");

        uint currentSupply = totalSupply();

            return 10; // 10 max per transaction
 
    }

    function getItemPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_Item_SUPPLY, "Sale has already ended, no more Items left to sell.");

        uint currentSupply = totalSupply();
  
            return 50000000000000000;  //   0.05 ETH
 
    }

    function mintItem(uint256 numberOfItem) public payable {
        // Exceptions that need to be handled + launch switch mechanic
        require(saleActive == true, "Sale has not started yet");
        require(totalSupply() < MAX_Item_SUPPLY, "Sale has already ended.");
        require(numberOfItem > 0, "You cannot mint 0 Items, please increase to more than 1");
        require(numberOfItem <= getItemMaxAmount(), "You are not allowed to buy this many Items at once. The limit is 10.");
        require(SafeMath.add(totalSupply(), numberOfItem) <= MAX_Item_SUPPLY, "Exceeds maximum Item supply of 3,000. Please try to mint less Items.");
        require(SafeMath.mul(getItemPrice(), numberOfItem) == msg.value, "Amount of Ether sent is not correct.");

        for (uint i = 0; i < numberOfItem; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        if (startingIndexBlock == 0 && (totalSupply() == MAX_Item_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_Item_SUPPLY;

        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_Item_SUPPLY;
        }

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
    
     function Launch() public onlyOwner {
        saleActive = !saleActive;
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
      function reserveGiveaway(uint256 numItem) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numItem <= 40, "40 mints for sale giveaways");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numItem; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}