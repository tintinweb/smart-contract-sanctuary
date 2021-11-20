/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.4.18;

contract VideoProvider {
    
    string Name;
    uint Age;
    bool AgeRestriction;
    
    function SetUserInfo(string _Name, uint _Age) public {
        Name = _Name;
        Age = _Age;
        if (Age >=18) {AgeRestriction = false;
        }
        else AgeRestriction = true;
    }
    
    function GetUserInfo() public view returns (string, uint, bool) {
return (Name, Age, AgeRestriction);
    }
    
    
    
}