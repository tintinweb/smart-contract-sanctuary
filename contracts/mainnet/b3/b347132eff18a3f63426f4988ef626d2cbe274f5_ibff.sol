/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract ibff {
    string public constant name = "Iron Bank Fixed Forex";
    string public constant symbol = "ibff";
    uint8 public constant decimals = 18;
    
    address public gov;
    address public nextgov;
    uint public commitgov;
    uint public constant delay = 1 days;
    
    
    constructor() {
        gov = msg.sender;
    }
    
    modifier g() {
        require(msg.sender == gov);
        _;
    }
    
    function setGov(address _gov) external g {
        nextgov = _gov;
        commitgov = block.timestamp + delay;
    }
    
    function acceptGov() external {
        require(msg.sender == nextgov && commitgov < block.timestamp);
        gov = nextgov;
    }
    
    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;
    
    mapping(address => mapping (address => uint)) internal allowances;
    mapping(address => uint) internal balances;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    function mint(address dst, uint amount) external g {
        // mint the amount
        totalSupply += amount;
        // transfer the amount to the recipient
        balances[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }
    
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balances[src] -= amount;
        balances[dst] += amount;
        
        emit Transfer(src, dst, amount);
    }
}