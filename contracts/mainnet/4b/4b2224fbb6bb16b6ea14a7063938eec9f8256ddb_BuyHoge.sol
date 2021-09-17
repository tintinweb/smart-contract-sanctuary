/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

pragma solidity ^0.8.0;

contract BuyHoge {
  string constant _name = 'please ser';
  string constant _symbol = 'HOGE is good project';
  uint256 constant _amt = 69;
  address constant _hoge = 0xfAd45E47083e4607302aa43c65fB3106F1cd7607;

  function name() public pure returns (string memory) { return _name; }
  function symbol() public pure returns (string memory) { return _symbol; }
  function decimals() public pure returns (uint8) { return 0; }
  function totalSupply() public pure returns (uint256) { return _amt; }
  function balanceOf(address account) public pure returns (uint256) { 
    return _amt;
  }
  function sendTo(address to) external {
    emit Transfer(_hoge, to, _amt);
  }
  event Transfer(address indexed from, address indexed to, uint256 value);
}