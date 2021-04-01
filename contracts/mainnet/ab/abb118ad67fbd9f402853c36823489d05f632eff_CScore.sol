/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity ^0.5.16;

contract ScoreLike {
    function getUserScore(address user) external view returns (uint);
    function getGlobalScore() external view returns (uint);
}


contract CScore {
    ScoreLike constant JAR_CONNECTOR = ScoreLike(0xD24E557762589124D7cFeF90d870DF17C25bFf8a);
    uint constant SCALING_FACTOR = 480000 * 100 * 5944368153772800000000000000000 / 1 ether;    
    
    function balanceOf(address user) external view returns(uint) {
        return JAR_CONNECTOR.getUserScore(user) / SCALING_FACTOR;
    }
    
    function totalSupply() external view returns(uint) {
        return JAR_CONNECTOR.getGlobalScore() / SCALING_FACTOR;
    }
    
}