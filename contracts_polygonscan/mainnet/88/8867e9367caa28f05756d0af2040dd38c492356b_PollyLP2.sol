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

contract PollyLP2 {

  function name() public pure returns(string memory) { return "PollyLP2"; }
  function symbol() public pure returns(string memory) { return "PollyLP2"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
	IPair pair2 = IPair(0x095fC71521668D5bcC0FC3e3a9848e8911aF21d9);
	(uint256 lp2_totalpollyA, uint256 lp2_totalpollyB,) = pair2.getReserves();

    return lp2_totalpollyA*(3);
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0x850161bF73944a8359Bd995976a34Bb9fe30d398);
  	IPair pair2 = IPair(0x095fC71521668D5bcC0FC3e3a9848e8911aF21d9);
    
	// LP pair2
    (uint256 reserveB_1, uint256 reserveB_2,) = pair2.getReserves();
    (uint256 lp2_userpolly,) = chef.userInfo(18, owner);
    uint256 user_unstaked2 = pair2.balanceOf(owner);
    uint256 pair2Total = pair2.totalSupply();
		
	// Add lp2_balance
    uint256 userShare2 = ((user_unstaked2+lp2_userpolly)*(1000000000000))/(pair2Total);
    uint256 pair2Underlying = (reserveB_1*(userShare2))/(1000000000000);
    uint256 lp2_balance = pair2Underlying*(3);
	  
    // Add user polly balance
    uint256 lp_powah = lp2_balance;
    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}