/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

pragma solidity =0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function getOwner() external view returns (address);
    function vest(address user, uint amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface INimbusReferralProgramUsers {
    function userSponsor(uint user) external view returns (uint);
    function registerUser(address user, uint category) external returns (uint);
    function registerUserBySponsorAddress(address user, address sponsorAddress, uint category) external returns (uint);
    function registerUserBySponsorId(address user, uint sponsorId, uint category) external returns (uint);
    function userIdByAddress(address user) external view returns (uint);
    function userAddressById(uint id) external view returns (address);
    function userSponsorAddressByAddress(address user) external view returns (address);
    function getUserReferrals(address user) external view returns (uint[] memory);
}

interface INimbusVesting {
    function vest(address user, uint amount, uint vestingFirstPeriod, uint vestingSecondPeriod) external;
    function vestWithVestType(address user, uint amount, uint vestingFirstPeriodDuration, uint vestingSecondPeriodDuration, uint vestType) external;
    function unvest() external returns (uint unvested);
    function unvestFor(address user) external returns (uint unvested);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function transferOwnership(address transferOwner) external onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

contract NimbusReferralProgramMarketingStorage is Ownable {  
    struct Qualification {
        uint Number;
        uint TotalTurnover; 
        uint Percentage; 
        uint FixedReward;
    }

    IBEP20 public NBU;
    INimbusReferralProgramUsers rpUsers;
    INimbusVesting public vestingContract;

    uint public totalFixedAirdropped;
    uint public totalVariableAirdropped;
    uint public airdropProgramCap;

    uint constant PERCENTAGE_PRECISION = 1e5;
    uint constant MARKETING_CATEGORY = 3;
    uint constant REFERRAL_LINES = 6;

    mapping(address => bool) public isRegionManager;
    mapping(address => bool) public isHeadOfLocation;
    mapping(address => address) public userHeadOfLocations;
    mapping(address => address) public headOfLocationRegionManagers;
    address[] public regionalManagers;
    address[] public headOfLocations;

    mapping(address => uint) public headOfLocationTurnover; //contains the whole structure turnover (more than 6 lines), including userStructureTurnover (only 6 lines turnover)
    mapping(address => uint) public regionalManagerTurnover;
    mapping(address => uint) public userPersonalTurnover;
    mapping(address => uint) public userStructureTurnover;
    mapping(address => uint) public userQualificationLevel;
    mapping(address => uint) public userQualificationOrigin; //0 - organic, 1 - imported, 2 - set
    mapping(address => uint) public userMaxLevelPayment;

    uint public qualificationsCount;
    mapping(uint => Qualification) public qualifications;
    uint public vestingFirstPeriodDuration;
    uint public vestingSecondPeriodDuration;

    mapping(address => bool) public isAllowedContract;
    mapping(address => bool) public registrators;

    event AirdropFixedReward(address indexed user, uint fixedAirdropped, uint indexed qualification);
    event AirdropVariableReward(address indexed user, uint variableAirdropped, uint indexed qualification);
    event QualificationUpdated(address indexed user, uint indexed previousQualificationLevel, uint indexed qualificationLevel);
    event UpdateVestingParams(uint vestingFirstPeriod, uint vestingSecondPeriod);

    event UserRegistered(address user, uint indexed sponsorId);
    event UserRegisteredWithoutHeadOfLocation(address user, uint indexed sponsorId);

    event UpdateReferralProfitAmount(address indexed user, uint amount, uint indexed line);
    event UpdateHeadOfLocationTurnover(address indexed headOfLocation, uint amount);
    event UpdateRegionalManagerTurnover(address indexed regionalManager, uint amount);
    event UpdateVestingContract(address indexed vestingContractAddress);
    event UpdateAirdropProgramCap(uint indexed newAirdropProgramCap);
    event UpdateQualification(uint indexed index, uint indexed totalTurnoverAmount, uint indexed percentage, uint fixedReward);
    event AddHeadOfLocation(address indexed headOfLocation, address indexed regionalManager);
    event RemoveHeadOfLocation(address indexed headOfLocation);
    event AddRegionalManager(address indexed regionalManager);
    event RemoveRegionalManager(address indexed regionalManager);
    event UpdateRegionalManager(address indexed user, bool indexed isManager);
    event ImportUserTurnoverSet(address indexed user, uint personalTurnover, uint structureTurnover);
    event ImportUserMaxLevelPayment(address indexed user, uint maxLevelPayment, bool indexed addToCurrentPayment);
    event ImportUserTurnoverUpdate(address indexed user, uint newPersonalTurnoverAmount, uint previousPersonalTurnoverAmount, uint newStructureTurnover, uint previousStructureTurnover);
    event ImportHeadOfLocationTurnoverUpdate(address indexed headOfLocation, uint previousTurnover, uint newTurnover);
    event ImportHeadOfLocationTurnoverSet(address indexed headOfLocation, uint turnover);
    event ImportRegionalManagerTurnoverUpdate(address indexed headOfLocation, uint previousTurnover, uint newTurnover);
    event ImportRegionalManagerTurnoverSet(address indexed headOfLocation, uint turnover);
    event ImportUserHeadOfLocation(address indexed user, address indexed headOfLocation);
    event UpgradeUserQualification(address indexed user, uint indexed previousQualification, uint indexed newQualification, uint previousStructureTurnOver, uint newStructureTurnover);
    event IncorrectMaxLevelPaymentForUser(address indexed user, uint currentMaxLevelPayment, uint variableReward);
    event ImportPreviousAirdrop(uint previousTotalFixedAirdropped, uint newTotalFixedAirdropped, uint previousTotalVariableAirdropped, uint newTotalVariableAirdropped);
}

contract NimbusReferralProgramMarketingProxy is NimbusReferralProgramMarketingStorage {
    address public target;
    
    event SetTarget(address indexed newTarget);

    constructor(address _newTarget) NimbusReferralProgramMarketingStorage() {
        _setTarget(_newTarget);
    }

    fallback() external payable {
        if (gasleft() <= 2300) {
            return;
        }

        address target_ = target;
        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(gas(), target_, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function setTarget(address _newTarget) external onlyOwner {
        _setTarget(_newTarget);
    }

    function _setTarget(address _newTarget) internal {
        require(Address.isContract(_newTarget), "Target not a contract");
        target = _newTarget;
        emit SetTarget(_newTarget);
    }
}