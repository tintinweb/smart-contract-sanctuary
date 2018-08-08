pragma solidity ^0.4.23;
contract RLPEncode {
    uint8 constant STRING_SHORT_PREFIX = 0x80;
    uint8 constant STRING_LONG_PREFIX = 0xb7;
    uint8 constant LIST_SHORT_PREFIX = 0xc0;
    uint8 constant LIST_LONG_PREFIX = 0xf7;

    /// @dev Rlp encodes a bytes
    /// @param self The bytes to be encoded
    /// @return The rlp encoded bytes
	function encodeBytes(bytes memory self) internal constant returns (bytes) {
        bytes memory encoded;
        if(self.length == 1 && uint(self[0]) < 0x80) {
            encoded = new bytes(1);
            encoded = self;
        } else {
        	encoded = encode(self, STRING_SHORT_PREFIX, STRING_LONG_PREFIX);
		}
        return encoded;
    }

    /// @dev Rlp encodes a bytes[]. Note that the items in the bytes[] will not automatically be rlp encoded.
    /// @param self The bytes[] to be encoded
    /// @return The rlp encoded bytes[]
    function encodeList(bytes[] memory self) internal constant returns (bytes) {
    	bytes memory list = flatten(self);
	    bytes memory encoded = encode(list, LIST_SHORT_PREFIX, LIST_LONG_PREFIX);
        return encoded;
    }

    function encode(bytes memory self, uint8 prefix1, uint8 prefix2) private constant returns (bytes) {
    	uint selfPtr;
        assembly { selfPtr := add(self, 0x20) }

        bytes memory encoded;
        uint encodedPtr;

    	uint len = self.length;
        uint lenLen;
        uint i = 0x1;
	    while(len/i != 0) {
	        lenLen++;
	        i *= 0x100;
	    }

        if(len <= 55) {
		    encoded = new bytes(len+1);

            // length encoding byte
		    encoded[0] = byte(prefix1+len);

            // string/list contents
            assembly { encodedPtr := add(encoded, 0x21) }
            memcpy(encodedPtr, selfPtr, len);
        } else {
        	// 1 is the length of the length of the length
		    encoded = new bytes(1+lenLen+len);

            // length of the length encoding byte
		    encoded[0] = byte(prefix2+lenLen);

            // length bytes
		    for(i=1; i<=lenLen; i++) {
		        encoded[i] = byte((len/(0x100**(lenLen-i)))%0x100);
		    }

            // string/list contents
            assembly { encodedPtr := add(add(encoded, 0x21), lenLen) }
            memcpy(encodedPtr, selfPtr, len);
        }
        return encoded;
    }

    function flatten(bytes[] memory self) private constant returns (bytes) {
        if(self.length == 0) {
            return new bytes(0);
        }

        uint len;
    	for(uint i=0; i<self.length; i++) {
    		len += self[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint flattenedPtr;
        assembly { flattenedPtr := add(flattened, 0x20) }

        for(i=0; i<self.length; i++) {
            bytes memory item = self[i];

            uint selfPtr;
            assembly { selfPtr := add(item, 0x20)}

            memcpy(flattenedPtr, selfPtr, item.length);
            flattenedPtr += self[i].length;
        }

        return flattened;
    }

    /// This function is from Nick Johnson&#39;s string utils library
    function memcpy(uint dest, uint src, uint len) private {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }



	//self function
	// 十六进制字符串转换成bytes
    function strToBytes(string data)returns (bytes){

        uint _ascii_0 = 48;
        uint _ascii_A = 65;
        uint _ascii_a = 97;

        bytes memory a = bytes(data);
        uint[] memory b = new uint[](a.length);

        for (uint i = 0; i < a.length; i++) {
            uint _a = uint(a[i]);

            if (_a > 96) {
                b[i] = _a - 97 + 10;
            }
            else if (_a > 66) {
                b[i] = _a - 65 + 10;
            }
            else {
                b[i] = _a - 48;
            }
        }

        bytes memory c = new bytes(b.length / 2);
        for (uint _i = 0; _i < b.length; _i += 2) {
            c[_i / 2] = byte(b[_i] * 16 + b[_i + 1]);
        }

        return c;
    }


    function bytesToUint(bytes b) public returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function addressToBytes(address a) constant returns (bytes b){
   assembly {
        let m := mload(0x40)
        mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
        mstore(0x40, add(m, 52))
        b := m
   }

}
}


contract ERC20Interface {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) public constant returns (uint256 balance);
}
contract MultiSigWallet is RLPEncode{
    event Deposit(address _sender, uint256 _value);
    event Transacted(address _to, address _tokenContractAddress,uint256 value);
    event SafeModeActivated(address _sender);
    //
    event modlog(bytes _res);
    //

    mapping (address => bool) public isSigner;
    uint256[] transactionTimeList;
    mapping (uint256 => bool) public isTransactionTimeExist;

    address public owner;
    bool public safeMode; // When active, wallet may only send to signer addresses

    uint8 private required;
    uint256 private transactionId;
    uint256 private transactionValue;

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    constructor(address[] _signers, uint8 _required) public{
        require(_required <= _signers.length &&  _required > 0 && _signers.length > 0);
        for (uint8 i=0; i<_signers.length; i++)
            isSigner[_signers[i]] = true;
        required = _required;
        transactionId=0;
        owner = msg.sender;
        safeMode =false;
    }

    function()
        payable public{
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address _destination, string  _value,  string _strTransactionTime,uint8[] _v, bytes32[] _r,bytes32[] _s) onlyOwner public{
        clearTimeMap();
        processAndCheckParam(_strTransactionTime,_destination,_v,_r,_s);

        bytes32 _msgHash = getMsgHash(_destination,_value,_strTransactionTime);
        
        verifySignatures(_msgHash, _v, _r,_s);
        _destination.transfer(transactionValue);
        emit Transacted(_destination,0,transactionValue);

    }

    function submitTransactionToken(address _destination,address _tokenContractAddress,string  _value, string _strTransactionTime,uint8[] _v, bytes32[] _r,bytes32[] _s) onlyOwner public{
        clearTimeMap();
        processAndCheckParam(_strTransactionTime,_destination,_v,_r,_s);

        bytes32 _msgHash = getMsgHash(_destination,_value,_strTransactionTime);
        verifySignatures(_msgHash, _v, _r,_s);

        ERC20Interface instance = ERC20Interface(_tokenContractAddress);
        require(instance.transfer(_destination,transactionValue));

        emit Transacted(_destination,_tokenContractAddress,transactionValue);
      }


    function activateSafeMode() onlyOwner public {
      safeMode = true;
      emit SafeModeActivated(msg.sender);
    }

    function clearTimeMap()  internal {
      for(uint256 i =0;i<transactionTimeList.length;i++)
      {
        if(transactionTimeList[i]<(now-864000))
        {
          delete(transactionTimeList[i]);
          delete(isTransactionTimeExist[transactionTimeList[i]]);
        }
      }
    }

    function getMsgHash(address _destination,string _value,string _expireTime) public  returns (bytes32){
      bytes[] memory rawTx = new bytes[](9);
      bytes[] memory bytesArray = new bytes[](9);

      string memory nonce = "09";
      string memory gasPrice = "09502f9000";
      string memory gasLimit = "5208";

      rawTx[0] = RLPEncode.strToBytes(nonce);
      rawTx[1] = RLPEncode.strToBytes(gasPrice);
      rawTx[2] = RLPEncode.strToBytes(gasLimit);
      rawTx[3] = RLPEncode.addressToBytes(_destination);
      rawTx[4] = RLPEncode.strToBytes(_value);
      rawTx[5] = RLPEncode.strToBytes(_expireTime);
      rawTx[6] = hex"03"; //03=testnet,01=mainnet

      transactionValue = RLPEncode.bytesToUint(rawTx[4]);
    
      for(uint i=0;i<9;i++)
       {
         bytesArray[i] = RLPEncode.encodeBytes(rawTx[i]);
       }
       bytes memory bytesList = RLPEncode.encodeList(bytesArray);
       modlog(bytesList);
       return (keccak256(bytesList));
    }

    function processAndCheckParam(string _strTransactionTime,address _destination,uint8[] _v, bytes32[] _r,bytes32[] _s) view private{

      uint256 _transactionTime = RLPEncode.bytesToUint(RLPEncode.strToBytes(_strTransactionTime));
      require(_transactionTime>=(now-864000) &&!isTransactionTimeExist[_transactionTime]);//isTransactionTimeExist是为了减少遍历动态数组

      transactionTimeList[transactionId] = _transactionTime;
      transactionId +=1;
      isTransactionTimeExist[_transactionTime] =true;

      require(_destination != 0 && _destination!=address(this) && _v.length ==_r.length &&_v.length == _s.length && _v.length >0);
      if(safeMode && !isSigner[_destination]) {
          revert();
        }
    }

    function verifySignatures(bytes32 _msgHash, uint8[] _v, bytes32[] _r,bytes32[] _s) view private{
        uint8 hasConfirmed=0;
        for (uint8 i=0; i<_v.length; i++){
             require(isSigner[ecrecover(_msgHash, _v[i], _r[i], _s[i])]);
             hasConfirmed++;
        }
        require(hasConfirmed >= required);
    }

}