pragma solidity ^0.4.13;

contract AbstractENS{
    function owner(bytes32 node) constant returns(address);
    function setOwner(bytes32 node, address owner);
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner);
}

contract Registrar {
  function transfer(bytes32 _hash, address newOwner);
  function entries(bytes32 _hash) constant returns (uint, Deed, uint, uint, uint);
}

contract Deed {
  address public owner;
  address public previousOwner;
}

contract subdomainSale{
  AbstractENS ens = AbstractENS(0x314159265dD8dbb310642f98f50C066173C1259b);
  Registrar registrar = Registrar(0x6090A6e47849629b7245Dfa1Ca21D94cd15878Ef);  
  address admin = 0x8301Fb8945760Fa2B3C669e8F420B8795Dc03766;


  struct Domain{
    address originalOwner;
    uint commitPeriod;
    uint regPeriod;
    bool subSale;
    uint subPrice;
    uint subExpiry;
  }

  mapping(bytes32=>Domain) records;

  modifier deed_check(bytes32 label){
     Deed deed;
     (,deed,,,) = registrar.entries(label); 
     if(deed.owner() != address(this)) throw;
     _;
  }
 
  modifier prevOwn_check(bytes32 label){
    Deed deed;
     (,deed,,,) = registrar.entries(label); 
     if(deed.previousOwner() != msg.sender) throw;
     _;
  }

  modifier ens_check(bytes32 node){
    if(ens.owner(node) != address(this)) throw;
    _;
  }


  modifier recorded_owner(bytes32 node){
    if (records[node].originalOwner != msg.sender) throw;
    _;
  }

  function subdomainSale() {}

  function listSubName(bytes32 label,bytes32 node,uint commit, uint price,uint expiry) prevOwn_check(label) deed_check(label) ens_check(node){
    require(records[node].subSale == false); 
    require(expiry>=604800);   
    require(expiry<=commit);

    records[node].originalOwner=msg.sender;
    records[node].subSale=true;
    records[node].subPrice=price;
    records[node].subExpiry=expiry;
    records[node].commitPeriod=now + commit + 86400;
  }

  function unlistSubName(bytes32 label,bytes32 node) recorded_owner(node) ens_check(node) deed_check(label){
    require(records[node].commitPeriod <= now);    

    ens.setOwner(node,records[node].originalOwner);
    registrar.transfer(label,records[node].originalOwner);
 
    records[node].originalOwner=address(0x0);
    records[node].subSale=false;
    records[node].subPrice = 0;
    records[node].subExpiry = 0;
    records[node].commitPeriod=0;
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

  function checkCommitPeriod(bytes32 node) returns(uint){
    return records[node].commitPeriod;
  }

  function checkRegPeriod(bytes32 node) returns(uint){
    return records[node].regPeriod;
  }

  function subBuy(bytes32 ensName,bytes32 subNode,bytes32 newNode,address newOwner) payable ens_check(ensName) {
    require( (records[ensName].subExpiry + now + 5) < records[ensName].commitPeriod );
    require(records[ensName].subSale == true);
    require(msg.value >= records[ensName].subPrice);
    
    require(records[newNode].regPeriod < now);

    uint fee = msg.value/20;
    uint netPrice = msg.value - fee;

    admin.transfer(fee);
    records[ensName].originalOwner.transfer(netPrice);

    records[newNode].regPeriod = now + records[ensName].subExpiry;
    records[newNode].subSale = false;
    records[newNode].subPrice = 0;
    records[newNode].subExpiry = 0;
    records[newNode].commitPeriod=0;

    ens.setSubnodeOwner(ensName,subNode,newOwner);
  }

 function() payable{
    admin.transfer(msg.value);
  }

}