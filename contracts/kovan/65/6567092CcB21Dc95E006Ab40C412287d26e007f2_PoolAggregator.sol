/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

pragma solidity ^0.8.7;

interface IAaveLendingPool{

    function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
    ) external;    
    
}

contract PoolAggregator{

    address AaveLendingPoolAddr = 0xa23842C61ca1e15bB148Ab13840768b87f04E642;

    IAaveLendingPool AaveLendingPool = IAaveLendingPool(AaveLendingPoolAddr);

    // external - funciton can only be accessed externally not internally
    function deposit(address asset, uint256 amount) external {
        // TODO: logic determining highest rate
        // calling external contract with type casting
        AaveLendingPool.deposit(asset, amount, msg.sender, 0);
        
    }

}