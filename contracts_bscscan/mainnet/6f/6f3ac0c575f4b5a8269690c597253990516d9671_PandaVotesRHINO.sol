/**
 *Submitted for verification at BscScan.com on 2021-10-31
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

contract PandaVotesRHINO {

  function name() public pure returns(string memory) { return "PandaVotesRHINO"; }
  function symbol() public pure returns(string memory) { return "PandaVotesRHINO"; }
  function decimals() public pure returns(uint8) { return 9; }  

  function totalSupply() public view returns (uint256) {
  IERC20 rhino = IERC20(0xD2ECa3cff5F09Cfc9C425167d12F0a005Fc97c8c);
  IPair pair2 = IPair(0x999fd87aA406adB81809bab15681f655d8a049FF);
  (uint256 lp2_totalpandaA, uint256 lp2_totalpandaB,) = pair2.getReserves();
  (uint256 unlockedTotal) = rhino.unlockedSupply();

    return (unlockedTotal*(250)/100)+(lp2_totalpandaB)*(10);
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0x9942cb4c6180820E6211183ab29831641F58577A);
    IERC20 rhino = IERC20(0xD2ECa3cff5F09Cfc9C425167d12F0a005Fc97c8c);
    IPair pair2 = IPair(0x999fd87aA406adB81809bab15681f655d8a049FF);
    
    // LP pair2
    (uint256 reserveB_1, uint256 reserveB_2,) = pair2.getReserves();
    (uint256 lp2_userpanda,) = chef.userInfo(92, owner);
    uint256 user_unstaked2 = pair2.balanceOf(owner);
    uint256 pair2Total = pair2.totalSupply();
	

	// Add lp1_balance
    uint256 userShare2 = ((user_unstaked2+lp2_userpanda)*(1000000000000))/(pair2Total);
    uint256 pair2Underlying = (reserveB_2*(userShare2))/(1000000000000);    
    	
    // Add user panda balance
    uint256 rhino_balance = rhino.balanceOf(owner)*(250)/(100);
    uint256 lp_powah = rhino_balance+(pair2Underlying)*(10);
    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}