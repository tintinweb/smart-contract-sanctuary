/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

pragma solidity 0.8.7;

contract ChildContract{
    string public name;

    function setName(string memory _name) public
    {
        name=_name;
    }
}

pragma solidity 0.8.7;

contract MomContract{
    event NewchildContract(address indexed ChildContract);

    function giveBirth(string memory name) public
    {
        bytes memory bytecode = type(ChildContract).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(name,block.timestamp));
        address childContract;

        assembly {
            childContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        emit NewchildContract(childContract);
    }
}