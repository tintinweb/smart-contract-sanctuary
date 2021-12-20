/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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
    
    
    
    address payable implementation = payable(0x34F549f0E07264B7d2910E56c5e8b7c4eAf4C159);
    
    
    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
    }
    
    function changeImplementation(address payable _newImplementation, uint256 _newVersion) public onlyOwner {
        
        implementation = _newImplementation;
    }
    
     
}