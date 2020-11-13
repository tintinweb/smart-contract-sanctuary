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
interface IUniswapV2Pair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface MasterChef {
    function userInfo(uint256, address)
    external
    view
    returns (uint256, uint256);
}

contract YaxisVoteProxy {
    // ETH/YAX token
    IUniswapV2Pair public constant yaxEthUniswapV2Pair = IUniswapV2Pair(
        0x1107B6081231d7F256269aD014bF92E041cb08df
    );
    // YAX token
    IERC20 public constant yax = IERC20(
        0xb1dC9124c395c1e97773ab855d66E879f053A289
    );

    // YaxisChef contract
    MasterChef public constant chef = MasterChef(
        0xbD17B1ce622d73bD438b9E658acA5996dc394b0d
    );

    // Pool 6 is the ETH/YAX pool
    uint256 public constant pool = uint256(6);

    // Using 9 decimals as we're square rooting the votes
    function decimals() external pure returns (uint8) {
        return uint8(9);
    }

    function name() external pure returns (string memory) {
        return "YAXIS Vote Power";
    }

    function symbol() external pure returns (string memory) {
        return "YAX VP";
    }

    function totalSupply() external view returns (uint256) {
        (uint256 _yaxAmount,,) = yaxEthUniswapV2Pair.getReserves();
        return sqrt(yax.totalSupply()) + sqrt((2 * _yaxAmount * yaxEthUniswapV2Pair.balanceOf(address(chef))) / yaxEthUniswapV2Pair.totalSupply());
    }
    function balanceOf(address _voter) external view returns (uint256) {
        (uint256 _stakeAmount, ) = chef.userInfo(pool, _voter);
        (uint256 _yaxAmount,, ) = yaxEthUniswapV2Pair.getReserves();
        return sqrt(yax.balanceOf(_voter)) + sqrt((2 * _yaxAmount * _stakeAmount) / yaxEthUniswapV2Pair.totalSupply());
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