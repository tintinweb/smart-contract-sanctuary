/**
 *Submitted for verification at polygonscan.com on 2021-10-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
 
contract Ownable {
  address public owner;
 
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

interface Token {
  function balanceOf(address _owner) external returns (uint256 );
  function transfer(address _to, uint256 _value) external ;
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract Airdrop is Ownable {
    
    function AirTransferDiffValue(address[] memory _recipients, uint[] memory _values, address _tokenAddress) onlyOwner public returns (bool) {
        require(_recipients.length > 0);
        require(_recipients.length == _values.length);

        Token token = Token(_tokenAddress);
        
        for(uint j = 0; j < _recipients.length; j++){
            token.transfer(_recipients[j], _values[j]);
        }
 
        return true;
    }
    
    function AirTransfer(address[] memory _recipients, uint256 _value, address _tokenAddress) onlyOwner public returns (bool) {
        require(_recipients.length > 0);
        Token token = Token(_tokenAddress);
        for(uint j = 0; j < _recipients.length; j++){
            token.transfer(_recipients[j], _value);
            
        }
        return true;
    }
 
    function withdrawalToken(address _tokenAddress) onlyOwner public { 
        Token token = Token(_tokenAddress);
        token.transfer(owner, token.balanceOf(address(this)));
    }

}