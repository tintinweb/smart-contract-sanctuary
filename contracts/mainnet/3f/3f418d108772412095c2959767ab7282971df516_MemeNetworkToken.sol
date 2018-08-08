pragma solidity ^0.4.11;
/*
    Meme Network Token contract source code.
    Copyright (C) 2017 whodknee

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

contract MemeNetworkToken {
    // Token information.
    string public constant name = "Meme Network Token";
    string public constant symbol = "MNT";
    uint8 public constant decimals = 18;

    uint256 public constant tokenCreationRate = 10;
    uint256 public constant tokenCreationCap = 100000 ether * tokenCreationRate;
    uint256 totalTokens;

    address public devAddress;

    // Ending block.
    uint256 public endingBlock;

    // Funding state.
    bool public funding = true;
    
    // Array of balances.
    mapping (address => uint256) balances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    function MemeNetworkToken(
        address _devAddress,
        uint256 _endingBlock
        ) {
        devAddress = _devAddress;
        endingBlock = _endingBlock;
    }

    function balanceOf(address _owner) external constant returns (uint256) {
        return balances[_owner];
    }
    
    function totalSupply() external constant returns (uint256) {
        return totalTokens;
    }

    // Transfer Coins
    function transfer(address _to, uint256 _value) {
        
        //check for proper balance and overflows
        if (balances[msg.sender] < _value)
            throw;
        if (balances[_to] + _value < balances[_to])
            throw;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }

    // Crowdfunding. Only if(funding).
    function create() payable external {
        // Abort if funding is over.
        // Abort if past ending block.
        // Abort if msg.value == 0
        // Abort if tokens created would cause 
        // totalTokens to be greater than tokenCreationCap
        if(!funding) throw;
        if (block.number > endingBlock)
            throw;
        // Do not allow creating 0 or more than the cap.
        if (msg.value == 0) throw;
        if (msg.value > (tokenCreationCap - totalTokens) / tokenCreationRate)
            throw;
        
        var numTokens = msg.value * tokenCreationRate;
        totalTokens += numTokens;

        balances[msg.sender] += numTokens;

        Transfer(0, msg.sender, numTokens);      
    }
    function finalize() {
        if (!funding) throw;
        if (block.number <= endingBlock &&
            totalTokens < tokenCreationCap)
            throw;
        
        funding = false;

        uint256 devTokens = tokenCreationCap - totalTokens + (tokenCreationCap / 5);
        balances[devAddress] += devTokens;
        Transfer(0, devAddress, devTokens);

        if (!devAddress.send(this.balance)) throw;
    }
}