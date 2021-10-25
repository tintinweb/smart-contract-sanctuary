/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

pragma solidity ^0.8;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    
    // don't need to define other functions, only using `transfer()` in this case
}

contract MyContract {
    // Do not use in production
    // This function can be executed by anyone
    function sendUSDT(address _to, uint256 _amount) external {
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        IERC20 usdt = IERC20(address(0xC1A2B78FB4B4Af82829EDde396C82260c840E45B));
        
        // transfers USDT that belong to your contract to the specified address
        usdt.transfer(_to, _amount);
    }
}