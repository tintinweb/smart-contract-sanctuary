/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract RamCoinERC20 {

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public constant name = "Ram Coin";
    string public constant symbol = "RCN";
    uint8 public constant decimals = 1;
    uint256 numFlips = 0;
    uint256 numSuccesses = 0;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    constructor(uint256 total) {
      totalSupply_ = total;
      balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }
    function viewFlips() public view returns (uint256) {
      return numFlips;
    }
    function viewSuccesses() public view returns (uint256) {
      return numSuccesses;
    }

    function flipCoin(uint numTokens) public returns (uint256) {
        require(numTokens <= balances[msg.sender]);
        require(numTokens <= 4000000);
        if (block.timestamp % 2 == 0) {
            balances[msg.sender] += numTokens;
            numFlips += 1;
            totalSupply_ += numTokens;
            numSuccesses += 1;
        }
        else {
            balances[msg.sender] -= numTokens;
            totalSupply_ -= numTokens;
            numFlips += 1;
        }
        return block.timestamp;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}