/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity ^0.8.0;

interface CErc20Delegator {
    function balanceOf(address owner) external view virtual returns (uint);
    function exchangeRateStored() external view returns (uint);
}

interface ITribe {
  function balanceOf(address who) external view returns (uint256);
  function getCurrentVotes(address who) external view returns (uint256);
  function delegates(address who) external view returns (address);
}

contract RGTVoting {

  CErc20Delegator public constant fRGT6 = CErc20Delegator(address(0x558a7A68C574D83f327E7008c63A86613Ea48B4f));
  CErc20Delegator public constant fRGT7 = CErc20Delegator(address(0xA9df6bDc438A06C7946f99B6840Bf412CffA3ab4));
  ITribe public constant RGT = ITribe(address(0xD291E7a03283640FDc51b121aC401383A46cC623));

  uint256 public constant multiplier = 27;

  function balanceOf(address who) public view returns (uint256) {
    uint256 f6 = fRGT6.balanceOf(who) * fRGT6.exchangeRateStored() / 1e18;
    uint256 f7 = fRGT7.balanceOf(who) * fRGT7.exchangeRateStored() / 1e18;

    return (f6 + f7 + rawBalanceOf(who)) * multiplier;
  }

  function rawBalanceOf(address who) internal view returns (uint256) {
    uint256 tokenBal = RGT.balanceOf(who);
    uint256 delegatedBal = RGT.getCurrentVotes(who);
    address delegatee = RGT.delegates(who);
    if (delegatee == address(0)) {
      return delegatedBal + tokenBal;
    } else {
      return delegatedBal;
    }
  }    
}