/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

pragma solidity ^0.8.4;

contract NameRegistrar {

    bool public unlocked = false;  // registrar locked, no name updates
    address public owner;

    struct NameRecord { // map hashes to addresses
        bytes32 name;
        address mappedAddress;
    }
    
    constructor () {
        owner = msg.sender;
    }

    // records who registered names
    mapping(address => NameRecord) public registeredNameRecord;
    // resolves hashes to addresses
    mapping(bytes32 => address) public resolve;

    function unlock() public {
        require(msg.sender == owner);
        unlocked = true;
    }
    
    
    function register(bytes32 _name, address _mappedAddress) public {
        // set up the new NameRecord
        NameRecord memory newRecord;
        newRecord.name = _name;
        newRecord.mappedAddress = _mappedAddress;

        resolve[_name] = _mappedAddress;
        registeredNameRecord[msg.sender] = newRecord;

        require(unlocked); // only allow registrations if contract is unlocked
    }
}