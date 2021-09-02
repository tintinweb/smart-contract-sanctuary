/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.8.3;
// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: GPL-3.0

library Balances {
    function move(mapping(address => uint256) storage balances, address from, address to, uint amount) internal {
        require(balances[from] >= amount);
        require(balances[to] + amount >= balances[to]);
        balances[from] -= amount;
        balances[to] += amount;
    }
}

contract Token {
    mapping(address => uint256) balances;
    using Balances for *;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 totalSupply;
    string id;
    address issuer;

    event Transfer(address from, address to, uint amount);
    event Approval(address owner, address spender, uint amount);
    event Burn(string token_id, address indexed burner, uint256 value);
    event Mint(address indexed minter, uint256 value);
    
    constructor() {
        totalSupply = 10000;
        balances[msg.sender] = 10000;
        id = "EthToken";
        issuer = msg.sender;
    }
    
    function getTotalSupply() public view returns (uint256 total) {
        return totalSupply;
    }
    
    function getTokenId() public view returns (string memory token_id) {
        return id;
    }
    
    function setTokenId(string memory token_id) public returns (bool success) {
        id = token_id;
        
        return true;
    }   

    function transfer(address to, uint amount) public returns (bool success) {
        balances.move(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;

    }

    function transferFrom(address from, address to, uint amount) public returns (bool success) {
        require(allowed[from][msg.sender] >= amount);
        allowed[from][msg.sender] -= amount;
        balances.move(from, to, amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(allowed[msg.sender][spender] == 0, "");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }
    
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who] - _value;
        totalSupply = totalSupply - _value;
        emit Burn(id, _who, _value);
        emit Transfer(_who, address(0), _value);
    }
    
    function mint(uint256 _value) public {
        _mint(msg.sender, _value);
    }
    
    function _mint(address _who, uint256 _value) internal {
        require(_who == issuer);
        balances[_who] = balances[_who] + _value;
        totalSupply = totalSupply + _value;
        emit Mint(_who, _value);
    }
}

// contract BurnableToken is BasicToken {
//     event Burn(address indexed burner, uint256 value);
    
//     function burn(uint256 _value) public {
//         _burn(msg.sender, _value);
//     }
    
//     function _burn(address _who, uint256 _value) internal {
//         require(_value <= balances[_who]);
//         balances[_who] = balances[_who].sub(_value);
//         totalSupply_ = totalSupply_.sub(_value);
//         emit Burn(_who, _value);
//         emit Transfer(_who, address(0), _value);
//     }
// }