/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

contract DNS {
  mapping(address => string) private dnsRecords;
  mapping(address => bool) private dnsHasRecords;

  address private _owner;

  constructor() {
    _owner = msg.sender;
  }

  function getOwner() external view returns (address) {
    return _owner;
  }

  function addToDNS(string memory domain) external {
    require(dnsHasRecords[msg.sender] == false,"error: domain already registered");

    dnsRecords[msg.sender] = domain;
    dnsHasRecords[msg.sender] = true;
  }

  function getFromDNS(address fromAddress) external view returns (string memory) {
    require(address(0) != fromAddress,"error: address is empty");
    require(dnsHasRecords[fromAddress] == true,"error: address has no domain");

    return dnsRecords[fromAddress];
  }

}