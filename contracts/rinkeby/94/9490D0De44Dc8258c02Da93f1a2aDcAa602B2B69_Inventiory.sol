/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

pragma solidity ^0.8.0;


 
contract Inventiory {

  struct Product {
    string name;
    string description;
    string location;
    string Producer;
    uint32 salePrice;
    uint256 CreationDate;
    bool exist;
  }


  mapping(string  => Product) private StorageProduct;
  mapping(address => mapping(string => bool)) private wallet;



  event CreateProduct(address addressProducer, string id, string Producer, uint256 CreationDate);
  event TransferProduct(address from, address to, string id);

  event TransferReject(address from, address to, string id, string RejectMessage);
  event CreationReject(address addressProducer, string id, string RejectMessage);

 
  function creationProduct(string memory name, string memory description, string memory id, string memory Producer, string memory location,  uint32 salePrice) public {
 
    if(StorageProduct[id].exist) {
        emit CreationReject(msg.sender, id, "Product con this id already exist");
        return;
      }
 
      StorageProduct[id] = Product(name, description, location, Producer, salePrice, block.timestamp, true);
      wallet[msg.sender][id] = true;
      emit CreateProduct(msg.sender, id, Producer, block.timestamp);
    }

  function transfProduct(address to, string memory id) public{
 
    if(!StorageProduct[id].exist) {
        emit TransferReject(msg.sender, to, id, "It does not exist a Product with this id");
        return;
    }
 
    if(!wallet[msg.sender][id]) {
        emit TransferReject(msg.sender, to, id, "user is not the owner of this Product.");
        return;
    }
 
    wallet[msg.sender][id] = false;
    wallet[to][id] = true;
    emit TransferProduct (msg.sender, to, id);
  }


  function getProduct(string memory id) public view returns  (string memory, string memory, string memory, string memory, uint256) {
 
    return (StorageProduct[id].name, StorageProduct[id].description, StorageProduct[id].Producer, StorageProduct[id].location, StorageProduct[id].salePrice);
  }

 function getPrice(string memory id) public view returns (uint256)
   {
    return StorageProduct[id].salePrice;
   }
   
   
  function isOwner(address owner, string memory id) public view returns (bool) {
 
    if(wallet[owner][id]) {
        return true;
    }
 
    return false;
  }
}