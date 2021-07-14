// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract Multisend {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public owner;
    IERC20 token;
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    constructor() public{
        owner = 0x67b8F8711487a1eba13DE9B9a77e0C1633619381;
        token = IERC20(0x3AD53Eb310bC6061baa62D900E6953601Dc90E5c);
    }
   
    //getowner
    function getOwner() public view returns (address) {
        return owner;
    }
    
    
    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    
    function getUserTokenBalance(address user) public view returns (uint256) {
        return token.balanceOf(user);
    }
    
    function getSenderTokenBalance() public view returns (uint256) {
        return token.balanceOf(msg.sender);
    }
    
    
    function getUser() public view returns (address) {
        return msg.sender;
    }
    //withdraw whole erc20 token balance
    function withdraw() public onlyOwner{
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
    
    
    
    //batch send different token amount from sender, require approval of contract as spender
    function multiSendDiffToken(address payable[] memory recipients, uint256[] memory amounts) public payable returns(bool) {
        
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
        return true;
        
    }   
     
    
    
    
    //batch send different token amount from contract
    function multiSendDiffTokenFromContract(address[] memory recipients, uint256[] memory amounts) public onlyOwner {
        
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