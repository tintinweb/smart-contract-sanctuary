pragma solidity ^0.4.18;

   contract ETPMap{
     mapping (address => string) internal address_map;
     event MapAddress(address, string);
     function get_address(address addr) constant public returns (string) {
         return address_map[addr];
     }

     function map_address(string etpaddr) public {
         address addr = msg.sender;
         address_map[addr] = etpaddr;
         MapAddress(addr, etpaddr);
     }
  }