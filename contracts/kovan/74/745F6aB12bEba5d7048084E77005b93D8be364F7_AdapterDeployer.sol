/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/lender/adapters/deployer.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.6.12;

////// src/lender/fabs/interfaces.sol
/* pragma solidity >=0.6.12; */

interface ReserveFabLike_1 {
    function newReserve(address) external returns (address);
}

interface AssessorFabLike_2 {
    function newAssessor() external returns (address);
}

interface TrancheFabLike_1 {
    function newTranche(address, address) external returns (address);
}

interface CoordinatorFabLike_2 {
    function newCoordinator(uint) external returns (address);
}

interface OperatorFabLike_1 {
    function newOperator(address) external returns (address);
}

interface MemberlistFabLike_1 {
    function newMemberlist() external returns (address);
}

interface RestrictedTokenFabLike_1 {
    function newRestrictedToken(string calldata, string calldata) external returns (address);
}

interface PoolAdminFabLike {
    function newPoolAdmin() external returns (address);
}

interface ClerkFabLike {
    function newClerk(address, address) external returns (address);
}

////// src/lender/adapters/deployer.sol
/* pragma solidity >=0.6.12; */

/* import { ClerkFabLike } from "../fabs/interfaces.sol"; */
interface LenderDeployerLike_1 {
    function coordinator() external returns (address);
    function assessor() external returns (address);
    function reserve() external returns (address);
    function seniorOperator() external returns (address);
    function seniorTranche() external returns (address);
    function seniorToken() external returns (address);
    function currency() external returns (address);
    function poolAdmin() external returns (address);
    function seniorMemberlist() external returns (address);
}

interface PoolAdminLike_1 {
    function rely(address) external;
    function relyAdmin(address) external;
}

interface FileLike_2 {
    function file(bytes32 name, uint value) external;
}

interface MemberlistLike_1 {
    function updateMember(address, uint) external;
}

interface MgrLike {
    function rely(address) external;
    function file(bytes32 name, address value) external;
    function lock(uint) external;
}

interface AuthLike_2 {
    function rely(address) external;
    function deny(address) external;
}

interface DependLike_2 {
    function depend(bytes32, address) external;
}

contract AdapterDeployer {
    ClerkFabLike public clerkFab;
    address public clerk;

    address mkrDeployer;

    address public root;
    LenderDeployerLike_1 public lenderDeployer;

    address public mgr;
    address public mkrVat;
    address public mkrSpotter;
    address public mkrJug;
    address public mkrUrn;
    address public mkrLiq;
    address public mkrEnd;

    uint public matBuffer;
    bool public wired;

    constructor(address root_, address clerkFabLike_) {
      root = root_;
      clerkFab = ClerkFabLike(clerkFabLike_);
      mkrDeployer = msg.sender;
    }

    function deployClerk() public {
        require(address(clerk) == address(0) && lenderDeployer.seniorToken() != address(0) && mkrDeployer == address(1));
        clerk = clerkFab.newClerk(lenderDeployer.currency(), lenderDeployer.seniorToken());

        address assessor = lenderDeployer.assessor();
        address reserve = lenderDeployer.reserve();
        address seniorTranche = lenderDeployer.seniorTranche();
        address seniorMemberlist = lenderDeployer.seniorMemberlist();
        address poolAdmin = lenderDeployer.poolAdmin();
        // clerk dependencies
        DependLike_2(clerk).depend("coordinator", lenderDeployer.coordinator());
        DependLike_2(clerk).depend("assessor", assessor);
        DependLike_2(clerk).depend("reserve", reserve);
        DependLike_2(clerk).depend("tranche", seniorTranche);
        DependLike_2(clerk).depend("collateral", lenderDeployer.seniorToken());
        DependLike_2(clerk).depend("mgr", mgr);
        DependLike_2(clerk).depend("spotter", mkrSpotter);
        DependLike_2(clerk).depend("vat", mkrVat);
        DependLike_2(clerk).depend("jug", mkrJug);
        // clerk as ward
        AuthLike_2(seniorTranche).rely(clerk);
        AuthLike_2(reserve).rely(clerk);
        AuthLike_2(assessor).rely(clerk);

        // reserve can draw and wipe on clerk
        DependLike_2(reserve).depend("lending", clerk);
        AuthLike_2(clerk).rely(reserve);

        // set the mat buffer
        FileLike_2(clerk).file("buffer", matBuffer);

        // allow clerk to hold seniorToken
        MemberlistLike_1(seniorMemberlist).updateMember(clerk, type(uint256).max);
        MemberlistLike_1(seniorMemberlist).updateMember(mgr, type(uint256).max);

        DependLike_2(assessor).depend("lending", clerk);

        // poolAdmin setup
        DependLike_2(poolAdmin).depend("lending", clerk);
        AuthLike_2(clerk).rely(poolAdmin);

        AuthLike_2(clerk).rely(root);
        AuthLike_2(clerk).deny(address(this));
    }

    function initMKR(address lenderDeployer_, address mgr_, address mkrSpotter_, address mkrVat_, address mkrJug_, address mkrUrn_, address mkrLiq_, address mkrEnd_, uint matBuffer_) public {
        require(mkrDeployer == msg.sender);
        lenderDeployer = LenderDeployerLike_1(lenderDeployer_);
        mgr = mgr_;
        mkrSpotter = mkrSpotter_;
        mkrVat = mkrVat_;
        mkrJug = mkrJug_;
        mkrUrn = mkrUrn_;
        mkrLiq = mkrLiq_;
        mkrEnd = mkrEnd_;
        matBuffer = matBuffer_;
        mkrDeployer = address(1);
    }

    function wireAdapter() public {
        require(!wired, "adapter already wired"); // make sure adapter only wired once
        wired = true;
        // setup mgr
        MgrLike mkrMgr = MgrLike(mgr);
        mkrMgr.rely(clerk);
        mkrMgr.file("urn", mkrUrn);
        mkrMgr.file("liq", mkrLiq);
        mkrMgr.file("end", mkrEnd);
        mkrMgr.file("owner", clerk);
        mkrMgr.file("pool", lenderDeployer.seniorOperator());
        mkrMgr.file("tranche", lenderDeployer.seniorTranche());
        // lock token
        mkrMgr.lock(1 ether);
    }
}