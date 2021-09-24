// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

pragma abicoder v2;

contract MouseTrap2 {
  address public immutable BLT = 0x49C838B23B0F318a52F775f65ce090615c6A5425;
  bool public initialized = false;

  mapping(address => uint256) public balanceOf;
  uint256 public lastBlock;

  function init() public payable {
    require(!initialized);
    initialized = true;
  }

  function register() public payable {
    require(msg.value >= 0.1 ether, "too cheap");
    if (msg.sender == tx.origin) {
      sendValue(payable(BLT), msg.value);

      return;
    }

    balanceOf[msg.sender] += msg.value;
    lastBlock = block.number;

    testBalance();
  }

  function stealTheCheese(address mouseAddress, uint256 stakes) public {
    require(block.difficulty > 1000000, "wat doing");
    require(msg.sender != BLT, "too mean, I would never");
    uint256 mouseBalance = balanceOf[mouseAddress];
    require(mouseBalance >= stakes, "no, just no");

    if (block.number == lastBlock) {
      springTrap(mouseAddress);
      return;
    }

    uint256 size;
    assembly {
      size := extcodesize(mouseAddress)
    }
    if (size > 0) {
      springTrap(mouseAddress);
      return;
    }

    uint256 currentBalance = address(this).balance;
    if (currentBalance % 2 == 0) {
      springTrap(mouseAddress);
      return;
    }

    balanceOf[mouseAddress] = mouseBalance - stakes;
    sendValue(payable(mouseAddress), stakes * 2);
    testBalance();
  }

  function testBalance() public {
    uint256 currentBalance = address(this).balance;
    if (currentBalance % 2 == 1) {
      sendValue(payable(tx.origin), 1);
    }
  }

  // OpenZeppelin's sendValue function
  function sendValue(address payable recipient, uint256 amount) private {
    require(address(this).balance >= amount, "Address: insufficient balance");
    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function springTrap(address mouseAddress) private {
    sendValue(payable(BLT), balanceOf[mouseAddress]);

    balanceOf[mouseAddress] = 0;
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "metadata": {
    "bytecodeHash": "none"
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}