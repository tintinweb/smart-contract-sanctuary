/**
 *Submitted for verification at polygonscan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This file provides a sample to easily run unit tests for the {CourtyardRegistry}.
**/


/**
 * @dev let's recall the interface of {CourtyardRegistry} here.
 */
interface IRegistry {
    function mintToken(address _to, bytes32 _proof) external returns (uint256);
}


/**
 * @dev a mock contract to test the interaction with a {IRegistry} and provide an example of how it works.
 */
contract MinterContractMock {

    IRegistry registry;

    constructor(address registryAddress) {
        registry = IRegistry(registryAddress);
    }

    function mint(bytes32 _proof) public returns (uint256) {
        return registry.mintToken(msg.sender, _proof);
    }

}