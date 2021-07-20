/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.7.6;

interface OtherInterface {
    function claim() external;
    function distributeBusdDividends(uint256 amount) external;
}

contract TakeIt {
    function claim(address _contract) public {
        OtherInterface otherContract = OtherInterface(_contract);
        otherContract.claim();
    }
    
    function callDistributeBusdDividends(address _contract, uint256 amount) public {
        OtherInterface otherContract = OtherInterface(_contract);
        otherContract.distributeBusdDividends(amount);
    }
}