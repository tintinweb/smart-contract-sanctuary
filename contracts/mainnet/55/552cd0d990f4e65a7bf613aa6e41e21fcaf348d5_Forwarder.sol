/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity 0.4.14;

contract ERC20Interface {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

/**
 * Contract that will forward any incoming Ether to its creator
 */
contract Forwarder {
  address public parentAddress;
  event ForwarderDeposited(address from, uint value, bytes data);

  event TokensFlushed(
    address tokenContractAddress,
    uint value
  );


  function Forwarder() {
    parentAddress = msg.sender;
  }


  modifier onlyParent {
    if (msg.sender != parentAddress) {
      revert();
    }
    _;
  }

  function() payable {
    if (!parentAddress.call.value(msg.value)(msg.data))
      revert();
    ForwarderDeposited(msg.sender, msg.value, msg.data);
  }

  function flushTokens(address tokenContractAddress) onlyParent {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    var forwarderAddress = address(this);
    var forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    if (!instance.transfer(parentAddress, forwarderBalance)) {
      revert();
    }
    TokensFlushed(tokenContractAddress, forwarderBalance);
  }

  function flush() {
    if (!parentAddress.call.value(this.balance)())
      revert();
  }
}