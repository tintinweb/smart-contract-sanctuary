// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

contract VoteBox {

    event NewAdmin(address indexed newAdmin);
    event Success();
    event Reset();

    address public admin;

    bool public success = false;

    constructor(address admin_) public {
        admin = admin_;
    }

    function setAdmin(address admin_) public {
        require(msg.sender == admin, "VoteBox::setAdmin: Call must come from admin.");
        admin = admin_;

        emit NewAdmin(admin);
    }

    function setSuccess() public {
        require(msg.sender == admin, "VoteBox::setAdmin: Call must come from admin.");
        success = true;

        emit Success();
    }

    function reset() public {
        require(msg.sender == admin, "VoteBox::setAdmin: Call must come from admin.");
        success = false;

        emit Reset();
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}