/**
 *Submitted for verification at polygonscan.com on 2021-10-25
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

contract PollyVotes {

  function name() public pure returns(string memory) { return "PollyVotes"; }
  function symbol() public pure returns(string memory) { return "PollyVotes"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
    IPair pair = IPair(0xF27C14AeDAD4C1CfA7207f826c64AdE3D5c741c3);
    IERC20 polly = IERC20(0x4C392822D4bE8494B798cEA17B43d48B2308109C);
    (uint256 lp_totalpolly, , ) = pair.getReserves();
    (uint256 unlockedTotal) = polly.unlockedSupply();
    (uint256 lockedTotal) = polly.totalLock();

    return lp_totalpolly*(3)+(unlockedTotal/(4))+(lockedTotal/(3));
  }

  function balanceOf(address owner) public view returns (uint256) {
    IMasterChef chef = IMasterChef(0x850161bF73944a8359Bd995976a34Bb9fe30d398);
    IERC20 polly = IERC20(0x4C392822D4bE8494B798cEA17B43d48B2308109C);
    IPair pair = IPair(0xF27C14AeDAD4C1CfA7207f826c64AdE3D5c741c3);
    
    (uint256 reserves, ,) = pair.getReserves();
    (uint256 lp_totalpolly, ) = chef.userInfo(0, owner);
    uint256 pairTotal = pair.totalSupply();
    uint256 locked_balance = polly.lockOf(owner);
    uint256 polly_balance = polly.balanceOf(owner)*(25)/(100);

    // Add locked balance
    uint256 userShare = lp_totalpolly/(pairTotal);
    uint256 pairUnderlying = reserves*(userShare)*(100);
    uint256 lp_balance = pairUnderlying*(3);
    lp_balance = lp_balance+(locked_balance*(33)/(100));
    
    // Add user polly balance
    uint256 lp_powah = lp_balance+(polly_balance);

    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}