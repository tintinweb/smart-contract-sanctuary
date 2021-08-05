/**
 *Submitted for verification at Etherscan.io on 2020-11-18
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

contract PickleVoteProxyV2 {
    // PICKLE token
    IERC20 public constant votes = IERC20(
        0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5
    );

    // Pickle's staking rewards contract
    StakingRewards public constant stakingRewards = StakingRewards(
        0xa17a8883dA1aBd57c690DF9Ebf58fC194eDAb66F
    );

    // Using 9 decimals as we're square rooting the votes
    function decimals() external pure returns (uint8) {
        return uint8(9);
    }

    function name() external pure returns (string memory) {
        return "PICKLEs In The Citadel V2";
    }

    function symbol() external pure returns (string memory) {
        return "PICKLE C";
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