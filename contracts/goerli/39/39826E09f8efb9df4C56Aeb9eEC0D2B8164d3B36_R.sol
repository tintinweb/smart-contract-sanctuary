// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMint {
    function mint() external;
}
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract R {
    function mint1(address _address) external {
        uint256 before = IERC20(_address).balanceOf(address(this));
        IMint(_address).mint();
        uint256 after1 = IERC20(_address).balanceOf(address(this));
        require(after1-before==1000**18);
    }
}