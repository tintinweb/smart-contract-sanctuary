/**
 *Submitted for verification at Etherscan.io on 2020-06-30
*/

pragma solidity 0.6.10;
contract Flag {

    bool public flag;
    address governor = 0x81dCc6246Fe261035FFeE91CD975FAf3D3f3375F;
    
    function setFlag(bool _flag) external {
        require(msg.sender == governor);
        flag = _flag;
    }
}