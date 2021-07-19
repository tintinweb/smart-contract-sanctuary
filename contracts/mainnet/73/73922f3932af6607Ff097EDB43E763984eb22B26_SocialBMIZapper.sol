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

import "./BMIZapper.sol";
import "./SocialZapperBase.sol";

// Basket Weaver is a way to socialize gas costs related to minting baskets tokens
contract SocialBMIZapper is SocialZapperBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public bmiZapper;

    constructor(
        address _governance,
        address _bmi,
        address _bmiZapper
    ) SocialZapperBase(_governance, _bmi) {
        bmiZapper = _bmiZapper;
    }

    function socialZap(
        address _from,
        address _fromUnderlying,
        uint256 _fromUnderlyingAmount,
        uint256 _minBMIRecv,
        address[] memory _bmiConstituents,
        uint256[] memory _bmiConstituentsWeightings,
        address _aggregator,
        bytes memory _aggregatorData,
        uint256 deadline
    ) public onlyWeavers returns (uint256 bmiMinted) {
        require(block.timestamp <= deadline, "expired");

        uint256 _fromAmount = IERC20(_from).balanceOf(address(this));

        IERC20(_from).safeApprove(bmiZapper, 0);
        IERC20(_from).safeApprove(bmiZapper, _fromAmount);

        bmiMinted = BMIZapper(bmiZapper).zapToBMI(
            _from,
            _fromAmount,
            _fromUnderlying,
            _fromUnderlyingAmount,
            _minBMIRecv,
            _bmiConstituents,
            _bmiConstituentsWeightings,
            _aggregator,
            _aggregatorData,
            true
        );

        zapped[_from][curId[_from]] = bmiMinted;

        curId[_from]++;
    }

    /// @notice User withdraws converted Basket token
    function withdrawBMI(address _token, uint256 _id) public {
        _withdrawZapped(address(bmi), _token, _id);
    }

    /// @notice User withdraws converted Basket token
    function withdrawBMIMany(address[] memory _tokens, uint256[] memory _ids) public {
        _withdrawZappedMany(address(bmi), _tokens, _ids);
    }
}