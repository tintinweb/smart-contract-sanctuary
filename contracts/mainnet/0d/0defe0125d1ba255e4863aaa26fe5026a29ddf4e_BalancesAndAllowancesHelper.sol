/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity ^0.7.6;

interface IERC20 {
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract BalancesAndAllowancesHelper {
    
    uint256 private constant infinityAllowance = 1 << 248;
    
    function getBalances(IERC20[] calldata tokens, address wallet) external view returns (uint256[] memory indexAndBalance) {
        uint counter = 0;
        uint256[] memory tmp = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            try tokens[i].balanceOf(wallet) returns (uint256 balance) {
                if (balance == 0) {
                continue;
            }
            
            tmp[counter] = i << 248 | balance;
            counter++;
            } catch {
                
            }
        }
        
        indexAndBalance = new uint256[](counter);
        for (uint i = 0; i < counter; i++) {
            indexAndBalance[i] = tmp[i];
        }
    }
    
    function getAllowances(IERC20[] calldata tokens, address owner, address spender) external view returns (uint256[] memory indexAndAllowance) {
        uint counter = 0;
        uint256[] memory tmp = new uint256[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            try tokens[i].allowance(owner, spender) returns (uint256 allowance) {
                if (allowance == 0) {
                    continue;
                }
            
                if (allowance > infinityAllowance) {
                    tmp[counter] = (i << 248) | (1 << 247);        
                } else {
                    tmp[counter] = (i << 248) | allowance;       
                }
                counter++;
            } catch {
                
            }
        }
        
        indexAndAllowance = new uint256[](counter);
        for (uint i = 0; i < counter; i++) {
            indexAndAllowance[i] = tmp[i];
        }
    }
}