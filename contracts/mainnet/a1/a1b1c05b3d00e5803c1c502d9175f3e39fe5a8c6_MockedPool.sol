/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Mocked Pool contract.
 * 
 * @dev Simulates a core pool, with the set weight function to be called
 * by the pool factory. It receives some weight so the total weight registered
 * by the factory contract is higher than 0, and allows ILV emissions to be
 * stopped and users are able to execute actions in the v1 contracts.
 */
contract MockedPool {
    /**
     * @dev Pool factory deployed instance.
     */
    address public factory;
    /**
     * @dev Weight registered by the factory
     */
    uint32 public weight;

    /**
     * @param _factory pool factory address
     */
    constructor(address _factory) {
        factory = _factory;
    }

    /**
     * @dev Called by the factory, just stores the received weight
     * in order to mock a v1 core pool.
     */
    function setWeight(uint32 _weight) external {
        require(msg.sender == factory, "invalid sender");
        weight = _weight;
    }
}