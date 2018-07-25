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
    
    function isClaimable(int8 _batteryWearLevel
    ) external pure returns (bool);

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
    uint public payout;
    uint public loading;

    struct Interval {
        uint min;
        uint max;
        uint coefficient;
    }

    mapping (bytes2 => mapping(string => uint) ) coefficients;
    mapping (bytes2 => Interval[]) coefficientIntervals;
    uint constant TOTAL_COEFFICIENTS = 6;
   
    string constant DEFAULT = &quot;default&quot;;
    bytes2 constant DESIGN_CAPACITY = &quot;DC&quot;;  
    bytes2 constant CHARGE_LEVEL = &quot;CL&quot;;  
    bytes2 constant DEVICE_AGE = &quot;DA&quot;; // in months

    bytes2 constant REGION = &quot;R&quot;;
    bytes2 constant DEVICE_BRAND = &quot;DB&quot;;
    bytes2 constant WEAR_LEVEL = &quot;WL&quot;;

    bytes2[] public notValid;
    
    using SafeMath for uint;

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

        premium = basePremium * cof;
        cof = getIntervalCoefficientMultiplier(_currentChargeLevel, _deviceAgeInMonths, _batteryDesignCapacity);
        
        premium = premium * cof;

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

        return &quot;&quot;;
    }

    function initialize(uint _basePremium, uint _loading, uint _payout) external onlyOwner {
        basePremium = _basePremium;
        loading = _loading;
        payout = _payout;

        // BATTERY DESIGN CAPACITY
        coefficientIntervals[DESIGN_CAPACITY].push(Interval(3000, 4000, 100));

        // CHARGE LEVEL
        coefficientIntervals[CHARGE_LEVEL].push(Interval(0, 10, 120));
        coefficientIntervals[CHARGE_LEVEL].push(Interval(10, 20, 110));
        coefficientIntervals[CHARGE_LEVEL].push(Interval(20, 30, 105));
        coefficientIntervals[CHARGE_LEVEL].push(Interval(30, 100, 100));
    
        // DEVICE BRAND
        coefficients[DEVICE_BRAND][&quot;huawei&quot;] = 100;
        coefficients[DEVICE_BRAND][&quot;samsung&quot;] = 100;
        coefficients[DEVICE_BRAND][&quot;xiaomi&quot;] = 100;
        coefficients[DEVICE_BRAND][&quot;oppo&quot;] = 105;
        coefficients[DEVICE_BRAND][&quot;vivo&quot;] = 105;
        coefficients[DEVICE_BRAND][DEFAULT] = 110;

        // DEVICE AGE IN MONTHS
        coefficientIntervals[DEVICE_AGE].push(Interval(0, 6, 90));
        coefficientIntervals[DEVICE_AGE].push(Interval(6, 12, 100));
        coefficientIntervals[DEVICE_AGE].push(Interval(12, 24, 110));
        coefficientIntervals[DEVICE_AGE].push(Interval(24, 72, 120));

        // REGION
        coefficients[REGION][&quot;ca&quot;] = 100;
        coefficients[REGION][&quot;ru&quot;] = 100;
        coefficients[REGION][&quot;mn&quot;] = 100;
        coefficients[REGION][&quot;no&quot;] = 100;
        coefficients[REGION][&quot;kg&quot;] = 100;
        coefficients[REGION][&quot;fi&quot;] = 100;
        coefficients[REGION][&quot;is&quot;] = 100;
        coefficients[REGION][&quot;tj&quot;] = 100;
        coefficients[REGION][&quot;se&quot;] = 100;
        coefficients[REGION][&quot;ee&quot;] = 100;
        coefficients[REGION][&quot;ch&quot;] = 100;
        coefficients[REGION][&quot;lv&quot;] = 100;
        coefficients[REGION][&quot;li&quot;] = 100;
        coefficients[REGION][&quot;kp&quot;] = 100;
        coefficients[REGION][&quot;ge&quot;] = 100;
        coefficients[REGION][&quot;by&quot;] = 100;
        coefficients[REGION][&quot;lt&quot;] = 100;
        coefficients[REGION][&quot;at&quot;] = 100;
        coefficients[REGION][&quot;kz&quot;] = 100;
        coefficients[REGION][&quot;sk&quot;] = 100;
        coefficients[REGION][&quot;cn&quot;] = 100;
        coefficients[REGION][&quot;am&quot;] = 100;
        coefficients[REGION][&quot;bt&quot;] = 100;
        coefficients[REGION][&quot;dk&quot;] = 100;
        coefficients[REGION][&quot;cz&quot;] = 100;
        coefficients[REGION][&quot;ad&quot;] = 100;
        coefficients[REGION][&quot;pl&quot;] = 100;
        coefficients[REGION][&quot;np&quot;] = 100;
        coefficients[REGION][&quot;ua&quot;] = 100;
        coefficients[REGION][&quot;cl&quot;] = 100;
        coefficients[REGION][&quot;gb&quot;] = 100;
        coefficients[REGION][&quot;de&quot;] = 100;
        coefficients[REGION][&quot;us&quot;] = 100;
        coefficients[REGION][&quot;lu&quot;] = 100;
        coefficients[REGION][&quot;ro&quot;] = 100;
        coefficients[REGION][&quot;si&quot;] = 100;
        coefficients[REGION][&quot;nl&quot;] = 100;
        coefficients[REGION][&quot;ie&quot;] = 100;
        // TODO: add others
        coefficients[REGION][DEFAULT] = 0;

        // WEAR LEVEL
        coefficients[WEAR_LEVEL][&quot;100&quot;] = 100;
        coefficients[WEAR_LEVEL][DEFAULT] = 0;
    }

    function getCoefficientMultiplier(string _deviceBrand, string _region, string _batteryWearLevel) 
            public 
            view 
            returns (uint coefficient) {
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
        coefficient = deviceBrandMultiplier 
                    * regionMultiplier
                    * batteryWearLevelMultiplier;
    }

    function getIntervalCoefficientMultiplier(uint _currentChargeLevel, uint _deviceAgeInMonths, uint _batteryDesignCapacity)
            public 
            view 
            returns (uint result) {
                
        uint designCapacityMultiplier = getIntervalCoefficient(DESIGN_CAPACITY, _batteryDesignCapacity);
        uint chargeLevelMultiplier = getIntervalCoefficient(CHARGE_LEVEL, _currentChargeLevel); 
        uint deviceAgeInMonthsMultiplier = getIntervalCoefficient(DEVICE_AGE, _deviceAgeInMonths);

        result = chargeLevelMultiplier
                    * deviceAgeInMonthsMultiplier
                    * designCapacityMultiplier;
    }

    function getIntervalCoefficient(bytes2 _type, uint _value) 
            public 
            view 
            returns (uint result) {
        for (uint i = 0; i < coefficientIntervals[_type].length; i++) {
            if (coefficientIntervals[_type][i].min < _value
                     && _value <= coefficientIntervals[_type][i].max) {
                result = coefficientIntervals[_type][i].coefficient;
            }
        }
    }

    function isClaimable(int8 _batteryWearLevel) public pure returns (bool) {      
        if(_batteryWearLevel <= 30) {
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

    function setIntervalCoefficient(bytes2 _type, uint _minValue, uint _maxValue, uint _coefficient) external onlyOwner {
        for (uint i = 0; i < coefficientIntervals[_type].length; i++) {
            if (coefficientIntervals[_type][i].coefficient == _coefficient) {
                emit IntervalCoefficientSet(_type, _minValue, _maxValue, _coefficient);
                coefficientIntervals[_type][i].min = _minValue;
                coefficientIntervals[_type][i].max = _maxValue;
                return;
            }
        }
        emit IntervalCoefficientSet(_type, _minValue, _maxValue, _coefficient);
        coefficientIntervals[_type].push(Interval(_minValue, _maxValue, _coefficient));
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