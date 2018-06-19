pragma solidity ^0.4.13;

contract AbstractENS{

    function owner(bytes32 node) constant returns(address);
    function resolver(bytes32 node) constant returns(address);
    function ttl(bytes32 node) constant returns(uint64);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
    function setResolver(bytes32 node, address resolver);
    function setTTL(bytes32 node, uint64 ttl);

    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
}

contract subSale{

  AbstractENS ens = AbstractENS(0x314159265dD8dbb310642f98f50C066173C1259b);
  address admin = 0x1f51d1d29AaFb00188168227a49d8f7E5D5b5bD9;

  struct Domain{
    address originalOwner;
    uint regPeriod;
    bool subSale;
    uint subPrice;
    uint subExpiry;
  }

  mapping(bytes32=>Domain) records;

  modifier node_owner(bytes32 node){
    if (ens.owner(node) != msg.sender) throw;
    _;
  }

  modifier recorded_owner(bytes32 node){
    if (records[node].originalOwner != msg.sender) throw;
    _;
  }

  function subSale() {}

  function listSubName(bytes32 node,uint price,uint expiry) node_owner(node){
    require(records[node].subSale != true);
 
    records[node].originalOwner=msg.sender;
    records[node].subSale=true;
    records[node].subPrice=price;
    records[node].subExpiry=expiry;
  }

  function unlistSubName(bytes32 node) recorded_owner(node){
    require(records[node].subSale==true);

    ens.setOwner(node,records[node].originalOwner);

    records[node].originalOwner=address(0x0);
    records[node].subSale=false;
    records[node].subPrice = 0;
    records[node].subExpiry = 0;
  }

  function nodeCheck(bytes32 node) returns(address){
    return ens.owner(node);
  }

  function subRegistrationPeriod(bytes32 node) returns(uint){
    return records[node].subExpiry;
  }

  function checkSubAvailability(bytes32 node) returns(bool){
    return records[node].subSale;
  }

  function checkSubPrice(bytes32 node) returns(uint){
    return records[node].subPrice;
  }

  function subBuy(bytes32 rootNode,bytes32 subNode,address newOwner) payable {
    require(records[rootNode].subSale == true);
    require(msg.value >= records[rootNode].subPrice);

    var newNode = sha3(rootNode,subNode);
    require(records[newNode].regPeriod < now);

    uint fee = msg.value/20;
    uint netPrice = msg.value - fee;

    admin.transfer(fee);
    records[rootNode].originalOwner.transfer(netPrice);

    records[newNode].regPeriod = now + records[rootNode].subExpiry;
    records[newNode].subSale = false;
    records[newNode].subPrice = 0;
    records[newNode].subExpiry = 0;

    ens.setSubnodeOwner(rootNode,subNode,newOwner);
  }

 function() payable{
    admin.transfer(msg.value);
  }

}