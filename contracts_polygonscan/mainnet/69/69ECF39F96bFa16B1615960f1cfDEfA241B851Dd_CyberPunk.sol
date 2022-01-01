/**
 *Submitted for verification at polygonscan.com on 2021-12-31
*/

pragma solidity >=0.4.22 <0.6.0;
contract CyberPunk {
    string public name;
    string public symbol;
    uint8 public decimals;
    mapping (address => uint256) public balanceOf ;

        constructor(uint256 initialSupply, 
        string memory TokenName, string memory TokenSymbol, uint8 decimalUnits) public
{
    balanceOf[msg.sender] = initialSupply;
    // Give the creator all initial tokens

    name = TokenName;
    // Set the name for display purposes

    symbol = TokenSymbol;
    // Set the symbol for display purposes

    decimals = decimalUnits;
    // Amount of decimals for display purposes
}
function transfer(address _to, uint256 _value) public returns (bool success) {
    require (balanceOf[msg.sender] >= _value);
    // Check if the sender has enough
    
    require(balanceOf[_to] + _value >= 
    balanceOf[_to]);
    // Check for overflows

balanceOf[msg.sender] -= _value;
    // Subtract from the sender 

    balanceOf[_to] += _value;
    // Add the same to the recipient

    return true;
}
}