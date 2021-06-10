/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.8.4;

interface ERC20 {
    function balanceOf(address tokenOwner) external view returns (uint balance);
}

contract BalanceLogger {
  address tracker_0x_address = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD; // Kovan DAI
  
  event HasBalanceOf(address _owner, uint _balance);

  function logBalance() public {
      uint balance = ERC20(tracker_0x_address).balanceOf(tx.origin);
      emit HasBalanceOf(tx.origin, balance);
  }

}