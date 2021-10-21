// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Balances {
    
    struct Balance {
        address user;
        address token;
        uint256 amount;
    }
    
    /* public functions */
    
    /* Check the ERC20 token balances of a wallet for multiple tokens and addresses.
     Returns array of token balances in wei units. */
    function tokenBalances(address[] calldata users,  address[] calldata tokens) external view returns (Balance[] memory balances) {
        balances = new Balance[](users.length * tokens.length);
        
        uint idx = 0;
        
        for(uint i = 0; i < tokens.length; i++) {
            
            for (uint j = 0; j < users.length; j++) {
                
                balances[idx].user = users[j];
                balances[idx].token = tokens[i];
                
                if(tokens[i] != address(0x0)) { 
                    balances[idx].amount = tokenBalance(users[j], tokens[i]); // check token balance and catch errors
                } else {
                    balances[idx].amount = users[j].balance; // ETH balance    
                }
                idx++;
            }
        }    
        return balances;
    }
    
    
    /* Private functions */
    
    
    /* Check the token balance of a wallet in a token contract.
    Returns 0 on a bad token contract   */
    function tokenBalance(address user, address token) internal view returns (uint) {
        // token.balanceOf(user), selector 0x70a08231
        return getNumberOneArg(token, 0x70a08231, user);
    }
    
    
    /* Generic private functions */
    
    // Get a token or exchange value that requires 1 address argument (most likely arg1 == user).
    // selector is the hashed function signature (see top comments)
    function getNumberOneArg(address contractAddr, bytes4 selector, address arg1) internal view returns (uint) {
        if(isAContract(contractAddr)) {
            (bool success, bytes memory result) = contractAddr.staticcall(abi.encodeWithSelector(selector, arg1));
            // if the contract call succeeded & the result looks good to parse
            if(success && result.length == 32) {
                return abi.decode(result, (uint)); // return the result as uint
            } else {
                return 0; // function call failed, return 0
            }
        } else {
            return 0; // not a valid contract, return 0 instead of error
        }
    }
    
    // check if contract (token, exchange) is actually a smart contract and not a 'regular' address
    function isAContract(address contractAddr) internal view returns (bool) {
        uint256 codeSize;
        assembly { codeSize := extcodesize(contractAddr) } // contract code size
        return codeSize > 0; 
        // Might not be 100% foolproof, but reliable enough for an early return in 'view' functions 
    }
}