// File: contracts\modules\Ownable.sol

pragma solidity =0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\interfaces\IVolatility.sol

pragma solidity =0.5.16;

interface IVolatility {
    function calculateIv(uint32 underlying,uint8 optType,uint256 expiration,uint256 currentPrice,uint256 strikePrice)external view returns (uint256);
}
contract ImportVolatility is Ownable{
    IVolatility internal _volatility;
    function getVolatilityAddress() public view returns(address){
        return address(_volatility);
    }
    function setVolatilityAddress(address volatility)public onlyOwner{
        _volatility = IVolatility(volatility);
    }
}

// File: contracts\modules\SmallNumbers.sol

pragma solidity =0.5.16;
    /**
     * @dev Implementation of a Fraction number operation library.
     */
library SmallNumbers {
//    using Fraction for fractionNumber;
    int256 constant private sqrtNum = 1<<120;
    int256 constant private shl = 80;
    uint8 constant private PRECISION   = 32;  // fractional bits
    uint256 constant public FIXED_ONE = uint256(1) << PRECISION; // 0x100000000
    int256 constant public FIXED_64 = 1 << 64; // 0x100000000
    uint256 constant private FIXED_TWO = uint256(2) << PRECISION; // 0x200000000
    int256 constant private FIXED_SIX = int256(6) << PRECISION; // 0x200000000
    uint256 constant private MAX_VAL   = uint256(1) << (256 - PRECISION); // 0x0000000100000000000000000000000000000000000000000000000000000000

    /**
     * @dev Standard normal cumulative distribution function
     */
    function normsDist(int256 xNum) internal pure returns (int256) {
        bool _isNeg = xNum<0;
        if (_isNeg) {
            xNum = -xNum;
        }
        if (xNum > FIXED_SIX){
            return _isNeg ? 0 : int256(FIXED_ONE);
        } 
        // constant int256 b1 = 1371733226;
        // constant int256 b2 = -1531429783;
        // constant int256 b3 = 7651389478;
        // constant int256 b4 = -7822234863;
        // constant int256 b5 = 5713485167;
        //t = 1.0/(1.0 + p*x);
        int256 p = 994894385;
        int256 t = FIXED_64/(((p*xNum)>>PRECISION)+int256(FIXED_ONE));
        //double val = 1 - (1/(Math.sqrt(2*Math.PI))  * Math.exp(-1*Math.pow(a, 2)/2)) * (b1*t + b2 * Math.pow(t,2) + b3*Math.pow(t,3) + b4 * Math.pow(t,4) + b5 * Math.pow(t,5) );
        //1.0 - (-x * x / 2.0).exp()/ (2.0*pi()).sqrt() * t * (a1 + t * (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429)))) ;
        xNum=xNum*xNum/int256(FIXED_TWO);
        xNum = int256(7359186145390886912/fixedExp(uint256(xNum)));
        int256 tt = t;
        int256 All = 1371733226*tt;
        tt = (tt*t)>>PRECISION;
        All += -1531429783*tt;
        tt = (tt*t)>>PRECISION;
        All += 7651389478*tt;
        tt = (tt*t)>>PRECISION;
        All += -7822234863*tt;
        tt = (tt*t)>>PRECISION;
        All += 5713485167*tt;
        xNum = (xNum*All)>>64;
        if (!_isNeg) {
            xNum = uint64(FIXED_ONE) - xNum;
        }
        return xNum;
    }
    function pow(uint256 _x,uint256 _y) internal pure returns (uint256){
        _x = (ln(_x)*_y)>>PRECISION;
        return fixedExp(_x);
    }

    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
        x = x << PRECISION;
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    function ln(uint256 _x)  internal pure returns (uint256) {
        return fixedLoge(_x);
    }
        /**
        input range: 
            [0x100000000,uint256_max]
        output range:
            [0, 0x9b43d4f8d6]

        This method asserts outside of bounds

    */
    function fixedLoge(uint256 _x) internal pure returns (uint256 logE) {
        /*
        Since `fixedLog2_min` output range is max `0xdfffffffff` 
        (40 bits, or 5 bytes), we can use a very large approximation
        for `ln(2)`. This one is used since it’s the max accuracy 
        of Python `ln(2)`

        0xb17217f7d1cf78 = ln(2) * (1 << 56)
        
        */
        //Cannot represent negative numbers (below 1)
        require(_x >= FIXED_ONE,"loge function input is too small");

        uint256 _log2 = fixedLog2(_x);
        logE = (_log2 * 0xb17217f7d1cf78) >> 56;
    }

    /**
        Returns log2(x >> 32) << 32 [1]
        So x is assumed to be already upshifted 32 bits, and 
        the result is also upshifted 32 bits. 
        
        [1] The function returns a number which is lower than the 
        actual value

        input-range : 
            [0x100000000,uint256_max]
        output-range: 
            [0,0xdfffffffff]

        This method asserts outside of bounds

    */
    function fixedLog2(uint256 _x) internal pure returns (uint256) {
        // Numbers below 1 are negative. 
        require( _x >= FIXED_ONE,"Log2 input is too small");

        uint256 hi = 0;
        while (_x >= FIXED_TWO) {
            _x >>= 1;
            hi += FIXED_ONE;
        }

        for (uint8 i = 0; i < PRECISION; ++i) {
            _x = (_x * _x) / FIXED_ONE;
            if (_x >= FIXED_TWO) {
                _x >>= 1;
                hi += uint256(1) << (PRECISION - 1 - i);
            }
        }

        return hi;
    }
    function exp(int256 _x)internal pure returns (uint256){
        bool _isNeg = _x<0;
        if (_isNeg) {
            _x = -_x;
        }
        uint256 value = fixedExp(uint256(_x));
        if (_isNeg){
            return uint256(FIXED_64) / value;
        }
        return value;
    }
    /**
        fixedExp is a ‘protected’ version of `fixedExpUnsafe`, which 
        asserts instead of overflows
    */
    function fixedExp(uint256 _x) internal pure returns (uint256) {
        require(_x <= 0x386bfdba29,"exp function input is overflow");
        return fixedExpUnsafe(_x);
    }
       /**
        fixedExp 
        Calculates e^x according to maclauren summation:

        e^x = 1+x+x^2/2!...+x^n/n!

        and returns e^(x>>32) << 32, that is, upshifted for accuracy

        Input range:
            - Function ok at    <= 242329958953 
            - Function fails at >= 242329958954

        This method is is visible for testcases, but not meant for direct use. 
 
        The values in this method been generated via the following python snippet: 

        def calculateFactorials():
            “”"Method to print out the factorials for fixedExp”“”

            ni = []
            ni.append( 295232799039604140847618609643520000000) # 34!
            ITERATIONS = 34
            for n in range( 1,  ITERATIONS,1 ) :
                ni.append(math.floor(ni[n - 1] / n))
            print( “\n        “.join([“xi = (xi * _x) >> PRECISION;\n        res += xi * %s;” % hex(int(x)) for x in ni]))

    */
    function fixedExpUnsafe(uint256 _x) internal pure returns (uint256) {
    
        uint256 xi = FIXED_ONE;
        uint256 res = 0xde1bc4d19efcac82445da75b00000000 * xi;

        xi = (xi * _x) >> PRECISION;
        res += xi * 0xde1bc4d19efcb0000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x6f0de268cf7e58000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x2504a0cd9a7f72000000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9412833669fdc800000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1d9d4d714865f500000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x4ef8ce836bba8c0000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xb481d807d1aa68000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x16903b00fa354d000000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x281cdaac677b3400000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x402e2aad725eb80000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x5d5a6c9f31fe24000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x7c7890d442a83000000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9931ed540345280000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xaf147cf24ce150000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xbac08546b867d000000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xbac08546b867d00000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xafc441338061b8000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x9c3cabbc0056e000000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x839168328705c80000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x694120286c04a0000;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x50319e98b3d2c400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x3a52a1e36b82020;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x289286e0fce002;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1b0c59eb53400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x114f95b55400;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0xaa7210d200;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x650139600;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x39b78e80;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x1fd8080;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x10fbc0;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x8c40;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x462;
        xi = (xi * _x) >> PRECISION;
        res += xi * 0x22;

        return res / 0xde1bc4d19efcac82445da75b00000000;
    }  
}

