// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract PercentQuadraticVoteProxy {
    // PCT
    IERC20 public constant pct = IERC20(
        0xbc16da9df0A22f01A16BC0620a27e7D6d6488550
    );

    // Using 9 decimals as we're square rooting the votes
    function decimals() external pure returns (uint8) {
        return uint8(9);
    }

    function name() external pure returns (string memory) {
        return "Percent Quadratic Vote";
    }

    function symbol() external pure returns (string memory) {
        return "PCT QV";
    }

    function totalSupply() external view returns (uint256) {
        return sqrt(pct.totalSupply());
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return sqrt(pct.balanceOf(_voter));
    }

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    constructor() public {}
}