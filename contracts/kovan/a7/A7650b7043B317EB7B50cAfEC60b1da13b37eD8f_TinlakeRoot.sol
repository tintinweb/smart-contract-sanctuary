/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/root.sol
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

////// src/root.sol
/* pragma solidity >=0.6.12; */

/* import "tinlake-auth/auth.sol"; */

interface AuthLike_3 {
    function rely(address) external;
    function deny(address) external;
}

interface DependLike_3 {
    function depend(bytes32, address) external;
}

interface BorrowerDeployerLike {
    function collector() external returns (address);
    function feed() external returns (address);
    function shelf() external returns (address);
    function title() external returns (address);
}
interface LenderDeployerLike_1 {
    function assessor() external returns (address);
    function reserve() external returns (address);
}


contract TinlakeRoot is Auth {
    BorrowerDeployerLike public borrowerDeployer;
    LenderDeployerLike_1 public  lenderDeployer;

    bool public             deployed;
    address public          deployUsr;

    constructor (address deployUsr_) public {
        deployUsr = deployUsr_;
    }

    // --- Prepare ---
    // Sets the two deployer dependencies. This needs to be called by the deployUsr
    function prepare(address lender_, address borrower_, address ward_) public {
        require(deployUsr == msg.sender);
        borrowerDeployer = BorrowerDeployerLike(borrower_);
        lenderDeployer = LenderDeployerLike_1(lender_);
        wards[ward_] = 1;
        deployUsr = address(0); // disallow the deploy user to call this more than once.
    }

    // --- Deploy ---
    // After going through the deploy process on the lender and borrower method, this method is called to connect
    // lender and borrower contracts.
    function deploy() public {
        require(address(borrowerDeployer) != address(0) && address(lenderDeployer) != address(0) && deployed == false);
        deployed = true;

        address reserve_ = lenderDeployer.reserve();
        address shelf_ = borrowerDeployer.shelf();

        // Borrower depends
        DependLike_3(borrowerDeployer.collector()).depend("reserve", reserve_);
        DependLike_3(borrowerDeployer.shelf()).depend("lender", reserve_);
        DependLike_3(borrowerDeployer.shelf()).depend("reserve", reserve_);

        //AuthLike(reserve).rely(shelf_);

        //  Lender depends
        address navFeed = borrowerDeployer.feed();

        DependLike_3(reserve_).depend("shelf", shelf_);
        DependLike_3(lenderDeployer.assessor()).depend("navFeed", navFeed);
    }

    // --- Governance Functions ---
    // `relyContract` & `denyContract` can be called by any ward on the TinlakeRoot
    // contract to make an arbitrary address a ward on any contract the TinlakeRoot
    // is a ward on.
    function relyContract(address target, address usr) public auth {
        AuthLike_3(target).rely(usr);
    }

    function denyContract(address target, address usr) public auth {
        AuthLike_3(target).deny(usr);
    }

}