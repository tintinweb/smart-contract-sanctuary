/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Collaborators {

    uint256 _number;
    address _collaboratorID;
    address[] private _collaborators;

    /*
     * *
     * @dev Store value in variable
     * @param id value to store
    */
    
    function createWorker() public {
        _collaborators.push(msg.sender);
    }
     

    /**
     * @dev Return value 
     * @return value of 'address[]'
     */
    function getcollaboratorWorkers() public view returns (address  [] memory){
        return _collaborators;
    }
}