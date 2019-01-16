pragma solidity ^0.4.20 ;

contract Manufacturer {
      uint64 private randSeqNum;
      uint64 private prodId;
      address private tempAddr;
     
   struct MedicineDetail{
    string MfgName;   
    string   MfgDate;
    string  prodName;
    string  ExpDate;
   }
   
   struct ShipperDetail{
    string Sender;   
    string   Receiver;
    string  PickUpDate;
    string  ShipperName;
   }
   
   struct RetailerInfor{
       address sellerPubKey;
       string SellerName;
       string SellingDate;
       bool isSold;
   }
   
    mapping (uint64 => MedicineDetail) private Product;
    mapping (address =>mapping(uint64=>bool)) private track;
    mapping (uint64 =>ShipperDetail)private Ship;
    mapping (uint64 => RetailerInfor) private Retailer;
    event ProdCreate(address account, uint64 prodId,string MfgName);
    event ProdTransfer(address From, address To, uint64 id);
    event SellProduct(address seller,string SellerName,uint64 id,bool isSold);
          

        function transferProd(address From) private {
                  track[From][prodId]=false;
                  track[msg.sender][prodId]=true;
               emit ProdTransfer(From, msg.sender,prodId);
                  
        }

    
  function CreateProduct  (string MfgName,string MfgDate ,string prodName,string ExpDate) public{ //for manufacturer
    randSeqNum=uint64(keccak256(block.timestamp));
    prodId=uint64(keccak256(randSeqNum,prodName,msg.sender,MfgDate,ExpDate));
    Product[prodId]=MedicineDetail(MfgName,MfgDate,prodName,ExpDate);
    track[msg.sender][prodId]=true;
    emit ProdCreate(msg.sender,prodId,MfgName);
  } 
  
  function shipMedicine(address From, string SenderName, string Receiver,string PickUpDate, string ShipperName) public { //for shipper
          Ship[prodId]=ShipperDetail(SenderName,Receiver,PickUpDate,ShipperName);   
          transferProd(From);
 
    }
function receivedFrom(address from) public {
    transferProd(from);
}    
    
  function SoldToCustomer(string SellerName,string SellingDate) public{
    Retailer[prodId]=RetailerInfor(msg.sender,SellerName,SellingDate,true)  ;
      track[msg.sender][prodId]=false;
      emit SellProduct(msg.sender,SellerName,prodId,true);
  }  
    
}