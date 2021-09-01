/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

pragma solidity 0.8.7;

//SPDX-License-Identifier: MIT

contract MyToken {

    string public constant name = "MyToken";
    string public constant symbol = "MTN";
    uint8 public constant decimals = 18;
    address private deployer;

    mapping (address => uint) private balances;
    mapping (address => mapping (address => uint)) private allowances;
    mapping (address => bool) private isBanned;
    mapping (address => bool) private isAuthorized;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Authorization(address indexed account, bool indexed status);
    event Ban(address account, bool status);

    constructor() {
        deployer = msg.sender;
        isAuthorized[deployer] = true;
        balances[msg.sender] = 100000000000000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == deployer, "Only the owner may execute this function.");
        _;
    }

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "You are not authorized.");
        _;
    }

    modifier notBanned() {
        require(isBanned[msg.sender] == false);
        _;
    }

    function totalSupply() public pure returns (uint) {
        return 100000000000000000000; // 100 Tokens
    }

    function balanceOf(address account) public view returns (uint) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) notBanned public returns (bool) {
        if (amount >= 0 && balances[msg.sender] >= amount) {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
            emit Transfer(msg.sender, recipient, amount);
            return true;
        }
        return false;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) notBanned public returns (bool) {
        if (amount >= 0) {
            allowances[msg.sender][spender] = amount;
            emit Approval(msg.sender, spender, amount);
            return true;
        }
        return false;
    }

    function transferFrom(address sender, address recipient, uint256 amount) notBanned public returns (bool) {
        if (amount >= 0 && allowances[sender][msg.sender] >= amount && balances[sender] >= amount && isBanned[sender] == false) {
            allowances[sender][msg.sender] -= amount;
            balances[sender] -= amount;
            balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
            return true;
        }
        return false;
    }

    function authorize(address account) onlyOwner public {
        isAuthorized[account] = true;
    }

    function removeAuthorization(address account) onlyOwner public {
        isAuthorized[account] = false;
    }

    function ban(address account) onlyAuthorized public {
        isBanned[account] = true;
        emit Ban(account, true);
    }

    function unBan(address account) onlyAuthorized public {
        isBanned[account] = false;
        emit Ban(account, false);
    }
}