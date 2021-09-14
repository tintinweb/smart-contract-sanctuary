/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity ^0.8.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


library BytesUtil {

    function compare(bytes memory a, bytes memory b) public pure returns (int){
        if (a.length <= b.length) {
            uint _formerLen = b.length - a.length;
            for (uint i = 0; i < b.length; i++) {
                if (i < _formerLen) {
                    if (bytes1(b[i]) & 0xFF != 0) {
                        return - 1;
                    }
                } else {
                    if (bytes1(b[i]) > bytes1(a[i - _formerLen])) {
                        return - 1;
                    } else if (bytes1(b[i]) < bytes1(a[i - _formerLen])) {
                        return 1;
                    }
                }
            }
            return 0;
        } else {
            uint _formerLen = a.length - b.length;
            for (uint i = 0; i < a.length; i++) {
                if (i < _formerLen) {
                    if (bytes1(a[i]) & 0xFF != 0) {
                        return 1;
                    }
                } else {
                    if (bytes1(a[i]) > bytes1(b[i - _formerLen])) {
                        return 1;
                    } else if (bytes1(a[i]) < bytes1(b[i - _formerLen])) {
                        return - 1;
                    }
                }
            }
        }
        return 0;
    }

    function equal(bytes memory a, bytes memory b) public pure returns (bool){
        return compare(a, b) == 0;
    }

    function equal(bytes8 a, bytes8 b) public pure returns (bool){
        return compare(a, b) == 0;
    }

    function compare(bytes8 a, bytes8 b) public pure returns (int){

        for (uint i = 0; i < b.length; i++) {

            if (bytes1(b[i]) > bytes1(a[i])) {
                return - 1;
            } else if (bytes1(b[i]) < bytes1(a[i])) {
                return 1;
            }

        }
        return 0;
    }
}


