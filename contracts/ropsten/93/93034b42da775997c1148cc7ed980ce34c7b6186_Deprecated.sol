/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-111 ===

    STATUS: [in progress]
    DEPLOYED AT: 0x93034b42da775997C1148CC7ed980cE34C7b6186

    VULNERABILITY REPRODUCTION STEPS:
    1. Call deposit() to load money into contract
    2. Call useDeprecated() to use all the deprecated functions and exit.
    
    EXPECTED OUTCOME:
    ...
    
    ACTUAL OUTCOME:
    The contract uses every deprecated function and keyword and then self destructs
    
    NOTES:
    None
*/

pragma solidity ^0.4.24;

contract Deprecated {
	uint256 amount = 0;
	
    function useDeprecated() public constant {

        bytes32 blockhash = block.blockhash(0);
        bytes32 hashofhash = sha3(blockhash);

        uint gas = msg.gas;

        if (gas == 0) {
            throw;
        }

        address(this).callcode();

        var a = [1,2,3];

        var (x, y, z) = (false, "test", 0);

        suicide(address(0));
    }
    
    function deposit() public payable {
        amount = msg.value;
    }
    
    function () public {}
}