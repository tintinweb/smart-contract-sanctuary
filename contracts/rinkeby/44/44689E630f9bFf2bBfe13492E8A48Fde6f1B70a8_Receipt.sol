// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Receipt {
  event Emmitance(string _adString);

  function sendAd(string memory _adString) external payable {
    require(msg.value > 0.01 ether, "Not enough for an ad");
    emit Emmitance(_adString);
  }
}

