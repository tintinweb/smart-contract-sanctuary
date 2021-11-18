/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity ^0.5.0;


/**
 * @title SimpleTimelock
 * @dev SimpleTimelock is an ETH holder contract that will allow a
 * beneficiary to receive the ETH after a given release time.
 */
contract SimpleTimelock {

    // beneficiary of ETH after it is released
    address payable public beneficiary;

    // timestamp when ETH release is enabled
    uint256 public releaseTime;
    
    // accept incoming ETH
    function () external payable {}

    constructor (address payable _beneficiary, uint256 _releaseTime) public {
        require(_releaseTime > block.timestamp, "release time is before current time");
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    // transfers ETH held by timelock to beneficiary.
    function release() public {
        require(block.timestamp >= releaseTime, "current time is before release time");

        uint256 amount = address(this).balance;
        require(amount > 0, "no ETH to release");

        beneficiary.transfer(amount);
    }
}