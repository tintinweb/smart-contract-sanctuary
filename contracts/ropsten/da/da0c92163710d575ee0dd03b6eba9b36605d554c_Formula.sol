pragma solidity ^0.4.23;

contract IReserve {
    // these function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    //function balanceOfRaw() public view returns(uint256) {}
    function balanceOfShares() public pure returns(uint256) {}
    function balanceOfOrder() public pure returns(uint256) {}
    function balanceOfMineral() public pure returns(uint256) {}
    function balanceOfColdWallet() public pure returns(uint256) {}
    
    function saveToColdWallet(uint256 _amount) public;
    function restoreFromColdWallet() public payable;
    function setColdWallet(address _coldWallet, uint256 _ratioAutoSave, uint256 _ratioAutoRemain) public;
    function depositShares() public payable;
    function depositOrder() public payable;
    function depositMineral() public payable;
    function order2Shares(uint256 _amount) public;
    function mineral2Shares(uint256 _amount) public;
    function withdrawShares(uint256 _amount) public;
    function withdrawSharesTo(address _to, uint256 _amount) public;
    function withdrawOrder(uint256 _amount) public;
    function withdrawOrderTo(address _to, uint256 _amount) public;
    function withdrawMineral(uint256 _amount) public;
    function withdrawMineralTo(address _to, uint256 _amount) public;
	function() public payable;
}

contract ICaller{
	function calledUpdate(ICalled _oldCalled, ICalled _newCalled) public;  // ownerOnly
	
	event CalledUpdate(ICalled _oldCalled, ICalled _newCalled);
}

contract DataCaller is ICaller {
    IData public data;
    
    constructor(IData _data) public {
        data = IData(_data);
    }
    
    function calledUpdate(ICalled _oldCalled, ICalled _newCalled) public {
        if(data == _oldCalled) {
            data = IData(_newCalled);
            emit CalledUpdate(_oldCalled, _newCalled);
        }
    }
    
	function getBAU2(bytes32 _key, address _addr, uint256 _index) internal view returns(uint256 val) {
		return data.getBAU2(_key,_addr,_index);
	}
	function getBAU2Length(bytes32 _key, address _addr) internal view returns(uint256 length) {
		length = data.getBAU2Length(_key,_addr);
	}
	function pushBAU2(bytes32 _key, address _addr, uint256 _value) internal {
		data.pushBAU2(_key,_addr,_value);
	}
	function cutBAU2Length(bytes32 _key, address _addr, uint256 _newLength) internal returns(uint256) {
		return data.cutBAU2Length(_key,_addr, _newLength);
	}
	function setBAU2(bytes32 _key, address _addr, uint256 _index, uint256 _value) internal {
		data.setBAU2(_key,_addr,_index,_value);
	}
	
    function getBU(bytes32 _key) internal view returns(uint256) {
        return data.bu(_key);        
    }
    function getBA(bytes32 _key) internal view returns(address) {
        return data.ba(_key);        
    }
/*    function getBI(bytes32 _key) internal view returns(int256) {
        return data.bi(_key);        
    }
    function getBS(bytes32 _key) internal view returns(string) {
        return data.bs(_key);        
    }
    function getBB(bytes32 _key) internal view returns(bytes) {
        return data.bb(_key);        
    }
*/
    function getBAU(bytes32 _key, address _addr) internal view returns(uint256) {
        return data.bau(_key, _addr);        
    }
	function getBUA(bytes32 _key, uint256 _index) internal view returns(address) {
        return data.bua(_key, _index);        
    }
    function getBAS(bytes32 _key, address _addr) internal view returns(string) {
        return data.bas(_key, _addr);        
    }
/*    function getBAI(bytes32 _key, address _addr) internal view returns(int256) {
        return data.bai(_key, _addr);        
    }
    function getBAB(bytes32 _key, address _addr) internal view returns(bytes) {
        return data.bab(_key, _addr);        
    }
*/
    function getBUU(bytes32 _key, uint256 _index) internal view returns(uint256) {
        return data.buu(_key, _index);        
    }
	function getBUUU(bytes32 _key, uint256 _index, uint256 _index2) internal view returns(uint256) {
        return data.buuu(_key, _index, _index2);        
    }
/*    function getBUI(bytes32 _key, uint256 _index) internal view returns(int256) {
        return data.bui(_key, _index);        
    }
    function getBUS(bytes32 _key, uint256 _index) internal view returns(string) {
        return data.bus(_key, _index);        
    }
    function getBUB(bytes32 _key, uint256 _index) internal view returns(bytes) {
        return data.bub(_key, _index);        
    }
*/
    function getBAAU(bytes32 _key, address _token, address _addr) internal view returns(uint256) {
        return data.baau(_key, _token, _addr);        
    }
    
    function getBAAAU(bytes32 _key, address _token, address _from, address _to) internal view returns(uint256) {
        return data.baaau(_key, _token, _from, _to);        
    }
    

    function setBU(bytes32 _key, uint256 _value) internal {
        data.setBU(_key, _value);    
    }
    function setBA(bytes32 _key, address _value) internal {
        data.setBA(_key, _value);    
    }
/*    function setBI(bytes32 _key, int256 _value) internal {
        data.setBI(_key, _value);    
    }
    function setBS(bytes32 _key, string _value) internal {
        data.setBS(_key, _value);
    }
    function setBB(bytes32 _key, bytes _value) internal {
        data.setBB(_key, _value);
    }
*/    
    function setBAU(bytes32 _key, address _addr, uint256 _value) internal {
        data.setBAU(_key, _addr, _value);    
    }
	function setBUA(bytes32 _key, uint256 _index, address _addr) internal {
        data.setBUA(_key, _index, _addr);        
    }
    function setBAS(bytes32 _key, address _addr, string _value) internal {
        data.setBAS(_key, _addr, _value);    
    }
/*    function setBAI(bytes32 _key, address _addr, int256 _value) internal {
        data.setBAI(_key, _addr, _value);    
    }
    function setBAB(bytes32 _key, address _addr, bytes _value) internal {
        data.setBAB(_key, _addr, _value);    
    }
*/    
    function setBUU(bytes32 _key, uint256 _index, uint256 _value) internal {
        data.setBUU(_key, _index, _value);    
    }
	function setBUUU(bytes32 _key, uint256 _index, uint256 _index2, uint256 _value) internal {
        data.setBUUU(_key, _index, _index2, _value);    
    }
/*    function setBUI(bytes32 _key, uint256 _index, int256 _value) internal {
        data.setBUI(_key, _index, _value);    
    }
    function setBUS(bytes32 _key, uint256 _index, string _value) internal {
        data.setBUS(_key, _index, _value);    
    }
    function setBUB(bytes32 _key, uint256 _index, bytes _value) internal {
        data.setBUB(_key, _index, _value);    
    }
*/    
    function setBAAU(bytes32 _key, address _token, address _addr, uint256 _value) internal {
        data.setBAAU(_key, _token, _addr, _value);
    }

    function setBAAAU(bytes32 _key, address _token, address _from, address _to, uint256 _value) internal {
        data.setBAAAU(_key, _token, _from, _to, _value);
    }

}

