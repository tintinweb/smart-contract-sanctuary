/**
 *Submitted for verification at Etherscan.io on 2020-11-17
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface InterfaceERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Airdropper {
    address public owner;
    constructor()public{
        owner = msg.sender;
    }
    
    function AirTransfer(address[] memory _recipients, uint _values, address _tokenAddress) onlyOwner public returns (bool) {
        require(_recipients.length > 0);
        InterfaceERC20 token = InterfaceERC20(_tokenAddress);
        for(uint j = 0; j < _recipients.length; j++){
            token.transfer(_recipients[j], _values);
        }
        return true;
    }
    
    function withdrawalToken(address _tokenAddress) onlyOwner public { 
        InterfaceERC20 token = InterfaceERC20(_tokenAddress);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}