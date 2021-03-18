// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

import "LibSafeMath.sol";
import "LibBaseAuth.sol";


interface IVokenTB {
    function cap() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function burningPermilleBorder() external view returns (uint16 min, uint16 max);
    function vokenCounter() external view returns (uint256);
    
    function address2voken(address account) external view returns (uint160);
    function balanceOf(address account) external view returns (uint256);
    function vestingOf(address account) external view returns (uint256);
    function availableOf(address account) external view returns (uint256);
    function isBank(address account) external view returns (bool);
    function referrer(address account) external view returns (address payable);
}


interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}


contract VokenTBData is BaseAuth {
    using SafeMath for uint256;

    IUniswapV2Router02 private immutable UniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IVokenTB private immutable VOKEN_TB = IVokenTB(0x1234567a022acaa848E7D6bC351d075dBfa76Dd4);
    address private immutable DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    receive() external payable {}

    function data(address account)
        public
        view
        returns (
            uint256 etherBalance,
            uint256 etherPrice,
            uint256 vokenPrice,

            uint256 cap,
            uint256 totalSupply,
            uint16 burningPermilleMin,
            uint16 burningPermilleMax,

            uint256 vokenCounter,

            uint160 vokenInt,
            uint256 balance,
            uint256 vesting,

            bool isBank,
            address payable referrer
        )
    {
        etherBalance = account.balance;
        etherPrice = _etherPrice();
        vokenPrice = _vokenPrice();

        cap = VOKEN_TB.cap();
        totalSupply = VOKEN_TB.totalSupply();
        (burningPermilleMin, burningPermilleMax) = VOKEN_TB.burningPermilleBorder();

        vokenCounter = VOKEN_TB.vokenCounter();

        vokenInt = VOKEN_TB.address2voken(account);
        balance = VOKEN_TB.balanceOf(account);
        vesting = VOKEN_TB.vestingOf(account);

        isBank = VOKEN_TB.isBank(account);
        referrer = VOKEN_TB.referrer(account);
    }
    
    function _etherPrice()
        private
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = UniswapV2Router02.WETH();
        path[1] = DAI;

        return UniswapV2Router02.getAmountsOut(1_000_000, path)[1];
    }

    function _vokenPrice()
        private
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = address(VOKEN_TB);
        path[1] = DAI;
        
        return UniswapV2Router02.getAmountsOut(1_000_000, path)[1].mul(1_000_000_000).div(1 ether);
    }
}