contract Utils {
    uint256 public constant MAX_UINT = uint256(0 - 1);
    
    /**
        constructor
    */
//    constructor() public{
//    }

    // verifies that an amount is greater than zero
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

	//Mitigate short address attack and compatible padding problem while using “call“ 
	modifier onlyPayloadSize(uint256 numCount){
		assert((msg.data.length == numCount*32 + 4) || (msg.data.length == (numCount + 1)*32));
		_;
	}
	
    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x);        //assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y);        //assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        require(_x == 0 || z / _x == _y);        //assert(_x == 0 || z / _x == _y);
        return z;
    }
	
	function safeDiv(uint256 _x, uint256 _y)internal pure returns (uint256){
	    // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return _x / _y;
	}
	
	function sqrt(uint x)public pure returns(uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
	
	//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) internal view returns (bool is_contract) {
        uint length;
        assembly {
              //retrieve the size of the code on target address, this needs assembly
              length := extcodesize(_addr)
        }
        return (length>0);
    }
    
    // todo: for debug
    event LogEvent(string name, uint256 value);

}

contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    //function creator() public pure returns (address) {}
    function owner() public pure returns (address) {}

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

contract ICalled is IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    //function callers(address) public pure returns (bool) { }

    function appendCaller(ICaller _caller) public;  // ownerOnly
    function removeCaller(ICaller _caller) public;  // ownerOnly
    
    event AppendCaller(ICaller _caller);
    event RemoveCaller(ICaller _caller);
}

