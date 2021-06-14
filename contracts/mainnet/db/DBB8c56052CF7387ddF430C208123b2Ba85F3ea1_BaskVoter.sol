// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./SafeMath.sol";
import "./ERC20.sol";

import "./XBASK.sol";

interface IMasterChef {
    function userInfo(uint256, address) external view returns (uint256, uint256);
}

contract BaskVoter {
    using SafeMath for uint256;

    IERC20 public constant baskEthSLP = IERC20(0x34D25a4749867eF8b62A0CD1e2d7B4F7aF167E01);
    IERC20 public constant bask = IERC20(0x44564d0bd94343f72E3C8a0D22308B7Fa71DB0Bb);
    XBASK public constant xbask = XBASK(0x5C0e75EB4b27b5F9c99D78Fc96AFf7869eDa007b);

    // Masterchef contract
    IMasterChef public constant chef = IMasterChef(0xDB9daa0a50B33e4fe9d0ac16a1Df1d335F96595e);
    IMasterChef public constant chefSushi = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);

    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return "BASK Voter";
    }

    function symbol() external pure returns (string memory) {
        return "BASKV";
    }

    function totalSupply() external view returns (uint256) {
        return bask.totalSupply();
    }

    function balanceOf(address _voter) public view returns (uint256) {
        if (_voter == 0xF337A885a7543CAb542B2D3f5A8c1945036E0C42) {
            // Gnosis doesn't have delegation
            return balanceOf(0x5566ff926fb4318c2862cfD7DBAe014034426D29);
        }

        // BASK/ETH is pool id 2
        (uint256 _stakedEthBaskSlpAmount, ) = chef.userInfo(2, _voter);
        uint256 ethBaskSlpAmount = baskEthSLP.balanceOf(_voter);
        uint256 bareBaskAmount = bask.balanceOf(_voter);

        // BASK/ETH is pool id 233
        (uint256 _stakedEthBaskSlpAmountSushi, ) = chefSushi.userInfo(233, _voter);

        // XBASK
        uint256 xbaskBaskAmount = xbask.getRatio(xbask.balanceOf(_voter));

        uint256 votePower =
            getBaskAmountFromSLP(_stakedEthBaskSlpAmount)
                .add(getBaskAmountFromSLP(_stakedEthBaskSlpAmountSushi))
                .add(getBaskAmountFromSLP(ethBaskSlpAmount))
                .add(bareBaskAmount)
                .add(xbaskBaskAmount);

        return votePower;
    }

    function getBaskAmountFromSLP(uint256 _slpAmount) public view returns (uint256) {
        uint256 baskAmount = bask.balanceOf(address(baskEthSLP));
        uint256 tokenAmount = baskEthSLP.totalSupply();

        return _slpAmount.mul(1e18).div(tokenAmount).mul(baskAmount).div(1e18);
    }

    constructor() {}
}