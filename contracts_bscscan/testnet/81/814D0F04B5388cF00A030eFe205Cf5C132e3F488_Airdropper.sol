/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

// File: contracts/5_Airdrop.sol

// SPDX-License-Identifier: MIT

/**
 * Adopted from https://github.com/XuHugo/solidityproject/blob/master/airdrop/airdrop.sol 
 * With modification such that it uses transferFrom instead of transfer.
 * So the contract does not hold tokens.
 * This contract is written based on requirement for MEONG Token.
 * https://bscscan.com/token/0x464acc420607d818f271875552868ddf8095cafe
 * 
*/

pragma solidity ^0.8.0;

/**
 * @notice ERC20 token interface.
 */
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
    
    /**
     * @notice Only addresses with zero balance can receive tokens.
     * @dev _recipients: list of recipient addresses
     * @dev _value: the value to send to each recipient.
     * @dev _tokenAddress: the address of the token.
     * @dev return value: the number of address receiving tokens.
     */
    function sendToNewAddressesExactValue(address[] memory _recipients, uint256 _value, address _tokenAddress) public returns (uint256) {
        require(_recipients.length > 0);
        
        Token token = Token(_tokenAddress);

        require(_value * _recipients.length <= token.allowance(msg.sender, address(this)), "Airdropper: Not enough allowance for all recipients.");
        
        uint256 ctr = 0;
        for(uint j = 0; j < _recipients.length; j++){
            if (token.balanceOf(_recipients[j]) == 0) {
                bool success = token.transferFrom(msg.sender, _recipients[j], _value);
                if(success) ctr ++;
            }
        }
 
        return ctr;
    }

    /**
     * @notice All listed balance can receive tokens.
     * @dev _recipients: list of recipient addresses
     * @dev _value: the value to send to each recipient.
     * @dev _tokenAddress: the address of the token.
     * @dev return value: the number of address receiving tokens.
     */
    function sendToAllAddressesExactValue(address[] memory _recipients, uint256 _value, address _tokenAddress) public returns (uint256) {
        require(_recipients.length > 0);
        
        Token token = Token(_tokenAddress);

        require(_value * _recipients.length <= token.allowance(msg.sender, address(this)), "Airdropper: Not enough allowance for all recipients.");
        
        uint256 ctr = 0;
        for(uint j = 0; j < _recipients.length; j++){
            bool success = token.transferFrom(msg.sender, _recipients[j], _value);
            if(success) ctr ++;
        }
 
        return ctr;
    }
    
    /**
     * @notice Only new addresses can receive tokens, with randomised values.
     * @dev _recipients: list of recipient addresses
     * @dev _value: the value to send to each recipient
     * @dev _variantMaxValue: the maximum value to determine the variable that will make the sent _value looks random. The approved value should be at least equal to (_value + _variantMaxValue) * _recipients.length 
     * @dev _tokenAddress: the address of the token.
     * @dev return value: the number of address receiving tokens.
     */
    function sendToNewAddressesVariantValue(address[] memory _recipients, uint256 _value, uint256 _variantMaxValue, address _tokenAddress) public returns (uint256) {
        require(_recipients.length > 0);
        
        Token token = Token(_tokenAddress);
        
        // make sure the allowance is at least equal to the maximum value transferred
        require((_value + _variantMaxValue) * _recipients.length <= token.allowance(msg.sender, address(this)), "Airdropper: Not enough allowance for all recipients.");
        
        uint256 ctr = 0;
        bytes32 randomseed = keccak256(abi.encodePacked(block.timestamp));
        for(uint j = 0; j < _recipients.length; j++){
            if (token.balanceOf(_recipients[j]) == 0) {
                uint256 randomiser_ = uint256(randomseed) % _variantMaxValue;
                bool success = token.transferFrom(msg.sender, _recipients[j], _value + randomiser_);
                if(success) ctr ++;
                randomseed = keccak256(abi.encodePacked(randomseed));
            }
        }
 
        return ctr;
    }
    
    /**
     * @notice All listed balance can receive tokens, with kind of randomised values.
     * @dev _recipients: list of recipient addresses
     * @dev _value: the value to send to each recipient
     * @dev _variantMaxValue: the maximum value to determine the variable that will make the sent _value looks random. The approved value should be at least equal to (_value + _variantMaxValue) * _recipients.length 
     * @dev _tokenAddress: the address of the token.
     * @dev return value: the number of address receiving tokens.
     */
    function sendToAllAddressesVariantValue(address[] memory _recipients, uint256 _value, uint256 _variantMaxValue, address _tokenAddress) public returns (uint256) {
        require(_recipients.length > 0);
        
        Token token = Token(_tokenAddress);
        
        // make sure the allowance is at least equal to the maximum value transferred
        require((_value + _variantMaxValue) * _recipients.length <= token.allowance(msg.sender, address(this)), "Airdropper: Not enough allowance for all recipients.");
        
        uint256 ctr = 0;
        bytes32 randomseed = keccak256(abi.encodePacked(block.timestamp));
        for(uint j = 0; j < _recipients.length; j++){
            uint256 randomiser_ = uint256(randomseed) % _variantMaxValue;
            bool success = token.transferFrom(msg.sender, _recipients[j], _value + randomiser_);
            if(success) ctr ++;
            randomseed = keccak256(abi.encodePacked(randomseed));
        }
 
        return ctr;
    }

    /**
     * @notice Checks the contract allowance in the token.
     */
    function getAllowance(address _sender, address _tokenAddress) public view returns(uint256 balance_) {
        Token token = Token(_tokenAddress);
        return  token.allowance(_sender, address(this));
    }

}