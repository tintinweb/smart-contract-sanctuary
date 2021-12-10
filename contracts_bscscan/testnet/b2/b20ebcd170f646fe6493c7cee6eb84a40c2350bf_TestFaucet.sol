/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.8.4;

interface IERC20 {
    
     /**
     * @dev returns the tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

     /**
     * @dev returns the decimal places of a token
     */
    function decimals() external view returns (uint8);

    /**
     * @dev transfers the `amount` of tokens from caller's account
     * to the `recipient` account.
     *
     * returns boolean value indicating the operation status.
     *
     * Emits a {Transfer} event
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
 
}

contract TestFaucet {
    
    // The underlying token of the Faucet
    IERC20 token;
    
    // The address of the faucet owner
    address owner;
    
    // For rate limiting
    mapping(address=>uint256) nextRequestAt;
    
    // No.of tokens to send when requested
    uint256 faucetDripAmount = 1;
    
    // Sets the addresses of the Owner and the underlying token
    constructor (address _tokenAddress, address _ownerAddress) {
        token = IERC20(_tokenAddress);
        owner = _ownerAddress;
    }   
    
    // Verifies whether the caller is the owner 
    modifier onlyOwner{
        require(msg.sender == owner,"FaucetError: Caller not owner");
        _;
    }
    
    // Sends the amount of token to the caller.
    function send() external {
        require(token.balanceOf(address(this)) > 1,"FaucetError: Empty");
        require(nextRequestAt[msg.sender] < block.timestamp, "FaucetError: Try again later");
        
        // Next request from the address can be made only after 5 minutes         
        nextRequestAt[msg.sender] = block.timestamp + (5 minutes); 
        
        token.transfer(msg.sender,faucetDripAmount * 10**token.decimals());
    }  
    
    // Updates the underlying token address
     function setTokenAddress(address _tokenAddr) external onlyOwner {
        token = IERC20(_tokenAddr);
    }    
    
    // Updates the drip rate
     function setFaucetDripAmount(uint256 _amount) external onlyOwner {
        faucetDripAmount = _amount;
    }  
     
     
     // Allows the owner to withdraw tokens from the contract.
     function withdrawTokens(address _receiver, uint256 _amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= _amount,"FaucetError: Insufficient funds");
        token.transfer(_receiver,_amount);
    }    
}