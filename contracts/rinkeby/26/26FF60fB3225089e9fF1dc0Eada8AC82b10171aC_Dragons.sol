// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Dragons is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    
    event ActionBuy(address indexed _owner, uint256 _id, uint256 count);
    event ActionAward(address indexed _owner, uint256 _id, uint256 count);
    
    uint256 public constant MAX_NFT_SUPPLY = 7777;
    uint256 public constant MAX_AWARDED_MANUALLY = 200;
    uint256 public constant MAX_BOUGHT = 7577;
    
    uint256 public constant MAX_BUY_COUNT = 7;
    
    uint256 public constant NFT_PRICE = 0.0777 ether;
    
    uint256 public _totalAwardedManually = 0;
    uint256 public _totalBought = 0;
    uint256 public _mintIndex = 0;
    
    bool public saleStarted = false;
    uint256 public saleEndTimestamp;
    // uint256 public constant SALE_DURATION = 277200; // 77*60*60 (timestamp)
    uint256 public constant SALE_DURATION = 577200; // temporary - TODO remove
    
    mapping (uint256 => uint256) public tokenIdToBirthBlockNumber;
    
    uint256 public constant NO_ODDS = 20;
    uint256 public constant EVOLUTION_BLOCK_COUNT = 8151; // 30*60*60/13.25 (block number between evolutions)
    
    uint8[20] public odds6 = [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 5, 5];
    uint8[20] public odds8 = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 6, 6, 7];
    uint8[20] public odds10 = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 5, 5, 6, 7, 8, 9];
    string[6] public namesBreed = ["inferno", "tidal", "gravestone", "zephyr", "trakkor", "ironlung"];
    string[10] public namesBackground = ["bg1", "bg2", "bg3", "bg4", "bg5", "bg6", "bg7", "bg8", "bg9", "bg10"];
    string[6] public namesPattern = ["nopattern", "stripes", "spots", "spirals", "prismatic", "xray"];
    string[6] public namesMood = ["nomood", "bashful", "silly", "confused", "chill", "fierce"];
    string[8] public namesBreath = ["nobreath", "flame", "icy", "electric", "poison", "darkness", "cosmic", "sonic"];
    string[8] public namesHorns = ["nohorns", "long", "spiked", "webbed", "ram", "bone", "uni", "bull"];

    string public baseURI = "";
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory __name, string memory __symbol)
        ERC721(__name, __symbol)
    {}
    
    function startSale() external onlyOwner {
      require(saleStarted == false, "Sale already started");
      
      saleStarted = true;
      saleEndTimestamp = block.timestamp + SALE_DURATION;
    }

    // Metadata handlers
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        string memory base = _baseURI();
        
        uint256 blockNo0 = tokenIdToBirthBlockNumber[tokenId];
        uint256 blockNo1 = blockNo0.add(EVOLUTION_BLOCK_COUNT);
        uint256 blockNo2 = blockNo1.add(EVOLUTION_BLOCK_COUNT);
        uint256 blockNo3 = blockNo2.add(EVOLUTION_BLOCK_COUNT);
        uint256 blockNo4 = blockNo3.add(EVOLUTION_BLOCK_COUNT);
        
        uint256 index_breed = (uint256(keccak256(abi.encodePacked(tokenId, blockhash(blockNo0)))) % NO_ODDS);
        uint256 index_bg = (uint256(keccak256(abi.encodePacked(tokenId, blockhash(blockNo0), uint8(1)))) % NO_ODDS);
        uint256 index_pattern = (uint256(keccak256(abi.encodePacked(tokenId, blockhash(blockNo1)))) % NO_ODDS);
        uint256 index_mood = (uint256(keccak256(abi.encodePacked(tokenId, blockhash(blockNo2)))) % NO_ODDS);
        uint256 index_breath = (uint256(keccak256(abi.encodePacked(tokenId, blockhash(blockNo3)))) % NO_ODDS);
        uint256 index_horns = (uint256(keccak256(abi.encodePacked(tokenId, blockhash(blockNo4)))) % NO_ODDS);
        
        if (blockNo4 < block.number) {
            return string(abi.encodePacked(
            base,
            namesBreed[odds6[index_breed]],
            "-", namesBackground[odds10[index_bg]],
            "-", namesPattern[odds6[index_pattern]],
            "-", namesMood[odds6[index_mood]],
            "-", namesBreath[odds8[index_breath]],
            "-", namesHorns[odds8[index_horns]]
          ));
        } else if (blockNo3 < block.number) {
            return string(abi.encodePacked(
            base,
            namesBreed[odds6[index_breed]],
            "-", namesBackground[odds10[index_bg]],
            "-", namesPattern[odds6[index_pattern]],
            "-", namesMood[odds6[index_mood]],
            "-", namesBreath[odds8[index_breath]]
          ));
        } else if (blockNo2 < block.number) {
            return string(abi.encodePacked(
            base,
            namesBreed[odds6[index_breed]],
            "-", namesBackground[odds10[index_bg]],
            "-", namesPattern[odds6[index_pattern]],
            "-", namesMood[odds6[index_mood]]
          ));
        } else if (blockNo1 < block.number) {
            return string(abi.encodePacked(
            base,
            namesBreed[odds6[index_breed]],
            "-", namesBackground[odds10[index_bg]],
            "-", namesPattern[odds6[index_pattern]]
          ));
        } else {
            return string(abi.encodePacked(
            base,
            namesBreed[odds6[index_breed]],
            "-", namesBackground[odds10[index_bg]]
          ));
        }
    }
    
    // Minting
            
    function mint(address minter, uint256 count) private returns (uint256) {
      require(_mintIndex.add(count) <= MAX_NFT_SUPPLY, "Mint limit exceeded");
      require(minter != address(0), "Minter address error");
      require(count > 0, "Count can't be 0");
      
      uint256 initial = _mintIndex;
      
      for (uint256 i = 0; i < count; i++) {
        require(!_exists(_mintIndex), "Token already minted");
        _mint(minter, _mintIndex);
        // evolveToken(_mintIndex, true);
        tokenIdToBirthBlockNumber[_mintIndex] = block.number - 1;
        _mintIndex++;
      }
      
      return initial;
    }
    
    // Award for free
    
    function awardFree(address minter, uint256 count) external onlyOwner returns (uint256) {
      require(saleStarted && block.timestamp <= saleEndTimestamp, "Sale not started or already ended");
      require(_totalAwardedManually.add(count) <= MAX_AWARDED_MANUALLY, "Award limit exceeded");
      
      _totalAwardedManually = _totalAwardedManually.add(count);
      uint256 initial = mint(minter, count);
      emit ActionAward(msg.sender, initial, count);
      
      return initial;
    }
    
    // Buy new
    
    function buy(uint256 count) external payable returns (uint256) {
      require(saleStarted && block.timestamp <= saleEndTimestamp, "Sale not started or already ended");
      require(_totalBought.add(count) <= MAX_BOUGHT, "Buy limit exceeded");
      require(count <= MAX_BUY_COUNT, "Count too big");
      require(msg.value == count.mul(NFT_PRICE), "Ether value sent is not correct");
      
      _totalBought = _totalBought.add(count);
      uint256 initial = mint(msg.sender, count);
      emit ActionBuy(msg.sender, initial, count);
      
      return initial;
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}