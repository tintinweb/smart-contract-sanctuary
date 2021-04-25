/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

pragma solidity 0.6.12;
interface unipair {
function burn(address to) external returns (uint amount0, uint amount1);
function transferFrom(address from, address to, uint value) external returns (bool);}
contract burner {
    function removeLiquidity(
        unipair pair,
        address to,
        uint256 amount
    ) external {
        pair.transferFrom(msg.sender, address(pair), amount); // send `amount` to pair
        pair.burn(to); // burn against `pair` to redeem liquidity
    }
}