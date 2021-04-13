/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

pragma solidity ^0.8.0;

interface ERC20 {
     function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Faucet {
    
    address buoyContract = 0xF52b15941F085a095253aeb1DfF5082aCF7C5675;
    
    ERC20 buoy = ERC20(buoyContract);
    
    function redeemFaucet() public {
        buoy.transfer(msg.sender, 100*(10**18));
    }
    
}