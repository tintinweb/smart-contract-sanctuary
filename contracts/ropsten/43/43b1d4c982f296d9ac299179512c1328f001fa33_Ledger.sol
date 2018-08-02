pragma solidity ^0.4.24;

contract Ledger {
    mapping (string => string) kvs;
    mapping (string => uint) mod_date;
    address owner;
    event Update(string key, string value);
    constructor () public {
        owner = msg.sender;
    }
    function set(string key, string value) public {
        require(msg.sender == owner);
        kvs[key] = value;
        mod_date[key] = block.timestamp;
        emit Update(key, value);
    }
    function get(string key) public view returns (string, uint){
        return (kvs[key], mod_date[key]);
    }
}