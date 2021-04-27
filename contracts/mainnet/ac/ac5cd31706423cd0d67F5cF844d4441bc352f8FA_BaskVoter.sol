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

    function balanceOf(address _voter) external view returns (uint256) {
        // BASK/ETH is pool id 2
        (uint256 _stakedEthBaskSlpAmount, ) = chef.userInfo(2, _voter);
        uint256 ethBaskSlpAmount = baskEthSLP.balanceOf(_voter);
        uint256 bareBaskAmount = bask.balanceOf(_voter);

        // XBASK
        uint256 xbaskBaskAmount = xbask.getRatio(xbask.balanceOf(_voter));

        uint256 votePower =
            getBaskAmountFromSLP(_stakedEthBaskSlpAmount)
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