// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract Multisend {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public owner;
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    constructor() public{
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
    
    //get token balance
    function getUserTokenBalance(IERC20 token, address user) public view returns (uint256) {
        return token.balanceOf(user);
    }
    
    //withdraw whole erc20 token balance
    function withdraw(IERC20 token) public onlyOwner{
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
    
    
    
    //batch send different token amount from sender, require approval of contract as spender
    function multiSendDiffToken(IERC20 token, address[] memory recipients, uint256[] memory amounts, uint256 total) public {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(total >= amounts[i] );
            total = total.sub(amounts[i]);
            token.safeTransfer(recipients[i],amounts[i]);
        }
        // uint256 allowance = token.allowance(from, address(this));
        // uint256 currentSum = 0;
        
        // for (uint256 i = 0; i < recipients.length; i++) {
        //     uint256 amount = amounts[i];
            
        //     require(amount > 0);
        //     currentSum = currentSum.add(amount);
        //     require(currentSum <= allowance);
            
        //     token.safeTransferFrom(from, recipients[i], amount);
        // }
        
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