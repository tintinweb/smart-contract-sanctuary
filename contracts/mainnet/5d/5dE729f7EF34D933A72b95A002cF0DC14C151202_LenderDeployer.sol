/**
 *Submitted for verification at Etherscan.io on 2021-06-02
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



////// src/lender/deployer.sol
/* pragma solidity >=0.6.12; */

/* import { ReserveFabLike, AssessorFabLike, TrancheFabLike, CoordinatorFabLike, OperatorFabLike, MemberlistFabLike, RestrictedTokenFabLike, PoolAdminFabLike } from "./fabs/interfaces.sol"; */

/* import {FixedPoint}      from "./../fixed_point.sol"; */


interface DependLike_2 {
    function depend(bytes32, address) external;
}

interface AuthLike_2 {
    function rely(address) external;
    function deny(address) external;
}

interface MemberlistLike_3 {
    function updateMember(address, uint) external;
}

interface FileLike_2 {
    function file(bytes32 name, uint value) external;
}

interface RootLike {
    function governance() external returns (address);
}

contract LenderDeployer is FixedPoint {
    address public root;
    address public currency;
    address public governance;
    address public memberAdmin;

    // factory contracts
    TrancheFabLike_1          public trancheFab;
    ReserveFabLike_1          public reserveFab;
    AssessorFabLike_2         public assessorFab;
    CoordinatorFabLike_2      public coordinatorFab;
    OperatorFabLike_1         public operatorFab;
    MemberlistFabLike_1       public memberlistFab;
    RestrictedTokenFabLike_1  public restrictedTokenFab;
    PoolAdminFabLike        public poolAdminFab;

    // lender state variables
    Fixed27             public minSeniorRatio;
    Fixed27             public maxSeniorRatio;
    uint                public maxReserve;
    uint                public challengeTime;
    Fixed27             public seniorInterestRate;


    // contract addresses
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

    constructor(address root_, address currency_, address trancheFab_, address memberlistFab_, address restrictedtokenFab_, address reserveFab_, address assessorFab_, address coordinatorFab_, address operatorFab_, address poolAdminFab_, address memberAdmin_) {
        deployer = msg.sender;
        root = root_;
        currency = currency_;
        memberAdmin = memberAdmin_;

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
        juniorToken = restrictedTokenFab.newRestrictedToken(juniorName, juniorSymbol);
        juniorTranche = trancheFab.newTranche(currency, juniorToken);
        juniorMemberlist = memberlistFab.newMemberlist();
        juniorOperator = operatorFab.newOperator(juniorTranche);
        AuthLike_2(juniorMemberlist).rely(root);
        AuthLike_2(juniorToken).rely(root);
        AuthLike_2(juniorToken).rely(juniorTranche);
        AuthLike_2(juniorOperator).rely(root);
        AuthLike_2(juniorTranche).rely(root);
    }

    function deploySenior() public {
        require(seniorTranche == address(0) && deployer == address(1));
        seniorToken = restrictedTokenFab.newRestrictedToken(seniorName, seniorSymbol);
        seniorTranche = trancheFab.newTranche(currency, seniorToken);
        seniorMemberlist = memberlistFab.newMemberlist();
        seniorOperator = operatorFab.newOperator(seniorTranche);
        AuthLike_2(seniorMemberlist).rely(root);
        AuthLike_2(seniorToken).rely(root);
        AuthLike_2(seniorToken).rely(seniorTranche);
        AuthLike_2(seniorOperator).rely(root);
        AuthLike_2(seniorTranche).rely(root);

    }

    function deployReserve() public {
        require(reserve == address(0) && deployer == address(1));
        reserve = reserveFab.newReserve(currency);
        AuthLike_2(reserve).rely(root);
    }

    function deployAssessor() public {
        require(assessor == address(0) && deployer == address(1));
        assessor = assessorFab.newAssessor();
        AuthLike_2(assessor).rely(root);
    }

    function deployPoolAdmin() public {
        require(poolAdmin == address(0) && deployer == address(1));
        poolAdmin = poolAdminFab.newPoolAdmin();
        AuthLike_2(poolAdmin).rely(root);
    }

    function deployCoordinator() public {
        require(coordinator == address(0) && deployer == address(1));
        coordinator = coordinatorFab.newCoordinator(challengeTime);
        AuthLike_2(coordinator).rely(root);
    }


    function deploy() public virtual {
        require(coordinator != address(0) && assessor != address(0) &&
                reserve != address(0) && seniorTranche != address(0));

        // required depends
        // reserve
        DependLike_2(reserve).depend("assessor", assessor);
        AuthLike_2(reserve).rely(seniorTranche);
        AuthLike_2(reserve).rely(juniorTranche);
        AuthLike_2(reserve).rely(coordinator);
        AuthLike_2(reserve).rely(assessor);


        // tranches
        DependLike_2(seniorTranche).depend("reserve",reserve);
        DependLike_2(juniorTranche).depend("reserve",reserve);
        AuthLike_2(seniorTranche).rely(coordinator);
        AuthLike_2(juniorTranche).rely(coordinator);
        AuthLike_2(seniorTranche).rely(seniorOperator);
        AuthLike_2(juniorTranche).rely(juniorOperator);

        // coordinator implements epoch ticker interface
        DependLike_2(seniorTranche).depend("coordinator", coordinator);
        DependLike_2(juniorTranche).depend("coordinator", coordinator);

        //restricted token
        DependLike_2(seniorToken).depend("memberlist", seniorMemberlist);
        DependLike_2(juniorToken).depend("memberlist", juniorMemberlist);

        //allow tinlake contracts to hold drop/tin tokens
        MemberlistLike_3(juniorMemberlist).updateMember(juniorTranche, type(uint256).max);
        MemberlistLike_3(seniorMemberlist).updateMember(seniorTranche, type(uint256).max);

        // operator
        DependLike_2(seniorOperator).depend("tranche", seniorTranche);
        DependLike_2(juniorOperator).depend("tranche", juniorTranche);
        DependLike_2(seniorOperator).depend("token", seniorToken);
        DependLike_2(juniorOperator).depend("token", juniorToken);


        // coordinator
        DependLike_2(coordinator).depend("reserve", reserve);
        DependLike_2(coordinator).depend("seniorTranche", seniorTranche);
        DependLike_2(coordinator).depend("juniorTranche", juniorTranche);
        DependLike_2(coordinator).depend("assessor", assessor);

        // assessor
        DependLike_2(assessor).depend("seniorTranche", seniorTranche);
        DependLike_2(assessor).depend("juniorTranche", juniorTranche);
        DependLike_2(assessor).depend("reserve", reserve);

        AuthLike_2(assessor).rely(coordinator);
        AuthLike_2(assessor).rely(reserve);
        AuthLike_2(assessor).rely(poolAdmin);

        // poolAdmin
        DependLike_2(poolAdmin).depend("assessor", assessor);
        DependLike_2(poolAdmin).depend("juniorMemberlist", juniorMemberlist);
        DependLike_2(poolAdmin).depend("seniorMemberlist", seniorMemberlist);

        AuthLike_2(juniorMemberlist).rely(poolAdmin);
        AuthLike_2(seniorMemberlist).rely(poolAdmin);
        if (memberAdmin != address(0)) AuthLike_2(juniorMemberlist).rely(memberAdmin);
        if (memberAdmin != address(0)) AuthLike_2(seniorMemberlist).rely(memberAdmin);

        FileLike_2(assessor).file("seniorInterestRate", seniorInterestRate.value);
        FileLike_2(assessor).file("maxReserve", maxReserve);
        FileLike_2(assessor).file("maxSeniorRatio", maxSeniorRatio.value);
        FileLike_2(assessor).file("minSeniorRatio", minSeniorRatio.value);
    }
}