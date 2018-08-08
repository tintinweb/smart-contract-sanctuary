pragma solidity ^0.4.11;

/*

ENS Trade Factory
========================

Listed names and additional information available at ensnames.com
Author: /u/Cintix
*/

// Interfaces for the various ENS contracts
contract AbstractENS {
  function setResolver(bytes32 node, address resolver);
}
contract Resolver {
  function setAddr(bytes32 node, address addr);
}
contract Deed {
  address public previousOwner;
}
contract Registrar {
  function transfer(bytes32 _hash, address newOwner);
  function entries(bytes32 _hash) constant returns (uint, Deed, uint, uint, uint);
}

// The child contract, used to make buying as simple as sending ETH.
contract SellENS {
  SellENSFactory factory;
  
  function SellENS(){
    // Store the address of the factory (0x34abcc1fdedb49c953445c11a71e428d719ba8d9)
    factory = SellENSFactory(msg.sender);
  }
  
  function () payable {
    // Delegate the work back to the factory to save space on the blockchain.
    // This saves on gas when creating sell contracts.
    // Could be replaced with a delegatecall to a library, but that
    // would require a second contract deployment and added complexity.
    factory.transfer(msg.value);
    factory.sell_label(msg.sender, msg.value);
  }
}

// The factory which produces the seller child contracts.
contract SellENSFactory {
  // Store the relevant information for each child contract.
  struct SellENSInfo {
    string label;
    uint price;
    address owner;
  }
  mapping (address => SellENSInfo) public get_info;
  
  // The developer address, used for seller fees.
  address developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;
  // The Ethereum Name Service primary contract.
  AbstractENS ens = AbstractENS(0x314159265dD8dbb310642f98f50C066173C1259b);
  // The Ethereum Name Service Registrar contract.
  Registrar registrar = Registrar(0x6090A6e47849629b7245Dfa1Ca21D94cd15878Ef);
  // The Ethereum Name Service Public Resolver contract.
  Resolver resolver = Resolver(0x1da022710dF5002339274AaDEe8D58218e9D6AB5);
  // The hash of ".eth" under which all top level names are registered.
  bytes32 root_node = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
  
  // Events used to help track sales.
  event SellENSCreated(SellENS sell_ens);
  event LabelSold(SellENS sell_ens);
  
  // Called by name sellers to make a new seller child contract.
  function createSellENS(string label, uint price) {
    SellENS sell_ens = new SellENS();
    // Store the seller&#39;s address so they can get paid when the name sells.
    get_info[sell_ens] = SellENSInfo(label, price, msg.sender);
    SellENSCreated(sell_ens);
  }
  
  // Called only by seller child contracts when a name is purchased.
  function sell_label(address buyer, uint amount_paid){
    SellENS sell_ens = SellENS(msg.sender);
    // Verify the sender is a child contract.
    if (get_info[sell_ens].owner == 0x0) throw;
    
    string label = get_info[sell_ens].label;
    uint price = get_info[sell_ens].price;
    address owner = get_info[sell_ens].owner;
    
    // Calculate the hash of the name being bought.
    bytes32 label_hash = sha3(label);
    // Retrieve the name&#39;s deed.
    Deed deed;
    (,deed,,,) = registrar.entries(label_hash);
    // Verify the deed&#39;s previous owner matches the seller.
    if (deed.previousOwner() != owner) throw;
    // Calculate the hash of the full name (i.e. rumours.eth).
    bytes32 node = sha3(root_node, label_hash);
    // Set the name&#39;s resolver to the public resolver.
    ens.setResolver(node, resolver);
    // Configure the resolver to direct payments sent to the name to the buyer.
    resolver.setAddr(node, buyer);
    // Transfer the name&#39;s deed to the buyer.
    registrar.transfer(label_hash, buyer);

    // Dev fee of 5%
    uint fee = price / 20;
    // The seller pays nothing to unlist and get their name back.
    if (buyer == owner) {
      price = 0;
      fee = 0;
    }
    // 5% to the dev
    developer.transfer(fee);
    // 95% to the seller
    owner.transfer(price - fee);
    // Any extra past the sale price is returned to the buyer.
    if (amount_paid > price) {
      buyer.transfer(amount_paid - price);
    }
    LabelSold(sell_ens);
  }
  
  // The factory must be payable to receive funds from its child contracts.
  function () payable {}
}