pragma solidity ^0.4.13;

interface IPremiumCalculator {
    function calculatePremium(
        uint _batteryDesignCapacity,
        uint _currentChargeLevel,
        uint _deviceAgeInMonths,
        string _region,
        string _deviceBrand,
        string _batteryWearLevel
    ) external view returns (uint);

    function validate(
        uint _batteryDesignCapacity, 
        uint _currentChargeLevel,
        uint _deviceAgeInMonths,
        string _region,
        string _deviceBrand,
        string _batteryWearLevel) 
            external 
            view 
            returns (bytes2);
    
    function isClaimable(string _batteryWearLevel
    ) pure returns (bool);

    function getPayout(
    ) external view returns (uint);
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
    uint public payout; // All payouts are equal (AIX in weis)
    uint public loading; // Office fee in percents. example from 1 to 100

    struct Interval {
        uint min;
        uint max;
        uint coefficient;
    }

    mapping (bytes2 => mapping(string => uint) ) coefficients;
    mapping (bytes2 => Interval[]) coefficientIntervals;
    uint constant TOTAL_COEFFICIENTS = 6;
   
    string constant OTHERS = "OTHERS";
    bytes2 constant DESIGN_CAPACITY = "DC";  
    bytes2 constant CHARGE_LEVEL = "CL";  
    bytes2 constant DEVICE_AGE = "DA"; // in months

    bytes2 constant REGION = "R";
    bytes2 constant DEVICE_BRAND = "DB";
    bytes2 constant WEAR_LEVEL = "WL";

    bytes2[] public notValid;
    
    using SafeMath for uint;
    using Strings for string;

    function getPayout() external view returns (uint) {
        return payout;
    }

    function calculatePremium(
        uint _batteryDesignCapacity, 
        uint _currentChargeLevel,
        uint _deviceAgeInMonths,
        string _region,
        string _deviceBrand,
        string _batteryWearLevel) external view returns (uint premium) {
        
        uint cof = getCoefficientMultiplier(_deviceBrand, _region, _batteryWearLevel);

        premium = basePremium.mul(cof);
        cof = getIntervalCoefficientMultiplier(_currentChargeLevel, _deviceAgeInMonths, _batteryDesignCapacity);
        
        premium = premium.mul(cof);

        // uint(100)**TOTAL_COEFFICIENTS is due to each cofficient multiplied by 100 
        premium = premium.mul(100 + loading).div(100).div(uint(100)**TOTAL_COEFFICIENTS);  
    }

    function validate(
        uint _batteryDesignCapacity, 
        uint _currentChargeLevel,
        uint _deviceAgeInMonths,
        string _region,
        string _deviceBrand,
        string _batteryWearLevel) 
            external 
            view 
            returns (bytes2) {
        
        if (coefficients[DEVICE_BRAND][_deviceBrand] == 0) {
            return(DEVICE_BRAND);
        }

        if (coefficients[REGION][_region] == 0) {
            return(REGION);
        }

        if (coefficients[WEAR_LEVEL][_batteryWearLevel] == 0) {
            return(WEAR_LEVEL);
        }

        if (getIntervalCoefficient(DESIGN_CAPACITY, _batteryDesignCapacity) == 0) {
            return(DESIGN_CAPACITY);
        }

        if (getIntervalCoefficient(CHARGE_LEVEL, _currentChargeLevel) == 0) {   
            return(CHARGE_LEVEL);
        }

        if (getIntervalCoefficient(DEVICE_AGE, _deviceAgeInMonths) == 0) {   
            return(DEVICE_AGE);
        }   

        return "";
    }

