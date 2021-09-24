/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

pragma solidity ^0.8.0;

interface CErc20Delegator {
    function balanceOf(address owner) external view virtual returns (uint);
    function exchangeRateStored() external view returns (uint);
}

contract FTribeVoting {

  CErc20Delegator public FTRIBE = CErc20Delegator(address(0xFd3300A9a74b3250F1b2AbC12B47611171910b07));

  function balanceOf(address who) public view returns (uint256) {
    return FTRIBE.balanceOf(who) * FTRIBE.exchangeRateStored() / 1e18;
  }  
}