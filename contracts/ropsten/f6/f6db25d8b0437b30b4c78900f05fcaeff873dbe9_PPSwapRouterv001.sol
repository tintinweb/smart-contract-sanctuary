/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-04
*/

pragma solidity =0.5.0;

contract PPSwapRouterv001{
    
    event Transfer(address indexed accountA, address indexed accountB, address indexed tokenA, uint amtA);
    
    
    /*
     * Step 1: approval from accountA
     * Step 2: approval from accountB
     * Step 3: call swapNoSwapfee Approval 
     *    *
     */
     // approve this contract, address(this), be a spender of the caller, msg.sender,  for token with amt
     // this is to be called by the ownerAccount
    function safeApprove(address token, uint amt) external returns (bool){
        
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, address(this), amt));
        
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'swapNoSwapfee failure: approval of spending tokens fails');
        
        return true;
    }
    
    
    function swapNoSwapfee(address accountA, address accountB, address tokenA, address tokenB, uint amtA, uint amtB) external returns(bool){
        // transfer amtA of tokenA from accountA to accountB
        (bool success, bytes memory data) = tokenA.call(abi.encodeWithSelector(0x23b872dd, accountA, accountB, amtA));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'swapNoSwapfee failure: transfer amtA of tokenA from accountA to accountB');
        
         // transfer amtB of tokenB from accountB to accountA
        (success, data) = tokenB.call(abi.encodeWithSelector(0x23b872dd, accountB, accountA, amtB));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'swapNoSwapfee failure: transfer amtB of tokenB from accountB to accountA');
        
        return true;
    }
}