/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/** 
 * @title TestResult
 * @dev Allows a person to share a TestResult of, for example, a COVID-19 test.
 */
contract TestResult {
    
    address public testedPerson;
    
    mapping (address => bool) public allowedViewers;
    
    bool private positive;
    
    constructor(bool result) {
        testedPerson = msg.sender;
        
        allowedViewers[testedPerson]=true;
        
        positive = result;
    }
    
    function allowPersonToView(address allowedViewer) public {
        require(msg.sender == testedPerson, "Only the tested person can determine who can view the result.");
        allowedViewers[allowedViewer]=true;
    }
    
    function getResult() public view returns (bool) {
        require(allowedViewers[msg.sender], "Has no right to view result");
        
        return positive;
    }
}