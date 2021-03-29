/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity ^0.8.0;

interface IWET {
    function accumulated(uint256 id) external view returns (uint256);
}

interface IWaifus {
    function balanceOf(address owner) external view returns (uint256);
    function tokenNameByIndex(uint256 id) external view returns (string memory);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract Accoomulator {
  IWET WET = IWET(0x76280AF9D18a868a0aF3dcA95b57DDE816c1aaf2);
  IWaifus WAIFUS = IWaifus(0x2216d47494E516d8206B70FCa8585820eD3C4946);
    
    struct WaifuInfo {
        uint256 tokenId;
        uint256 wetAccumulated;
        string name;
    }
  function accoomulatedWET(uint256[] calldata ids) external view returns (uint256[] memory) {
    uint256[] memory wetAccumulated = new uint256[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
    }
    return wetAccumulated;
  }
  
  function accoomulatedNames(uint256[] calldata ids) external view returns (string[] memory) {
    string[] memory namesAccumulated = new string[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
    }
    return namesAccumulated;
  }
  
  function accoomulatedTokenIdsOwned(address owner) external view returns (WaifuInfo[] memory) {
    uint256 waifusOwned = WAIFUS.balanceOf(owner);
    
    WaifuInfo[] memory tokenInfos = new WaifuInfo[](waifusOwned);
    for (uint256 i = 0; i < waifusOwned; i++) {
      uint256 id = WAIFUS.tokenOfOwnerByIndex(owner, i);
      uint256 wetAccumulated = WET.accumulated(id);
      string memory name = WAIFUS.tokenNameByIndex(id);
      tokenInfos[i] = WaifuInfo(id, wetAccumulated, name);
    }
    return tokenInfos;
  }
}