/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// sender.sol

pragma solidity ^0.5.11;

contract IStateSender {
  function syncState(address receiver, bytes calldata data) external;
  function register(address sender, address receiver) public;
}

//sender contract address on goerli=0xd9014fc9b4349ec2f77897864896ad293240e73e
contract sender {
  address public stateSenderContract = 0xEAa852323826C71cd7920C3b4c007184234c3945;
  address public receiver = 0xf1e0b9D20b92DA41D0c99B54Fc9E138494cE4D80;
  
  uint public states = 0;

  function sendState(bytes calldata data) external {
    states = states + 1 ;
    IStateSender(stateSenderContract).syncState(receiver, data);
  }
  
}