/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract NFTommo
{
    address private owner;
    
    uint256 private registerPrice;
    mapping (address => bool) private userToRegistered;
    
    constructor()
    {
        owner = msg.sender;   
        registerPrice = 0.1 ether;
    }
    
    //////////
    // Getters
    
    function getRegisterPrice() external view returns(uint256)
    {
        return(registerPrice);
    }

    function getOwner() external view returns(address)
    {
        return(owner);
    }
    
    function isAddressRegistered(address _account) external view returns(bool)
    {
        return(userToRegistered[_account]);
    }
    
    //////////
    // Setters
    function setOwner(address _owner) external
    {
        require(msg.sender == owner, "Function only callable by owner!");
    
        owner = _owner;    
    }
    
    function setRegisterPrice(uint256 _registerPrice) external
    {
        require(msg.sender == owner, "Function only callable by owner!");
        
        registerPrice = _registerPrice;
    }
    
    /////////////////////
    // Register functions
    receive() external payable
    {
        register();
    }
    
    function register() public payable
    {
        require(!userToRegistered[msg.sender], "Address already registered!");
        require(msg.value >= registerPrice);
        
        userToRegistered[msg.sender] = true;
    }
    
    /////////////////
    // Withdraw Ether
    function withdraw(uint256 _amount, address _receiver) external
    {   
        require(msg.sender == owner, "Function only callable by owner!");
        
        payable(_receiver).transfer(_amount);
    }
}