/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract PoCGenericEthV2 {
    
    address eAddress;
    
    uint8 year;

    Voter volterField;
    
    struct Voter { // Struct
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    function setYear(uint8 value) public {
      year = value;
    }

        
    function getYear() public view returns (uint8) {
      return year;
    }
    
    function getAddress() public view returns (address) {
      return eAddress;
    }
    
    function setAddress(address inputAddress) public {
       eAddress = inputAddress;
    }
    
    function setYearAndAddress(uint8 inputYear, address inputAddress) public {
      eAddress = inputAddress;
      year = inputYear;
    }

    function setVoterStruct(Voter memory inputVoter) public {
      volterField = inputVoter;
    }
    
 
}