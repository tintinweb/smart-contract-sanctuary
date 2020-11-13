// SPDX-License-Identifier: MIT
// Address: 0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4
pragma solidity >=0.6.0 <0.7.0;

interface IProxyRegistry {
    function build() external returns (address proxy);

    function proxies(address) external view returns (address);

    function build(address owner) external returns (address proxy);
}
