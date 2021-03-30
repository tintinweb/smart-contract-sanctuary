/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface Lib {
    function safeTransfer(address token, address to, uint256 value) external;
}

contract TestLib {
    
    function Transfer(address lib, address token, address to, uint256 value) public {
        lib.delegatecall(abi.encodeWithSignature("safeTransfer(address,address,uint256)", token, to, value));
    }

}