/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.4.25;
contract ERC20 {
    function transfer(address _recipient, uint256 amount) public;
}       
contract Erc20MultiTransfer {
    function erc20MultiTransfer(ERC20 token, address[] _addresses, uint256 amount) public {
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer(_addresses[i], amount);
        }
    }
}