pragma solidity ^0.4.23;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="412520372401202a2e2c23206f222e2c">[email&#160;protected]</a>
// released under Apache 2.0 licence
contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public pure returns (address) {}

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

contract IERC223Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _holder) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);
}
contract IERC20Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _holder) public view returns (uint256);
    function allowance(address _from, address _spender) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _holder, address indexed _spender, uint256 _value);
}
contract ICaller{
	function calledUpdate(address _oldCalled, address _newCalled) public;  // ownerOnly
	
	event CalledUpdate(address _oldCalled, address _newCalled);
}

contract IERC721 {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens);
    function takeOwnerShip(uint256 _tokenId) public;
    function setTokenMetadata(uint256 _tokenId, string _recommendJson) public;
    function getTokenMetadata(uint256 _tokenId) public view returns(string);
    function supportsInterface(bytes4 interfaceID) public view returns (bool);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    
    //
    //function approvalForAll() public;
    //function isApproved() public;
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
	/**
        @dev Returns the largest integer smaller than or equal to _x.
        @param _x   number _x
        @return     value
    */
	function floor(uint _x)public pure returns(uint){
		return (_x / 1 ether) * 1 ether;
	}
	
	/**
        @dev Returns the smallest integer larger than or equal to _x.
        @param _x   number _x
        @return     value
    */
	function ceil(uint _x)public pure returns(uint ret){
		ret = (_x / 1 ether) * 1 ether;
		if((_x % 1 ether) == 0){
			return ret;
		}else{
			return ret + 1 ether;
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

contract IERC223Receiver {
  
   /**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}
contract RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;

    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0) 
            return RLPItem(0, 0);

        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item));

        uint items = numItems(item);
        result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr); 
            memPtr = memPtr + dataLen;
        }
    }

    /*
    * Helpers
    */

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) internal pure returns (uint) {
        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) internal pure returns (uint len) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 1;
        
        else if (byte0 < STRING_LONG_START)
            return byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                len := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        } 

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) internal pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) 
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /** RLPItem conversions into data types **/

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix according to RLP spec
        require(item.len == 21, "Invalid RLPItem. Addresses are encoded in 20 bytes");
        
        uint memPtr = item.memPtr + 1; // skip the length prefix
        uint addr;
        assembly {
            addr := div(mload(memPtr), exp(256, 12)) // right shift 12 bytes. we want the most significant 20 bytes
        }
        
        return address(addr);
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;
        uint memPtr = item.memPtr + offset;

        uint result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len))) // shift to the correct location
        }

        return result;
    }
    
/*	function test(bytes _header) public  {
	    RLPReader.RLPItem[] memory header = toList(toRlpItem(_header)); 
        bytes32 hash = toBytes32(header[1]);
        log1("aaH",hash);
	}
      

	function test1(bytes _headers) public  {
	    RLPReader.RLPItem[] memory headers = toList(toRlpItem(_headers)); 
	    RLPReader.RLPItem[] memory header0=toList(headers[0]);     
	  //  log1("header0[1]:",header0[1]);
        bytes32 hash = toBytes32(header0[1]);
        log1("aaH",hash);
	}*/
  

    function toBytes(RLPItem memory item) internal pure returns (bytes) {
        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    function toBytes32(RLPItem memory item) internal pure returns (bytes32) {
        uint u=toUint(item);
        return bytes32(u);
    }


    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) internal pure {
        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(dest))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

