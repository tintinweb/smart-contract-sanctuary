pragma solidity ^0.4.13;

contract IPremiumCalculator {
    function calculatePremium( 
        uint _currentChargeLevel,
        uint _deviceAgeInMonths,
        uint _totalCpuUsage,
        string _region,
        string _deviceBrand,
        string _batteryWearLevel
    ) public view returns (uint);
    
    function isClaimable() public pure returns (bool);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract PremiumCalculator is Owned, IPremiumCalculator {
    uint public basePremium; // AIX in weis
    uint public loading;

    struct Interval {
        uint min;
        uint max;
        uint coefficient;
    }

    mapping (bytes2 => mapping(string => uint) ) coefficients;
    mapping (bytes2 => Interval[]) coefficientIntervals;
   
    string constant DEFAULT = "default";
    bytes2 constant CHARGE_LEVEL = "CL";  
    bytes2 constant DEVICE_BRAND = "DB";
    bytes2 constant DEVICE_AGE = "DA"; // in months
    bytes2 constant CPU_USAGE = "CU";
    bytes2 constant REGION = "R";
    bytes2 constant WEAR_LEVEL = "WL";
    
    using SafeMath for uint;

    function calculatePremium(
        uint _currentChargeLevel,
        uint _deviceAgeInMonths,
        uint _totalCpuUsage,
        string _region,
        string _deviceBrand,
        string _batteryWearLevel) public view returns (uint) {
       
        // coefficients are multiplied x1000000 is due to Solidity not supporting doubles
        uint c1 = getCoefficientMultiplier(_deviceBrand, _region, _batteryWearLevel);
       
        uint c2 = getIntervalCoefficientMultiplier(_currentChargeLevel, _deviceAgeInMonths, _totalCpuUsage);

        uint riskPremium = basePremium * c1 * c2;

        // 1000000000000 is due to each cofficient multiplied by 100
        uint officePremium = riskPremium * (100 - loading) / 100000000000000; 
        
        return officePremium;
    }

    function initialize(uint _basePremium, uint _loading) external onlyOwner {
        basePremium = _basePremium;
        loading = _loading;

        // CHARGE LEVEL
        coefficientIntervals[CHARGE_LEVEL].push(Interval(0, 10, 120));
        coefficientIntervals[CHARGE_LEVEL].push(Interval(10, 20, 110));
        coefficientIntervals[CHARGE_LEVEL].push(Interval(20, 30, 105));
        coefficientIntervals[CHARGE_LEVEL].push(Interval(30, 100, 100));
    
        // DEVICE BRAND
        coefficients[DEVICE_BRAND]["huawei"] = 100;
        coefficients[DEVICE_BRAND]["samsung"] = 100;
        coefficients[DEVICE_BRAND]["xiaomi"] = 100;
        coefficients[DEVICE_BRAND]["oppo"] = 105;
        coefficients[DEVICE_BRAND]["vivo"] = 105;
        coefficients[DEVICE_BRAND][DEFAULT] = 110;

        // DEVICE AGE IN MONTHS
        coefficientIntervals[DEVICE_AGE].push(Interval(0, 6, 90));
        coefficientIntervals[DEVICE_AGE].push(Interval(6, 12, 100));
        coefficientIntervals[DEVICE_AGE].push(Interval(12, 24, 110));
        coefficientIntervals[DEVICE_AGE].push(Interval(24, 72, 120));

        // CPU USAGE
        coefficientIntervals[CPU_USAGE].push(Interval(0, 10, 95));
        coefficientIntervals[CPU_USAGE].push(Interval(10, 20, 100));
        coefficientIntervals[CPU_USAGE].push(Interval(20, 30, 105));
        coefficientIntervals[CPU_USAGE].push(Interval(30, 100, 110));

        // REGION
        coefficients[REGION]["ca"] = 100;
        coefficients[REGION]["ru"] = 100;
        coefficients[REGION]["mn"] = 100;
        coefficients[REGION]["no"] = 100;
        coefficients[REGION]["kg"] = 100;
        coefficients[REGION]["fi"] = 100;
        coefficients[REGION]["is"] = 100;
        coefficients[REGION]["tj"] = 100;
        coefficients[REGION]["se"] = 100;
        coefficients[REGION]["ee"] = 100;
        coefficients[REGION]["ch"] = 100;
        coefficients[REGION]["lv"] = 100;
        coefficients[REGION]["li"] = 100;
        coefficients[REGION]["kp"] = 100;
        coefficients[REGION]["ge"] = 100;
        coefficients[REGION]["by"] = 100;
        coefficients[REGION]["lt"] = 100;
        coefficients[REGION]["at"] = 100;
        coefficients[REGION]["kz"] = 100;
        coefficients[REGION]["sk"] = 100;
        coefficients[REGION]["cn"] = 100;
        coefficients[REGION]["am"] = 100;
        coefficients[REGION]["bt"] = 100;
        coefficients[REGION]["dk"] = 100;
        coefficients[REGION]["cz"] = 100;
        coefficients[REGION]["ad"] = 100;
        coefficients[REGION]["pl"] = 100;
        coefficients[REGION]["np"] = 100;
        coefficients[REGION]["ua"] = 100;
        coefficients[REGION]["cl"] = 100;
        coefficients[REGION]["gb"] = 100;
        coefficients[REGION]["de"] = 100;
        coefficients[REGION]["us"] = 100;
        coefficients[REGION]["lu"] = 100;
        coefficients[REGION]["ro"] = 100;
        coefficients[REGION]["si"] = 100;
        coefficients[REGION]["nl"] = 100;
        coefficients[REGION]["ie"] = 100;
        // TODO: add others
        coefficients[REGION][DEFAULT] = 0;

        // WEAR LEVEL
        coefficients[WEAR_LEVEL]["100"] = 100;
        coefficients[WEAR_LEVEL][DEFAULT] = 0;
    }

    function getCoefficientMultiplier(string _deviceBrand, string _region, string _batteryWearLevel) public view returns (uint result) {
        uint deviceBrandMultiplier = coefficients[DEVICE_BRAND][DEFAULT];
        uint regionMultiplier = coefficients[REGION][DEFAULT];
        uint batteryWearLevelMultiplier = coefficients[WEAR_LEVEL][DEFAULT];

        if (coefficients[DEVICE_BRAND][_deviceBrand] != 0) {
            deviceBrandMultiplier = coefficients[DEVICE_BRAND][_deviceBrand];
        }

        if (coefficients[REGION][_region] != 0) {
            regionMultiplier = coefficients[REGION][_region];
        }

        if (coefficients[WEAR_LEVEL][_batteryWearLevel] != 0) {
            batteryWearLevelMultiplier = coefficients[WEAR_LEVEL][_batteryWearLevel];
        }

        
        result = deviceBrandMultiplier 
                    * regionMultiplier
                    * batteryWearLevelMultiplier;
    }

    function getIntervalCoefficientMultiplier(uint _currentChargeLevel, uint _deviceAgeInMonths, uint _totalCpuUsage)
    public view returns (uint result) {
        uint totalCpuUsageMultiplier = getCoefficient(CPU_USAGE, _totalCpuUsage); 
        uint chargeLevelMultiplier = getCoefficient(CHARGE_LEVEL, _currentChargeLevel); 
        uint deviceAgeInMonthsMultiplier = getCoefficient(DEVICE_AGE, _deviceAgeInMonths); 

        result = totalCpuUsageMultiplier
                    * chargeLevelMultiplier
                    * deviceAgeInMonthsMultiplier;
    }

    function getCoefficient(bytes2 _type, uint _value) public view returns (uint result) {
        for (uint i = 0; i < coefficientIntervals[_type].length; i++) {
            if (coefficientIntervals[_type][i].min < _value &&
                _value <= coefficientIntervals[_type][i].max) {
                    result = coefficientIntervals[_type][i].coefficient;
                }
        }
    }

    function isClaimable() public pure returns (bool) {

        return false; // TODO:
    }

    function setBasePremium(uint _newBasePremium) external onlyOwner {
        emit BasePremiumUpdated(basePremium, _newBasePremium);
        basePremium = _newBasePremium;
    }

    function setLoading(uint _newLoading) external onlyOwner {
        emit LoadingUpdated(loading, _newLoading);
        loading = _newLoading;
    }

    event BasePremiumUpdated(uint oldBasePremium, uint newBasePremium);
    event LoadingUpdated(uint oldLoading, uint newLoading);
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}