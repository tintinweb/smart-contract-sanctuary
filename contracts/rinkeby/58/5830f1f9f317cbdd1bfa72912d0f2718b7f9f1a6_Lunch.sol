/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

contract Lunch {
    address public dao;
    address public person;
    bool public lunchAllowed = false;
    
    modifier onlyDAO() {
        require(msg.sender == dao, "!dao");
        _;
    }
    
    modifier onlyPerson() {
        require(msg.sender == person, "!person");
        _;
    }
    
    constructor(address _dao, address _person) {
        require(isContract(_dao), "_dao !contract");
        require(!isContract(_person), "person is contract");
        dao = _dao;
        person = _person;
    }
    
    function allowLunch() external onlyDAO {
        require(!lunchAllowed, "already allowed");
        lunchAllowed = true;
    }
    
    function doLunch() external onlyPerson {
        require(lunchAllowed, "not allowed");
        lunchAllowed = false;
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}