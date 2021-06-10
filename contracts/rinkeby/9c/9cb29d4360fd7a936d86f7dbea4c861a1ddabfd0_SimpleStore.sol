/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

contract SimpleStore {
    uint256[] value;
    address dev;
    address public creator;
    
     constructor() public {
        dev = msg.sender;
        creator = tx.origin;
    }
    
  function setUint(uint256[] memory _values) public {
    value = _values;
  }

  function getUint() public view returns (uint256[] memory) {
    return value;
  }

    address[] tokens;
    
  function setTokens(address[] memory _tokens) public {
    tokens = _tokens;
  }

  function getTokens() public view returns (address[] memory) {
    return tokens;
  }
  

    string[] infos;
    
  function setStrings(string[] memory _infos) public {
    infos = _infos;
  }

  function getStrings() public view returns (string[] memory) {
    return infos;
  }
}