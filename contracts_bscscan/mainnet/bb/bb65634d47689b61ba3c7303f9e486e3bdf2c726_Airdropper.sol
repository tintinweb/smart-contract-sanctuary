/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: MIT

/**
 * Adopted from https://github.com/XuHugo/solidityproject/blob/master/airdrop/airdrop.sol 
 * With modification such that it uses transferFrom instead of transfer.
 * So the contract does not hold tokens.
 * This contract is written based on requirement for MEONG Token.
 * Only addresses with zero balance can receive tokens.
*/

pragma solidity ^0.8.0;

interface Token {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Airdropper {
    
    function airTransfer(address[] memory _recipients, uint _value, address _tokenAddress) public returns (bool) {
        require(_recipients.length > 0);
        
        Token token = Token(_tokenAddress);
        
        for(uint j = 0; j < _recipients.length; j++){
            if (token.balanceOf(_recipients[j]) == 0) {
                token.transferFrom(msg.sender, _recipients[j], _value);
            }
        }
 
        return true;
    }

    function getAllowance(address _owner, address _tokenAddress) public view returns(uint256 balance_) {
        Token token = Token(_tokenAddress);
        return token.allowance(_owner, address(this));
    }

}