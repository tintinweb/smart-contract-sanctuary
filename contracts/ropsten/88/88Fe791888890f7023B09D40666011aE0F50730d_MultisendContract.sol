/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}


contract MultisendContract {
    function send(address tokenAddress, address[] memory addresses, uint256[] memory values) public returns (bool) {
        require(addresses.length == values.length, "Array length mismatch");
        
        IERC20 token = IERC20(tokenAddress);
        uint256 total = 0;
        
        for (uint i = 0; i < values.length; i++) {
            total += values[i];
        }
        
        require(total > token.allowance(msg.sender, address(this)), "Allowance is too low");
        require(total > token.balanceOf(msg.sender), "Balance is too low");
        
        
        for (uint i = 0; i < addresses.length; i++) {
            require(token.transferFrom(msg.sender, addresses[i], values[i]));
        }
        
        return true;
    }
}