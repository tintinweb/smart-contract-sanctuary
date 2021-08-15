/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract Date{
    address public admin;
    address public token;
    
    address public dater1;
    address public dater2;
    address public merchant;
    uint256 public datetime;
    uint256 public stake;
    
    string public merchant_name;
    bool public isBooked;
    bool public isDater1Arrived;
    bool public isDater2Arrived;
    bool public isDateSuccess;
    
    mapping(address => uint256) private _balances;
    
    constructor (address _token, address _dater1, address _dater2, address _merchant, uint256 _datetime, string memory _merchant_name, uint256 _stake) {
        token = _token;
        admin = msg.sender;
        
        dater1 = _dater1;
        dater2 = _dater2;
        merchant = _merchant;
        datetime = _datetime;
        merchant_name = _merchant_name;
        stake = _stake;
        
        isBooked = false;
        isDater1Arrived = false;
        isDater2Arrived = false;
        isDateSuccess = false;
    }
    
    function deposit(uint256 amount) public {
        require(stake == amount, "Amount need to be the same as the agreed stake amount");
        uint256 balance = IERC20(token).balanceOf(address(msg.sender));
        require(balance >= amount, "INSUFFICIENT TOKEN IN WALLET");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _balances[msg.sender] += amount;
    }
    
    function bothHaveStaked() public view returns (bool) {
        require(msg.sender == dater1 || msg.sender == dater2 || msg.sender == merchant, "Only daters specified in this contract or merchant can check stake status");
        return (_balances[dater1] == stake && _balances[dater2] == stake);
    }
    
    function balanceOfPool(address user) public view returns (uint256 amount) {
        return _balances[user];
    }
    
    function hasStaked() public view returns (bool) {
        require(msg.sender == dater1 || msg.sender == dater2, "Only daters specified in this contract can check date");
        return _balances[msg.sender] == stake;
    }

    function confirmBooking() public {
        require(msg.sender == merchant, "No permission to confirm booking");
        require(bothHaveStaked(), "Daters have not staked their share");
        isBooked = true;
    }

    function cancelBooking() public {
        require(msg.sender == dater1 || msg.sender == dater2 || msg.sender == merchant, "Only daters specified in this contract or merchant can cancel booking");
        require(isBooked == true && block.timestamp < datetime - 86400, "Cannot cancel booking within 1 day of the date");
        _unlockTokens();
        isBooked = false;
    }

    function confirmArrival(address _dater) public {
        require(msg.sender == merchant, "No permission to confirm booking");
        require(block.timestamp > datetime && block.timestamp < datetime + 7200, "Can only confirm arrival within 2 hours of the date");
        require(_dater == dater1 || _dater == dater2, "Can only confirm arrival for registered daters");
        if (_dater == dater1){
            isDater1Arrived = true;
        }
        if (_dater == dater2){
            isDater2Arrived = true;
        }
        if (isDater1Arrived && isDater2Arrived) {
            isDateSuccess = true;
            _unlockTokens();
        }
    }
    
    function claimCompensation() public {
        require(msg.sender == dater1 && isDater1Arrived && !isDater2Arrived || msg.sender == dater2 && isDater2Arrived && !isDater1Arrived);
        require(block.timestamp > datetime + 7200, "Can only claim compensation after 2 hours of the date");
        _compensate(msg.sender);
    }

    function _compensate(address dater) private {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(dater, balance);
        _balances[dater1] = 0;
        _balances[dater2] = 0;
        _balances[merchant] = 0;
    }

    function _unlockTokens() private {
        IERC20(token).transfer(dater1, _balances[dater1]);
        IERC20(token).transfer(dater2, _balances[dater2]);
        IERC20(token).transfer(merchant, _balances[merchant]);
        _balances[dater1] = 0;
        _balances[dater2] = 0;
        _balances[merchant] = 0;
    }
    
}