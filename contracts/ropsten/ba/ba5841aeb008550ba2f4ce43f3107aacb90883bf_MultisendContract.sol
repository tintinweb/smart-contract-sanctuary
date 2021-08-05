/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract MultisendContract {
    function send(address tokenAddress, address[] memory addresses, uint256[] memory values) public returns (bool) {
        require(addresses.length == values.length, "Array length mismatch");
        
        IERC20 token = IERC20(tokenAddress);
        
        for (uint i = 0; i < addresses.length; i++) {
            require(token.transferFrom(msg.sender, addresses[i], values[i]));
        }
        
        return true;
    }
}