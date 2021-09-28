// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.3;

import 'StandardToken.sol';

contract BlockchainDevToken is StandardToken {
    /**
     * Public variables of the token
     * NOTE: The following variables are OPTIONAL vantiies. One does not have to include them.
     * They allow one to customoze the token contract & in no way influences the core functionality.
     * Some wallets/interfaces might not even bother to look at this information.
     */
    string public name;                     // Token name
    uint8 public decimals;                  // Number of decimals that our token will have. To be standard-compliant, keep it 18.
    string public symbol;                   // A short identifer for your contract (eg. ACAD for Academy Token, EOS, etc).
    uint256 public unitsOneEthCanBuy;       // How many units of your token can be bought by 1 ETH? (eg: 1000000000000000000 wei) = 10 tokens.
    uint256 public totalRaisedEthInWei;     // WEI is the smallest unit of ETH. Similar to cent in USD or Satoshi in BTC. Total raised from ICO.
    address payable public owner;           // The raised ETH will go to this account.

    constructor() public {
        decimals = 18;                          // Number of decimals for your token.
        _totalSupply = 1000000000000000000000;  // Update the total supply of your token. (1000 * 10^18).
        _balances[msg.sender] = _totalSupply;   // Grant the contract creator all inital tokens. In this case, it is set 1000.
                                                // Ex: If you want your initial coins to be 500 and your decimals is 6, set this value to: (500 * 10^6).
        name = "Blockchain Dev Token";          // Set name. For display purposes.
        symbol = "BDT";                         // Set Symbol. For display purposes.
        unitsOneEthCanBuy = 10;                 // Set the price of your token for the ICO;
                                                // In this case, if a user pay 1 ETH, they will receive 10 BDT;
        owner = msg.sender;                     // Owner of this contract gets the total ETH raised.
    }

    /**
     * As of Solidity 0.6.0, if you want your contract to receive Etherm you have to implement a receive Ether function
     * (using payable fallback function for receiving Ether is not recommended, since it would not fail on interface confusions).
     */
    receive() external payable {
        totalRaisedEthInWei = totalRaisedEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(_balances[owner] >= amount);
        _balances[owner] -= amount;
        _balances[msg.sender] += amount;
        Transfer(owner, msg.sender, amount);
        owner.transfer(msg.value);
    }
}