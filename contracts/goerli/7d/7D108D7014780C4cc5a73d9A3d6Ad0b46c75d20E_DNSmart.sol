/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract DNSmart {
      
   struct DNSResolver {
    uint Years;
    string url;
    string ipaddr;
    string ownerinfo;
  }
  mapping (address => DNSResolver) dnsresolver;
  address[] public DNSAccts;

  function registerDNS(address _address, uint _years, string memory _url, string memory _ipaddr, string memory _info) public {
    //var instructor = instructors[_address];
    dnsresolver[_address].Years = _years;
    dnsresolver[_address].url = _url;
    dnsresolver[_address].ipaddr= _ipaddr;   
    dnsresolver[_address].ownerinfo= _info;      
    DNSAccts.push(_address) ;
  }
  function DNSResolvers() view public returns(address[] memory) {
    return DNSAccts;
  }
  function getIPaddr(address _address) view public returns (string memory) {
    return (dnsresolver[_address].ipaddr);
  }
    function getOwnerInfo(address _address) view public returns (uint, string memory) {
    return (dnsresolver[_address].Years, dnsresolver[_address].ownerinfo);
  }
  function countDNS() view public returns (uint) {
    return DNSAccts.length;
  }
  function hi() pure public returns(string memory){
        return "Hello world";
  }
}