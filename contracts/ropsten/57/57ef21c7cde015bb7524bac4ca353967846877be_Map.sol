pragma solidity ^0.4.18;

contract Map {
    
    mapping(string => string) map;
    
    event mylog(string msg, string key, string value);
    
    function getvalue(string key) public constant returns (string) {
        return map[key];
    }
    
    function setvalue(string key, string value) public {
        mylog(&quot;setvalue invoked&quot;, key, value);
        map[key] = value;
    }
}