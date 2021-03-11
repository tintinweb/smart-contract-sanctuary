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
    RegistryLike constant REGISTRY_PROXY = RegistryLike(0x64A436ae831C1672AE81F674CAb8B6775df3475C);
    ScoreLike constant JAR_CONNECTOR = ScoreLike(0x82ac7A2D5D9C473B680263B4D7233fAF92a3795e);
    GetCDPLike constant GET_CDP = GetCDPLike(0x592301a23d37c591C5856f28726AF820AF8e7014);
    address constant BCDP_MANAGER = address(0x0470000Ff279d3951F0Fb4893443C25EA4E0ec69);
    uint constant SCALING_FACTOR = 24 * 60 * 60 * 1000;
    
    function balanceOf(address user) external view returns(uint) {
        address proxy = REGISTRY_PROXY.proxies(user);
        if(proxy == address(0)) return 0;
        if(ProxyLike(proxy).owner() != user) return 0;
        
        (uint[] memory cdps,,) = GET_CDP.getCdpsAsc(BCDP_MANAGER, proxy);
        if(cdps.length == 0) return 0;
        
        return JAR_CONNECTOR.getUserScore(bytes32(cdps[0]));
    }
    
    function totalSupply() external view returns(uint) {
        return JAR_CONNECTOR.getGlobalScore() / SCALING_FACTOR;
    }
    
}