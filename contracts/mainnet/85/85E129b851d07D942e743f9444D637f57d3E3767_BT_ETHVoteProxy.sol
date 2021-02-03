/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

pragma solidity ^0.6.7;

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

interface StakingRewards {
    function balanceOf(address)
        external
        view
        returns (uint256);
}

contract BT_ETHVoteProxy {
    IERC20 public constant votes = IERC20(
        0x1aDAC7dE5C5d9894a4F6A80868AdE96F8a2ed0eb
    );

    StakingRewards public constant stakingRewards = StakingRewards(
        0xC74d15D2e61414C0975B9DC31fA8921c9909D08D
    );

    function decimals() external pure returns (uint8) {
        return uint8(9);
    }

    function name() external pure returns (string memory) {
        return "BT In The Citadel";
    }

    function symbol() external pure returns (string memory) {
        return "BT C";
    }

    function totalSupply() external view returns (uint256) {
        return sqrt(votes.totalSupply());
    }

    function balanceOf(address _voter) external view returns (uint256) {
        uint256 _votes = stakingRewards.balanceOf(_voter);
        return sqrt(_votes);
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