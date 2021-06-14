/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity  ^0.7.0;

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
    
    function tokensOfOwner(address owner)external view returns(uint[]memory);
        
         function uri(uint  id)external  view returns (string memory);
         function name(uint  id)external  view returns (string memory);

         function symbol(uint  id)external  view returns (string memory);
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
   enum NFT {ERC1155,ERC721}
   enum Order {Martingale,market,limit}
    struct Item {
        address _tokenConntract;
        address payable _owner;
        uint _tokenId;
        Order _orderType;
        NFT _tokenType;
        uint _multiples;
        uint _bidPrice;
      //  uint _askPrice;//using start price as ask price
        uint _curentPrice;
        uint _multiplier;
        uint _startPrie;
        uint _freeTokens;
        uint _balanceTokens;
         uint _auctionStart;
        address _counterParty;
    }
    event NFTReceived(address indexed from, uint indexed tokenId,uint value ,uint timestamp);
    event orderAdded(uint orderType,uint tokenType,address tokenaddress,uint tokeId);
    event buyOrderReceived(uint _auctionId,uint orderType,uint amount, address _bidder);
        event offerReceived(uint _auctionId,uint amount, address _bidder);
        event marketOrderReceived(uint _auctionId,uint amount, address _bidder);
        event acceptBid(uint _auctionId,address owner, uint amount);
        event rejectBid(uint _auctionId,address owner,uint amount);
        event withdrawid(uint _auctionId,address bidder,uint amount);
        event counterOfferReceived(uint _auctionId,uint amount, address _bidder);
         event endingAuction(uint auctionId,address auctioneer, uint tokenId, uint tokenBalance);
                  event proceedsTransferred(uint _auctionId,address auctioneer, uint amount);


     mapping(uint=>Item)public idToAuction ;// id to auction details mapping
    uint public auctionCounter=1; // auction counter
    mapping (uint=>uint)public escrowBalance;// escrow of auction amount
    mapping (address=>uint[]) auctioneerList;// auctioneer adress to auctions
        mapping (address=>uint[]) biddersList;// bidders adress to auctions
uint[]public auctionsList;// array to maintain list of all active auctions
 
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155).interfaceId;
            
    }
    /*is called when ERC1155 is sent to this contract*/
 function  onERC1155Received(address operator,address from,uint256 id,uint256 value,bytes calldata data)override external returns(bytes4){
   uint time= block.timestamp;
    emit NFTReceived(from, id,value,  time);
    return   this.onERC1155Received.selector; //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
 }
 function onERC1155BatchReceived(address operator,address from,int256[] calldata ids,uint256[] calldata values,bytes calldata data)override external returns(bytes4){
     
    return   this.onERC1155Received.selector; //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
 }
       function  viewauctiondata(uint id)public view returns(uint _auctionId,uint _orderType, address _tokenConntract,address _owner,address _counterParty,string memory uri,uint _tokenId,uint _bidPrice,uint _curentPrice,uint _startPrice,uint _freeTokens,uint _balanceToken){
    Item memory  itemData =idToAuction[id];
    string memory uri =IERC1155(itemData._tokenConntract).uri(itemData._tokenId); //"https://ipfs.daonomic.com/ipfs/QmfNnPcmX1rzPym7KuksjRSFy8Dx8Fj1RTnmviyarCs9ez";//""sampleURI";

    return (id, uint(itemData._orderType),itemData._tokenConntract,itemData._owner,itemData._counterParty,uri,itemData._tokenId,itemData._bidPrice, itemData._curentPrice,itemData._startPrie,getfreeTokens(itemData._multiples,itemData._balanceTokens,itemData._freeTokens), itemData._balanceTokens);
}
function getfreeTokens(uint multiples,uint balance,uint free)public view returns (uint){
    // Item memory  itemData =idToAuction[id];
      uint  soldtokens=multiples.sub(balance);
    uint freeTokens= (free>soldtokens)?free-soldtokens:0;
    return freeTokens;
}
    
