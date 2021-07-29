/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.8.4;

interface mintableERC20 {
    function mint() external returns (bool success);
}

contract iMint {
    function mintt(address _mint) external {
        mintableERC20(_mint).mint();
    }
}