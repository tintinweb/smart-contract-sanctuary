/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.9;

interface IPancakePredictionV2 {
    function currentEpoch() external view returns(uint256);

    function betBear(uint256 epoch) external payable;

    function betBull(uint256 epoch) external payable;
    
    function claim(uint256[] calldata epochs) external;
}

contract PancakePredictionV2 is IPancakePredictionV2 {
    uint256 public currentEpoch = 100;
    
    function betBear(uint256) external payable {}

    function betBull(uint256) external payable {}
 
    function claim(uint256[] calldata epochs) external {}   
}

contract Bid {
    
    address owner;
    address pancake;
    
    constructor(address _pancake) {
        owner = msg.sender;
        pancake = _pancake;
    }
    
    function _currentEpoch() internal view returns(uint256) {
        return IPancakePredictionV2(pancake).currentEpoch();
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed.");
        _;
    }
    
    function withdraw() external onlyOwner {
        (bool success, ) = owner.call{value: _getBalance()}("");
        require(success, "Withdraw failed.");
    }
    
    function _getBalance() internal view returns(uint256) {
        return address(this).balance;
    }
    
    receive() external payable {}
}