function viewauctioneerList(address auctioneer) public view returns(uint[] memory){
    return  auctioneerList[auctioneer];
}
function viewBidderList(address bidder) public view returns(uint[] memory){
    return  biddersList[bidder];
    
}
function viewAuctionList() public view returns(uint[] memory){
    return auctionsList;
}
    function removeAuction(uint id) public  returns(bool){
        
        address auctioneer= idToAuction[id]._owner;
        auctioneerList[auctioneer]= removeItem(id,auctioneerList[auctioneer]);
        delete idToAuction[id];
       auctioneerList[auctioneer]=removeItem(id,auctioneerList[auctioneer]);
        auctionsList= removeItem(id,auctionsList);//TODO check logic to remove item from auction
        
    }
    function addOrder(uint tokenType, address tokenConntract,address payable owner,uint tokenId,uint orderType,uint freeTokens,uint  multiples ,uint bidPrice, uint startPrice, uint multiplier,uint duration)public{
                  idToAuction[auctionCounter]._tokenType=NFT(tokenType);

         idToAuction[auctionCounter]._tokenConntract=tokenConntract;
        idToAuction[auctionCounter]._owner=owner;
        idToAuction[auctionCounter]._tokenId =tokenId;
        idToAuction[auctionCounter]._orderType =Order(orderType);
        idToAuction[auctionCounter]._multiples=multiples;
        idToAuction[auctionCounter]._bidPrice=bidPrice;
        //idToAuction[auctionCounter]._askPrice=askPrice;
        idToAuction[auctionCounter]._curentPrice=0;
        idToAuction[auctionCounter]._multiplier= multiplier;
        idToAuction[auctionCounter]._startPrie=startPrice;
        idToAuction[auctionCounter]._freeTokens=freeTokens;
        idToAuction[auctionCounter]._balanceTokens=multiples;
        
        auctioneerList[msg.sender].push(auctionCounter);
        auctionsList.push(auctionCounter);
        auctionCounter=auctionCounter.add(1);
        
        addEscrow(tokenConntract,owner,tokenId,multiples);
             emit orderAdded( orderType, tokenType, tokenConntract, tokenId);

    }
    /*escrow the already approve NFT token to this contract by calling transfer from
    */
    function addEscrow(address tokenConntract,address from,uint tokenId,uint value)public{
        address  to= address(this);
    //    bytes memory  data= bytes(0xf23a6e61); //bytes(0x0);
      IERC1155(tokenConntract).safeTransferFrom(from,to,tokenId,value, '0x0');
    
    }
    /*
    Release the Escrowed NFT to the successfull buyer/bidder */
    function releaseEscrow(uint id,address tokenConntract,address to,uint tokenId,uint value)public{
        address  from= address(this);
    //    bytes memory  data= bytes(0xf23a6e61); //bytes(0x0);
      IERC1155(tokenConntract).safeTransferFrom(from,to,tokenId,value, '0x0');
    idToAuction[id]._balanceTokens=idToAuction[id]._balanceTokens.sub(value);

    
    }
     /* update the purchase at stated price*/
    function _purchase(uint id, uint amount, address buyer)public payable{
        
             Item memory itemData = idToAuction[id];
            require(itemData._startPrie==amount,"amount should be equal to current price");

             escrowBalance[id]= escrowBalance[id].add(amount);
             
       releaseEscrow(id,itemData._tokenConntract,buyer,itemData._tokenId,1);

               emit marketOrderReceived(id, amount, buyer);

    }
    function removeBidder(uint id)public{
 address payable oldBidder =  payable(idToAuction[id]._counterParty);
        uint oldBid=  idToAuction[id]._bidPrice;
        require(escrowBalance[id]>=oldBid, "un known  issues in old Bid escrow");// validate that old bidis properly escrowed
        oldBidder.transfer(oldBid);
      biddersList[oldBidder]= removeItem(id,biddersList[oldBidder]);// remove from bidders list

    }
     /* update the Counter bid
     and return the previous bid*/
    function _counterOffer(uint id, uint amount,address buyer)public payable{
        removeBidder(id);
            // Item memory itemData = idToAuction[id];
             idToAuction[id]._bidPrice=amount;
             idToAuction[id]._counterParty=buyer;
             
             escrowBalance[id]= escrowBalance[id].add(amount);
biddersList[buyer].push(id);
emit counterOfferReceived( id, amount,  buyer);
       
    }
     /* update the first Offer
     and return the previous bid*/
    function _firstOffer(uint id, uint amount,address buyer)public payable{
       
        idToAuction[id]._counterParty=buyer;
            idToAuction[id]._bidPrice=amount;  
             escrowBalance[id]= escrowBalance[id].add(amount);
biddersList[buyer].push(id);
emit offerReceived( id, amount,  buyer);
       
    }
    
    /* update the bid*/
    function _offer(uint id, uint amount,address buyer)public payable{
        if(idToAuction[id]._bidPrice==0){
            _firstOffer(id,amount,buyer);
        }else if(amount>idToAuction[id]._bidPrice) {
            _counterOffer(id,amount,buyer);
            }else{
               revert('Invalid Offer') ;
            }
            
             
        }
    
    function removeItem(uint item, uint[] memory array) public pure returns(uint[] memory){
       

        for (uint i=0;i<array.length-1;i++){
            if(array[i]==item){
              delete  array [i];
            }

            return array;
        }
    }
     /*withdraw the offer*/
     function _withdraw(uint id)public payable{
        
             Item memory itemData = idToAuction[id];
             address payable  buyer= payable(itemData._counterParty);
                 require(msg.sender==buyer,"only token offerer can withdraw the offer");// check only bidder can withdraw

            uint amount=itemData._bidPrice;
            require(escrowBalance[id]>=amount,"Insufficient amount");
                        escrowBalance[id]= escrowBalance[id].sub(amount);// update the escrow balance
 buyer.transfer(amount);
            idToAuction[id]._bidPrice=0; //set bid price to zero again afrer jecting
            idToAuction[id]._counterParty=address(0);
            
               biddersList[buyer]= removeItem(id,biddersList[buyer]);
               
               emit withdrawid( id,buyer, amount);

     }  
     /*reject the offer*/
     function _reject(uint id)public payable{
        
             Item memory itemData = idToAuction[id];
     address tokenowner= itemData._owner;
     require(itemData._bidPrice!=0,"No pending bids received");
    require(msg.sender==tokenowner,"only token owner can accept the offer");// check only owner can reject
             address payable  buyer= payable(itemData._counterParty);
            uint amount=itemData._bidPrice;
            require(escrowBalance[id]>=amount,"Insufficient amount");
            buyer.transfer(amount);// return the  received bid amount.
            escrowBalance[id]= escrowBalance[id].sub(amount);// update the escrow balance
            idToAuction[id]._bidPrice=0; //set bid price to zero again afrer jecting
            idToAuction[id]._counterParty=address(0);// reset counter party to zero
           biddersList[buyer]= removeItem(id,biddersList[buyer]);// remove from bidders list
           
emit rejectBid( id,tokenowner, amount);
     }     
    /*accep the offer*/
     function _accept(uint id)public payable{

             Item memory itemData = idToAuction[id];
    address tokenowner= itemData._owner;
    require(msg.sender==tokenowner,"only token owner can accept the offer");// check only owner can accept
             address buyer= itemData._counterParty;
            uint amount=itemData._bidPrice;
            
       releaseEscrow(id,itemData._tokenConntract,buyer,itemData._tokenId,1);// transfer a single token
    biddersList[buyer]= removeItem(id,biddersList[buyer]);// remove from bidders list
    idToAuction[id]._counterParty= address(0); // reset the  counter party
    idToAuction[id]._bidPrice=0;// reset bid to 0

emit acceptBid( id,tokenowner, amount);
    }
    function _bidAuction(uint id, uint amount,address buyer)public payable{
        require (amount==msg.value, "amount mismatch");
        address bidder= msg.sender;
         Item memory itemData = idToAuction[id];
         require(amount>=itemData._curentPrice,"amount less than current price");
       
       escrowBalance[id]= escrowBalance[id].add(amount);
       updateAuction(id);
       releaseEscrow(id,itemData._tokenConntract,bidder,itemData._tokenId,1);
        
    }
    function buy(uint id, uint amount)public payable{
        require (amount==msg.value, "amount mismatch");
        address bidder= msg.sender;
        Item memory itemData = idToAuction[id];
        
        if(itemData._orderType==Order.Martingale){
            _bidAuction(id,amount,bidder);
        }else if(itemData._orderType==Order.limit){
            _offer(id,amount,bidder);
        }else if(itemData._orderType==Order.market){
            _purchase(id,amount,bidder);
        }else{
           revert("not a valid ordertype");
        }
        emit buyOrderReceived(id,uint(itemData._orderType),amount, bidder);
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
       //  idToAuction[id]._balanceTokens=itemData._balanceTokens.sub(1);
         
         //-
    }
    
    function endAuction(uint id) public{
    
        Item memory itemData= idToAuction[id]; // fetch auction itemData
        require(itemData._owner==msg.sender,"only owner can end auction");// only owner can end auction
        require(itemData._counterParty==address(0),"have a pending bid");// make sure no pending bids
        releaseEscrow(id,itemData._tokenConntract,itemData._owner,itemData._tokenId,itemData._balanceTokens);// return balance 1155 tokens to original owner
        transferProceeds(id);
        removeAuction(id);
        emit  endingAuction( id, itemData._owner, itemData._tokenId,itemData._balanceTokens );
        
    }
    function transferProceeds(uint id) internal{
    Item memory itemData= idToAuction[id]; // fetch auction itemData
    uint amount= escrowBalance[id];//fetch escrowed balance
    address payable owner= itemData._owner;
    
    escrowBalance[id]= escrowBalance[id].sub(amount);
    owner.transfer(amount);
                       emit proceedsTransferred(id,owner, amount);

}
     
    
    

}