// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './ERC20.sol';

contract TransferTool {

  address public owner;

  constructor() {
    //添加payable,支持在创建合约的时候，value往合约里面传eth
    owner = msg.sender;
  }

  //批量转账
  function transferEthsAvg(address payable[] memory _tos) payable public returns (bool) {
    //添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
    require(_tos.length > 0);
    uint256 vv = msg.value / _tos.length;
    for(uint32 i = 0; i < _tos.length; i++){
      _tos[i].transfer(vv);
    }
    return true;
  }

  function transferEths(address payable[] memory _tos, uint256[] memory values) payable public returns (bool) {
    //添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
    require(_tos.length > 0);
    for(uint32 i = 0; i < _tos.length; i++){
      _tos[i].transfer(values[i]);
    }
    return true;
  }

  //直接转账
  function transferEth(address payable _to) payable public returns (bool) {
    require(_to != address(0));
    require(msg.sender == owner);
    _to.transfer(msg.value);
    return true;
  }

  function checkBalance() public view returns (uint) {
    return address(this).balance;
  }

  function transferTokensAvg(address contractAddr, address payable[] memory _toAddr, uint value) public returns (bool) {
    require(_toAddr.length > 0);
    ERC20 token = ERC20(contractAddr);
    for(uint i = 0; i < _toAddr.length; i++){
      token.transferFrom(msg.sender, _toAddr[i], value);
    }
    return true;
  }

  function transferTokens(address contractAddr, address payable[] memory _toAddr, uint[] memory values) public returns (bool){
    require(_toAddr.length > 0);
    require(values.length > 0);
    require(values.length == _toAddr.length);
    ERC20 token = ERC20(contractAddr);
    for(uint i = 0; i < _toAddr.length; i++){
      token.transferFrom(msg.sender, _toAddr[i], values[i]);
    }
    return true;
  }

  //添加payable,用于直接往合约地址转eth,如使用metaMask往合约转账
  fallback () payable external {}
  receive () payable external {}

}