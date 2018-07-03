pragma solidity ^0.4.23;

contract AMA20180702 {
    
    address public owner;
    int public totalAuthentication = 0;
    
    mapping(string => string) byCode;
    mapping(string => string) byPhone;
    mapping(string => int) totalByPhone;
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function addAuthByCode(string amaCode, string phoneNumber) external onlyOwner returns(string) {
        require(compareStrings(byCode[amaCode], &quot;&quot;));
        byCode[amaCode] = phoneNumber;
        addAuthByPhone(amaCode, phoneNumber);
        return byCode[amaCode];
    }
    
    function getAuthByCode(string amaCode) external view returns(string) {
        return byCode[amaCode];
    }
    
    function addAuthByPhone(string amaCode, string phoneNumber) internal {
        if (compareStrings(byPhone[phoneNumber], &quot;&quot;)) {
            byPhone[phoneNumber] = amaCode;
            totalByPhone[phoneNumber] = 1;
        }
        else {
            byPhone[phoneNumber] = strConcat(byPhone[phoneNumber], &quot; | &quot;, amaCode);
            totalByPhone[phoneNumber] += 1;
        }
        totalAuthentication += 1;
    }
    
    function getAuthByPhone(string phoneNumber) external view returns(string, int) {
        return (byPhone[phoneNumber], totalByPhone[phoneNumber]);
    }
    
    function compareStrings(string a, string b) internal pure returns (bool){
        return keccak256(a) == keccak256(b);
    }
    
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
    
    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, &quot;&quot;);
    }
    
    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, &quot;&quot;, &quot;&quot;);
    }
    
    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, &quot;&quot;, &quot;&quot;, &quot;&quot;);
    }
}