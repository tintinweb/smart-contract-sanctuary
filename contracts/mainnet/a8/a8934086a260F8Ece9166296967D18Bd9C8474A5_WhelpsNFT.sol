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

contract WhelpsNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    
    address public _approvedContract = address(0);
    
    /**
     * @dev Returns the address of the current owner.
     */
    function approvedContract() public view virtual returns (address) {
        return _approvedContract;
    }
    
    function setApprovedContract(address _contract) external onlyOwner {
      _approvedContract = _contract;
    }
    
    modifier onlyOwnerOrApprovedContract() {
        require(owner() == _msgSender() || approvedContract() == _msgSender(), "Caller is not the owner or the approved contract");
        _;
    }
    
    event ActionBuy(address indexed _owner, uint256 _id, uint256 count);
    event ActionAward(address indexed _owner, uint256 _id, uint256 count);
    
    uint256 public constant MAX_NFT_SUPPLY = 7777;
    uint256 public constant MAX_AWARDED_MANUALLY = 275;
    uint256 public constant MAX_BOUGHT = 7502;
    
    uint256 public constant MAX_BUY_COUNT = 7;
    
    uint256 public constant NFT_PRICE = 0.0777 ether;
    
    uint256 public _totalAwardedManually = 0;
    uint256 public _totalBought = 0;
    uint256 public _mintIndex = 0;
    
    bool public saleStarted = false;
    uint256 public saleEndTimestamp;
    uint256 public constant SALE_DURATION = 604800; // 7*24*60*60 (timestamp)
    
    mapping (uint256 => uint256) public tokenIdToBirthBlockNumber;
    
    uint256 public constant NO_ODDS = 20;
    uint256 public constant EVOLUTION_BLOCK_COUNT = 8151; // 30*60*60/13.25 (block number between evolutions)
    
    uint8[20] public odds6 = [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 5, 5];
    uint8[20] public odds8 = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 6, 6, 7];
    uint8[20] public odds10 = [0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 5, 5, 6, 7, 8, 9];
    string[6] public namesBreed = ["inferno", "tidal", "gravestone", "zephyr", "trakkor", "ironlung"];
    string[10] public namesBackground = ["bg0", "bg1", "bg2", "bg3", "bg4", "bg5", "bg6", "bg7", "bg8", "bg9"];
    string[6] public namesPattern = ["nopattern", "stripes", "spots", "spirals", "prismatic", "xray"];
    string[6] public namesMood = ["nomood", "bashful", "silly", "confused", "chill", "fierce"];
    string[8] public namesBreath = ["nobreath", "flame", "icy", "electric", "poison", "darkness", "cosmic", "sonic"];
    string[8] public namesHorns = ["nohorns", "long", "spiked", "webbed", "ram", "bone", "uni", "bull"];

    string public baseURI = "https://whelpsio.herokuapp.com/api/";
    string public ipfsBaseURI = "https://whelps.mypinata.cloud/ipfs/";
    mapping (uint256 => string) public tokenTraitSummaryToIpfsHash;
    
    // 1 - force use computed name for all
    // 2 - use ipfs hash if available, fallback to computed name
    // 3 - force use ipfs hash for all
    uint256 public metadataSwitch = 1;
    bool public ipfsLocked = false;
    mapping (uint256 => bool) public ipfsLockPerToken;
    bool public switchLocked = false;
    
    uint256[] public blocks = [0];
    uint256[] public blockhashHistory = [0];
    uint256 public constant BLOCKHASH_MINIMUM_BLOCK_INTERVAL = 27; // 6*60/13.25 (at least 10 minutes between hashes added)
    
    function totalBlocks() public view returns (uint256) {
      return blocks.length;
    }
    
    function lastBlock() public view returns (uint256) {
      return blocks[blocks.length-1];
    }
    
    function checkHash() public view returns (uint256) {
      return (block.number-1) - lastBlock();
    }
    
    function externalRecordBlockhash() external {
      uint256 recordedBlock = block.number - 1;
      require(lastBlock().add(BLOCKHASH_MINIMUM_BLOCK_INTERVAL) <= recordedBlock);
    
      internalRecordBlockhash(recordedBlock);
    }
    
    function internalRecordBlockhash(uint256 recordedBlock) internal {
      blocks.push(recordedBlock);
      blockhashHistory.push(uint256(blockhash(recordedBlock)));
    }
    
    function binarySearchBlockIndex(uint256 val) public view returns (uint256) {
      uint256[] storage arr = blocks;
      
      uint256 maxlen = totalBlocks();
      
      uint256 len;
      uint256 end = maxlen;
      uint256 begin = 0;
      uint256 mid;
      uint256 v;
      
      while (true) {
        len = end - begin;
        if (len == 0) {
          if (maxlen <= begin)
            return 0;
          else
            return begin;
        }
        
        mid = begin + len / 2;
        v = arr[mid];
        if (val < v)
          end = mid;
        else if (val > v)
          begin = mid+1;
        else
          return mid;
      }
      
      return 0;
    } 
    
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
    
    function _ipfsBaseURI() internal view returns (string memory) {
        return ipfsBaseURI;
    }
    
    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    
    function setIpfsBaseUri(string memory _uri) external onlyOwner {
        require(ipfsLocked == false);
        ipfsBaseURI = _uri;
    }
    
    function lockIpfsMetadata() external onlyOwner {
        require(ipfsLocked == false);
        ipfsLocked = true;
    }
    
    function setMetadataSwitch(uint256 _switch) external onlyOwner {
        if (switchLocked == true) {
          require (_switch > metadataSwitch);
        }
        
        require(_switch >= 1 && _switch <= 3);
        
        metadataSwitch = _switch;
    }
    
    function lockMetadataSwitch() external onlyOwner {
        require(switchLocked == false);
        switchLocked = true;
    }
    
    function setIpfsHash(uint256 traitSummary, string memory hash) external onlyOwnerOrApprovedContract {
        if (ipfsLocked == true) {
          require(bytes(tokenTraitSummaryToIpfsHash[traitSummary]).length == 0);
        }
        require(ipfsLockPerToken[traitSummary] == false);
        
        tokenTraitSummaryToIpfsHash[traitSummary] = hash;
    }
    
    function lockIpfsPerToken(uint256 traitSummary) external onlyOwnerOrApprovedContract {
        require(ipfsLockPerToken[traitSummary] == false);
        ipfsLockPerToken[traitSummary] = true;
    }
    
    function tokenURIComputedName(uint256 tokenId) public view returns (string memory) {   
        uint256 blockNo0 = tokenIdToBirthBlockNumber[tokenId];
        uint256 blockNo1 = blockNo0.add(EVOLUTION_BLOCK_COUNT);
        uint256 blockNo2 = blockNo1.add(EVOLUTION_BLOCK_COUNT);
        uint256 blockNo3 = blockNo2.add(EVOLUTION_BLOCK_COUNT);
        uint256 blockNo4 = blockNo3.add(EVOLUTION_BLOCK_COUNT);
        
        uint256 hash_0 = blockhashHistory[binarySearchBlockIndex(blockNo0)];
        
        uint256 index_breed = (uint256(keccak256(abi.encodePacked(tokenId, hash_0))) % NO_ODDS);
        uint256 index_bg = (uint256(keccak256(abi.encodePacked(tokenId, hash_0, uint8(1)))) % NO_ODDS);
        uint256 index_pattern = (uint256(keccak256(abi.encodePacked(tokenId, blockhashHistory[binarySearchBlockIndex(blockNo1)]))) % NO_ODDS);
        uint256 index_mood = (uint256(keccak256(abi.encodePacked(tokenId, blockhashHistory[binarySearchBlockIndex(blockNo2)]))) % NO_ODDS);
        uint256 index_breath = (uint256(keccak256(abi.encodePacked(tokenId, blockhashHistory[binarySearchBlockIndex(blockNo3)]))) % NO_ODDS);
        uint256 index_horns = (uint256(keccak256(abi.encodePacked(tokenId, blockhashHistory[binarySearchBlockIndex(blockNo4)]))) % NO_ODDS);

        uint256 lastblock = lastBlock();

        if (blockNo4 <= lastblock) {
            return string(abi.encodePacked(
            namesBreed[odds6[index_breed]],
            "-", namesBackground[odds10[index_bg]],
            "-", namesPattern[odds6[index_pattern]],
            "-", namesMood[odds6[index_mood]],
            "-", namesBreath[odds8[index_breath]],
            "-", namesHorns[odds8[index_horns]]
          ));
        } else if (blockNo3 <= lastblock) {
            return string(abi.encodePacked(
            namesBreed[odds6[index_breed]],
            "-", namesBackground[odds10[index_bg]],
            "-", namesPattern[odds6[index_pattern]],
            "-", namesMood[odds6[index_mood]],
            "-", namesBreath[odds8[index_breath]]
          ));
        } else if (blockNo2 <= lastblock) {
            return string(abi.encodePacked(
            namesBreed[odds6[index_breed]],
            "-", namesBackground[odds10[index_bg]],
            "-", namesPattern[odds6[index_pattern]],
            "-", namesMood[odds6[index_mood]]
          ));
        } else if (blockNo1 <= lastblock) {
            return string(abi.encodePacked(
            namesBreed[odds6[index_breed]],
            "-", namesBackground[odds10[index_bg]],
            "-", namesPattern[odds6[index_pattern]]
          ));
        } else {
            return string(abi.encodePacked(
            namesBreed[odds6[index_breed]],
            "-", namesBackground[odds10[index_bg]]
          ));
        }
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        string memory base = _baseURI();
        string memory ipfsBase = _ipfsBaseURI();
        
        string memory computedName = tokenURIComputedName(tokenId);
        string memory ipfsHash = tokenTraitSummaryToIpfsHash[uint256(keccak256(bytes(computedName)))];
        
        if (metadataSwitch == 1) {
            // force computed name
            return string(abi.encodePacked(base, computedName, "/", tokenId.toString()));
        } else if (metadataSwitch == 2) {
            // ipfs hash if available, fallback to computed name
            if (bytes(ipfsHash).length == 0) {
                return string(abi.encodePacked(base, computedName, "/", tokenId.toString()));
            } else {
                return string(abi.encodePacked(ipfsBase, ipfsHash));
            }
        } else if (metadataSwitch == 3) {
            // force ipfs hash
            return string(abi.encodePacked(ipfsBase, ipfsHash));
        }
        
        return "";
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
        tokenIdToBirthBlockNumber[_mintIndex] = block.number - 1;
        _mintIndex++;
      }
      
      if (lastBlock() < block.number - 1) {
        internalRecordBlockhash(block.number - 1);
      }
      
      return initial;
    }
    
    // Award for free
    
    function awardFree(address minter, uint256 count) external onlyOwnerOrApprovedContract returns (uint256) {
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