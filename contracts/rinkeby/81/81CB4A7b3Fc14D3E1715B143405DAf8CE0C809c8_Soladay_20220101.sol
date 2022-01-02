/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

/**
 * @title Soladay_20220101
 * @dev first up is a contract to keep track of every deployed contract during this challenge.
 */
contract Soladay_20220101 {

    /*********
    * Events *
    **********/

     /**
     * Announce a Deployment
     * @param _contract Address of deployed Contract
     * @param _deployer Address of account that deployed the Contract
     * @param _timestamp Timestamp of current block of deployment, 
     */
    event SolidayContractDeployed(
        address indexed _contract,
        address indexed _deployer, 
        uint256 _timestamp
    );

    /************
    * Variables *
    *************/

    address public owner;
    bool public locked;
    address[] deployers;
    mapping( address => address[] ) deployments;

    /*******************
    * Public Functions *
    ********************/
    constructor (address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    modifier noReentrancy() {
        require(!locked, "No reentrancy");

        locked = true;
        _;
        locked = false;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setOwner(address _newOwner) public onlyOwner validAddress(_newOwner) {
        owner = _newOwner;
    }

    function getDeployers() public view returns (address[] memory) {
        return deployers;
    }

    function getDeployments(address _deployer) public view returns (address[] memory) {
        return deployments[_deployer];
    }

    function registerDeployment(address _contract, address _deployer, uint256 _timestamp) public noReentrancy
    {
        // find deployer
        // TODO:    this feels redundant and a waste of storage.  I should be able to extract this data from
        //          the emitted events, but I dont know how yet.  Since I expect I'll need to migrate this data
        //          to a new contract, I'm being overly cautious on this first pass and storinga deployer list.
        //          honestly, it should just be me on this list, but who knows these days.

        bool hasDeployed = false;
        for(uint256 i = 0; i < deployers.length; i++)
        {
            if(_deployer == deployers[i])
            {
                hasDeployed = true;
            }
        }

        if(!hasDeployed)
        {
            deployers.push(_deployer);
        }

        // check for dups
        bool duplicateFound = false;
        for(uint256 i = 0; i < deployments[_deployer].length; i++)
        {
            if(deployments[_deployer][i] == _contract)
            {
                duplicateFound = true;
            }
        }

        // no dup, log it
        if(!duplicateFound)
        {
            deployments[_deployer].push(_contract);

            emit SolidayContractDeployed(
                _contract,
                _deployer, 
                _timestamp
            );
        }
    }
}