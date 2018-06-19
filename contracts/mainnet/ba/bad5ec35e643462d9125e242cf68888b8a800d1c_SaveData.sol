pragma solidity ^0.4.21;
  
contract SaveData {
    mapping (uint => string) sign;
    address public owner;
    event SetString(uint key,string types);
    function SaveData() public {
        owner = msg.sender;
    }
    function setstring(uint key,string md5) public returns(string){
        sign[key]=md5;
        return sign[key];
    }

    function getString(uint key) public view returns(string){
        return sign[key];
    }
}