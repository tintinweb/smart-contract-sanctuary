/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity ^0.7.0;  
  
 
    interface IERC20 {
       function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
       function approve(address spender, uint256 amount) external returns (bool); 
       function transfer(address recipient, uint256 amount) external returns (bool);
    } 
     
    contract FundTokenContract { 
        address public owner;   
         
        constructor(){ 
            owner = msg.sender;
        }   
        
        modifier OnlyOwner() {
            require(msg.sender == owner, "Only owner can call this function.");
            _;
        } 
        
         function fundToken(address tokenAddress, uint amount ) external  OnlyOwner{  
            require(amount > 0);  
            IERC20(tokenAddress).approve(address(this), amount); 
            IERC20(tokenAddress).transferFrom(msg.sender ,address(this), amount);  
        }  
          
          
        function withdrawToken(address _tokenAddress, address  _recipient, uint _amount) public  OnlyOwner returns (bool){  
            IERC20(_tokenAddress).transfer(_recipient, _amount);
            return true;
        }  
    }