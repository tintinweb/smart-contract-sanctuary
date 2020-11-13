// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

interface ISmartRightsCertify {
    function certifyHash(address _owner, bytes32 _hash) external;
    function certifyHash(bytes32 _hash) external;
    function getHashOwner(bytes32 _hash) external view returns(address);
    function addToWhitelist(address user) external;
}