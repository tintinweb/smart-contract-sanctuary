/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  enum HowToCall { Call, DelegateCall }
  function proxy(address dest, HowToCall howToCall, bytes memory _calldata) public returns (bool result,bytes memory returndata)
  {
      if (howToCall == HowToCall.Call) {
          (result,returndata) = dest.call(_calldata);
      } else if (howToCall == HowToCall.DelegateCall) {
          (result,returndata) = dest.delegatecall(_calldata);
      }
  }

  function proxyDelegateCall(address dest,string memory _method,address _to,uint _amount) public returns (bool result,bytes memory returndata)
  {
      (result,returndata) = dest.delegatecall(abi.encodeWithSignature(_method, _to, _amount));
  }

  function proxyCall(address dest,string memory _method,address _to,uint _amount) public returns (bool result,bytes memory returndata)
  {
      (result,returndata) = dest.call(abi.encodeWithSignature(_method, _to, _amount));
  }
}