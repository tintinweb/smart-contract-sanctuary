/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.5.4;

contract shoppy {
    
   address payable public owner;
   
   constructor() public {
       owner=msg.sender;
          }
      uint id;
      uint purchaseId;
    
    struct product{
        string productId;
        string productName;
        string Category;
        uint price;
        string description;
        address payable seller;
        bool isActive;
        
           }
     struct ordersPlaced {
               string productId;
               uint purchaseId;
               address orderedBy;
               
              }
    struct orders{
        string productId;
        string orderStatus;
        uint purchaseId;
        string shipmentStatus;
        
          }
    struct user{
        string name;
        string email;
        string deliveryAddress;
        bool isCreated;
           }
    
    struct sellerShipment {
        string productId;
        uint purchaseId;
        string shipmentStatus;
        string deliveryAddress;
        address  payable orderedBy;
        bool isActive;
        bool isCanceled;
        
        
            }
    struct seller{
                string name;
                address addr;
                uint bankGuaraantee;
                bool bgPaid;
                }
    product[] public allProducts;
    
    mapping (string => product) products;
    mapping (address=>orders[]) userOrders;
    mapping (address=> user) users;
    mapping(address=> seller) public sellers;
    mapping (address=> ordersPlaced[]) sellerOrders;
    mapping (address=> mapping(uint=>sellerShipment))sellerShipments;
    
    
    function addProduct(string memory _productId, string memory _productName, string memory _category, uint _price, string memory _description) public {
      require(!products[_productId].isActive);
       require(sellers[msg.sender].bgPaid);
       
       product memory product = product(_productId, _productName, _category, _price, _description, msg.sender, true);  
       products[_productId].productId= _productId;
       products[_productId].productName= _productName;   
       products[_productId].Category= _category;   
       products[_productId].description= _description;   
       products[_productId].price= _price;   
       products[_productId].seller= msg.sender; 
       products[_productId].isActive = true;
       allProducts.push(product);
          
                     }
    
    function buyProduct(string memory _productId)  public payable {
        
        
        require(msg.value == products[_productId].price);
        require( users[msg.sender].isCreated);
        
        products[_productId].seller.transfer(msg.value);
        
        purchaseId = id++;
         orders memory order = orders(_productId,  "Order Placed With Seller",purchaseId, sellerShipments[products[_productId].seller][purchaseId].shipmentStatus);
        userOrders[msg.sender].push(order);
        ordersPlaced memory ord = ordersPlaced(_productId, purchaseId, msg.sender);
        sellerOrders[products[_productId].seller].push(ord);
        
        sellerShipments[products[_productId].seller][purchaseId].productId=_productId;
        sellerShipments[products[_productId].seller][purchaseId].orderedBy= msg.sender;
        sellerShipments[products[_productId].seller][purchaseId].purchaseId= purchaseId;
        sellerShipments[products[_productId].seller][purchaseId].deliveryAddress = users[msg.sender].deliveryAddress;
        sellerShipments[products[_productId].seller][purchaseId].isActive= true;
        
        
                     }
    function createAccount(string memory _name, string memory _email, string memory _deliveryAddress) public {
        
        users[msg.sender].name= _name;
        users[msg.sender].email= _email;
        users[msg.sender].deliveryAddress= _deliveryAddress;
        users[msg.sender].isCreated= true;
                     }
    function updateShipment(uint _purchaseId, string memory _shipmentDetails) public {
        require(sellerShipments[msg.sender][_purchaseId].isActive);
        
        sellerShipments[msg.sender][_purchaseId].shipmentStatus= _shipmentDetails;
        
                    }
    
    function sellerSignUp(string memory _name) public payable{
    require(!sellers[msg.sender].bgPaid);
        require(msg.value==5 ether);
        owner.transfer(msg.value);
        sellers[msg.sender].name= _name;
        sellers[msg.sender].addr= msg.sender;
        sellers[msg.sender].bankGuaraantee = msg.value;
        sellers[msg.sender].bgPaid=true;
    }
    function cancelOrder(string memory _productId, uint _purchaseId) public payable {
    require(sellerShipments[products[_productId].seller][_purchaseId].orderedBy==msg.sender);
    
    sellerShipments[products[_productId].seller][_purchaseId].shipmentStatus= "Order Canceled By Buyer, Payment will Be  Refunded";
    sellerShipments[products[_productId].seller][_purchaseId].isCanceled= true; 
    }
    function refund(string memory _productId, uint _purchaseId)public payable {
       require (sellerShipments[msg.sender][_purchaseId].isCanceled); 
        require(msg.value==products[_productId].price);
        sellerShipments[msg.sender][_purchaseId].orderedBy.transfer(msg.value);
        sellerShipments[products[_productId].seller][_purchaseId].shipmentStatus= "Order Canceled By Buyer, Payment Refunded";
        
        
    }
    
    
    //getters
     function getOrdersPlacedLength() public view returns(uint) {
        return sellerOrders[msg.sender].length;
         }
    function getProductsLength() public view returns(uint) {
        return allProducts.length;
         }
         
     function getMyOrdersLength() public view returns(uint) {
        return userOrders[msg.sender].length;
         }
    
    function myOrders (uint _index) public view returns(string memory, string memory, uint, string memory) {
        
        return(userOrders[msg.sender][_index].productId, userOrders[msg.sender][_index].orderStatus, userOrders[msg.sender][_index].purchaseId, sellerShipments[products[userOrders[msg.sender][_index].productId].seller][userOrders[msg.sender][_index].purchaseId].shipmentStatus);
                  }
   
    function getShipmentProductId(uint _purchaseId) public view returns(string memory) {
        
        return(sellerShipments[msg.sender][_purchaseId].productId);
    }
     function getShipmentStatus(uint _purchaseId) public view returns(string memory) {
        
        return(sellerShipments[msg.sender][_purchaseId].shipmentStatus);
    }
     function getShipmentOrderedBy(uint _purchaseId) public view returns(address) {
        
        return(sellerShipments[msg.sender][_purchaseId].orderedBy);
    
    }
     function getShipmentAddress(uint _purchaseId) public view returns(string memory) {
        
        return(sellerShipments[msg.sender][_purchaseId].deliveryAddress);
    }
      
     function getOrdersPlaced(uint _index) public view returns(string memory, uint, address, string memory) {
        
        return(sellerOrders[msg.sender][_index].productId, sellerOrders[msg.sender][_index].purchaseId, sellerOrders[msg.sender][_index].orderedBy, sellerShipments[msg.sender][sellerOrders[msg.sender][_index].purchaseId].shipmentStatus);
    } 
}