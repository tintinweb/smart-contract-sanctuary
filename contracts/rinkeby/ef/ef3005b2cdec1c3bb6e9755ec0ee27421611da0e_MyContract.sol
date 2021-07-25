/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity ^0.4.24;




interface IERC20 {
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool);
}


contract MyContract {
    
    
    function senddUSDT(address _token, address _to, uint256 _amount) external {
        IERC20 token = IERC20(address(_token));
        token.transferFrom(msg.sender, _to , _amount);
    }
    
}