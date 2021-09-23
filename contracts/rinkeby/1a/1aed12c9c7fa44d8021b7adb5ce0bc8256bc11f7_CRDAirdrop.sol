// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";

interface IERC20 { 
   function transfer(address recipient, uint256 amount) external returns (bool); 
   function balanceOf(address account) external view returns (uint256);
} 

contract CRDAirdrop is Ownable {
 
    struct Record { 
        bool eligible; 
    } 
    
    struct Account { 
        address account; 
    } 
     
    
    mapping (address => bool) private isAdmin;
    mapping (address  => Record) private addressRecord;
    
    address public tokenAddress;
    uint public rewardAmount;
    
    constructor(address _tokenAddress, uint _rewardAmount) Ownable() {
        tokenAddress = _tokenAddress;
        rewardAmount = _rewardAmount;
        isAdmin[_msgSender()] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender]);
        _;
    }
    
    function claimReward() public { 
        require (addressRecord[msg.sender].eligible == true);  
        IERC20(tokenAddress).transfer(msg.sender, rewardAmount); 
        addressRecord[msg.sender].eligible = false; 
    }

    function setEligibleAccounts(Account[] memory _records) public onlyAdmin { 
        for(uint i=0; i< _records.length; i++){
           addressRecord[_records[i].account] = Record( true ); 
        } 
    }
    
    function checkStatus(address  _address) public view returns(bool, uint) { 
        return (addressRecord[_address].eligible, rewardAmount);
    }
    
    function transferTokens(  uint _amount) public  onlyAdmin returns (bool){  
        IERC20(tokenAddress).transfer(msg.sender, _amount);
        return true;
    }  
       
}