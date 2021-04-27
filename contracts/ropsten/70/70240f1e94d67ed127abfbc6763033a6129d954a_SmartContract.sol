/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SmartContract {
    string public name = "BlockchainToken";
    string public symbol = "BCT";
    uint8 public decimals = 0; // 1.002 => decimals = 3
    uint public totalSupply = 0;

    mapping(address => uint) balances;
    event Transfer(address indexed _from, address indexed _to, uint _value);
    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    fallback() external payable{
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }
    
    receive() external payable {
        // custom function code
    }
}