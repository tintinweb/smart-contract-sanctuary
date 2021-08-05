// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "ERC1363.sol";

contract JasmyDepositToken is ERC1363
{
    address public owner;
    
    constructor(address _owner, string memory _name, string memory _symbol) public ERC1363(_name, _symbol)
    {
        owner = _owner;
    }
    
    function mint(address _to, uint256 _amount) external
    {
        require(msg.sender == owner);
        
        _mint(_to, _amount);
    }
    
    function burn(uint256 _amount, bool _fromOwner) external
    {
        require(msg.sender == owner);
        
        _burn(_fromOwner ? owner : address(this), _amount);
    }
}