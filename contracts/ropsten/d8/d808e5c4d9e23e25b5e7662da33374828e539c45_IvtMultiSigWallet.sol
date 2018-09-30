pragma solidity ^0.4.21;


library RLPEncode {
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

    function strToBytes(string data)internal pure returns (bytes){
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

    function bytesToUint(bytes b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function addressToBytes(address a) internal pure returns (bytes b){
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function stringToUint(string s) internal pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
           if (b[i] >= 48 && b[i] <= 57){
                result = result * 16 + (uint(b[i]) - 48); // bytes and int are not compatible with the operator -.
            }
            else if(b[i] >= 97 && b[i] <= 122)
            {
                result = result * 16 + (uint(b[i]) - 87);
            }
        }
        return result;
    }

    function subString(string str, uint startIndex, uint endIndex) internal pure returns (string) {
        bytes memory strBytes = bytes(str);
        if(strBytes.length !=48){revert();}
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function strConcat(string _a, string _b) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
            for (i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
                return string(bab);
        }

    function stringToAddr(string _input) internal pure returns (address){
        string memory _a = strConcat("0x",_input);
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
            return address(iaddr);
    }
}

contract IvtMultiSigWallet {
    
    event Deposit(address _sender, uint256 _value);
    event Transacted(address _to, address _tokenContractAddress, uint256 _value);
    event SafeModeActivated(address _sender);
    event Kill(address _safeAddress, uint256 _value);
    event Debuglog(address _address,bool _flag0,bool _flag1);

    mapping (address => bool) public signers;
    mapping (uint256 => bool) private transactions;
    mapping (address => bool) private signedAddresses;

    address private owner;
    bool private safeMode;

    uint8 private required;
    uint8 private safeModeConfirmed;
    address private safeAddress;

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    constructor(address[] _signers, uint8 _required) public{
        require(_required <= _signers.length && _required > 0 && _signers.length > 0);

        for (uint8 i = 0; i < _signers.length; i++){
            require(_signers[i] != address(0));
            signers[_signers[i]] = true;
        }
        required = _required;
        owner = msg.sender;
        safeMode = false;
        safeModeConfirmed = 0;
        safeAddress = 0;
    }

    function() payable public{
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address _destination, string _value, string _strTransactionData, uint8[] _v, bytes32[] _r, bytes32[] _s) onlyOwner public{
        processAndCheckParam(_destination, _strTransactionData, _v, _r, _s);

        uint256 transactionValue = RLPEncode.stringToUint(_value);
        bytes32 _msgHash = getMsgHash(_destination, _value, _strTransactionData);
        verifySignatures(_msgHash, _v, _r, _s);

        _destination.transfer(transactionValue);

        emit Transacted(_destination, 0, transactionValue);
    }

    function submitTransactionToken(address _destination, address _tokenContractAddress, string _value, string _strTransactionData, uint8[] _v, bytes32[] _r,bytes32[] _s) onlyOwner public{
        processAndCheckParam(_destination, _strTransactionData, _v, _r, _s);

        uint256 transactionValue = RLPEncode.stringToUint(_value);
        bytes32 _msgHash = getMsgHash(_destination, _value, _strTransactionData);
        verifySignatures(_msgHash, _v, _r, _s);

        ERC20Interface instance = ERC20Interface(_tokenContractAddress);
        require(instance.transfer(_destination, transactionValue));

        emit Transacted(_destination, _tokenContractAddress, transactionValue);
    }


    function confirmTransaction(address _safeAddress) public{
        require(safeMode && signers[msg.sender] && signers[_safeAddress]);
        if (safeAddress == 0){
            safeAddress = _safeAddress;
        }
        require(safeAddress == _safeAddress);
        safeModeConfirmed++;

        delete(signers[msg.sender]);

        if(safeModeConfirmed >= required){
            emit Kill(safeAddress, address(this).balance);
            selfdestruct(safeAddress);
        }
    }

    function activateSafeMode() onlyOwner public {
        safeMode = true;
        emit SafeModeActivated(msg.sender);
    }

    function getMsgHash(address _destination, string _value, string _strTransactionData) constant internal returns (bytes32){
        bytes[] memory rawTx = new bytes[](9);
        bytes[] memory bytesArray = new bytes[](9);

        rawTx[0] = hex"09";
        rawTx[1] = hex"09502f9000";
        rawTx[2] = hex"5208";
        rawTx[3] = RLPEncode.addressToBytes(_destination);
        rawTx[4] = RLPEncode.strToBytes(_value);
        rawTx[5] = RLPEncode.strToBytes(_strTransactionData);
        rawTx[6] = hex"01"; //03=testnet,01=mainnet

        for(uint8 i = 0; i < 9; i++){
            bytesArray[i] = RLPEncode.encodeBytes(rawTx[i]);
        }

        bytes memory bytesList = RLPEncode.encodeList(bytesArray);

        return keccak256(bytesList);
    }

    function processAndCheckParam(address _destination, string _strTransactionData, uint8[] _v, bytes32[] _r, bytes32[] _s)  internal{
        require(!safeMode && _destination != 0 && _destination != address(this) && _v.length == _r.length && _v.length == _s.length && _v.length > 0);

        string memory strTransactionTime = RLPEncode.subString(_strTransactionData, 40, 48);
        uint256 transactionTime = RLPEncode.stringToUint(strTransactionTime);
        require(!transactions[transactionTime]);

        string memory strTransactionAddress = RLPEncode.subString(_strTransactionData, 0, 40);
        address contractAddress = RLPEncode.stringToAddr(strTransactionAddress);
        require(contractAddress == address(this));

        transactions[transactionTime] = true;

    }

    function verifySignatures(bytes32 _msgHash, uint8[] _v, bytes32[] _r,bytes32[] _s)  internal{
        uint8 hasConfirmed = 0;
        address[] memory  tempAddresses = new address[](20);
        for (uint8 i = 0; i < _v.length; i++){
            tempAddresses[i] = ecrecover(_msgHash, _v[i], _r[i], _s[i]);
            require(signers[tempAddresses[i]]);
            require(!signedAddresses[tempAddresses[i]]);
            
            signedAddresses[tempAddresses[i]] = true;
            hasConfirmed++;
        }
        for (uint8 j = 0; j < 20; j++){
            delete signedAddresses[tempAddresses[j]];
        }
        require(hasConfirmed >= required);
    }
}


contract ERC20Interface {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function balanceOf(address _owner) public constant returns (uint256 balance);
}