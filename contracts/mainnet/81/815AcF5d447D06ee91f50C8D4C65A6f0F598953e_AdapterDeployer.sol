/**
 *Submitted for verification at Etherscan.io on 2021-07-26
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

interface TinlakeManagerFabLike {
    function newTinlakeManager(address, address, address,  address, address, address, address, address) external returns (address);
}

////// src/lender/adapters/deployer.sol
/* pragma solidity >=0.6.12; */

/* import { ClerkFabLike, TinlakeManagerFabLike } from "../fabs/interfaces.sol"; */

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
    TinlakeManagerFabLike public mgrFab;
    address public clerk;
    address public mgr;

    address public root;
    LenderDeployerLike_1 public lenderDeployer;
    
    address deployUsr;

    constructor(address root_, address clerkFabLike_, address mgrFabLike_) {
        root = root_;
        clerkFab = ClerkFabLike(clerkFabLike_);
        mgrFab = TinlakeManagerFabLike(mgrFabLike_);
        deployUsr = msg.sender;
    }

    function deployClerk(address lenderDeployer_) public {
        require(deployUsr == msg.sender && address(clerk) == address(0) && LenderDeployerLike_1(lenderDeployer_).seniorToken() != address(0));

        lenderDeployer = LenderDeployerLike_1(lenderDeployer_);
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

        // clerk as ward
        AuthLike_2(seniorTranche).rely(clerk);
        AuthLike_2(reserve).rely(clerk);
        AuthLike_2(assessor).rely(clerk);

        // reserve can draw and wipe on clerk
        DependLike_2(reserve).depend("lending", clerk);
        AuthLike_2(clerk).rely(reserve);

        // allow clerk to hold seniorToken
        MemberlistLike_1(seniorMemberlist).updateMember(clerk, type(uint256).max);

        DependLike_2(assessor).depend("lending", clerk);

        AuthLike_2(clerk).rely(poolAdmin);

        AuthLike_2(clerk).rely(root);
    }

    function deployMgr(address dai, address daiJoin, address end, address vat, address vow, address liq, address spotter, address jug, uint matBuffer) public {
        require(deployUsr == msg.sender && address(clerk) != address(0) && address(mgr) == address(0) && lenderDeployer.seniorToken() != address(0));

        // deploy mgr
        mgr = mgrFab.newTinlakeManager(dai, daiJoin, lenderDeployer.seniorToken(), lenderDeployer.seniorOperator(), lenderDeployer.seniorTranche(), end, vat, vow);
        wireClerk(mgr, vat, spotter, jug, matBuffer);

        // setup mgr
        MgrLike mkrMgr = MgrLike(mgr);
        mkrMgr.rely(clerk);
        mkrMgr.file("liq", liq);
        mkrMgr.file("end", end);
        mkrMgr.file("owner", clerk);

        // rely root, deny adapter deployer
        AuthLike_2(mgr).rely(root);
        AuthLike_2(mgr).deny(address(this));
    }

    // This is separated as the system tests don't use deployMgr, but do need the clerk wiring
    function wireClerk(address mgr_, address vat, address spotter, address jug, uint matBuffer) public {
        require(deployUsr == msg.sender && address(clerk) != address(0));

        // wire clerk
        DependLike_2(clerk).depend("mgr", mgr_);
        DependLike_2(clerk).depend("spotter", spotter);
        DependLike_2(clerk).depend("vat", vat);
        DependLike_2(clerk).depend("jug", jug);
        
        // set the mat buffer
        FileLike_2(clerk).file("buffer", matBuffer);

        // rely root, deny adapter deployer
        AuthLike_2(clerk).deny(address(this));

        MemberlistLike_1(lenderDeployer.seniorMemberlist()).updateMember(mgr_, type(uint256).max);
    }
}