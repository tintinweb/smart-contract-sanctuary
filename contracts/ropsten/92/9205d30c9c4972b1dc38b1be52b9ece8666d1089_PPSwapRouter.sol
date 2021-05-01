/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-04
*/

pragma solidity =0.5.0;

contract PPSwapRouter{
    
    function swapNoSwapFee(address accountA, address accountB, address tokenA, address tokenB, uint amtA, uint amtB) external returns(bool){
        // transfer amtA of tokenA from accountA to accountB
        (bool success, bytes memory data) = tokenA.call(abi.encodeWithSelector(0x23b872dd, accountA, accountB, amtA));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SwapNoSwapFee failure: transfer amtA of tokenA from accountA to accountB');
        
         // transfer amtB of tokenB from accountB to accountA
        (success, data) = tokenB.call(abi.encodeWithSelector(0x23b872dd, accountB, accountA, amtB));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SwapNoSwapFee failure: transfer amtB of tokenB from accountB to accountA');
        
        return true;
    }
}