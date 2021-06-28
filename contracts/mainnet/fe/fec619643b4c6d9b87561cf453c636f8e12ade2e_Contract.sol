/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.6;
interface IERC20ish {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}
contract Contract {
    function random(uint16 floor,uint16 ceil) external view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return (randomHash % ceil) + floor;
    }
    function balanceOf(address token, address hodler) external view returns (uint) {
        uint8 decimals = IERC20ish(token).decimals();
        return 10**decimals / IERC20ish(token).balanceOf(hodler);
    }
    function isContract(address addr) external view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}