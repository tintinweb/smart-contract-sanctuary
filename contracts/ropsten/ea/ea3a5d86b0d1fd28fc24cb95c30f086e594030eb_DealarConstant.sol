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
    string constant A = &quot;Perak&quot;;
    string constant B = &quot;Selangor&quot;;
    string constant C = &quot;Pahang&quot;;
    string constant D = &quot;Kelantan&quot;;
    string constant F = &quot;Putrajaya&quot;;
    string constant J = &quot;Johor&quot;;
    string constant K = &quot;Kedah&quot;;
    string constant M = &quot;Malacca&quot;;
    string constant N = &quot;Negeri Sembilan&quot;;
    string constant P = &quot;Penang&quot;;
    string constant R = &quot;Perlis&quot;;
    string constant T = &quot;Terengganu&quot;;
    string constant W = &quot;Kuala Lumpur&quot;;
}
contract DealarConstant is StateConstant {
    using Strings for string;
    string dealerID;
    constructor() public {
        dealerID = A.concat(&quot;0001&quot;);
    }
}