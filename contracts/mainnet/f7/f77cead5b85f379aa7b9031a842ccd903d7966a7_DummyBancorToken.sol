pragma solidity ^0.4.11;

/*
    Overflow protected math functions
*/
contract SafeMath {
    /**
        constructor
    */
    function SafeMath() {
    }

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

/*
    Open issues:
    - The formula is not yet super accurate, especially for very small/very high ratios
    - Improve dynamic precision support
*/

contract BancorFormula is SafeMath {

    uint256 constant ONE = 1;
    uint256 constant TWO = 2;
    uint256 constant MAX_FIXED_EXP_32 = 0x386bfdba29;
    string public version = &#39;0.2&#39;;

    function BancorFormula() {
    }

    /**
        @dev given a token supply, reserve, CRR and a deposit amount (in the reserve token), calculates the return for a given change (in the main token)

        Formula:
        Return = _supply * ((1 + _depositAmount / _reserveBalance) ^ (_reserveRatio / 100) - 1)

        @param _supply             token total supply
        @param _reserveBalance     total reserve
        @param _reserveRatio       constant reserve ratio, 1-100
        @param _depositAmount      deposit amount, in reserve token

        @return purchase return amount
    */
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint8 _reserveRatio, uint256 _depositAmount) public constant returns (uint256) {
        // validate input
        require(_supply != 0 && _reserveBalance != 0 && _reserveRatio > 0 && _reserveRatio <= 100);

        // special case for 0 deposit amount
        if (_depositAmount == 0)
            return 0;

        uint256 baseN = safeAdd(_depositAmount, _reserveBalance);
        uint256 temp;

        // special case if the CRR = 100
        if (_reserveRatio == 100) {
            temp = safeMul(_supply, baseN) / _reserveBalance;
            return safeSub(temp, _supply); 
        }

        uint8 precision = calculateBestPrecision(baseN, _reserveBalance, _reserveRatio, 100);
        uint256 resN = power(baseN, _reserveBalance, _reserveRatio, 100, precision);
        temp = safeMul(_supply, resN) >> precision;
        return safeSub(temp, _supply);
     }

    /**
        @dev given a token supply, reserve, CRR and a sell amount (in the main token), calculates the return for a given change (in the reserve token)

        Formula:
        Return = _reserveBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / (_reserveRatio / 100)))

        @param _supply             token total supply
        @param _reserveBalance     total reserve
        @param _reserveRatio       constant reserve ratio, 1-100
        @param _sellAmount         sell amount, in the token itself

        @return sale return amount
    */
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint8 _reserveRatio, uint256 _sellAmount) public constant returns (uint256) {
        // validate input
        require(_supply != 0 && _reserveBalance != 0 && _reserveRatio > 0 && _reserveRatio <= 100 && _sellAmount <= _supply);

        // special case for 0 sell amount
        if (_sellAmount == 0)
            return 0;

        uint256 baseD = safeSub(_supply, _sellAmount);
        uint256 temp1;
        uint256 temp2;

        // special case if the CRR = 100
        if (_reserveRatio == 100) {
            temp1 = safeMul(_reserveBalance, _supply);
            temp2 = safeMul(_reserveBalance, baseD);
            return safeSub(temp1, temp2) / _supply;
        }

        // special case for selling the entire supply
        if (_sellAmount == _supply)
            return _reserveBalance;

        uint8 precision = calculateBestPrecision(_supply, baseD, 100, _reserveRatio);
        uint256 resN = power(_supply, baseD, 100, _reserveRatio, precision);
        temp1 = safeMul(_reserveBalance, resN);
        temp2 = safeMul(_reserveBalance, ONE << precision);
        return safeSub(temp1, temp2) / resN;
    }

    /**
        calculateBestPrecision 
        Predicts the highest precision which can be used in order to compute "base^exp" without exceeding 256 bits in any of the intermediate computations.
        Instead of calculating "base ^ exp", we calculate "e ^ (ln(base) * exp)".
        The value of ln(base) is represented with an integer slightly smaller than ln(base) * 2 ^ precision.
        The larger the precision is, the more accurately this value represents the real value.
        However, function fixedExpUnsafe(x), which calculates e ^ x, is limited to a maximum value of x.
        The limit depends on the precision (e.g, for precision = 32, the maximum value of x is MAX_FIXED_EXP_32).
        Hence before calling the &#39;power&#39; function, we need to estimate an upper-bound for ln(base) * exponent.
        Of course, we should later assert that the value passed to fixedExpUnsafe is not larger than MAX_FIXED_EXP(precision).
        Due to this assertion (made in function fixedExp), functions calculateBestPrecision and fixedExp are tightly coupled.
        Note that the outcome of this function only affects the accuracy of the computation of "base ^ exp".
        Therefore, we do not need to assert that no intermediate result exceeds 256 bits (nor in this function, neither in any of the functions down the calling tree).
    */
    function calculateBestPrecision(uint256 _baseN, uint256 _baseD, uint256 _expN, uint256 _expD) constant returns (uint8) {
        uint8 precision;
        uint256 maxExp = MAX_FIXED_EXP_32;
        uint256 maxVal = lnUpperBound32(_baseN,_baseD) * _expN;
        for (precision = 0; precision < 32; precision += 2) {
            if (maxExp < (maxVal << precision) / _expD)
                break;
            maxExp = (maxExp * 0xeb5ec5975959c565) >> (64-2);
        }
        if (precision == 0)
            return 32;
        return precision+32-2;
    }

    /**
        @dev calculates (_baseN / _baseD) ^ (_expN / _expD)
        Returns result upshifted by precision

        This method is overflow-safe
    */ 
    function power(uint256 _baseN, uint256 _baseD, uint256 _expN, uint256 _expD, uint8 _precision) constant returns (uint256) {
        uint256 logbase = ln(_baseN, _baseD, _precision);
        // Not using safeDiv here, since safeDiv protects against
        // precision loss. It&#39;s unavoidable, however
        // Both `ln` and `fixedExp` are overflow-safe. 
        return fixedExp(safeMul(logbase, _expN) / _expD, _precision);
    }
    
    /**
        input range: 
            - numerator: [1, uint256_max >> precision]    
            - denominator: [1, uint256_max >> precision]
        output range:
            [0, 0x9b43d4f8d6]

        This method asserts outside of bounds
    */
    function ln(uint256 _numerator, uint256 _denominator, uint8 _precision) public constant returns (uint256) {
        // denominator > numerator: less than one yields negative values. Unsupported
        assert(_denominator <= _numerator);

        // log(1) is the lowest we can go
        assert(_denominator != 0 && _numerator != 0);

        // Upper bits are scaled off by precision
        uint256 MAX_VAL = ONE << (256 - _precision);
        assert(_numerator < MAX_VAL);
        assert(_denominator < MAX_VAL);

        return fixedLoge( (_numerator << _precision) / _denominator, _precision);
    }

    /**
        lnUpperBound32 
        Takes a rational number "baseN / baseD" as input.
        Returns an integer upper-bound of the natural logarithm of the input scaled by 2^32.
        We do this by calculating "UpperBound(log2(baseN / baseD)) * Ceiling(ln(2) * 2^32)".
        We calculate "UpperBound(log2(baseN / baseD))" as "Floor(log2((_baseN - 1) / _baseD)) + 1".
        For small values of "baseN / baseD", this sometimes yields a bad upper-bound approximation.
        We therefore cover these cases (and a few more) manually.
        Complexity is O(log(input bit-length)).
    */
    function lnUpperBound32(uint256 _baseN, uint256 _baseD) constant returns (uint256) {
        assert(_baseN > _baseD);

        uint256 scaledBaseN = _baseN * 100000;
        if (scaledBaseN <= _baseD *  271828) // _baseN / _baseD < e^1 (floorLog2 will return 0 if _baseN / _baseD < 2)
            return uint256(1) << 32;
        if (scaledBaseN <= _baseD *  738905) // _baseN / _baseD < e^2 (floorLog2 will return 1 if _baseN / _baseD < 4)
            return uint256(2) << 32;
        if (scaledBaseN <= _baseD * 2008553) // _baseN / _baseD < e^3 (floorLog2 will return 2 if _baseN / _baseD < 8)
            return uint256(3) << 32;

        return (floorLog2((_baseN - 1) / _baseD) + 1) * 0xb17217f8;
    }

    /**
        input range: 
            [0x100000000, uint256_max]
        output range:
            [0, 0x9b43d4f8d6]

        This method asserts outside of bounds

        Since `fixedLog2_min` output range is max `0xdfffffffff` 
        (40 bits, or 5 bytes), we can use a very large approximation
        for `ln(2)`. This one is used since it&#39;s the max accuracy 
        of Python `ln(2)`

        0xb17217f7d1cf78 = ln(2) * (1 << 56)
    */
    function fixedLoge(uint256 _x, uint8 _precision) constant returns (uint256) {
        // cannot represent negative numbers (below 1)
        assert(_x >= ONE << _precision);

        uint256 flog2 = fixedLog2(_x, _precision);
        return (flog2 * 0xb17217f7d1cf78) >> 56;
    }

    /**
        Returns log2(x >> 32) << 32 [1]
        So x is assumed to be already upshifted 32 bits, and 
        the result is also upshifted 32 bits. 
        
        [1] The function returns a number which is lower than the 
        actual value

        input-range : 
            [0x100000000, uint256_max]
        output-range: 
            [0,0xdfffffffff]

        This method asserts outside of bounds

    */
    function fixedLog2(uint256 _x, uint8 _precision) constant returns (uint256) {
        uint256 fixedOne = ONE << _precision;
        uint256 fixedTwo = TWO << _precision;

        // Numbers below 1 are negative. 
        assert( _x >= fixedOne);

        uint256 hi = 0;
        while (_x >= fixedTwo) {
            _x >>= 1;
            hi += fixedOne;
        }

        for (uint8 i = 0; i < _precision; ++i) {
            _x = (_x * _x) / fixedOne;
            if (_x >= fixedTwo) {
                _x >>= 1;
                hi += ONE << (_precision - 1 - i);
            }
        }

        return hi;
    }

    /**
        floorLog2
        Takes a natural number (n) as input.
        Returns the largest integer smaller than or equal to the binary logarithm of the input.
        Complexity is O(log(input bit-length)).
    */
    function floorLog2(uint256 _n) constant returns (uint256) {
        uint8 t = 0;
        for (uint8 s = 128; s > 0; s >>= 1) {
            if (_n >= (ONE << s)) {
                _n >>= s;
                t |= s;
            }
        }

        return t;
    }

    /**
        fixedExp is a &#39;protected&#39; version of `fixedExpUnsafe`, which asserts instead of overflows.
        The maximum value which can be passed to fixedExpUnsafe depends on the precision used.
        The following array maps each precision between 0 and 63 to the maximum value permitted:
        maxExpArray = {
            0xc1               ,0x17a              ,0x2e5              ,0x5ab              ,
            0xb1b              ,0x15bf             ,0x2a0c             ,0x50a2             ,
            0x9aa2             ,0x1288c            ,0x238b2            ,0x4429a            ,
            0x82b78            ,0xfaadc            ,0x1e0bb8           ,0x399e96           ,
            0x6e7f88           ,0xd3e7a3           ,0x1965fea          ,0x30b5057          ,
            0x5d681f3          ,0xb320d03          ,0x15784a40         ,0x292c5bdd         ,
            0x4ef57b9b         ,0x976bd995         ,0x122624e32        ,0x22ce03cd5        ,
            0x42beef808        ,0x7ffffffff        ,0xf577eded5        ,0x1d6bd8b2eb       ,
            0x386bfdba29       ,0x6c3390ecc8       ,0xcf8014760f       ,0x18ded91f0e7      ,
            0x2fb1d8fe082      ,0x5b771955b36      ,0xaf67a93bb50      ,0x15060c256cb2     ,
            0x285145f31ae5     ,0x4d5156639708     ,0x944620b0e70e     ,0x11c592761c666    ,
            0x2214d10d014ea    ,0x415bc6d6fb7dd    ,0x7d56e76777fc5    ,0xf05dc6b27edad    ,
            0x1ccf4b44bb4820   ,0x373fc456c53bb7   ,0x69f3d1c921891c   ,0xcb2ff529eb71e4   ,
            0x185a82b87b72e95  ,0x2eb40f9f620fda6  ,0x5990681d961a1ea  ,0xabc25204e02828d  ,
            0x14962dee9dc97640 ,0x277abdcdab07d5a7 ,0x4bb5ecca963d54ab ,0x9131271922eaa606 ,
            0x116701e6ab0cd188d,0x215f77c045fbe8856,0x3ffffffffffffffff,0x7abbf6f6abb9d087f,
        };
        Since we cannot use an array of constants, we need to approximate the maximum value dynamically.
        For a precision of 32, the maximum value permitted is MAX_FIXED_EXP_32.
        For each additional precision unit, the maximum value permitted increases by approximately 1.9.
        So in order to calculate it, we need to multiply MAX_FIXED_EXP_32 by 1.9 for every additional precision unit.
        And in order to optimize for speed, we multiply MAX_FIXED_EXP_32 by 1.9^2 for every 2 additional precision units.
        Hence the general function for mapping a given precision to the maximum value permitted is:
        - precision = [32, 34, 36, ..., 62]
        - MaxFixedExp(precision) = MAX_FIXED_EXP_32 * 3.61 ^ (precision / 2 - 16)
        Since we cannot use non-integers, we do MAX_FIXED_EXP_32 * 361 ^ (precision / 2 - 16) / 100 ^ (precision / 2 - 16).
        But there is a better approximation, because this "1.9" factor in fact extends beyond a single decimal digit.
        So instead, we use 0xeb5ec5975959c565 / 0x4000000000000000, which yields maximum values quite close to real ones:
        maxExpArray = {
            -------------------,-------------------,-------------------,-------------------,
            -------------------,-------------------,-------------------,-------------------,
            -------------------,-------------------,-------------------,-------------------,
            -------------------,-------------------,-------------------,-------------------,
            -------------------,-------------------,-------------------,-------------------,
            -------------------,-------------------,-------------------,-------------------,
            -------------------,-------------------,-------------------,-------------------,
            -------------------,-------------------,-------------------,-------------------,
            0x386bfdba29       ,-------------------,0xcf8014760e       ,-------------------,
            0x2fb1d8fe07b      ,-------------------,0xaf67a93bb37      ,-------------------,
            0x285145f31a8f     ,-------------------,0x944620b0e5ee     ,-------------------,
            0x2214d10d0112e    ,-------------------,0x7d56e7677738e    ,-------------------,
            0x1ccf4b44bb20d0   ,-------------------,0x69f3d1c9210d27   ,-------------------,
            0x185a82b87b5b294  ,-------------------,0x5990681d95d4371  ,-------------------,
            0x14962dee9dbd672b ,-------------------,0x4bb5ecca961fb9bf ,-------------------,
            0x116701e6ab0967080,-------------------,0x3fffffffffffe6652,-------------------,
        };
    */
    function fixedExp(uint256 _x, uint8 _precision) constant returns (uint256) {
        uint256 maxExp = MAX_FIXED_EXP_32;
        for (uint8 p = 32; p < _precision; p += 2)
            maxExp = (maxExp * 0xeb5ec5975959c565) >> (64-2);
        
        assert(_x <= maxExp);
        return fixedExpUnsafe(_x, _precision);
    }

    /**
        fixedExp 
        Calculates e ^ x according to maclauren summation:

        e^x = 1 + x + x ^ 2 / 2!...+ x ^ n / n!

        and returns e ^ (x >> 32) << 32, that is, upshifted for accuracy

        Input range:
            - Function ok at    <= 242329958953 
            - Function fails at >= 242329958954

        This method is is visible for testcases, but not meant for direct use. 
 
        The values in this method been generated via the following python snippet: 

        def calculateFactorials():
            """Method to print out the factorials for fixedExp"""

            ni = []
            ni.append(295232799039604140847618609643520000000) # 34!
            ITERATIONS = 34
            for n in range(1, ITERATIONS, 1) :
                ni.append(math.floor(ni[n - 1] / n))
            print( "\n        ".join(["xi = (xi * _x) >> _precision;\n        res += xi * %s;" % hex(int(x)) for x in ni]))

    */
    function fixedExpUnsafe(uint256 _x, uint8 _precision) constant returns (uint256) {
        uint256 xi = _x;
        uint256 res = uint256(0xde1bc4d19efcac82445da75b00000000) << _precision;

        res += xi * 0xde1bc4d19efcac82445da75b00000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x6f0de268cf7e5641222ed3ad80000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x2504a0cd9a7f7215b60f9be480000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x9412833669fdc856d83e6f920000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x1d9d4d714865f4de2b3fafea0000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x4ef8ce836bba8cfb1dff2a70000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0xb481d807d1aa66d04490610000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x16903b00fa354cda08920c2000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x281cdaac677b334ab9e732000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x402e2aad725eb8778fd85000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x5d5a6c9f31fe2396a2af000000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x7c7890d442a82f73839400000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x9931ed54034526b58e400000;
        xi = (xi * _x) >> _precision;
        res += xi * 0xaf147cf24ce150cf7e00000;
        xi = (xi * _x) >> _precision;
        res += xi * 0xbac08546b867cdaa200000;
        xi = (xi * _x) >> _precision;
        res += xi * 0xbac08546b867cdaa20000;
        xi = (xi * _x) >> _precision;
        res += xi * 0xafc441338061b2820000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x9c3cabbc0056d790000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x839168328705c30000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x694120286c049c000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x50319e98b3d2c000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x3a52a1e36b82000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x289286e0fce000;
        xi = (xi * _x) >> _precision;
        res += xi * 0x1b0c59eb53400;
        xi = (xi * _x) >> _precision;
        res += xi * 0x114f95b55400;
        xi = (xi * _x) >> _precision;
        res += xi * 0xaa7210d200;
        xi = (xi * _x) >> _precision;
        res += xi * 0x650139600;
        xi = (xi * _x) >> _precision;
        res += xi * 0x39b78e80;
        xi = (xi * _x) >> _precision;
        res += xi * 0x1fd8080;
        xi = (xi * _x) >> _precision;
        res += xi * 0x10fbc0;
        xi = (xi * _x) >> _precision;
        res += xi * 0x8c40;
        xi = (xi * _x) >> _precision;
        res += xi * 0x462;
        xi = (xi * _x) >> _precision;
        res += xi * 0x22;

        return res / 0xde1bc4d19efcac82445da75b00000000;
    }
}


