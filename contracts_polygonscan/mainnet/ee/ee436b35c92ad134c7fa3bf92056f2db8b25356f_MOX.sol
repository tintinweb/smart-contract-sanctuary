/***
 *
 * 
 *  Project: XXX
 *  Website: XXX
 *  Contract: NFT
 *  
 *  Description: XXX
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
import "./IMOX.sol";


contract MOX is Ownable, ERC721, ERC721Enumerable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    event NewMOX(uint256 id);
   
    uint32 public indexType;    

    string private _baseTokenURI; 
     
    CARD[] public cardArray;
    struct CARD {
		uint32 typeId;
        uint256 birthdayTime;
        uint32 currentBid;
        uint32 currentAsk;
        uint32 assessedQuality;	
		uint32 redeemed;	
    }

	//mapping by type:
    mapping (uint32 => bool) public activeIndex;
 	mapping (uint32 => uint256) public initialPrice;
	mapping (uint32 => uint32) public initialQuality;
  
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_RECEIVER = 0x150b7a02; 
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    address private _owner;
    IERC20 private token;
    address private _nftContractAddress;
    
     /**
     * @dev Sets the values for {name}, {symbol} and {baseTokenURI}.
     *      Sets the address of the associated token contract.
     * 
     */
    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
		_owner = _msgSender();
		indexType = 0;
		token = IERC20(_nftContractAddress);

         // register supported interfaces
        supportsInterface(_INTERFACE_ID_ERC165);
        supportsInterface(_INTERFACE_ID_ERC20);
        supportsInterface(_INTERFACE_ID_ERC721);
        supportsInterface(_INTERFACE_ID_ERC721_RECEIVER);
        supportsInterface(_INTERFACE_ID_ERC721_METADATA);
        supportsInterface(_INTERFACE_ID_ERC721_ENUMERABLE);        
    }

    /**
     * @dev Returns the baseTokenURI.
     *
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @dev Standard safeTransferFrom with 3 parameters
     *
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
	
	/**
     * @dev Returns initial price mapping for a certain NFT type
     *
     */
	function getPrice(uint32 _typeId) public view returns (uint256) {
        require(_typeId <= indexType, "NFT not available yet");
        return initialPrice[_typeId];
    }
	
	function getInitialQuality(uint32 _typeId) public view returns (uint32) {
        require(_typeId <= indexType, "NFT not available yet");
        return initialQuality[_typeId];
    }

	/**
     * @dev Returns type by id
     *
     */
	function getType(uint256 _id) external view returns (uint32) {
        require(_id < totalSupply(), "NFT not available yet");
		return cardArray[_id].typeId;
    }

	/**
     * @dev Returns birthday by id
     *
     */
	function getBirthday(uint256 _id) external view returns (uint256) {
        require(_id < totalSupply(), "NFT not available yet");
		return cardArray[_id].birthdayTime;
    }
	
	/**
     * @dev Returns current bid by id
     *
     */
    function getBid(uint256 _id) external view returns (uint32) {
		require(_id < totalSupply(), "NFT not available yet");
		return cardArray[_id].currentBid;
    }
	
	/**
     * @dev Returns current ask by id
     *
     */
    function getAsk(uint256 _id) external view returns (uint32) {
		require(_id < totalSupply(), "NFT not available yet");
		return cardArray[_id].currentAsk;
    }
	
	/**
     * @dev Returns quality rating  by id (assessed by Mox team)
     *
     */
	function getQuality(uint256 _id) external view returns (uint32) {
		require(_id < totalSupply(), "NFT not available yet");
		return cardArray[_id].assessedQuality;
    }
    
    /**
     * @dev Checks the status of a NFT (redeemed = true / not redeemed = false).
     */
    function isRedeemed(uint256 _id) external view returns (bool) {
        if(cardArray[_id].redeemed==0)
            return false;
        else    
            return true; 
    } 

    /**
     * @dev Public NFT creation function. Allows the creation based on a type defined by the owner.
     *
     */ 
    function mintNFT(uint32 _type) public payable {
        require(_type <= indexType, "NFT not available yet");
        require(activeIndex[_type] == true, "NFT not available");
		require(getPrice(_type) == msg.value, "Token value is not correct");
        
        
        token.transferFrom(msg.sender, address(this), getPrice(_type));
        token.burn(getPrice(_type));
        
		uint _mintIndex = totalSupply();
        _safeMint(msg.sender, _mintIndex);
		cardArray.push(CARD(_type, uint256(block.timestamp), 0, 0, getInitialQuality(_type), 0));  
        
		uint16 id = uint16(cardArray.length).sub(1);
        emit NewMOX(id);		
    }
	
	/**
     * @dev Public (only owner) type creation function. Allows the creation of a new NFT type.
     *
     */ 
    function createNewType(uint256 _initialPrice, uint32 _initialQuality) public onlyOwner {
        indexType = indexType + 1;
		activeIndex[indexType] = true;
		initialPrice[indexType] = _initialPrice;
		initialQuality[indexType] = _initialQuality;
    }
	
	
    /**
     * @dev Public (only owner) quality edit function. Allows editing the quality of a NFT.
     *
     */ function editQuality(uint256 _id, uint32 _newQuality) public onlyOwner {
		require(_id < totalSupply(), "NFT not available yet");
		cardArray[_id].assessedQuality = _newQuality;
    }

	/**
     * @dev Public (only owner) type deactivation function. Allows the deactivation of a NFT type.
     *
     */ 
    function deactivateType(uint32 _type) public onlyOwner {
        require(_type <= indexType, "NFT not available yet");
		activeIndex[_type] = false;
    }
    
    /**
     * @dev Sets the ask for a NFT, callable only by the owner of the NFT
     *
     */ 
    function setAsk(uint256 _id, uint32 _newAsk) public {
        require(_id < totalSupply(), "NFT not available yet");
        address owner = ownerOf(_id);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
		cardArray[_id].currentAsk = _newAsk;
    }
    
    /**
     * @dev Redeems the physical NFT, callable only by the owner of the NFT
     *
     */ 
    function redeemNFT(uint256 _id) public {
        require(_id < totalSupply(), "NFT not available yet");
        address owner = ownerOf(_id);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(cardArray[_id].redeemed == 0, "NFT already redeemed");
		cardArray[_id].redeemed = 1;
    }
    
    /**
     * @dev Sets the bid for a NFT, callable anyone. The new bid has to be higher then current one
     *
     */ 
    function setBid(uint256 _id, uint32 _newBid) public {
        require(cardArray[_id].currentBid < _newBid, "Place a higher bid");
		cardArray[_id].currentBid = _newBid;
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
     * @dev Withdraws MATIC.
     */
    function withdraw() public onlyOwner{
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
}