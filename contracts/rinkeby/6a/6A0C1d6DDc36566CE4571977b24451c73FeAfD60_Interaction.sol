/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

pragma solidity >=0.4.24 <0.6.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Interaction {
    IERC20 private _token= IERC20(0x21F62f22F61913eB77feb9533B8F6e3634B4Fe08);

    function sendERC20TokeToDnividends(address sender, address recipient, uint256 amount) public returns (bool) {
        _token.transferFrom(sender, recipient, amount);
        return true;
    }
}