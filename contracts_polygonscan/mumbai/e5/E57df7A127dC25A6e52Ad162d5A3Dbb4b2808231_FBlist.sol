// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract FBlist {
    address public admin;
    address[] public list;
    constructor() {
        admin = msg.sender;
    }

    function addlist(address addr) external {
        require(msg.sender == admin, "!admin");
        list.push(addr);
    }

    function getlist()public view returns( address  [] memory){
        return list;
    }

    function removelist(address addr) external {
        require(msg.sender == admin, "!admin");
        uint p = list.length;
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == addr) {
                p = i;
            }
        }
        if (p < list.length) {
            for (uint i = p; i < list.length - 1; i++) {
                list[i] = list[i + 1];
            }
        }
        delete list[list.length - 1];
    }

    function getCountList() external view returns(uint) {
        return list.length;
    }

    function inlist(address addr) external view returns(uint){
        uint p = list.length;
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == addr) {
                p = i;
            }
        }
        if (p < list.length) {
            return 1;
        }
        return 0;
    }

    function setAdmin(address addr) public {
        require(msg.sender == admin, "!admin");
        admin = addr;
    }
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