contract BasicERC20Token {
    /* Public variables of the token */
    string public standard = &#39;Token 0.1&#39;;
    string public name = &#39;Ivan\&#39;s Trackable Token&#39;;
    string public symbol = &#39;ITT&#39;;
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;

    /* This creates an array with all balances */
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event BalanceCheck(uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    /* Functions below are specific to this token and
     * not part of the ERC-20 standard */

    function deposit() payable returns (bool success) {
        if (msg.value == 0) return false;
        balances[msg.sender] += msg.value;
        totalSupply += msg.value;
        return true;
    }

    function withdraw(uint256 amount) returns (bool success) {
        if (balances[msg.sender] < amount) return false;
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        if (!msg.sender.send(amount)) {
            balances[msg.sender] += amount;
            totalSupply += amount;
            return false;
        }
        return true;
    }

}


contract DummyBancorToken is BasicERC20Token, BancorFormula {

    string public standard = &#39;Token 0.1&#39;;
    string public name = &#39;Dummy Constant Reserve Rate Token&#39;;
    string public symbol = &#39;DBT&#39;;
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;

    uint8 public ratio = 10; // CRR of 10%

    address public owner = 0x0;

    event Deposit(address indexed sender);
    event Withdraw(uint256 amount);

    /* I can&#39;t make MyEtherWallet send payments as part of constructor calls
     * while creating contracts. So instead of implementing a constructor,
     * we follow the SetUp/TearDown paradigm */
    function setUp(uint256 _initialSupply) payable {
        if (owner != 0) return;
        owner = msg.sender;
        balances[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    function tearDown() {
        if (msg.sender != owner) return;
        selfdestruct(owner);
    }

    function reserveBalance() constant returns (uint256) {
        return this.balance;
    }

    // Our reserve token is always ETH.
    function deposit() payable returns (bool success) {
        if (msg.value == 0) return false;
        uint256 tokensPurchased = calculatePurchaseReturn(totalSupply, reserveBalance(), ratio, msg.value);
        balances[msg.sender] += tokensPurchased;
        totalSupply += tokensPurchased;
        Deposit(msg.sender);
        return true;
    }

    function withdraw(uint256 amount) returns (bool success) {
        if (balances[msg.sender] < amount) return false;
        uint256 ethAmount = calculateSaleReturn(totalSupply, reserveBalance(), ratio, amount);
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        if (!msg.sender.send(ethAmount)) {
            balances[msg.sender] += amount;
            totalSupply += amount;
            return false;
        }
        Withdraw(amount);
        return true;
    }

}