    function initialize(uint _basePremium, uint _loading, uint _payout) external onlyOwner {
        basePremium = _basePremium;
        loading = _loading;
        payout = _payout;

        // BATTERY DESIGN CAPACITY
        coefficientIntervals[DESIGN_CAPACITY].push(Interval(1000, 3000, 110));
        coefficientIntervals[DESIGN_CAPACITY].push(Interval(3000, 4000, 100));
        coefficientIntervals[DESIGN_CAPACITY].push(Interval(4000, 6000, 110));

        // CHARGE LEVEL
        coefficientIntervals[CHARGE_LEVEL].push(Interval(1, 10, 120));
        coefficientIntervals[CHARGE_LEVEL].push(Interval(10, 20, 110));
        coefficientIntervals[CHARGE_LEVEL].push(Interval(20, 30, 105));
        coefficientIntervals[CHARGE_LEVEL].push(Interval(30, 100, 100));
    
        // DEVICE BRAND
        coefficients[DEVICE_BRAND]["HUAWEI"] = 100;
        coefficients[DEVICE_BRAND]["SAMSUNG"] = 100;
        coefficients[DEVICE_BRAND]["XIAOMI"] = 100;
        coefficients[DEVICE_BRAND]["OPPO"] = 105;
        coefficients[DEVICE_BRAND]["VIVO"] = 105;
        coefficients[DEVICE_BRAND][OTHERS] = 110;

        // DEVICE AGE IN MONTHS
        coefficientIntervals[DEVICE_AGE].push(Interval(0, 6, 90));
        coefficientIntervals[DEVICE_AGE].push(Interval(6, 12, 100));
        coefficientIntervals[DEVICE_AGE].push(Interval(12, 24, 110));
        coefficientIntervals[DEVICE_AGE].push(Interval(24, 60, 120));

        // REGION
        coefficients[REGION]["CA"] = 100;
        coefficients[REGION]["RU"] = 100;
        coefficients[REGION]["MN"] = 100;
        coefficients[REGION]["NO"] = 100;
        coefficients[REGION]["KG"] = 100;
        coefficients[REGION]["FI"] = 100;
        coefficients[REGION]["IS"] = 100;
        coefficients[REGION]["TJ"] = 100;
        coefficients[REGION]["SE"] = 100;
        coefficients[REGION]["EE"] = 100;
        coefficients[REGION]["CH"] = 100;
        coefficients[REGION]["LV"] = 100;
        coefficients[REGION]["LI"] = 100;
        coefficients[REGION]["KP"] = 100;
        coefficients[REGION]["GE"] = 100;
        coefficients[REGION]["BY"] = 100;
        coefficients[REGION]["LT"] = 100;
        coefficients[REGION]["AT"] = 100;
        coefficients[REGION]["KZ"] = 100;
        coefficients[REGION]["SK"] = 100;
        coefficients[REGION]["CN"] = 100;
        coefficients[REGION]["AM"] = 100;
        coefficients[REGION]["BT"] = 100;
        coefficients[REGION]["DK"] = 100;
        coefficients[REGION]["CZ"] = 100;
        coefficients[REGION]["AD"] = 100;
        coefficients[REGION]["PL"] = 100;
        coefficients[REGION]["NP"] = 100;
        coefficients[REGION]["UA"] = 100;
        coefficients[REGION]["CL"] = 100;
        coefficients[REGION]["GB"] = 100;
        coefficients[REGION]["DE"] = 100;
        coefficients[REGION]["US"] = 100;
        coefficients[REGION]["LU"] = 100;
        coefficients[REGION]["RO"] = 100;
        coefficients[REGION]["SI"] = 100;
        coefficients[REGION]["NL"] = 100;
        coefficients[REGION]["IE"] = 100;
        
        coefficients[REGION][OTHERS] = 115;

        // WEAR LEVEL
        coefficients[WEAR_LEVEL]["100"] = 100;
    }

    function getCoefficientMultiplier(string _deviceBrand, string _region, string _batteryWearLevel) 
            public 
            view 
            returns (uint coefficient) {
        uint deviceBrandMultiplier = coefficients[DEVICE_BRAND][OTHERS];
        uint regionMultiplier = coefficients[REGION][OTHERS];
        uint batteryWearLevelMultiplier = coefficients[WEAR_LEVEL][OTHERS];

        if (coefficients[DEVICE_BRAND][_deviceBrand] != 0) {
            deviceBrandMultiplier = coefficients[DEVICE_BRAND][_deviceBrand];
        }
        if (coefficients[REGION][_region] != 0) {
            regionMultiplier = coefficients[REGION][_region];
        }
        if (coefficients[WEAR_LEVEL][_batteryWearLevel] != 0) {
            batteryWearLevelMultiplier = coefficients[WEAR_LEVEL][_batteryWearLevel];
        }
        coefficient = deviceBrandMultiplier 
                .mul(regionMultiplier)
                .mul(batteryWearLevelMultiplier);
    }

