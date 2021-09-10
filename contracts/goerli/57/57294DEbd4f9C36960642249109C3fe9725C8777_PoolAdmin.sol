/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/lender/admin/pool.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.6;

////// src/lender/admin/pool.sol
/* pragma solidity >=0.7.6; */

interface AssessorLike_3 {
    function file(bytes32 name, uint256 value) external;
}

interface LendingAdapterLike {
    function raise(uint256 amount) external;
    function sink(uint256 amount) external;
    function heal() external;
    function file(bytes32 what, uint value) external;
}

interface FeedLike {
    function overrideWriteOff(uint loan, uint writeOffGroupIndex_) external;
    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) external;
    function file(bytes32 name, uint rate_, uint writeOffPercentage_, uint overdueDays_) external;
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, bytes32 nftID_, uint maturityDate_) external;
    function update(bytes32 nftID_,  uint value) external;
    function update(bytes32 nftID_, uint value, uint risk_) external;
}

interface MemberlistLike_3 {
    function updateMember(address usr, uint256 validUntil) external;
    function updateMembers(address[] calldata users, uint256 validUntil) external;
}

interface CoordinatorLike_2 {
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, bool value) external;
    function poolClosing() external view returns(bool);
}

// Wrapper contract for various pool management tasks.
contract PoolAdmin {
  
    AssessorLike_3        public assessor;
    LendingAdapterLike  public lending;
    FeedLike            public navFeed;
    MemberlistLike_3      public seniorMemberlist;
    MemberlistLike_3      public juniorMemberlist;
    CoordinatorLike_2     public coordinator;

    bool                public live = true;

    mapping (address => uint256) public admin_level;

    uint public constant LEVEL_1 = 1;
    uint public constant LEVEL_2 = 2;
    uint public constant LEVEL_3 = 3;

    modifier level1     { require(admin_level[msg.sender] >= LEVEL_1 && live); _; }
    modifier level2     { require(admin_level[msg.sender] >= LEVEL_2 && live); _; }
    modifier level3     { require(admin_level[msg.sender] == LEVEL_3 && live); _; }

    constructor() {
        admin_level[msg.sender] = LEVEL_3;
        emit Rely(msg.sender, LEVEL_3);
    }

    // --- Liquidity Management, authorized by level 1 admins ---
    event SetMaxReserve(uint256 value);
    event RaiseCreditline(uint256 amount);
    event SinkCreditline(uint256 amount);
    event HealCreditline();
    event UpdateSeniorMember(address indexed usr, uint256 validUntil);
    event UpdateSeniorMembers(address[] indexed users, uint256 validUntil);
    event UpdateJuniorMember(address indexed usr, uint256 validUntil);
    event UpdateJuniorMembers(address[] indexed users, uint256 validUntil);

    // Manage max reserve
    function setMaxReserve(uint256 value) public level1 {
        assessor.file("maxReserve", value);
        emit SetMaxReserve(value);
    }

    // Manage creditline
    function raiseCreditline(uint256 amount) public level1 {
        lending.raise(amount);
        emit RaiseCreditline(amount);
    }

    function sinkCreditline(uint256 amount) public level1 {
        lending.sink(amount);
        emit SinkCreditline(amount);
    }

    function healCreditline() public level1 {
        lending.heal();
        emit HealCreditline();
    }

    function setMaxReserveAndRaiseCreditline(uint256 newMaxReserve, uint256 creditlineRaise) public level1 {
        setMaxReserve(newMaxReserve);
        raiseCreditline(creditlineRaise);
    }

    function setMaxReserveAndSinkCreditline(uint256 newMaxReserve, uint256 creditlineSink) public level1 {
        setMaxReserve(newMaxReserve);
        sinkCreditline(creditlineSink);
    }

    // Manage memberlists
    function updateSeniorMember(address usr, uint256 validUntil) public level1 {
        seniorMemberlist.updateMember(usr, validUntil);
        emit UpdateSeniorMember(usr, validUntil);
    }

    function updateSeniorMembers(address[] memory users, uint256 validUntil) public level1 {
        seniorMemberlist.updateMembers(users, validUntil);
        emit UpdateSeniorMembers(users, validUntil);
    }

    function updateJuniorMember(address usr, uint256 validUntil) public level1 {
        juniorMemberlist.updateMember(usr, validUntil);
        emit UpdateJuniorMember(usr, validUntil);
    }

    function updateJuniorMembers(address[] memory users, uint256 validUntil) public level1 {
        juniorMemberlist.updateMembers(users, validUntil);
        emit UpdateJuniorMembers(users, validUntil);
    }
    
    // --- Risk Management, authorized by level 2 admins ---
    event OverrideWriteOff(uint loan, uint writeOffGroupIndex);
    event AddRiskGroup(uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_);
    event AddRiskGroups(uint[] risks_, uint[] thresholdRatios_, uint[] ceilingRatios_, uint[] rates_);
    event AddWriteOffGroup(uint rate_, uint writeOffPercentage_, uint overdueDays_);
    event SetMatBuffer(uint value);
    event UpdateNFTValue(bytes32 nftID_, uint value);
    event UpdateNFTValueRisk(bytes32 nftID_, uint value, uint risk_);
    event UpdateNFTMaturityDate(bytes32 nftID_, uint maturityDate_);

    function overrideWriteOff(uint loan, uint writeOffGroupIndex_) public level2 {
        navFeed.overrideWriteOff(loan, writeOffGroupIndex_);
        emit OverrideWriteOff(loan, writeOffGroupIndex_);
    }

    function addRiskGroup(uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) public level2 {
        navFeed.file("riskGroup", risk_, thresholdRatio_, ceilingRatio_, rate_, recoveryRatePD_);
        emit AddRiskGroup(risk_, thresholdRatio_, ceilingRatio_, rate_, recoveryRatePD_);
    }

    function addRiskGroups(uint[] memory risks_, uint[] memory thresholdRatios_, uint[] memory ceilingRatios_, uint[] memory rates_, uint[] memory recoveryRatePDs_) public level2 {
        require(risks_.length == thresholdRatios_.length && thresholdRatios_.length == ceilingRatios_.length && ceilingRatios_.length == rates_.length && rates_.length == recoveryRatePDs_.length, "non-matching-arguments");
        for (uint i = 0; i < risks_.length; i++) {
            addRiskGroup(risks_[i], thresholdRatios_[i], ceilingRatios_[i], rates_[i], recoveryRatePDs_[i]);
        }
    }

    function addWriteOffGroup(uint rate_, uint writeOffPercentage_, uint overdueDays_) public level2 {
        navFeed.file("writeOffGroup", rate_, writeOffPercentage_, overdueDays_);
        emit AddWriteOffGroup(rate_, writeOffPercentage_, overdueDays_);
    }

    function addWriteOffGroups(uint[] memory rates_, uint[] memory writeOffPercentages_, uint[] memory overdueDays_) public level2 {
        require(rates_.length == writeOffPercentages_.length && writeOffPercentages_.length == overdueDays_.length, "non-matching-arguments");
        for (uint i = 0; i < rates_.length; i++) {
            addWriteOffGroup(rates_[i], writeOffPercentages_[i], overdueDays_[i]);
        }
    }

    function setMatBuffer(uint value) public level3 {
        lending.file("buffer", value);
        emit SetMatBuffer(value);
    }

    function updateNFTValue(bytes32 nftID_, uint value) public level2 {
        navFeed.update(nftID_, value);
        emit UpdateNFTValue(nftID_, value);
    }

    function updateNFTValueRisk(bytes32 nftID_, uint value, uint risk_) public level2 {
        navFeed.update(nftID_, value, risk_);
        emit UpdateNFTValueRisk(nftID_, value, risk_);
    }

    function updateNFTMaturityDate(bytes32 nftID_, uint maturityDate_) public level2 {
        navFeed.file("maturityDate", nftID_, maturityDate_);
        emit UpdateNFTMaturityDate(nftID_, maturityDate_);
    }

    // --- Pool Governance, authorized by level 3 admins ---
    event File(bytes32 indexed what, bool indexed data);
    event SetSeniorInterestRate(uint value);
    event SetDiscountRate(uint value);
    event SetMinimumEpochTime(uint value);
    event SetChallengeTime(uint value);
    event SetMinSeniorRatio(uint value);
    event SetMaxSeniorRatio(uint value);
    event SetEpochScoringWeights(uint weightSeniorRedeem, uint weightJuniorRedeem, uint weightJuniorSupply, uint weightSeniorSupply);
    event ClosePool();
    event UnclosePool();
    event Rely(address indexed usr, uint indexed level);
    event Deny(address indexed usr);
    event Depend(bytes32 indexed contractname, address addr);

    function setSeniorInterestRate(uint value) public level3 {
        assessor.file("seniorInterestRate", value);
        emit SetSeniorInterestRate(value);
    }

    function setDiscountRate(uint value) public level3 {
        navFeed.file("discountRate", value);
        emit SetDiscountRate(value);
    }

    function setMinimumEpochTime(uint value) public level3 {
        coordinator.file("minimumEpochTime", value);
        emit SetMinimumEpochTime(value);
    }

    function setChallengeTime(uint value) public level3 {
        coordinator.file("challengeTime", value);
        emit SetChallengeTime(value);
    }

    function setMinSeniorRatio(uint value) public level3 {
        assessor.file("minSeniorRatio", value);
        emit SetMinSeniorRatio(value);
    }

    function setMaxSeniorRatio(uint value) public level3 {
        assessor.file("maxSeniorRatio", value);
        emit SetMaxSeniorRatio(value);
    }

    function setEpochScoringWeights(uint weightSeniorRedeem, uint weightJuniorRedeem, uint weightJuniorSupply, uint weightSeniorSupply) public level3 {
        coordinator.file("weightSeniorRedeem", weightSeniorRedeem);
        coordinator.file("weightJuniorRedeem", weightJuniorRedeem);
        coordinator.file("weightJuniorSupply", weightJuniorSupply);
        coordinator.file("weightSeniorSupply", weightSeniorSupply);
        emit SetEpochScoringWeights(weightSeniorRedeem, weightJuniorRedeem, weightJuniorSupply, weightSeniorSupply);
    }

    function closePool() public level3 {
        require(coordinator.poolClosing() == false, "already-closed");
        coordinator.file("poolClosing", true);
        emit ClosePool();
    }

    function unclosePool() public level3 {
        require(coordinator.poolClosing() == true, "not-yet-closed");
        coordinator.file("poolClosing", false);
        emit UnclosePool();
    }

    function rely(address usr, uint level) public level3 {
        require(level > 0 && level <= LEVEL_3, "invalid-level");
        admin_level[usr] = level;
        emit Rely(usr, level);
    }

    function deny(address usr) public level3 {
        admin_level[usr] = 0;
        emit Deny(usr);
    }

    function depend(bytes32 contractName, address addr) public level3 {
        if (contractName == "assessor") {
            assessor = AssessorLike_3(addr);
        } else if (contractName == "lending") {
            lending = LendingAdapterLike(addr);
        } else if (contractName == "seniorMemberlist") {
            seniorMemberlist = MemberlistLike_3(addr);
        } else if (contractName == "juniorMemberlist") {
            juniorMemberlist = MemberlistLike_3(addr);
        } else if (contractName == "navFeed") {
            navFeed = FeedLike(addr);
        } else if (contractName == "coordinator") {
            coordinator = CoordinatorLike_2(addr);
        } else revert();
        emit Depend(contractName, addr);
    }

    function file(bytes32 what, bool data) public level3 {
        live = data;
        emit File(what, data);
    }

}