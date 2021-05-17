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
import "./SafeMath.sol";

import "./ABDKMath64x64.sol";
import "./IAssimilator.sol";
import "./IOracle.sol";

contract CadcToUsdAssimilator is IAssimilator {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    using SafeMath for uint256;

    IOracle private constant oracle = IOracle(0xa34317DB73e77d453b1B8d04550c44D10e981C8e);
    IERC20 private constant cadc = IERC20(0xcaDC0acd4B445166f12d2C07EAc6E2544FbE2Eef);

    IERC20 private constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // solhint-disable-next-line
    constructor() {}

    function getRate() public view override returns (uint256) {
        (, int256 price, , , ) = oracle.latestRoundData();
        return uint256(price);
    }

    // takes raw cadc amount, transfers it in, calculates corresponding numeraire amount and returns it
    function intakeRawAndGetBalance(uint256 _amount) external override returns (int128 amount_, int128 balance_) {
        bool _transferSuccess = cadc.transferFrom(msg.sender, address(this), _amount);

        require(_transferSuccess, "Curve/CADC-transfer-from-failed");

        uint256 _balance = cadc.balanceOf(address(this));

        uint256 _rate = getRate();

        balance_ = ((_balance * _rate) / 1e8).divu(1e18);

        amount_ = ((_amount * _rate) / 1e8).divu(1e18);
    }

    // takes raw cadc amount, transfers it in, calculates corresponding numeraire amount and returns it
    function intakeRaw(uint256 _amount) external override returns (int128 amount_) {
        bool _transferSuccess = cadc.transferFrom(msg.sender, address(this), _amount);

        require(_transferSuccess, "Curve/cadc-transfer-from-failed");

        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(1e18);
    }

    // takes a numeraire amount, calculates the raw amount of cadc, transfers it in and returns the corresponding raw amount
    function intakeNumeraire(int128 _amount) external override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(1e18) * 1e8) / _rate;

        bool _transferSuccess = cadc.transferFrom(msg.sender, address(this), amount_);

        require(_transferSuccess, "Curve/CADC-transfer-from-failed");
    }

    // takes a numeraire account, calculates the raw amount of cadc, transfers it in and returns the corresponding raw amount
    function intakeNumeraireLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr,
        int128 _amount
    ) external override returns (uint256 amount_) {
        uint256 _cadcBal = cadc.balanceOf(_addr);

        if (_cadcBal <= 0) return 0;

        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in 1e6
        uint256 _rate = _usdcBal.mul(1e18).div(_cadcBal.mul(1e18).div(_baseWeight));

        amount_ = (_amount.mulu(1e18) * 1e6) / _rate;

        bool _transferSuccess = cadc.transferFrom(msg.sender, address(this), amount_);

        require(_transferSuccess, "Curve/CADC-transfer-from-failed");
    }

    // takes a raw amount of cadc and transfers it out, returns numeraire value of the raw amount
    function outputRawAndGetBalance(address _dst, uint256 _amount)
        external
        override
        returns (int128 amount_, int128 balance_)
    {
        uint256 _rate = getRate();

        uint256 _cadcAmount = ((_amount) * _rate) / 1e8;

        bool _transferSuccess = cadc.transfer(_dst, _cadcAmount);

        require(_transferSuccess, "Curve/CADC-transfer-failed");

        uint256 _balance = cadc.balanceOf(address(this));

        amount_ = _cadcAmount.divu(1e18);

        balance_ = ((_balance * _rate) / 1e8).divu(1e18);
    }

    // takes a raw amount of cadc and transfers it out, returns numeraire value of the raw amount
    function outputRaw(address _dst, uint256 _amount) external override returns (int128 amount_) {
        uint256 _rate = getRate();

        uint256 _cadcAmount = (_amount * _rate) / 1e8;

        bool _transferSuccess = cadc.transfer(_dst, _cadcAmount);

        require(_transferSuccess, "Curve/CADC-transfer-failed");

        amount_ = _cadcAmount.divu(1e18);
    }

    // takes a numeraire value of cadc, figures out the raw amount, transfers raw amount out, and returns raw amount
    function outputNumeraire(address _dst, int128 _amount) external override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(1e18) * 1e8) / _rate;

        bool _transferSuccess = cadc.transfer(_dst, amount_);

        require(_transferSuccess, "Curve/CADC-transfer-failed");
    }

    // takes a numeraire amount and returns the raw amount
    function viewRawAmount(int128 _amount) external view override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(1e18) * 1e8) / _rate;
    }

    // takes a numeraire amount and returns the raw amount without the rate
    function viewRawAmountLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr,
        int128 _amount
    ) external view override returns (uint256 amount_) {
        uint256 _cadcBal = cadc.balanceOf(_addr);

        if (_cadcBal <= 0) return 0;

        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in 1e6
        uint256 _rate = _usdcBal.mul(1e18).div(_cadcBal.mul(1e18).div(_baseWeight));

        amount_ = (_amount.mulu(1e18) * 1e6) / _rate;
    }

    // takes a raw amount and returns the numeraire amount
    function viewNumeraireAmount(uint256 _amount) external view override returns (int128 amount_) {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(1e18);
    }

    // views the numeraire value of the current balance of the reserve, in this case cadc
    function viewNumeraireBalance(address _addr) external view override returns (int128 balance_) {
        uint256 _rate = getRate();

        uint256 _balance = cadc.balanceOf(_addr);

        if (_balance <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((_balance * _rate) / 1e8).divu(1e18);
    }

    // views the numeraire value of the current balance of the reserve, in this case cadc
    function viewNumeraireAmountAndBalance(address _addr, uint256 _amount)
        external
        view
        override
        returns (int128 amount_, int128 balance_)
    {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(1e18);

        uint256 _balance = cadc.balanceOf(_addr);

        balance_ = ((_balance * _rate) / 1e8).divu(1e18);
    }

    // views the numeraire value of the current balance of the reserve, in this case cadc
    // instead of calculating with chainlink's "rate" it'll be determined by the existing
    // token ratio. This is in here to prevent LPs from losing out on future oracle price updates
    function viewNumeraireBalanceLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr
    ) external view override returns (int128 balance_) {
        uint256 _cadcBal = cadc.balanceOf(_addr);

        if (_cadcBal <= 0) return ABDKMath64x64.fromUInt(0);

        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in 1e6
        uint256 _rate = _usdcBal.mul(1e18).div(_cadcBal.mul(1e18).div(_baseWeight));

        balance_ = ((_cadcBal * _rate) / 1e6).divu(1e18);
    }
}