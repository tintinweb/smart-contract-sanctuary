pragma solidity ^0.4.24;

 // ----------------------------------------------------------------------------
 // Owned contract
 // ----------------------------------------------------------------------------
 contract Owned {
     address public owner;
     address public newOwner;
 
     event OwnershipTransferred(address indexed _from, address indexed _to);
 
     constructor() public {
         owner = msg.sender;
     }
 
     modifier onlyOwner {
         require(msg.sender == owner);
         _;
     }
 
     function transferOwnership(address _newOwner) public onlyOwner {
         newOwner = _newOwner;
     }
     function acceptOwnership() public {
         require(msg.sender == newOwner);
         emit OwnershipTransferred(owner, newOwner);
         owner = newOwner;
         newOwner = address(0);
     }
 }
 
contract WifiStore is Owned{
    
    mapping(string => string) wifiMap;
    
    function addWifi(string wifi,string pwd) public onlyOwner{
        wifiMap[wifi] = pwd;
    }
    
    function getWifiPwd(string wifi) public view onlyOwner returns (string pwd)  {
        return wifiMap[wifi];
    }
    
}