contract IMiningShares is IOwned, ICaller {
    /**
        获取价格
     */
    function price() view public returns(uint256);
    /**
        万份收益
     */
    function incomeOf10k() view public returns(uint256);
    /**
        七日年化收益
     */
    function yield7Day() view public returns(uint256);

    /**
        订单总数
     */
    function amountOfOrderQueue() view public returns(uint256 amount);

    /**
        矿石兑换总数
     */
    function amountOfWorkpointQueue() view public returns(uint256 amount);
    
    /**
        
     */
    function rewardsFactor() view public returns(uint256 factor);             //for 721
    function additionalRewards() view public returns(uint256 amount);
    
    /**
        挖矿兑换，返回矿石
        参考 ConvertReward.sol ConvertPoolReward
     */
    //function mining(uint256 _height, bytes _header)public payable returns(uint256 msm);
    function mining(bytes _header)public payable returns(uint256 msm);

    /**
        锻造，锻造矿石，兑换成其他token
        Foundry
        params:
            _msm  兑换矿石总量，小于总量抛出异常
            _isPositive4DividendOrNegative4Redeem 兑换类型
                等于0 兑换成 ?
                大于0 兑换成 ?
                小于0 兑换成 ?
     */
    function forging(uint256 _msm, uint256 _target) public returns (uint256 msm2, uint256 msr, uint256 ms, uint256 msd);

    /**
        申购矿股
        params: 
            _wantDividend 想要分红矿股
            _nonInvate 是否使用邀请码
        return:
            mso 矿股订单数量
            amount 申购的矿股数量
     */
    function purchase(bool _wantDividend, bool _nonInvate) public payable;

    /**
        取消订单
        params:
            _mso 订单数量
            _fromHead 队尾或对头
        return:
            eth 取消数量
     */
    function cancelOrder(uint256 _mso, bool _fromHead) public returns(uint256 eth);

    /**
        锁定矿股
        params:
            _ms 矿股总数
        return:
            msd 锁定矿股总数
     */
    function lock4Dividend(uint256 _msd2_ms) public returns(uint256 msd);

    /**
        分红矿股解锁(%2)
        params:
            _msd 总数
        return
            msd2 解锁总数
     */
    function unlock4Circulate(uint256 _msd) public returns(uint256 msd2);

    function transferMS(address _to, uint256 _ms) public returns (bool success);
    function transferMSI(address _to, uint256 _msi) public returns (bool success);
    function transferMSM(address _to, uint256 _msm) public returns (bool success);
    function batchTransferMSM(address[] _tos, uint256[] _msms) public returns(uint256 msmSum);

    /**
        冷却矿股(%2) => 赎回矿股
        params:
            _ms 矿股数量
        return:
            ms2r 冷却中的数量
     */
    function apply4Redeem(uint256 _ms) public returns(uint256 ms2r);

    /**
        赎回矿股 => 流通矿股
        params:
            _msr 数量
        return:
            ms 数量
     */
    function cancelRedeem(uint256 _ms2r_msr) public returns(uint256 ms);

    /**
        赎回矿股 => ETH
        params:
            amountMSR 赎回矿股数量
        return:
            amountETH ETH数量
     */
    function redeem(uint256 msr) public returns(uint256 eth);
    
	/*
		设置矿池默认的锻造结果：
		params: 1:分红 2:流通 3:清算
	*/
	function setTransformTarget(uint256 _value)public;

	/*
		矿池结算(批量转账)时，是否直接排队换矿股: 
		params: 1排队，2不排队
	*/
	function setLineUpEnable(uint256 _value)public;
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

contract ISmartToken{
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
	//function() public payable;
}


contract ICalled is IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function callers(address) public pure returns (bool) { }

    function appendCaller(ICaller _caller) public;  // ownerOnly
    function removeCaller(ICaller _caller) public;  // ownerOnly
    
    event AppendCaller(ICaller _caller);
    event RemoveCaller(ICaller _caller);
}