contract IFormula is ICalled {
    uint32 public constant MAX_WEIGHT = 1000000;
    function reserve() public view returns(address) { }
	function calledUpdate(ICalled, ICalled) public { }    // ownerOnly
	
    function totalSupply() public view returns (uint256);
    function balanceOf(address _addr)public view returns(uint256);
    function price() view public returns(uint256);
    //function costOfTxShares() view public returns(uint256);
    
	function calcTimedQuota(uint256 _rest, uint256 _full, uint256 _timespan, uint256 _period) public pure returns (uint256);
    function calcEma(uint256 _emaPre, uint256 _value, uint32 _timeSpan, uint256 _period) public view returns(uint256);
    function calcFactorReward(uint256 _dailyYield) public view returns(uint256);
    
    function calcInvitationAmount(uint256 _orderAmount)public view returns(uint256);
	function calcOrderToMsAmount(uint256) public view returns(uint256);
	//function calcMiningSharesAmount(uint256 _amount, uint256 _factorRestrain) public view returns(uint256);

    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public constant returns (uint256);
    function calculateRedeemReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public constant returns (uint256);
	
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) public view returns (uint256, uint8);
    function power2(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) public view returns (uint256, uint8);
    function ln(uint256 _numerator, uint256 _denominator) public pure returns (uint256);
    
}

