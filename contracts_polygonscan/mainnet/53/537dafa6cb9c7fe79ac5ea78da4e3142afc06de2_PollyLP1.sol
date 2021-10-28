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

contract PollyLP1 {

  function name() public pure returns(string memory) { return "PollyLP1"; }
  function symbol() public pure returns(string memory) { return "PollyLP1"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
  IPair pair1 = IPair(0xF27C14AeDAD4C1CfA7207f826c64AdE3D5c741c3);
  (uint256 lp1_totalpollyA, uint256 lp1_totalpollyB,) = pair1.getReserves();

    return lp1_totalpollyA*(3);
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0x850161bF73944a8359Bd995976a34Bb9fe30d398);
    IPair pair1 = IPair(0xF27C14AeDAD4C1CfA7207f826c64AdE3D5c741c3);
    
	// LP pair1
    (uint256 reserveA_1, uint256 reserveA_2,) = pair1.getReserves();
    (uint256 lp1_userpolly,) = chef.userInfo(17, owner);
    uint256 user_unstaked1 = pair1.balanceOf(owner);
    uint256 pair1Total = pair1.totalSupply();
	
	// Add lp1_balance
    uint256 userShare1 = ((user_unstaked1+lp1_userpolly)*(1000000000000))/(pair1Total);
    uint256 pair1Underlying = (reserveA_1*(userShare1))/(1000000000000);
    uint256 lp1_balance = pair1Underlying*(3);
	
    // Add user polly balance
    uint256 lp_powah = lp1_balance;
    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}