// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract BatchSendERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public owner;
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    constructor(){
        owner = msg.sender;
    }
   
    //getowner
    function getOwner() public view returns (address) {
        return owner;
    }
    
    //get token balance
    function getTokenBalance(IERC20 token) public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    //withdraw whole erc20 token balance
    function withdraw(IERC20 token) public onlyOwner{
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
    
    //batch send fixed token amount from sender, require approval of contract as spender
    function multiSendFixedToken(IERC20 token, address[] memory recipients, uint256 amount) public {
        
        address from = msg.sender;
        
        require(recipients.length > 0);
        require(amount > 0);
        require(recipients.length * amount <= token.allowance(from, address(this)));
        
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(from, recipients[i], amount);
        }
        
    }  
    
    //batch send different token amount from sender, require approval of contract as spender
    function multiSendDiffToken(IERC20 token, address[] memory recipients, uint256[] memory amounts) public {
        
        require(recipients.length > 0);
        require(recipients.length == amounts.length);
        
        address from = msg.sender;
        
        uint256 allowance = token.allowance(from, address(this));
        uint256 currentSum = 0;
        
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amount = amounts[i];
            
            require(amount > 0);
            currentSum = currentSum.add(amount);
            require(currentSum <= allowance);
            
            token.safeTransferFrom(from, recipients[i], amount);
        }
        
    }   
     
    
    //batch send fixed token amount from contract
    function multiSendFixedTokenFromContract(IERC20 token, address[] memory recipients, uint256 amount) public onlyOwner {
        require(recipients.length > 0);
        require(amount > 0);
        require(recipients.length * amount <= token.balanceOf(address(this)));
        
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransfer(recipients[i], amount);
        }
    }
    
    //batch send different token amount from contract
    function multiSendDiffTokenFromContract(IERC20 token, address[] memory recipients, uint256[] memory amounts) public onlyOwner {
        
        require(recipients.length > 0);
        require(recipients.length == amounts.length);
        
        uint256 length = recipients.length;
        uint256 currentSum = 0;
        uint256 currentTokenBalance = token.balanceOf(address(this));
        
        for (uint256 i = 0; i < length; i++) {
            uint256 amount = amounts[i];
            require(amount > 0);
            currentSum = currentSum.add(amount);
            require(currentSum <= currentTokenBalance);
            
            token.safeTransfer(recipients[i], amount);
        }
    }
    
}


//Developed by Meta Identity