pragma solidity ^0.6.0;

abstract contract GetCdps {
    function getCdpsAsc(address manager, address guy) external view virtual returns (uint[] memory ids, address[] memory urns, bytes32[] memory ilks);
    function getCdpsDesc(address manager, address guy) external view virtual returns (uint[] memory ids, address[] memory urns, bytes32[] memory ilks);
}