contract IData is ICalled
{
    // these function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function bu(bytes32) public pure returns(uint256) {}
    function ba(bytes32) public pure returns(address) {}
    // function baa(bytes32, address) public pure returns(address) {}
    //function bi(bytes32) public pure returns(int256) {}
    //function bs(bytes32) public pure returns(string) {}
    //function bb(bytes32) public pure returns(bytes) {}
    
    function bau(bytes32, address) public pure returns(uint256) {}
	// function pushBAU2(bytes32, address, uint256) public;
	// function setBAU2(bytes32, address , uint256, uint256) public;
	// function getBAU2(bytes32, address , uint256) public view returns(uint256);
	// function getBAU2Length(bytes32, address)public view returns(uint256);
	
	//order转账时，自身的order列表需要减少长度
	// function cutBAU2Length(bytes32, address, uint256)public returns(uint256);
	
    function bua(bytes32, uint256) public pure returns(address) {}
    //function bai(bytes32, address) public pure returns(int256) {}
    function bas(bytes32, address) public pure returns(string) {}
    //function bab(bytes32, address) public pure returns(bytes) {}
    
    function buu(bytes32, uint256) public pure returns(uint256) {}
    function bauu(bytes32, address, uint256) public pure returns(uint256) {}
    function buuu(bytes32, uint256, uint256) public pure returns(uint256) {}
    //function bui(bytes32, uint256) public pure returns(int256) {}
    //function bus(bytes32, uint256) public pure returns(string) {}
    //function bub(bytes32, uint256) public pure returns(bytes) {}
    
    function baau(bytes32, address, address) public pure returns(uint256) {}
    function baaau(bytes32, address, address, address) public pure returns(uint256) {}
    
    function setBU(bytes32 _key, uint256 _value) public;
    function setBA(bytes32 _key, address _value) public;
    // function setBAA(bytes32 _key, address _addr, address _value) public;
    //function setBI(bytes32 _key, int256 _value) public;
    //function setBS(bytes32 _key, string _value) public;
    //function setBB(bytes32 _key, bytes _value) public;
    
    function setBAU(bytes32 _key, address _addr, uint256 _value) public;
    function setBUA(bytes32 _key, uint256 _index, address _addr) public;
    //function setBAI(bytes32 _key, address _addr, int256 _value) public;
    function setBAS(bytes32 _key, address _addr, string _value) public;
    //function setBAB(bytes32 _key, address _addr, bytes _value) public;
    
    function setBUU(bytes32 _key, uint256 _index, uint256 _value) public;
	function setBAUU(bytes32 _key, address _addr, uint256 _index, uint256 _value) public;
	function setBUUU(bytes32 _key, uint256 _index,  uint256 _index2, uint256 _value) public;
    //function setBUI(bytes32 _key, uint256 _index, int256 _value) public;
    //function setBUS(bytes32 _key, uint256 _index, string _value) public;
    //function setBUB(bytes32 _key, uint256 _index, bytes _value) public;

    function setBAAU(bytes32 _key, address _token, address _addr, uint256 _value) public;
    function setBAAAU(bytes32 _key, address _token, address _from, address _to, uint256 _value) public;
}

