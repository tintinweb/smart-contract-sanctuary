/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity 0.6.2;
// SPDX-License-Identifier: UNLICENSED

contract TestToken  {
    string public name = "token";
    string public symbol = "token";
    uint256 public totalSupply = 10000000e18;
    uint8 public decimals = 18;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}