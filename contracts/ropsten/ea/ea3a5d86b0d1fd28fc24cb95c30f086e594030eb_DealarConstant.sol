pragma solidity ^0.4.0;
library Strings {
    function concat(string _base, string _value) internal pure returns (string) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);
        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);
        uint i;
        uint j;
        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }
        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i++];
        }
        return string(_newValue);
    }
}
contract StateConstant {
    string constant A = "Perak";
    string constant B = "Selangor";
    string constant C = "Pahang";
    string constant D = "Kelantan";
    string constant F = "Putrajaya";
    string constant J = "Johor";
    string constant K = "Kedah";
    string constant M = "Malacca";
    string constant N = "Negeri Sembilan";
    string constant P = "Penang";
    string constant R = "Perlis";
    string constant T = "Terengganu";
    string constant W = "Kuala Lumpur";
}
contract DealarConstant is StateConstant {
    using Strings for string;
    string dealerID;
    constructor() public {
        dealerID = A.concat("0001");
    }
}