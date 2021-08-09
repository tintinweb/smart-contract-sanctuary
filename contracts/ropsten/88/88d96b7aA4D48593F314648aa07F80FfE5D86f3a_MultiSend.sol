// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface ERC20Basic {
  function totalSupply() external view returns  (uint256);
  function balanceOf(address who) external view returns  (uint256);
  function transfer(address to, uint256 value) external view returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 is ERC20Basic {
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external view returns (bool);
  function approve(address spender, uint256 value) external view returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MultiSend {
  function multiSend(address _token, address[] memory addresses, uint amount) external {
    //address(_token).transfer(address(this), value);
    //ERC20 token = ERC20(_token);
    address token = address(_token);
    for(uint i = 0; i < addresses.length; i++) {
      //require(token.transferFrom(msg.sender, addresses[i], amount));
      token.call(abi.encodeWithSelector(0x23b872dd, msg.sender, addresses[i], amount));
    }
  }
  //function multiSendEth(address[] memory addresses) external {
  //  for(uint i = 0; i < addresses.length; i++) {
  //    addresses[i].transfer(msg.value / addresses.length);
  //  }
  //  msg.sender.transfer(this.balance);
  //}
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}