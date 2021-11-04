/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

///SPDX-License-Identifier: SPDX-License

pragma solidity 0.7.4;


contract RulesOfContract {
    
    address public owner; // creat the owner
    
    constructor(){
        owner = msg.sender; // set the "owner"
    }
    
    
    modifier onlyOwner(){
        require(owner == msg.sender, "ERROR: You no owner."); // only the "owner" can add the "date" and  "temperature"
        _;
    }
    
}



contract Temperatures is RulesOfContract {
     
    mapping (uint256 => string) public tempDisplay; // create a place for saving "date" and "temperature"
    
}


contract TempDisplay is Temperatures {
    
    function addDateAndTemp( uint256 _date, string memory _temp) public onlyOwner{
       tempDisplay[_date] = _temp; // Association for a key in an associative array
    }
    
    
    
}