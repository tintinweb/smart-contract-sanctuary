/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity ^0.8.0;

interface ERC20 {
     function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Faucet {
    
    address buoyContract = 0xF949F43E85f92678db2ac026921aC56D32F84597;
    
    ERC20 buoy = ERC20(buoyContract);
    
    function redeemFaucet() public {
        buoy.transfer(msg.sender, 100*(10**18));
    }
    
}