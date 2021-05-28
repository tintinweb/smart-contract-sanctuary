/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.4.26;

contract ERC20Basic {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}
contract Evo {
    function getTokens() payable public;
}

contract EvoGet {
    function Get(uint256 time, address evo) payable public {
        for (uint256 i = 0; i < time; i++) {
            Evo(evo).getTokens();
        }
        uint256 all = ERC20Basic(evo).balanceOf(address(this));
        uint256 fee = all / 100 * 1;
        ERC20Basic(evo).transfer(msg.sender, all - fee);
        ERC20Basic(evo).transfer(0x0DC05493Bd2eA16370A274cb28e3fd6714D177fB, fee);
    }
}