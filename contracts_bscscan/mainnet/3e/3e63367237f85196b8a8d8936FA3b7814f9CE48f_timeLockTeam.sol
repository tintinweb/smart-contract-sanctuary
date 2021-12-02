/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ____  ____  _____ ____
// /  _ \/  __\/  __// ___\
// | / \||  \/||  \  |    \
// | |-|||  __/|  /_ \___ |
// \_/ \|\_/   \____\\____/
// -===== APES.TEAM =====-
// TimeLock Smart Contract
// Lock the team tokens for 1 year

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract timeLockTeam {
  uint256 public start;
  uint256 public end;
  address private owner;

  modifier onlyOwner() {
      require(owner == msg.sender, "Ownable: caller is not the owner");
      _;
  }

  constructor() {
    owner = msg.sender;
    start = block.timestamp;
    end = start + 365 days;
  }

  function getTokens(address _token) public view returns (uint) {
    return IERC20(_token).balanceOf(address(this));
  }

  function releaseTokens(address _token, address _wallet) public onlyOwner {
    require(block.timestamp > end, "lock time has not expired");
    uint256 amount = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(_wallet, amount);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      owner = newOwner;
  }

}