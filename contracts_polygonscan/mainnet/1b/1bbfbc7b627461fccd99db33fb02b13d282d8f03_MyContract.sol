/**
 *Submitted for verification at polygonscan.com on 2021-09-25
*/

pragma solidity >=0.8.7;

interface WethLike {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract MyContract {
  WethLike weth;

  constructor(WethLike weth_) {
    weth = weth_;
  }

  function foo() external payable {
    weth.deposit{ value: msg.value }();
  }
  
  receive() external payable {
      weth.deposit{value: msg.value}();
  }
  
   function selfDestruct() external {
        selfdestruct(payable(msg.sender));
    }
}