/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

pragma solidity ^0.5.0;

// 5/1/2021 
contract PPSwapRouterv002{
    address public trustAccount; 
    event Transfer(address indexed accountA, address indexed accountB, address indexed tokenA, uint amtA);

     constructor() public{
         trustAccount = msg.sender;
     }
     
    function safeApprove(address token, uint amt) external returns (bool){
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, trustAccount, amt));
        
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'swapNoSwapfee failure: approval of spending tokens fails');
        
        return true;
    }
    
    
    function swapNoSwapfee(address accountA, address accountB, address tokenA, address tokenB, uint amtA, uint amtB) external returns(bool){
        require(trustAccount == msg.sender, 'swapNoSwapfee: can only be called by the trust account.');
        
        // transfer amtA of tokenA from accountA to accountB
        (bool success, bytes memory data) = tokenA.call(abi.encodeWithSelector(0x23b872dd, accountA, accountB, amtA));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'swapNoSwapfee failure: transfer amtA of tokenA from accountA to accountB');
        
         // transfer amtB of tokenB from accountB to accountA
        (success, data) = tokenB.call(abi.encodeWithSelector(0x23b872dd, accountB, accountA, amtB));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'swapNoSwapfee failure: transfer amtB of tokenB from accountB to accountA');
        
        return true;
    }
}