/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

pragma solidity >=0.8.10;
// SPDX-License-Identifier: MIT


contract DASDAOOWNER {
    
    address public owner;
    address public backup;

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    event BackupChanged(address indexed previousBackup, address indexed newBackup);

    /**
    * @param _backup is the backup owner to set
    */
    constructor(address _backup) {
        owner = msg.sender;
        backup = _backup;
    }

    // checks if the caller of the function is authorized to call it (current owner or backup)
    modifier Auth {
        require(msg.sender == owner || msg.sender == backup, "UNAUTH SENDER");
        _;
    }

    /**
    * @param _newOwner is the new owner address to change to
    */
    function changeOwner(address _newOwner) external Auth {
        address old = owner;
        owner = _newOwner;
        emit OwnerChanged(old, _newOwner);
    }

    /**
    * @param _newBackup is the new backup owner address to change to
    */
    function changeBackup(address _newBackup) external Auth {
        address old = backup;
        backup = _newBackup;
        emit BackupChanged(old, _newBackup);
    }

}