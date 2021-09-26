/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;



// Part: FlexClient

contract FlexClient {
  address owner;
  uint256 principalAmount; //In Wei

  constructor(address _owner) {
    owner = _owner;
  }

  function deposit(address _requestSender) payable public {
    require(_requestSender == owner);
    principalAmount += msg.value;
  }

  function withdraw(address _requestSender) payable public {
    require(_requestSender == owner);
    payable(_requestSender).transfer(address(this).balance);
    principalAmount = 0;
  }
}

// File: FlexMain.sol

contract FlexMain {
mapping(address => FlexClient) public ownerAccountToContractAccount;
address public owner;
   FlexClient[] public clients;

  constructor() {
    owner = msg.sender;
  }

  function deposit() payable external returns (FlexClient) {
    FlexClient client;
    if (clientExists(ownerAccountToContractAccount[msg.sender])) {
      client = FlexClient(address(ownerAccountToContractAccount[msg.sender]));
      clients.push(client);
    } else {
      client = new FlexClient(msg.sender);
      ownerAccountToContractAccount[msg.sender] = client;
    }
    client.deposit{value: msg.value}(msg.sender);
    return client;
  }

  function withdraw() payable external {
    require(clientExists(ownerAccountToContractAccount[msg.sender]));
    FlexClient client = FlexClient(address(ownerAccountToContractAccount[msg.sender]));
    address clientAddress = address(client);
    require(clientAddress.balance > 0);
    client.withdraw(msg.sender);
  }

  function clientExists(FlexClient _client) private pure returns (bool) {
    if (address(_client) == address(0x0)) {
      return false;
    }
    return true;
  }
}