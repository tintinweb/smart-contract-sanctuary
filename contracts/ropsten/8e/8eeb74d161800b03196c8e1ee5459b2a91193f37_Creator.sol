// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MATtoken.sol";

contract Creator{
    
    event TokenCreated(address creator,address Token);
    
    address [] tokenAddress;
    
    address obj;
    
    function setobj(address _addr) external{
        obj = _addr;
    }
    
    function get()public view returns(address [] memory){
        
        return tokenAddress;
    }
    function createToken(string memory _name,
                string memory _symbol,
                uint _totalSupply) external returns(Token tokenaddress){
            
            tokenaddress = new Token(_name,_symbol,_totalSupply);
            tokenAddress.push(address(tokenaddress));
            emit TokenCreated(address(this), address(tokenaddress));
    }
    
    function getName() external view returns(string memory){
        return IERC20Metadata(obj).name();
    }
    
    function getSymbol() external view returns(string memory){
        return IERC20Metadata(obj).symbol();
    }
    
    function gettotalSupply() external view returns(uint){
        return IERC20(obj).totalSupply();
    }
    

}