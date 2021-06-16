/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

contract MVP {

    mapping(string => address[]) public signedInstances;
    
    mapping(address => string[]) public instancesSignedPerAddress;

    string[] public listOfInstances;

    event SignedInstance(address _signee, string _instance);

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function getListOfInstances()
        public
        view
        returns (string[] memory _hashes)
    {
        return listOfInstances;
    }

    function signInstance(string memory _hash) public {
        if (signedInstances[_hash].length == 0) {
            listOfInstances.push(_hash);
        }
        for (uint256 i = 0; i < signedInstances[_hash].length; i++) {
            assert(signedInstances[_hash][i] != msg.sender);
        }
        signedInstances[_hash].push(msg.sender);
        instancesSignedPerAddress[msg.sender].push(_hash);
        emit SignedInstance(msg.sender, _hash);
    }

    function getSignaturesOfHash(string memory _hash)
        public
        view
        returns (address[] memory signees)
    {
        //require(signedInstances[_hash].length >= 1, "Instance not registered");
        return signedInstances[_hash];
    }
    
    function getSignedInstancesPerAddress()
        public
        view
        returns (string[] memory instances)
    {
        return instancesSignedPerAddress[msg.sender];
    }
}