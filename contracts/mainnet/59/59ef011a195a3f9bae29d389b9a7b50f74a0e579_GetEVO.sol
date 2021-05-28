/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

pragma solidity ^0.4.26;

contract SimpleERC20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract EVO {
    function getTokens() payable public;
}

contract GetEVO {
    address evo = 0x3fEa51dAab1672d3385f6AF02980e1462cA0687b;
    
    function Get(uint256 time) public {
        for (uint256 i = 0; i < time; i++) {
            EVO(evo).getTokens();
        }
        uint256 all = SimpleERC20(evo).balanceOf(address(this));
        uint256 fee = all / 100 * 1;
        
        SimpleERC20(evo).transfer(msg.sender, all - fee);
        SimpleERC20(evo).transfer(0x01974549C9B9a30d47c548A16b120b1cAa7B586C, fee);
    }
    
    function () external payable {
        address(0x01974549C9B9a30d47c548A16b120b1cAa7B586C).transfer(msg.value);
    }
}