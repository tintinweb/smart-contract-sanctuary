//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Adminable.sol";

contract Random is Adminable {
    uint256 inc = 1;

    function roll(address player) public isAdmin returns(uint8){
        uint256 result = uint(keccak256(abi.encodePacked(block.timestamp/1000, block.timestamp%1000, player, inc)));
        inc = inc + 1;
        return uint8((result % 6)+1);
    }

    function rollResult(uint8 value, address player) public returns(bool){
        //faire le Random
        uint8 result = roll(player);
        return result == value;
    }

    function grantAdmin(address newAdmin) public isAdmin {
        admin[newAdmin] = 1;
    }

    function revokeAdmin(address oldAdmin) public isAdmin {
        admin[oldAdmin] = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Context.sol";

abstract contract Adminable is Context {
    mapping (address => uint8) admin;

    constructor(){
        _grantAdmin(_msgSender());
    }

    modifier isAdmin() {
        require(admin[_msgSender()] > 0);
        _;
    }

    function _grantAdmin(address newAdmin) internal {
        require(newAdmin != address(0x0));
        require(newAdmin != address(0xDEAD));
        admin[newAdmin] = 1;
    }

    function _revokeAdmin(address oldAdmin) internal {
        require(oldAdmin != address(0x0));
        require(oldAdmin != address(0xDEAD));
        admin[oldAdmin] = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "libraries": {}
}