contract Owned is IOwned {
    address public owner;
    address public newOwner;

    /**
        @dev constructor
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }
}

contract Called is ICalled, Owned {
    mapping(address => bool) public callers;

    // allows calling by the callers only
    modifier callerOnly {
        assert(callers[msg.sender] || msg.sender == owner);  // || msg.sender == creator);
        _;
    }

    function appendCaller(ICaller _caller) public ownerOnly {  //creatorOrOwner {
        callers[_caller] = true;
        emit AppendCaller(_caller);
    }
    
    function removeCaller(ICaller _caller) public ownerOnly {  //creatorOrOwner {
        delete callers[_caller];
        emit RemoveCaller(_caller);
    }
}

contract CommonArgsGetter is DataCaller, Called{
    bytes32 m_dataKey  = "CommonArguments";
	bytes32 m_dataKey2 = "CommonArguments2";
    bytes32 m_dataKey3 = "CommonArguments3";
    bytes32 m_dataKey4 = "CommonArguments4";
    bytes32 m_dataKey5 = "CommonArguments5";
	
	constructor(address _data) DataCaller(IData(_data)) public {
		
	}
	
	//通用分母
	function getDenominator()public view returns(uint256){
		return getBUU(m_dataKey, 0);
	}
	
	//order用到的参数(getOrderDealSpeed、getOrderListLengthFactor、getOrderDealTimeInterval工分共用)
	function getOrderSupportCancel()public view returns(uint256){
		return getBUU(m_dataKey, 1000);
	}
	function getOrderDealSpeed()public view returns(uint256){
		return getBUU(m_dataKey, 1001);
	}
	function getOrderListLengthFactor()public view returns(uint256){
		return getBUU(m_dataKey, 1002);
	}
	function getInvitationValidPeriod()public view returns(uint256){
		return getBUU(m_dataKey, 1003);
	}
	//function getOrderDealTimeInterval()public view returns(uint256){          // instead of getBA("periodQuotaOrder");
	//	return getBUU(m_dataKey, 1004);
	//}
	function getInvitationMultiple()public view returns(uint256){
		return getBUU(m_dataKey, 1005);
	}
	
	//工分用到的参数	
	function getWorkpointSupportCancel()public view returns(uint256){
		return getBUU(m_dataKey, 2000);
	}
	
	//三级设置，排队买到的目标矿股
	function getTransformTarget_default()public view returns(uint256) {
		return getBUU(m_dataKey, 2001);
	}
	function getTransformTarget_pool(address _pool)public view returns(uint256){
		return getBAU(m_dataKey2, _pool);
	}
	function getTransformTarget_miner(address _miner)public view returns(uint256){
		return getBAU(m_dataKey3, _miner);
	}
	
	//三级设置，矿池结算时，是否直接排队买矿股: 1排队，2不排队
	function getLineUpEnable_default()public view returns(uint256){
		return getBUU(m_dataKey, 2002);
	}
	function getLineUpEnable_pool(address _pool)public view returns(uint256){
		return getBAU(m_dataKey4, _pool);
	}
	function getLineUpEnable_miner(address _miner)public view returns(uint256){
		return getBAU(m_dataKey5, _miner);
	}
}

contract Formula is IFormula, Utils, Called, CommonArgsGetter{
    string public version = &#39;0.3&#39;;
    IReserve public reserve;

    uint256 public constant ONE = 1; 
    uint32 public constant MAX_WEIGHT = 1000000;
    uint8 public constant MIN_PRECISION = 32;
    uint8 public constant MAX_PRECISION = 127;

    /**
        The values below depend on MAX_PRECISION. If you choose to change it:
        Apply the same change in file &#39;PrintIntScalingFactors.py&#39;, run it and paste the results below.
    */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x1ffffffffffffffffffffffffffffffff;

    /**
        The values below depend on MAX_PRECISION. If you choose to change it:
        Apply the same change in file &#39;PrintLn2ScalingFactors.py&#39;, run it and paste the results below.
    */
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
        The values below depend on MIN_PRECISION and MAX_PRECISION. If you choose to change either one of them:
        Apply the same change in file &#39;PrintFunctionBancorFormula.py&#39;, run it and paste the results below.
    */
    uint256[128] private maxExpArray;

    //constructor (IData _data) CommonArgsGetter(_data) public {
    constructor (IData _data, IReserve _reserve) CommonArgsGetter(_data) public {
		reserve = _reserve;
		
    //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
    //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
    //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
    //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
    //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
    //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
    //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
    //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
    //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
    //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
    //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
    //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
    //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
    //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
    //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
    //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
    //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
    //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
    //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
    //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
    //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
    //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
    //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
    //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
    //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
    //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
    //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
    //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
    //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
    //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
    //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
    //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
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

    function calledUpdate(ICalled _oldCalled, ICalled _newCalled) public ownerOnly {  //creatorOrOwner {
        if(data == _oldCalled){
            data = IData(_newCalled);
        }else if(ICalled(reserve) == _oldCalled){
            reserve = IReserve(_newCalled);
        }else{
            return;
        }
        //DataCaller.calledUpdate(_oldCalled, _newCalled);
    }
    
    function totalSupply() public view returns (uint256 result) {
        result = 0;      
        result = safeAdd(result, getBAU("totalSupply", getBA("MS")));
        result = safeAdd(result, getBAU("totalSupply", getBA("MSD")));
        result = safeAdd(result, getBAU("totalSupply", getBA("MSR")));
        result = safeAdd(result, getBAU("totalSupply", getBA("MSD2")));
        result = safeAdd(result, getBAU("totalSupply", getBA("MS2R")));
    }
    
    function balanceOf(address _addr)public view returns(uint256 result) {
        result = 0;      
        result = safeAdd(result, getBAAU("balanceOf", getBA("MS"), _addr));
        result = safeAdd(result, getBAAU("balanceOf", getBA("MSD"), _addr));
        result = safeAdd(result, getBAAU("balanceOf", getBA("MSR"), _addr));
        result = safeAdd(result, getBAAU("balanceOf", getBA("MSD2"), _addr));
        result = safeAdd(result, getBAAU("balanceOf", getBA("MS2R"), _addr));
    }
    
    function price() view public returns(uint256) {
        uint32 weight = uint32(getBU("weightOfReserve"));
        return safeDiv(safeMul(safeDiv(safeMul(reserve.balanceOfShares(), MAX_WEIGHT), weight), 1 ether), totalSupply());   
    }   // price = reserve * 1000000 / weight * 10**18 / supply
    
    //function costOfTxShares() view public returns(uint256 result) {
    //    //result = getBU("costOfTxShares");
    //    uint256 GAS_TX_SHARES = 500000;         // gasUsed: 489232
    //    result = GAS_TX_SHARES * tx.gasprice * 1 ether / price();
    //}
    
    function calcTimedQuotaByPower(uint256 _rest, uint256 _full, uint256 _timespan, uint256 _period) public view returns (uint256) {
        uint256 weight;
        uint8 precision;
        (weight, precision) = power2(_period-1, _period, uint32(_timespan), 1);
        return (_rest * weight + _full * ((uint256(1) << precision) - weight)) >> precision;
    }
    
    function calcTimedQuota(uint256 _rest, uint256 _full, uint256 _timespan, uint256 _period) public pure returns (uint256) {
        if(_timespan > _period)
            _timespan = _period;
        return (_rest * (_period - _timespan) + _timespan * _full) / _period;
    }
    
    function calcEma(uint256 _emaPre, uint256 _value, uint32 _timeSpan, uint256 _period) public view returns(uint256) {
        uint256 base;
        uint8 precision;
        (base, precision) = power2(_period, _period-1, (_timeSpan+1), 1);
        uint256 weight = uint256(1) << precision;
        return _emaPre*weight/base + (_value+_emaPre)*(base-weight)/base/(_timeSpan+1);
    }
    
    //  moved to Initializer.sol
    //function initFactorReward(uint256 _yieldBegin, uint256 _factorBegin, uint256 _yieldEnd, uint256 _factorEnd) public ownerOnly returns(uint256) {
    //    uint256 exp = ln(_factorBegin, _factorEnd) * MAX_WEIGHT / ln(_yieldEnd, _yieldBegin);
    //    setBU("factorRewardYieldBegin", _yieldBegin);
    //    setBU("factorRewardBegin", _factorBegin);
    //    setBU("factorRewardYieldEnd", _yieldEnd);
    //    setBU("factorRewardEnd", _factorEnd);
    //    setBU("factorRewardExp", exp);
    //    return exp;
    //}
    
    function calcFactorReward(uint256 _dailyYield) public view returns(uint256) {
        uint256 yieldEnd = getBU("factorRewardYieldEnd");
        if(_dailyYield >= yieldEnd)
            return getBU("factorRewardEnd");
        uint256 yieldBegin = getBU("factorRewardYieldBegin");
        uint256 factorBegin = getBU("factorRewardBegin");
        if(_dailyYield <= yieldBegin)
            return factorBegin;
        uint32 exp = uint32(getBU("factorRewardExp"));
        uint256 base;
        uint8 precision;
        (base, precision) = power2(_dailyYield, yieldBegin, exp, MAX_WEIGHT);
        return (factorBegin << precision) / base;
    }
    
    
	//乘以2后向下取整：0.5以上的eth才会有邀请码
	function calcInvitationAmount(uint256 _orderAmount)public view returns(uint256){
		uint256 srcAmount = safeDiv(safeMul(_orderAmount, getInvitationMultiple()), getDenominator());
		uint256 factor    = 10**18;
		
		uint256 ret       = safeDiv(srcAmount, factor);
		return safeMul(ret, factor);
	}
	
	function calcOrderToMsAmount(uint256 _orderAmount)public view returns(uint256){
        uint32 weight = uint32(getBU("weightOfReserve"));
        return calculatePurchaseReturn(totalSupply(), reserve.balanceOfShares(), weight, _orderAmount);
	}
	
	//  moved to Foundry.sol
	//function calcMiningSharesAmount(uint256 _amount, uint256 _factorRestrain) public view returns(uint256){
	//	uint256 factor = getBU("factorReward") * safeSub(1 ether, _factorRestrain) / 1 ether + 1 ether;
	//	return calcOrderToMsAmount(_amount) * factor / 1 ether;
	//}   // *= factorReward * (1 - factorRestrain) + 1
	
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
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256) {
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
    function calculateRedeemReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256) {
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
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) public view returns (uint256, uint8) {
        
        uint256 lnBaseTimesExp = ln(_baseN, _baseD) * _expN / _expD;
        uint8 precision = findPositionInMaxExpArray(lnBaseTimesExp);
        assert(precision >= MIN_PRECISION);                                     //hhj+ move from findPositionInMaxExpArray
        return (fixedExp(lnBaseTimesExp >> (MAX_PRECISION - precision), precision), precision);
    }

    // hhj+ support _baseN < _baseD
    function power2(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) public view returns (uint256, uint8) {
        if(_baseN >= _baseD)
            return power(_baseN, _baseD, _expN, _expD);
        uint256 lnBaseTimesExp = ln(_baseD, _baseN) * _expN / _expD;
        uint8 precision = findPositionInMaxExpArray(lnBaseTimesExp);
        if(precision < MIN_PRECISION)
            return (0, 0);
        uint256 base = fixedExp(lnBaseTimesExp >> (MAX_PRECISION - precision), precision);
        base = (uint256(1) << (MIN_PRECISION + MAX_PRECISION)) / base;
        precision = MIN_PRECISION + MAX_PRECISION - precision;
        return (base, precision);
    }

    /**
        Return floor(ln(numerator / denominator) * 2 ^ MAX_PRECISION), where:
        - The numerator   is a value between 1 and 2 ^ (256 - MAX_PRECISION) - 1
        - The denominator is a value between 1 and 2 ^ (256 - MAX_PRECISION) - 1
        - The output      is a value between 0 and floor(ln(2 ^ (256 - MAX_PRECISION) - 1) * 2 ^ MAX_PRECISION)
        This functions assumes that the numerator is larger than or equal to the denominator, because the output would be negative otherwise.
    */
    function ln(uint256 _numerator, uint256 _denominator) public pure returns (uint256) {
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
    function floorLog2(uint256 _n) internal pure returns (uint8) {
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
    function findPositionInMaxExpArray(uint256 _x) internal view returns (uint8) {
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

        //assert(false);                                                        //hhj- move to power
        return 0;
    }

    /**
        This function can be auto-generated by the script &#39;PrintFunctionFixedExp.py&#39;.
        It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
        It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
        The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
        The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
    */
    function fixedExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
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
   
    //function calcChanges(uint256 _value, uint256 _rate, uint256 _time) public view returns (uint256) {
    //    uint256 weight;
    //    uint8 precision;    // _rate^(timeSpan/86400)
    //    (weight, precision) = power2(_rate, 1 ether, uint32(safeSub(now, _time)), uint32(86400/60));     // /60 for test
    //    return safeMul(_value, weight) >> precision;
    //}   // _value * weight / 2^precision
    //
    //function test(uint256 _value, uint32 _exp) public view returns(uint256) {
    //    uint256 weight;
    //    uint8 precision;    // (1/_rate)^(timeSpan/86400)
    //    (weight, precision) = power(1 ether, 980000000000000000, _exp, 1);
    //    return safeDiv(_value << precision, weight);
    //}
    //
    //function test2(uint256 _value, uint32 _exp) public view returns(uint256) {
    //    uint256 weight;
    //    uint8 precision;    // (1/_rate)^(timeSpan/86400)
    //    (weight, precision) = power2(980000000000000000, 1 ether, _exp, 1);
    //    return safeMul(_value, weight) >> precision;
    //}
    //
    //function test3() public returns(uint256) {
    //    log0(bytes32(uint256(-1) / ln(MAX_NUM, 1)));
    //    return uint256(-1) / ln(MAX_NUM, 1);
    //}

}

contract IData is ICalled
{
    // these function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function bu(bytes32) public pure returns(uint256) {}
    function ba(bytes32) public pure returns(address) {}
    //function bi(bytes32) public pure returns(int256) {}
    //function bs(bytes32) public pure returns(string) {}
    //function bb(bytes32) public pure returns(bytes) {}
    
    function bau(bytes32, address) public pure returns(uint256) {}
	function pushBAU2(bytes32, address, uint256) public;
	function setBAU2(bytes32, address , uint256, uint256) public;
	function getBAU2(bytes32, address , uint256) public view returns(uint256);
	function getBAU2Length(bytes32, address)public view returns(uint256);
	
	//order转账时，自身的order列表需要减少长度
	function cutBAU2Length(bytes32, address, uint256)public returns(uint256);
	
    function bua(bytes32, uint256) public pure returns(address) {}
    //function bai(bytes32, address) public pure returns(int256) {}
    function bas(bytes32, address) public pure returns(string) {}
    //function bab(bytes32, address) public pure returns(bytes) {}
    
    function buu(bytes32, uint256) public pure returns(uint256) {}
    function buuu(bytes32, uint256, uint256) public pure returns(uint256) {}
    //function bui(bytes32, uint256) public pure returns(int256) {}
    //function bus(bytes32, uint256) public pure returns(string) {}
    //function bub(bytes32, uint256) public pure returns(bytes) {}
    
    function baau(bytes32, address, address) public pure returns(uint256) {}
    function baaau(bytes32, address, address, address) public pure returns(uint256) {}
    
    function setBU(bytes32 _key, uint256 _value) public;
    function setBA(bytes32 _key, address _value) public;
    //function setBI(bytes32 _key, int256 _value) public;
    //function setBS(bytes32 _key, string _value) public;
    //function setBB(bytes32 _key, bytes _value) public;
    
    function setBAU(bytes32 _key, address _addr, uint256 _value) public;
    function setBUA(bytes32 _key, uint256 _index, address _addr) public;
    //function setBAI(bytes32 _key, address _addr, int256 _value) public;
    function setBAS(bytes32 _key, address _addr, string _value) public;
    //function setBAB(bytes32 _key, address _addr, bytes _value) public;
    
    function setBUU(bytes32 _key, uint256 _index, uint256 _value) public;
	function setBUUU(bytes32 _key, uint256 _index,  uint256 _index2, uint256 _value) public;
    //function setBUI(bytes32 _key, uint256 _index, int256 _value) public;
    //function setBUS(bytes32 _key, uint256 _index, string _value) public;
    //function setBUB(bytes32 _key, uint256 _index, bytes _value) public;

    function setBAAU(bytes32 _key, address _token, address _addr, uint256 _value) public;
    function setBAAAU(bytes32 _key, address _token, address _from, address _to, uint256 _value) public;
}