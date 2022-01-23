/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.11;

contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint value);
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint);
}

contract owned {

    address public owner;

    function owned() payable {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        owner = _owner;
    }
}
contract Crowdsale is owned {

    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function Crowdsale() payable owned() {
        totalSupply = 25000000;
        balanceOf[this] = 24000000;
        balanceOf[owner] = totalSupply - balanceOf[this];
        Transfer(this, owner, balanceOf[owner]);
    }

    function () payable {
        require(balanceOf[this] > 0);
        uint256 tokens = 5000 * msg.value / 1000000000000000000;
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint valueWei = tokens * 1000000000000000000 / 5000;
            msg.sender.transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender,tokens);
    }
}

contract Token is Crowdsale {
    string public standard = 'Token 0.1';
    string public name     = 'LNZtoken';
    string public symbol   = 'LNZ';
    uint8  public decimals = 0;

    function Token() payable Crowdsale() {}

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
}

contract MyContract is Token {

    function MyContract() payable Token() {}

    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }

    function killMe() public onlyOwner {
        selfdestruct(owner);
    }
}