/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity >=0.7.0 <0.9.0;

interface evo {
    function getTokens() external;
    function transfer(address to, uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256);
}
contract miner {
    address public owner;
    address public EVO;
    constructor() public {owner = msg.sender; EVO = 0x3fEa51dAab1672d3385f6AF02980e1462cA0687b;}
    function mineNow(uint256 times) public {
        for(uint256 i=0;i<times;i++) EVO.call{value:0,gas:gasleft()}("");
    }
    function withdraw() public {
        evo(EVO).transfer(owner,evo(EVO).balanceOf(address(this)));
    }
}