    function getIntervalCoefficientMultiplier(uint _currentChargeLevel, uint _deviceAgeInMonths, uint _batteryDesignCapacity)
            public 
            view 
            returns (uint result) {
                
        uint designCapacityMultiplier = getIntervalCoefficient(DESIGN_CAPACITY, _batteryDesignCapacity);
        uint chargeLevelMultiplier = getIntervalCoefficient(CHARGE_LEVEL, _currentChargeLevel); 
        uint deviceAgeInMonthsMultiplier = getIntervalCoefficient(DEVICE_AGE, _deviceAgeInMonths);

        result = chargeLevelMultiplier
                .mul(deviceAgeInMonthsMultiplier)
                .mul(designCapacityMultiplier);
    }

    function getIntervalCoefficient(bytes2 _type, uint _value) 
            public 
            view 
            returns (uint result) {
        for (uint i = 0; i < coefficientIntervals[_type].length; i++) {
            // Check interval exmaple (0, 1] (0 -not included, 1 included)
            if (coefficientIntervals[_type][i].min < _value
                     && _value <= coefficientIntervals[_type][i].max) {
                result = coefficientIntervals[_type][i].coefficient;
                break;
            }
        }
    }

    function isClaimable(string _batteryWearLevel) public pure returns (bool) {      
        if(_batteryWearLevel.equal("10") 
            || _batteryWearLevel.equal("20") 
            || _batteryWearLevel.equal("30")){
            return true;
        } else {
            return false;
        }
    }

    function removeIntervalCoefficient(bytes2 _type, uint _coefficient) external onlyOwner {
        for (uint i = 0; i < coefficientIntervals[_type].length; i++) {
            if (coefficientIntervals[_type][i].coefficient == _coefficient) {
                emit CoefficientRemoved(_type, coefficientIntervals[_type][i].coefficient);
                delete coefficientIntervals[_type][i];
            }
        }
    }

    function setIntervalCoefficient(
            bytes2 _type, 
            uint _index, 
            bool _insert, // 1 insert, 0 update
            uint _minValue, 
            uint _maxValue, 
            uint _coefficient
            ) 
            external 
            onlyOwner {

        if (_insert){
            emit IntervalCoefficientSet(_type, _minValue, _maxValue, _coefficient);
            coefficientIntervals[_type].push(Interval(_minValue, _maxValue, _coefficient));
        } else {
            emit IntervalCoefficientSet(_type, _minValue, _maxValue, _coefficient);
            coefficientIntervals[_type][_index].min = _minValue;
            coefficientIntervals[_type][_index].max = _maxValue;
            coefficientIntervals[_type][_index].coefficient = _coefficient;
        }
    }

    function setCoefficient(bytes2 _type, string _key, uint _coefficient) external onlyOwner {
        emit CoefficientSet(_type, _key, _coefficient);
        coefficients[_type][_key] =_coefficient;
    }

    function setBasePremium(uint _newBasePremium) external onlyOwner {
        emit BasePremiumUpdated(basePremium, _newBasePremium);
        basePremium = _newBasePremium;
    }

    function setLoading(uint _newLoading) external onlyOwner {
        emit LoadingUpdated(loading, _newLoading);
        loading = _newLoading;
    }

    function setPayout(uint _newPayout) external onlyOwner {
        emit PayoutUpdated(payout, _newPayout);
        payout = _newPayout;
    }

    event CoefficientSet(bytes2 coefficientType, string key, uint coefficient);
    event CoefficientRemoved(bytes2 coefficientType, uint coefficient);
    event IntervalCoefficientSet(bytes2 coefficientType, uint minValue, uint maxValue, uint newCoefficient);
    event BasePremiumUpdated(uint oldBasePremium, uint newBasePremium);
    event LoadingUpdated(uint oldLoading, uint newLoading);
    event PayoutUpdated(uint oldPayout, uint newPayout);
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

library Strings {
    function equal(string memory _a, string memory _b) pure internal returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
       
        if (a.length != b.length) {
            return false;
        }
        
        for (uint i = 0; i < a.length; i ++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        
        return true;
    }
}