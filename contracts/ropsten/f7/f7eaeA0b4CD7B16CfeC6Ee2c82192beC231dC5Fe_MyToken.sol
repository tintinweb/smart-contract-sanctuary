/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balances;

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string  memory _tokenSymbol) {
        name = _tokenName;
        symbol = _tokenSymbol;
        decimals = _decimalUnits;
        totalSupply = _initialAmount;
        balances[msg.sender] = _initialAmount;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// 0x70a08231
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /// 0xa9059cbb
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "token balance is lower than the transfer value");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}