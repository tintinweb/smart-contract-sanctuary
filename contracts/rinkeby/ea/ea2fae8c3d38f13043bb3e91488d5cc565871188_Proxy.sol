/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
 
contract Ownable {
  address public owner; // slot 0

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

contract Proxy is Ownable {
    
    string wellcomeString = "Hello, world!";
    
    address payable implementation = payable(0x2fbcE81e0e7f4Ef95B5735bD23d8774956b77b17);
    uint256 version = 1;
    
    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
    }
    
    function changeImplementation(address payable _newImplementation, uint256 _newVersion) public onlyOwner {
        require(_newVersion > version, "New version must be greater then previous");
        implementation = _newImplementation;
    }
    
    uint256[50] private _gap;
}