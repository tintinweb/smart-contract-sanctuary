/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/*
    NFT                 0.07
    NFT+BONUS           0.11
    whitelisted         0.07    =NFT+Bonus      // A tous les whitelisté qui acheteront durant la phase de whitelisting

    10 PEZ per day until January 1st 2032
     5 PEZ               January 1st 2034
     0 PEZ starting on   January 1st 2036
*/
struct TPNS 
{
    string  collection;
    uint256 tokenId;
    address userWallet;
    address caller;
}
//--------------------------------------------------------------------------------
contract    PezNftCollection
{
    IPEZToken   public      PEZ;

    string      internal    collectionName = "DOOLNIES";       // required for PEZ identification
}
//--------------------------------------------------------------------------------
interface   IPEZToken
{
    function    activateNftBonuses(string memory collectionName, uint256 tokenId, address userWallet) external returns(TPNS memory);

    function    transferNftBonus(  string memory collectionName, uint256 tokenId, address from, address to) external returns(bool);
}
//--------------------------------------------------------------------------------
struct TCollaborator 
{
    address     walletAddress;
    uint256     shareValue;
}
//--------------------------------------------------------------------------------
struct TAffiliate 
{
    address     walletAddress;
    uint256     shareValue;
    string      username;
    bool        enabled;    
    uint256     salesCount;      // increment +1 a chaque MINT/bonus amener
}
//--------------------------------------------------------------------------------
struct TTimePhases
{
    string       phase;
    uint256      presalesTimestamp;
    uint256      salesTimestamp;
}
//--------------------------------------------------------------------------------
struct TBonusState
{
    uint256     tokenId;
    bool        isActivated;
}
//--------------------------------------------------------------------------------
interface   IERC165
{
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
//--------------------------------------------------------------------------------
interface   IERC721 is IERC165
{
    event   Transfer(      address indexed from,  address indexed to,       uint256  indexed tokenId);
    event   Approval(      address indexed owner, address indexed approved, uint256  indexed tokenId);
    event   ApprovalForAll(address indexed owner, address indexed operator, bool             approved);

    function balanceOf(        address owner)                                   external view returns (uint256 balance);
    function ownerOf(          uint256 tokenId)                                 external view returns (address owner);
    function safeTransferFrom( address from,     address to, uint256 tokenId)   external;
    function transferFrom(     address from,     address to, uint256 tokenId)   external;
    function approve(          address to,       uint256 tokenId)               external;
    function getApproved(      uint256 tokenId)                                 external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved)                external;
    function isApprovedForAll( address owner,    address operator)              external view returns (bool);
    function safeTransferFrom( address from,     address to, uint256 tokenId, bytes calldata data) external;
}
//--------------------------------------------------------------------------------
interface   IERC721Metadata is IERC721
{
    function name()                     external view returns (string memory);
    function symbol()                   external view returns (string memory);
    function tokenURI(uint256 tokenId)  external view returns (string memory);
}
//--------------------------------------------------------------------------------
interface   IERC721Enumerable is IERC721
{
    function totalSupply()                                      external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index)  external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index)                        external view returns (uint256);
}
//--------------------------------------------------------------------------------
interface   IERC721Receiver
{
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
//--------------------------------------------------------------------------------
library     Strings
{
    bytes16 private constant alphabet = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory)
    {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value==0)       return "0";
   
        uint256 temp = value;
        uint256 digits;
   
        while (temp!=0)
        {
            digits++;
            temp /= 10;
        }
       
        bytes memory buffer = new bytes(digits);
       
        while (value != 0)
        {
            digits        -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value         /= 10;
        }
       
