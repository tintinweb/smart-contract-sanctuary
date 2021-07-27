/**
 *Submitted for verification at polygonscan.com on 2021-07-27
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IdQuick {
    function QUICKBalance(address _account) external view returns (uint256 quickAmount_);

}


interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

struct Contracts {
  IERC20 quickswap;
  IdQuick dragonLair;
}


contract QuickswapVoting {
  IERC20 constant public QUICKSWAP = IERC20(0x831753DD7087CaC61aB5644b308642cc1c33Dc13);
  IdQuick constant public DRAGONLAIR = IdQuick(0xf28164A485B0B2C90639E47b0f377b4a438a16B1);

  function balanceOf(address _owner) external view returns (uint256 balance_) {
    balance_ = QUICKSWAP.balanceOf(_owner) + DRAGONLAIR.QUICKBalance(_owner);
  }
 
}