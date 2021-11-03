/**
 *Submitted for verification at BscScan.com on 2021-11-03
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

contract PandaVotesRHINOPCS {

  function name() public pure returns(string memory) { return "PandaVotesRHINOPCS"; }
  function symbol() public pure returns(string memory) { return "PandaVotesRHINOPCS"; }
  function decimals() public pure returns(uint8) { return 9; }  

  function totalSupply() public view returns (uint256) {
  IPair pair1 = IPair(0x92DC12e0eB47B287b4D91976D4Eb968f61822531);
  (uint256 lp1_totalpandaA, uint256 lp1_totalpandaB,) = pair1.getReserves();

    return (lp1_totalpandaB)*(10);
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0x9942cb4c6180820E6211183ab29831641F58577A);
    IPair pair1 = IPair(0x92DC12e0eB47B287b4D91976D4Eb968f61822531);
    
    // LP pair2
    (uint256 lp1_totalpandaA, uint256 lp1_totalpandaB,) = pair1.getReserves();
    (uint256 lp1_userpanda,) = chef.userInfo(93, owner);
    uint256 user_unstaked1 = pair1.balanceOf(owner);
    uint256 pair1Total = pair1.totalSupply();
	

	// Add lp1_balance
    uint256 userShare1 = ((user_unstaked1+lp1_userpanda)*(1000000000000))/(pair1Total);
    uint256 pair1Underlying = (lp1_totalpandaB*(userShare1))/(1000000000000);
    uint256 lp1_balance = pair1Underlying*(10);
    	
    // Add user panda balance
    uint256 lp_powah = lp1_balance;
    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}