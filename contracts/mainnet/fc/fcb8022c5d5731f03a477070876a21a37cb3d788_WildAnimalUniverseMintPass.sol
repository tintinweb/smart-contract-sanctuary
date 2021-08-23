pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";

contract WildAnimalUniverseMintPass is ERC721, Ownable, IMintedBeforeReveal {


    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 1629679036;

    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP;

    // Maximum amount in existance.
    uint256 public constant MAX_ANIMALPASS_SUPPLY = 5555;

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
 
    function getANIMALPASSMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_ANIMALPASS_SUPPLY, "Sale has already ended and all sold out, no more left to sell.");


            return 55; // 55 max per transaction
 
    }

    function getANIMALPASSPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_ANIMALPASS_SUPPLY, "Sale has already ended, no more Wild Passes left to sell.");


            return 50000000000000000;  //   0.05 ETH
 
    }

    function mintWILDPASS(uint256 numberOfANIMALPASS) public payable {
        // Exceptions that need to be handled + launch switch mechanic
        require(saleActive == true, "Sale has not started yet");
        require(totalSupply() < MAX_ANIMALPASS_SUPPLY, "Sale has already ended.");
        require(numberOfANIMALPASS > 0, "You cannot mint 0, please increase to 1 or more");
        require(numberOfANIMALPASS <= getANIMALPASSMaxAmount(), "You are not allowed to buy this many at once. The limit is 10.");
        require(SafeMath.add(totalSupply(), numberOfANIMALPASS) <= MAX_ANIMALPASS_SUPPLY, "Exceeds maximum supply of 5,555. Please try to mint less.");
        require(SafeMath.mul(getANIMALPASSPrice(), numberOfANIMALPASS) == msg.value, "Amount of Ether sent is not correct.");

        for (uint i = 0; i < numberOfANIMALPASS; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        if (startingIndexBlock == 0 && (totalSupply() == MAX_ANIMALPASS_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_ANIMALPASS_SUPPLY;

        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_ANIMALPASS_SUPPLY;
        }

        if (startingIndex == 0) {
            startingIndex = SafeMath.add(startingIndex, 1);
        }
    }
    
   
    address Address1 = 0x836530e1095B1B3A244751e3d296BF6a9EBC678D;
    address Address2 = 0xED0597cf344B344328f9091BD9931e14Db6CC799;
    address Address3 = 0x7F10171f927eF5053Df88801ECe76b8dEEc43Df4;
    address Address4 = 0x0E0459B365de942401dBb0ab409eDFE2CE110069;
    address Address5 = 0x943472A249202dDA686Eb1a4dA126f0de14F9B2A;


    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(Address1).transfer(balance*25/100);
        payable(Address2).transfer(balance*25/100);
        payable(Address3).transfer(balance*25/100);
        payable(Address4).transfer(balance*10/100);
        payable(Address5).transfer(balance*15/100);
        payable(msg.sender).transfer(address(this).balance);
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
      function reserveGiveaway(uint256 numANIMALPASS) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numANIMALPASS <= 55, "55 mints for sale giveaways");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numANIMALPASS; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}