/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


// gas estimate: 
// deploy: 329429
contract BWS_DatabaseImmutable {
  
    // These will be assigned at the construction
    // phase, where `msg.sender` is the account
    // creating this contract.
    address private immutable owner;
    
    // "table" definition
    struct bytes32Column {
        bool created;
        bytes32 value;
    }
    mapping (bytes32 => mapping(bytes32 => bytes32Column)) public myBytes32Table;

    // events
    event LogOwner (address indexed owner);

    // exceptions
    error Unauthorized();
    error NoData();
    error RowKeyInUse();

    constructor() {
        owner = msg.sender;
        emit LogOwner(msg.sender);
    }

    modifier onlyBy(address _account)
    {
        if (msg.sender != _account)
            revert Unauthorized();
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }

    // identity represents the "user" that owns the "database"
    // and is (for now) generated and stored by Blockchain Web Services.
    function insertBytes32(bytes32 identity, bytes32 key, bytes32 data)
        public
        onlyBy(owner)
    {
        if (!myBytes32Table[identity][key].created){
          myBytes32Table[identity][key].created = true;
          myBytes32Table[identity][key].value = data;
        }
        else
          revert RowKeyInUse();
    }

    function selectBytes32(bytes32 identity, bytes32 key)
        public view 
        onlyBy(owner)
        returns (bytes32)
    {
        if (!myBytes32Table[identity][key].created)
          revert NoData();     
        return myBytes32Table[identity][key].value; 
    }

}