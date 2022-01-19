/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external;
}

interface FeeDistributor {
    function claim(address addr) external returns (uint256);

    function token() external view returns (address);
}

interface VE {
    function deposit_for(address addr, uint256 value) external;
}

interface Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

interface SquidStakingHelper {
    function stake(uint256 _amount) external;
}

interface wrappedsSquid {
    function wrapFromsSQUID(uint256 _amount) external returns (uint256);
}

contract FeeLockHelper {
    FeeDistributor public constant wsSquidFeeDistributor =
        FeeDistributor(0xF3bC8fabcFC368B52ec18016d6cA8ab8967c550A);
    FeeDistributor public constant wethFeeDistributor =
        FeeDistributor(0x008EB46CdC6651eeE592eE23fe4b121dAEBfbb18);
    VE public constant vewsSquid =
        VE(0x58807E624b9953C2279E0eFae5EDcf9C7DA08c7B);
    Router public constant sushiSwapRouter =
        Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    SquidStakingHelper public constant squidStakingHelper =
        SquidStakingHelper(0x3eC8d9C851552b8917182F39F6014e14e6EE0BfC);
    address public constant wsSquid =
        0x3b1388eB39c72D2145f092C01067C02Bb627d4BE;
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant squid = 0x21ad647b8F4Fe333212e735bfC1F36B4941E6Ad2;
    address public constant sSquid = 0x9d49BfC921F36448234b0eFa67B5f91b3C691515;

    function claimAndLockWsSquid() external {
        uint256 wsSquidClaimed = wsSquidFeeDistributor.claim(msg.sender);
        if (wsSquidClaimed > 0) {
            vewsSquid.deposit_for(msg.sender, wsSquidClaimed);
        }
    }

    function claimWethAndswapForvewsSquid() external {
        uint256 sSquidAmount = _claimWethAndSwapForsSquid(false);
        if (sSquidAmount > 0) {
            IERC20(sSquid).approve(address(wsSquid), sSquidAmount);
            uint256 wrappedAmount = wrappedsSquid(wsSquid).wrapFromsSQUID(
                sSquidAmount
            );
            IERC20(wsSquid).transfer(msg.sender, wrappedAmount);
            vewsSquid.deposit_for(msg.sender, wrappedAmount);
        }
    }

    function claimWethAndSwapForsSquid() external {
        _claimWethAndSwapForsSquid(true);
    }

    function _claimWethAndSwapForsSquid(bool sendsSquidToUser)
        internal
        returns (uint256 sSquidAmount)
    {
        uint256 wethClaimed = wethFeeDistributor.claim(msg.sender);
        IERC20(weth).transferFrom(msg.sender, address(this), wethClaimed);
        if (wethClaimed > 0) {
            address[] memory paths = new address[](2);
            paths[0] = weth;
            paths[1] = squid;
            uint256 squidAmountOutMin = (sushiSwapRouter.getAmountsOut(
                wethClaimed,
                paths
            )[1] * 99) / 100; // 1% slippage
            IERC20(weth).approve(address(sushiSwapRouter), wethClaimed);
            uint256 squidAmountReceived = sushiSwapRouter
                .swapExactTokensForTokens(
                    wethClaimed,
                    squidAmountOutMin,
                    paths,
                    address(this),
                    block.timestamp
                )[1];
            IERC20(squid).approve(
                address(squidStakingHelper),
                squidAmountReceived
            );
            squidStakingHelper.stake(squidAmountReceived);
            sSquidAmount = squidAmountReceived;
            if (sendsSquidToUser) {
                IERC20(sSquid).transfer(msg.sender, sSquidAmount);
            }
        }
    }
}