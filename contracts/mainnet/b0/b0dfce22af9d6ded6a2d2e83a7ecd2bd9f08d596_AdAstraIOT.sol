// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "SwapTokenBase.sol";

contract AdAstraIOT is ERC1363
{
    address private owner;
    
    constructor(address _owner) public ERC1363("AdAstraIOT", "aIOT")
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
}