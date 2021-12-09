//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
//import "hardhat/console.sol";
contract Tycoon {
  event Tipped(address sender, address receiver, uint value);
  event Funded(address sender, address receiver, uint value, string msg);
  mapping (address => uint) public balance;
  // Fund an address => increases the balance
  function fund(address _receiver, string calldata str) external payable {
    balance[_receiver] += msg.value;
    emit Funded(msg.sender, _receiver, msg.value, str);
  }
  // Tip an address => does not change the balance. Insteaad direclty sends the money to the address
  function tip(address _receiver) external payable {
    (bool r, ) = payable(_receiver).call{value: msg.value}("");
    require(r, "E1");
    emit Tipped(msg.sender, _receiver, msg.value);
  }
  // Withdraw balance (only owner)
  function withdraw() external payable {
    uint _balance = balance[msg.sender];
    require(_balance > 0, "E2");
    (bool r2, ) = payable(msg.sender).call{value: _balance}("");
    require(r2, "E3");
  }
}