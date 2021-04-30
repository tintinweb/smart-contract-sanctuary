/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.10; // optimization runs: 200, evm version: istanbul


interface IERC20 {
  function balanceOf(address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
}


contract TradeReserveEtherReceiver {
  address payable internal constant _TRADE_RESERVE = (
    0xfffF5A4a958C7f9533EE06A51B09d4BF561DA775
  );
    
  receive() external payable {}
  
  function settleEther() external {
    (bool ok,) = _TRADE_RESERVE.call{
      value: address(this).balance
    }("");

    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }
  
  function settleERC20(IERC20 token) external {
    bool ok = token.transfer(
      _TRADE_RESERVE, token.balanceOf(address(this))
    );
    
    require(ok, "Token transfer failed.");
  }
}