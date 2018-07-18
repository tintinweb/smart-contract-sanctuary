pragma solidity 0.4.24;

contract contentHolder {
  string internal prefix = &quot;&quot;;
  string internal suffix = &quot;&quot;;
  string internal content = &quot;&quot;;

  // Contract constructor that takes a string param
  function setContent(string _content) public {
    content = _content;
  }

  function setFixes(string _prefix, string _suffix) public {
    prefix = _prefix;
    suffix = _suffix;
  }

  function printContent() external view returns (string) {
    return strConcat(prefix, content, suffix);
  }

  function strConcat(string _a, string _b, string _c) internal pure returns (string){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    string memory abc = new string(_ba.length + _bb.length + _bc.length);
    bytes memory babc = bytes(abc);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babc[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babc[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babc[k++] = _bc[i];
    return string(babc);
  }
}