/**
 *Submitted for verification at polygonscan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Bounty {

    mapping(address => uint256) private _accountValue;
    uint256 private _requiredDeposit;

    address private _owner;

    constructor() {
        _owner = msg.sender;
        _requiredDeposit = 5 ether;
    }

    function accountValue(address account) external view returns (uint256) {
        return _accountValue[account];
    }

    function kill(address killer, address killed) external {
        require(msg.sender == _owner, "!Permission");
        uint256 gotBounty = _accountValue[killed];
        uint256 fee = gotBounty / 5;
        _accountValue[killed] = 0;
        payable(_owner).transfer(fee);        
        payable(killer).transfer(gotBounty-fee);
    }

    function recoverDeposit(address account) external {
        require(msg.sender == _owner, "!Permission");
        uint256 amount = _accountValue[account];
        _accountValue[account] = 0;
        payable(account).transfer(amount);
    }

    function newRequiredDeposit(uint256 amount) external {
        require(msg.sender == _owner, "!Permission");
        _requiredDeposit = amount;
    }

    function newOwner(address _newOwner) external {
        require(msg.sender == _owner, "!Permission");
        _owner = _newOwner;
    }

    function deposit() external payable {
        require(_accountValue[msg.sender]+msg.value == _requiredDeposit, "Wrong deposit amount");
        _accountValue[msg.sender] += msg.value;
    }

    function canPlay(address account) external view returns (bool) {
        if (_accountValue[account] == 0) return false;
        if (_accountValue[account] - _requiredDeposit >= 0) {
           return true; 
        } else return false;
    }

    function requiredDeposit() external view returns (uint256) {
        return _requiredDeposit;
    }

    function owner() external view returns (address) {
        return _owner;
    }
}