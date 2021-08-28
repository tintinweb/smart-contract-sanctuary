/***
 *
 * 
 *  Project: XXX
 *  Website: XXX
 *  Contract: Unique Items NFTs 
 *  
 *  Description: Unique items.
 * 
 */
 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./IKawaiiCatsNFT.sol"; 

contract KawaiiCatsUniqueItemsNFT is Ownable, ERC721, ERC721Enumerable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    string private _baseTokenURI; 
    address private _nftAddress;
    address private _tokenAddress;
    
    
    uint256 public NFT_ITEM_LIMIT_PER_ADDRESS = 12;
    uint256 public CUSTOM_PRICE = 100000000000000000; //0.1 ETH
    uint256 public queue; 
   
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_RECEIVER = 0x150b7a02; 
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    address private _owner;
    
    uniqueItem[] public uniqueItemArray;
    
    event NewUniqueItem(uint16 _typeId);
    
    struct uniqueItem {
        uint16 typeId; 
        string name;
        string description; 
    }
    
    CustomRequest[] public requestsArray;
    
    struct CustomRequest {
        uint32 picId;
        uint32 timeRequested;
        string description;
        address owner;
        uint16 assignedNFTId;
        uint pricePaid;
        bool done;
    }
    
    mapping (uint16 => uint16) public nftToItem;
    mapping (uint16 => uint16) public itemToNFT;
    
    IKawaiiCatsNFT private nftInterface;
    IERC20 private token;
    
     /**
     * @dev Sets the values for {name}, {symbol} and {baseTokenURI}.
     *      Sets the address of the associated token contract.
     * 
     */
    constructor(string memory name, string memory symbol, string memory baseTokenURI, address nftAddress, address TokenAddress) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _nftAddress = nftAddress;
        _tokenAddress = TokenAddress;
         
         // register supported interfaces
        supportsInterface(_INTERFACE_ID_ERC165);
        supportsInterface(_INTERFACE_ID_ERC20);
        supportsInterface(_INTERFACE_ID_ERC721);
        supportsInterface(_INTERFACE_ID_ERC721_RECEIVER);
        supportsInterface(_INTERFACE_ID_ERC721_METADATA);
        supportsInterface(_INTERFACE_ID_ERC721_ENUMERABLE); 
        
        queue = 0; 
        nftInterface = IKawaiiCatsNFT(_nftAddress);
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
    

    /**
     * @dev safeTransferFrom override.
     *
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
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
     * @dev Public NFT unique items creation function
     *
     */
    function mintItem(string memory _name, string memory _description) public onlyOwner {
        
        uint16 mintIndex = uint16(totalSupply()); 
        
        _safeMint(msg.sender, mintIndex);
        uniqueItemArray.push(uniqueItem(mintIndex,_name,_description));
        nftToItem[50000] = mintIndex;
        itemToNFT[mintIndex] = 50000;
        
        emit NewUniqueItem(mintIndex);
    }
    
    /**
     * @dev Public Assign Item to a NFT. 
     *
     */
    function assignItem(uint16 _itemId, uint16 _nftId) public {
        address owner = ownerOf(_itemId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        uint16 auxNFT;
        uint16 auxItem;
        
      
        auxNFT = itemToNFT[_itemId];
        auxItem = nftToItem[_nftId];
            
        nftToItem[auxNFT] = 50000;
        itemToNFT[auxItem] = 50000; 
             
        nftToItem[_nftId] = _itemId;
        itemToNFT[_itemId] = _nftId;
        
        nftInterface.assignUniqueType(_itemId, _nftId);
      
    }
    
    /**
     * @dev  Changes the name of an NFT Item
     */
    function changeName (uint16 itemId, string memory newName) public onlyOwner {
        uniqueItemArray[itemId].name = newName; 
    }
    
    /**
     * @dev  Changes the description of an NFT Item
     */
    function changeDescription (uint16 itemId, string memory newDescription) public onlyOwner {
        uniqueItemArray[itemId].description = newDescription; 
    } 
    
    /**
     * @dev Changes the limit of NFT items per address.
     */
    function changeNFTItemLimitPerAddress (uint _newLimit) public onlyOwner{
       NFT_ITEM_LIMIT_PER_ADDRESS = _newLimit; 
    } 
    
    /**
     * @dev Get custom price based on queue.
     */
    function getCustomPrice () public view returns (uint) {
       return CUSTOM_PRICE + queue.mul(CUSTOM_PRICE).div(10);
    } 
    
    /**
     * @dev Sign up for a custom outfit
     */
    function requestCustomOutfit (uint32 _picId, uint16 _assignedNFTId, string memory _description) public payable {
        require(nftInterface.balanceOf(msg.sender) > 0, "Must own at least a kawaii cat");
        require(getCustomPrice() == msg.value, "Ether value sent is not correct");
        requestsArray.push(CustomRequest(_picId, uint32(block.timestamp), _description, msg.sender, _assignedNFTId, getCustomPrice(), false)); 
        queue ++;
    } 
    
    /**
     * @dev Fulfill custom order
     *
     */
    function mintAndAssignItem(string memory _name, string memory _description, uint requestsArrayId) public onlyOwner {
        CustomRequest memory req = requestsArray[requestsArrayId];
        require(req.done == false, "Already fulfilled");
        
        uint16 mintIndex = uint16(totalSupply()); 
        _safeMint(req.owner, mintIndex); 
        uniqueItemArray.push(uniqueItem(mintIndex,_name,_description));
        
        uint16 auxItem;
        auxItem = nftToItem[req.assignedNFTId];
        itemToNFT[auxItem] = 50000; 
        
        nftToItem[req.assignedNFTId] = mintIndex;
        itemToNFT[mintIndex] = req.assignedNFTId;
        
        nftInterface.assignUniqueType(mintIndex, req.assignedNFTId);
        requestsArray[requestsArrayId].done = true; 
        if(queue>0)
            queue--;
            
        emit NewUniqueItem(mintIndex);
    }
    
    /**
     * @dev Cancel custom order
     *
     */
    function cancelOrder (uint requestsArrayId) public onlyOwner {
        CustomRequest memory req = requestsArray[requestsArrayId];
        require(req.done == false, "Already fulfilled");
        payable(req.owner).transfer(req.pricePaid); 
        requestsArray[requestsArrayId].done = true; 
        if(queue>0)
            queue--;
    }
    
     /**
     * @dev Changes the cost of a custom outfit. In the event of a high number of orders, 
     *      we reserve the right to increase the price. 
     */
    function changeCustomPrice(uint _newPrice) public onlyOwner{
       CUSTOM_PRICE = _newPrice;  
    } 
    
    /**
     * @dev Withdraws ETH.
     */
    function withdraw() public onlyOwner{
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
   
    
}