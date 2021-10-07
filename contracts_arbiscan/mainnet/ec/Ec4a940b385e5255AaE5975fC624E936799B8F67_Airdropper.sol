/**
 *Submitted for verification at arbiscan.io on 2021-09-21
*/

pragma solidity 0.4.26;
 
contract Ownable {
  address public owner=0x0b07aF2FdC80b9f87c37E83cDB1d6dE7Dffc5F3F;
 
  function setOwner(address newOwner) onlyOwner public {
    owner = newOwner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

interface Token {
  function balanceOf(address _owner) external returns (uint256 );
  function transfer(address _to, uint256 _value) external;
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract Airdropper is Ownable {
    
    Token public token;
    uint public unitPer = 1200000000000000000000;
    
    constructor(address _tokenAddress) public {
        token = Token(_tokenAddress);
    }
    
    function setToken(address _tokenAddress) onlyOwner public {
        token = Token(_tokenAddress);
    }
    
    function setUnitPer(uint newUnitPer) onlyOwner public returns (uint) {
        unitPer = newUnitPer;
        return unitPer;
    }
    
    function AirTransfer(address[] _recipients) onlyOwner public returns (bool) {
        require(_recipients.length > 0);
        
        for(uint j = 0; j < _recipients.length; j++){
            token.transfer(_recipients[j], unitPer);
        }
 
        return true;
    }
 
    function withdrawalToken() onlyOwner public { 
        token.transfer(owner, token.balanceOf(address(this)));
    }

}