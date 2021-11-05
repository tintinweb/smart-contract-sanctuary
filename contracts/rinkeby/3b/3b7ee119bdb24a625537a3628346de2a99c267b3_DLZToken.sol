/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
    NFT                 0.07
    NFT+STAKE           0.11
    whitelisted         0.07    +STAKING        // 3000 PREMIERS 
*/



/// TO-DO
///         Ajouter une gestion de STAKING au prix sans staking a tous les whitelisté.
///         ex: prix sans staking : 0.06 ETH
///                  avec staking : 0.10 ETH
///
///             si le gars est whitelisté, on le fait acheté a 0.06 ETH tout en lui donnant du staking



/*
    1 PEZ/2H    =>  12 PEZ/day/nft  pendant 12 ans
                    6 PEZ/                  6 ans
                    3 PEZ                   3
                    1.5 PEZ                 2 ans
                    1 PEZ                   1 ans
                    0.5 PEZ                 

    6 years     =>  12 PEZ/day
    4 years     =>  8
    3 years     =>  6
    2 years     =>  4
    1 year      =>  2
    inifite     =>  1 
*/



struct TNftReward
{
    uint256     tokenId;
    uint256     reward;
}

interface IPEZToken
{
    function    nftStake(         string memory collectionName, uint256 tokenId)            external returns(bool);
    function    claimNftRewards(  string memory collectionName, uint256[] memory tokenIds)  external view returns(TNftReward[] memory rewards);
    function    disableNftStaking(string memory collectionName, uint256 tokenId)            external;
}
//--------------------------------------------------------------------------------
struct P2EDoolny
{
    uint32      health;
    uint32      defense;
    uint32      attack;
    uint32      power1Type;
    uint32      power2Type;
    uint32      power1Level;
    uint32      power2Level;
    uint32      power1Xp;
    uint32      power2Xp;
    uint32      squidAttackLevel;
    uint32      squidDefenseLevel;
    uint32      transDetectionLevel;
    uint32      gatewayLevel;
}
//--------------------------------------------------------------------------------
interface IBEP20 
{
    function balanceOf(   address account) external view returns (uint256);
    function transfer(    address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
//--------------------------------------------------------------------------------
interface IERC165
{
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
//--------------------------------------------------------------------------------
interface IERC721 is IERC165
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
interface IERC721Metadata is IERC721
{
    function name()                     external view returns (string memory);
    function symbol()                   external view returns (string memory);
    function tokenURI(uint256 tokenId)  external view returns (string memory);
}
//--------------------------------------------------------------------------------
interface IERC721Enumerable is IERC721
{
    function totalSupply()                                      external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index)  external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index)                        external view returns (uint256);
}
//--------------------------------------------------------------------------------
interface IERC721Receiver
{
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
//--------------------------------------------------------------------------------
library Strings
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
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable
{
    using Address for address;
    using Strings for uint256;

    string private _name;   // Token name
    string private _symbol; // Token symbol
    
    address private _pezContractAddress;     // Pour la gestion de stop du staking apres un transfert

    mapping(uint256 => address)                  internal _owners;              // Mapping from token ID to owner address
    mapping(address => uint256)                  internal _balances;            // Mapping owner address to token count
    mapping(uint256 => address)                  private  _tokenApprovals;      // Mapping from token ID to approved address
    mapping(address => mapping(address => bool)) private  _operatorApprovals;   // Mapping from owner to operator approvals

    constructor(string memory name_, string memory symbol_)
    {
        _name   = name_;
        _symbol = symbol_;
    }
   
    function initStakeContract(address ThePezContractAddress) external
    {
        _pezContractAddress = ThePezContractAddress;
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

        _balances[from] -= 1;
        _balances[to]   += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
        
        //----- Gestion de staking a arreter, car changement de proprietaire
        
        IPEZToken(_pezContractAddress).disableNftStaking("DOOLNIES", tokenId);
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
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
//--------------------------------------------------------------------------------
contract DLZToken     is  ERC721Enumerable
{
    using Address for address;
    using Strings for uint256;

    modifier callerIsUser()
    {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    event   onWidthdrawal(address from, address to, uint256 amount);
    event   onMaxMintPerWallet(uint256 lastMaxCount, uint256 newMaxCount);
   
    uint256 private     presalesTimestamp  = 1634482800;
    uint256 private     presalesPrice      = 0.0001 ether;
    uint256 private     stakePresalesPrice = 0.0001 ether;

    uint256 private     salesTimestamp     = 1634482800;
    uint256 private     salesPrice         = 0.00005 ether;
    uint256 private     stakeSalesPrice    = 0.00005 ether;

    uint256 private     totalTokens        = 10000;
    uint256 private     leftTokenCount     = totalTokens;
    uint256 private     mintedTokenCount   = 0;
    uint256 private     maxMintPerWallet   = 20;
   
    string  private     baseURI = '';       // FOR SECURITY REASON THIS WILL BE SET LATER

    address private     ownerWallet;

    uint256 private     totalReserved = 0;

    uint256 private     collaborators100Percent        = 10000;
    uint256 private     totalCollaboratorsSharePercent = 0;
    
    address private     pezContractAddress = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    struct TCollaborator 
    {
        address     walletAddress;
        uint256     shareValue;
    }
    
    mapping(address => uint256) private walletMintCounts;
    mapping(address => uint256) private walletMintedTokenIds;
    mapping(uint256 => uint256) private tokenCreationEpochs;

    TCollaborator[] private     collaborators;
    P2EDoolny[]     private     doolnyProfiles;

                //------- Whitelisting
                
    uint256 private     mintingMode = 2;        // 1: Raffle   2: Presale(whitelist)   3: PublicSale   0: disabled 
    
    mapping(address => uint256) private whitelistingUsers;
    mapping(address => uint256) private whitelistingTimestamps;
    

    //=============================================================================
    constructor()   ERC721("DL01 Token", "DL01")   // temporary Symbol and title
    {
        ownerWallet = msg.sender;
    }
    //=============================================================================
    function    setBaseTokenURI(string memory newUri)   external onlyOwner                      { baseURI = newUri;             }
    function    baseTokenURI()                          external view returns (string memory)   { return baseURI;               }
    function    _baseURI() internal view virtual override returns (string memory)               { return baseURI;               }
    //=============================================================================
    function    addExtraTokens(  uint256 extraAmount)           external onlyOwner              { totalTokens      += extraAmount;          }
    function    setPresalesDate( uint256 newPresalesTimestamp)  external onlyOwner              { presalesTimestamp = newPresalesTimestamp; }
    function    setSalesDate(    uint256 newSalesTimestamp)     external onlyOwner              { salesTimestamp    = newSalesTimestamp; }
    function    setPresalesPrice(uint256 newPresalesPrice)      external onlyOwner              { presalesPrice     = newPresalesPrice;    }
    function    setSalesPrice(   uint256 newSalesPrice)         external onlyOwner              { salesPrice        = newSalesPrice;    }
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
    function    isWalletHasNftTokenId(address walletAddress, uint256 tokenId) external view returns(bool isTokenFound)
    {
        require(walletAddress!=address(0),  "BlackHole wallet not allowed");
        require(tokenId>0,                  "Invalid token ID");
       
        uint256          count  = balanceOf(walletAddress);

        for (uint256 i=0; i<count; i++)
        {
            uint256 id = tokenOfOwnerByIndex(walletAddress, i);
            
            if (id==tokenId)
            {
                return true;
            }
        }
       
        return false;
    }
    //=============================================================================
    function nftTransfer(address to, uint256 tokenId) external
    {
        address fromAddr = _msgSender();

        require(_isApprovedOrOwner(fromAddr, tokenId), "ERC721: transfer caller is not owner nor approved");
       
        _transfer(fromAddr, to, tokenId);

        require(isERC721ReceivedCheck(fromAddr, to, tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
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
    function    addWhitelistUser(address userWallet) external //returns(bool)
    {
        require(mintingMode<=2, "The Presale is finished. Can't add you!");
        
        whitelistingUsers[userWallet]      = 1;
        whitelistingTimestamps[userWallet] = block.timestamp;
        
        //return true;
    }
    //=============================================================================
    function    getMintingMode() external view returns(uint256)
    {
        return mintingMode;     // 1: Raffle   2: Presale(whitelist)   3: PublicSale   0: disabled 
    }
    //=============================================================================
    function    setMintingMode(uint256 newMode) external //returns(bool)        // 1: Raffle   2: Presale(whitelist)   3: PublicSale   0: disabled 
    {
        require(newMode!=mintingMode && newMode<10);
        
        mintingMode = newMode;
        
        //return true;
    }
    //=============================================================================
    function    setmaxMintPerWallet(uint256 newMaxCount) external //returns(bool)
    {
        uint256 lastMaxCount = maxMintPerWallet;
       
        maxMintPerWallet = newMaxCount;
       
        emit onMaxMintPerWallet(lastMaxCount, maxMintPerWallet);
        
        //return true;
    }
    //=============================================================================
    function    reserve(uint256 quantity)  external onlyOwner
    {
        require(leftTokenCount >= quantity, "Not enough tokens left to reserve anymore");

        address us = msg.sender;

        totalReserved  += quantity;
        leftTokenCount -= quantity;

        for (uint256 i=0; i<quantity; i++)
        {
            mintedTokenCount++;
           
            _mint(us, mintedTokenCount);
            
            tokenCreationEpochs[mintedTokenCount] = block.timestamp;
        }
    }
    //=============================================================================
    function    mint(uint256 quantity)              external payable callerIsUser
    {
        uint256 orderPrice = calculateMintingOrderPrice(quantity, 1);       // mode: 1=Simple_MINT  2=MINT+STAKING
        
        mintEx(quantity, orderPrice, false);
    }
    //=============================================================================
    function    mintWithStaking(uint256 quantity)   external payable callerIsUser
    {
        uint256 orderPrice = calculateMintingOrderPrice(quantity, 2);       // mode: 1=Simple_MINT  2=MINT+STAKING
        
        mintEx(quantity, orderPrice, true);
    }
    //=============================================================================
    function    calculateMintingOrderPrice(uint256 quantity, uint256 mode) internal returns(uint256)
    {
        uint256     orderPrice;
        
        if (mintingMode==2)             // on est dans la phase de WHITELIST 
        {
            require(block.timestamp>=presalesTimestamp, "PreSale will open soon. Stay tuned");
            
            if (block.timestamp>=salesTimestamp)
            {
                mintingMode=3;          // on est plus en mode PRESALE, mais en PUBLIC SALE
            }
            else
            {
                uint256 userWhitelistMode = whitelistingUsers[msg.sender];
            
                require(userWhitelistMode!=0, "You're not a whitelisted user");
    
                if (mode==1)    orderPrice = presalesPrice      * quantity;
                else            orderPrice = stakePresalesPrice * quantity;
            }
        }
        
        if (mintingMode>2)
        {
            require(block.timestamp>=salesTimestamp,    "Sale will open soon. Stay tuned");
            
            if (mode==1)    orderPrice = salesPrice      * quantity;
            else            orderPrice = stakeSalesPrice * quantity;
        }

        require(msg.value==orderPrice,  "Send exact Amount to claim NFT(s)!");

        return orderPrice;
    }
    //=============================================================================
    function    mintEx(uint256 quantity, uint256 buyPrice, bool isWithStaking) internal callerIsUser
    {
        require(msg.value     == buyPrice*quantity, "Send exact Amount to claim your Nfts");
        require(leftTokenCount>= quantity,          "No tokens left to be claimed");

        uint256 n = walletMintCounts[msg.sender] + quantity;
        
        require(n<maxMintPerWallet,                 "You have reached your minting limit");

        leftTokenCount -= quantity;

        for (uint256 i=0; i < quantity; i++)
        {
            mintedTokenCount++;

            _mint(msg.sender, mintedTokenCount);
            
            tokenCreationEpochs[mintedTokenCount] = block.timestamp;

            //----- Now start the staking of this NFT if it's asked to do so.
        
            if (isWithStaking)
            {
                IPEZToken(pezContractAddress).nftStake("DOOLNIES", mintedTokenCount);
            }
            
            //----- creation du P2E profile
            
            //doolnyProfiles.push(generateDoolnyProfile());
            P2EDoolny memory  profile;
        
            profile.health              = rand(4000, 6500);
            profile.defense             = rand(1000, 1900);
            profile.attack              = rand(1000, 1900);
            profile.power1Type          = rand(1,4);
            profile.power2Type          = rand(5,7);
            profile.power1Level         = rand(4000, 6500);
            profile.power2Level         = rand(4000, 6500);
            profile.power1Xp            = rand(4000, 6500);
            profile.power2Xp            = rand(4000, 6500);
            profile.squidAttackLevel    = rand(4000, 6500);
            profile.squidDefenseLevel   = rand(4000, 6500);
            profile.transDetectionLevel = rand(6000, 9000);
            profile.gatewayLevel        = rand(4000, 9500);

            doolnyProfiles[mintedTokenCount] = profile;
        }
    }
    //=============================================================================
    function setCollaborators(address[] memory wallets, uint256[] memory sharePercents)  external onlyOwner
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
    function withdraw() external onlyOwner 
    {
        uint256 totalBalance        = address(this).balance;
        uint256 totalSent           = 0;
        uint256 collaboratorBalance = 0;
        uint256 nCollaborator       = collaborators.length;

        for (uint256 i=0; i<nCollaborator; i++) 
        {
            address collaboratorWallet = collaborators[i].walletAddress;
            
            if (i<(nCollaborator-1))    collaboratorBalance = mulScale(totalBalance, collaborators[i].shareValue);
            else                        collaboratorBalance = totalBalance - totalSent; // gerer les decimales residuelles

            payable(collaboratorWallet).transfer(collaboratorBalance);

            totalSent += collaboratorBalance;
        }
    }/*
    //=============================================================================
    function withdrawToken(address token) external onlyOwner        // withdraw a BINANCE BEP20 token
    {
        uint256 totalBalance        = IBEP20(token).balanceOf(address(this));
        uint256 totalSent           = 0;
        uint256 collaboratorBalance = 0;
        uint256 nCollaborator       = collaborators.length;

        for (uint256 i=0; i<nCollaborator; i++) 
        {
            address collaboratorWallet = collaborators[i].walletAddress;
            
            if (i<(nCollaborator-1))    collaboratorBalance = mulScale(totalBalance, collaborators[i].shareValue);
            else                        collaboratorBalance = totalBalance - totalSent; // gerer les decimales residuelles

            IBEP20(token).transfer(collaboratorWallet, collaboratorBalance);

            totalSent += collaboratorBalance;
        }
    }*/
    //=============================================================================
    function mulScale(uint256 x,uint256 y) internal pure returns (uint256) 
    {
        uint256 a = x / 10000;
        uint256 b = x % 10000;
        uint256 c = y / 10000;
        uint256 d = y % 10000;

        return a * c * 10000 + a * d + b * c + (b * d) / 10000;
    }
    //=============================================================================
    function    setPezContract(address contractAddress) external onlyOwner
    {
        pezContractAddress = contractAddress;
    }
    //=============================================================================
    function    getDoolnyInfo(uint256 tokenId) external view returns (P2EDoolny memory)
    {
        require(tokenId>0,                "Invalid doolny id");
        require(tokenId>mintedTokenCount, "Invalid doolny ID (too high)");
        
        return doolnyProfiles[tokenId];
    }
    //=============================================================================
    function    generateDoolnyProfile() external view returns (P2EDoolny memory)
    {
        P2EDoolny memory  profile;
        
        profile.health              = rand(4000, 6500);
        profile.defense             = rand(1000, 1900);
        profile.attack              = rand(1000, 1900);
        profile.power1Type          = rand(1,4);
        profile.power2Type          = rand(5,7);
        profile.power1Level         = rand(4000, 6500);
        profile.power2Level         = rand(4000, 6500);
        profile.power1Xp            = rand(4000, 6500);
        profile.power2Xp            = rand(4000, 6500);
        profile.squidAttackLevel    = rand(4000, 6500);
        profile.squidDefenseLevel   = rand(4000, 6500);
        profile.transDetectionLevel = rand(6000, 9000);
        profile.gatewayLevel        = rand(4000, 9500);
        
        return profile;
    }
    //=============================================================================
    function    rand(uint32 from, uint32 to) internal view returns(uint32)
    {
        uint32          modulo = to   - from;
        uint32          minVal = from;
        
        if (to<from)    
        {
            modulo = from - to;
            minVal = to;
        }
        
        return minVal + uint32
        (
            uint256(keccak256(abi.encodePacked
            (
                block.timestamp, 
                block.difficulty
            ))
        )
        %
        modulo);
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
}