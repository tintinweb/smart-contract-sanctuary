/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

pragma solidity ^0.4.25;

contract DeepSkillsIssuerRegistry {
  address public manager;
  uint public lastIssuerIndex;
  mapping(uint => string) public issuersMap;

  constructor() public {
    manager = msg.sender;
    lastIssuerIndex = 0;
  }

  function returnIssuer(uint _index) public view returns(string) {
    return issuersMap[_index];
  }

  function addIssuer(string _issuer) public payable onlyManager {
    issuersMap[lastIssuerIndex] = _issuer;
    lastIssuerIndex = lastIssuerIndex + 1;
  }

  modifier onlyManager() {
    require (msg.sender == manager);
    _;
  }

}