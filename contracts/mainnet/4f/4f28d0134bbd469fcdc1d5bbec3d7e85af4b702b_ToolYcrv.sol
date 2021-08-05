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

interface ICurveFi_4 {
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;
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

contract ToolYcrv {
    using SafeMath for uint256;

    address public constant yDeposit = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;
    address public constant yCrv = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;
    address public constant bYcrv = 0x50DFDdA590eA1C38A6F041A4F383818C9caF3b16;

    // stablecoins
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant tusd = 0x0000000000085d4780B73119b644AE5ecd22b376;

    event Recycled(address indexed user, uint256 sentDai, uint256 sentUsdc,
        uint256 sentUsdt, uint256 sentTusd, uint256 sentYcrv, uint256 receivedYusd);

    constructor() public {
        IERC20(dai).approve(yDeposit, uint256(- 1));
        IERC20(usdc).approve(yDeposit, uint256(- 1));
        USDT(usdt).approve(yDeposit, uint256(- 1));
        IERC20(tusd).approve(yDeposit, uint256(- 1));
        IERC20(yCrv).approve(bYcrv, uint256(- 1));
    }

    function recycleExactAmounts(address sender, uint256 _dai, uint256 _usdc, uint256 _usdt, uint256 _tusd, uint256 _ycrv) internal {
        if (_dai > 0) {
            IERC20(dai).transferFrom(sender, address(this), _dai);
        }
        if (_usdc > 0) {
            IERC20(usdc).transferFrom(sender, address(this), _usdc);
        }
        if (_usdt > 0) {
            USDT(usdt).transferFrom(sender, address(this), _usdt);
        }
        if (_tusd > 0) {
            IERC20(tusd).transferFrom(sender, address(this), _tusd);
        }
        if (_ycrv > 0) {
            IERC20(yCrv).transferFrom(sender, address(this), _ycrv);
        }

        uint256[4] memory depositAmounts = [_dai, _usdc, _usdt, _tusd];
        if (_dai.add(_usdc).add(_usdt).add(_tusd) > 0) {
            ICurveFi_4(yDeposit).add_liquidity(depositAmounts, 0);
        }

        uint256 ycrvBalance = IERC20(yCrv).balanceOf(address(this));
        if (ycrvBalance > 0) {
            IVault(bYcrv).deposit(ycrvBalance);
        }

        uint256 _bYcrv = IERC20(bYcrv).balanceOf(address(this));
        if (_bYcrv > 0) {
            IERC20(bYcrv).transfer(sender, _bYcrv);
        }

        assert(IERC20(bYcrv).balanceOf(address(this)) == 0);

        emit Recycled(sender, _dai, _usdc, _usdt, _tusd, _ycrv, _bYcrv);
    }

    function recycle() external {
        uint256 _dai = Math.min(IERC20(dai).balanceOf(msg.sender), IERC20(dai).allowance(msg.sender, address(this)));
        uint256 _usdc = Math.min(IERC20(usdc).balanceOf(msg.sender), IERC20(usdc).allowance(msg.sender, address(this)));
        uint256 _usdt = Math.min(IERC20(usdt).balanceOf(msg.sender), IERC20(usdt).allowance(msg.sender, address(this)));
        uint256 _tusd = Math.min(IERC20(tusd).balanceOf(msg.sender), IERC20(tusd).allowance(msg.sender, address(this)));
        uint256 _ycrv = Math.min(IERC20(yCrv).balanceOf(msg.sender), IERC20(yCrv).allowance(msg.sender, address(this)));

        recycleExactAmounts(msg.sender, _dai, _usdc, _usdt, _tusd, _ycrv);
    }


    function recycleExact(uint256 _dai, uint256 _usdc, uint256 _usdt, uint256 _tusd, uint256 _ycrv) external {
        recycleExactAmounts(msg.sender, _dai, _usdc, _usdt, _tusd, _ycrv);
    }
}