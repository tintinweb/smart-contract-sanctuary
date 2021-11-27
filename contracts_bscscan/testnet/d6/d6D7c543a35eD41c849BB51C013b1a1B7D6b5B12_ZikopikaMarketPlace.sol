/**
 *Submitted for verification at BscScan.com on 2021-11-27
*/

pragma solidity ^0.8.0;

interface IERC165 {
  
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IMarket{

 function withdrawNFT(uint itemId)external;
function addtoMarket(address nftContract,address owner, uint tokenId,uint price) external;
function buyNFT(uint itemId, address newOwner)payable external;
}

interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

   
    function balanceOf(address owner) external view returns (uint256 balance);

    
    
    function ownerOf(uint256 tokenId) external view returns (address owner);

   
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

   
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

  
    function approve(address to, uint256 tokenId) external;

  
    function getApproved(uint256 tokenId) external view returns (address operator);

   
    function setApprovalForAll(address operator, bool _approved) external;

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

   
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
interface IERC721Receiver {
   
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ZikopikaMarketPlace is IERC721Receiver,IMarket{
    struct Item{
        uint _id;
        address _nftContract;
        address _owner; 
        uint _tokenId;
        uint _currentPrice;
        uint _offer;
    }

     uint public itemCounter;
    mapping(uint=>Item)public idToItem ;

    //events
    event NFT_Listed(address _nftContract, address _owner,uint _tokenId, uint _itemId,uint _price);
event NFT_Purchased(address _nftContract, address _exOwner,address _newOwner,uint indexed _tokenId, uint _itemId,uint _price);
event NFT_Withdraw(address _nftContract, address _exOwner,uint indexed _tokenId, uint _itemId);

/* called by NFT contract to verify that its transferred to contract*/

    function onERC721Received(
        address operator, address from,uint256 tokenId,bytes calldata data) override external virtual returns (bytes4){
//- some logic
        return IERC721Receiver.onERC721Received.selector;
    }
    function addtoMarket(address nftContract,
    address owner, uint tokenId,uint price)override public{
IERC721(nftContract).transferFrom(msg.sender,address(this),tokenId);

        Item memory item =Item(itemCounter,nftContract,owner,tokenId,price,0);
        idToItem[itemCounter]=item;
        
            emit NFT_Listed(nftContract, owner,tokenId, itemCounter++, price);

    }
    function buyNFT(uint itemId, address newOwner)override payable public{
        Item memory item= idToItem[itemId];
   //     require (item._currentPrice==msg.value,"Insufficient amount transferred");

IERC721(item._nftContract).transferFrom(address(this),newOwner,item._tokenId);// transfer tokenId
delete idToItem[itemId];
emit NFT_Purchased(item._nftContract, item._owner,newOwner,item._tokenId, itemId, item._currentPrice);


       
    }
   




       
  
/*withdraw NFT */
function withdrawNFT(uint itemId) override public{
        Item memory item= idToItem[itemId];
        require (item._owner==msg.sender,"Only  owner can withdraw NFT");

IERC721(item._nftContract).transferFrom(address(this),item._owner,item._tokenId);// transfer tokenId
delete idToItem[itemId];
emit NFT_Withdraw(item._nftContract, item._owner, item._tokenId, itemId);


       
    }
 function viewNFT(uint  itemId) view public returns(address _nftConract,uint _tokenId,string memory _tokenUri){
        Item memory item =idToItem[itemId];
        string memory uri=IERC721Metadata(item._nftContract).tokenURI(item._tokenId);
        return(item._nftContract,item._tokenId,uri);
    }

}