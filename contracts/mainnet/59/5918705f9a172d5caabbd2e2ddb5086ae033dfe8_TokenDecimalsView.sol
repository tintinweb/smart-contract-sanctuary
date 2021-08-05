/**
 *Submitted for verification at Etherscan.io on 2020-12-29
*/

/**
 *  @authors: [@mtsalenc]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.0;

/** @title TokenDecimalsView
 *  Utility view contract to fetch token decimals in batches.
 */
contract TokenDecimalsView {
    
    function getTokenDecimals(address[] calldata _tokens) external view returns (uint[] memory decimals) {
        decimals = new uint[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            address tokenAddress = _tokens[i];
            // Call the contract's decimals() function without reverting when
            // the contract does not implement it.
            // 
            // Two things should be noted: if the contract does not implement the function
            // and does not implement the contract fallback function, `success` will be set to
            // false and decimals won't be set. However, in some cases (such as old contracts) 
            // the fallback function is implemented, and so staticcall will return true
            // even though the value returned will not be correct (the number below):
            // 
            // 22270923699561257074107342068491755213283769984150504402684791726686939079929
            //
            // We handle that edge case by also checking against this value.
            uint returnedDecimals;
            bool success;
            bytes4 sig = bytes4(keccak256("decimals()"));
            assembly {
                let x := mload(0x40)   // Find empty storage location using "free memory pointer"
                mstore(x, sig)          // Set the signature to the first call parameter. 0x313ce567 === bytes4(keccak256("decimals()")
                success := staticcall(
                    30000,              // 30k gas
                    tokenAddress,       // The call target.
                    x,                  // Inputs are stored at location x
                    0x04,               // Input is 4 bytes long
                    x,                  // Overwrite x with output
                    0x20                // The output length
                )
                
                returnedDecimals := mload(x)   
            }
            if (success && returnedDecimals != 22270923699561257074107342068491755213283769984150504402684791726686939079929) {
                decimals[i] = returnedDecimals;
            }
        }
    }
}