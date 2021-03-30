/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// Copyright (C) 2020 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.5.15 <0.6.0;

// Copyright (C) 2020 Centrifuge

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.5.15 <0.6.0;

interface ReserveFabLike {
    function newReserve(address) external returns (address);
}

interface AssessorFabLike {
    function newAssessor() external returns (address);
}

interface TrancheFabLike {
    function newTranche(address, address) external returns (address);
}

interface CoordinatorFabLike {
    function newCoordinator(uint) external returns (address);
}

interface OperatorFabLike {
    function newOperator(address) external returns (address);
}

interface MemberlistFabLike {
    function newMemberlist() external returns (address);
}

interface RestrictedTokenFabLike {
    function newRestrictedToken(string calldata, string calldata) external returns (address);
}

interface AssessorAdminFabLike {
    function newAssessorAdmin() external returns (address);
}



// Copyright (C) 2020 Centrifuge
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.15 <0.6.0;

contract FixedPoint {
    struct Fixed27 {
        uint value;
    }
}


interface DependLike {
    function depend(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface MemberlistLike {
    function updateMember(address, uint) external;
}

interface FileLike {
    function file(bytes32 name, uint value) external;
}

contract LenderDeployer is FixedPoint {
    address public root;
    address public currency;

    // factory contracts
    TrancheFabLike          public trancheFab;
    ReserveFabLike          public reserveFab;
    AssessorFabLike         public assessorFab;
    CoordinatorFabLike      public coordinatorFab;
    OperatorFabLike         public operatorFab;
    MemberlistFabLike       public memberlistFab;
    RestrictedTokenFabLike  public restrictedTokenFab;
    AssessorAdminFabLike    public assessorAdminFab;

    // lender state variables
    Fixed27             public minSeniorRatio;
    Fixed27             public maxSeniorRatio;
    uint                public maxReserve;
    uint                public challengeTime;
    Fixed27             public seniorInterestRate;


    // contract addresses
    address             public assessor;
    address             public assessorAdmin;
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

    constructor(address root_, address currency_, address trancheFab_, address memberlistFab_, address restrictedtokenFab_, address reserveFab_, address assessorFab_, address coordinatorFab_, address operatorFab_, address assessorAdminFab_) public {

        deployer = msg.sender;
        root = root_;
        currency = currency_;

        trancheFab = TrancheFabLike(trancheFab_);
        memberlistFab = MemberlistFabLike(memberlistFab_);
        restrictedTokenFab = RestrictedTokenFabLike(restrictedtokenFab_);
        reserveFab = ReserveFabLike(reserveFab_);
        assessorFab = AssessorFabLike(assessorFab_);
        assessorAdminFab = AssessorAdminFabLike(assessorAdminFab_);
        coordinatorFab = CoordinatorFabLike(coordinatorFab_);
        operatorFab = OperatorFabLike(operatorFab_);
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
        AuthLike(juniorMemberlist).rely(root);
        AuthLike(juniorToken).rely(root);
        AuthLike(juniorToken).rely(juniorTranche);
        AuthLike(juniorOperator).rely(root);
        AuthLike(juniorTranche).rely(root);
    }

    function deploySenior() public {
        require(seniorTranche == address(0) && deployer == address(1));
        seniorToken = restrictedTokenFab.newRestrictedToken(seniorName, seniorSymbol);
        seniorTranche = trancheFab.newTranche(currency, seniorToken);
        seniorMemberlist = memberlistFab.newMemberlist();
        seniorOperator = operatorFab.newOperator(seniorTranche);
        AuthLike(seniorMemberlist).rely(root);
        AuthLike(seniorToken).rely(root);
        AuthLike(seniorToken).rely(seniorTranche);
        AuthLike(seniorOperator).rely(root);
        AuthLike(seniorTranche).rely(root);

    }

    function deployReserve() public {
        require(reserve == address(0) && deployer == address(1));
        reserve = reserveFab.newReserve(currency);
        AuthLike(reserve).rely(root);
    }

    function deployAssessor() public {
        require(assessor == address(0) && deployer == address(1));
        assessor = assessorFab.newAssessor();
        AuthLike(assessor).rely(root);
    }

    function deployAssessorAdmin() public {
        require(assessorAdmin == address(0) && deployer == address(1));
        assessorAdmin = assessorAdminFab.newAssessorAdmin();
        AuthLike(assessorAdmin).rely(root);
    }

    function deployCoordinator() public {
        require(coordinator == address(0) && deployer == address(1));
        coordinator = coordinatorFab.newCoordinator(challengeTime);
        AuthLike(coordinator).rely(root);
    }

    function deploy() public {
        require(coordinator != address(0) && assessor != address(0) &&
                reserve != address(0) && seniorTranche != address(0));

        // required depends
        // reserve
        DependLike(reserve).depend("assessor", assessor);
        AuthLike(reserve).rely(seniorTranche);
        AuthLike(reserve).rely(juniorTranche);
        AuthLike(reserve).rely(coordinator);
        AuthLike(reserve).rely(assessor);


        // tranches
        DependLike(seniorTranche).depend("reserve",reserve);
        DependLike(juniorTranche).depend("reserve",reserve);
        AuthLike(seniorTranche).rely(coordinator);
        AuthLike(juniorTranche).rely(coordinator);
        AuthLike(seniorTranche).rely(seniorOperator);
        AuthLike(juniorTranche).rely(juniorOperator);

        // coordinator implements epoch ticker interface
        DependLike(seniorTranche).depend("epochTicker", coordinator);
        DependLike(juniorTranche).depend("epochTicker", coordinator);

        //restricted token
        DependLike(seniorToken).depend("memberlist", seniorMemberlist);
        DependLike(juniorToken).depend("memberlist", juniorMemberlist);

        //allow tinlake contracts to hold drop/tin tokens
        MemberlistLike(juniorMemberlist).updateMember(juniorTranche, uint(-1));
        MemberlistLike(seniorMemberlist).updateMember(seniorTranche, uint(-1));

        // operator
        DependLike(seniorOperator).depend("tranche", seniorTranche);
        DependLike(juniorOperator).depend("tranche", juniorTranche);
        DependLike(seniorOperator).depend("token", seniorToken);
        DependLike(juniorOperator).depend("token", juniorToken);


        // coordinator
        DependLike(coordinator).depend("reserve", reserve);
        DependLike(coordinator).depend("seniorTranche", seniorTranche);
        DependLike(coordinator).depend("juniorTranche", juniorTranche);
        DependLike(coordinator).depend("assessor", assessor);

        // assessor
        DependLike(assessor).depend("seniorTranche", seniorTranche);
        DependLike(assessor).depend("juniorTranche", juniorTranche);
        DependLike(assessor).depend("reserve", reserve);

        AuthLike(assessor).rely(coordinator);
        AuthLike(assessor).rely(reserve);
        AuthLike(assessor).rely(assessorAdmin);

        // assessorAdmin
        DependLike(assessorAdmin).depend("assessor", assessor);

        

        FileLike(assessor).file("seniorInterestRate", seniorInterestRate.value);
        FileLike(assessor).file("maxReserve", maxReserve);
        FileLike(assessor).file("maxSeniorRatio", maxSeniorRatio.value);
        FileLike(assessor).file("minSeniorRatio", minSeniorRatio.value);
    }
}