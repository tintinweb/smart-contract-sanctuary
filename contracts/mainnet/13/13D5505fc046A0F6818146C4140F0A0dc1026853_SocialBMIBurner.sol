// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IATokenV1.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./ILendingPoolV1.sol";
import "./ICompoundLens.sol";
import "./IUniswapV2.sol";
import "./IBasicIssuanceModule.sol";
import "./IOneInch.sol";

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./BMIBurner.sol";
import "./SocialZapperBase.sol";

// Basket Weaver is a way to socialize gas costs related to minting baskets tokens
contract SocialBMIBurner is SocialZapperBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public bmiBurner;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor(
        address _governance,
        address _bmi,
        address _bmiBurner
    ) SocialZapperBase(_governance, _bmi) {
        bmiBurner = _bmiBurner;
    }

    function socialBurn(
        uint256 _minRecv,
        uint256 deadline
    ) public onlyWeavers returns (uint256) {
        require(block.timestamp <= deadline, "expired");

        address _from = bmi;
        uint256 _fromAmount = IERC20(_from).balanceOf(address(this));

        IERC20(_from).safeApprove(bmiBurner, 0);
        IERC20(_from).safeApprove(bmiBurner, _fromAmount);

        uint256 bmiBurned = BMIBurner(bmiBurner).burnBMIToUSDC(_fromAmount, _minRecv);

        zapped[_from][curId[_from]] = bmiBurned;

        curId[_from]++;

        return bmiBurned;
    }

    /// @notice User withdraws converted Basket token
    function withdrawUSDC(address _token, uint256 _id) public {
        _withdrawZapped(USDC, _token, _id);
    }

    /// @notice User withdraws converted Basket token
    function withdrawUSDCMany(address[] memory _tokens, uint256[] memory _ids) public {
        _withdrawZappedMany(USDC, _tokens, _ids);
    }
}