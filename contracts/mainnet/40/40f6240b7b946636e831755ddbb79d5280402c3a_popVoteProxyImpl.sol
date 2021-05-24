/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface UniswapV2Pair is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IVoteProxy {
    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _voter) external view returns (uint256);
}

interface IMasterChef {
    function userInfo(uint256, address) external view returns (uint256, uint256);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare
        );
}

contract popVoteProxyImpl is IVoteProxy {
    address public baseToken = 0x7fC3eC3574d408F3b59CD88709baCb42575EBF2b;

    function decimals() public pure virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return IERC20(baseToken).totalSupply();
    }

    function getTokenInPair(
        uint256 lpAmount,
        address token,
        address pair
    ) public view returns (uint256) {
        uint256 supply = UniswapV2Pair(pair).totalSupply();
        (uint112 r0, uint112 r1, ) = UniswapV2Pair(pair).getReserves();
        if (UniswapV2Pair(pair).token0() == token) {
            return (r0 * lpAmount) / supply;
        } else if (UniswapV2Pair(pair).token1() == token) {
            return (r1 * lpAmount) / supply;
        }
        return 0;
    }

    function getTokenInPairMasterChef(
        uint256 pid,
        address chef,
        address user,
        address token,
        address pair
    ) public view returns (uint256) {
        (uint256 amount, ) = IMasterChef(chef).userInfo(pid, user);
        return getTokenInPair(amount, token, pair);
    }

    function getTokenBalanceInPair(
        address user,
        address token,
        address pair
    ) public view returns (uint256) {
        return getTokenInPair(IERC20(pair).balanceOf(user), token, pair);
    }

    function balanceOfDetail(address user) public view virtual returns (uint256[] memory detailBalances) {
        // pop
        detailBalances = new uint256[](3);
        detailBalances[0] = IERC20(baseToken).balanceOf(user);
        // pair pop/weth
        address popWethPair = 0x7E5D0da0f5BA5c24043DcEb0DA78E97dfddCA7Df;
        detailBalances[1] = getTokenBalanceInPair(user, baseToken, popWethPair);

        // mlp pop/weth
        detailBalances[2] = getTokenInPairMasterChef(0, 0x1A13B10C13650eE3C33F0D6488a84CBB8603B47E, user, baseToken, popWethPair);
    }

    function balanceOf(address user) public view virtual override returns (uint256) {
        uint256[] memory detailBalances = balanceOfDetail(user);
        uint256 balance = 0;
        for (uint8 pid = 0; pid < detailBalances.length; ++pid) {
            balance += detailBalances[pid];
        }
        return balance;
    }
}