// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;


contract FreeMoneyBox {

    address private moneybox = 0xA2eb9BfF23f5117979767bD0c51BE8E2F7Fbf52F;
    address private free = 0x1cc1bD553dF7f45F697a85Cac7a121c0A7E2e1C4;
    address private owner;

    constructor(){
        owner = msg.sender;
    }

    function setMoneyBox(address _moneybox) public {
        require(msg.sender == owner, 'Only Owner can change MoneyBox');
        moneybox = _moneybox;
    }

    function getMoneyBox() public view returns (address) {
        return moneybox;
    }


    function setFree(address _free) public {
        require(msg.sender == owner, 'Only Owner can change Free');
        free = _free;
    }

    function getFree() public view returns (address) {
        return free;
    }

    function setOwner(address _owner) public {
        require(msg.sender == owner, 'Only Owner can change Owner');
        owner = _owner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
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