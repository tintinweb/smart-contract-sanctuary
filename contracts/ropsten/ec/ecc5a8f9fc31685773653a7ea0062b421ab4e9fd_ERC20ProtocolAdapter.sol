/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;


interface ERC20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);
}

abstract contract ProtocolAdapter {

    function getBalance(address token, address account) public virtual returns (int256);
}


contract ERC20ProtocolAdapter is ProtocolAdapter {

    function getBalance(address token, address account) public view override returns (int256) {
        return int256(ERC20(token).balanceOf(account));
    }
}