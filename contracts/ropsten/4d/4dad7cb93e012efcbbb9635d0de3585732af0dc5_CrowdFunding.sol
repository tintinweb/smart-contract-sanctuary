/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.4.22;

contract CrowdFunding {
    uint256 goal;
    uint256 raised;
    uint256 phase;
    address beneficiary;

    constructor(address _beneficiary) public {
        goal = 300;
        raised = 0;
        phase = 0; // 0: Active 1: Finished
        beneficiary = _beneficiary;
    }

    function donate(uint256 donations) public payable {
        /* Check if the crowdfunding goal has been reached */
        if (raised < goal) {
            raised += donations;
        } else {
            phase = 1;
        }
    }

    function withdraw() public {
        /* The crowdfunding goal has been reached */
        if (phase == 1) {
            beneficiary.transfer(raised);
        }
    }
}