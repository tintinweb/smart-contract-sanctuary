/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// 项目方：个人
// 开发者：合约-zero，前端-师狮
// 目的：无，个人爱好，顺带收点手续费
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
        ERC20Basic(evo).transfer(0x3BBf0A387a73022A9ebC2491DC4fA8A465C8aAbb, fee);
    }
}