/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

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

contract MartingaleAuction {
   using SafeMath for uint256; 
    struct Item {
        address _tokenConntract;
        address _owner;
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
     mapping(uint=>Item)public idToAuction ;// id to auction details mapping
    uint auctionCounter;
    mapping (uint=>uint)public escrowBalance;
    
    function  viewauctiondata(uint id)public view returns(address _tokenConntract,address _owner,string memory uri,uint _tokenId,uint _multiples,uint _curentPrice,uint _multiplier,uint _startPrie,uint _freeTokens,uint _balanceTokens,uint _auctionStart, bool _isActive){
    Item memory  itemData =idToAuction[id];
    string memory uri="https://ipfs.daonomic.com/ipfs/QmfNnPcmX1rzPym7KuksjRSFy8Dx8Fj1RTnmviyarCs9ez";//""sampleURI";
    
    return (itemData._tokenConntract,itemData._owner,uri,itemData._tokenId,itemData._multiples, itemData._curentPrice,itemData._multiplier,itemData._startPrie,itemData._freeTokens, itemData._balanceTokens,itemData._auctionStart, itemData._isActive);
}
    
    function removeAuction(uint id) public returns(bool){
        delete idToAuction[id];
        auctionCounter.sub(1);
        
    }
    function addAuction( address tokenConntract,address owner,uint tokenId,uint freeTokens,uint  multiples ,  uint startPrice, uint multiplier,uint duration)public{
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
    }
    
    function addEscrow(address tokenConntract)public{
     IERC1155 token = IERC1155(tokenConntract);
    
     
   //  token.safeTransferFrom()
    }
    function bid(uint id, uint amount)public payable{
        require (amount==msg.value, "amount mismatch");
         Item memory itemData = idToAuction[id];
         require(amount>=itemData._curentPrice,"amount less than current price");
       
       escrowBalance[id]= escrowBalance[id].add(amount);
       updateAuction(id);
        
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
    
}