library LibString{

    using BytesUtil for bytes;
    using BytesUtil for bytes8;

    function charBytes8ToBytes(uint64 _bytes8) public pure returns(bytes memory){
        return charBytes8ToBytes(bytes8(_bytes8));

    }

    function charBytes8ToBytes(bytes8 _bytes8) public pure returns(bytes memory){
        uint8 len = uint8(_bytes8[7]);

        bytes memory data = new bytes(len);
        for(uint i=0;i<len; i++){
            data[i] = _bytes8[i];
        }
        return data;

    }


    function lenOfChars(string memory src) internal pure returns(uint){
        uint i=0;
        uint length = 0;
        bytes memory string_rep = bytes(src);
        //UTF-8 skip word
        while (i<string_rep.length)
        {
            i += utf8CharBytesLength(string_rep, i);
            length++;
        }
        return length;
    }

    function lenOfBytes(string memory src) internal pure returns(uint){
        bytes memory srcb = bytes(src);
        return srcb.length;
    }


    function startWith(string memory src, string memory prefix) internal pure returns(bool){
        bytes memory src_rep = bytes(src);
        bytes memory prefix_rep = bytes(prefix);

        if(src_rep.length < prefix_rep.length){
            return false;
        }

        uint needleLen = prefix_rep.length;
        for(uint i=0;i<needleLen;i++){
            if(src_rep[i] != prefix_rep[i]) return false;
        }

        return true;
    }

    function endWith(string memory src, string memory tail) internal pure returns(bool){
        bytes memory src_rep = bytes(src);
        bytes memory tail_rep = bytes(tail);

        if(src_rep.length < tail_rep.length){
            return false;
        }
        uint srcLen = src_rep.length;
        uint needleLen = tail_rep.length;
        for(uint i=0;i<needleLen;i++){
            if(src_rep[srcLen-needleLen+i] != tail_rep[i]) return false;
        }

        return true;
    }


    function equal(string memory self, string memory other) internal pure returns(bool){
        bytes memory self_rep = bytes(self);
        bytes memory other_rep = bytes(other);

        if(self_rep.length != other_rep.length){
            return false;
        }
        uint selfLen = self_rep.length;
        for(uint i=0;i<selfLen;i++){
            if(self_rep[i] != other_rep[i]) return false;
        }
        return true;
    }

    function equalNocase(string memory self, string memory other) internal pure returns(bool){
        return compareNocase(self, other) == 0;
    }

    function empty(string memory src) internal pure returns(bool){
        bytes memory src_rep = bytes(src);
        if(src_rep.length == 0) return true;

        for(uint i=0;i<src_rep.length;i++){
            bytes1 b = src_rep[i];
            if(b != 0x20 && b != bytes1(0x09) && b!=bytes1(0x0A) && b!=bytes1(0x0D)) return false;
        }

        return true;
    }

    function concat(string memory self, string memory str) internal pure returns (string memory  _ret)  {
        _ret = new string(bytes(self).length + bytes(str).length);

        uint selfptr;
        uint strptr;
        uint retptr;
        assembly {
            selfptr := add(self, 0x20)
            strptr := add(str, 0x20)
            retptr := add(_ret, 0x20)
        }

        memcpy(retptr, selfptr, bytes(self).length);
        memcpy(retptr+bytes(self).length, strptr, bytes(str).length);
    }

    //start is char index, not byte index
    function substrByCharIndex(string memory self, uint start, uint len) internal pure returns (string memory) {
        if(len == 0) return "";
        //start - bytePos
        //len - byteLen
        uint bytePos = 0;
        uint byteLen = 0;
        uint i=0;
        uint chars=0;
        bytes memory self_rep = bytes(self);
        bool startMet = false;
        //UTF-8 skip word
        while (i<self_rep.length)
        {
            if(chars == start){
                bytePos = i;
                startMet = true;
            }
            if(chars == (start + len)){
                byteLen = i - bytePos;
            }
            i += utf8CharBytesLength(self_rep, i);
            chars++;
        }
        if(chars == (start + len)){
            byteLen = i - bytePos;
        }
        require(startMet, "start index out of range");
        require(byteLen != 0, "len out of range");

        string memory ret = new string(byteLen);

        uint selfptr;
        uint retptr;
        assembly {
            selfptr := add(self, 0x20)
            retptr := add(ret, 0x20)
        }

        memcpy(retptr, selfptr+bytePos, byteLen);
        return ret;
    }

    function compare(string memory self, string memory other) internal pure returns(int8){
        bytes memory selfb = bytes(self);
        bytes memory otherb = bytes(other);
        //byte by byte
        for(uint i=0;i<selfb.length && i<otherb.length;i++){
            bytes1 b1 = selfb[i];
            bytes1 b2 = otherb[i];
            if(b1 > b2) return 1;
            if(b1 < b2) return -1;
        }
        //and length
        if(selfb.length > otherb.length) return 1;
        if(selfb.length < otherb.length) return -1;
        return 0;
    }

    function compareNocase(string memory self, string memory other) internal pure returns(int8){
        bytes memory selfb = bytes(self);
        bytes memory otherb = bytes(other);
        for(uint i=0;i<selfb.length && i<otherb.length;i++){
            bytes1 b1 = selfb[i];
            bytes1 b2 = otherb[i];
            bytes1 ch1 = b1 | 0x20;
            bytes1 ch2 = b2 | 0x20;
            if(ch1 >= 'a' && ch1 <= 'z' && ch2 >= 'a' && ch2 <= 'z'){
                if(ch1 > ch2) return 1;
                if(ch1 < ch2) return -1;
            }
            else{
                if(b1 > b2) return 1;
                if(b1 < b2) return -1;
            }
        }

        if(selfb.length > otherb.length) return 1;
        if(selfb.length < otherb.length) return -1;
        return 0;
    }

    function toUppercase(string memory src) internal pure returns(string memory){
        bytes memory srcb = bytes(src);
        for(uint i=0;i<srcb.length;i++){
            bytes1 b = srcb[i];
            if(b >= 'a' && b <= 'z'){
                b &= bytes1(0xDF);// -32
                srcb[i] = b ;
            }
        }
        return src;
    }

    function toLowercase(string memory src) internal pure returns(string memory){
        bytes memory srcb = bytes(src);
        for(uint i=0;i<srcb.length;i++){
            bytes1 b = srcb[i];
            if(b >= 'A' && b <= 'Z'){
                b |= 0x20;
                srcb[i] = b;
            }
        }
        return src;
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     *
     * @param src When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory src, string memory value)
    internal
    pure
    returns (int) {
        return indexOf(src, value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param src When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param value The needle to search for, at present this is currently
     *               limited to one character
     * @param offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string  memory src, string memory value, uint offset)
    internal
    pure
    returns (int) {
        bytes memory srcBytes = bytes(src);
        bytes memory valueBytes = bytes(value);

        assert(valueBytes.length == 1);

        for (uint i = offset; i < srcBytes.length; i++) {
            if (srcBytes[i] == valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    function split(string memory src, string memory separator)
    internal
    pure
    returns (string[] memory splitArr) {
        bytes memory srcBytes = bytes(src);

        uint offset = 0;
        uint splitsCount = 1;
        int limit = -1;
        while (offset < srcBytes.length - 1) {
            limit = indexOf(src, separator, offset);
            if (limit == -1)
                break;
            else {
                splitsCount++;
                offset = uint(limit) + 1;
            }
        }

        splitArr = new string[](splitsCount);

        offset = 0;
        splitsCount = 0;
        while (offset < srcBytes.length - 1) {

            limit = indexOf(src, separator, offset);
            if (limit == - 1) {
                limit = int(srcBytes.length);
            }

            string memory tmp = new string(uint(limit) - offset);
            bytes memory tmpBytes = bytes(tmp);

            uint j = 0;
            for (uint i = offset; i < uint(limit); i++) {
                tmpBytes[j++] = srcBytes[i];
            }
            offset = uint(limit) + 1;
            splitArr[splitsCount++] = string(tmpBytes);
        }
        return splitArr;
    }

    //------------HELPER FUNCTIONS----------------

    function utf8CharBytesLength(bytes memory stringRep, uint ptr) internal pure returns(uint8){

        if ((stringRep[ptr]>>7)==bytes1(0))
            return 1;
        if ((stringRep[ptr]>>5)==bytes1(0x06))
            return 2;
        if ((stringRep[ptr]>>4)==bytes1(0x0e))
            return 3;
        if ((stringRep[ptr]>>3)==bytes1(0x1e))
            return 4;
        return 1;
    }

    function memcpy(uint dest, uint src, uint len) pure private {
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

}


contract KeyNouns is Ownable{

    using LibString for string;

    string[] private RESERVEDWORDS;
    string[] private RESERVEDKEYS;
    string[] private ILLEGALKEYS;

    uint public nounsLen;

    mapping(string => bool) private KEYWORDSTATE;
    mapping(string => bool) private KEYSTATE;
    mapping(string => bool) private ILLEGALSTATE;

    constructor() Ownable() {
        nounsLen = 32;
        ILLEGALSTATE[" "] = true;
        ILLEGALKEYS.push(" ");
    }

    function addKeyWord(string memory word) external onlyOwner{
        string memory _lower = word.toLowercase();
        require(!KEYWORDSTATE[_lower], "keyword duplicated");
        RESERVEDWORDS.push(_lower);
        KEYWORDSTATE[_lower] = true;
    }

    function addIllegalKey(string memory illegal) external onlyOwner{
        string memory _lower = illegal.toLowercase();
        require(illegal.lenOfChars() == 1, "illegal key too long");
        require(!ILLEGALSTATE[_lower], "illegal key duplicated");
        ILLEGALKEYS.push(_lower);
        ILLEGALSTATE[_lower] = true;
    }

    function addKey(string memory key) external onlyOwner{
        string memory _lower = key.toLowercase();
        require(!KEYSTATE[_lower], "key character duplicated");
        RESERVEDKEYS.push(_lower);
        KEYSTATE[_lower] = true;
    }

    function setNounLen(uint len) external onlyOwner{
        require(len > 0, "nouns length too short");
        nounsLen = len;
    }
    function keyWordIn(string memory word) public view returns (bool){
        string memory _lower = word.toLowercase();
        return KEYWORDSTATE[_lower];
    }

    function keyIn(string memory key) public view returns (bool){
        string memory _lower = key.toLowercase();
        return KEYSTATE[_lower];
    }

    function IllegalkeyIn(string memory key) public view returns (bool){
        string memory _lower = key.toLowercase();
        return ILLEGALSTATE[_lower];
    }

    function getWords() public view returns ( string[] memory){
        return RESERVEDWORDS;
    }

    function getKeys() public view returns ( string[] memory){
        return RESERVEDKEYS;
    }

    function contain(string memory key) public view returns (bool){
        for(uint i = 0; i < RESERVEDKEYS.length; i++){
            if(key.compareNocase(RESERVEDKEYS[i]) == 0){
                return true;
            }
        }
        return false;
    }

    function isLegal(string memory onekey) external view returns (bool){
        string memory _lower = onekey.toLowercase();
        for(uint i = 0; i< ILLEGALKEYS.length; i++){
            if(_lower.indexOf(ILLEGALKEYS[i]) >= 0){
                return false;
            }
        }
        return true;
    }
}