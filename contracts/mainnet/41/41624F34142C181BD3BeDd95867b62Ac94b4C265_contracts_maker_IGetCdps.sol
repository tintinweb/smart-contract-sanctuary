// SPDX-License-Identifier: MIT
// Address: 0x36a724Bd100c39f0Ea4D3A20F7097eE01A8Ff573
pragma solidity >=0.6.0 <0.7.0;

interface IGetCdps {
    function getCdpsAsc(address manager, address guy)
        external
        view
        returns (
            uint256[] memory ids,
            address[] memory urns,
            bytes32[] memory ilks
        );

    function getCdpsDesc(address manager, address guy)
        external
        view
        returns (
            uint256[] memory ids,
            address[] memory urns,
            bytes32[] memory ilks
        );
}