contract DataCaller is Owned, ICaller {
    IData public data;
    
    constructor(IData _data) public {
        data = IData(_data);
    }
    
    function calledUpdate(address _oldCalled, address _newCalled) public ownerOnly {
        if(data == _oldCalled) {
            data = IData(_newCalled);
            emit CalledUpdate(_oldCalled, _newCalled);
        }
    }
    
	// function getBAU2(bytes32 _key, address _addr, uint256 _index) internal view returns(uint256 val) {
		// return data.getBAU2(_key,_addr,_index);
	// }
	// function getBAU2Length(bytes32 _key, address _addr) internal view returns(uint256 length) {
		// length = data.getBAU2Length(_key,_addr);
	// }
	// function pushBAU2(bytes32 _key, address _addr, uint256 _value) internal {
		// data.pushBAU2(_key,_addr,_value);
	// }
	// function cutBAU2Length(bytes32 _key, address _addr, uint256 _newLength) internal returns(uint256) {
		// return data.cutBAU2Length(_key,_addr, _newLength);
	// }
	// function setBAU2(bytes32 _key, address _addr, uint256 _index, uint256 _value) internal {
		// data.setBAU2(_key,_addr,_index,_value);
	// }
	
    function getBU(bytes32 _key) internal view returns(uint256) {
        return data.bu(_key);        
    }
    function getBA(bytes32 _key) internal view returns(address) {
        return data.ba(_key);        
    }
    // function getBAA(bytes32 _key, address _addr) internal view returns(address) {
        // return data.baa(_key, _addr);        
    // }
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
	function getBAUU(bytes32 _key, address _addr, uint256 _index) internal view returns(uint256) {
        return data.bauu(_key, _addr, _index);        
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
    // function setBAA(bytes32 _key, address _addr, address _value) internal {
        // data.setBAA(_key, _addr, _value);    
    // }
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
	function setBAUU(bytes32 _key, address _addr, uint256 _index, uint256 _value) internal {
        data.setBAUU(_key, _addr, _index, _value);    
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

contract CommonArgsSetter is DataCaller{
    bytes32 m_dataKey  = "CommonArguments";
    bytes32 m_dataKey2 = "CommonArguments2";
    bytes32 m_dataKey3 = "CommonArguments3";
    bytes32 m_dataKey4 = "CommonArguments4";
    bytes32 m_dataKey5 = "CommonArguments5";
	
	constructor(IData _data) DataCaller(_data) public {
		
	}
	
	function init()public ownerOnly{
		//通用分母
		setBUU(m_dataKey, 0, 1000000);
		
		/***************order用到的***************/
		//OrderSupportCancel
		setBUU(m_dataKey, 1000, 1);
		// OrderDealSpeed : 1%
		setBUU(m_dataKey, 1001, 10000);
		// OrderListLengthFactor: 20%
		setBUU(m_dataKey, 1002, 200000);
		// InvitationValidPeriod: 100 days
		setBUU(m_dataKey, 1003, 100 days);
		//OrderDealTimeInterval: 1 days
		setBUU(m_dataKey, 1004, 1 days);
		//由order量计算邀请码量用到的参数，等于通用分母的 2 倍(发两倍的邀请码)
		setBUU(m_dataKey, 1005, 1000000*2);
		
		// 工分支持取消(默认不支持)
		// setBUU(m_dataKey, 2000, 0);
		
		//工分排队，成交后买到的三种token：1:分红,2流通,3清算
		setBUU(m_dataKey, 2001, 1);
		//矿池在给旷工结算收益时，是否直接将矿石排队买矿股：1：排队， 2：不排队
		setBUU(m_dataKey, 2002, 1);
	}
	
	function getterForTest(uint256 key)public view returns(uint256){
		return getBUU(m_dataKey, key);
	}
	
	//通用分母
	function setDenominator(uint256 _value)public ownerOnly{
		setBUU(m_dataKey, 0, _value);
	}
	
	//order用到的参数	
	function setOrderSupportCancel(uint256 _value)public ownerOnly{
		setBUU(m_dataKey, 1000, _value);
	}
	function setOrderDealSpeed(uint256 _value)public ownerOnly{
		setBUU(m_dataKey, 1001, _value);
	}
	function setOrderListLengthFactor(uint256 _value)public ownerOnly{
		setBUU(m_dataKey, 1002, _value);
	}
	function setInvitationValidPeriod(uint256 _value)public ownerOnly{
		setBUU(m_dataKey, 1003, _value);
	}
	function setOrderDealTimeInterval(uint256 _value)public ownerOnly{
		setBUU(m_dataKey, 1004, _value);
	}
	function setInvitationMultiple(uint256 _value)public ownerOnly{
		setBUU(m_dataKey, 1005, _value);
	}
	
	//工分用到的参数	
	function setWorkpointSupportCancel(uint256 _value)public ownerOnly{
		setBUU(m_dataKey, 2000, _value);
	}
	function setTransformTarget_default(uint256 _value)public ownerOnly{
		setBUU(m_dataKey, 2001, _value);
	}
	function setTransformTarget_pool(address _sender, uint256 _value)public ownerOnly{
		setBAU(m_dataKey2, _sender, _value);
	}
	function setTransformTarget_miner(address _sender, uint256 _value)public ownerOnly{
		setBAU(m_dataKey3, _sender, _value);
	}
	
	function setLineUpEnable_default(uint256 _value)public ownerOnly{
		setBUU(m_dataKey, 2002, _value);
	}
	function setLineUpEnable_pool(address _sender, uint256 _value)public ownerOnly{
		setBAU(m_dataKey4, _sender, _value);
	}
	function setLineUpEnable_miner(address _sender, uint256 _value)public ownerOnly{
		setBAU(m_dataKey5, _sender, _value);
	}
}
contract IReserve is ICalled {
    // these function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
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


contract MiningShares is IMiningShares, DataCaller, RLPReader, Utils {
    IReserve internal reserve;
    IFormula internal formula;
    IMiningSharesImpl internal impl;
    
    constructor(IData _data, IReserve _reserve, IFormula _formula, IMiningSharesImpl _impl) DataCaller(IData(_data)) public {
        reserve = _reserve;
        formula = _formula;
        impl = _impl;
    }
    
    //function tokenCalledUpdate(bytes32 sym, ICalled _oldCalled, ICalled _newCalled) internal {
    //    IDummyToken dummy = IDummyToken(getBA(sym));
    //    dummy.calledUpdate(_oldCalled, _newCalled);
    //    dummy.operator().calledUpdate(_oldCalled, _newCalled);
    //}
    
    function calledUpdate(address _oldCalled, address _newCalled) public ownerOnly {
        //tokenCalledUpdate("MS", _oldCalled, _newCalled);
        //tokenCalledUpdate("MSD", _oldCalled, _newCalled);
        //tokenCalledUpdate("MSD2", _oldCalled, _newCalled);
        //tokenCalledUpdate("MSR", _oldCalled, _newCalled);
        //tokenCalledUpdate("MS2R", _oldCalled, _newCalled);
        //tokenCalledUpdate("MSI", _oldCalled, _newCalled);
        //tokenCalledUpdate("MSO", _oldCalled, _newCalled);
        //tokenCalledUpdate("MSM", _oldCalled, _newCalled);
        //tokenCalledUpdate("MSM2", _oldCalled, _newCalled);
        //formula.calledUpdate(_oldCalled, _newCalled);
        
        if(data == _oldCalled){
            data = IData(_newCalled);
        }else if(reserve == _oldCalled){
            reserve = IReserve(_newCalled);
        }else if(formula == _oldCalled){
            formula = IFormula(_newCalled);
        }else if(impl == _oldCalled){
			impl = IMiningSharesImpl(_oldCalled);
		}else{
            return;
        }
        emit CalledUpdate(_oldCalled, _newCalled);
    }
    
    function totalSupply() public view returns (uint256 result) {
        return formula.totalSupply();
    }
    
    function balanceOf(address _addr)public view returns(uint256 result) {
        return formula.balanceOf(_addr);
    }

    function price() view public returns(uint256) {
        return formula.price();
    }
    
    function incomeOf10k() view public returns(uint256) {
        return 0;
    }
    
    function yield7Day() view public returns(uint256) {
        return  0;
    }
    
    function amountOfOrderQueue() view public returns(uint256 amount) {
        return getBU("orderQueue.amount");
    }
    function amountOfWorkpointQueue() view public returns(uint256 amount) {
        return getBU("workpointQueue.amount");
    }
    
    function rewardsFactor() view public returns(uint256 factor) {              //for 721
        return 0;
    }
    
    function additionalRewards() view public returns(uint256 amount) {
        return 0;
    }

    function updateEmaDailyYield(uint256 _value) internal returns(uint256) {
        uint256 ema = getBU("emaDailyYield");
        uint32 timeSpan = uint32(safeSub(now, getBU("timeLastMining")));
        ema = formula.calcEma(ema, _value, timeSpan, 86400);
        setBU("emaDailyYield", ema);
        return ema;
    }
    
    function updateFactorReward() internal  returns(uint256) {
        uint256 factorReward = formula.calcFactorReward(getBU("emaDailyYield"));
        setBU("factorReward", factorReward);
        return factorReward;
    }

	function ParseHeaderItem(RLPReader.RLPItem item) internal pure returns(address coinBase, uint256 height, bool hasNonceMark,bytes32 unclesHash,bytes32 parentHash){
	    RLPReader.RLPItem[] memory ls = toList(item); 
        coinBase = toAddress(ls[2]);
        height = toUint(ls[8]);
        bytes memory nonce=toBytes(ls[14]);
        bytes2[4] memory nonceArray;
        for (uint i = 0; i < 4; i++) {
            nonceArray[i] |= bytes2(nonce[i*2] & 0xFF) ;
            nonceArray[i] |= bytes2(nonce[i*2+1] & 0xFF)>> 8;
        }
        hasNonceMark = (nonceArray[3] == (nonceArray[0] ^ nonceArray[1] ^ nonceArray[2]));
		unclesHash = toBytes32(ls[1]);
		parentHash = toBytes32(ls[0]);
    }
	
	function ParseHeaderData(bytes _header) internal pure returns(address coinBase, uint256 height, bool hasNonceMark,bytes32 unclesHash,bytes32 parentHash){
		RLPReader.RLPItem memory item=toRlpItem(_header);
		return ParseHeaderItem(item);
    }
	

    function setQueue(uint256 value) public{
        setBU("queueFlag", value);
    }

    function getQueue() public view returns(uint256) {
        return getBU("queueFlag");
    }


    event Mining(address indexed _spender, address indexed _coinBase, bool indexed _hasNonceMark, uint256 _height, uint256 _value);
	function mining(bytes _header) public payable returns(uint256 msm) {
        address coinBase;
        uint256 height;
        bool hasNonceMark;
	    bytes32 unclesHash;
	    bytes32 parentHash;
        (coinBase, height, hasNonceMark, unclesHash, parentHash) = ParseHeaderData(_header);
	    require(coinBase != 0x0);
	    require(blockhash(height) == keccak256(_header));
        require(getBUU("convertedOf", height) == 0);
        setBUU("convertedOf", height, 1);
		
		emit Mining(msg.sender, coinBase, hasNonceMark, height, msg.value);
        
        //require(msg.value > 0);
        reserve.depositMineral.value(msg.value)();
        updateEmaDailyYield(msg.value);     // todo <= 3
        updateFactorReward();
        setBU("timeLastMining", now);
	//有nonce标记的，存到data里，MSM_Operator的issue方法会检查该字段
	//setBAU("hasNonceMark", coinBase, verifyHeadNonce(_header) ? 1 : 0);
	    setBU("hasNonceMark", hasNonceMark ? 1 : 0);
        ITokenOperator(IDummyToken(getBA("MSM")).operator()).issue(coinBase, msg.value);
        msm = msg.value;
        if (getQueue()==uint256(1)) 
			impl.dequeueOrder();
        else if(getQueue()==uint256(2)) 
			impl.dequeueIngot();
		else
			impl.dequeueDouble();
    }
    
    event MiningUncle(address indexed _spender, address indexed _coinBase, bool indexed _hasNonceMark, uint256 _height, uint256 _value, uint256 _index);
    function mining_uncle(bytes _header, bytes _uncleHeader, uint256 index) public payable returns(uint256 msm) {
        address[2] memory coinBase;
        uint256[2] memory height;
        bool[2] memory hasNonceMark;
		bytes32[2] memory unclesHash;		
		bytes32[2] memory parentHash;
        (coinBase[0], height[0], hasNonceMark[0],unclesHash[0],parentHash[0]) = ParseHeaderData(_header);
		require(coinBase[0] != 0x0);
	//	require(blockhash(height[0]) == keccak256(_header));
		require(unclesHash[0] == keccak256(_uncleHeader));
	
		RLPReader.RLPItem[] memory headers = toList(toRlpItem(_uncleHeader)); 
        (coinBase[1], height[1], hasNonceMark[1],unclesHash[1],parentHash[1]) = ParseHeaderItem(headers[index]);

		emit MiningUncle(msg.sender, coinBase[1], hasNonceMark[1], height[1], msg.value, index);
        
		require(coinBase[1] != 0x0);
	//	require(blockhash(height[1]-1) == parentHash[1]);
		if (index==0){
			require(getBUU("convertedOfUncle0", height[0]) == 0);
			setBUU("convertedOfUncle0", height[0], 1);
		}
		else if(index==1){
			require(getBUU("convertedOfUncle1", height[0]) == 0);
			setBUU("convertedOfUncle1", height[0], 1);
		}
		uint256 amount=getUncleAmount(safeSub(height[0],height[1]));//此uncle应得eth
		require(msg.value>=amount);
        reserve.depositMineral.value(amount)();
        updateEmaDailyYield(amount);     // todo <= 3
        updateFactorReward();
        setBU("timeLastMining", now);
		//有nonce标记的，存到data里，MSM_Operator的issue方法会检查该字段
		//setBAU("hasNonceMark", coinBase, verifyHeadNonce(_header) ? 1 : 0);
		setBU("hasNonceMark", hasNonceMark[1] ? 1 : 0);
        ITokenOperator(IDummyToken(getBA("MSM")).operator()).issue(coinBase[1], amount);  
        msm = amount;

        if (getQueue()==uint256(1)) 
           impl.dequeueOrder();
        else if(getQueue()==uint256(2)) 
           impl.dequeueIngot();
		else
			impl.dequeueDouble();
 
    }

	function getUncleAmount(uint256 heightDiff) public pure returns(uint256) {
		  return safeDiv(safeMul(safeSub(8, heightDiff), 3*(1 ether)), 8);
	}

    function forging(uint256 _msm, uint256 _target) public returns(uint256 msm2, uint256 msr, uint256 ms, uint256 msd) {
        return impl.impl_forging(msg.sender, _msm, _target);
    }
    
    function purchase(bool _wantDividend, bool _nonInvate) public payable {
        return impl.impl_purchase.value(msg.value)(msg.sender, _wantDividend, _nonInvate);
    }

    function cancelOrder(uint256 _mso, bool _fromHead) public returns(uint256 eth) {
        return impl.impl_cancelOrder(msg.sender, _mso, _fromHead);
    }
    
    function lock4Dividend(uint256 _msd2_ms) public returns(uint256 msd) {
        return impl.impl_lock4Dividend(msg.sender, _msd2_ms);
    }
    
    function unlock4Circulate(uint256 _msd) public returns(uint256 msd2) {
        return impl.impl_unlock4Circulate(msg.sender, _msd);
    }
    
    function transferMS(address _to, uint256 _ms) public returns(bool success) {
        return IDummyToken(getBA("MS")).operator().token_transfer(msg.sender, _to, _ms);
    }
    
    function transferMSI(address _to, uint256 _msi) public returns(bool success) {
        return IDummyToken(getBA("MSI")).operator().token_transfer(msg.sender, _to, _msi);
    }
    
    function transferMSM(address _to, uint256 _msm) public returns(bool success) {
        return IDummyToken(getBA("MSM")).operator().token_transfer(msg.sender, _to, _msm);
    }
    
    function batchTransferMSM(address[] _tos, uint256[] _msms) public returns(uint256 msmSum) {
        return IMSM_Operator(IDummyToken(getBA("MSM")).operator()).token_batchTransfer(msg.sender, _tos, _msms);
    }
    
    function apply4Redeem(uint256 _ms) public returns(uint256 msr) {
        return impl.impl_apply4Redeem(msg.sender, _ms);
    }
    
    function cancelRedeem(uint256 _ms2r_msr) public returns(uint256 ms) {
        return impl.impl_cancelRedeem(msg.sender, _ms2r_msr);
    }
    
    function redeem(uint256 _msr) public returns(uint256 eth) {
        return impl.impl_redeem(msg.sender, _msr);
    }

    //function tokenFallback(address _from, uint _value, bytes _data) public {
    //    
    //}
    function setTransformTarget(uint256 _value)public{
		if(IERC721(getBA("SmartERC721")).balanceOf(msg.sender) > 0){
			CommonArgsSetter(getBA("CommonArgsSetter")).setTransformTarget_pool(msg.sender, _value);
		}else{
			CommonArgsSetter(getBA("CommonArgsSetter")).setTransformTarget_miner(msg.sender, _value);
		}
	}
	
	function setLineUpEnable(uint256 _value)public{
		if(IERC721(getBA("SmartERC721")).balanceOf(msg.sender) > 0){
			CommonArgsSetter(getBA("CommonArgsSetter")).setLineUpEnable_pool(msg.sender, _value);
		}else{
			CommonArgsSetter(getBA("CommonArgsSetter")).setLineUpEnable_miner(msg.sender, _value);
		}
	}
	
    function () public payable {
       purchase(false, false);
    }
    
}

contract IMSM_Operator {
	function token_batchTransfer(address _from, address[] _tos, uint256[] _msms) public returns(uint256);    //callerOnly
}

contract IDummyToken is IERC20Token, IERC223Token, IERC223Receiver, ICaller, IOwned {
    // these function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function operator() public pure returns(ITokenOperator) {}
    //ITokenOperator public operator;
}

contract IMiningSharesImpl is ICalled, ICaller {
    //function impl_price() view public returns(uint256);
    //function impl_incomeOf10k() view public returns(uint256);
    //function impl_yield7Day() view public returns(uint256);
    //function impl_amountOfOrderQueue() view public returns(uint256 amount);
    //function impl_amountOfWorkpointQueue() view public returns(uint256 amount);
    //function impl_rewardsFactor() view public returns(uint256 factor);             //for 721
    //function impl_additionalRewards() view public returns(uint256 amount);
    
    //function impl_mining(address _from, uint256 _height, bytes _header)public payable returns(uint256 msm);
    //function impl_mining(address _from, bytes _header)public payable returns(uint256 msm);
    //function impl_mining_uncle(address _from, bytes _header,bytes _uncleHeader,uint256 index) public payable returns(uint256 msm); 
    
    function dequeueOrder() public;
    function dequeueIngot() public;
    function dequeueAlternately() public;
    function dequeueDouble() public;
    function dequeue() public;
    
    function impl_forging(address _from, uint256 _msm, uint256 _target) public returns (uint256 msm2, uint256 msr, uint256 ms, uint256 msd);
    function impl_purchase(address _from, bool _wantDividend, bool _nonInvate) public payable;
    function impl_cancelOrder(address _from, uint256 _msm, bool _fromHead) public returns(uint256 eth);
    function impl_lock4Dividend(address _from, uint256 _msd2_ms) public returns(uint256 msd);
    function impl_unlock4Circulate(address _from, uint256 _msd) public returns(uint256 msd2);

    //function impl_transferMS(address _from, address _to, uint256 _ms) public returns (bool success);
    //function impl_transferMSI(address _from, address _to, uint256 _msi) public returns (bool success);
    //function impl_transferMSM(address _from, address _to, uint256 _msm) public returns (bool success);
    //function impl_batchTransferMSM(address _from, address[] _tos, uint256[] _msms) public returns(uint256 msmSum);

    function impl_apply4Redeem(address _from, uint256 _ms) public returns(uint256 ms2r);
    function impl_cancelRedeem(address _from, uint256 _ms2r_msr) public returns(uint256 ms);
    function impl_redeem(address _from, uint256 msr) public returns(uint256 eth);
}

contract IFormula is IOwned, ICaller {
    uint32 public constant MAX_WEIGHT = 1000000;
    function reserve() public pure returns(IReserve) { }

    function totalSupply() public view returns (uint256);
    function balanceOf(address _addr)public view returns(uint256);
    function price() view public returns(uint256);
    //function costOfTxShares() view public returns(uint256);
    
	function calcTimedQuota(uint256 _rest, uint256 _full, uint256 _timespan, uint256 _period) public pure returns (uint256);
    function calcEma(uint256 _emaPre, uint256 _value, uint32 _timeSpan, uint256 _period) public view returns(uint256);
    function calcFactorReward(uint256 _dailyYield) public view returns(uint256);
    
    //function calcInvitationAmount(uint256 _orderAmount)public view returns(uint256);      // moved to DealOrder
	function calcOrderToMsAmount(uint256) public view returns(uint256);
	//function calcMiningSharesAmount(uint256 _amount, uint256 _factorRestrain) public view returns(uint256);

    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public constant returns (uint256);
    function calculateRedeemReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public constant returns (uint256);
	
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) public view returns (uint256, uint8);
    function power2(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) public view returns (uint256, uint8);
    function ln(uint256 _numerator, uint256 _denominator) public pure returns (uint256);
    
}

contract ITokenOperator is ISmartToken, ICalled, ICaller {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function dummy() public pure returns (IDummyToken) {}
    
    function updateChanges(address) public;
    function updateChangesByBrother(address, uint256, uint256) public;
    
    function token_name() public view returns (string);
    function token_symbol() public view returns (string);
    function token_decimals() public view returns (uint8);
    
    function token_totalSupply() public view returns (uint256);
    function token_balanceOf(address _owner) public view returns (uint256);
    function token_allowance(address _from, address _spender) public view returns (uint256);

    function token_transfer(address _from, address _to, uint256 _value) public returns (bool success);
    function token_transfer(address _from, address _to, uint _value, bytes _data) public returns (bool success);
    function token_transfer(address _from, address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success);
    function token_transferFrom(address _spender, address _from, address _to, uint256 _value) public returns (bool success);
    function token_approve(address _from, address _spender, uint256 _value) public returns (bool success);
    
    function fallback(address _from, bytes _data) public payable;                      		// eth input
    function token_fallback(address _token, address _from, uint _value, bytes _data) public;    // token input from IERC233
}