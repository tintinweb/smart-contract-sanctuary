/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity ^0.5.0;

         
/**
 * @title Cake-LpTimelock
 * @dev Cake-LpTimelock is an CAKE-LP holder contract that will allow a
 * beneficiary to receive the CAKE-LP after a given release time.
 */
contract CakeLPTimelock {
         
    // beneficiary of Cake-LP after it is released
    address payable public beneficiary;

    // timestamp when Cake-LP release is enabled
    uint256 public releaseTime;
    
    // accept incoming Cake-LP
    function () external payable {}

    constructor (address payable _beneficiary, uint256 _releaseTime) public {
        require(_releaseTime > block.timestamp, "release time is before current time");
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    // transfers Cake-LP held by timelock to beneficiary.
    function release() public {
        require(block.timestamp >= releaseTime, "current time is before release time");

        uint256 amount = address(this).balance;
        require(amount > 0, "no Cake-LP to release");

        beneficiary.transfer(amount);
    }
}