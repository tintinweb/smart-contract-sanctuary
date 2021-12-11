/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title SmartWalletChecker
 */
contract SmartWalletChecker {

    mapping(address => bool) public isManager;
    mapping(address => bool) public isAllowed;

    constructor() public {
        isManager[msg.sender] = true;
    }

    /**
     * @notice Sets the status of a manager
     * @param _manager The address of the manager
     * @param _status The status to allow the manager 
     */
    function setManager(
        address _manager,
        bool _status
    )
        external
        onlyManager
    {
        isManager[_manager] = _status;
    }

    /**
     * @notice Sets the status of a contract to be allowed or disallowed
     * @param _contract The address of the contract
     * @param _status The status to allow the manager 
     */
    function setAllowedContract(
        address _contract,
        bool _status
    )
        external
        onlyManager
    {
        isAllowed[_contract] = _status;
    }

    /**
     * @notice returns true is _address is whitelisted
     * @param _address The address to check
     */
    function check (
        address _address
    )
        external
        view
        returns(bool)
    {
        return isAllowed[_address];
    }

    modifier onlyManager() {
        require(isManager[msg.sender], "!manager");
        _;
    }
}