/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

pragma solidity ^0.8.2;
//SPDX-License-Identifier: MIT

contract Timelock {
    address public owner;
    
    uint256 public start;
    uint256 public start_block;

    uint256 public unlock_per_second;
    uint256 public already_claimed;

    
    event Claim(address _token, uint256 _amount);
    
    constructor(address _owner) {
        owner = _owner;
        start = 1630425851; //Tue Aug 31 2021 16:04:11 GMT
        unlock_per_second = 16900674482700000000; //6 months = 15,778,463 seconds, 266,666,667 tokens = 16.9/second
    }
    
    function transferOwnership(address _newOwner) external ownerOnly {
        owner = _newOwner;
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