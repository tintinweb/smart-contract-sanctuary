/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity 0.8.4;

interface Router {
    function deposit(address payable vault, address asset, uint amount, string memory memo) external payable;
}

contract Emitter {
  event Deposit(address indexed to, address indexed asset, uint amount, string memo);
  function deposit(address payable vault, address asset, uint amount, string memory memo) external {
      Router(0xC145990E84155416144C532E31f89B840Ca8c2cE).deposit(vault, asset, 0, memo);
      emit Deposit(vault, asset, amount, memo);
  }
}