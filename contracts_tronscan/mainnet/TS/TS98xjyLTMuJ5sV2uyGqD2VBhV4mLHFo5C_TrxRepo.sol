//SourceUnit: REPO.sol

// SPDX-License-Identifier: SimPL-2.0

/**
*
*  ████████╗██████╗ ██╗  ██╗    ██████╗ ███████╗██████╗  ██████╗
*  ╚══██╔══╝██╔══██╗╚██╗██╔╝    ██╔══██╗██╔════╝██╔══██╗██╔═══██╗
*     ██║   ██████╔╝ ╚███╔╝     ██████╔╝█████╗  ██████╔╝██║   ██║
*     ██║   ██╔══██╗ ██╔██╗     ██╔══██╗██╔══╝  ██╔═══╝ ██║   ██║
*     ██║   ██║  ██║██╔╝ ██╗    ██║  ██║███████╗██║     ╚██████╔╝
*     ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝╚═╝      ╚═════╝
*
*
*
*
* TRX REPO DAPP official website
* 
* https://trx-repo.github.io/
* or
* https://trx-repo.netlify.app/
* or
* https://trx-repo.cloud/
*
**/



pragma solidity ^0.5.9;

contract Unit {
    uint256 internal  constant MWEI = 1000000;
}

contract ValidAddress {
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }
}

contract NotThis {
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }
}

contract SafeMath {

    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x); 
        return z;
    }

    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y); 
        return _x - _y;
    }

    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        require(_x == 0 || z / _x == _y);        
        return z;
    }
	
	function safeDiv(uint256 _x, uint256 _y)internal pure returns (uint256){
        require( _y != 0);
        return _x / _y;
	}
	
	function safeMod(uint256 _x, uint256 _y) internal pure returns (uint256){
        require( _y != 0);
        return _x % _y;
    }
}

contract Sqrt {
	function sqrt(uint x) internal pure returns(uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

contract Floor is Unit {
	function floor(uint _x) internal view returns(uint){
		return (_x / MWEI ) * MWEI;
	}
}

contract Ceil is Unit{
	function ceil(uint _x)public view returns(uint ret){
		ret = (_x / MWEI) * MWEI;
		if((_x % MWEI) == 0){
			return ret;
		}else{
			return ret + MWEI;
		}
	}
}

interface IERC20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _holder) external view returns (uint256);
    function allowance(address _holder, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _amount) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool success);
    function approve(address _spender, uint256 _amount) external returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _holder, address indexed _spender, uint256 _amount);
}


contract ErcToken {
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function transferFrom(address _from, address _to, uint _value) public;
}

contract ERC20Token is IERC20Token, SafeMath, ValidAddress {
    uint256 internal constant MAX_TOTAL_ISSUE = 30000000000; 
    uint256 internal constant ISSUE_TYPE_INVEST = 1;
    uint256 internal constant ISSUE_TYPE_SUBSCRIPTION = 2; 

    string  internal m_name = '';
    string  internal m_symbol = '';
    uint8   internal m_decimals = 0;
    uint256 internal m_totalSupply = 0;
    uint256 internal m_total_issue_subscription = 0;
    uint256 internal m_total_issue_invest = 0;
    
    mapping (address => uint256) internal m_balanceOf;
    mapping (address => mapping (address => uint256)) internal m_allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _holder, address indexed _spender, uint256 _amount);

    function name()  public view returns (string memory){
        return m_name;
    }
    function symbol()  public view returns (string memory){
        return m_symbol;
    }
    function decimals()  public view returns (uint8){
        return m_decimals;
    }
    function totalIssue()  public view returns (uint256){
        return m_total_issue_invest +  m_total_issue_subscription;
    }
    function totalSupply()  public view returns (uint256){
        return m_totalSupply;
    }
    function maxTotalIssue()  public view returns (uint256){
        return MAX_TOTAL_ISSUE;
    }

    function balanceOf(address _holder)  public view returns(uint256){
        return m_balanceOf[_holder];
    }
    function allowance(address _holder, address _spender)  public view returns (uint256){
        return m_allowance[_holder][_spender];
    }
    
    function transfer(address _to, uint256 _amount)
        public
        validAddress(_to)
        returns (bool success)
    {
        m_balanceOf[msg.sender] = safeSub(m_balanceOf[msg.sender], _amount);
        m_balanceOf[_to]        = safeAdd(m_balanceOf[_to], _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _amount)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        m_allowance[_from][msg.sender]  = safeSub(m_allowance[_from][msg.sender], _amount);
        m_balanceOf[_from]              = safeSub(m_balanceOf[_from], _amount);
        m_balanceOf[_to]                = safeAdd(m_balanceOf[_to], _amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }


    function approve(address _spender, uint256 _amount)
        public
        validAddress(_spender)
        returns (bool success)
    {
        require(_amount == 0 || m_allowance[msg.sender][_spender] == 0);

        m_allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
}


contract Creator {
    address payable public creator;
    address payable public newCreator;

    constructor() public {
        creator = msg.sender;
    }

    modifier creatorOnly {
        assert(msg.sender == creator);
        _;
    }

    function transferCreator(address payable _newCreator)  public creatorOnly {
        require(_newCreator != creator);
        newCreator = _newCreator;
    }

    function acceptCreator()  public {
        require(msg.sender == newCreator);
        creator = newCreator;
        newCreator = address(0x0);
    }
}

/**
    Provides support and utilities for disable contract functions
*/
contract Disable is Creator {
	bool private disabled;
	
	modifier enabled {
		assert(!disabled);
		_;
	}
	
	function disable(bool _disable) public creatorOnly {
		disabled = _disable;
	}
}


contract SmartToken is  Creator, ERC20Token, NotThis {

    bool public transfersEnabled = true;    

    event NewSmartToken(address _token);
    event Issuance(uint256 _amount);
    event Destruction(uint256 _amount);


    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }


    function disableTransfers(bool _disable)  public creatorOnly {
        transfersEnabled = !_disable;
    }
    

    function issue(address _to, uint256 _amount)
        private
        validAddress(_to)
        notThis(_to)
    {
        m_totalSupply = safeAdd(m_totalSupply, _amount);
        m_balanceOf[_to] = safeAdd(m_balanceOf[_to], _amount);

        emit Issuance(_amount);
        emit Transfer(address(0), _to, _amount);
    }
    
    function vailIssue(address _to, uint256 _amount,uint256 issueType)
        internal
        validAddress(_to)
        notThis(_to)
    {
        if(issueType==ISSUE_TYPE_INVEST){
             _amount = (m_total_issue_invest + _amount) > safeDiv(MAX_TOTAL_ISSUE,2) ? safeSub(safeDiv(MAX_TOTAL_ISSUE,2),m_total_issue_invest):_amount;
            if(_amount>0){
                issue(_to, _amount);
                m_total_issue_invest = safeAdd(m_total_issue_invest,_amount);
            }
        }
        if(issueType==ISSUE_TYPE_SUBSCRIPTION){
             _amount = (m_total_issue_subscription + _amount) > safeDiv(MAX_TOTAL_ISSUE,2) ? safeSub(safeDiv(MAX_TOTAL_ISSUE,2),m_total_issue_subscription):_amount;
            if(_amount>0){
                 issue(_to, _amount);
                 m_total_issue_subscription = safeAdd(m_total_issue_subscription,_amount);
            }
        }
    }
    
    function destroy(address _from, uint256 _amount)   internal {
        m_balanceOf[_from] = safeSub(m_balanceOf[_from], _amount);
        m_totalSupply = safeSub(m_totalSupply, _amount);

        emit Transfer(_from, address(0), _amount);
        emit Destruction(_amount);
    }
    
    function transfer(address _to, uint256 _amount)   public transfersAllowed returns (bool success){
        return super.transfer(_to, _amount);
    }
    
    function transferFrom(address _from, address _to, uint256 _amount)   public transfersAllowed returns (bool success){
        return super.transferFrom(_from, _to, _amount);
    }
}


