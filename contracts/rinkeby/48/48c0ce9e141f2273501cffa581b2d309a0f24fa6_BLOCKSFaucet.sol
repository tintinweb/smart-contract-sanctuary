/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: UNLISCENSED
/*
 ________  ___       ________  ________  ___  __    ________      
|\   __  \|\  \     |\   __  \|\   ____\|\  \|\  \ |\   ____\     
\ \  \|\ /\ \  \    \ \  \|\  \ \  \___|\ \  \/  /|\ \  \___|_    
 \ \   __  \ \  \    \ \  \\\  \ \  \    \ \   ___  \ \_____  \   
  \ \  \|\  \ \  \____\ \  \\\  \ \  \____\ \  \\ \  \|____|\  \  
   \ \_______\ \_______\ \_______\ \_______\ \__\\ \__\____\_\  \ 
    \|_______|\|_______|\|_______|\|_______|\|__| \|__|\_________\
                                                      \|_________|
https://blocks.io
*/
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

contract BLOCKSFaucet {
    
    // The underlying token of the Faucet
    IERC20 token;
    
    // The address of the faucet owner
    address owner;
    
    // For rate limiting
    mapping(address=>uint256) nextRequestAt;
    
    // No.of tokens to send when requested
    uint256 faucetDripAmount = 2;
    
    // Sets the addresses of the Owner and the underlying token
    constructor (address _blocksAddress, address _ownerAddress) {
        token = IERC20(_blocksAddress);
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
        
        // Next request from the address can be made only after 24 hours         
        nextRequestAt[msg.sender] = block.timestamp + (24 hours); 
        
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