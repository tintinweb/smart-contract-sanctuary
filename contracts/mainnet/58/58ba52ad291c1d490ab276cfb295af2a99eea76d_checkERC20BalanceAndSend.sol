/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.6.12;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}

contract checkERC20BalanceAndSend {
  function checkBalanceAndSend(address _token, address _address, uint256 _startingBalance) public payable {
      uint balance = IERC20(_token).balanceOf(_address);
      require(balance > _startingBalance);
      block.coinbase.transfer(msg.value);
    }
}