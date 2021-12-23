/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface WBNB{
    function deposit() external payable;
    function transfer(address receiver,uint256 _amount) external;
}

interface WNativeRelayer{
function withdraw(uint256 _amount) external;
}

contract Bank {
  WNativeRelayer wnative;

  WBNB wbnb;

  constructor(WNativeRelayer _wnative) {
    wnative = _wnative;
    wbnb = WBNB(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
  }


function deposit() public payable{
    wbnb.deposit{value:msg.value}();
    wbnb.transfer(address(wnative),msg.value);
}
  function withdraw(uint256 _amount) public {
    wnative.withdraw(_amount);
    (bool success, ) = msg.sender.call{value: _amount}("");
    require(success, "WNativeRelayer::onlyWhitelistedCaller:: can't withdraw");
  }

  receive() external payable {}
}