// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";

interface IERC20 { 
   function transfer(address recipient, uint256 amount) external returns (bool); 
   function balanceOf(address account) external view returns (uint256);
} 

contract CRDNetworkAirdropV2 is Ownable {
   
    mapping (address => bool) private addressRecord; 
    address public tokenAddress;
    uint public rewardAmount;
    
    constructor(address _tokenAddress, uint _rewardAmount) Ownable() {
        tokenAddress = _tokenAddress;
        rewardAmount = _rewardAmount; 
    }  
    
    function claimReward() public { 
        require (addressRecord[msg.sender]  == true);  
        IERC20(tokenAddress).transfer(msg.sender, rewardAmount); 
        addressRecord[msg.sender] = false; 
    }
    
    function setReward(uint _rewardAmount) public onlyOwner { 
        rewardAmount = _rewardAmount; 
    }
    
    function setToken(address  _tokenAddress) public onlyOwner { 
        tokenAddress = _tokenAddress; 
    }

    function setAccounts(address[] memory _records) public onlyOwner { 
        for(uint i=0; i< _records.length; i++){
           addressRecord[_records[i]] = true;
        } 
    }
    
    function checkStatus(address  _address) public view returns(bool, uint) { 
        return (addressRecord[_address], rewardAmount);
    }
    
    function transferToken(  uint _amount) public  onlyOwner returns (bool){  
        IERC20(tokenAddress).transfer(msg.sender, _amount);
        return true;
    }  
       
}