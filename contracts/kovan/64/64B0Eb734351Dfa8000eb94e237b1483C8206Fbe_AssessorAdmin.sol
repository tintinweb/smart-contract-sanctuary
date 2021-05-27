/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/lender/admin/assessor.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.6.12;

////// lib/tinlake-auth/src/auth.sol
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
/* pragma solidity >=0.5.15; */

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

////// src/lender/admin/assessor.sol
/* pragma solidity >=0.6.12; */

/* import "tinlake-auth/auth.sol"; */

interface AssessorLike_2 {
     function file(bytes32 name, uint value) external;
}

// Wrapper contract for permission restriction on the assessor.
// This contract ensures that only the maxReserve size of the pool can be set
contract AssessorAdmin is Auth {
    AssessorLike_2  public assessor;
    constructor() public {
        wards[msg.sender] = 1;
    }

    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "assessor") {
            assessor = AssessorLike_2(addr);
        } else revert();
    }

    function setMaxReserve(uint value) public auth {
        assessor.file("maxReserve", value);
    }
}