// File: contracts\optionsPrice.sol

pragma solidity =0.5.16;



/**
 * @title Options price calculation contract.
 * @dev calculate options' price, using B-S formulas.
 *
 */
contract OptionsPrice is ImportVolatility{
    // one year seconds
    uint256 constant internal Year = 365 days;
    int256 constant public FIXED_ONE = 1 << 32; // 0x100000000
    uint256 internal ratioR2 = 4<<32;
    
    /**
     * @dev constructor function , setting contract address.
     */  
    constructor (address ivContract) public{
        setVolatilityAddress(ivContract);
    }

    /**
     * @dev calculate option's price using B_S formulas
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param underlying option's underlying id, 1 for BTC, 2 for ETH.
     * @param optType option's type, 0 for CALL, 2 for PUT.
     */
    function getOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration,uint32 underlying,uint8 optType)public view returns (uint256){
         uint256 _iv = _volatility.calculateIv(underlying,optType,expiration,currentPrice,strikePrice);
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,_iv);
        }else if (optType == 1){
            return putOptionsPrice(currentPrice,strikePrice,expiration,_iv);
        }else{
            require(optType<2," Must input 0 for call option or 1 for put option");
        }
    }
    /**
     * @dev calculate option's price using B_S formulas with user input iv.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param _iv user input iv numerator.
     * @param optType option's type, 0 for CALL, 2 for PUT.
     */
    function getOptionsPrice_iv(uint256 currentPrice, uint256 strikePrice, uint256 expiration,
            uint256 _iv,uint8 optType)public view returns (uint256){
        if (optType == 0) {
            return callOptionsPrice(currentPrice,strikePrice,expiration,_iv);
        }else if (optType == 1){
            return putOptionsPrice(currentPrice,strikePrice,expiration,_iv);
        }else{
            require(optType<2," Must input 0 for call option or 1 for put option");
        }
    }
    /**
     * @dev An auxiliary function, calculate parameter d1 and d2 in B_S formulas.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param derta implied volatility value in B-S formulas.
     */
    function calculateD1D2(uint256 currentPrice, uint256 strikePrice, uint256 expiration, uint256 derta) 
            internal pure returns (int256,int256) {
        int256 d1 = 0;
        if (currentPrice > strikePrice){
            d1 = int256(SmallNumbers.fixedLoge((currentPrice<<32)/strikePrice));
        }else if (currentPrice<strikePrice){
            d1 = -int256(SmallNumbers.fixedLoge((strikePrice<<32)/currentPrice));
        }
        uint256 derta2 = (derta*derta)>>33;//0.5*derta^2
        derta2 = derta2*expiration/Year;
        d1 = d1+int256(derta2);
        derta2 = SmallNumbers.sqrt(derta2*2);
        d1 = (d1<<32)/int256(derta2);
        return (d1, d1 - int256(derta2));
    }
    /**
     * @dev An auxiliary function, calculate put option price using B_S formulas.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param derta implied volatility value in B-S formulas.
     */
    //L*pow(e,-rT)*(1-N(d2)) - S*(1-N(d1))
    function putOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration, uint256 derta) 
                internal pure returns (uint256) {
       (int256 d1, int256 d2) = calculateD1D2(currentPrice, strikePrice, expiration, derta);
        d1 = SmallNumbers.normsDist(d1);
        d2 = SmallNumbers.normsDist(d2);
        d1 = (FIXED_ONE - d1)*int256(currentPrice);
        d2 = (FIXED_ONE - d2)*int256(strikePrice);
        d1 = d2 - d1;
        int256 minPrice = int256(currentPrice)*12884902;
        return (d1>minPrice) ? uint256(d1>>32) : currentPrice*3/1000;
    }
    /**
     * @dev An auxiliary function, calculate call option price using B_S formulas.
     * @param currentPrice current underlying price.
     * @param strikePrice option's strike price.
     * @param expiration option's expiration left time. Equal option's expiration timestamp - now.
     * @param derta implied volatility value in B-S formulas.
     */
    //S*N(d1)-L*pow(e,-rT)*N(d2)
    function callOptionsPrice(uint256 currentPrice, uint256 strikePrice, uint256 expiration, uint256 derta) 
                internal pure returns (uint256) {
       (int256 d1, int256 d2) = calculateD1D2(currentPrice, strikePrice, expiration, derta);
        d1 = SmallNumbers.normsDist(d1);
        d2 = SmallNumbers.normsDist(d2);
        d1 = d1*int256(currentPrice)-d2*int256(strikePrice);
        int256 minPrice = int256(currentPrice)*12884902;
        return (d1>minPrice) ? uint256(d1>>32) : currentPrice*3/1000;
    }
    function calOptionsPriceRatio(uint256 selfOccupied,uint256 totalOccupied,uint256 totalCollateral) public pure returns (uint256){
        //r1 + 0.5
        if (selfOccupied*2<=totalOccupied){
            return 4294967296;
        }
        uint256 r1 = (selfOccupied<<32)/totalOccupied-2147483648;
        uint256 r2 = (totalOccupied<<32)/totalCollateral*2;
        //r1*r2*1.5
        r1 = (r1*r2)>>32;
        return ((r1*r1*r1)>>64)*3+4294967296;
//        return SmallNumbers.pow(r1,r2);
    }
}