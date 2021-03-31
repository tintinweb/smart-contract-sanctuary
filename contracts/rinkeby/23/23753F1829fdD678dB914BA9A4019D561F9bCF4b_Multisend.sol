// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Multisend {
    address private owner;
    IERC20 private token;

    constructor (address tokenAddress) {
        owner = msg.sender;
        token = IERC20(tokenAddress);
    }

    function convertAddressToBinaryData(address[] calldata addresses) external pure returns(bytes memory) {
        bytes memory data = new bytes(0);
        uint256 length = addresses.length;
        for (uint256 i = 0; i < length; ++i) {
            data = abi.encodePacked(data, addresses[i]);
        }
        return data;
    }

    function convertAmountsToBinaryData(uint256[] calldata amounts) external pure returns(bytes memory) {
        bytes memory data = new bytes(0);
        uint256 length = amounts.length;
        for (uint256 i = 0; i < length; ++i) {
            data = abi.encodePacked(data, amounts[i]);
        }
        return data;
    }

    function multisend(address[] calldata addresses, uint256[] calldata amounts) external {
        require(owner == msg.sender, "!Owner");
        uint256 length = addresses.length;
        for (uint256 i = 0; i < length; ++i) {
            token.transfer(addresses[i], amounts[i]);
        }
    }

    function multisendBinary(bytes calldata addresses, bytes calldata amounts, uint256 length) external {
        require(owner == msg.sender, "!Owner");
        uint256 _length = length;
        bytes memory _addresses = addresses;
        bytes memory _amounts = amounts;
        address _address;
        uint256 _amount;
        for (uint256 i = 0; i < _length; ++i) {
            (_address, _addresses) = abi.decode(_addresses, (address, bytes));
            (_amount, _amounts) = abi.decode(_amounts, (uint256, bytes));
            token.transfer(_address, _amount);
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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