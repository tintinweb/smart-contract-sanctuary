/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9; 

contract Distributor {
  // shares are calculated as basis points
  mapping (address => uint256) shares;
  address payable[] public beneficiaries; 
  address public owner;
  event Transfer(address indexed _to, uint256 _value);
  event Received(address indexed _from, uint256 _value);

  constructor(){
    owner = msg.sender;
    }

  modifier onlyOwner(){
    require(msg.sender == owner, "Ownable: caller is not the owner");
    _;
    } 

  function distribute() public{ 
    uint256 totalBalance = address(this).balance;
    for (uint256 i = 0; i < beneficiaries.length; i++) {
      uint256 share = shares[beneficiaries[i]] * totalBalance  / 10000;
      beneficiaries[i].transfer(share);
      emit Transfer(beneficiaries[i], share); 
      }
    }

  receive() external payable {
    emit Received(msg.sender, msg.value);
    }

  function addBenificiary(address payable _newBeneficiary, uint256 basisPoints) public onlyOwner{ 
    shares[_newBeneficiary] = basisPoints; 
    }

  function removeBenificiary(address _oldBeneficiary) public onlyOwner{
    shares[_oldBeneficiary] = 0;
    }

  function renounceOwnership() public onlyOwner{ 
    owner = 0x0000000000000000000000000000000000000000;
    }
  }