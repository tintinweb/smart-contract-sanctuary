/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/TestContract.sol

pragma solidity ^0.8.7;

contract TestContract {
    function revertFunction(uint256 amount) public {
        revert("error");
    }
}