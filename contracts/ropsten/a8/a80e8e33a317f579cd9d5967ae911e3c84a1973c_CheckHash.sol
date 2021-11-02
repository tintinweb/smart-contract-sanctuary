/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-100 ===

    STATUS: [complete]
    DEPLOYED AT: 0xa80e8e33a317f579cd9d5967ae911e3c84a1973c

    VULNERABILITY REPRODUCTION STEPS:
    1. Call the Deposit Function with Some Ethereum as the Value
    2. Call _sendMoney to send money
    
    EXPECTED OUTCOME:
    _sendMoney should be marked private since it is intended that user call withdraw 
    where the user is validated and then _sendMoney is called.
    
    ACTUAL OUTCOME:
    The attacker can just call _sendMoney directly and bypass the validation check. the
    wallet amount should increase regardless of which sender is calling the function.
    
    NOTES:
    None
*/

pragma solidity ^0.4.24;

contract CheckHash {
    uint256 money = 0;
    
    
    function withdraw() public {
        require(address(msg.sender) == address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4));
        _sendMoney(msg.sender);
        
    }
    
    function _sendMoney(address wallet) {
        wallet.transfer(money);
    }
    
    function deposit() payable public {
        money = msg.value;
    }
}