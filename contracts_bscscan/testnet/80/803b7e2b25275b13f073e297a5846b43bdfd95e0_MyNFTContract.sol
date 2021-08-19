/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.7;


contract MyNFTContract {
    event Mint(address indexed _to, uint256 indexed _tokenId);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    uint256 tokenCounter = 1;
    mapping(uint256 => address) internal idToOwner;

    function mint(address _to, address _coinAddress, uint256 _value) public {
        MyCoinContract coinContract = MyCoinContract(_coinAddress);
        require(coinContract.balanceOf(_to)>_value, "Insuficient coins");
        require(coinContract.transfer(coinContract.owner.address, _value), "Transaction failed");
        uint256 _tokenId = tokenCounter;
        idToOwner[_tokenId] = _to;
        tokenCounter++;
        emit Mint(_to, _tokenId);
    }
    

    function transfer(address _to, uint256 _tokenId) public {
        require(msg.sender == idToOwner[_tokenId]);
        idToOwner[_tokenId] = _to;
        emit Transfer(msg.sender, _to, _tokenId);
    }
    
    

}


contract MyCoinContract {
  function totalSupply() view external returns (uint256 supply){}
  function balanceOf(address _owner) view external returns (uint256 balance){}
  function transfer(address _to, uint256 _value)  view external returns (bool success){}
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){}
  function approve(address _spender, uint256 _value) public returns (bool success){}
  function allowance(address _owner, address _spender) public returns (uint256 remaining){}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
  address public owner;
}