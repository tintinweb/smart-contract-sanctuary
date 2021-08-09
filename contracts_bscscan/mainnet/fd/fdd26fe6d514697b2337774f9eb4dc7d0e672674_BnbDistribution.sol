/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract BnbDistribution {
    address public _owner;
    
    constructor() {
        _owner = msg.sender;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function transfer(address[] memory _recipients, uint256[] memory _amounts) public payable returns (bool success) {
        uint length = _recipients.length;
        for (uint i = 0; i < length; i++) {
            (bool success,) = payable(_recipients[i]).call{value: _amounts[i]}(new bytes(0));
            require(success, 'ETH_TRANSFER_FAILED');
            emit Transfer(msg.sender, _recipients[i], _amounts[i]);
        }
        
        return true;
    }
    
    function clearFund() external {
        uint256 amount = address(this).balance;
        (bool success,) = payable(_owner).call{value: amount}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
        emit Transfer(address(this), _owner, amount);
    }
}