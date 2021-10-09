/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

contract certi {
    
  address admin;
  
  constructor() {
    admin = msg.sender;    
  }
  
  modifier onlyAdmin {
      require(msg.sender == admin, "Insufficient privilage");
      _;
  }
  
  struct certificate {
      string courseName;
      string candidateName;
      string grade;
      string date;
  }
  
  mapping (string => certificate) public certificateDetails;
  
  function newCertificate (
      string memory _certificateID,
      string memory _courseName,
      string memory _candidateName,
      string memory _grade,
      string memory _date ) public onlyAdmin {
          certificateDetails[_certificateID] = certificate(
                                                    _courseName,
                                                    _candidateName,
                                                    _grade,
                                                    _date);
      }
}