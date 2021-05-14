/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// Built off of https://github.com/DeltaBalances/DeltaBalances.github.io/blob/master/smart_contract/deltabalances.sol
pragma solidity ^0.4.21;


contract ContractChecker {
  /* Fallback function, don't accept any ETH */
  function() public payable {
    revert();
  }
  
   function checkAddress(address[] addr) view external returns(bool[] isContracts) {
      isContracts = new bool[](addr.length);
      for(uint i; i<addr.length; i++) {
        uint size;
        address token = addr[i];
        assembly { size := extcodesize(token) }
        isContracts[i] = size>0;
      }
      return isContracts;
    }
}