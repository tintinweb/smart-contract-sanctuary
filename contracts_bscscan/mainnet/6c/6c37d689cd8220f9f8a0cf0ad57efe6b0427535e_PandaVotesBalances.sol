/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function unlockedSupply() external view returns (uint256);
    function totalLock() external view returns (uint256);
    function lockOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract PandaVotesBalances {

  function name() public pure returns(string memory) { return "PandaVotesBalances"; }
  function symbol() public pure returns(string memory) { return "PandaVotesBalances"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
    IERC20 bamboo = IERC20(0xD2ECa3cff5F09Cfc9C425167d12F0a005Fc97c8c);
    IERC20 rhino = IERC20(0xEF88e0d265dDC8f5E725a4fDa1871F9FE21B11E2);
    IERC20 panda = IERC20(0x47DcC83a14aD53Ed1f13d3CaE8AA4115f07557C0);
    (uint256 unlockedTotalPanda) = panda.unlockedSupply();
    (uint256 lockedTotalPanda) = panda.totalLock();
    (uint256 unlockedTotalRhino) = rhino.unlockedSupply();
    (uint256 unlockedTotalBamboo) = bamboo.unlockedSupply();

    return ((unlockedTotalRhino)*(250000000000)/(100000000000))+(unlockedTotalPanda/(4))+(lockedTotalPanda/(3))+(unlockedTotalBamboo/(4));
  }
  function balanceOf(address owner) public view returns (uint256) {
    IERC20 bamboo = IERC20(0xD2ECa3cff5F09Cfc9C425167d12F0a005Fc97c8c);
    IERC20 rhino = IERC20(0xEF88e0d265dDC8f5E725a4fDa1871F9FE21B11E2);
    IERC20 panda = IERC20(0x47DcC83a14aD53Ed1f13d3CaE8AA4115f07557C0);
    
    // Add locked balance 
    uint256 locked_balance = panda.lockOf(owner);
    uint256 panda_balance = panda.balanceOf(owner)*(25)/(100);
    uint256 bamboo_balance = bamboo.balanceOf(owner)*(25)/(100);
    uint256 rhino_balance = rhino.balanceOf(owner)*(250000000000)/(100000000000);
    uint256 lp_powah = panda_balance+bamboo_balance+rhino_balance+(locked_balance*(33)/(100));
    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}