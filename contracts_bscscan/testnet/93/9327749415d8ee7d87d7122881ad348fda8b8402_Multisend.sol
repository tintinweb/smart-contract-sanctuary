// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Multisend {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public owner;
    IERC20 erc20token;
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    constructor() public{
        owner = msg.sender;
        erc20token = IERC20(0x3AD53Eb310bC6061baa62D900E6953601Dc90E5c);
    }
   
    //getowner
    function getOwner() public view returns (address) {
        return owner;
    }
    
    //get token balance
    function getTokenBalance() public view returns (uint256) {
        return erc20token.balanceOf(address(this));
    }
    
    //withdraw whole erc20 token balance
    function withdraw() public onlyOwner{
        erc20token.safeTransfer(msg.sender, erc20token.balanceOf(address(this)));
    }
    
    //batch send fixed token amount from sender, require approval of contract as spender
    function multiSendFixedToken(address[] memory recipients, uint256 amount) public {
        
        address from = msg.sender;
        
        require(recipients.length > 0);
        require(amount > 0);
        require(recipients.length * amount <= erc20token.allowance(from, address(this)));
        
        for (uint256 i = 0; i < recipients.length; i++) {
            erc20token.safeTransferFrom(from, recipients[i], amount);
        }
        
    }  
    
    //batch send different token amount from sender, require approval of contract as spender
    function multiSendDiffToken(address[] memory recipients, uint256[] memory amounts) public {
        
        require(recipients.length > 0);
        require(recipients.length == amounts.length);
        
        address from = msg.sender;
        
        uint256 allowance = erc20token.allowance(from, address(this));
        uint256 currentSum = 0;
        
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amount = amounts[i];
            
            require(amount > 0);
            currentSum = currentSum.add(amount);
            require(currentSum <= allowance);
            
            erc20token.safeTransferFrom(from, recipients[i], amount);
        }
        
    }   
     
    
    //batch send fixed token amount from contract
    function multiSendFixedTokenFromContract(address[] memory recipients, uint256 amount) public onlyOwner {
        require(recipients.length > 0);
        require(amount > 0);
        require(recipients.length * amount <= erc20token.balanceOf(address(this)));
        
        for (uint256 i = 0; i < recipients.length; i++) {
            erc20token.safeTransfer(recipients[i], amount);
        }
    }
    
    //batch send different token amount from contract
    function multiSendDiffTokenFromContract(address[] memory recipients, uint256[] memory amounts) public onlyOwner {
        
        require(recipients.length > 0);
        require(recipients.length == amounts.length);
        
        uint256 length = recipients.length;
        uint256 currentSum = 0;
        uint256 currentTokenBalance = erc20token.balanceOf(address(this));
        
        for (uint256 i = 0; i < length; i++) {
            uint256 amount = amounts[i];
            require(amount > 0);
            currentSum = currentSum.add(amount);
            require(currentSum <= currentTokenBalance);
            
            erc20token.safeTransfer(recipients[i], amount);
        }
    }
    
}