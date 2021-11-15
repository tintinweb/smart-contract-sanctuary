/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/L1/Gerald.sol

pragma solidity ^0.8.0;

interface IStarknetCore {
  // Sends a message to an L2 contract.
  // Returns the hash of the message.
  function sendMessageToL2(
    uint256 to_address,
    uint256 selector,
    uint256[] calldata payload
  ) external returns (bytes32);

  // Consumes a message that was sent from an L2 contract.
  // Returns the hash of the message.
  function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
    external
    returns (bytes32);
}

contract Gerald {
  // The StarkNet core contract.
  IStarknetCore public starknetCore;

  uint256 public l2ContractAddress;

  mapping(address => uint256) public balances;

  mapping(address => uint256) public starkKeys;

  mapping(uint256 => address) public starkKeyAddresses;

  uint256 constant DEPOSIT_SELECTOR =
    352040181584456735608515580760888541466059565068553383579463728554843487745;

  constructor(IStarknetCore _starknetCore) public {
    starknetCore = _starknetCore;
  }

  function setStarknetCore(IStarknetCore _starknetCore) public {
    starknetCore = _starknetCore;
  }

  function setL2ContractAddress(uint256 _l2ContractAddress) public {
    l2ContractAddress = _l2ContractAddress;
  }

  function mint(uint256 amount) public {
    uint256 balance = balances[msg.sender];
    balances[msg.sender] = balance + amount;
  }

  function claimStartKey(uint256 starkKey) public {
    require(
      starkKeyAddresses[starkKey] == address(0),
      "setStartKey: already claimed"
    );
    starkKeys[msg.sender] = starkKey;
    starkKeyAddresses[starkKey] = msg.sender;
  }

  function deposit(uint256 amount) public {
    uint256 balance = balances[msg.sender];
    require(balance >= amount, "deposit: not enough balance");
    uint256 starkKey = starkKeys[msg.sender];
    require(starkKey != 0, "deposit: no stark key set");

    balances[msg.sender] -= amount;

    uint256[] memory payload = new uint256[](2);
    payload[0] = starkKey;
    payload[1] = amount;

    starknetCore.sendMessageToL2(l2ContractAddress, DEPOSIT_SELECTOR, payload);
  }
}