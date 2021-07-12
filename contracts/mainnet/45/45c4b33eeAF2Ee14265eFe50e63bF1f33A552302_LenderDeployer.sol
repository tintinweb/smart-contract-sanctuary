/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/lender/deployer.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.6.12;

////// src/fixed_point.sol
/* pragma solidity >=0.6.12; */

abstract contract FixedPoint {
    struct Fixed27 {
        uint value;
    }
}

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

////// src/lender/deployer.sol
/* pragma solidity >=0.6.12; */

/* import { ReserveFabLike, AssessorFabLike, TrancheFabLike, CoordinatorFabLike, OperatorFabLike, MemberlistFabLike, RestrictedTokenFabLike, PoolAdminFabLike, ClerkFabLike } from "./fabs/interfaces.sol"; */

/* import {FixedPoint}      from "./../fixed_point.sol"; */


interface DependLike_3 {
    function depend(bytes32, address) external;
}

interface AuthLike_3 {
    function rely(address) external;
    function deny(address) external;
}

interface MemberlistLike_4 {
    function updateMember(address, uint) external;
}

interface FileLike_3 {
    function file(bytes32 name, uint value) external;
}

contract LenderDeployer is FixedPoint {
    address public immutable root;
    address public immutable currency;
    address public immutable memberAdmin;

    // factory contracts
    TrancheFabLike_1          public immutable trancheFab;
    ReserveFabLike_1          public immutable reserveFab;
    AssessorFabLike_2         public immutable assessorFab;
    CoordinatorFabLike_2      public immutable coordinatorFab;
    OperatorFabLike_1         public immutable operatorFab;
    MemberlistFabLike_1       public immutable memberlistFab;
    RestrictedTokenFabLike_1  public immutable restrictedTokenFab;
    PoolAdminFabLike        public immutable poolAdminFab;

    // lender state variables
    Fixed27             public minSeniorRatio;
    Fixed27             public maxSeniorRatio;
    uint                public maxReserve;
    uint                public challengeTime;
    Fixed27             public seniorInterestRate;


    // contract addresses
    address             public adapterDeployer;
    address             public assessor;
    address             public poolAdmin;
    address             public seniorTranche;
    address             public juniorTranche;
    address             public seniorOperator;
    address             public juniorOperator;
    address             public reserve;
    address             public coordinator;

    address             public seniorToken;
    address             public juniorToken;

    // token names
    string              public seniorName;
    string              public seniorSymbol;
    string              public juniorName;
    string              public juniorSymbol;
    // restricted token member list
    address             public seniorMemberlist;
    address             public juniorMemberlist;

    address             public deployer;
    bool public wired;

    constructor(address root_, address currency_, address trancheFab_, address memberlistFab_, address restrictedtokenFab_, address reserveFab_, address assessorFab_, address coordinatorFab_, address operatorFab_, address poolAdminFab_, address memberAdmin_, address adapterDeployer_) {
        deployer = msg.sender;
        root = root_;
        currency = currency_;
        memberAdmin = memberAdmin_;
        adapterDeployer = adapterDeployer_;

        trancheFab = TrancheFabLike_1(trancheFab_);
        memberlistFab = MemberlistFabLike_1(memberlistFab_);
        restrictedTokenFab = RestrictedTokenFabLike_1(restrictedtokenFab_);
        reserveFab = ReserveFabLike_1(reserveFab_);
        assessorFab = AssessorFabLike_2(assessorFab_);
        poolAdminFab = PoolAdminFabLike(poolAdminFab_);
        coordinatorFab = CoordinatorFabLike_2(coordinatorFab_);
        operatorFab = OperatorFabLike_1(operatorFab_);
    }

    function init(uint minSeniorRatio_, uint maxSeniorRatio_, uint maxReserve_, uint challengeTime_, uint seniorInterestRate_, string memory seniorName_, string memory seniorSymbol_, string memory juniorName_, string memory juniorSymbol_) public {
        require(msg.sender == deployer);
        challengeTime = challengeTime_;
        minSeniorRatio = Fixed27(minSeniorRatio_);
        maxSeniorRatio = Fixed27(maxSeniorRatio_);
        maxReserve = maxReserve_;
        seniorInterestRate = Fixed27(seniorInterestRate_);

        // token names
        seniorName = seniorName_;
        seniorSymbol = seniorSymbol_;
        juniorName = juniorName_;
        juniorSymbol = juniorSymbol_;

        deployer = address(1);
    }

    function deployJunior() public {
        require(juniorTranche == address(0) && deployer == address(1));
        juniorToken = restrictedTokenFab.newRestrictedToken(juniorSymbol, juniorName);
        juniorTranche = trancheFab.newTranche(currency, juniorToken);
        juniorMemberlist = memberlistFab.newMemberlist();
        juniorOperator = operatorFab.newOperator(juniorTranche);
        AuthLike_3(juniorMemberlist).rely(root);
        AuthLike_3(juniorToken).rely(root);
        AuthLike_3(juniorToken).rely(juniorTranche);
        AuthLike_3(juniorOperator).rely(root);
        AuthLike_3(juniorTranche).rely(root);
    }

    function deploySenior() public {
        require(seniorTranche == address(0) && deployer == address(1));
        seniorToken = restrictedTokenFab.newRestrictedToken(seniorSymbol, seniorName);
        seniorTranche = trancheFab.newTranche(currency, seniorToken);
        seniorMemberlist = memberlistFab.newMemberlist();
        seniorOperator = operatorFab.newOperator(seniorTranche);
        AuthLike_3(seniorMemberlist).rely(root);
        AuthLike_3(seniorToken).rely(root);
        AuthLike_3(seniorToken).rely(seniorTranche);
        AuthLike_3(seniorOperator).rely(root);
        AuthLike_3(seniorTranche).rely(root);

        if (adapterDeployer != address(0)) {
            AuthLike_3(seniorTranche).rely(adapterDeployer);
            AuthLike_3(seniorMemberlist).rely(adapterDeployer);
        }
    }

    function deployReserve() public {
        require(reserve == address(0) && deployer == address(1));
        reserve = reserveFab.newReserve(currency);
        AuthLike_3(reserve).rely(root);
        if (adapterDeployer != address(0)) AuthLike_3(reserve).rely(adapterDeployer);
    }

    function deployAssessor() public {
        require(assessor == address(0) && deployer == address(1));
        assessor = assessorFab.newAssessor();
        AuthLike_3(assessor).rely(root);
        if (adapterDeployer != address(0)) AuthLike_3(assessor).rely(adapterDeployer);
    }

    function deployPoolAdmin() public {
        require(poolAdmin == address(0) && deployer == address(1));
        poolAdmin = poolAdminFab.newPoolAdmin();
        AuthLike_3(poolAdmin).rely(root);
        if (adapterDeployer != address(0)) AuthLike_3(poolAdmin).rely(adapterDeployer);
    }

    function deployCoordinator() public {
        require(coordinator == address(0) && deployer == address(1));
        coordinator = coordinatorFab.newCoordinator(challengeTime);
        AuthLike_3(coordinator).rely(root);
    }

    function deploy() public virtual {
        require(coordinator != address(0) && assessor != address(0) &&
                reserve != address(0) && seniorTranche != address(0));
    
        require(!wired, "lender contracts already wired"); // make sure lender contracts only wired once
        wired = true;

        // required depends
        // reserve
        AuthLike_3(reserve).rely(seniorTranche);
        AuthLike_3(reserve).rely(juniorTranche);
        AuthLike_3(reserve).rely(coordinator);
        AuthLike_3(reserve).rely(assessor);

        // tranches
        DependLike_3(seniorTranche).depend("reserve",reserve);
        DependLike_3(juniorTranche).depend("reserve",reserve);
        AuthLike_3(seniorTranche).rely(coordinator);
        AuthLike_3(juniorTranche).rely(coordinator);
        AuthLike_3(seniorTranche).rely(seniorOperator);
        AuthLike_3(juniorTranche).rely(juniorOperator);

        // coordinator implements epoch ticker interface
        DependLike_3(seniorTranche).depend("coordinator", coordinator);
        DependLike_3(juniorTranche).depend("coordinator", coordinator);

        //restricted token
        DependLike_3(seniorToken).depend("memberlist", seniorMemberlist);
        DependLike_3(juniorToken).depend("memberlist", juniorMemberlist);

        //allow tinlake contracts to hold drop/tin tokens
        MemberlistLike_4(juniorMemberlist).updateMember(juniorTranche, type(uint256).max);
        MemberlistLike_4(seniorMemberlist).updateMember(seniorTranche, type(uint256).max);

        // operator
        DependLike_3(seniorOperator).depend("tranche", seniorTranche);
        DependLike_3(juniorOperator).depend("tranche", juniorTranche);
        DependLike_3(seniorOperator).depend("token", seniorToken);
        DependLike_3(juniorOperator).depend("token", juniorToken);

        // coordinator
        DependLike_3(coordinator).depend("reserve", reserve);
        DependLike_3(coordinator).depend("seniorTranche", seniorTranche);
        DependLike_3(coordinator).depend("juniorTranche", juniorTranche);
        DependLike_3(coordinator).depend("assessor", assessor);

        // assessor
        DependLike_3(assessor).depend("seniorTranche", seniorTranche);
        DependLike_3(assessor).depend("juniorTranche", juniorTranche);
        DependLike_3(assessor).depend("reserve", reserve);

        AuthLike_3(assessor).rely(coordinator);
        AuthLike_3(assessor).rely(reserve);
        AuthLike_3(assessor).rely(poolAdmin);
        
        // poolAdmin
        DependLike_3(poolAdmin).depend("assessor", assessor);
        DependLike_3(poolAdmin).depend("juniorMemberlist", juniorMemberlist);
        DependLike_3(poolAdmin).depend("seniorMemberlist", seniorMemberlist);
        
        AuthLike_3(juniorMemberlist).rely(poolAdmin);
        AuthLike_3(seniorMemberlist).rely(poolAdmin);

        if (memberAdmin != address(0)) AuthLike_3(juniorMemberlist).rely(memberAdmin);
        if (memberAdmin != address(0)) AuthLike_3(seniorMemberlist).rely(memberAdmin);

        FileLike_3(assessor).file("seniorInterestRate", seniorInterestRate.value);
        FileLike_3(assessor).file("maxReserve", maxReserve);
        FileLike_3(assessor).file("maxSeniorRatio", maxSeniorRatio.value);
        FileLike_3(assessor).file("minSeniorRatio", minSeniorRatio.value);
    }
}