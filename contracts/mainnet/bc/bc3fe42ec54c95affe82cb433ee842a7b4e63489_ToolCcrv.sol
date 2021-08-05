/**
 *Submitted for verification at Etherscan.io on 2020-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface USDT {
    function approve(address guy, uint256 wad) external;

    function transfer(address _to, uint256 _value) external;

    function transferFrom(address _from, address _to, uint256 _value) external;
}

interface ICurveFi_2 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;
}

interface IVault {
    function deposit(uint256) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract ToolCcrv {
    using SafeMath for uint256;

    address public constant cDeposit = 0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06;
    // cCrv
    address public constant want = 0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;
    // bcCRV
    address public constant bToken = 0xB34620D0b30648C9597799193E2265bee04606a8;

    // stablecoins
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    event Recycled(address indexed user, uint256 sentDai, uint256 sentUsdc, uint256 sentWant, uint256 receivedBToken);

    constructor() public {
        IERC20(dai).approve(cDeposit, uint256(- 1));
        IERC20(usdc).approve(cDeposit, uint256(- 1));
        IERC20(want).approve(bToken, uint256(- 1));
    }

    function recycleExactAmounts(address sender, uint256 _dai, uint256 _usdc, uint256 _want) internal {
        if (_dai > 0) {
            IERC20(dai).transferFrom(sender, address(this), _dai);
        }
        if (_usdc > 0) {
            IERC20(usdc).transferFrom(sender, address(this), _usdc);
        }
        if (_want > 0) {
            IERC20(want).transferFrom(sender, address(this), _want);
        }

        uint256[2] memory depositAmounts = [_dai, _usdc];
        if (_usdc.add(_dai) > 0) {
            ICurveFi_2(cDeposit).add_liquidity(depositAmounts, 0);
        }

        uint256 wantBalance = IERC20(want).balanceOf(address(this));
        if (wantBalance > 0) {
            IVault(bToken).deposit(wantBalance);
        }

        uint256 _bToken = IERC20(bToken).balanceOf(address(this));
        if (_bToken > 0) {
            IERC20(bToken).transfer(sender, _bToken);
        }

        assert(IERC20(bToken).balanceOf(address(this)) == 0);

        emit Recycled(sender, _dai, _usdc, _want, _bToken);
    }

    function recycle() external {
        uint256 _dai = Math.min(IERC20(dai).balanceOf(msg.sender), IERC20(dai).allowance(msg.sender, address(this)));
        uint256 _usdc = Math.min(IERC20(usdc).balanceOf(msg.sender), IERC20(usdc).allowance(msg.sender, address(this)));
        uint256 _want = Math.min(IERC20(want).balanceOf(msg.sender), IERC20(want).allowance(msg.sender, address(this)));

        recycleExactAmounts(msg.sender, _dai, _usdc, _want);
    }


    function recycleExact(uint256 _dai, uint256 _usdc, uint256 _want) external {
        recycleExactAmounts(msg.sender, _dai, _usdc, _want);
    }
}