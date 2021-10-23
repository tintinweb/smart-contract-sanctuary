// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Balances {
    
    struct Balance {
        address user;
        address token;
        uint256 amount;  // amount in wei
    }
    
    
    /* Check the ERC20 token balances of a wallet for multiple tokens and addresses.*/
    function tokenBalances(address[] calldata users,  address[] calldata tokens) external view returns (Balance[] memory balances) {
        balances = new Balance[](users.length + tokens.length);
        
        uint idx = 0;
        
        for(uint i = 0; i < tokens.length; i++) {
            for (uint j = 0; j < users.length; j++) {
                
                balances[idx].user = users[j];
                balances[idx].token = tokens[i];
                
                if(tokens[i] != address(0x0)) { 
                    // check token balance and catch errors
                    balances[idx].amount = tokenBalance(users[j], tokens[i]);
                } else {
                    // ETH balance
                    balances[idx].amount = users[j].balance;
                }
                idx++;
            }
        }
        return balances;
    }
    
    
    /* Check the token balance of a wallet in a token contract.
    Returns 0 on a bad token contract.*/
    function tokenBalance(address user, address token) internal view returns (uint) {
        // token.balanceOf(user), selector 0x70a08231
        return getNumberOneArg(token, 0x70a08231, user);
    }
    
    
    /* Check the ERC-1155 token balances of a wallet for multiple addresses.*/
    function token1155Balances(address[] calldata users,  address token, uint256 id) external view returns (uint256[] memory balances) {
        balances = new uint256[](users.length);
        
        for (uint i = 0; i < users.length; i++) {
            balances[i] = token1155Balance(users[i], token, id);
        }
        return balances;
    }
    
    
    /* Check the ERC-1155 token balance of a wallet in a token contract for specific token and id.
    Returns 0 on a bad token contract.*/
    function token1155Balance(address user, address token, uint256 id) internal view returns (uint) {
        // token.balanceOf(address,uint256), selector 0x00fdd58e
        return getNumberTwoArgs(token, 0x00fdd58e, user, id);
    }
    
    
    /* Generic private functions */
    
    // Get a token value that requires 1 address argument (most likely arg1 == user).
    // selector is the hashed function signature
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
    
    // Get an token balance requires 2 address arguments ( (token, user), (user, token), (user, id), ...).
    // selector is the hashed function signature
    function getNumberTwoArgs(address contractAddr, bytes4 selector, address arg1, uint256 arg2) internal view returns (uint) {
        if(isAContract(contractAddr)) {
            (bool success, bytes memory result) = contractAddr.staticcall(abi.encodeWithSelector(selector, arg1, arg2));
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