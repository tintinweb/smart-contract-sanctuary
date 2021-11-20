/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

pragma solidity ^0.4.26;
//访问控制不当
contract Rubixi{
    uint private balance = 0;
    uint private collectedFees=0;
    uint private feePercent=10;
    uint private pyramidMultiplier=300;
    uint private payoutOrder=0;
    address public creator;
    function DynamicPyramid() external{
        creator = msg.sender;
    }
}