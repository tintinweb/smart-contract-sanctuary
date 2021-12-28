/**
 *Submitted for verification at FtmScan.com on 2021-12-27
*/

pragma solidity ^0.8.6;

interface IMaiEthVault {
    function getDebtCeiling() external view returns(uint);
}

contract GetMaiReserveContract {
  uint data;
  address counterAddr;

  function getFtmEthMaiReserveData(address addr) external view returns(uint) {
    return IMaiEthVault(addr).getDebtCeiling();
  }
}