/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity ^0.5.16;

contract RegistryLike {
    function proxies(address user) public view returns(address);
}

contract ProxyLike {
    function owner() public view returns(address);
}

contract ScoreLike {
    function getUserScore(bytes32 user) external view returns (uint);
    function getGlobalScore() external view returns (uint);
}

contract GetCDPLike {
    function getCdpsAsc(address manager, address guy) external view returns (uint[] memory ids, address[] memory urns, bytes32[] memory ilks);
}



contract MScore {
    RegistryLike constant REGISTRY_PROXY = RegistryLike(0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4);
    ScoreLike constant JAR_CONNECTOR = ScoreLike(0xf10Bb2Ca172249C715E4F9eE7776b2C8C31aaA69);
    GetCDPLike constant GET_CDP = GetCDPLike(0x36a724Bd100c39f0Ea4D3A20F7097eE01A8Ff573);
    address constant BCDP_MANAGER = address(0x3f30c2381CD8B917Dd96EB2f1A4F96D91324BBed);
    uint constant SCALING_FACTOR = 24 * 60 * 60 * 1000;
    
    function balanceOf(address user) external view returns(uint) {
        address proxy = REGISTRY_PROXY.proxies(user);
        if(proxy == address(0)) return 0;
        if(ProxyLike(proxy).owner() != user) return 0;
        
        (uint[] memory cdps,,) = GET_CDP.getCdpsAsc(BCDP_MANAGER, proxy);
        if(cdps.length == 0) return 0;
        
        return JAR_CONNECTOR.getUserScore(bytes32(cdps[0])) / SCALING_FACTOR;
    }
    
    function totalSupply() external view returns(uint) {
        return JAR_CONNECTOR.getGlobalScore() / SCALING_FACTOR;
    }
    
}