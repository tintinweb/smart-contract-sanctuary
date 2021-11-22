/**
 *Submitted for verification at snowtrace.io on 2021-11-22
*/

/**
 *Submitted for verification at snowtrace.io on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
// import '@openzeppelin/contracts/access/Ownable.sol';
interface IERC20 {
  function balanceOf(address _user) external view returns(uint256);
  function transferFrom(address _user1, address _user2, uint256 amount) external ;
}

contract Verse {
  IERC20 public USDCContract = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);
  IERC20 public VerseContract = IERC20(0xabC6A451f9f8dDec2D4916C813D8f1065526897F);
  address public ownerAddr = 0xEE6440dF09E5dAE2037a5dfc6e6E314edea44047;

  constructor () {
  }

  function buyVerseToken(uint amount) public {
    uint256 usdcamount = amount * (10 ** 6);
    uint256 USDCBalance = USDCContract.balanceOf(msg.sender);
    uint256 VerseBalance = VerseContract.balanceOf(ownerAddr);
    require(USDCBalance > usdcamount, "need more money to buy verse");
    require(VerseBalance > amount, "need more verse token");
    USDCContract.transferFrom(msg.sender, ownerAddr, usdcamount);
    VerseContract.transferFrom(ownerAddr, msg.sender, amount);
  }
}