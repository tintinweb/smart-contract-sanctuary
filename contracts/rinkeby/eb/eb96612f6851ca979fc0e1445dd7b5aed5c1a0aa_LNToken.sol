/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IERC165
{
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



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



interface IERC721Metadata is IERC721
{
    function name()                     external view returns (string memory);
    function symbol()                   external view returns (string memory);
    function tokenURI(uint256 tokenId)  external view returns (string memory);
}



interface IERC721Enumerable is IERC721
{
    function totalSupply()                                      external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index)  external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index)                        external view returns (uint256);
}



interface IERC721Receiver
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



contract LNToken     is  Ownable
{
    using Address for address;
    using Strings for uint256;

    modifier callerIsUser()
    {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor()
    {
    }
     


    struct THandledNftCollection
    {
        address         contractAddress;
        bool            enabled;
        string          title;
        string          symbol;
        uint256         floorPriceInWei;
        uint256         since;
    }

    mapping(address => THandledNftCollection)       public handledNftCollections;

    mapping(address => uint256)                     public lenderBalances;
    mapping(address => mapping(uint256 => address)) public tokenOwners;

    uint256     minLendingCapital = 0.0001 ether;            // combien doit avoir le lender au minimum sur son capital afin d'etre eligible

    //-------------------
/*
    function    nftLocking(address collectionAddress, uint256 tokenId) external
    {
        require(collectionAddress!=address(0x0), "BlackHole not allowed");

        THandledNftCollection memory collection = handledNftCollections[collectionAddress];

        bool    isEnabled        = collection.enabled;
        
        require(isEnabled==true, "This collection is not handled");
        
        //-----

        address tokenOwner = IERC721(collection.contractAddress).ownerOf(tokenId);

        require(tokenOwner==msg.sender, "You are not the owner of this NFT");

        //-----

        require(address(this).balance>= 0.00001 ether, "Cannot lend you, not enough fund on your side");

                    //--- TODO : faire une gestion qu'on lend au max 20% de la reserve en ETH

        //-----

        IERC721(collection.contractAddress).safeTransferFrom(msg.sender, address(this), tokenId);       // Céder le droit du token au smartcontract

        tokenOwners[ collectionAddress ] [ tokenId ] = msg.sender;                                      // Le smartcontract est le nouveau proprio de ce NFT

        //-----

        payable(msg.sender).transfer(0.00001 ether);
    }*/
   
    function    nftLocking(address collectionAddress, uint256 tokenId) external
    {
        IERC721(collectionAddress).safeTransferFrom(msg.sender, address(this), tokenId);       // Céder le droit du token au smartcontract

        tokenOwners[ collectionAddress ] [ tokenId ] = msg.sender;                                      // Le smartcontract est le nouveau proprio de ce NFT

        payable(msg.sender).transfer(0.00001 ether);
    }

/*
    function    nftUnlocking(address collectionAddress, uint256 tokenId) external payable
    {
        require(msg.value==0.00002 ether, "Send the exact Refund amount");

        bool isNftOwnerCalling = (tokenOwners[ collectionAddress ] [ tokenId ] == msg.sender);

        require(isNftOwnerCalling==true, "Only real owner of the token can Unlock it");

        require(collectionAddress!=address(0x0), "BlackHole not allowed");

        IERC721(collectionAddress).safeTransferFrom(address(this), msg.sender, tokenId);       // Céder le droit du token au smartcontract

        delete tokenOwners[ collectionAddress ] [ tokenId ];      
    }*/

    function    nftUnlocking(address collectionAddress, uint256 tokenId) external payable
    {
        IERC721(collectionAddress).safeTransferFrom(address(this), msg.sender, tokenId);       // Céder le droit du token au smartcontract

        delete tokenOwners[ collectionAddress ] [ tokenId ];      
    }

    function    setNftCollections(address[] memory contractAddresses,bool[] memory enableStates, string[] memory titles, string[] memory symbols, uint256[] memory floorPricesInWei) external
    {
        uint256 l1 = contractAddresses.length;
        uint256 l2 = enableStates.length;
        uint256 l3 = titles.length;
        uint256 l4 = symbols.length;
        uint256 l5 = floorPricesInWei.length;

        require(l1==l2 && l2==l3 && l3==l4 && l4==l5, "Invalid collections information provided");

        //-----

        for(uint256 i=0; i<l1; i++)
        {
            setNftCollectionEx
            (
                contractAddresses[i],
                enableStates[i],
                titles[i],
                symbols[i],
                floorPricesInWei[i]
            );
        }
    }

    function    setNftCollectionEx(address contractAddress, bool isEnabled, string memory title, string memory symbol, uint256 floorPriceInWei) internal
    {
        require(contractAddress!=address(0x0), "Blackhole not allowed");

        handledNftCollections[contractAddress] = THandledNftCollection
        (
            contractAddress,
            isEnabled,
            title,
            symbol,
            floorPriceInWei,
            block.timestamp
        );
    }

    function    addLenderCapital() external payable
    {
        uint256 lenderCurrentBalance = lenderBalances[ msg.sender ];
        uint256 investmentAmount     = msg.value;

        uint256 lenderCapital = lenderCurrentBalance + investmentAmount;

        require(lenderCapital >= minLendingCapital, "Please invest more to be eligible");

        lenderBalances[ msg.sender ] = lenderCapital; 
    }
}