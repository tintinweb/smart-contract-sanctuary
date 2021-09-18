/**
 *Submitted for verification at BscScan.com on 2021-09-17
*/

/**
 *Submitted for verification at BscScan.com on 2020-09-14
*/

pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract ClaimToken {

    function claim(IERC20 token, address recipient, uint256 value) external {
        require(token.transfer(recipient, value));
    }


}