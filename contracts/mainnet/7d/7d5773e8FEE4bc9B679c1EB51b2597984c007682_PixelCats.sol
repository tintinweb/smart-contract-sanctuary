// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Ownable.sol";

contract PixelCats is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
   
    event ActionBuy(address indexed _owner, uint256 _id, uint256 count);
    event ActionAward(address indexed _owner, uint256 _id, uint256 count); 
    
    uint256 public constant MAX_NFT_SUPPLY = 7777;
    uint256 public constant MAX_AWARDED_MANUALLY = 220;
    uint256 public constant MAX_BOUGHT = 7557;
    
    uint256 public constant MAX_BUY_COUNT = 15;
    uint256 public constant NFT_PRICE = 0.03 ether;
    
    uint256 public _buyIndex = 0;
    uint256 public _awardIndex = 7560;
    uint256 public _totalAwardedManually = 0;
    
    bool public regularSaleEnabled = false;
    
    string public baseURI = "https://api.pixelcatgang.com/token/";
    string public ipfsBaseURI = "";
    mapping (uint256 => string) public tokenIdToIpfsHash;
    bool public ipfsLocked = false;
    
    modifier onlyApprovedAccount() {
        require(0xee292EAc90CC854bc1Af438015A3b848a4EAe949 == _msgSender() || 0x609F49eFF8110074273fC3E53c4ff275F89b084D == _msgSender() || 0x838B3de2CbeA56D343bF8113b06F13a2Bc96D222 == _msgSender() || owner() == _msgSender(), "Unauthorized account");
        _;
    }
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory __name, string memory __symbol)
        ERC721(__name, __symbol)
    {}
    
    function toggleRegularSale() external onlyOwner {
      regularSaleEnabled = !regularSaleEnabled;
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
    
    function setIpfsHash(uint256 tokenId, string memory hash) external onlyOwner {
        require(ipfsLocked == false);
        tokenIdToIpfsHash[tokenId] = hash;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        
        string memory base = _baseURI();
        string memory ipfsBase = _ipfsBaseURI();
        string memory ipfsHash = tokenIdToIpfsHash[tokenId];
        
        if (bytes(ipfsHash).length == 0) {
            return string(abi.encodePacked(base, tokenId.toString()));
        } else {
            return string(abi.encodePacked(ipfsBase, ipfsHash));
        }
    }
    
    // Minting
            
    function mint(address minter, uint256 count, uint256 initial) private {
      require(minter != address(0), "Minter address error");
      require(count > 0, "Count can't be 0");
      
      uint256 mintIndex = initial;
      for (uint256 i = 0; i < count; i++) {
        require(!_exists(mintIndex), "Token already minted");
        _mint(minter, mintIndex);
        mintIndex++;
      }
    }
    
    // Award for free
    
    function awardFree(address minter, uint256 count) external onlyApprovedAccount {
      require(_awardIndex.add(count) <= MAX_NFT_SUPPLY, "Award limit exceeded");
      
      emit ActionAward(msg.sender, _awardIndex, count);
      
      mint(minter, count, _awardIndex);
      _awardIndex = _awardIndex.add(count);
      _totalAwardedManually = _totalAwardedManually.add(count);
    }
    
    function awardJokerCat(address toAddress) external onlyApprovedAccount {
      require(toAddress != address(0), "toAddress address error");
      require(!_exists(MAX_BOUGHT), "Token already minted");
      
      emit ActionAward(msg.sender, MAX_BOUGHT, 1);
      
      _totalAwardedManually = _totalAwardedManually.add(1);
      _mint(toAddress, MAX_BOUGHT);
    }
    
    function awardBatmanCat(address toAddress) external onlyApprovedAccount {
      require(toAddress != address(0), "toAddress address error");
      require(!_exists(MAX_BOUGHT+1), "Token already minted");
      
      emit ActionAward(msg.sender, MAX_BOUGHT+1, 1);
      
      _totalAwardedManually = _totalAwardedManually.add(1);
      _mint(toAddress, MAX_BOUGHT+1);
    }
    
    function awardLoganPaulCat(address toAddress) external onlyApprovedAccount {
      require(toAddress != address(0), "toAddress error");
      require(!_exists(MAX_BOUGHT+2), "Token already minted");
      
      emit ActionAward(msg.sender, MAX_BOUGHT+2, 1);
      
      _totalAwardedManually = _totalAwardedManually.add(1);
      _mint(toAddress, MAX_BOUGHT+2);
    }
    
    
    // Buy new
    
    function buy(uint256 count) external payable {
      require(regularSaleEnabled, "Sale not live");
      require(_buyIndex.add(count) <= MAX_BOUGHT, "Buy limit exceeded");
      require(count <= MAX_BUY_COUNT, "Count too big");
      require(msg.value == count.mul(NFT_PRICE), "Wrong ETH value");
      
      emit ActionBuy(msg.sender, _buyIndex, count);
      
      mint(msg.sender, count, _buyIndex);
      _buyIndex = _buyIndex.add(count);
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}