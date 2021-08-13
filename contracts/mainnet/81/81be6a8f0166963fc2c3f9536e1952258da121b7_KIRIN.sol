// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;

import "./MintableToken.sol";
import "./BurnableToken.sol";
import "./PausableToken.sol";
 
contract KIRIN is MintableToken, BurnableToken, PausableToken {
    
    string public name = "KIRIN";
    string public symbol = "KIRIN"; // Currency Unit
    uint   public decimals = 8;     // Decimals Point
    uint   public INITIAL_SUPPLY = 51000000000 * (10 ** decimals);

    mapping (address => uint256) public airDropHistory;
    event AirDrop(address _receiver, uint256 _amount);

    // Constructor
    constructor() public {
    	totalSupply_ = INITIAL_SUPPLY;
    	balances[msg.sender] = INITIAL_SUPPLY;
    	emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    
    // Airdrop
    function dropToken(address[] memory receivers, uint256[] memory values) public {
        require(receivers.length != 0);
        require(receivers.length == values.length);

        for (uint256 i = 0; i < receivers.length; i++) {
            address receiver = receivers[i];
            uint256 amount = values[i];

            transfer(receiver, amount);
            airDropHistory[receiver] += amount;

            emit AirDrop(receiver, amount);
        }
    }
}