/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface LastCA {
         function viewAddI(address add_, uint256 ix_) external view returns (uint256);
         function viewHODLers(address add_) external view returns (uint256);
         function viewHIndexs(uint256 _No) external view returns (address);
         function viewNoHODLers() external view returns (uint256);
         function viewTicketI(uint256 _No) external view returns (address);
         function viewNoofTickets() external view returns (uint256);
         function HowManyTickets(address add_) external view returns (uint256);
}

contract SimpleViewer is LastCA {
    address public keyaddress;
    
    function GetAddress(address add_) external {
          keyaddress = add_;  
    }
    
    function  viewAddI(address add_, uint256 ix_) external view override returns (uint256) {
        return LastCA(address(keyaddress)).viewAddI(add_, ix_);
    }

    function viewHODLers(address add_) external view override returns (uint256) {
        return LastCA(address(keyaddress)).viewHODLers(add_);
    }
 
    function viewHIndexs(uint256 _No) external view override returns (address) {
        return LastCA(address(keyaddress)).viewHIndexs(_No);
    }
    
    function viewNoHODLers() external view override returns (uint256) {
        return LastCA(address(keyaddress)).viewNoHODLers();
    }
    
    function viewTicketI(uint256 _No) external view override returns (address) {
        return LastCA(address(keyaddress)).viewTicketI(_No);
    }
    
    function viewNoofTickets() external view override returns (uint256) {
        return LastCA(address(keyaddress)).viewNoofTickets();
    }
    
    function HowManyTickets(address add_) external view override returns (uint256) {
           return LastCA(address(keyaddress)).HowManyTickets(add_);
    }
  
}