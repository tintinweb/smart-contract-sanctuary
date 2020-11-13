// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

interface IDSProxy {
    function authority() external view returns (address);

    function cache() external view returns (address);

    function execute(address _target, bytes calldata _data)
        external
        payable
        returns (bytes memory response);

    function execute(bytes calldata _code, bytes calldata _data)
        external
        payable
        returns (address target, bytes memory response);

    function owner() external view returns (address);

    function setAuthority(address authority_) external;

    function setCache(address _cacheAddr) external returns (bool);

    function setOwner(address owner_) external;
}