contract Formula is SafeMath {

    uint256 internal constant ONE = 1; 
    uint32 internal constant MAX_WEIGHT = 1000000;
    uint8 internal constant MIN_PRECISION = 32;
    uint8 internal constant MAX_PRECISION = 127;

    /**
        The values below depend on MAX_PRECISION. If you choose to change it:
        Apply the same change in file 'PrintIntScalingFactors.py', run it and paste the results below.
    */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x1ffffffffffffffffffffffffffffffff;

    /**
        The values below depend on MAX_PRECISION. If you choose to change it:
        Apply the same change in file 'PrintLn2ScalingFactors.py', run it and paste the results below.
    */
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
        The values below depend on MIN_PRECISION and MAX_PRECISION. If you choose to change either one of them:
        Apply the same change in file 'PrintFunctionBancorFormula.py', run it and paste the results below.
    */
    uint256[128] private maxExpArray;

    constructor () public {


        maxExpArray[ 32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[ 33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[ 34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[ 35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[ 36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[ 37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[ 38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[ 39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[ 40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[ 41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[ 42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[ 43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[ 44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[ 45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[ 46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[ 47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[ 48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[ 49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[ 50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[ 51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[ 52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[ 53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[ 54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[ 55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[ 56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[ 57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[ 58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[ 59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[ 60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[ 61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[ 62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[ 63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[ 64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[ 65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[ 66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[ 67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[ 68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[ 69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[ 70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[ 71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[ 72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[ 73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[ 74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[ 75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[ 76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[ 77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[ 78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[ 79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[ 80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[ 81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[ 82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[ 83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[ 84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[ 85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[ 86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[ 87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[ 88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[ 89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[ 90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[ 91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[ 92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[ 93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[ 94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[ 95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[ 96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[ 97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[ 98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[ 99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    /**
        @dev given a token supply, connector balance, weight and a deposit amount (in the connector token),
        calculates the return for a given conversion (in the main token)

        Formula:
        Return = _supply * ((1 + _depositAmount / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)

        @param _supply              token total supply
        @param _connectorBalance    total connector balance
        @param _connectorWeight     connector weight, represented in ppm, 1-1000000
        @param _depositAmount       deposit amount, in connector token

        @return purchase return amount
    */
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) internal view returns (uint256) {
        // validate input
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT);

        // special case for 0 deposit amount
        if (_depositAmount == 0)
            return 0;

        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT)
            return safeMul(_supply, _depositAmount) / _connectorBalance;

        uint256 result;
        uint8 precision;
        uint256 baseN = safeAdd(_depositAmount, _connectorBalance);
        (result, precision) = power(baseN, _connectorBalance, _connectorWeight, MAX_WEIGHT);
        uint256 temp = safeMul(_supply, result) >> precision;
        return temp - _supply;
    }

    /**
        @dev given a token supply, connector balance, weight and a sell amount (in the main token),
        calculates the return for a given conversion (in the connector token)

        Formula:
        Return = _connectorBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / (_connectorWeight / 1000000)))

        @param _supply              token total supply
        @param _connectorBalance    total connector
        @param _connectorWeight     constant connector Weight, represented in ppm, 1-1000000
        @param _sellAmount          sell amount, in the token itself

        @return sale return amount
    */
    function calculateRedeemReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) internal view returns (uint256) {
        // validate input
        require(_supply > 0 && _connectorBalance > 0 && _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT && _sellAmount <= _supply);

        // special case for 0 sell amount
        if (_sellAmount == 0)
            return 0;

        // special case for selling the entire supply
        if (_sellAmount == _supply)
            return _connectorBalance;

        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT)
            return safeMul(_connectorBalance, _sellAmount) / _supply;

        uint256 result;
        uint8 precision;
        uint256 baseD = _supply - _sellAmount;
        (result, precision) = power(_supply, baseD, MAX_WEIGHT, _connectorWeight);
        uint256 temp1 = safeMul(_connectorBalance, result);
        uint256 temp2 = _connectorBalance << precision;
        return (temp1 - temp2) / result;
    }
    
    /**
        General Description:
            Determine a value of precision.
            Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
            Return the result along with the precision used.

        Detailed Description:
            Instead of calculating "base ^ exp", we calculate "e ^ (ln(base) * exp)".
            The value of "ln(base)" is represented with an integer slightly smaller than "ln(base) * 2 ^ precision".
            The larger "precision" is, the more accurately this value represents the real value.
            However, the larger "precision" is, the more bits are required in order to store this value.
            And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
            This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
            Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
            This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
            This functions assumes that "_expN < (1 << 256) / ln(MAX_NUM, 1)", otherwise the multiplication should be replaced with a "safeMul".
    */
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) private view returns (uint256, uint8) {
        
        uint256 lnBaseTimesExp = ln(_baseN, _baseD) * _expN / _expD;
        uint8 precision = findPositionInMaxExpArray(lnBaseTimesExp);
        assert(precision >= MIN_PRECISION);                                     //hhj+ move from findPositionInMaxExpArray
        return (fixedExp(lnBaseTimesExp >> (MAX_PRECISION - precision), precision), precision);
    }

  
    /**
        Return floor(ln(numerator / denominator) * 2 ^ MAX_PRECISION), where:
        - The numerator   is a value between 1 and 2 ^ (256 - MAX_PRECISION) - 1
        - The denominator is a value between 1 and 2 ^ (256 - MAX_PRECISION) - 1
        - The output      is a value between 0 and floor(ln(2 ^ (256 - MAX_PRECISION) - 1) * 2 ^ MAX_PRECISION)
        This functions assumes that the numerator is larger than or equal to the denominator, because the output would be negative otherwise.
    */
    function ln(uint256 _numerator, uint256 _denominator) private pure returns (uint256) {
        assert(_numerator <= MAX_NUM);

        uint256 res = 0;
        uint256 x = _numerator * FIXED_1 / _denominator;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return res * LN2_NUMERATOR / LN2_DENOMINATOR;
    }

    /**
        Compute the largest integer smaller than or equal to the binary logarithm of the input.
    */
    function floorLog2(uint256 _n) private pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        }
        else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
        The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
        - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
        - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
    */
    function findPositionInMaxExpArray(uint256 _x) private  view returns (uint8) {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= _x)
                lo = mid;
            else
                hi = mid;
        }

        if (maxExpArray[hi] >= _x)
            return hi;
        if (maxExpArray[lo] >= _x)
            return lo;

        //assert(false);                                                        // move to power
        return 0;
    }

    /**
        This function can be auto-generated by the script 'PrintFunctionFixedExp.py'.
        It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
        It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
        The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
        The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
    */
    function fixedExp(uint256 _x, uint8 _precision) private pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision;
        res += xi * 0x03442c4e6074a82f1797f72ac0000000; // add x^2 * (33! / 2!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0116b96f757c380fb287fd0e40000000; // add x^3 * (33! / 3!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0045ae5bdd5f0e03eca1ff4390000000; // add x^4 * (33! / 4!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000defabf91302cd95b9ffda50000000; // add x^5 * (33! / 5!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0002529ca9832b22439efff9b8000000; // add x^6 * (33! / 6!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000054f1cf12bd04e516b6da88000000; // add x^7 * (33! / 7!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000a9e39e257a09ca2d6db51000000; // add x^8 * (33! / 8!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000012e066e7b839fa050c309000000; // add x^9 * (33! / 9!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x0000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x000000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision;
        res += xi * 0x00000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }
} 


contract Constant is Unit{
    uint256 internal constant ONE_DAY                           = 86400;
    uint256 internal constant ONE_HOUR                          = 3600; 
    uint256 internal constant UP_NODE_CONTER                    = 15;     
    uint256 internal constant SPEND_PERSENT_EVERY_DATE          = 1;    
    uint256 internal constant MAX_DAY                           = 10;    
    function getAdjustedNow() internal view returns(uint256){
       return   now+ONE_HOUR*9;
    }
    function getAdjustedDate()internal view returns(uint256)
    {
        return (now+ONE_HOUR*9) - (now+ONE_HOUR*9)%ONE_DAY - ONE_HOUR*9;
    }
    
}


/**
    RepoToken implementation
*/
contract RepoToken is SmartToken, Constant, Floor, Sqrt, Formula   {
    uint32  internal weight    = MAX_WEIGHT;               // 100%
    uint256 internal reserve;
    uint256 internal profitPool;
    mapping (address => uint256) internal stakingOf;
    mapping (address => uint256) internal lastDay4ProfitOf;
    mapping (address => uint256) internal profitedOf;
    uint256 internal totalProfited;
    uint256 internal totalDestroyed;
    mapping (address => uint256) internal rewardOf;
    
    ErcToken constant  usdtToken = ErcToken(0x41A614F803B6FD780986A42C78EC9C7F77E6DED13C); 
    
    constructor() public{
        m_name = "REPO Token";
        m_symbol = "REPO";
        m_decimals = 6;
    }
    
    function issueToken(address _holder, address _parent, uint256 _value, uint256 _sonCount)  internal {
        uint256 amount = floor(safeDiv(_value, 1500));
        if(amount>0){
            if(_parent != address(0)) {
                vailIssue(_parent, MWEI,ISSUE_TYPE_INVEST);
            }
            vailIssue(_holder, amount,ISSUE_TYPE_INVEST);
        }
        if(_parent != address(0)){
            uint256 tokenAmount =  safeDiv(safeSub(_sonCount,rewardOf[_parent]),UP_NODE_CONTER);
            if(tokenAmount>0){
                vailIssue(_parent, safeMul(tokenAmount,MWEI),ISSUE_TYPE_INVEST);
                rewardOf[_parent] = safeAdd(rewardOf[_parent],safeMul(tokenAmount,UP_NODE_CONTER));
            }
        }
        
        _value = safeDiv(_value, 25);                                           // 4%
        profitPool = safeAdd(profitPool, _value);
        reserve = safeAdd(reserve, _value);
        adjustWeight();
        emitPrice();
    }
    
    function destroy(address _from, uint256 _amount)   internal {
        super.destroy(_from, _amount);
        totalDestroyed = safeAdd(totalDestroyed, _amount);
    }
    
    function calcWeight(uint256 _reserve)  public pure returns (uint32 weight_) {
        weight_ = uint32(safeDiv(safeMul(MAX_WEIGHT, 2e9), sqrt(_reserve)));
        if(weight_ > MAX_WEIGHT) weight_ = MAX_WEIGHT;
    }
    
    // adjust weight when reserve changed
    function adjustWeight()  internal {
        weight = calcWeight(reserve);
    }
    
    // tax 10% when transfer or unstake
    event Tax(address _to, uint256 _amount);
    function tax(address _to, uint256 _amount)  internal {
        if(_to == address(this)) return;                                           // no tax when stake
            
        destroy(_to, _amount / 10);
        emit Tax(_to, _amount / 10);
        emitPrice();
    }
    
    function transfer(address _to, uint256 _amount)  public transfersAllowed returns (bool success){
        success = super.transfer(_to, _amount);
        tax(_to, _amount);
    }
    
    function transferFrom(address _from, address _to, uint256 _amount)  public transfersAllowed returns (bool success){
        success = super.transferFrom(_from, _to, _amount);
        tax(_to, _amount);
    }
    
    function totalStaking()  public view returns (uint256){
        return balanceOf(address(this));
    }
    
    event Stake(address _holder, uint256 _amount);
    function stake(uint256 _amount)  public returns (bool success){
        success = transfer(address(this), _amount);
        stakingOf[msg.sender] = safeAdd(stakingOf[msg.sender], _amount);
        lastDay4ProfitOf[msg.sender] = getAdjustedNow() / ONE_DAY;
        emit Stake(msg.sender, _amount);
    }
    
    event Unstake(address _holder, uint256 _amount);
    function unstake(uint256 _amount)  public returns (bool success){
        stakingOf[msg.sender] = safeSub(stakingOf[msg.sender], _amount);
        success = this.transfer(msg.sender, _amount);
        emit Unstake(msg.sender, _amount);
    }
    
    function profitingOf(address _holder)  internal view returns (uint256){
        uint256 day = safeSub( getAdjustedNow() / ONE_DAY, lastDay4ProfitOf[_holder]);
        if(day < 1) return 0;
        if(totalStaking() == 0) return 0;
        if(stakingOf[_holder] * day > totalStaking())
            return profitPool / 10;
        else
            return profitPool / 10 * stakingOf[_holder] * day / totalStaking();
    }
    
    event DivideProfit(address _holder, uint256 _value);
    function divideProfit()  public returns (uint256 profit){
        profit = profitingOf(msg.sender);
        profitedOf[msg.sender] = safeAdd(profitedOf[msg.sender], profit);
        totalProfited = safeAdd(totalProfited, profit);
        profitPool = safeSub(profitPool, profit);
        lastDay4ProfitOf[msg.sender] =  getAdjustedNow() / ONE_DAY;
        usdtToken.transfer(msg.sender,profit);
        emit DivideProfit(msg.sender, profit);
    }
    
    function price()  public view returns (uint256){
        if(m_totalSupply == 0)
            return MWEI / 100;
		return safeDiv(safeMul(safeDiv(safeMul(reserve, MAX_WEIGHT), weight), MWEI), m_totalSupply);   
    }
    
    event Price(uint256 _price, uint256 _reserve, uint256 _supply, uint32 _weight);
    function emitPrice()  internal {
        emit Price(price(), reserve, m_totalSupply, weight);
    }
    
    function calcPurchaseRet(uint256 _value)  public view returns (uint256 amount, uint256 price_, uint256 tax_) {
        uint256 value_90 = safeDiv(safeMul(_value, 90), 100);                   // 90% into reserve, 10% to distributePool
        uint32  weight_ = calcWeight(safeAdd(reserve, value_90));
        uint256 value_85 = safeDiv(safeMul(_value, 85), 100);                   // 85% token returns
        amount = calculatePurchaseReturn(m_totalSupply, reserve, weight_, value_85);
        price_ = safeDiv(safeMul(value_85, MWEI), amount);
        tax_ = safeSub(_value, value_85);
        amount = (m_total_issue_subscription + amount) > safeDiv(MAX_TOTAL_ISSUE,2) ? safeSub(safeDiv(MAX_TOTAL_ISSUE,2),m_total_issue_subscription):amount;
    }
    
    function purchase(uint256 _value)  public  returns (uint256 amount){
        
        uint256 value_90 = safeDiv(safeMul(_value, 90), 100);                // 90% into reserve, 10% to distributePool
        weight = calcWeight(safeAdd(reserve, value_90));
        uint256 value_85 = safeDiv(safeMul(_value, 85), 100);                // 85% token returns
        amount = calculatePurchaseReturn(m_totalSupply, reserve, weight, value_85);
        reserve = safeAdd(reserve, value_90);
        vailIssue(msg.sender, amount,ISSUE_TYPE_SUBSCRIPTION);
        emitPrice();
    }
    
    function calcRedeemRet(uint256 _amount)  public view returns (uint256 value_, uint256 price_, uint256 tax_) {
        value_ = calculateRedeemReturn(m_totalSupply, reserve, weight, _amount);
        price_ = safeDiv(safeMul(value_, MWEI), _amount);
        tax_ = safeDiv(safeMul(value_, 15), 100); 
        value_ -= tax_;
    }
    
    function redeem(uint256 _amount)  public returns (uint256 value_){
        value_ = calculateRedeemReturn(m_totalSupply, reserve, weight, _amount);
        reserve = safeSub(reserve, safeDiv(safeMul(value_, 95), 100));
        adjustWeight();
        destroy(msg.sender, _amount);
        value_ = safeDiv(safeMul(value_, 85), 100);                             // 85% redeem, 5% to reserve, 10% to distributePool
        usdtToken.transfer(msg.sender,value_);
        emitPrice();
    }
        
}


/**
    Main contract TrxRepo implementation
*/
contract TrxRepo is RepoToken   {
    
    function purchase(uint256 _value)   public  returns (uint256 amount){
        require(m_total_issue_subscription<safeDiv(MAX_TOTAL_ISSUE,2),"overrun");
        require(usdtToken.balanceOf(msg.sender) >= _value&& usdtToken.allowance(msg.sender,address(this))>= _value,"insufficient balance");
        
        usdtToken.transferFrom(msg.sender, address(this), _value);
        uint256 tax = safeDiv(_value, 10);
        distributePool = safeAdd(distributePool, tax);  // 10% to distributePool
        ethTax[roundNo] = safeAdd(ethTax[roundNo], tax);
        amount = super.purchase(_value);
    }
    
    function redeem(uint256 _amount)   public returns (uint256 value_){
        value_ = super.redeem(_amount);
        uint256 tax = safeDiv(safeMul(value_, 10), 85);
        distributePool = safeAdd(distributePool, tax);  // 10% to distributePool
        ethTax[roundNo] = safeAdd(ethTax[roundNo], tax);
    }

    uint256  distributePool;                      
    uint256  devFund;                             
    uint256  top3Pool;                            
    mapping (uint256 => uint256)  totalInvestment;
    mapping (uint256 => uint256)  ethTax;         
    mapping (uint256 => uint256)  lastSeriesNo;   
    uint256  roundNo;                           
    address  devFundAddr = address(0x41521B68C8A084BD0597F9EE6D2CDE21530AACF744); 
    
    struct User{ 
        uint256 seriesNo;
        uint256 investment; 
        uint256 investmentPre;
        uint256 investmentPreSum;
        uint256 investmentTolal;
        uint256 withdraw; 
        uint256 withdrawTolal;
        uint256 times;
        uint256 dailyInterestTotal;                              
        uint256 roundFirstDate;                       
        uint256 distributeLastTime;                   
        bool quitted;                                
        bool boxReward;                              
    }
    
    struct User1{                                     
        uint256 sonAmount;                            
        uint256 sonAmountPre;                         
        uint256 sonAmountDate;                        
        uint256 sonTotalAmount1;                      
        uint256 sonTotalAmount15;                      
        
        uint256 linkReward;                           
        uint256 nodeReward;                           
        uint256 supNodeReward;                        
        uint256 linkRewardTotal;                      
        uint256 nodeRewardTotal;                      
        uint256 supNodeRewardTotal;                   
    }
    
    struct User2{
	    uint256 firstTime;                            
        uint256 roundNo;                              
        address parent;                               
        uint256 sonCount;                             
        uint256 sonNodeCount;                         
		uint256 supNodeCount;                         
    }

    mapping (uint256 => mapping(address => User)) public user;     
    mapping (uint256 => mapping(address => User1)) public user1;   
    mapping (address => User2) public user2;                     
    
    mapping(uint256 => uint256)  quitAmount;                
    mapping(uint256 => uint256)  quitLastTime;              

    address[3]  top3;                                      
    address[3]  top3Pre;                                   
    bool[3]     top3Withdraw;                             
    uint256     top3date;                                 
    uint256     top3PoolPre;                                 
    
    mapping(uint256 => uint256)  boxExpire;
    mapping(uint256 => uint256)  boxLastSeriesNo;           
    
    constructor() public{
        roundNo = 1;
        boxExpire[roundNo]=now+72*ONE_HOUR;
        quitLastTime[roundNo] = getAdjustedDate();
    }
    
    event logAddrAmount(uint256 indexed lastSeriesNo,uint256 indexed round,address send, uint256 amount,uint256 logtime);
    event logProfit(uint256 indexed round,address addr, uint256 profitAmount,uint256 invitAmount,uint256 logtime);
    event loglink(uint256 indexed round, address indexed parent, address indexed addr, uint256 investment, uint256 invitAmount, uint256 sonCount, uint256 nodeCount, uint256 supNodeCount, uint256 firstTime);

    function () external payable {
    }
    
    function limSub(uint256 _x,uint256 _y) private pure returns (uint256) {
      if (_x>_y)
        return _x - _y;
      else
        return 0;
    }
    
    function play(address parent,uint256 value) public  { 
      address addr = msg.sender;
      
      require(safeMod(value,MWEI) == 0 &&(value >= (100 * MWEI) && value <= (20000 * MWEI)), "Bad amount");  
      require( now < boxExpire[roundNo], "Box expire"); 
      
      require(usdtToken.balanceOf(addr) >= value&& usdtToken.allowance(addr,address(this))>= value,"insufficient balance");
      usdtToken.transferFrom(addr, address(this), value);
     
      if  (((parent==address(0))||(user2[parent].roundNo == 0))&&(addr!=creator)){ 
          parent = creator;
      }
      if(user2[addr].parent==address(0))
        user2[addr].parent = parent;
      else
        parent = user2[addr].parent;
        
	  if (user2[addr].firstTime==0) user2[addr].firstTime = now;
      if (roundNo>user2[addr].roundNo)  user2[addr].roundNo = roundNo;
      
      bool reinvestment = false; 
      if(user[roundNo][addr].investment>0){
		if (user[roundNo][addr].withdraw < user[roundNo][addr].investment *125/100){ 
          revert("Deposit already exists");
        }else{
          require(value >= safeSub(user[roundNo][addr].investment ,user[roundNo][addr].investmentPre), "Bad reinvestment amount"); 
          user[roundNo][addr].withdraw = 0;
          user[roundNo][addr].dailyInterestTotal = 0;
          user[roundNo][addr].times  += 1;
          reinvestment = true;
        }
      }
      
      if(user[roundNo][addr].distributeLastTime!=0 && (now - user[roundNo][addr].distributeLastTime) > 10 days)  user[roundNo][addr].investmentPreSum  = 0;
      
      uint256 curDay = getAdjustedDate();
      user[roundNo][msg.sender].investmentPre = user[roundNo][addr].investment; 
      user[roundNo][addr].investmentPreSum += user[roundNo][addr].investment;

      user[roundNo][addr].investment = value;
      user[roundNo][addr].investmentTolal += value; 
      user[roundNo][addr].roundFirstDate = curDay; 
      user[roundNo][addr].distributeLastTime = curDay; 
        
      totalInvestment[roundNo]     += value;
      distributePool        += value * 80 / 100; 
      devFund               += value * 6 / 100; 
      top3Pool              += value * 3 / 100; 

      if (parent!=address(0)){
        nodeReward(parent, value);
        
        if (!reinvestment) {
            address parent_temp = addSon(parent);
            if(parent_temp != address(0))  addSonNode(parent_temp);
        }
        
        updateSonAmount(parent,value);
        emit loglink(roundNo, parent, addr, user[roundNo][addr].investment, user1[roundNo][addr].sonTotalAmount15, user2[addr].sonCount, user2[addr].sonNodeCount, user2[addr].supNodeCount, user2[addr].firstTime);
        updateTop3(parent);
      }

      lastSeriesNo[roundNo]=lastSeriesNo[roundNo]+1;
      user[roundNo][addr].seriesNo = lastSeriesNo[roundNo];
      if (now<=boxExpire[roundNo]){
        boxLastSeriesNo[roundNo]=lastSeriesNo[roundNo];
        if ((now+72*ONE_HOUR)>(boxExpire[roundNo]+3*ONE_HOUR))
          boxExpire[roundNo]=boxExpire[roundNo]+3*ONE_HOUR;
        else
          boxExpire[roundNo]=now+72*ONE_HOUR;
      }
      issueToken(addr, parent, value,user2[parent].sonCount);
      emit logAddrAmount(lastSeriesNo[roundNo],roundNo,addr,value,now);  

    }
    
    function addSon(address addr) private returns(address){
       user2[addr].sonCount += 1;
       if ((user2[addr].sonCount==UP_NODE_CONTER)&&(user2[addr].parent!=address(0))){
          return user2[addr].parent;
       }
       return address(0);
    }

    function addSonNode(address addr) private {
       user2[addr].sonNodeCount += 1;
	   if ((user2[addr].sonNodeCount==UP_NODE_CONTER)&&(user2[addr].parent!=address(0)))
	   {
	      user2[user2[addr].parent].supNodeCount += 1;
	   }
    }
    
    function updateSonAmount(address addr,uint value) private {
      uint256 date = getAdjustedDate();
      if (date == user1[roundNo][addr].sonAmountDate){
        user1[roundNo][addr].sonAmount = user1[roundNo][addr].sonAmount + value;
      }
      else if (date-ONE_DAY == user1[roundNo][addr].sonAmountDate){
        user1[roundNo][addr].sonAmountPre = user1[roundNo][addr].sonAmount;
        user1[roundNo][addr].sonAmount = value;
      }
      else if (user1[roundNo][addr].sonAmountDate==0){
        user1[roundNo][addr].sonAmount = value;
      }
      else{
        user1[roundNo][addr].sonAmountPre = 0;
        user1[roundNo][addr].sonAmount = value;
      }
      user1[roundNo][addr].sonAmountDate = date;
      
      user1[roundNo][addr].sonTotalAmount1 += value;
      for(uint256 i=0; i<15; i++) {
        user1[roundNo][addr].sonTotalAmount15 += value;
		if (user2[addr].parent==address(0)) break;
	    emit loglink(roundNo, user2[addr].parent, addr, user[roundNo][addr].investment, user1[roundNo][addr].sonTotalAmount15, user2[addr].sonCount, user2[addr].sonNodeCount, user2[addr].supNodeCount, user2[addr].firstTime);
        if (addr==user2[addr].parent) break;
        addr = user2[addr].parent;
      }
    }
    
    function restart() private returns(bool){
      if (now>boxExpire[roundNo]){ 
        if ((now - boxExpire[roundNo]) > 24*ONE_HOUR){
          distributePool += totalInvestment[roundNo]* 1/100;
          roundNo = roundNo + 1;
          boxExpire[roundNo]=now + 72*ONE_HOUR;
          return true;
        }
      }
      return false;
    }


    function quit() public { 
        address payable addr = msg.sender;
        if (user[roundNo][addr].quitted) revert();
            
        uint256 curDay = getAdjustedDate();
        uint256 quitDone = 0; 
        if (quitLastTime[roundNo] == curDay) quitDone = quitAmount[roundNo];
        
        uint256 value = user[roundNo][addr].investment*50/100 > user[roundNo][addr].withdraw ? safeSub(user[roundNo][addr].investment*50/100, user[roundNo][addr].withdraw ):0;        
        if(quitDone + value > distributePool *1/100)  revert();
        
        user[roundNo][addr].quitted = true;
        if (quitLastTime[roundNo] != curDay)
            quitLastTime[roundNo] = curDay;
        
        quitAmount[roundNo] = quitDone + value;
        distributePool = limSub(distributePool, value);
        usdtToken.transfer(addr,value);
        restart();
    }

  function distributionReward() public {
      if (user[roundNo][msg.sender].quitted) revert();
         
      address payable addr = msg.sender;
      uint256 curDay = getAdjustedDate();
      uint256[9] memory r = calcUserReward(addr);
      user[roundNo][addr].distributeLastTime = curDay;
      user[roundNo][addr].withdraw += r[4];
      user[roundNo][addr].withdrawTolal += r[4];
      user[roundNo][addr].dailyInterestTotal += r[0];

      distributePool = limSub(distributePool, r[4]);

      user1[roundNo][addr].linkReward = 0;
      user1[roundNo][addr].nodeReward = 0;
      user1[roundNo][addr].supNodeReward = 0;
      
      if(devFund >= 1 * MWEI){
        usdtToken.transfer(devFundAddr,devFund); 
        devFund  = 0;
      } 
      usdtToken.transfer(addr,ceilWithdraw(r[4],14));
            
      emit logProfit(roundNo, addr, r[8], user1[roundNo][addr].sonTotalAmount1, now);

      if (user2[addr].parent!=address(0)) linkReward(addr, r[4]);
      restart();
    }  
      
    function ceilWithdraw(uint256 withAmount ,uint256 scale) private view returns(uint256 amount_) {
        if(usdtToken.balanceOf(address(this)) < totalInvestment[roundNo] * scale / 100)  return 0;
        return safeSub(usdtToken.balanceOf(address(this)),totalInvestment[roundNo] * scale / 100)>withAmount?withAmount: safeSub(usdtToken.balanceOf(address(this)) ,totalInvestment[roundNo] * scale / 100);
    }
    
    function ceilReward(address addr, uint256 amount) private view returns(uint256 amount_) {
        uint256 curDay = getAdjustedDate();
        uint256 day = limSub(curDay , user[roundNo][addr].distributeLastTime) / ONE_DAY;
        if (day>MAX_DAY)day=MAX_DAY;
        
        uint256 disReward = (user[roundNo][addr].investment + user[roundNo][addr].investmentPreSum) * SPEND_PERSENT_EVERY_DATE/100 * day;
        uint256 sumReward =disReward + user1[roundNo][addr].linkReward + user1[roundNo][addr].nodeReward + user1[roundNo][addr].supNodeReward;
        return limSub(amount, limSub(amount + user[roundNo][addr].withdraw + sumReward, user[roundNo][addr].investment *125/100));
    }

   function linkReward(address addr,uint256 amount) private {
        bool sonCountPre = false;
        bool sonNodeCountPre = false;
        uint256 amountPre = amount;
        user2[addr].sonCount>=UP_NODE_CONTER ? sonCountPre = true:sonCountPre = false;
        user2[addr].sonNodeCount>=UP_NODE_CONTER ? sonNodeCountPre = true:sonNodeCountPre = false;
        address parent = user2[addr].parent;
        for(uint i=0; i<15; i++){
            if(user2[parent].sonCount > i) {
                uint256 basicReward;
                uint256 parallelReward;
                uint256 sumReward;
                
                if(sonNodeCountPre==true&&(user2[parent].sonNodeCount>=UP_NODE_CONTER)){
                     parallelReward = safeDiv(safeMul(amountPre,20),100);
                }else if(sonCountPre==true&&(user2[parent].sonCount>=UP_NODE_CONTER)&&(user2[parent].sonNodeCount<UP_NODE_CONTER)){
                     parallelReward = safeDiv(safeMul(amountPre,20),100);
                }
                basicReward = calcLinkReward(i,amount);
                sumReward = ceilReward(parent,safeAdd(basicReward,parallelReward) );
                if(sumReward > 0){
                    user1[roundNo][parent].linkReward += sumReward;
                    user1[roundNo][parent].linkRewardTotal += sumReward;
                }
                
                user2[parent].sonCount>=UP_NODE_CONTER ? sonCountPre = true:sonCountPre = false;
                user2[parent].sonNodeCount>=UP_NODE_CONTER ? sonNodeCountPre = true:sonNodeCountPre = false;
                amountPre = basicReward;
           }else{
                sonCountPre = false;
                sonNodeCountPre = false;
                amountPre = 0;
           }
           if (user2[parent].parent==address(0)||parent==user2[parent].parent) break;
           parent = user2[parent].parent;
        }
    }

    function nodeReward(address parent,uint256 amount) private {
       uint256 amount_  = 0;
       if(user2[parent].sonNodeCount  >= UP_NODE_CONTER){
            amount_ =  ceilReward(parent, amount * 20/100);
            if(amount_ > 0){
                user1[roundNo][parent].supNodeReward += amount_;
                user1[roundNo][parent].supNodeRewardTotal += amount_;
            }
        }else if(user2[parent].sonCount >= UP_NODE_CONTER){
            amount_ =  ceilReward(parent, amount * 10/100);
              if(amount_ > 0){
                user1[roundNo][parent].nodeReward += amount_;
                user1[roundNo][parent].nodeRewardTotal += amount_;
            }
        }else{
            amount_ =  ceilReward(parent, amount * 5/100);
              if(amount_ > 0){
                user1[roundNo][parent].linkReward += amount_;
                user1[roundNo][parent].linkRewardTotal += amount_;
            }
        }
    }

    function updateTop3(address addr) private {
      if (addr == creator) return;
        
      uint256 amount1 = user1[roundNo][addr].sonAmount;
      uint256 date =  getAdjustedDate();
      bool updateTop3date=false;
      address addr0 = top3[0];
      address addr1 = top3[1];
      address addr2 = top3[2];
      if (date == top3date){
        uint256 insertIndex=100;
        uint256 repeateIndex=100;
        address[3] memory tmp;
        if(!((amount1>user1[roundNo][top3[2]].sonAmount)||(amount1>user1[roundNo][top3[1]].sonAmount)))
          return;
        for (uint i=0;i<3;i++){
	      if (top3[i] == addr)
	        repeateIndex=i;
	      else
	        tmp[i] = top3[i];
        }
        for (uint i=0;i<3;i++){
          if (amount1>user1[roundNo][tmp[i]].sonAmount){
	        insertIndex = i;
            break;
          }
        }
        uint j=0;//tmp
        for (uint i=0;i<3;i++){
          if (insertIndex==i){
            if (top3[i]!=addr)
	          top3[i]=addr;
	      }
          else{
            if (top3[i]!=tmp[j])
              top3[i]=tmp[j];
	        j += 1;
	      }
         if(j == repeateIndex)
	          j += 1;
        }
      }
      else if (date-ONE_DAY == top3date){
        top3Pre[0]=addr0;
        top3Pre[1]=addr1;
        top3Pre[2]=addr2;
        top3[0]=addr;
        top3[1]=address(0);
        top3[2]=address(0);
        top3PoolPre = limSub(top3Pool , msg.value*3/100);
        updateTop3date=true;
      } 
      else if(top3date == 0){
        top3[0] = addr;
        updateTop3date = true;
      }
      else{
        for (uint i=0; i<3; i++){
          top3Pre[i] = address(0);
          if (i != 0)
          top3[i] = address(0);
        }
        top3[0] = addr;
        updateTop3date = true;
      }
      if (updateTop3date){
        top3date = date;
        for (uint i=0; i<3; i++)
          top3Withdraw[i] = false;
      }
    }

    function getTop3Reward() public {
      if (user[roundNo][msg.sender].quitted) revert();
         
      address payable addr=msg.sender;
      uint256 date = getAdjustedDate();
      uint256 index = 100;
   
      if (date-ONE_DAY == top3date){
        top3Pre[0] = top3[0];
        top3Pre[1] = top3[1];
        top3Pre[2] = top3[2];
        for (uint i=0; i<3; i++){
          top3[i] = address(0);
          top3Withdraw[i] = false;
        }
        top3date = date;
		top3PoolPre=top3Pool;
      } 

      if (top3date==date){

        if (addr == top3Pre[0]){
          index = 0;
        }
        else if(addr==top3Pre[1]){
          index =1;
        }
        else if(addr==top3Pre[2]){
          index = 2;
        }
      }
      if ((index<3)&&(!top3Withdraw[index])){
        uint256 ret = calcTop3Reward(index,top3PoolPre);
        top3Pool = limSub(top3Pool,ret);
        top3Withdraw[index] = true;
        usdtToken.transfer(addr,ret);
      }
    }

    function userBoxInfo(address addr) public view returns(uint256 curRoundNo,uint256 userBoxReward,bool boxOpened,bool drew){
      curRoundNo = user2[addr].roundNo;
      drew = false;
      userBoxReward = 0;
      if (curRoundNo==0){
        boxOpened = false;
        return (curRoundNo,userBoxReward,boxOpened,drew);
      }
      if (now>boxExpire[curRoundNo]){
        boxOpened = true;
        if ((user[curRoundNo][addr].seriesNo>0)&&(boxLastSeriesNo[curRoundNo]>=user[curRoundNo][addr].seriesNo)&&(boxLastSeriesNo[curRoundNo]-user[curRoundNo][addr].seriesNo<580)){
          drew = user[curRoundNo][addr].boxReward;
          uint256 rank = boxLastSeriesNo[curRoundNo]-user[curRoundNo][addr].seriesNo+1;
          userBoxReward = calcBoxReward(rank,curRoundNo);
        }
      }
    }

    function getBoxReward() public {
      if (user[roundNo][msg.sender].quitted) revert();
        
      address payable addr=msg.sender;
      uint256 curRoundNo;
      uint256 userBoxReward;
      bool boxOpened;
      bool drew=false;
      (curRoundNo,userBoxReward,boxOpened,drew) = userBoxInfo(addr);
      if ((userBoxReward>0)&&(!drew)){
        user[curRoundNo][addr].boxReward = true;
        usdtToken.transfer(addr,userBoxReward);
      }
    }
    
    
    function quitable(address addr) public view returns(uint256){ 
      if (user[roundNo][addr].quitted){
        return 0;
      }
      uint256 curDay = getAdjustedDate();
      uint256 quitDone=0; 
      if (quitLastTime[roundNo]==curDay)
        quitDone=quitAmount[roundNo];
      
      uint256 value = user[roundNo][addr].investment*50/100 > user[roundNo][addr].withdraw ? safeSub(user[roundNo][addr].investment*50/100, user[roundNo][addr].withdraw ):0;        
      uint256 quitAmount1= quitDone + value;
      if(quitAmount1 > distributePool *1/100){
         return 2;
      }
      return 1;  
    }

    function boolToUint256(bool bVar) private pure returns (uint256) {
      if (bVar)
        return 1;
      else
        return 0;
    }

    function calcUserReward(address  addr) public view returns(uint256[9] memory r){ 
        uint256 curDay = getAdjustedDate();
        uint256 day = limSub(curDay , user[roundNo][addr].distributeLastTime) / ONE_DAY;
        if (day < 1){
            for(uint256 i=0; i<9; i++){
                r[i]=0;
            }
        }
        if (day>MAX_DAY)  day=MAX_DAY;
        uint256 disPure   = user[roundNo][addr].investment * SPEND_PERSENT_EVERY_DATE / 100 * day; 
        uint256 disReward = disPure + (user[roundNo][addr].investmentPreSum * SPEND_PERSENT_EVERY_DATE / 100 * day); 
        uint256 sumReward = disReward + user1[roundNo][addr].linkReward + user1[roundNo][addr].nodeReward + user1[roundNo][addr].supNodeReward ;
        if ((user[roundNo][addr].withdraw + sumReward) > (user[roundNo][addr].investment *125/100)){
            sumReward = limSub(user[roundNo][addr].investment *125/100, user[roundNo][addr].withdraw);
        }
        if (disPure > sumReward)
            disPure = sumReward;
        if (sumReward < disReward)
            disReward = sumReward;

        r[0] = disReward;                                
        r[1] = user1[roundNo][addr].linkReward;   
        r[2] = user1[roundNo][addr].nodeReward;   
        r[3] = user1[roundNo][addr].supNodeReward;
        r[4] = sumReward;
        r[5] = user[roundNo][addr].investment *250/100;
        r[6] = disPure;                                         
        r[7] = user[roundNo][addr].withdraw *2;                   
        if (addr != creator)
            r[8] = (user[roundNo][addr].withdraw + sumReward) *2; 
    }
    
    function userTop3RewardInfo(address addr) public view returns(uint256 reward,bool done){  
        uint256 date = getAdjustedDate();
        uint256 index =100;
    	uint256 poolAmount;
        if (top3date==date){
            if (addr == top3Pre[0]){
              index = 0;
            }
            else if(addr==top3Pre[1]){
              index =1;
            }
            else if(addr==top3Pre[2]){
              index = 2;
            }
    		poolAmount = top3PoolPre;
        }
        else if (date-ONE_DAY == top3date){
            if (addr == top3[0]){
              index = 0;
            }
            else if(addr==top3[1]){
              index =1;
            }
            else if(addr==top3[2]){
              index = 2;
            }
    		poolAmount = top3Pool;
        }
        if (index<3){
            reward = calcTop3Reward(index,poolAmount);
            done = top3Withdraw[index];
        }else{
            reward = 0;
            done = false;
        }
     }
    
     function getUserInfo(address addr) public view returns(uint256[50] memory ret) {
        uint256[9] memory r= calcUserReward(addr);
        uint256 curUserRoundNo = user2[addr].roundNo;
        
        ret[0] = user[roundNo][addr].seriesNo;
        ret[1] = user[roundNo][addr].investment;           
        ret[2] = user[roundNo][addr].withdraw + r[4];       
        ret[3] = user[roundNo][addr].withdraw;              
        ret[4] = user[roundNo][addr].distributeLastTime;   
        ret[5] = boolToUint256(user[roundNo][addr].quitted);
        ret[6] = uint256(user2[addr].parent);               
        ret[7] = user2[addr].sonCount;                     
        ret[8] = user2[addr].sonNodeCount;                 
        
        uint256 date = getAdjustedDate();
        if (user1[roundNo][addr].sonAmountDate == date){
          ret[9] = user1[roundNo][addr].sonAmount;                       
          ret[10] = user1[roundNo][addr].sonAmountPre;                   
        }else if(date-ONE_DAY == user1[roundNo][addr].sonAmountDate) {
          ret[9] = 0;                              
          ret[10] = user1[roundNo][addr].sonAmount;                      
        }
        ret[11] = user1[roundNo][addr].sonAmountDate;                    
        ret[12] = boolToUint256(user[curUserRoundNo][addr].boxReward);   
        ret[13] = user[roundNo][addr].roundFirstDate;
        ret[14] = quitable(addr);                                        
        ret[15] = user[roundNo][addr].investmentPreSum;                           
        ret[16] = balanceOf(addr);                                       
        ret[17] = stakingOf[addr];                                       
        ret[18] = profitedOf[addr];                                      
        
        ret[19] = user[roundNo][addr].dailyInterestTotal *2;                        
        ret[20] = r[1];                                                  
        ret[21] = r[2];                                                  
        ret[22] = r[3];                                                  
        ret[23] = r[4];                                                  
        ret[24] = r[5];                                                  
        ret[25] = limSub(user[roundNo][addr].investment * 250/100, r[7]); 
        ret[26] = r[7];                                                  

        uint256 curRoundNo;
        bool boxOpened;
        bool drew=false;
        (curRoundNo,ret[27], boxOpened, drew) = userBoxInfo(addr);           
        ret[28] = boolToUint256(boxOpened);                                  
        ret[29] = profitingOf(addr);                                         
        
        bool top3Done;
        (ret[30],top3Done) = userTop3RewardInfo(addr);                   
        ret[31] = boolToUint256(top3Done);    
        
        ret[32] = r[8];  
        ret[33] = user[roundNo][addr].investmentPre;
        ret[34] = user[roundNo][addr].times;
        ret[35] = user1[roundNo][addr].sonTotalAmount1;
        ret[36] = user1[roundNo][addr].sonTotalAmount15;
        ret[37] = user[roundNo][addr].investmentTolal;
        ret[38] = user[roundNo][addr].withdrawTolal;
        ret[39] = user1[roundNo][addr].linkRewardTotal;
        ret[40] = user1[roundNo][addr].nodeRewardTotal;   
        ret[41] = user1[roundNo][addr].supNodeRewardTotal;   
        return ret;
    }
    
    function getInfo() public view returns(uint256[50] memory) {
        uint256[50] memory ret;
        ret[0] = distributePool;                 
        ret[1] = top3Pool;                       
        ret[2] = totalInvestment[roundNo]* 2/100;
        ret[3] = totalInvestment[roundNo]* 1/100;
        ret[4] = devFund;                        
        ret[5] = totalInvestment[roundNo];       
        ret[6] = lastSeriesNo[roundNo];          
        ret[7] = roundNo;                        
        ret[8] = boxExpire[roundNo];             
        ret[9] = boxLastSeriesNo[roundNo];       
        ret[10]= ethTax[roundNo];                
    
      uint256 i=11;
      uint256 date = getAdjustedDate();
      if (top3date == date){
        for (uint256 j=0;j<3;j++){
          ret[i]=uint256(top3[j]); 
          i=i+1;
          ret[i]=user1[roundNo][top3[j]].sonAmount;
          i=i+1;
          if (ret[i-2]==0)
            ret[i] = 0;
          else
            ret[i] =  calcTop3Reward(j,top3Pool);
          i=i+1;
        }
      }
      ret[20] = m_totalSupply;
      ret[21] = reserve;
      ret[22] = profitPool;
      ret[23] = totalProfited;
      ret[24] = totalDestroyed;
      ret[25] = price();
      ret[26] = totalStaking();
      ret[27] = uint256(creator);
      ret[28] = weight;
      ret[29] = totalInvestment[roundNo-1]; 
      uint256 quitDone = 0;  
      if (quitLastTime[roundNo] == date)
    	quitDone = quitAmount[roundNo];
      ret[30] = limSub(distributePool *1/100, quitDone);
      ret[31] = m_total_issue_invest;
      ret[32] = m_total_issue_subscription;
      ret[33] = MAX_TOTAL_ISSUE ;

      ret[49] = now;
      return ret;
    }
    
    function calcLinkReward(uint256 rank,uint256 amount) private pure returns(uint256) {
      uint256 result = 0;
      if (rank==0){
            result = safeDiv(safeMul(amount,20),100);
        }
        else if(rank>=1 && rank<=4){
            result = safeDiv(safeMul(amount,10 ),100);
        }
        else if(rank>=5 && rank<=9){
            result = safeDiv(safeMul(amount,5),100);
        }
        else if(rank>=10 && rank<=14){
            result = safeDiv(safeMul(amount,3),100);
        }
        return result;
  }
    
  function calcBoxReward(uint256 rank,uint256 curRoundNo) private view returns(uint256) {
      uint256 amount  = safeDiv(safeMul(safeDiv(safeMul(totalInvestment[curRoundNo],2),100),25),100);  
      if (rank>=1 && rank<=3){
        return safeDiv(amount,3);
      }
      else if(rank>=4 && rank<=10){
        return safeDiv(amount,7);
      }
      else if(rank>=11 && rank<=80){
        return safeDiv(amount,70);
      }
      else if(rank>=81 && rank<=580){
        return safeDiv(amount,500);
      }
      return 0;
    }

    function calcTop3Reward(uint256 rank,uint256 poolAmount) private pure returns(uint256) {
      poolAmount  = safeMul(poolAmount,3);  
      uint256 ret=0;
        if (rank==0)
          ret = safeDiv(safeMul(safeMul(poolAmount,3),6),100);  
        else if(rank==1)
          ret = safeDiv(safeMul(safeMul(poolAmount,3),3),100);
        else if(rank==2)
          ret = safeDiv(safeMul(safeMul(poolAmount,3),1),100);
       return ret;
    }
    
   
    
}