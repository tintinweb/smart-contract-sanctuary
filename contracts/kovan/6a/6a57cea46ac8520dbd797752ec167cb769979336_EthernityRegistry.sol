pragma solidity ^0.5.17;

/**
 * Copyright (C) 2018, 2019, 2020 Ethernity HODL UG
 *
 * This file is part of ETHERNITY PoX SC.
 *
 * ETHERNITY PoE SC is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */


import "./EthernityStorage.sol";

contract EthernityRegistry is EthernityStorage {

    constructor() public {
        versions.push(address(0));
        versionsPro.push(address(0));
    }


    /**
    * @dev Upgrades the implementation address
    * @param _newImplementation address of the new implementation
    */
    function upgradeTo(address _newImplementation) public onlyOwner returns (bool success){

        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
        return true;
    }

    /**
    * @dev Upgrades the implementation address
    * @param _newImplementation address of the new implementation
    */
    function upgradeToPro(address _newImplementation) public onlyOwner returns (bool success){

        require(implementationPro != _newImplementation);
        _setImplementationPro(_newImplementation);
        return true;
    }

    /**
     * @dev Fallback function allowing to perform a delegatecall
     * to the given implementation. This function will return
     * whatever the implementation call returns
     */

    function _fallback() internal {
        address target = address(0);
        if (usersPro[msg.sender] == true) {
            target = implementationPro;
        } else {
            target = implementation;
        }

        require(target != address(0));
        callerAddress = msg.sender;

        assembly {
            let ptr := mload(0x40)
            let size := and(add(calldatasize, 0x1f), not(0x1f))
            mstore(0x40, add(ptr, size))
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, target, ptr, calldatasize, 0, 0)

            switch result
            case 0 {
                revert(0, 0)
            } default {
                let retptr := mload(0x40)
                mstore(0x40, add(retptr, returndatasize))
                returndatacopy(retptr, 0x0, returndatasize)
                return (retptr, returndatasize)
            }
        }
    }

    function() payable external {
        _fallback();
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        _fallback();
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        _fallback();
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        _fallback();
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        _fallback();
    }

    function _addProUser(address userPro) public onlyOwner returns (bool){
        usersPro[userPro] = true;
        return true;
    }

    function _removeProUser(address userPro) public onlyOwner returns (bool){
        usersPro[userPro] = false;
        return true;
    }

    function _checkProUser(address userPro) public onlyOwner view returns (bool){
        return usersPro[userPro];
    }

    /**
    * @dev Sets the address of the current implementation
    * @param _newImp address of the new implementation
    */
    function _setImplementation(address _newImp) internal onlyOwner {
        implementation = _newImp;
        versions.push(_newImp);
    }

    function _setImplementationPro(address _newImp) internal onlyOwner {
        implementationPro = _newImp;
        versionsPro.push(_newImp);
    }

    /**
    * returns true for pro users | false for community
    */
    function _checkSubscription() public view returns (bool){
        return usersPro[msg.sender];
    }
}