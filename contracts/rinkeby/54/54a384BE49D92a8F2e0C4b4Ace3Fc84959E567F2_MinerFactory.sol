// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "./MinerContract.sol";

contract MinerFactory {

    /* event fired on every new SimpleSwap deployment */
    event MinerDeployed(address contractAddress);

    /* mapping to keep track of which contracts were deployed by this factory */
    mapping (address => bool) public deployedContracts;

    /* address of the ERC20-token, to be used by the to-be-deployed chequebooks */
    address public PoolAddress;

    constructor(address _poolAddress) {
        PoolAddress = _poolAddress;
    }

    function deployMiner(address issuer)
    public returns (address) {
        address contractAddress = address(new MinerContract(issuer, PoolAddress, block.timestamp));
        deployedContracts[contractAddress] = true;
        emit MinerDeployed(contractAddress);
        return contractAddress;
    }
}