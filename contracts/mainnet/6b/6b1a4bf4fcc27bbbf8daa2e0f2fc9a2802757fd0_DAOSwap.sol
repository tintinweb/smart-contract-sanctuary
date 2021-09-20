/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IERC20 {
  function balanceOf(address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
}

contract DAOSwap {
  address public constant DAVID = 0x8F73bE66CA8c79382f72139be03746343Bf5Faa0;
  address payable public constant JOELS = payable(0x7E88C2ef313EF805a62327a623301295aEb49B8b);
  IERC20 private constant DAO = IERC20(0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413);

  function cancel() external {
    DAO.transfer(JOELS, DAO.balanceOf(address(this)));
  }

  function swap() external payable {
    uint256 balance = DAO.balanceOf(address(this));
    if (msg.value != balance) {
      revert();
    }
    DAO.transfer(DAVID, balance);

    JOELS.transfer(msg.value);
    //selfdestruct(JOELS);
  }
}