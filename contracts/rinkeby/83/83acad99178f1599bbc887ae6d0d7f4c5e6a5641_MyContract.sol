/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

pragma solidity ^0.4.24;




interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}


contract MyContract {
    
    function sendDETH(address _to, uint256 _amount) external {
        IERC20 deth = IERC20(address(0x885072b7447A15E1CAc973F0702A4bcc2Ddb97E6));
        deth.transfer(_to, _amount);
    }
    
}