        return string(buffer);
    }
}
//--------------------------------------------------------------------------------
library Address
{
    function isContract(address account) internal view returns (bool)
    {
        uint256 size;
       
        assembly { size := extcodesize(account) }   // solhint-disable-next-line no-inline-assembly
        return size > 0;
    }
}
//--------------------------------------------------------------------------------
abstract contract ReentrancyGuard 
{
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED     = 2;

    uint256 private _status;

    constructor() 
    {       
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant()         // Prevents a contract from calling itself, directly or indirectly.
    {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");    // On the first call to nonReentrant, _notEntered will be true
        _status = _ENTERED;                                                 // Any calls to nonReentrant after this point will fail
        _;
        _status = _NOT_ENTERED;                                             // By storing the original value once again, a refund is triggered (see // https://eips.ethereum.org/EIPS/eip-2200)
    }
}
//--------------------------------------------------------------------------------
abstract contract ERC165 is IERC165
{
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    {
        return (interfaceId == type(IERC165).interfaceId);
    }
}
//--------------------------------------------------------------------------------
abstract contract Context
{
    function _msgSender() internal view virtual returns (address)
    {
        return msg.sender;
    }
}
//--------------------------------------------------------------------------------
abstract contract Ownable is Context
{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
    constructor ()
    {
        address msgSender = _msgSender();
                   _owner = msgSender;
                   
        emit OwnershipTransferred(address(0), msgSender);
    }
   
    function owner() public view virtual returns (address)
    {
        return _owner;
    }
   
    modifier onlyOwner()
    {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
   
    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
       
        emit OwnershipTransferred(_owner, newOwner);
       
        _owner = newOwner;
    }
}
//--------------------------------------------------------------------------------
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable, PezNftCollection
{
    using Address for address;
    using Strings for uint256;

    string private _name;   // Token name
    string private _symbol; // Token symbol
    
    mapping(uint256 => address)                  internal _owners;              // Mapping from token ID to owner address
    mapping(address => uint256)                  internal _balances;            // Mapping owner address to token count
    mapping(uint256 => address)                  private  _tokenApprovals;      // Mapping from token ID to approved address
    mapping(address => mapping(address => bool)) private  _operatorApprovals;   // Mapping from owner to operator approvals

    mapping(uint256 => address)                  internal tokenIdsWallets;

    constructor(string memory name_, string memory symbol_)
    {
        _name   = name_;
        _symbol = symbol_;
    }
   
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool)
    {
        return  interfaceId == type(IERC721).interfaceId         ||
                interfaceId == type(IERC721Metadata).interfaceId ||
                super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256)
    {
        require(owner != address(0), "ERC721: balance query for the zero address");
       
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address)
    {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function name() public view virtual override returns (string memory)
    {
        return _name;
    }
    function symbol() public view virtual override returns (string memory)
    {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
       
        return (bytes(baseURI).length>0) ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory)
    {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override
    {
        address owner = ERC721.ownerOf(tokenId);
   
        require(to!=owner, "ERC721: approval to current owner");
        require(_msgSender()==owner || ERC721.isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address)
    {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
   
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public virtual override
    {
        //----- solhint-disable-next-line max-line-length
       
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override
    {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
       
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual
    {
        _transfer(from, to, tokenId);
   
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool)
    {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
       
        address owner = ERC721.ownerOf(tokenId);
       
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal virtual
    {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual
    {
        _mint(to, tokenId);
   
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal virtual
    {
        require(to != address(0),  "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to]   += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
    function _transfer(address from, address to, uint256 tokenId) internal virtual
    {
        require(ERC721.ownerOf(tokenId)==from,  "ERC721: transfer of token that is not own");
        require(to != address(0),               "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);      // Clear approvals from the previous owner

        _balances[from]  -= 1;
        _balances[to]    += 1;
        _owners[tokenId]  = to;

        emit Transfer(from, to, tokenId);
        
        tokenIdsWallets[tokenId] = to;      // Transferer la propriété a la nouvelle addresse
        
        //----- Gestion de bonus a arreter, car changement de proprietaire
        
        PEZ.transferNftBonus(collectionName, tokenId, from, to);    // Transferer le bonus a un autre, tout en stoppant celui de l'ancien proprio
    }
    function _approve(address to, uint256 tokenId) internal virtual
    {
        _tokenApprovals[tokenId] = to;
   
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    function _checkOnERC721Received(address from,address to,uint256 tokenId,bytes memory _data) private returns (bool)
    {
        if (to.isContract())
        {
            try
                       
                IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
           
            returns (bytes4 retval)
            {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            }
            catch (bytes memory reason)
            {
                if (reason.length==0)
                {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                else
                {
                    assembly { revert(add(32, reason), mload(reason)) }     //// solhint-disable-next-line no-inline-assembly
                }
            }
        }
        else
        {
            return true;
        }
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual
    {
        //
    }
}
//--------------------------------------------------------------------------------
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable
{
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;           // Mapping from owner to list of owned token IDs
    mapping(uint256 => uint256)                     private _ownedTokensIndex;      // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256)                     private _allTokensIndex;        // Mapping from token id to position in the allTokens array

    uint256[] private _allTokens;                                                   // Array with all token ids, used for enumeration

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool)
    {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function totalSupply() public view virtual override returns (uint256)
    {
        return _allTokens.length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256)
    {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
   
        return _ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256)
    {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
   
        return _allTokens[index];
    }

    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override
    {
        super._beforeTokenTransfer(from, to, tokenId);

             if (from == address(0))     _addTokenToAllTokensEnumeration(tokenId);
        else if (from != to)             _removeTokenFromOwnerEnumeration(from, tokenId);
       
             if (to == address(0))       _removeTokenFromAllTokensEnumeration(tokenId);
        else if (to != from)             _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private
    {
        uint256 length = ERC721.balanceOf(to);
   
        _ownedTokens[to][length]   = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private
    {
        _allTokensIndex[tokenId] = _allTokens.length;
   
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private
    {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex)   // When the token to delete is the last token, the swap operation is unnecessary
        {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        
        delete _ownedTokensIndex[tokenId];              // This also deletes the contents at the last position of the array
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private
    {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
contract DLZToken     is  ERC721Enumerable, ReentrancyGuard
{
    using Address for address;
    using Strings for uint256;

    modifier callerIsUser()    { require(tx.origin == msg.sender, "The caller is another contract"); _; }

    event   onWhitelistUserAdded(address wallet, uint256 timestamp);

    //-----

    uint256 public     vDebug=0;
    uint256 public     vDebug2=0;
    
    uint256 public     presalesTimestamp  = 1637080000;
    uint256 public     presalesPrice      = 0.0005 ether;
    uint256 public     bonusPresalesPrice = 0.0005 ether;

    uint256 public     salesTimestamp     = 2000000000;
    uint256 public     salesPrice         = 0.0005 ether;
    uint256 public     bonusSalesPrice    = 0.0008 ether;
    
    uint256 public     bonusOnlyPrice     = 0.0005 ether;

    uint256 public     totalTokens        = 10000;
    uint256 public     leftTokenCount     = totalTokens;
    uint256 public     mintedTokenCount   = 0;
   
    string  public     baseURI = 'https://ipfs.io/ipfs/QmUYGCPStXBoAU2YenpZpKgBPdjLHhwkqDu7AJ5eJyr9Ee/';

    address public     ownerWallet;

    uint256 public     totalReserved = 0;

    uint256 public     totalCollaboratorsSharePercent = 0;
    
    
    mapping(address => uint256) public walletMintCounts;
    mapping(uint256 => uint256) public tokenCreationEpochs;
    mapping(uint256 => bool)    public tokenBonusStates;

    TCollaborator[] public     collaborators;

                //-------
                
    mapping(uint256 => address) public firstOwners;     // Keep track of guys who bought directly the NFT, for future rewards

                //------- Whitelisting
                
    mapping(address => uint256) public whitelistedUsers;
    mapping(address => uint256) public whitelistedTimestamps;

    uint256                     public whitelistedUserCount=0;
    
                //------ Affiliation
                
    mapping(uint256 => TAffiliate) public affiliates;

    event A1();    event A2();    event A3();    event A4();    event A5();    event A6();    event A7();
    event A8();    event A9();    event A10();    event A11();    event A12();    event A13();    event A14();    event A15();
    event MintPrices(uint256 unit, uint256 quantity, uint256 total, uint256 sent);
    event b1(uint256 isTotalPriceOk);
    event b2(uint256 isQuantityOk);
    event b3(uint256 qty, uint256 walletCount, uint256 total);
    event b4(uint256 isMaxPerWalletOk);
    event b5(uint256 isWithBonus);
    event b6(uint256 affHashUsed);
    event b7(string collectionName);
    event b8(uint256 isPEZCallOk);

    event pns(string collectionName, uint256 tokenId, address userWallet, address caller);

    //=============================================================================
    //constructor()   ERC721("The Doolnies", "DLNZ")   // temporary Symbol and title
    constructor()   ERC721("DLN5 Token", "DLN05")   // temporary Symbol and title
    {
        ownerWallet = msg.sender;
        
        setPezContract(0x89435A7EBD9Ae3452903d28Fd0843DCE560B2874);

        setAffiliate(0x2091f35A4A64f6F1419c333d57afD7D152B18272, 'fgs', 500, true); // (address walletAddress, string memory username, uint256 share, bool enabled) public onlyOwner
    }
    //=============================================================================
    function    setBaseTokenURI(string memory newUri)   external onlyOwner                      { baseURI = newUri;             }
    function    baseTokenURI()                          external view returns (string memory)   { return baseURI;               }
    function    _baseURI() internal view virtual override returns (string memory)               { return baseURI;               }
    //=============================================================================
    function    increaseCollectionSize(uint256 extraAmount)          external onlyOwner         
    { 
        totalTokens    += extraAmount;
        leftTokenCount += extraAmount;
    }
    //-----------------------------------------------------------------------------
    function    decreaseCollectionSize(uint256 subAmount)           external onlyOwner         
    { 
        require(subAmount < totalTokens,    "Invalid subAmount for totalTokens");
        require(subAmount < leftTokenCount, "Invalid subAmount for leftTokenCount");

        totalTokens    -= subAmount;
        leftTokenCount -= subAmount;
    }
    //=============================================================================
    function    getTokenIdsByWallet(address walletAddress) external view returns(uint256[] memory)
    {
        require(walletAddress!=address(0), "BlackHole wallet not allowed");
       
        uint256          count  = balanceOf(walletAddress);
        uint256[] memory result = new uint256[](count);
       
        for (uint256 i=0; i<count; i++)
        {
            result[i] = tokenOfOwnerByIndex(walletAddress, i);
        }
       
        return result;
    }
    //=============================================================================
    function    isItTheNftOwner(address walletAddress, uint256 tokenId) external view returns(bool)
    {
        require(walletAddress!=address(0),  "BlackHole wallet not allowed");
        require(tokenId>0,                  "Invalid token ID");
       
        return (tokenIdsWallets[tokenId] == walletAddress);
    }
    //=============================================================================
    function    nftTransfer(address to, uint256 tokenId) external
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
       
        _transfer(msg.sender, to, tokenId);

        require(isERC721ReceivedCheck(msg.sender, to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
    }
    //-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    function    isERC721ReceivedCheck(address from,address to,uint256 tokenId,bytes memory _data) private returns (bool)
    {
        if (to.isContract())
        {
            try
           
                IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
           
            returns (bytes4 retval)
            {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            }
            catch (bytes memory reason)
            {
                if (reason.length==0)
                {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                else
                {
                    assembly { revert(add(32, reason), mload(reason)) }     //// solhint-disable-next-line no-inline-assembly
                }
            }
        }
        else
        {
            return true;
        }
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
    //=============================================================================
    function    addWhitelistUsers(address[] memory wallets)    external onlyOwner
    {
        uint256 n = wallets.length;

        for (uint i=0; i<n; i++)
        {
            address wallet = wallets[i];

            whitelistedUsers[wallet]      = 1;
            whitelistedTimestamps[wallet] = block.timestamp;
        
            emit onWhitelistUserAdded(wallet, block.timestamp);
        }
    }
    //=============================================================================
    function    addWhitelistUser()    external 
    {
        require(block.timestamp < salesTimestamp, "Whitelisting period is over!");
        
        if (whitelistedUsers[msg.sender]!=1)
        {
            whitelistedUserCount++;             // une personne de plus
        }

        whitelistedUsers[msg.sender]      = 1;
        whitelistedTimestamps[msg.sender] = block.timestamp;
        
        
        emit onWhitelistUserAdded(msg.sender, block.timestamp);
    }
    //=============================================================================
    function    getWhitelistedUsersTimestamps(address[] memory wallets)    external view returns(uint256[] memory)
    {
        uint256 count               = wallets.length;
        uint256[] memory timestamps = new uint256[](count);
        
        for(uint256 i; i<count; i++)
        {
            address wallet = wallets[i];
            
            timestamps[i] = (whitelistedUsers[wallet]==1) ? whitelistedTimestamps[wallet] : 0;
        }
        
        return timestamps;
    }
    //=============================================================================
    function    isWhitelistedUser(address userWallet)     external view returns(bool)
    {
        return (whitelistedUsers[userWallet]==1);
    }
    //=============================================================================
    function    isUserInWhitelistMoment(address userWallet) external view returns(bool)
    {
        bool        isOk = false;
        
        if (whitelistedUsers[userWallet]==1)           // Ce gars un whitelisté dans nos registres
        {
            if (block.timestamp>=presalesTimestamp && block.timestamp<salesTimestamp)
            {
                isOk = true;                            // En ce moment, on est bien dans la periode de whitelisting
            }
        }
        
        return isOk;
    }
    //=============================================================================
    function    getWhitelistedUserCount() external view returns(uint256)
    {
        return whitelistedUserCount;
    }
    //=============================================================================
    //=============================================================================
    function    getCurrentPhase() public view returns(string memory)
    {
             if (block.timestamp>=salesTimestamp)       return "sales";
        else if (block.timestamp>=presalesTimestamp)    return "presales";
                                                        return "off";
    }
    //=============================================================================
    function    getPriceForMinting()            view public returns(uint256)
    {
                                                uint256 orderPrice = bonusPresalesPrice;
        if (block.timestamp>=salesTimestamp)            orderPrice = bonusSalesPrice;

        return orderPrice;
    }
    //=============================================================================
    function    getPriceForMintingWithBonus()   view public returns(uint256)
    {
                                                uint256 orderPrice = bonusPresalesPrice;
        if (block.timestamp>=salesTimestamp)            orderPrice = bonusSalesPrice;

        return orderPrice;
    }
    //=============================================================================
    function    getPriceForBonusOnly()   view public returns(uint256)
    {
        return bonusOnlyPrice;
    }
    //=============================================================================
    function    setPrices(uint256 newPresalesPriceInWei, uint256 newSalesPriceInWei)        external onlyOwner
    {
        bonusPresalesPrice = newPresalesPriceInWei;
        bonusSalesPrice    = newSalesPriceInWei;
    }
    //=============================================================================
    function    setPriceForBonunsOnly(uint256 newPriceInWei)   external  onlyOwner
    {
        bonusOnlyPrice = newPriceInWei;
    }
    //=============================================================================
    function    setPresalesTimestamp( uint256 newPresalesTimestamp)  external onlyOwner         
    { 
        presalesTimestamp = newPresalesTimestamp; 
    }
    //=============================================================================
    function    setSalesTimestamp(    uint256 newSalesTimestamp)     external onlyOwner         
    { 
        salesTimestamp    = newSalesTimestamp;    
    }
    //=============================================================================
    function    same(string memory a, string memory b) pure internal returns(bool)
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
    //=============================================================================
    function    reserve(uint256 quantity)                   external onlyOwner
    {
        require(leftTokenCount >= quantity, "Not enough tokens left to reserve anymore");

        address ourWallet = msg.sender;

        totalReserved  += quantity;
        leftTokenCount -= quantity;

        for (uint256 i=0; i<quantity; i++)
        {
            mintedTokenCount++;
           
            _safeMint(ourWallet, mintedTokenCount);
            
            tokenCreationEpochs[mintedTokenCount] = block.timestamp;
            
            //-----
            
            PEZ.activateNftBonuses(collectionName, mintedTokenCount, owner());
        }
    }
    //=============================================================================
    function    buyDailyBonus(uint256 tokenId, uint256 affHash)                 external payable callerIsUser nonReentrant
    {
        require(msg.value==bonusOnlyPrice, "Send exact amount to activate your bonus");
        
                                                bool isAllowed = true;
        if (tokenBonusStates[tokenId]==true)         isAllowed = false;         // Deja un bonus activé!
        
        require(isAllowed==true, "This NFT token already has Daily bonus");
            
        affTransfer(affHash);

        //-----        
        
        tokenBonusStates[tokenId]  = true;            // valider ce token comme etant un token avec bonus

        PEZ.activateNftBonuses(collectionName, tokenId, msg.sender);
    }
    //=============================================================================
    function    mint(uint256 quantity, uint256 affHash)                      external payable callerIsUser nonReentrant
    {
        uint256 unitPrice      = getPriceForMinting();
        bool    isBonusAllowed = false;

        if (whitelistedUsers[msg.sender]==1)                            // Ce gars est un whitelisté dans nos registres?
        {
            if (block.timestamp>=presalesTimestamp && block.timestamp<salesTimestamp)
            {
                isBonusAllowed = true;                                  // En ce moment, on est bien dans la periode de whitelisting
            }
        }
        
        mintEx(quantity, unitPrice, isBonusAllowed, affHash);
    }
    //=============================================================================
    function    mintWithBonus(uint256 quantity, uint256 affHash)           external payable callerIsUser nonReentrant 
    {
        bool    isWhitelisted  = false;

        if (whitelistedUsers[msg.sender]==1)                           // Ce gars un whitelisté dans nos registres
        {
            if (block.timestamp>=presalesTimestamp && block.timestamp<salesTimestamp)
            {
                isWhitelisted = true;                                // En ce moment, on est bien dans la periode de whitelisting
            }
        }
                                    uint256 unitPrice = 0.1 ether;
        if (isWhitelisted==true)            unitPrice = getPriceForMinting();           // Un whitelisté ne paiera pas le plein pot
        else                                unitPrice = getPriceForMintingWithBonus();
        
        mintEx(quantity, unitPrice, true, affHash);
    }
    //=============================================================================
    function    mintEx(uint256 quantity, uint256 unitPrice, bool isWithBonus, uint256 affHash) internal callerIsUser
    {
        require(block.timestamp>=presalesTimestamp, "You can't buy yet");

        uint256 orderTotalPrice = unitPrice * quantity;

        require(msg.value==orderTotalPrice, "Send the exact price amount to mint");
/*
        emit MintPrices(unitPrice, quantity, orderTotalPrice, msg.value);
        emit b1(msg.value==orderTotalPrice ? 1:0); 
        emit b2(leftTokenCount >= quantity ? 1:0);
        uint256 n = walletMintCounts[msg.sender] + quantity;

        emit b3(quantity, walletMintCounts[msg.sender], n);
        
        emit b5(isWithBonus ? 1:0);
        emit b6(affHash);
        emit b7(collectionName);
*/
        //-----
        
        leftTokenCount               -= quantity;
        walletMintCounts[msg.sender] += quantity;

        for (uint256 i=0; i < quantity; i++)
        {
            mintedTokenCount++;
            
            tokenIdsWallets[mintedTokenCount] = msg.sender;

            _safeMint(msg.sender, mintedTokenCount);
            
            tokenCreationEpochs[mintedTokenCount] = block.timestamp;
            firstOwners[mintedTokenCount]         = msg.sender;             // Note this address, it's the original buyer.
            tokenBonusStates[mintedTokenCount]    = isWithBonus;

            //----- Now activate the BONUS of this NFT if it's asked to do so.
        
            if (isWithBonus)
            {/*
                TPNS memory p = PEZ.activateNftBonuses(collectionName, mintedTokenCount, msg.sender);
                
                emit pns(p.collection, p.tokenId, p.userWallet, p.caller);*/

                PEZ.activateNftBonuses(collectionName, mintedTokenCount, msg.sender);
            }
            
        }

        //----- Faut-il payer un affilié
            
        affTransfer(affHash);
    }
    //=============================================================================
    function    setCollaborators(address[] memory wallets, uint256[] memory sharePercents)  external onlyOwner
    {
        require(totalCollaboratorsSharePercent<10000, "Collaborators already listed");
        
        uint256 nWallet = wallets.length;
        uint256 nShares = sharePercents.length;
        
        require(nWallet==nShares, "Wallets & percents array not same size");
        
        for(uint256 i=0; i<nWallet; i++)
        {
            collaborators.push( TCollaborator( wallets[i], sharePercents[i] ) );
        
            totalCollaboratorsSharePercent += sharePercents[i];
        }
    }
    //=============================================================================
    function    calculateCollaboratorShare(uint256 x,uint256 y) internal pure returns (uint256) 
    {
        uint256 a = x / 10000;
        uint256 b = x % 10000;
        uint256 c = y / 10000;
        uint256 d = y % 10000;

        return a * c * 10000 + a * d + b * c + (b * d) / 10000;
    }
    //=============================================================================
    function    withdraw() external
    {
        uint256 totalBalance        = address(this).balance;

        require(totalBalance!=0, "Balance is empty. No sharing possible!!!");

        uint256 nCollaborator  = collaborators.length;
        bool    isCollaborator = false;

        for (uint256 i=0; i<nCollaborator; i++) 
        {
            if (msg.sender==collaborators[i].walletAddress)
            {
                isCollaborator = true;
                break;
            }
        }
        
        require(isCollaborator==true, "You are not a collaborator");

        //----- Let's withdraw to ALL collaborators since one collaborators has asked for a withdraw
        //----- It's the way to always send the right share to each one.
        
        uint256 totalSent           = 0;
        uint256 collaboratorBalance = 0;

        for (uint256 i=0; i<nCollaborator; i++) 
        {
            address collaboratorWallet = collaborators[i].walletAddress;
            
            if (i<(nCollaborator-1))    collaboratorBalance = calculateCollaboratorShare(totalBalance, collaborators[i].shareValue);
            else                        collaboratorBalance = totalBalance - totalSent;     // gerer les decimales residuelles

            payable(collaboratorWallet).transfer(collaboratorBalance);

            totalSent += collaboratorBalance;
        }
    }
    //=============================================================================
    function    setPezContract(address contractAddress) public onlyOwner
    {
        PEZ = IPEZToken(contractAddress);
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
    //=============================================================================
    function    addAvailableTokens(uint256 extraAmount) external onlyOwner
    {
        totalTokens    += extraAmount;
        leftTokenCount += extraAmount;
    }
    //=============================================================================
    function    getAvailableTokens() external view returns (uint256)
    {
        return leftTokenCount;
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
    function    setAffiliate(address walletAddress, string memory username, uint256 share, bool enabled) public onlyOwner
    {
        require(share<=8000, "Affilate share too high");
        
        uint256 affHash = forgeAffHash(username, walletAddress);
        
        affiliates[affHash] = TAffiliate( walletAddress, share, username, enabled, 0);
    }
    //----------------------------------------------------------------------
    function    forgeAffHash(string memory name, address wallet) public pure returns(uint256)
    {
        return uint256
        (
            keccak256
            (
                abi.encodePacked
                (
                    name,
                    wallet
                )
            )
        );
    }
    //----------------------------------------------------------------------
    event AFF0();
    event AFF1(TAffiliate affilate);
    event AFF2(bool isAffiliatedEnabled);
    event AFF3(address affAddr, address caller);
    event AFF4(address affiliateAddress, uint256 commission);
    //=============================================================================
    function    affTransfer(uint256 affHash) internal
    {
        TAffiliate memory affiliate = affiliates[affHash];

        if (affiliate.enabled)
        {
            if (affiliate.walletAddress!=msg.sender)            // don't pay commission on affilate buys!
            {
                uint256 commission = (affiliate.shareValue * msg.value) / 10000;
                    
                payable(affiliate.walletAddress).transfer(commission);       // Directly pay the affiliate

                affiliate.salesCount++;
            }
        }
    }
    //=============================================================================
    function    getAffiliation(uint256[] memory affHashes) view external returns(uint256[] memory)
    {
        uint256          nHash    = affHashes.length;
        uint256[] memory affSales = new uint256[](nHash);

        for (uint256 i=0; i<nHash; i++)
        {
            uint256 hash = affHashes[i];
            
            TAffiliate memory affiliate = affiliates[hash];

            affSales[i] = affiliate.salesCount;
        }

        return affSales;
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
    function    firstOwnerOf(uint256[] memory tokenIds) external view returns(address[] memory)
    {
        uint256 n = tokenIds.length;
        
        address[] memory addressList = new address[](n);
        
        for(uint256 i=0; i<n; i++)
        {
            addressList[i] = firstOwners[ tokenIds[i] ];
        }
        
        return addressList;
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
    function    getTimePhases()  external view returns(TTimePhases memory)
    {
        string memory   phase = getCurrentPhase();

        return TTimePhases( phase, presalesTimestamp, salesTimestamp );            
    }
    //=============================================================================
    function    getNftBonusStates() external view returns(TBonusState[] memory)
    {
        uint256       count  = balanceOf(msg.sender);
        TBonusState[] memory result = new TBonusState[](count);
       
        for (uint256 i=0; i<count; i++)
        {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);

            result[i] = TBonusState(tokenId, tokenBonusStates[tokenId]);
        }
       
        return result;
    }
    //=============================================================================
}