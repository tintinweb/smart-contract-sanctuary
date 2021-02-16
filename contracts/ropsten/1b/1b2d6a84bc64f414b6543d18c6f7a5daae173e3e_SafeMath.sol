/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.6.0;


library UserAddress {
  struct data {
     address userAddress;
     bool isValue;
   }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract SamoohProtocol {
    
    using SafeMath for uint256;
    
    using UserAddress for UserAddress.data;
    
    mapping(string => UserAddress.data) public usernameMap;
    
    mapping(address => string) public userProfileDataMap;
    

    function setUsernameAddress(string memory _username) public {
        
        require(!usernameMap[_username].isValue, "username already exists.");

        usernameMap[_username].userAddress = msg.sender;
        usernameMap[_username].isValue = true;
      
    }
    

    function setUsernameProfile(string memory _profile) public {
        
        userProfileDataMap[msg.sender] = _profile;
        
    }

    function sendTip(address payable _toAddress) public payable {
        
        uint256 _fee = msg.value.div(100);
        
        uint256 _amt = msg.value - _fee;
    
        _toAddress.transfer(_amt);
    }

    
}