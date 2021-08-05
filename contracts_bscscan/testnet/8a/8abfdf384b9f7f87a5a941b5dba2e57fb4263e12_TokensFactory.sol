// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Token.sol";

contract TokensFactory {
    
    address[] public children;

    event CreatedToken(address tokenAddress, address tokenOwner, string name, string symbol, uint8 decimals, uint256 totalSupply);
    
    function createERC20Token(
        string memory name, 
        string memory symbol, 
        uint8 decimals, 
        uint256 totalSupply) public {

        bytes memory bytecode = abi.encodePacked(type(ERC20Token).creationCode, abi.encode(name, symbol, decimals, totalSupply, msg.sender));
        
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), callvalue())
            
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        children.push(addr);
        
        emit CreatedToken(addr, msg.sender, name, symbol, decimals, totalSupply);
    }
}