/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IERC721 /* is ERC165 */ {

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    //function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    //function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    //function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    //function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    
    function Create(address _owner) external returns(uint256);
    function ActivateCard(address _owner, uint256 _cardId) external returns(uint256);
    function TransferCard(uint256 _cardId, address _fromowner, address _newowner) external returns(uint256);
    
    function getOwnerNFTCount(address _owner) external view returns(uint256);
    function getOwnerNFTIDs(address _owner) external view returns(uint256[] memory);
    
    function ViewCardInfo(uint _cardId) external view  returns (uint, address, uint, uint, bool);
    
    //function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
/*
interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
*/

contract TestNFT is IERC721 {
    
    
      // Token name
    string public name = "RPS Access Card";

    // Token symbol
    string private symbol = "RAC";

    // Mapping from token ID to owner address
    mapping(uint256 => address) private owners;

    // Mapping owner address to token count
    mapping(address => uint256) private balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) public tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    
    string constant INVALID_INDEX = "005007";
    
   //dev Array of all NFT IDs.
  uint256[] internal tokens;

  //Mapping from token ID to its index in global tokens array.
  mapping(uint256 => uint256) internal idToIndex;

  //Mapping from owner to list of owned NFT IDs.
  mapping(address => uint256[]) internal ownerToIds;

  //Mapping from NFT ID to its index in the owner tokens list.
  mapping(uint256 => uint256) internal idToOwnerIndex;

    
     struct CardInfo {
        address owner;
        uint energy; //random 0-5
        //uint plus_access; //random 0-5
        uint replication_limit; //random 2-5
        uint replicated_count;
        bool is_activated;
        bool is_sale;
    }

    //mapping (uint256 => address) TokenIdToAddress;
    
    mapping (uint256 => CardInfo) ownerCardInfo;
    uint256 public CardId;
    uint8 energyLimit;
    uint8 accessLimit;
    uint8 replicationLimit;

    constructor(){
        //operator = msg.sender;
        
        CardId = 100000; //starting number
        energyLimit = 4; //0-3
        //accessLimit = 7; //0-6
        replicationLimit = 4; //0-3...+ 2
    }
    

    function Create(address _owner) public override returns(uint256) {
        //require admin = msg.sender
        
        CardId += 1;
        CardInfo storage _card = ownerCardInfo[CardId];
        _card.owner = _owner;
        owners[CardId] = _owner;
        //_card.energy = random(energyLimit) + 2;
        //_card.plus_access = random(accessLimit) + 4;
        //_card.replication_limit = random(replicationLimit) + 2;

        _mint(_owner, CardId);
        addNFToken(_owner, CardId);
        
        return CardId;
    }
    
    function ActivateCard(address _owner, uint256 _cardId) public override returns(uint256) {
        require(ownerOf(_cardId) == _owner, "ERC721: invalid owner");
        
        CardInfo storage _card = ownerCardInfo[_cardId];
        require(!_card.is_activated, "ERC721: card already activated");
        _card.energy = random(energyLimit) + 2;
        _card.replication_limit = random(replicationLimit) + 2;
        _card.is_activated = true;

        return CardId;
    }
    
    function TransferCard(uint256 _cardId, address _fromowner, address _newowner) public  override returns(uint256)  {
        
        require(ownerOf(_cardId) == _fromowner, "ERC721: transfer of token that is not own");
        require(_newowner != address(0), "ERC721: transfer to the zero address");

        //_beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), _cardId);
        
        removeNFToken(_fromowner, _cardId);
        
        addNFToken(_newowner, _cardId);
        
        emit Transfer(_fromowner, _newowner, _cardId);
        
        return _cardId;
    }
    
    //total count of nfts
    function totalSupply()    public view returns (uint256)
    {
        return tokens.length;
    }
    
    /**
   * @dev Returns NFT ID by its index.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex( uint256 _index ) internal view returns (uint256)
  {
    require(_index < tokens.length, INVALID_INDEX);
    return tokens[_index];
  }
  
  /**
   * @dev returns the n-th NFT ID from a list of owner's tokens.
   * @param _owner Token owner's address.
   * @param _index Index number representing n-th token in owner's list of tokens.
   * @return Token id.
   */
      function tokenOfOwnerByIndex( address _owner, uint256 _index) internal view returns(uint256)
      {
        require(_index < ownerToIds[_owner].length, INVALID_INDEX);
        return ownerToIds[_owner][_index];
      }
      
      
      function getOwnerNFTCount( address _owner ) external override virtual view returns (uint256)
    {
        return ownerToIds[_owner].length;
    }
    
      function getOwnerNFTIDs(address _owner ) external override  virtual view returns (uint256[] memory)
    {
        return ownerToIds[_owner];
    }

    
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return balances[_owner];
    }
    

    
    
    function addNFToken( address _to, uint256 _cardId) internal 
  {
    //require(ownerOf[_tokenId] == address(0), NFT_ALREADY_EXISTS);
    balances[_to] += 1;
    owners[_cardId] = _to;
    ownerToIds[_to].push(_cardId);
    idToOwnerIndex[_cardId] = ownerToIds[_to].length - 1;
  }
    
    function removeNFToken( address _from, uint256 _cardId ) internal  virtual
  {
    //require(ownerOf[_tokenId] == _from, "ERC721: transfer of token that is not own");
    delete owners[_cardId];
    balances[_from] -= 1;
    uint256 tokenToRemoveIndex = idToOwnerIndex[_cardId];
    uint256 lastTokenIndex = ownerToIds[_from].length - 1;

    if (lastTokenIndex != tokenToRemoveIndex)
    {
      uint256 lastToken = ownerToIds[_from][lastTokenIndex];
      ownerToIds[_from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    ownerToIds[_from].pop();
  }
  
  function _mint(address to, uint256 _cardId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        //require(!_exists(_cardId), "ERC721: token already minted");

        //_beforeTokenTransfer(address(0), to, tokenId);

        tokens.push(_cardId);
        idToIndex[_cardId] = tokens.length - 1;

        emit Transfer(address(0), to, _cardId);
    }
    
    function _approve(address to, uint256 _cardId) internal virtual {
        tokenApprovals[_cardId] = to;
        
        emit Approval(ownerOf(_cardId), to, _cardId);
    }
    
     function ownerOf(uint256 _cardId) public view virtual override returns (address) {
        address owner =  owners[_cardId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        //require owner
        
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function _exists(uint256 _cardId) internal view virtual returns (bool) {
        return owners[_cardId] != address(0);
    }
    
    
    
    function random(uint8 rndLimit) view internal returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, CardId))) % rndLimit;
        return randomnumber;
    }
    
    
    function ViewCardInfo(uint _cardId) public view virtual override  returns (uint, address, uint, uint, bool) {
        CardInfo storage getInfo = ownerCardInfo[_cardId];
        return (_cardId, getInfo.owner, getInfo.energy, getInfo.replication_limit,  getInfo.is_activated);
    }
    /*
 function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);

    uint256 tokenIndex = idToIndex[_tokenId];
    uint256 lastTokenIndex = tokens.length - 1;
    uint256 lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;

    tokens.pop();
    // This wastes gas if you are burning the last token but saves a little gas if you are not.
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }
*/
}