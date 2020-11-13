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

// File: contracts\modules\whiteList.sol

pragma solidity =0.5.16;
    /**
     * @dev Implementation of a whitelist which filters a eligible uint32.
     */
library whiteListUint32 {
    /**
     * @dev add uint32 into white list.
     * @param whiteList the storage whiteList.
     * @param temp input value
     */

    function addWhiteListUint32(uint32[] storage whiteList,uint32 temp) internal{
        if (!isEligibleUint32(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    /**
     * @dev remove uint32 from whitelist.
     */
    function removeWhiteListUint32(uint32[] storage whiteList,uint32 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible uint256.
     */
library whiteListUint256 {
    // add whiteList
    function addWhiteListUint256(uint256[] storage whiteList,uint256 temp) internal{
        if (!isEligibleUint256(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListUint256(uint256[] storage whiteList,uint256 temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}
    /**
     * @dev Implementation of a whitelist which filters a eligible address.
     */
library whiteListAddress {
    // add whiteList
    function addWhiteListAddress(address[] storage whiteList,address temp) internal{
        if (!isEligibleAddress(whiteList,temp)){
            whiteList.push(temp);
        }
    }
    function removeWhiteListAddress(address[] storage whiteList,address temp)internal returns (bool) {
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        if (i<len){
            if (i!=len-1) {
                whiteList[i] = whiteList[len-1];
            }
            whiteList.length--;
            return true;
        }
        return false;
    }
    function isEligibleAddress(address[] memory whiteList,address temp) internal pure returns (bool){
        uint256 len = whiteList.length;
        for (uint256 i=0;i<len;i++){
            if (whiteList[i] == temp)
                return true;
        }
        return false;
    }
    function _getEligibleIndexAddress(address[] memory whiteList,address temp) internal pure returns (uint256){
        uint256 len = whiteList.length;
        uint256 i=0;
        for (;i<len;i++){
            if (whiteList[i] == temp)
                break;
        }
        return i;
    }
}

// File: contracts\modules\Operator.sol

pragma solidity =0.5.16;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Operator is Ownable {
    using whiteListAddress for address[];
    address[] private _operatorList;
    /**
     * @dev modifier, every operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperator() {
        require(_operatorList.isEligibleAddress(msg.sender),"Managerable: caller is not the Operator");
        _;
    }
    /**
     * @dev modifier, Only indexed operator can be granted exclusive access to specific functions. 
     *
     */
    modifier onlyOperatorIndex(uint256 index) {
        require(_operatorList.length>index && _operatorList[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    /**
     * @dev add a new operator by owner. 
     *
     */
    function addOperator(address addAddress)public onlyOwner{
        _operatorList.addWhiteListAddress(addAddress);
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address addAddress)public onlyOwner{
        _operatorList[index] = addAddress;
    }
    /**
     * @dev remove operator by owner. 
     *
     */
    function removeOperator(address removeAddress)public onlyOwner returns (bool){
        return _operatorList.removeWhiteListAddress(removeAddress);
    }
    /**
     * @dev get all operators. 
     *
     */
    function getOperator()public view returns (address[] memory) {
        return _operatorList;
    }
    /**
     * @dev set all operators by owner. 
     *
     */
    function setOperators(address[] memory operators)public onlyOwner {
        _operatorList = operators;
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

// File: contracts\impliedVolatility.sol

pragma solidity =0.5.16;


/**
 * @title Options Implied volatility calculation.
 * @dev A Smart-contract to calculate options Implied volatility.
 *
 */
contract ImpliedVolatility is Operator {
    //Implied volatility decimal, is same with oracle's price' decimal. 
    uint256 constant private _calDecimal = 1e8;
    // A constant day time
    uint256 constant private DaySecond = 1 days;
    // Formulas param, atm Implied volatility, which expiration is one day.
    struct ivParam {
        int48 a;
        int48 b;
        int48 c;
        int48 d;
        int48 e; 
    }
    mapping(uint32=>uint256) internal ATMIv0;
    // Formulas param A,B,C,D,E
    mapping(uint32=>ivParam) internal ivParamMap;
    // Formulas param ATM Iv Rate, sort by time
    mapping(uint32=>uint64[]) internal ATMIvRate;

    constructor () public{
        ATMIv0[1] = 48730000;
        ivParamMap[1] = ivParam(-38611755991,38654705664,-214748365,214748365,4294967296);
        ATMIvRate[1] = [4294967296,4446428991,4537492540,4603231970,4654878626,4697506868,4733852952,4765564595,4793712531,4819032567,
                4842052517,4863164090,4882666130,4900791915,4917727094,4933621868,4948599505,4962762438,4976196728,4988975383,
                5001160887,5012807130,5023960927,5034663202,5044949946,5054852979,5064400575,5073617969,5082527781,5091150366,
                5099504108,5107605667,5115470191,5123111489,5130542192,5137773878,5144817188,5151681926,5158377145,5164911220,
                5171291916,5177526445,5183621518,5189583392,5195417907,5201130526,5206726363,5212210216,5217586590,5222859721,
                5228033600,5233111985,5238098426,5242996276,5247808706,5252538720,5257189164,5261762736,5266262001,5270689395,
                5275047237,5279337732,5283562982,5287724992,5291825675,5295866857,5299850284,5303777626,5307650478,5311470372,
                5315238771,5318957082,5322626652,5326248774,5329824691,5333355597,5336842639,5340286922,5343689509,5347051421,
                5350373645,5353657131,5356902795,5360111520,5363284160,5366421536,5369524445,5372593655,5375629909,5378633924];
        ATMIv0[2] = 48730000;
        ivParamMap[2] = ivParam(-38611755991,38654705664,-214748365,214748365,4294967296);
        ATMIvRate[2] =  ATMIvRate[1];
        //mkr
        ATMIv0[3] = 150000000;
        ivParamMap[3] = ivParam(-38611755991,38654705664,-214748365,214748365,4294967296);
        ATMIvRate[3] =  ATMIvRate[1];
        //snx
        ATMIv0[4] = 200000000;
        ivParamMap[4] = ivParam(-38611755991,38654705664,-214748365,214748365,4294967296);
        ATMIvRate[4] =  ATMIvRate[1];
        //link
        ATMIv0[5] = 180000000;
        ivParamMap[5] = ivParam(-38611755991,38654705664,-214748365,214748365,4294967296);
        ATMIvRate[5] =  ATMIvRate[1];
    }
    /**
     * @dev set underlying's atm implied volatility. Foundation operator will modify it frequently.
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * @param _Iv0 underlying's atm implied volatility. 
     */ 
    function SetAtmIv(uint32 underlying,uint256 _Iv0)public onlyOperatorIndex(0){
        ATMIv0[underlying] = _Iv0;
    }
    function getAtmIv(uint32 underlying)public view returns(uint256){
        return ATMIv0[underlying];
    }
    /**
     * @dev set implied volatility surface Formulas param. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     */ 
    function SetFormulasParam(uint32 underlying,int48 _paramA,int48 _paramB,int48 _paramC,int48 _paramD,int48 _paramE)
        public onlyOwner{
        ivParamMap[underlying] = ivParam(_paramA,_paramB,_paramC,_paramD,_paramE);
    }
    /**
     * @dev set implied volatility surface Formulas param IvRate. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     */ 
    function SetATMIvRate(uint32 underlying,uint64[] memory IvRate)public onlyOwner{
        ATMIvRate[underlying] = IvRate;
    }
    /**
     * @dev Interface, calculate option's iv. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * optType option's type.,0 for CALL, 1 for PUT
     * @param expiration Option's expiration, left time to now.
     * @param currentPrice underlying current price
     * @param strikePrice option's strike price
     */ 
    function calculateIv(uint32 underlying,uint8 /*optType*/,uint256 expiration,uint256 currentPrice,uint256 strikePrice)public view returns (uint256){
        if (underlying>2){
            return (ATMIv0[underlying]<<32)/_calDecimal;
        }
        uint256 iv = calATMIv(underlying,expiration);
        if (currentPrice == strikePrice){
            return iv;
        }
        return calImpliedVolatility(underlying,iv,currentPrice,strikePrice);
    }
    /**
     * @dev calculate option's atm iv. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * @param expiration Option's expiration, left time to now.
     */ 
    function calATMIv(uint32 underlying,uint256 expiration)internal view returns(uint256){
        uint256 index = expiration/DaySecond;
        
        if (index == 0){
            return (ATMIv0[underlying]<<32)/_calDecimal;
        }
        uint256 len = ATMIvRate[underlying].length;
        if (index>=len){
            index = len-1;
        }
        uint256 rate = insertValue(index*DaySecond,(index+1)*DaySecond,ATMIvRate[underlying][index-1],ATMIvRate[underlying][index],expiration);
        return ATMIv0[underlying]*rate/_calDecimal;
    }
    /**
     * @dev calculate option's implied volatility. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * @param _ATMIv atm iv, calculated by calATMIv
     * @param currentPrice underlying current price
     * @param strikePrice option's strike price
     */ 
    function calImpliedVolatility(uint32 underlying,uint256 _ATMIv,uint256 currentPrice,uint256 strikePrice)internal view returns(uint256){
        ivParam memory param = ivParamMap[underlying];
        int256 ln = calImpliedVolLn(underlying,currentPrice,strikePrice,param.d);
        //ln*ln+e
        uint256 lnSqrt = uint256(((ln*ln)>>32) + param.e);
        lnSqrt = SmallNumbers.sqrt(lnSqrt);
        //ln*c+sqrt
        ln = ((ln*param.c)>>32) + int256(lnSqrt);
        ln = (ln* param.b + int256(_ATMIv*_ATMIv))>>32;
        return SmallNumbers.sqrt(uint256(ln+param.a));
    }
    /**
     * @dev An auxiliary function, calculate ln price. 
     * @param underlying underlying ID.,1 for BTC, 2 for ETH
     * @param currentPrice underlying current price
     * @param strikePrice option's strike price
     */ 
    //ln(k) - ln(s) + d
    function calImpliedVolLn(uint32 underlying,uint256 currentPrice,uint256 strikePrice,int48 paramd)internal view returns(int256){
        if (currentPrice == strikePrice){
            return paramd;
        }else if (currentPrice > strikePrice){
            return int256(SmallNumbers.fixedLoge((currentPrice<<32)/strikePrice))+paramd;
        }else{
            return -int256(SmallNumbers.fixedLoge((strikePrice<<32)/currentPrice))+paramd;
        }
    }
    /**
     * @dev An auxiliary function, Linear interpolation. 
     */ 
    function insertValue(uint256 x0,uint256 x1,uint256 y0, uint256 y1,uint256 x)internal pure returns (uint256){
        require(x1 != x0,"input values are duplicated!");
        return y0 + (y1-y0)*(x-x0)/(x1-x0);
    }

}