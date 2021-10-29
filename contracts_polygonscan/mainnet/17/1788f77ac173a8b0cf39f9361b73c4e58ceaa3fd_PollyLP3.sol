/**
 *Submitted for verification at polygonscan.com on 2021-10-28
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function unlockedSupply() external view returns (uint256);
    function totalLock() external view returns (uint256);
    function lockOf(address account) external view returns (uint256);
}

interface IPair {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface IMasterChef {
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pendingReward(uint256 nr, address who) external view returns (uint256);
}

contract PollyLP3 {

  function name() public pure returns(string memory) { return "PollyLP3"; }
  function symbol() public pure returns(string memory) { return "PollyLP3"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
	  IPair pair3 = IPair(0xf70B37a372beFe8c274A84375C233a787D0D4DFa);
	  (uint256 lp3_totalpollyA, uint256 lp3_totalpollyB,) = pair3.getReserves();
    return lp3_totalpollyB*(3);
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0x850161bF73944a8359Bd995976a34Bb9fe30d398);
  	IPair pair3 = IPair(0xf70B37a372beFe8c274A84375C233a787D0D4DFa);
	
	// LP pair3
    (uint256 reserveC_1, uint256 reserveC_2,) = pair3.getReserves();
    (uint256 lp3_userpolly,) = chef.userInfo(19, owner);
    uint256 user_unstaked3 = pair3.balanceOf(owner);
    uint256 pair3Total = pair3.totalSupply();

	// Add lp3_balance
    uint256 userShare3 = ((user_unstaked3+lp3_userpolly)*(1000000000000))/(pair3Total);
    uint256 pair3Underlying = (reserveC_2*(userShare3))/(1000000000000);
    uint256 lp3_balance = pair3Underlying*(3);
    
    // Add user polly balance
    uint256 lp_powah = lp3_balance;
    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}