/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ElonStake {
    using SafeMath for uint256;

    IBEP20 StakingToken;

    mapping(address => uint256) stakingValues;

    constructor(address _tokenAddress) {
        StakingToken = IBEP20(_tokenAddress);
    }

    function stake(uint256 _amount) public {
        uint256 allowance = StakingToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        uint256 balanceOfAddress = stakingValues[msg.sender];
        StakingToken.transferFrom(msg.sender, address(this), _amount);
        stakingValues[msg.sender] = balanceOfAddress.add(_amount);
    }

    function unstake(uint256 _amount) public {
        uint256 balanceOfAddress = stakingValues[msg.sender];
        require(balanceOfAddress >= _amount, "Amount exceeds staked balance");
        StakingToken.transfer(msg.sender, _amount);
        stakingValues[msg.sender] = balanceOfAddress.sub(_amount);
    }

    function setStakingToken(address _tokenAddress) public {
        StakingToken = IBEP20(_tokenAddress);
    }

    function getStakingValue(address _address) public view returns(uint256) {
        return stakingValues[_address];
    }
}