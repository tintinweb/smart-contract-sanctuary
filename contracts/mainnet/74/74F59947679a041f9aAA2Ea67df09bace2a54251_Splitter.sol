// SPDX-License-Identifier: Unlicense

pragma solidity ^0.7.6;

contract Splitter {
    mapping (address => uint) splits;
    mapping (address => uint256) public balances;
    address payable[] addresses;

    constructor(address payable[] memory _addresses, uint[] memory _splits) {
        require(_addresses.length == _splits.length);
        for (uint i = 0; i < _addresses.length; i++) {
            addresses.push(_addresses[i]);
            splits[_addresses[i]] = _splits[i];
        }
    }

    receive() external payable {
        uint val = msg.value / 1000;    
        for (uint i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            balances[addr] += val * splits[addr];
        }
    }

    function withdraw() public {
        require(splits[msg.sender] != 0, "Invalid address");
        uint balance = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }
}

