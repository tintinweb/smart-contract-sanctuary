/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity >=0.7.0 <0.8.0;

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 /* is ERC165 */ {
   
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);     
    function setApprovalForAll(address _operator, bool _approved) external;
}
interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,address from,
        uint256 id,uint256 value,bytes calldata data)external returns(bytes4);

    function onERC1155BatchReceived(address operator,address from,int256[] calldata ids,uint256[] calldata values,bytes calldata data)external returns(bytes4);
}

/*Safe MathLibrary  for mathematical operations*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MartingaleAuction is IERC1155Receiver {
   using SafeMath for uint256; 
    struct Item {
        address _tokenConntract;
        address payable _owner;
        uint _tokenId;
        uint _multiples;
        uint _curentPrice;
        uint _multiplier;
        uint _startPrie;
        uint _freeTokens;
        uint _balanceTokens;
        uint _auctionStart;
        bool _isActive;
    }
    event NFTReceived(address indexed from, uint indexed tokenId,uint value ,uint timestamp);
     mapping(uint=>Item)public idToAuction ;// id to auction details mapping
    uint public auctionCounter; // auction counter
    mapping (uint=>uint)public escrowBalance;// escrow of auction amount
    
 
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155).interfaceId;
            
    }
 function  onERC1155Received(address operator,address from,uint256 id,uint256 value,bytes calldata data)override external returns(bytes4){
   uint time= block.timestamp;
    emit NFTReceived(from, id,value,  time);
    return   this.onERC1155Received.selector; //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
 }
 function onERC1155BatchReceived(address operator,address from,int256[] calldata ids,uint256[] calldata values,bytes calldata data)override external returns(bytes4){
     
    return   this.onERC1155Received.selector; //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
 }
       function  viewauctiondata(uint id)public view returns(address _tokenConntract,address _owner,string memory uri,uint _tokenId,uint _multiples,uint _curentPrice,uint _multiplier,uint _startPrie,uint _freeTokens,uint _balanceTokens,uint _auctionStart, bool _isActive){
    Item memory  itemData =idToAuction[id];
    string memory uri="https://ipfs.daonomic.com/ipfs/QmfNnPcmX1rzPym7KuksjRSFy8Dx8Fj1RTnmviyarCs9ez";//""sampleURI";
    
    return (itemData._tokenConntract,itemData._owner,uri,itemData._tokenId,itemData._multiples, itemData._curentPrice,itemData._multiplier,itemData._startPrie,itemData._freeTokens, itemData._balanceTokens,itemData._auctionStart, itemData._isActive);
}
    function removeAuction(uint id) public returns(bool){
        delete idToAuction[id];
        auctionCounter.sub(1);
        
    }
    function addAuction( address tokenConntract,address payable owner,uint tokenId,uint freeTokens,uint  multiples ,  uint startPrice, uint multiplier,uint duration)public{
         idToAuction[auctionCounter]._tokenConntract=tokenConntract;
        idToAuction[auctionCounter]._owner=owner;
        idToAuction[auctionCounter]._tokenId =tokenId;
        idToAuction[auctionCounter]._multiples=multiples;
        idToAuction[auctionCounter]._curentPrice=0;
        idToAuction[auctionCounter]._multiplier= multiplier;
        idToAuction[auctionCounter]._startPrie=startPrice;
        idToAuction[auctionCounter]._freeTokens=freeTokens;
        idToAuction[auctionCounter]._balanceTokens=multiples;
        idToAuction[auctionCounter]._auctionStart= block.timestamp;
        idToAuction[auctionCounter]._isActive=true;
        auctionCounter++;
        
      //  addEscrow(tokenConntract,owner,tokenId,multiples);
    }
    
    function addEscrow(address tokenConntract,address from,uint tokenId,uint value)public{
        address  to= address(this);
    //    bytes memory  data= bytes(0xf23a6e61); //bytes(0x0);
      IERC1155(tokenConntract).safeTransferFrom(from,to,tokenId,value, '0x0');
    
     
    }
    function releaseEscrow(address tokenConntract,address to,uint tokenId,uint value)public{
        address  from= address(this);
    //    bytes memory  data= bytes(0xf23a6e61); //bytes(0x0);
      IERC1155(tokenConntract).safeTransferFrom(from,to,tokenId,value, '0x0');
    
    }
    function bid(uint id, uint amount)public payable{
        require (amount==msg.value, "amount mismatch");
        address bidder= msg.sender;
         Item memory itemData = idToAuction[id];
         require(amount>=itemData._curentPrice,"amount less than current price");
       
       escrowBalance[id]= escrowBalance[id].add(amount);
       updateAuction(id);
      // releaseEscrow(itemData._tokenConntract,bidder,itemData._tokenId,1);
        
    }
    function updateAuction(uint id )internal{
        uint  newprice=0;
         Item memory itemData= idToAuction[id];
           uint currenttoken = itemData._multiples - itemData._balanceTokens;
           if(currenttoken<itemData._freeTokens){
              // newprice=0;//do nothing already zero
           }else if(currenttoken==itemData._freeTokens){
               newprice= itemData._startPrie; /* set the price to start price if it reaches the free token limit */
           }else{
         newprice=itemData._curentPrice *itemData._multiplier;
         }
         idToAuction[id]._curentPrice=newprice;
         idToAuction[id]._balanceTokens=itemData._balanceTokens.sub(1);
         
         
    }
    function endAuction(uint id) public{
        Item memory itemData= idToAuction[id]; // fetch auction itemData
      //  releaseEscrow(itemData._tokenConntract,itemData._owner,itemData._tokenId,itemData._balanceTokens);// return balance tokens to original owner
        
    }
    function transferProceeds(uint id) internal{
    Item memory itemData= idToAuction[id]; // fetch auction itemData
    uint amount= escrowBalance[id];//fetch escrowed balance
    address payable owner= itemData._owner;
    
    escrowBalance[id]= escrowBalance[id].add(amount);
    
}
     
    
    

}