// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MockUpdate {
    function batchUpdateCustomers(
        uint[] memory tokenIds_, 
        uint[] memory volumes_, 
        uint[] memory debitPluses_, 
        uint[] memory creditPluses_, 
        bool[] memory zeroProfits_) public returns (bool) 
    
    {
        require(tokenIds_[0] != 99, "Failed");
    }
}