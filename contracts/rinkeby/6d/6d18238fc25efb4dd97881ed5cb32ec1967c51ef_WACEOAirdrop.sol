// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Ownable.sol";

interface IERC20 { 
   function transfer(address recipient, uint256 amount) external returns (bool);  
} 

contract WACEOAirdrop is Ownable {
   
    struct Record { 
        address recipient;
        uint vestingTerm;  
        uint maxPayout;
        bool rewardPaid; 
        bool eligible; 
    } 

    address public token; 
    mapping (address => Record) private addressRecord; 
    
    
    constructor(address _token ) Ownable() {
        token = _token; 
    }  
    
    function status(address  _address) public view returns(Record memory) { 
        return (addressRecord[_address]);
    }  
 
    function claim() public { 
       require(addressRecord[msg.sender].eligible, "Address is not eligible");
       require(addressRecord[msg.sender].rewardPaid == false, "Reward already proceeded");
       require(block.timestamp > addressRecord[msg.sender].vestingTerm, "Reward not available yet");
       IERC20(token).transfer(msg.sender, addressRecord[msg.sender].maxPayout);
       addressRecord[msg.sender].rewardPaid = true;
    }  
 
    function setToken(address  _token) public onlyOwner { 
        token = _token; 
    }   

    function setAccounts(Record[] memory _records) public onlyOwner { 
        for(uint i=0; i< _records.length; i++){
           addressRecord[_records[i].recipient] = Record(_records[i].recipient, _records[i].vestingTerm, _records[i].maxPayout, false, true ); 
        } 
    }

    function setAccount(address _address, uint _vestingTerm, uint _maxPayout) public onlyOwner { 
         addressRecord[_address] = Record(_address, _vestingTerm, _maxPayout, false, true ); 
    }
    
    function transfer(uint _amount) public  onlyOwner returns (bool){  
        IERC20(token).transfer(msg.sender, _amount);
        return true;
    }  
       
}