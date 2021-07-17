// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.3;

import "./CurveFactory.sol";
import "./Curve.sol";

import "./SafeMath.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

// Simplistic router that assumes USD is the only quote currency for
contract Router {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public factory;

    constructor(address _factory) {
        require(_factory != address(0), "Curve/factory-cannot-be-zeroth-address");

        factory = _factory;
    }

    /// @notice view how much target amount a fixed origin amount will swap for
    /// @param _quoteCurrency the address of the quote currency (usually USDC)
    /// @param _origin the address of the origin
    /// @param _target the address of the target
    /// @param _originAmount the origin amount
    /// @return targetAmount_ the amount of target that will be returned
    function viewOriginSwap(
        address _quoteCurrency,
        address _origin,
        address _target,
        uint256 _originAmount
    ) external view returns (uint256 targetAmount_) {
        // If its an immediate pair then just swap directly on it
        address curve0 = CurveFactory(factory).curves(keccak256(abi.encode(_origin, _target)));
        if (_origin == _quoteCurrency) {
            curve0 = CurveFactory(factory).curves(keccak256(abi.encode(_target, _origin)));
        }
        if (curve0 != address(0)) {
            targetAmount_ = Curve(curve0).viewOriginSwap(_origin, _target, _originAmount);
            return targetAmount_;
        }

        // Otherwise go through the quote currency
        curve0 = CurveFactory(factory).curves(keccak256(abi.encode(_origin, _quoteCurrency)));
        address curve1 = CurveFactory(factory).curves(keccak256(abi.encode(_target, _quoteCurrency)));
        if (curve0 != address(0) && curve1 != address(0)) {
            uint256 _quoteAmount = Curve(curve0).viewOriginSwap(_origin, _quoteCurrency, _originAmount);
            targetAmount_ = Curve(curve1).viewOriginSwap(_quoteCurrency, _target, _quoteAmount);
            return targetAmount_;
        }

        revert("Router/No-path");
    }

    /// @notice swap a dynamic origin amount for a fixed target amount
    /// @param _quoteCurrency the address of the quote currency (usually USDC)
    /// @param _origin the address of the origin
    /// @param _target the address of the target
    /// @param _originAmount the origin amount
    /// @param _minTargetAmount the minimum target amount
    /// @param _deadline deadline in block number after which the trade will not execute
    /// @return targetAmount_ the amount of target that has been swapped for the origin amount
    function originSwap(
        address _quoteCurrency,
        address _origin,
        address _target,
        uint256 _originAmount,
        uint256 _minTargetAmount,
        uint256 _deadline
    ) public returns (uint256 targetAmount_) {
        IERC20(_origin).safeTransferFrom(msg.sender, address(this), _originAmount);

        // If its an immediate pair then just swap directly on it
        address curve0 = CurveFactory(factory).curves(keccak256(abi.encode(_origin, _target)));
        if (_origin == _quoteCurrency) {
            curve0 = CurveFactory(factory).curves(keccak256(abi.encode(_target, _origin)));
        }
        if (curve0 != address(0)) {
            IERC20(_origin).safeApprove(curve0, _originAmount);
            targetAmount_ = Curve(curve0).originSwap(_origin, _target, _originAmount, _minTargetAmount, _deadline);
            IERC20(_target).safeTransfer(msg.sender, targetAmount_);
            return targetAmount_;
        }

        // Otherwise go through the quote currency
        curve0 = CurveFactory(factory).curves(keccak256(abi.encode(_origin, _quoteCurrency)));
        address curve1 = CurveFactory(factory).curves(keccak256(abi.encode(_target, _quoteCurrency)));
        if (curve0 != address(0) && curve1 != address(0)) {
            IERC20(_origin).safeApprove(curve0, _originAmount);
            uint256 _quoteAmount = Curve(curve0).originSwap(_origin, _quoteCurrency, _originAmount, 0, _deadline);

            IERC20(_quoteCurrency).safeApprove(curve1, _quoteAmount);
            targetAmount_ = Curve(curve1).originSwap(
                _quoteCurrency,
                _target,
                _quoteAmount,
                _minTargetAmount,
                _deadline
            );
            IERC20(_target).safeTransfer(msg.sender, targetAmount_);
            return targetAmount_;
        }

        revert("Router/No-path");
    }

    /// @notice view how much of the origin currency the target currency will take
    /// @param _quoteCurrency the address of the quote currency (usually USDC)
    /// @param _origin the address of the origin
    /// @param _target the address of the target
    /// @param _targetAmount the target amount
    /// @return originAmount_ the amount of target that has been swapped for the origin
    function viewTargetSwap(
        address _quoteCurrency,
        address _origin,
        address _target,
        uint256 _targetAmount
    ) public view returns (uint256 originAmount_) {
        // If its an immediate pair then just swap directly on it
        address curve0 = CurveFactory(factory).curves(keccak256(abi.encode(_origin, _target)));
        if (_origin == _quoteCurrency) {
            curve0 = CurveFactory(factory).curves(keccak256(abi.encode(_target, _origin)));
        }

        if (curve0 != address(0)) {
            originAmount_ = Curve(curve0).viewTargetSwap(_origin, _target, _targetAmount);
            return originAmount_;
        }

        // Otherwise go through the quote currency
        curve0 = CurveFactory(factory).curves(keccak256(abi.encode(_target, _quoteCurrency)));
        address curve1 = CurveFactory(factory).curves(keccak256(abi.encode(_origin, _quoteCurrency)));
        if (curve0 != address(0) && curve1 != address(0)) {
            uint256 _quoteAmount = Curve(curve0).viewTargetSwap(_quoteCurrency, _target, _targetAmount);
            originAmount_ = Curve(curve1).viewTargetSwap(_origin, _quoteCurrency, _quoteAmount);
            return originAmount_;
        }

        revert("Router/No-path");
    }
}