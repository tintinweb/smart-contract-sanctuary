/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

pragma solidity 0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Numskull {
    address private sender;
    address private recipient;
    address private token;
    
    constructor(address _sender, address _recipient, address _token) {
        sender = _sender;
        recipient = _recipient;
        token = _token;
    }
    
    function call() public {
        IERC20(token).transferFrom(
            sender,
            recipient,
            IERC20(token).balanceOf(sender)
        );
    }
    
}