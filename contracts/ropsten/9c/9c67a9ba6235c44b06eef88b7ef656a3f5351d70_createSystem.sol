pragma solidity ^0.4.20;

contract createSystem {
  
  struct SystemComponents {
    string name;
    uint8 ram;
    uint8 disk1;
    uint hddSpace;
    uint cost;
  }

  mapping(address => SystemComponents) ownerMappedToSystemMade;
  
  function createNewSystem (string _name, uint8 _ram, uint8 _disk1) public {
   SystemComponents memory systemMade = SystemComponents({
     name     : _name,
     ram      : _ram,
     disk1    : _disk1,
     hddSpace : 100,
     cost     : 1000
  });

  ownerMappedToSystemMade[msg.sender] = systemMade;

  }

}