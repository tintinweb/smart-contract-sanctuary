pragma solidity ^0.5.17;

import './ERC20.sol';

contract UniLiquidityCalculator {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public ZZZ = IERC20(address(0));
  IERC20 public UNI = IERC20(address(0));

  constructor(address _zzz,address _uni) public {
    ZZZ = IERC20(_zzz);
    UNI = IERC20(_uni);
  }
  
  function getZZZBalanceInUni() public view returns (uint256) {
    return ZZZ.balanceOf(address(UNI));
  }

  function getUNIBalance(address account) public view returns (uint256) {
    return UNI.balanceOf(account);
  }

  function getTotalUNI() public view returns (uint256) {
    return UNI.totalSupply();
  }

  function calculateShare(address account) external view returns (uint256) {
    // ZZZ in pool / total number of UNI tokens * number of uni tokens owned by account
    return getZZZBalanceInUni().mul(getUNIBalance(account)).div(getTotalUNI());
  }
 }