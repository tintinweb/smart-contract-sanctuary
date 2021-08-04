pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";

contract TierZero is ERC721, Ownable, IMintedBeforeReveal {


    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 1628200680;

    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP;

    // Maximum amount of Monsters in existance.
    uint256 public constant MAX_BEAST_SUPPLY = 10000;

    // The block in which the starting index was created.
    uint256 public startingIndexBlock;

    // The index of the item that will be #1.
    uint256 public startingIndex;

    mapping (uint256 => bool) private _mintedBeforeReveal;
    
    bool public saleActive = false;
    
    uint256 private _BEASTprice = 0.06 ether;
    
    address Address1 = 0x859A5bBF4085789063e79e181D44659093f4d5d0;
    address Address2 = 0x2349334b6c1Ee1eaF11CBFaD871570ccdF28440e;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }

    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }
 
    function getBEASTMaxAmount() public view returns (uint256) {
            return 10; // 10 max per transaction
 
    }

  function setBEASTPrice(uint256 _newBEASTPrice) public onlyOwner() {
        _BEASTprice = _newBEASTPrice;
    }


   function getBEASTPrice() public view returns (uint256){
        return _BEASTprice;
    }

    function mintBEAST(uint256 numberOfBEAST) public payable {
        // Exceptions that need to be handled + launch switch mechanic
        require(saleActive == true, "Sale has not started yet");
        require(totalSupply() < MAX_BEAST_SUPPLY, "Sale has already ended.");
        require(numberOfBEAST > 0, "You cannot mint 0 Beasts, please increase to more than 1");
        require(numberOfBEAST <= getBEASTMaxAmount(), "You are not allowed to buy this many Beasts at once. The limit is 10.");
        require(SafeMath.add(totalSupply(), numberOfBEAST) <= MAX_BEAST_SUPPLY, "Exceeds maximum Beasts supply of 10,000. Please try to mint less Beasts.");
        require(SafeMath.mul(getBEASTPrice(), numberOfBEAST) == msg.value, "Amount of Ether sent is not correct.");

        for (uint i = 0; i < numberOfBEAST; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        if (startingIndexBlock == 0 && (totalSupply() == MAX_BEAST_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_BEAST_SUPPLY;

        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_BEAST_SUPPLY;
        }

        if (startingIndex == 0) {
            startingIndex = SafeMath.add(startingIndex, 1);
        }
    }
    

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(Address1).transfer(balance*473/500);
        payable(Address2).transfer(balance*27/500);
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
      function reserveGiveaway(uint256 numBEAST) public onlyOwner {
        uint currentSupply = totalSupply();
        require(totalSupply() + numBEAST <= 100, "100 mints for sale giveaways");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numBEAST; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}