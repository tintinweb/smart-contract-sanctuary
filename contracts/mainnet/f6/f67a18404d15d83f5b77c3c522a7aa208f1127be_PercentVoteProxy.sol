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

interface PctPool {
    function balanceOf(address) external view returns (uint256);
}

contract PercentVoteProxy {
    // PCT/WETH BPT token
    IERC20 public constant votes = IERC20(
        0xEB85B2E12320a123d447Ca0dA26B49E666b799dB
    );

    // Percent's pool contract
    PctPool public constant pctPool = PctPool(
        0x23b53026187626Ed8488e119767ACB2Fe5F8de4e
    );

    // Using 9 decimals as we're square rooting the votes
    function decimals() external pure returns (uint8) {
        return uint8(9);
    }

    function name() external pure returns (string memory) {
        return "Percent Vote";
    }

    function symbol() external pure returns (string memory) {
        return "PCT V";
    }

    function totalSupply() external view returns (uint256) {
        return sqrt(votes.totalSupply());
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return sqrt(pctPool.balanceOf(_voter));
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