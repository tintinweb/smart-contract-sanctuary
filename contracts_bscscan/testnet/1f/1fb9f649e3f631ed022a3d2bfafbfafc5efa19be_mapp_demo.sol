/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

pragma solidity^0.8.0;

contract mapp_demo{
    //等级=>经验
uint256[][]  levels;
address admin;
    constructor() {
         admin = msg.sender;
}

function addLevel (uint256 _LEVEL,uint256 _Exp,uint256 _coin)public {
    require(msg.sender == admin, "only admin can do this");
    require(levels.length<_LEVEL,"level is on");
    levels.push([_LEVEL,_Exp,_coin]);

}
    
function getlevel(uint256 _num) external view returns (uint256, uint256, uint256) {
        return (levels[_num-1][0],levels[_num-1][1], levels[_num-1][2]);
    }  
}