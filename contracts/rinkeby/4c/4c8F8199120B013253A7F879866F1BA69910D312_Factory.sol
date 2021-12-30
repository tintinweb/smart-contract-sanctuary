/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// hevm: flattened sources of src/Factory.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

////// src/Instance.sol
/* pragma solidity ^0.8.0; */

contract Instance {

    event InstanceCreated(uint256 indexed id);

    uint256 internal _id;

    constructor(uint256 id_) {
        _id = id_;
        emit InstanceCreated(id_);
    }
    
}

////// src/Factory.sol
/* pragma solidity ^0.8.0; */

/* import { Instance } from "./Instance.sol"; */

contract Factory {

    event FactoryCreated();
    event FactoryCreatedInstance(uint256 indexed id);

    uint256 internal _nextId;

    constructor() {
        emit FactoryCreated();
    }

    function create() external {
        new Instance(_nextId);
        emit FactoryCreatedInstance(_nextId);
        _nextId += 1;
    }
    
}