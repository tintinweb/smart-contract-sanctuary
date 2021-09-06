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
import "./IPURRtoken.sol";

contract KawaiiCatsUniqueItemsNFT is Ownable, ERC721, ERC721Enumerable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    string private _baseTokenURI; 
    address private _nftAddress;
    address private _tokenAddress;
    
    
    uint256 public CUSTOM_PRICE = 50000000000000000; //0.05 ETH
    uint256 public CUSTOM_ANIM_PRICE = 100000000000000000; //0.1 ETH
    uint256 public CUSTOM_PURR_PRICE = 10000000000000000000000; //10000 PURR
    uint256 public CUSTOM_PURR_LTG_PRICE = 200000000000000000000; //200 PURR 
    uint256 public queue; 
    uint256 public queueAnimation; 
    bool public requestCustomPurr = true;
   
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_RECEIVER = 0x150b7a02; 
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    address private _owner;
    uint16 private neverReach = 65000;
    
    uniqueItem[] public uniqueItemArray;
    
    event NewUniqueItem(uint16 _typeId); 
    
    struct uniqueItem {
        uint16 typeId; 
        string name;
        string description; 
        string setName; 
        bool animated;
        string lt;
        string lg;
    }
    
    CustomRequest[] public requestsArray;
    
    struct CustomRequest {
        string picURL;
        uint32 timeRequested;
        string name;
        string description;
        bool animation;
        address owner;
        uint16 assignedNFTId;
        uint pricePaid;
        bool done;
    }
    
    CustomAnimationRequest[] public requestsAnimationArray;
    
    struct CustomAnimationRequest {
        uint16 itemId;
        string description;
        bool done;
    } 
    
    mapping (uint16 => uint16) public nftToItem;
    mapping (uint16 => uint16) public itemToNFT;
    
    IKawaiiCatsNFT private nftInterface;
    IPURRtoken private token;
    
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
        queueAnimation = 0; 
        nftInterface = IKawaiiCatsNFT(_nftAddress);
        token = IPURRtoken(_tokenAddress);
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
    function mintItem(string memory _name, string memory _description, string memory _setName, bool _animated) public onlyOwner {
        
        uint16 mintIndex = uint16(totalSupply()); 
        
        _safeMint(msg.sender, mintIndex);
        uniqueItemArray.push(uniqueItem(mintIndex,_name,_description,_setName, _animated, "",""));
        nftToItem[neverReach] = mintIndex;
        itemToNFT[mintIndex] = neverReach;
        
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
            
        nftToItem[auxNFT] = neverReach;
        itemToNFT[auxItem] = neverReach; 
             
        nftToItem[_nftId] = _itemId;
        itemToNFT[_itemId] = _nftId;
        
        if (auxNFT!=neverReach)
            nftInterface.assignUniqueType(_nftId, auxNFT, _itemId);
        else     
            nftInterface.assignUniqueType(_nftId, 0, _itemId);
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
     * @dev  Changes the setName of an NFT Item
     */
    function changeSetName (uint16 itemId, string memory newSetName) public onlyOwner {
        uniqueItemArray[itemId].setName = newSetName; 
    }
    
    /**
     * @dev  Changes the bool animation variable
     */
    function changeAnimation (uint16 itemId, bool _animation) public onlyOwner {
        uniqueItemArray[itemId].animated = _animation;  
    }
    
    /**
     * @dev Public change LTG of an cat wearing a costume NFT by onlyOwner. 
     *
     */
    function changeLTG(uint16 _itemId, string memory _lt, string memory _lg) public onlyOwner{
        uniqueItemArray[_itemId].lt = _lt;
        uniqueItemArray[_itemId].lg = _lg;
    }
    
    /**
     * @dev Outputs the Name of an NFT Item.
     *
     */
    function getName(uint16 _id) public view returns (string memory) {
        return uniqueItemArray[_id].name;    
    }
    
    /**
     * @dev Outputs the Description of an NFT Item.
     *
     */
    function getDescription(uint16 _id) public view returns (string memory) { 
        return uniqueItemArray[_id].description;
    }
    
    /**
     * @dev Outputs the setName of an NFT Item.
     *
     */
    function getSetName(uint16 _id) public view returns (string memory) { 
        return uniqueItemArray[_id].setName; 
    }
    
    /**
     * @dev Outputs the animation status of an NFT Item.
     *
     */
    function getAnimationStatus(uint16 _id) public view returns (bool) { 
        return uniqueItemArray[_id].animated; 
    }
    
    /**
     * @dev Outputs the ltg status of an NFT Item.
     *
     */
    function getLTG(uint16 _id) public view returns (string memory, string memory) { 
        return (uniqueItemArray[_id].lt,uniqueItemArray[_id].lg); 
    } 
     
    /**
     * @dev Public setLTG of an cat wearing a costume NFT. 
     *
     */
    function setLTG(uint16 _itemId, string memory _lt, string memory _lg) public {
        address owner = ownerOf(_itemId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        uniqueItemArray[_itemId].lt = _lt;
        uniqueItemArray[_itemId].lg = _lg;
        token.transferFrom(msg.sender, address(this), CUSTOM_PURR_LTG_PRICE);
        token.burn(CUSTOM_PURR_LTG_PRICE); 
    }
    
    /**
     * @dev Get custom price based on queue.
     */
    function getCustomPrice (bool _animation) public view returns (uint) {
        if(_animation==false)
            return CUSTOM_PRICE + queue.mul(CUSTOM_PRICE).div(10);
        else
            return CUSTOM_PRICE + queue.mul(CUSTOM_PRICE).div(10) + CUSTOM_ANIM_PRICE;
    }   
    
    /**
     * @dev Sign up for a custom outfit
     */
    function requestCustomOutfit (string memory _picURL, uint16 _assignedNFTId, string memory _name, string memory _description, bool _animation) public payable {
        require(nftInterface.balanceOf(msg.sender) > 0, "Must own at least a kawaii cat");
        require(getCustomPrice(_animation) == msg.value, "Ether value sent is not correct");
        requestsArray.push(CustomRequest(_picURL, uint32(block.timestamp), _name, _description, _animation, msg.sender, _assignedNFTId, getCustomPrice(_animation), false)); 
        queue ++;
    } 
    
     /**
     * @dev Sign up for a custom outfit with PURR tokens
     */
    function requestCustomOutfitPURR (string memory _picURL, uint16 _assignedNFTId, string memory _name, string memory _description, bool _animation) public {
        require(nftInterface.balanceOf(msg.sender) > 0, "Must own at least a kawaii cat");
        require(requestCustomPurr == true, "Function inactive"); 
        require(token.getBalanceOf(msg.sender) > CUSTOM_PURR_PRICE, "Not enough PURR");
        
        requestsArray.push(CustomRequest(_picURL, uint32(block.timestamp), _name, _description, _animation, msg.sender, _assignedNFTId, 0, false)); 
        token.transferFrom(msg.sender, address(this), CUSTOM_PURR_PRICE);
        token.burn(CUSTOM_PURR_PRICE);
        queue ++;
    } 
    
    /**
     * @dev Fulfill custom order
     *
     */
    function mintAndAssignItem(string memory _name, string memory _description, string memory _setName, bool _animated, uint requestsArrayId) public onlyOwner {
        CustomRequest memory req = requestsArray[requestsArrayId];
        require(req.done == false, "Already fulfilled");
        
        uint16 mintIndex = uint16(totalSupply()); 
        _safeMint(req.owner, mintIndex); 
        uniqueItemArray.push(uniqueItem(mintIndex,_name,_description,_setName, _animated, "",""));
        
        uint16 auxItem;
        auxItem = nftToItem[req.assignedNFTId];
        itemToNFT[auxItem] = neverReach; 
        
        nftToItem[req.assignedNFTId] = mintIndex;
        itemToNFT[mintIndex] = req.assignedNFTId;
        
        nftInterface.assignUniqueType(req.assignedNFTId, 0, mintIndex);
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
        if(req.pricePaid>0)
            payable(req.owner).transfer(req.pricePaid); 
        requestsArray[requestsArrayId].done = true; 
        if(queue>0)
            queue--;
    }
    
     /**
     * @dev Sign up for a custom animation
     */
    function requestCustomAnimation (uint16 _itemId, string memory _description) public payable {
        address owner = ownerOf(_itemId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(CUSTOM_ANIM_PRICE == msg.value, "Ether value sent is not correct");
        requestsAnimationArray.push(CustomAnimationRequest(_itemId, _description, false)); 
        queueAnimation ++;
    } 
    
    /**
     * @dev  Fulfill animation request
     */
    function fulfillAnimationRequest (uint16 requestId) public onlyOwner {
        CustomAnimationRequest memory req = requestsAnimationArray[requestId];
        require(req.done == false, "Already fulfilled");
        
        uniqueItemArray[requestsAnimationArray[requestId].itemId].animated = true; 
        requestsAnimationArray[requestId].done = true; 
        if(queueAnimation>0)
            queueAnimation--;
    }
    
    /**
     * @dev Changes the cost of a custom outfit. In the event of a high number of orders, 
     *      we reserve the right to increase the price. 
     */
    function changeCustomPrice(uint _newPrice) public onlyOwner{
       CUSTOM_PRICE = _newPrice;  
    }
    
     /**
     * @dev Changes the cost of the animation service. In the event of a high number of orders, 
     *      we reserve the right to increase the price. 
     */
    function changeCustomAnimationPrice(uint _newPrice) public onlyOwner{
       CUSTOM_ANIM_PRICE = _newPrice;  
    }
    
    
    /**
     * @dev Changes the cost of a custom outfit. In the event of a high number of orders, 
     *      we reserve the right to increase the price. 
     */
    function changeCustomPricePURR(uint _newPrice) public onlyOwner{
       CUSTOM_PURR_PRICE = _newPrice;  
    } 
    
    /**
     * @dev Changes the cost of setting a ltg for a custom outfit. 
     */
    function changeLTGPricePURR(uint _newPrice) public onlyOwner{
       CUSTOM_PURR_LTG_PRICE = _newPrice;  
    } 
    
    /**
     * @dev Switches requestCustomPurr boolean value.
     */
    function switchRequestCustomPurr() public onlyOwner{
        if (requestCustomPurr == false)
            requestCustomPurr = true;
        else     
            requestCustomPurr = false;
    } 
    
    /**
     * @dev Withdraws ETH.
     */
    function withdraw() public onlyOwner{
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
   
    
}