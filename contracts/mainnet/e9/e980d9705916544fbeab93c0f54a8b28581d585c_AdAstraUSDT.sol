// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "ERC20.sol";

contract AdAstraUSDT is ERC20
{
    address private owner;
    
    constructor(address _owner) public ERC20("AdAstraUSDT", "adUSDT")
    {
        owner = _owner;
    }
    
    function getOwner() external view returns (address)
    {
        return owner;
    }
    
    function mint(address _to, uint256 _amount) external
    {
        require(msg.sender == owner);
        
        _mint(_to, _amount);
    }
    
    function burn(uint256 _amount, address _fromOwner) external
    {
        require(msg.sender == owner);
        
        _burn(_fromOwner, _amount);
    }
}