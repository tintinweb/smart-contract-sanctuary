/**
 *Submitted for verification at BscScan.com on 2021-09-29
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

contract NimbusReferralProgramMarketing is Ownable {

    struct Qualification {
        uint Number;
        uint TotalTurnover; 
        uint Percentage; 
        uint FixedReward;
    }

    IBEP20 public immutable NBU;
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
    event ImportUserTurnoverUpdate(address indexed user, uint newPersonalTurnoverAmount, uint previousPersonalTurnoverAmount, uint newStructureTurnover, uint previousStructureTurnover);
    event ImportHeadOfLocationTurnoverUpdate(address indexed headOfLocation, uint previousTurnover, uint newTurnover);
    event ImportHeadOfLocationTurnoverSet(address indexed headOfLocation, uint turnover);
    event ImportRegionalManagerTurnoverUpdate(address indexed headOfLocation, uint previousTurnover, uint newTurnover);
    event ImportRegionalManagerTurnoverSet(address indexed headOfLocation, uint turnover);
    event ImportUserHeadOfLocation(address indexed user, address indexed headOfLocation);
    event UpgradeUserQualification(address indexed user, uint indexed previousQualification, uint indexed newQualification, uint previousStructureTurnOver, uint newStructureTurnover);

    constructor(address _nbu, address _rpUsers, address _vestingContract) {
        require(Address.isContract(_nbu), "NimbusReferralProgramMarketing: _nbu is not a contract");
        require(Address.isContract(_rpUsers), "NimbusReferralProgramMarketing: _rpUsers is not a contract");
        require(Address.isContract(_vestingContract), "NimbusReferralProgramMarketing: _vestingContract is not a contract");

        NBU = IBEP20(_nbu);
        rpUsers = INimbusReferralProgramUsers(_rpUsers);
        vestingContract = INimbusVesting(_vestingContract);
        emit UpdateVestingContract(_vestingContract);
        vestingFirstPeriodDuration = 0;
        vestingSecondPeriodDuration = 90 days;
        airdropProgramCap = 75_000_000e18;
    }

    modifier onlyAllowedContract() {
        require(isAllowedContract[msg.sender], "NimbusReferralProgramMarketing: Provided address is not an allowed contract");
        _;
    }

    modifier onlyRegistrators() {
        require(registrators[msg.sender], "NimbusReferralProgramMarketing: Provided address is not a registrator");
        _;
    }



    function register(uint sponsorId) external returns (uint userId) {
        return _register(msg.sender, sponsorId);
    }

    function registerUser(address user, uint sponsorId) external onlyRegistrators returns (uint userId) {
        return _register(user, sponsorId);
    }

    function registerBySponsorAddress(address sponsor) external returns (uint userId) {
        uint sponsorId = rpUsers.userIdByAddress(sponsor);
        return _register(msg.sender, sponsorId);
    }

    function registerUserBySponsorAddress(address user, address sponsor) external onlyRegistrators returns (uint userId) {
        uint sponsorId = rpUsers.userIdByAddress(sponsor);
        return _register(user, sponsorId);
    }

    function updateReferralProfitAmount(address user, uint amount) external onlyAllowedContract {
        require(rpUsers.userIdByAddress(user) != 0, "NimbusReferralProgramMarketing: User is not a part of referral program");

        _updateReferralProfitAmount(user, amount, 0, false);
    }

    function claimRewards() external {
        (uint userFixedAirdropAmount, uint userVariableAirdropAmount, uint potentialLevel) = getUserRewards(msg.sender);
        if (userFixedAirdropAmount > 0) {
            totalFixedAirdropped += userFixedAirdropAmount;
            vestingContract.vestWithVestType(msg.sender, userFixedAirdropAmount, vestingFirstPeriodDuration, vestingSecondPeriodDuration, 11); 
            emit AirdropFixedReward(msg.sender, userFixedAirdropAmount, potentialLevel);
        }

        if (userVariableAirdropAmount > 0) {
            totalVariableAirdropped += userVariableAirdropAmount;
            vestingContract.vestWithVestType(msg.sender, userVariableAirdropAmount, vestingFirstPeriodDuration, vestingSecondPeriodDuration, 12); 
            emit AirdropVariableReward(msg.sender, userVariableAirdropAmount, potentialLevel);
        }
        require(totalAirdropped() <= airdropProgramCap, "NimbusReferralProgramMarketing: Airdrop program reached its cap");
        emit QualificationUpdated(msg.sender, userQualificationLevel[msg.sender], potentialLevel);
        userQualificationLevel[msg.sender] = potentialLevel;
    }


    function totalAirdropped() public view returns(uint) {
        return totalFixedAirdropped + totalVariableAirdropped;
    }

    function totalTurnover() public view returns(uint total) {
        for (uint i = 0; i < regionalManagers.length; i++) {
            total += regionalManagerTurnover[regionalManagers[i]];
        }
    }

    function getRegionalManagers() public view returns(address[] memory) {
        return regionalManagers;
    }

    function getHeadOfLocations() public view returns(address[] memory) {
        return headOfLocations;
    }



    function canQualificationBeUpgraded(address user) external view returns (bool) {
        uint qualificationLevel = userQualificationLevel[user];
        return _getUserPotentialQualificationLevel(user, qualificationLevel) > qualificationLevel;
    }

    function getUserPotentialQualificationLevel(address user) public view returns (uint) {
        uint qualificationLevel = userQualificationLevel[user];
        return _getUserPotentialQualificationLevel(user, qualificationLevel);
    }

    function userTotalTurnover(address user) public view returns (uint) {
        return userPersonalTurnover[user] + userStructureTurnover[user];
    }

    function getUserRewards(address user) public view returns (uint userFixed, uint userVariable, uint potentialLevel) {
        require(rpUsers.userIdByAddress(user) > 0, "NimbusReferralProgramMarketing: User not registered");
        uint qualificationLevel = userQualificationLevel[user];
        potentialLevel = _getUserPotentialQualificationLevel(user, qualificationLevel);
        require(potentialLevel > qualificationLevel, "NimbusReferralProgramMarketing: User level hasn't changed");
        //uint userTurnover = userTotalTurnover(user);
        uint[] memory userReferrals = rpUsers.getUserReferrals(user);
        if (userReferrals.length == 0) return (0, 0, potentialLevel);

        address[] memory referralAddresses = new address[](userReferrals.length);
        for (uint i; i < userReferrals.length; i++) {
            address referralAddress = rpUsers.userAddressById(userReferrals[i]);
            referralAddresses[i] = referralAddress;
        }
        
        userFixed = _getFixedRewardToBePaidForQualification(user, referralAddresses, userTotalTurnover(user), qualificationLevel, potentialLevel);
        userVariable = _getVariableRewardToBePaidForQualification(referralAddresses, userStructureTurnover[user], potentialLevel);
    }

    function getUserRewardsByLines(address user) public view returns (uint userFixed, address[] memory referralAddresses, uint[] memory linePercentages, uint[] memory lineVariables, uint potentialLevel) {
        require(rpUsers.userIdByAddress(user) > 0, "NimbusReferralProgramMarketing: User not registered");
        uint qualificationLevel = userQualificationLevel[user];
        potentialLevel = _getUserPotentialQualificationLevel(user, qualificationLevel);
        require(potentialLevel > qualificationLevel, "NimbusReferralProgramMarketing: User level hasn't changed");
        //uint userTurnover = userTotalTurnover(user);
        uint[] memory userReferrals = rpUsers.getUserReferrals(user);
        if (userReferrals.length == 0) return (0, new address[](0), new uint[](0), new uint[](0), potentialLevel);
        
        referralAddresses = new address[](userReferrals.length);
        for (uint i; i < userReferrals.length; i++) {
            address referralAddress = rpUsers.userAddressById(userReferrals[i]);
            referralAddresses[i] = referralAddress;
        }

        userFixed = _getFixedRewardToBePaidForQualification(user, referralAddresses, userTotalTurnover(user), qualificationLevel, potentialLevel);
        (linePercentages, lineVariables) = _getVariableRewardToBePaidForQualificationByLines(referralAddresses, userStructureTurnover[user], potentialLevel);
    }



    function _register(address user, uint sponsorId) private returns (uint userId) {
        require(rpUsers.userIdByAddress(user) == 0, "NimbusReferralProgramMarketing: User already registered");
        address sponsor = rpUsers.userAddressById(sponsorId);
        require(sponsor != address(0), "NimbusReferralProgramMarketing: User sponsor address is equal to 0");

        address sponsorAddress = rpUsers.userAddressById(sponsorId);
        if (isHeadOfLocation[sponsorAddress]) {
            userHeadOfLocations[user] = sponsorAddress;
        } else {
            address head = userHeadOfLocations[sponsor];
            if (head != address(0)){
                userHeadOfLocations[user] = head;
            } else {
                emit UserRegisteredWithoutHeadOfLocation(user, sponsorId);
            }
        }
        
        emit UserRegistered(user, sponsorId);   
        return rpUsers.registerUserBySponsorId(user, sponsorId, MARKETING_CATEGORY);
    }

    function _updateReferralProfitAmount(address user, uint amount, uint line, bool isRegionalAmountUpdated) internal {
        if (line == 0) {
            userPersonalTurnover[user] += amount;
            emit UpdateReferralProfitAmount(user, amount, line);
            address userSponsor = rpUsers.userSponsorAddressByAddress(user);
            if (isHeadOfLocation[user]) {
                headOfLocationTurnover[user] += amount;
                address regionalManager = headOfLocationRegionManagers[user];
                regionalManagerTurnover[regionalManager] += amount;
                isRegionalAmountUpdated = true;
            } else if (isRegionManager[user]) {
                regionalManagerTurnover[user] += amount;
                return;
            } else {
                _updateReferralProfitAmount(userSponsor, amount, 1, isRegionalAmountUpdated);
            }
        } else {
            userStructureTurnover[user] += amount;
            emit UpdateReferralProfitAmount(user, amount, line);
            if (isHeadOfLocation[user]) {
                headOfLocationTurnover[user] += amount;
                address regionalManager = headOfLocationRegionManagers[user];
                if (!isRegionalAmountUpdated) {
                    regionalManagerTurnover[regionalManager] += amount;
                    isRegionalAmountUpdated = true;
                }
            } else if (isRegionManager[user]) {
                if (!isRegionalAmountUpdated) regionalManagerTurnover[user] += amount;
                return;
            }

            if (line >= REFERRAL_LINES && !isRegionalAmountUpdated) {
                _updateReferralHeadOfLocationAndRegionalTurnover(user, amount);
                return;
            }

            address userSponsor = rpUsers.userSponsorAddressByAddress(user);
            if (userSponsor == address(0) && !isRegionalAmountUpdated) {
                _updateReferralHeadOfLocationAndRegionalTurnover(user, amount);
                return;
            }

            _updateReferralProfitAmount(userSponsor, amount, ++line, isRegionalAmountUpdated);
        }
    }

    function _updateReferralHeadOfLocationAndRegionalTurnover(address user, uint amount) internal {
        address headOfLocation = userHeadOfLocations[user];
        if (headOfLocation == address(0)) return;
        headOfLocationTurnover[headOfLocation] += amount;
        address regionalManager = headOfLocationRegionManagers[user];
        emit UpdateHeadOfLocationTurnover(headOfLocation, amount);
        if (regionalManager == address(0)) return;
        regionalManagerTurnover[regionalManager] += amount;
        emit UpdateRegionalManagerTurnover(regionalManager, amount);
    }



    function _getUserPotentialQualificationLevel(address user, uint qualificationLevel) internal view returns (uint) {
        if (qualificationLevel >= qualificationsCount) return qualificationsCount - 1;
        
        uint turnover = userTotalTurnover(user);
        for (uint i = qualificationLevel; i < qualificationsCount; i++) {
            if (qualifications[i+1].TotalTurnover > turnover) {
                return i;
            }
        }
        return qualificationsCount - 1; //user gained max qualification
    }

    function _getFixedRewardToBePaidForQualification(address user, address[] memory referralAddresses, uint userTurnover, uint qualificationLevel, uint potentialLevel) internal view returns (uint userFixed) { 
        if (referralAddresses.length == 0) return 0;
        uint turnoverForCalculations;
        uint personalTurnover = userPersonalTurnover[user];
        if (personalTurnover * PERCENTAGE_PRECISION / userTurnover < 5e4) 
            turnoverForCalculations += personalTurnover;
        
        for (uint i; i < referralAddresses.length; i++) {
            uint referralTurnover = userTotalTurnover(referralAddresses[i]);
            if (referralTurnover * PERCENTAGE_PRECISION / userTurnover < 5e4)
                turnoverForCalculations += referralTurnover;            
        }

        if (turnoverForCalculations > 0) {
            for (uint i = qualificationLevel + 1; i <= potentialLevel; i++) {
                uint fixedRewardAmount = qualifications[i].FixedReward;
                if (fixedRewardAmount > 0) {
                    userFixed += fixedRewardAmount * turnoverForCalculations / userTurnover;
                }
            }
        }
    }

    function _getVariableRewardToBePaidForQualification(address[] memory referralAddresses, uint structureTurnover, uint qualification) internal view returns (uint userVariable) {
        uint userQualificationPercentage = qualifications[qualification].Percentage;
        for (uint i; i < referralAddresses.length; i++) {
            uint referralPercentage = qualifications[userQualificationLevel[referralAddresses[i]]].Percentage;
            if (referralPercentage >= userQualificationPercentage) continue;
            userVariable += (userQualificationPercentage - referralPercentage) * structureTurnover / PERCENTAGE_PRECISION;
        }
    }

    function _getVariableRewardToBePaidForQualificationByLines(address[] memory referralAddresses, uint structureTurnover, uint qualification) internal view returns (uint[] memory linePercentages, uint[] memory lineVariables) {
        uint userQualificationPercentage = qualifications[qualification].Percentage;
        linePercentages = new uint[](referralAddresses.length);
        lineVariables = new uint[](referralAddresses.length);
        for (uint i; i < referralAddresses.length; i++) {
            uint referralPercentage = qualifications[userQualificationLevel[referralAddresses[i]]].Percentage;
            if (referralPercentage >= userQualificationPercentage) continue;
            uint linePercentage = userQualificationPercentage - referralPercentage;
            linePercentages[i] = linePercentage;
            lineVariables[i] = linePercentage * structureTurnover / PERCENTAGE_PRECISION;
        }
    }



    function updateVestingContract(address vestingContractAddress) external onlyOwner {
        require(Address.isContract(vestingContractAddress), "NimbusInitialAcquisition: VestingContractAddress is not a contract");
        vestingContract = INimbusVesting(vestingContractAddress);
        emit UpdateVestingContract(vestingContractAddress);
    }

    function updateVestingParams(uint vestingFirstPeriod, uint vestingSecondPeriod) external onlyOwner {
        require(vestingFirstPeriod != vestingFirstPeriodDuration && vestingSecondPeriodDuration != vestingSecondPeriod, "NimbusInitialAcquisition: Same params");
        vestingFirstPeriodDuration = vestingFirstPeriod;
        vestingSecondPeriodDuration = vestingSecondPeriod;
        emit UpdateVestingParams(vestingFirstPeriod, vestingSecondPeriod);
    }

    function updateRegistrator(address registrator, bool isActive) external onlyOwner {
        require(registrator != address(0), "NimbusReferralProgramMarketing: Registrator address is equal to 0");

        registrators[registrator] = isActive;
    }

    function updateAllowedContract(address _contract, bool _isAllowed) external onlyOwner {
        require(Address.isContract(_contract), "NimbusReferralProgramMarketing: Provided address is not a contract");
        isAllowedContract[_contract] = _isAllowed;
    }

    function updateQualifications(uint[] memory totalTurnoverAmounts, uint[] memory percentages, uint[] memory fixedRewards) external onlyOwner {
        require(totalTurnoverAmounts.length == percentages.length && totalTurnoverAmounts.length == fixedRewards.length, "NimbusReferralProgramMarketing: Arrays length are not equal");
        qualificationsCount = 0;

        for (uint i; i < totalTurnoverAmounts.length; i++) {
            _updateQualification(i, totalTurnoverAmounts[i], percentages[i], fixedRewards[i]);
        }
        qualificationsCount = totalTurnoverAmounts.length;
    }

    function updateAirdropProgramCap(uint newAirdropProgramCap) external onlyOwner {
        require(newAirdropProgramCap > 0, "NimbusReferralProgramMarketing: Airdrop cap must be grater then 0");
        airdropProgramCap = newAirdropProgramCap;
        emit UpdateAirdropProgramCap(newAirdropProgramCap);
    }

    function setUserQualification(address user, uint qualification) external onlyOwner {
        _upgradeUserQualification(user, qualification);
    }

    function setUserQualifications(address[] memory users, uint[] memory newQualifications) external onlyOwner {
        require(users.length == newQualifications.length, "NimbusReferralProgramMarketing: Arrays length are not equal");
        for (uint i; i < users.length; i++) {
            _upgradeUserQualification(users[i], newQualifications[i]);
        }
    }

    function addHeadOfLocation(address headOfLocation, address regionalManager) external onlyOwner {
        _addHeadOfLocation(headOfLocation, regionalManager);
    }

    function addHeadOfLocations(address[] memory headOfLocation, address[] memory managers) external onlyOwner {
        require(headOfLocation.length == managers.length, "NimbusReferralProgramMarketing: Arrays length are not equal");
        for (uint i; i < headOfLocation.length; i++) {
            _addHeadOfLocation(headOfLocation[i], managers[i]);
        }
    }

    function removeHeadOfLocation(uint index) external onlyOwner {
        require (headOfLocations.length > index, "NimbusReferralProgramMarketing: Incorrect index");
        address headOfLocation = headOfLocations[index];
        headOfLocations[index] = headOfLocations[headOfLocations.length - 1];
        headOfLocations.pop(); 
        emit RemoveHeadOfLocation(headOfLocation);
    }

    function addRegionalManager(address regionalManager) external onlyOwner {
        _addRegionalManager(regionalManager);
    }

    function addRegionalManagers(address[] memory managers) external onlyOwner {
        for (uint i; i < managers.length; i++) {
            _addRegionalManager(managers[i]);
        }
    }

    function removeRegionalManager(uint index) external onlyOwner {
        require (regionalManagers.length > index, "NimbusReferralProgramMarketing: Incorrect index");
        address regionalManager = regionalManagers[index];
        regionalManagers[index] = regionalManagers[regionalManagers.length - 1];
        regionalManagers.pop(); 
        emit RemoveRegionalManager(regionalManager);
    }

    function importUserHeadOfLocation(address user, address headOfLocation) external onlyOwner {
        _importUserHeadOfLocation(user, headOfLocation);
    }

    function importUserHeadOfLocations(address[] memory users, address[] memory headOfLocationsLocal) external onlyOwner {
        require(users.length == headOfLocationsLocal.length, "NimbusReferralProgramMarketing: Array length missmatch");
        for(uint i = 0; i < users.length; i++) {
            _importUserHeadOfLocation(users[i], headOfLocationsLocal[i]);
        } 
    }
    
    function importUserTurnover(address user, uint personalTurnover, uint structureTurnover, uint levelHint, bool addToCurrentTurnover, bool updateLevel) external onlyOwner {
        _importUserTurnover(user, personalTurnover, structureTurnover, levelHint, addToCurrentTurnover, updateLevel);
    }

    function importUserTurnovers(address[] memory users, uint[] memory personalTurnovers, uint[] memory structureTurnovers, uint[] memory levelsHints, bool addToCurrentTurnover, bool updateLevel) external onlyOwner {
        require(users.length == personalTurnovers.length && 
            users.length == structureTurnovers.length, "NimbusReferralProgramMarketing: Array length missmatch");

        for(uint i = 0; i < users.length; i++) {
            _importUserTurnover(users[i], personalTurnovers[i], structureTurnovers[i], levelsHints[i], addToCurrentTurnover, updateLevel);
        }   
    }

    function importHeadOfLocationTurnover(address headOfLocation, uint turnover, uint levelHint, bool addToCurrentTurnover, bool updateLevel) external onlyOwner {
        _importHeadOfLocationTurnover(headOfLocation, turnover, levelHint, addToCurrentTurnover, updateLevel);
    }

    function importHeadOfLocationTurnovers(address[] memory heads, uint[] memory turnovers, uint[] memory levelsHints, bool addToCurrentTurnover, bool updateLevel) external onlyOwner {
        require(heads.length == turnovers.length, "NimbusReferralProgramMarketing: Array length missmatch");

        for(uint i = 0; i < heads.length; i++) {
            _importHeadOfLocationTurnover(heads[i], turnovers[i], levelsHints[i], addToCurrentTurnover, updateLevel);
        }   
    }

    function importRegionalManagerTurnover(address headOfLocation, uint turnover, uint levelHint, bool addToCurrentTurnover, bool updateLevel) external onlyOwner {
        _importRegionalManagerTurnover(headOfLocation, turnover, levelHint, addToCurrentTurnover, updateLevel);
    }

    function importRegionalManagerTurnovers(address[] memory managers, uint[] memory turnovers, uint[] memory levelsHints, bool addToCurrentTurnover, bool updateLevel) external onlyOwner {
        require(managers.length == turnovers.length, "NimbusReferralProgramMarketing: Array length missmatch");

        for(uint i = 0; i < managers.length; i++) {
            _importRegionalManagerTurnover(managers[i], turnovers[i], levelsHints[i], addToCurrentTurnover, updateLevel);
        }   
    }


    function _addHeadOfLocation(address headOfLocation, address regionalManager) internal {
        require(!isHeadOfLocation[headOfLocation], "NimbusReferralProgramMarketing: Head of location already added");
        require(isRegionManager[regionalManager], "NimbusReferralProgramMarketing: Regional manager exists");
        headOfLocations.push(headOfLocation);
        isHeadOfLocation[headOfLocation] = true;
        headOfLocationRegionManagers[headOfLocation] = regionalManager;
        emit AddHeadOfLocation(headOfLocation, regionalManager);
    }

    function _addRegionalManager(address regionalManager) internal {
        require(!isRegionManager[regionalManager], "NimbusReferralProgramMarketing: Regional manager exist");
        regionalManagers.push(regionalManager);
        isRegionManager[regionalManager] = true;
        emit AddRegionalManager(regionalManager);
    }

    function _upgradeUserQualification(address user, uint qualification) internal {
        require(qualification < qualificationsCount, "NimbusReferralProgramMarketing: Incorrect qualification index");
        require(userQualificationLevel[user] < qualification, "NimbusReferralProgramMarketing: Can't donwgrade user qualification");
        uint newTurnover = qualifications[qualification].TotalTurnover;
        emit UpgradeUserQualification(user, userQualificationLevel[user], qualification, userStructureTurnover[user], newTurnover);
        userQualificationLevel[user] = qualification;
        userStructureTurnover[user] = newTurnover;
    }

    function _importUserHeadOfLocation(address user, address headOfLocation) internal onlyOwner {
        require(isHeadOfLocation[headOfLocation], "NimbusReferralProgramMarketing: Not head of location");
        userHeadOfLocations[user] = headOfLocation;
        emit ImportUserHeadOfLocation(user, headOfLocation);
    }

    function _updateQualification(uint index, uint totalTurnoverAmount, uint percentage, uint fixedReward) internal {
        require(totalTurnoverAmount > 0, "NimbusReferralProgramMarketing: Total turnover amount can't be lower then one");
        qualifications[index] = Qualification(index, totalTurnoverAmount, percentage, fixedReward);
        emit UpdateQualification(index, totalTurnoverAmount, percentage, fixedReward);
    }

    function _importUserTurnover(address user, uint personalTurnover, uint structureTurnover, uint levelHint, bool addToCurrentTurnover, bool updateLevel) private {
        require(rpUsers.userIdByAddress(user) != 0, "NimbusReferralProgramMarketing: User is not registered");
       
       uint actualStructureTurnover;
       if (addToCurrentTurnover) {
           uint previousPersonalTurnover = userPersonalTurnover[user];
           uint previousStructureTurnover = userStructureTurnover[user];

           uint newPersonalTurnover = previousPersonalTurnover + personalTurnover;
           actualStructureTurnover = previousStructureTurnover + structureTurnover;
           emit ImportUserTurnoverUpdate(user, newPersonalTurnover, previousPersonalTurnover, actualStructureTurnover, previousStructureTurnover);
           userPersonalTurnover[user] = newPersonalTurnover;
           userStructureTurnover[user] = actualStructureTurnover;
       } else {
           userPersonalTurnover[user] = personalTurnover;
           userStructureTurnover[user] = structureTurnover;
           emit ImportUserTurnoverSet(user, personalTurnover, structureTurnover);
           actualStructureTurnover = structureTurnover;
       }

       if (updateLevel) {
            uint potentialLevel = _findQualificationLevel(actualStructureTurnover, levelHint);
            if (potentialLevel > 0) {
                userQualificationLevel[user] = potentialLevel;
                emit QualificationUpdated(user, 0, potentialLevel);
            }
       }
        userQualificationOrigin[user] = 1;
    }

    function _importHeadOfLocationTurnover(address headOfLocation, uint turnover, uint levelHint, bool addToCurrentTurnover, bool updateLevel) private {
        require(isHeadOfLocation[headOfLocation], "NimbusReferralProgramMarketing: User is not head of location");
       
       uint actualTurnover;
       if (addToCurrentTurnover) {
           uint previousTurnover = headOfLocationTurnover[headOfLocation];

           actualTurnover = previousTurnover + turnover;
           emit ImportHeadOfLocationTurnoverUpdate(headOfLocation, previousTurnover, actualTurnover);
           headOfLocationTurnover[headOfLocation] = actualTurnover;
       } else {
           headOfLocationTurnover[headOfLocation] = turnover;
           emit ImportHeadOfLocationTurnoverSet(headOfLocation, turnover);
           actualTurnover = turnover;
       }

        if (updateLevel) {
            uint potentialLevel = _findQualificationLevel(actualTurnover, levelHint);
            if (potentialLevel > 0) {
                userQualificationLevel[headOfLocation] = potentialLevel;
                emit QualificationUpdated(headOfLocation, 0, potentialLevel);
            }
        }
        userQualificationOrigin[headOfLocation] = 1;
    }

    function _importRegionalManagerTurnover(address regionalManager, uint turnover, uint levelHint, bool addToCurrentTurnover, bool updateLevel) private {
        require(isRegionManager[regionalManager], "NimbusReferralProgramMarketing: User is not head of location");
        require(levelHint < qualificationsCount, "NimbusReferralProgramMarketing: Incorrect level hint");
       
       uint actualTurnover;
       if (addToCurrentTurnover) {
           uint previousTurnover = regionalManagerTurnover[regionalManager];

           actualTurnover = previousTurnover + turnover;
           emit ImportRegionalManagerTurnoverUpdate(regionalManager, previousTurnover, actualTurnover);
           regionalManagerTurnover[regionalManager] = actualTurnover;
       } else {
           regionalManagerTurnover[regionalManager] = turnover;
           emit ImportRegionalManagerTurnoverSet(regionalManager, turnover);
           actualTurnover = turnover;
       }

        if (updateLevel) {
            uint potentialLevel = _findQualificationLevel(actualTurnover, levelHint);
            if (potentialLevel > 0) {
                userQualificationLevel[regionalManager] = potentialLevel;
                emit QualificationUpdated(regionalManager, 0, potentialLevel);
            }
        }
        userQualificationOrigin[regionalManager] = 1;
    }

    function _findQualificationLevel(uint amount, uint levelHint) internal view returns (uint) {
        if ((levelHint == (qualificationsCount - 1) && amount >= qualifications[levelHint].TotalTurnover) ||
            (amount >= qualifications[levelHint].TotalTurnover && amount < qualifications[levelHint + 1].TotalTurnover)) {
            return levelHint;
        } else {
            require(amount >= qualifications[levelHint].TotalTurnover, "NimbusReferralProgramMarketing: Incorrect hint");
            for (uint i = levelHint; i < qualificationsCount; i++) {
                if (qualifications[i+1].TotalTurnover > amount) {
                    return i;
                }
            }
        }

        return qualificationsCount - 1;
    }
}