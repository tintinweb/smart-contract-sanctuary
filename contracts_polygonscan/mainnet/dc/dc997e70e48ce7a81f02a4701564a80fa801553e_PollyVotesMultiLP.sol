/**
 *Submitted for verification at polygonscan.com on 2021-10-28
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function unlockedSupply() external view returns (uint256);
    function totalLock() external view returns (uint256);
    function lockOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract PollyVotesMultiLP {

  function name() public pure returns(string memory) { return "PollyVotesMultiLP"; }
  function symbol() public pure returns(string memory) { return "PollyVotesMultiLP"; }
  function decimals() public pure returns(uint8) { return 18; }  

  function totalSupply() public view returns (uint256) {
    IERC20 pair1 = IERC20(0x537Dafa6CB9c7FE79AC5Ea78Da4E3142afc06dE2);
    IERC20 pair2 = IERC20(0x8867e9367caa28F05756D0af2040DD38C492356b);
    IERC20 pair3 = IERC20(0x1788f77aC173a8b0CF39f9361B73C4E58CEaa3Fd);
    IERC20 polly = IERC20(0x4C392822D4bE8494B798cEA17B43d48B2308109C);
    uint256 lp1_totalpolly = pair1.totalSupply();
	uint256 lp2_totalpolly = pair2.totalSupply();
	uint256 lp3_totalpolly = pair3.totalSupply();
    (uint256 unlockedTotal) = polly.unlockedSupply();
    (uint256 lockedTotal) = polly.totalLock();

    return lp1_totalpolly+lp2_totalpolly+lp3_totalpolly+(unlockedTotal/(4))+(lockedTotal/(3));
  }
  function balanceOf(address owner) public view returns (uint256) {
    IERC20 polly = IERC20(0x4C392822D4bE8494B798cEA17B43d48B2308109C);
    IERC20 pair1 = IERC20(0x537Dafa6CB9c7FE79AC5Ea78Da4E3142afc06dE2);
    IERC20 pair2 = IERC20(0x8867e9367caa28F05756D0af2040DD38C492356b);
    IERC20 pair3 = IERC20(0x1788f77aC173a8b0CF39f9361B73C4E58CEaa3Fd);
    
    // Add locked balance 
    uint256 locked_balance = polly.lockOf(owner);
    uint256 polly_balance = polly.balanceOf(owner)*(25)/(100);
    uint256 lp1_balance = pair1.balanceOf(owner);
    uint256 lp2_balance = pair2.balanceOf(owner);
    uint256 lp3_balance = pair3.balanceOf(owner);
    uint256 lp_locked = lp1_balance+lp2_balance+lp3_balance+(locked_balance*(33)/(100));
    
    // Add user polly balance
    uint256 lp_powah = lp_locked+(polly_balance);
    
    return lp_powah;
  }

  function allowance(address, address) public pure returns (uint256) { return 0; }
  function transfer(address, uint256) public pure returns (bool) { return false; }
  function approve(address, uint256) public pure returns (bool) { return false; }
  function transferFrom(address, address, uint256) public pure returns (bool) { return false; }
}