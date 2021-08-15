/***
 *
 * 
 *  Project: XXX
 *  Website: XXX
 *  Contract: NFT
 *  
 *  Description: 10,000 unique felines, 10 different breeds, editable names, descriptions, background color, unique items.
 * 
 */
 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./IERC721.sol";


contract KawaiiCatsNFT is Ownable, ERC721, ERC721Enumerable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    event NewCat(uint16 id);
   
    uint16 public constant MAX_SUPPLY = 10000;
    uint256 public NFT_PRICE = 80000000000000000; //0.08 ETH
    uint256 public UPGRADE_PRICE = 100000000000000000000; //100 PURR
    uint256 public NFT_LIMIT_PER_ADDRESS = 5;
    uint32[10] public breedIndex  = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    
    string private _baseTokenURI; 
    address private _tokenAddress;
    address private _additionalContract;

    Cat[] public catArray;
    struct Cat {
        string name;
        string description;
        uint32 breed;
        uint32 readyTime;
        uint32 rarity;
        uint32 background;
        uint32 uniqueItem;
    }

    mapping (uint16 => uint256) public birthday;
   
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_RECEIVER = 0x150b7a02; 
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    address private _owner;
    IERC20 private token;
    
     /**
     * @dev Sets the values for {name}, {symbol} and {baseTokenURI}.
     *      Sets the address of the associated token contract.
     * 
     */
    constructor(string memory name, string memory symbol, string memory baseTokenURI, address TokenAddress) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _tokenAddress = TokenAddress;
       
         // register supported interfaces
        supportsInterface(_INTERFACE_ID_ERC165);
        supportsInterface(_INTERFACE_ID_ERC20);
        supportsInterface(_INTERFACE_ID_ERC721);
        supportsInterface(_INTERFACE_ID_ERC721_RECEIVER);
        supportsInterface(_INTERFACE_ID_ERC721_METADATA);
        supportsInterface(_INTERFACE_ID_ERC721_ENUMERABLE); 
        
        token = IERC20(_tokenAddress);
        _owner = _msgSender();
    }

    /**
     * @dev Returns the baseTokenURI.
     *
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    modifier onlyTokenContract() {
        require(msg.sender == _tokenAddress);
        _;
    }
    
    modifier onlyAdditionalContract() {
        require(msg.sender == _additionalContract);
        _;
    }
    
    /**
     * @dev safeTransferFrom override.
     *
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(balanceOf(to) < NFT_LIMIT_PER_ADDRESS, "Maximum 5 NFTs per address");
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Generates a weighted rarity with values [1-4].
     *
     */
     function _generateRandomRarity(uint _input) private view returns (uint32) {
        uint _randNonce = uint(keccak256(abi.encodePacked(_input))).mod(100);
        _randNonce = _randNonce.add(5);
        uint randRarity = uint(keccak256(abi.encodePacked(block.timestamp + 1 days, msg.sender, _randNonce))).mod(100);
        if (randRarity >= 95) {
            return 1; //legendary - 5% probability
        } else if (randRarity >= 85) {
            return 2; //epic - 10% probability
        } else if (randRarity >= 70) {    
            return 3; //rare - 15% probability
        } else 
            return 4; //common - 70% probability
    }

    /**
     * @dev Generates random information for a new NFT based on its breed.
     *
     */
    function _makeCat(uint32 _breed) private { 
        require(breedIndex[_breed]<1000);
        uint32 _rarity =  _generateRandomRarity(breedIndex[_breed]);
      
        breedIndex[_breed] = breedIndex[_breed].add(1);
        string memory _name = "Name";
        string memory _description = "Description";
        uint32 _background = 1;
        catArray.push(Cat(_name, _description, _breed, uint32(block.timestamp), _rarity, _background, 0));  
        uint16 id = uint16(catArray.length).sub(1);
        birthday[id] = block.timestamp;
        emit NewCat(id);
    }
  
     /**
     * @dev Outputs total cost for creating _numberOfCats NTFs.
     *
     */
    function getPrice(uint256 _numberOfCats) public view returns (uint256) {
        return NFT_PRICE.mul(_numberOfCats); 
    }
    
    
    /**
     * @dev Public NFT creation function. Allows up to 5 NTFs to be created at the same time.
     *
     */ 
    function mintCat(uint256 _numberOfCats, uint32 _breed) public payable {
        require(totalSupply() < MAX_SUPPLY, "Sale has already ended");
        require(_numberOfCats > 0, "Can not mint 0 cats");
        require(_numberOfCats <= 5, "You may not buy more than 5 cats");
        require(totalSupply().add(_numberOfCats) <= MAX_SUPPLY, "Exceeds Maximum supply");
        require(getPrice(_numberOfCats) == msg.value, "Ether value sent is not correct");
        require(balanceOf(msg.sender).add(_numberOfCats) <= NFT_LIMIT_PER_ADDRESS, "Maximum 5 NFTs per address");

        for (uint i = 0; i < _numberOfCats; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            _makeCat(_breed);
        }
    }
    
    /**
     * @dev Outputs the breed type of an NFT.
     *
     */
    function getBreed(uint16 _id) external view returns (uint32) {
        return catArray[_id].breed;
    }
    
    /**
     * @dev Outputs the Name of an NFT.
     *
     */
    function getName(uint16 _id) external view returns (string memory) {
        return catArray[_id].name;    
    }
    
    /**
     * @dev Outputs the creation date of an NFT.
     *
     */
    function getBirthday(uint16 _id) external view returns (uint256) {
        return birthday[_id];    
    }
    
    /**
     * @dev Outputs the Description of an NFT.
     *
     */
    function getDescription(uint16 _id) external view returns (string memory) { 
        return catArray[_id].description;
    }
    
    /**
     * @dev Outputs the rarity of an NFT.
     *
     */
    function getRarity(uint16 _id) external view returns (uint32) {
        return catArray[_id].rarity;
    }
    
    /**
     * @dev Outputs the background of an NFT.
     *
     */
    function getBackground(uint16 _id) external view returns (uint32) {
        return catArray[_id].background;
    }
    
     /**
     * @dev Outputs the uniqueItem of an NFT.
     *
     */
    function getUniqueItem(uint16 _id) external view returns (uint32) {
        return catArray[_id].uniqueItem;
    }
    
   
    /**
     * @dev  Changes the name of an NFT
     */
    function changeName (uint16 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        
        catArray[tokenId].name = newName; 
        token.transferFrom(msg.sender, address(this), UPGRADE_PRICE);
        token.burn(UPGRADE_PRICE);
    }
    
    /**
     * @dev  Changes the description of an NFT
     */
    function changeDescription (uint16 tokenId, string memory newDescription) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        
        catArray[tokenId].description = newDescription; 
        token.transferFrom(msg.sender, address(this), UPGRADE_PRICE);
        token.burn(UPGRADE_PRICE);
    }
    
    /**
     * @dev  Changes the background color of an NFT
     */
    function changeBackground (uint16 tokenId, uint32 newBackground) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        
        catArray[tokenId].background = newBackground; 
        token.transferFrom(msg.sender, address(this), UPGRADE_PRICE);
        token.burn(UPGRADE_PRICE);
    }
    
    /**
     * @dev Allows the assignment of an uniqueItem to an NFT.
     *
     */ 
    function assignUniqueType(uint16 tokenId, uint16 itemId) external onlyAdditionalContract {
        catArray[tokenId].uniqueItem = itemId;
    }  
    
    /**
     * @dev Set _AdditionalContract address
     */
    function setAdditionalContractAddress(address contractAddress) public onlyOwner{
        _additionalContract = contractAddress;
    }
  
    /**
     * @dev See {IERC721}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Withdraws ETH.
     */
    function withdraw() public onlyOwner{
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
   
    
    /**
     * @dev Changes the cost of upgrades.
     */
    function changeUpgradePrice(uint _newPrice) public onlyOwner{
       UPGRADE_PRICE = _newPrice; 
    } 
    
    /**
     * @dev Changes the limit of NFTs per address.
     */
    function changeNFTLimitPerAddress (uint _newLimit) public onlyOwner{
       NFT_LIMIT_PER_ADDRESS = _newLimit; 
    }  
    
}