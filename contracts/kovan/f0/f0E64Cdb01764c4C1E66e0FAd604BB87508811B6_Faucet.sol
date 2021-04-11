/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity ^0.8.0;

interface ERC20 {
     function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Faucet {
    
    address buoyContract = 0x8c07dbc0EE8A62eE7dcd2732f2bb735D89cf7487;
    
    ERC20 buoy = ERC20(buoyContract);
    
    function redeemFaucet() public {
        buoy.transfer(msg.sender, 100*(10**18));
    }
    
}