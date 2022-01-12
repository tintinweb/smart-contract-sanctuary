/**
 *Submitted for verification at polygonscan.com on 2022-01-12
*/

pragma solidity ^0.8.11;
//SPDX-License-Identifier: MIT

contract Dripper {
    address public owner;
    
    uint256 public start;
    uint256 public start_block;

    uint256 public unlock_per_second;
    uint256 public already_claimed;

    
    event Claim(address _token, uint256 _amount);
    
    constructor(address _admin) {
        owner = _admin;
        start = block.timestamp;
        unlock_per_second = 25351013290000000; // 3 months = 200k
    }

    function transferOwnership(address _new) external ownerOnly {
        owner = _new;
    }
    
    modifier ownerOnly {
        require(msg.sender == owner, 'Restricted to owner');
        _;
    }
    
    function claim(address _token, uint256 _amount, bool _claim_all) public ownerOnly {
        ERC20 token = ERC20(_token);
        uint256 time_since_start = block.timestamp - start;
        uint256 total_allowed_to_claim = time_since_start * unlock_per_second;
        
        if (_claim_all){
            _amount = total_allowed_to_claim - already_claimed;
            uint256 balance = token.balanceOf(address(this));
            if (_amount > balance){
                _amount = balance;
            }
        }
        
        require(_amount <= (total_allowed_to_claim - already_claimed), "Claim less!");
        
        already_claimed += _amount;

        token.transfer(owner, _amount);
                
        emit Claim(_token, _amount);
    }
    
    function getAllowedAmount() public view returns (uint256) {
        uint256 time_since_start = block.timestamp - start;
        uint256 total_allowed_to_claim = time_since_start * unlock_per_second;
        return total_allowed_to_claim - already_claimed;
    }
}

interface ERC20 {
    function totalSupply() external;
    function balanceOf(address _owner) external returns (uint256);
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
    function allowance(address _owner, address _spender) external;
    function decimals() external;
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}