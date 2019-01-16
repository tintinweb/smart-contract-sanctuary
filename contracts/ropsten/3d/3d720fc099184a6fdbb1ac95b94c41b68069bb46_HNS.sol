pragma solidity ^0.4.25;


library strings {
    struct slice{
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure{
        // Copy word-length chunks while possible
        for(;len >= 32;len -= 32){
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

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory){
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l){
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0;ptr < end;l++){
            uint8 b;
            assembly { 
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }
    
    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool){
        if (self._len < needle._len) {
            return false;
        }
        uint selfptr = self._ptr + self._len - needle._len;
        if (selfptr == needle._ptr) {
            return true;
        }
        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory){
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }
}

/***
 * HPB地址命名服务
 *  */
contract HNS {
    
    //使用strings的工具库
    using strings for *;
    
    string public name = "HPB Name Service";
    
    //用于未来HNS合约分离扩展
    address public preAddr = 0;
    //用于未来HNS合约分离扩展
    address public nextAddr = 0;
    
    //HPB地址命名=>hpb的账户地址
    mapping (bytes32 => address) public hnsMap;
    
    // HPB首席管理员(可以基金会掌握)
    address public owner;

    /**
     * 只有HPB首席管理员可以调用
     * Only the HPB foundation account (administrator) can call.
     */
    modifier onlyOwner{
        require(msg.sender == owner);
        // Do not forget the "_;"! It will be replaced by the actual function
        // body when the modifier is used.
        _;
    }

    // 记录发送HPB的发送者地址和发送的金额
    // Record the sender address and the amount sent to send HPB.
    event ReceivedHpb(address indexed sender, uint amount);

    // 接受HPB转账，为了未来扩展用途
    // Accept HPB transfer
    function () payable  external{
        emit ReceivedHpb (msg.sender, msg.value);
    }
   
    constructor() payable public{
        owner = msg.sender;
    }
    
    event TransferOwnership(address indexed from,address indexed to);
    
    function transferOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
        emit TransferOwnership(msg.sender,newOwner);
    }
    
    event SetPreAddr(address indexed _preAddr);
    function setPreAddr(address _preAddr) onlyOwner public{
        preAddr = _preAddr;
        emit SetPreAddr(_preAddr);
    }
    event SetNextAddr(address indexed _nextAddr);
    function setNextAddr(address _nextAddr) onlyOwner public{
        nextAddr = _nextAddr;
        emit SetNextAddr(_nextAddr);
    }
	/*
     * 判断是否以.hpb作为后缀的名称
     */
    function isEndsWithHpb(string _name)  public pure returns(bool _check){
        strings.slice memory s = _name.toSlice();
        return s.endsWith(".hpb".toSlice());
    }
    
	/*
     * 判断hpb地址命名是否满足长度，包括.hpb后缀名一起校验长度，
     * 如果不包括后缀名称，那么长度在3到32位
     */
    function isValidLenth(string _name) public pure returns(bool _check){
        strings.slice memory s = _name.toSlice();
        return s.len()>6&&s.len()<35;
    }

    /**
     * string类型转换成bytes32类型
     */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result){
      assembly {
        result := mload(add(source, 32))
      }
    }
    /**
     * bytes32类型转换成string类型
     */
    function bytes32ToString(bytes32 x) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    event RegistMyHns(string indexed _name,address indexed _addr);
    /**
     * 注册个人的HPB账户地址名称
     */
	function registMyHns(string _name,address _addr) public{
	    //必须是本人才能注册
	    require(msg.sender == _addr);
        string memory  newName;
        
        if(!isEndsWithHpb(_name)){
            newName=_name.toSlice().concat(".hpb".toSlice());
        } else {
            newName=_name;
        }
        //必须是满足长度要求
        require(isValidLenth(newName));
        //必须是名称没有被使用
        require(getAddressByName(newName)==0);
        
        hnsMap[stringToBytes32(newName)]=_addr;
        emit RegistMyHns(newName,_addr);
    }
    event UpdateMyHns(string indexed _name,address indexed _addr);
    /**
     * 更新个人的HPB账户地址名称
     */
	function updateMyHns(string _name,address _addr) public{
	    //必须是本人才能注册
	    require(msg.sender == _addr);
        string memory  newName;
        
        if(!isEndsWithHpb(_name)){
            newName=_name.toSlice().concat(".hpb".toSlice());
        } else {
            newName=_name;
        }
        //必须是满足长度要求
        require(isValidLenth(newName));
        address hnsAddr=getAddressByName(newName);
        if(hnsAddr!=0){
            //必须是本人才允许更新自己的HPB账户名称对应的地址
	    	require(msg.sender ==hnsAddr);
        }
        hnsMap[stringToBytes32(newName)]=_addr;
        emit UpdateMyHns(newName,_addr);
    }
    event RegistHns(string indexed _name,address indexed _addr);
    
    /**
     * 通过HPB基金会来注册HPB账户地址名称
     */
    function registHns(string _name,address _addr) onlyOwner public{
        string memory  newName;
        if(!isEndsWithHpb(_name)){
            newName=_name.toSlice().concat(".hpb".toSlice());
        } else {
            newName=_name;
        }
        //必须是满足长度要求
        require(isValidLenth(newName));
        //必须是名称没有被使用
        require(getAddressByName(newName)==0);
        
        hnsMap[stringToBytes32(newName)]=_addr;
        emit RegistHns(newName,_addr);
    }
    /**
     * 通过HPB基金会来批量注册HPB账户地址名称
     */
    function  registHnsBatch (
    	bytes32[] _names,
    	address[] _addrs
    ) onlyOwner public {
         for(uint i=0;i<_addrs.length;i++){
            registHns(bytes32ToString(_names[i]),_addrs[i]);
        }
    }
    /**
     * 根据HPB账户名称获取对应的账户地址
     */
    function getAddressByName(
        string _name
    )  public constant returns (
        address addr
    ){
        return hnsMap[stringToBytes32(_name)];
    }
    /**
     * 批量获取名称对应的账户地址
     */
    function getAddressByNames(
        bytes32[] _names
    )  public constant returns (
        address[] addrs
    ){
        address[] memory _addrs=new address[](_names.length);
        for (uint i = 0;i<=_names.length;i++){
            _addrs[i]=hnsMap[_names[i]];
        }
        return _addrs;
    }
}