/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

pragma solidity ^0.4.17;

contract ERC20 {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
}

contract BalanceLogger {
  address tracker_0x_address = 0xf80a32a835f79d7787e8a8ee5721d0feafd78108; // Ropsten DAI
  
  event HasBalanceOf(address _owner, uint _balance);

  function logBalance() public {
      uint balance = ERC20(tracker_0x_address).balanceOf(tx.origin);
      emit HasBalanceOf(tx.origin, balance);
  }

}