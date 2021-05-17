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

import "./IERC20.sol";

import "./ABDKMath64x64.sol";
import "./IAssimilator.sol";
import "./IOracle.sol";

contract UsdcToUsdAssimilator is IAssimilator {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    IOracle private constant oracle = IOracle(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
    IERC20 private constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // solhint-disable-next-line
    constructor() {}

    // solhint-disable-next-line
    function getRate() public view override returns (uint256) {
        return uint256(oracle.latestAnswer());
    }

    function intakeRawAndGetBalance(uint256 _amount) external override returns (int128 amount_, int128 balance_) {
        bool _success = usdc.transferFrom(msg.sender, address(this), _amount);

        require(_success, "Curve/USDC-transfer-from-failed");

        uint256 _balance = usdc.balanceOf(address(this));

        uint256 _rate = getRate();

        balance_ = ((_balance * _rate) / 1e8).divu(1e6);

        amount_ = ((_amount * _rate) / 1e8).divu(1e6);
    }

    function intakeRaw(uint256 _amount) external override returns (int128 amount_) {
        bool _success = usdc.transferFrom(msg.sender, address(this), _amount);

        require(_success, "Curve/USDC-transfer-from-failed");

        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(1e6);
    }

    function intakeNumeraire(int128 _amount) external override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(1e6) * 1e8) / _rate;

        bool _success = usdc.transferFrom(msg.sender, address(this), amount_);

        require(_success, "Curve/USDC-transfer-from-failed");
    }

    function intakeNumeraireLPRatio(
        // solhint-disable-next-line
        uint256 _baseWeight,
        // solhint-disable-next-line
        uint256 _quoteWeight,
        // solhint-disable-next-line
        address _addr,
        int128 _amount
    ) external override returns (uint256 amount_) {
        amount_ = _amount.mulu(1e6);

        bool _success = usdc.transferFrom(msg.sender, address(this), amount_);

        require(_success, "Curve/USDC-transfer-from-failed");
    }

    function outputRawAndGetBalance(address _dst, uint256 _amount)
        external
        override
        returns (int128 amount_, int128 balance_)
    {
        uint256 _rate = getRate();

        uint256 _usdcAmount = ((_amount * _rate) / 1e8);

        bool _success = usdc.transfer(_dst, _usdcAmount);

        require(_success, "Curve/USDC-transfer-failed");

        uint256 _balance = usdc.balanceOf(address(this));

        amount_ = _usdcAmount.divu(1e6);

        balance_ = ((_balance * _rate) / 1e8).divu(1e6);
    }

    function outputRaw(address _dst, uint256 _amount) external override returns (int128 amount_) {
        uint256 _rate = getRate();

        uint256 _usdcAmount = (_amount * _rate) / 1e8;

        bool _success = usdc.transfer(_dst, _usdcAmount);

        require(_success, "Curve/USDC-transfer-failed");

        amount_ = _usdcAmount.divu(1e6);
    }

    function outputNumeraire(address _dst, int128 _amount) external override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(1e6) * 1e8) / _rate;

        bool _success = usdc.transfer(_dst, amount_);

        require(_success, "Curve/USDC-transfer-failed");
    }

    function viewRawAmount(int128 _amount) external view override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(1e6) * 1e8) / _rate;
    }

    function viewRawAmountLPRatio(
        // solhint-disable-next-line
        uint256 _baseWeight,
        // solhint-disable-next-line
        uint256 _quoteWeight,
        // solhint-disable-next-line
        address _addr,
        int128 _amount
    ) external pure override returns (uint256 amount_) {
        amount_ = _amount.mulu(1e6);
    }

    function viewNumeraireAmount(uint256 _amount) external view override returns (int128 amount_) {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(1e6);
    }

    function viewNumeraireBalance(address _addr) public view override returns (int128 balance_) {
        uint256 _rate = getRate();

        uint256 _balance = usdc.balanceOf(_addr);

        if (_balance <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((_balance * _rate) / 1e8).divu(1e6);
    }

    // views the numeraire value of the current balance of the reserve, in this case xsgd
    // instead of calculating with chainlink's "rate" it'll be determined by the existing
    // token ratio
    // Mainly to protect LP from losing
    function viewNumeraireBalanceLPRatio(
        uint256,
        uint256,
        address _addr
    ) external view override returns (int128 balance_) {
        return viewNumeraireBalance(_addr);
    }

    function viewNumeraireAmountAndBalance(address _addr, uint256 _amount)
        external
        view
        override
        returns (int128 amount_, int128 balance_)
    {
        amount_ = _amount.divu(1e6);

        uint256 _balance = usdc.balanceOf(_addr);

        balance_ = _balance.divu(1e6);
    }
}