/**
 *Submitted for verification at polygonscan.com on 2021-10-25
*/

pragma solidity ^0.8.0;

interface IERC {
    function mint(uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

contract getUSDC {
    address usdc_address = 0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e;
    
    function getAirdrop(uint256 amount) public {
        require (amount <= 50000000, "Amount > 50$");
        IERC USDC = IERC(usdc_address);
        USDC.mint(amount);
        USDC.transfer(msg.sender, amount);
    }
}