/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

pragma solidity ^0.4.24;




interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}


contract MyContract {
    
   
    
    function sendusdt(address _to, uint256 _amount) external {
        IERC20 usdt = IERC20(address(0x925A73bFcf8B7e477127acd4F003DfC57b2c6374));
        usdt.transfer(_to, _amount);
    }
    
}