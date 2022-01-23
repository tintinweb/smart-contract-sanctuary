// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

contract Token {
    address private owner;

    string public constant name = "MyToken";

    uint256 private totalSupply;

    mapping(address => uint256) private balances;

    constructor(uint256 _totalSupply) {
        owner = msg.sender;
        totalSupply = _totalSupply;
        balances[owner] += totalSupply;
    }

    function transfer(uint256 _amount, address _to) external {
        require(balances[msg.sender] >= _amount, "Insufficient funds");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    function balanceOf(address _address)
        external
        view
        returns (uint256 result)
    {
        result = balances[_address];
    }

    function getTotalSupply() external view returns (uint256 _totalSupply) {
        _totalSupply = totalSupply;
    }
}