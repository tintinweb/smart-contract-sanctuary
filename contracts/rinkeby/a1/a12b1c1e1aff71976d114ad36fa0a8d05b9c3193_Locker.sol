/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Locker {
    event Lock(IERC20 token, address from_address, address to_address, uint256 amount);

    
    constructor() {}

    
    function lock(IERC20 token, address from_address, uint256 amount) public {
        token.transferFrom(from_address, address(this), amount);
        emit Lock(token, from_address, from_address, amount);
    }
    
    function lockFor(IERC20 token, address from_address, address to_address, uint256 amount) public {
        token.transferFrom(from_address, address(this), amount);
        emit Lock(token, from_address, to_address, amount);
    }

}