/**
 *Submitted for verification at Etherscan.io on 2020-09-06
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: UNLICENSED

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract LuckySwapPoolNames is Ownable {
    mapping(uint256 => string) public logos;
    mapping(uint256 => string) public names;
    
    constructor() public {
        logos[0] = '🐢'; names[0] = 'Tether Turtle';
        logos[1] = '🐌'; names[1] = 'Circle Snail';
        logos[2] = '🦆'; names[2] = 'Donald DAI';
        logos[3] = '🦍'; names[3] = 'Spartan Dollar';
        logos[4] = '🍄'; names[4] = 'Compound Truffle';
        logos[5] = '🐗'; names[5] = 'Aave Boar';
        logos[6] = '🐍'; names[6] = 'Synthetic Snake';
        logos[7] = '🦑'; names[7] = 'Umami Squid';
        logos[8] = '🐸'; names[8] = 'Toadie Marine';
        logos[9] = '🦖'; names[9] = 'Band-osaurus';
        logos[10] = '🐥'; names[10] = 'Ample Chicks';
        logos[11] = '🐋'; names[11] = 'YFI Whale';
        logos[12] = '🍀'; names[12] = 'Lucky Clover!';
        logos[13] = '🦏'; names[13] = 'REN Rhino';
        logos[14] = '🐂'; names[14] = 'BASED Bull';
        logos[15] = '🦈'; names[15] = 'SRM Shark';
        logos[16] = '🍠'; names[16] = 'YAMv2 Yam';
        logos[17] = '🐊'; names[17] = 'CRV Crocodile';
    }
    
    function setPoolInfo(uint256 pid, string memory logo, string memory name) public onlyOwner {
        logos[pid] = logo;
        names[pid] = name;
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
        "abi"
      ]
    }
  }
}