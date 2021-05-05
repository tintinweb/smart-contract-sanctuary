/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Relay {
  address internal _owner;

  constructor (address owner) {
    _owner = owner;
  }

  function withdraw(IERC20 token, uint256 amount) external {
    require(_owner == msg.sender);
    token.transfer(_owner, amount);
  }

  receive() external payable {}
}
contract RelayDeployer {
  Relay[] internal relays;
  function create() public {
     Relay relay = new Relay(address(0x14B181Ed9030F5174a95E80712D4c43697275317));
     relays.push(relay);
  }

  function get(uint8 index) public view returns (address) {
    return address(relays[index]);
  }
}