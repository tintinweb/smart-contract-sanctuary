/**
 *Submitted for verification at polygonscan.com on 2021-10-27
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

contract PollyVotesTest {

  function name() public pure returns(string memory) { return "PollyVotesTest"; }
  function symbol() public pure returns(string memory) { return "PollyVotesTest"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
    IPair pair = IPair(0xf70B37a372beFe8c274A84375C233a787D0D4DFa);
    IERC20 polly = IERC20(0x4C392822D4bE8494B798cEA17B43d48B2308109C);
    (uint256 lp_totalpolly, ,) = pair.getReserves();
    (uint256 unlockedTotal) = polly.unlockedSupply();
    (uint256 lockedTotal) = polly.totalLock();

    return lp_totalpolly*(3)+(unlockedTotal/(4))+(lockedTotal/(3));
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0x850161bF73944a8359Bd995976a34Bb9fe30d398);
    IERC20 polly = IERC20(0x4C392822D4bE8494B798cEA17B43d48B2308109C);
    IPair pair = IPair(0xf70B37a372beFe8c274A84375C233a787D0D4DFa);
    
    (uint256 reserveA_1, uint256 reserveA_2,) = pair.getReserves();
    (uint256 lp1_userpolly,) = chef.userInfo(19, owner);
    uint256 pairTotal1 = pair.totalSupply();
    uint256 locked_balance = polly.lockOf(owner);
    uint256 polly_balance = polly.balanceOf(owner)*(25)/(100);

    // Add locked balance
    uint256 userShare1 = (lp1_userpolly*(1000000))/(pairTotal1);
    uint256 pair1Underlying = (reserveA_2*(userShare1))/(10000);
    uint256 lp1_balance = pair1Underlying*(3);
    uint256 lp_locked = lp1_balance+(locked_balance*(33)/(100));
    
    // Add user polly balance
    uint256 lp_powah = pair1Underlying;
    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}