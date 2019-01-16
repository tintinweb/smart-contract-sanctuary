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
    event ProdCreate(int createEvent,uint64 prodId,address account,string MfgName);
    event ProdTransfer(int shipEvent,uint64 prodId,address From, address To );
    event SellProduct(int sellEvent,uint64 prodId,address seller,string SellerName);
          

        function transferProd(address From) private {
                  track[From][prodId]=false;
                  track[msg.sender][prodId]=true;
               emit ProdTransfer(1,prodId,From, msg.sender);
                  
        }

    
  function CreateProduct  (string MfgName,string MfgDate ,string prodName,string ExpDate) public{ //for manufacturer
    randSeqNum=uint64(keccak256(block.timestamp));
    prodId=uint64(keccak256(randSeqNum,prodName,msg.sender,MfgDate,ExpDate));
    Product[prodId]=MedicineDetail(MfgName,MfgDate,prodName,ExpDate);
    track[msg.sender][prodId]=true;
    emit ProdCreate(0,prodId,msg.sender,MfgName);
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
      emit SellProduct(2,prodId,msg.sender,SellerName);
  }  
    
}