/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity >=0.6.0 <0.8.0;

abstract contract ERC20 {
  function transfer(address _recipient, uint256 _value) public virtual returns (bool success);
}

contract Airdrop {
  function drop(ERC20 token, address[] memory recipients, uint256[] memory values) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      token.transfer(recipients[i], values[i]);
    }
  }
  
  function getBlocknum() public view returns (uint256 number) {
      return block.number;
  }
  
  function getTimestamp() public view returns (uint256 timestamp) {
      return block.timestamp;
  }
}