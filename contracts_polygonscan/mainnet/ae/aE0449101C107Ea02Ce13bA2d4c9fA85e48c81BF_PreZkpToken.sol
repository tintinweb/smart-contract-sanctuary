// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract PreZkpToken {
    string public constant name = "PreZKP token";
    string public constant symbol = "PreZKP";
    uint8 public constant decimals = 18;

    address public immutable MINTER;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _minter) {
        require(address(_minter) != address(0), "PreZKP:E1");
        MINTER = _minter;
    }

    function mint(address to, uint256 value) external {
        require(msg.sender == MINTER);
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }
}