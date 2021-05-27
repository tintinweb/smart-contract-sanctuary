/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity 0.5.6;


interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract Wallet {
    address internal token = 0xbD62253c8033F3907C0800780662EaB7378a4B96;
    address internal hotWallet = 0xa3601967B0c3180b7C2631638dea69eafA956475;

    constructor() public {
        // send all tokens from this contract to hotwallet
        IERC20(token).transfer(
            hotWallet,
            IERC20(token).balanceOf(address(this))
        );

    }
}