/**
 *Submitted for verification at snowtrace.io on 2021-11-12
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

interface IERC20
{
	function balanceOf(address _account) external view returns (uint256 _balanceof);
	function approve(address _spender, uint256 _amount) external returns (bool _success);
	function transfer(address _to, uint256 _amount) external returns (bool _success);
}

interface Pair
{
	function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
	function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes calldata _data) external;
}

interface PSM
{
	// function tin() external view returns (uint256 _tin);
	// function tout() external view returns (uint256 _tout);
	function sellGem(address _account, uint256 _amount) external;
	function buyGem(address _account, uint256 _amount) external;
}

contract BscArb
{
	address constant TREASURY = 0x392681Eaf8AD9BC65e74BE37Afe7503D92802b7d;
	address constant MOR = 0x87BAde473ea0513D4aA7085484aEAA6cB6EBE7e3;
	address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
	address constant APEMORBUSD = 0x33526eD690200663EAAbF28e1D8621e58898c5fd;
	address constant PSMMORBUSD = 0x90F3Fb97a56b83bAE3d26A47f250760CD8FF8cB1;
	address constant JOINMORBUSD = 0xE02CE329281664A5d2BC0006342DC84f6c384663;

	uint256 constant MIN_PROFIT = 1e18; // 1 MOR

	constructor ()
	{
		require(IERC20(MOR).approve(PSMMORBUSD, type(uint256).max));
		require(IERC20(BUSD).approve(JOINMORBUSD, type(uint256).max));
	}

	function rebalance() external
	{
		Pair _pair = Pair(APEMORBUSD);
		(uint256 _reserve0, uint256 _reserve1,) = _pair.getReserves();
		uint256 _mean = _sqrt(_reserve0 * _reserve1);
		if (_reserve1 > _mean && _mean > _reserve0) {
			uint256 _busdAmt = _reserve1 - _mean;
			uint256 _morNetAmt = _mean - _reserve0;
			uint256 _morAmt = _morNetAmt * 10021 / 10000; // a bit more than 1/0.998
			// uint256 _calcMorAmt = _busdAmt - _busdAmt * _psm.tin() / 1e18;
			_pair.swap(0, _busdAmt, address(this), abi.encode(_morAmt));
			return;
		}
		if (_reserve0 > _mean && _mean > _reserve1) {
			uint256 _morAmt = _reserve0 - _mean;
			uint256 _busdNetAmt = _mean - _reserve1;
			uint256 _busdAmt = _busdNetAmt * 10021 / 10000; // a bit more than 1/0.998
			uint256 _busdPsmAmt = IERC20(BUSD).balanceOf(JOINMORBUSD);
			if (_busdAmt > _busdPsmAmt) {
				_morAmt = _morAmt * _busdPsmAmt / _busdAmt;
				_busdAmt = _busdPsmAmt;
			}
			// uint256 _calcMorAmt = _busdAmt + _busdAmt * _psm.tout() / 1e18;
			_pair.swap(_morAmt, 0, address(this), abi.encode(_busdAmt));
			return;
		}
		require(false, "balanced");
	}

	function pancakeCall(address, uint256 _morAmt, uint256 _busdAmt, bytes calldata _data) external
	{
		if (_busdAmt > 0) {
			_morAmt = abi.decode(_data, (uint256));
			PSM(PSMMORBUSD).sellGem(address(this), _busdAmt);
			require(IERC20(MOR).transfer(msg.sender, _morAmt));
		} else {
			_busdAmt = abi.decode(_data, (uint256));
			PSM(PSMMORBUSD).buyGem(msg.sender, _busdAmt);
		}
		uint256 _balance = IERC20(MOR).balanceOf(address(this));
		require(_balance >= MIN_PROFIT, "unprofitable");
		require(IERC20(MOR).transfer(TREASURY, _balance));
	}

	function _sqrt(uint256 _y) internal pure returns (uint256 _z)
	{
		if (_y > 3) {
			_z = _y;
			uint256 _x = _y / 2 + 1;
			while (_x < _z) {
				_z = _x;
				_x = (_y / _x + _x) / 2;
			}
			return _z;
		}
		if (_y > 0) return 1;
		return 0;
	}
}

contract AvaxArb
{
	address constant TREASURY = 0x1d64CeAF2cDBC9b6d41eB0f2f7CDA8F04c47d1Ac;
	address constant MOR = 0x87BAde473ea0513D4aA7085484aEAA6cB6EBE7e3;
	address constant USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
	address constant TDJMORUSDC = 0xBbdA95e89e5D65a5D1178dB1aDC0D62D1c6f4BB3;
	address constant BRDGMORUSDC = 0xE0327dA3f94Efe600569Ca68Aa02e6921FD89Bfa;
	address constant JOINMORUSDC = 0x65764167EC4B38D611F961515B51a40628614018;

	uint256 constant MIN_PROFIT = 1e18; // 1 MOR

	constructor ()
	{
		require(IERC20(MOR).approve(BRDGMORUSDC, type(uint256).max));
		require(IERC20(USDC).approve(BRDGMORUSDC, type(uint256).max));
	}

	function rebalance() external
	{
		Pair _pair = Pair(TDJMORUSDC);
		(uint256 _reserve0, uint256 _reserve1,) = _pair.getReserves();
		_reserve1 *= 1e12;
		uint256 _mean = _sqrt(_reserve0 * _reserve1);
		if (_reserve1 > _mean && _mean > _reserve0) {
			uint256 _usdcAmt = _reserve1 - _mean;
			uint256 _morNetAmt = _mean - _reserve0;
			uint256 _morAmt = _morNetAmt * 10031 / 10000; // a bit more than 1/0.997
			// uint256 _calcMorAmt = _usdcAmt - _usdcAmt * _psm.tin() / 1e18;
			_usdcAmt /= 1e12;
			_pair.swap(0, _usdcAmt, address(this), abi.encode(_morAmt));
			return;
		}
		if (_reserve0 > _mean && _mean > _reserve1) {
			uint256 _morAmt = _reserve0 - _mean;
			uint256 _usdcNetAmt = _mean - _reserve1;
			uint256 _usdcAmt = _usdcNetAmt * 10031 / 10000; // a bit more than 1/0.997
			uint256 _usdcPsmAmt = IERC20(USDC).balanceOf(JOINMORUSDC);
			_usdcPsmAmt *= 1e12;
			if (_usdcAmt > _usdcPsmAmt) {
				_morAmt = _morAmt * _usdcPsmAmt / _usdcAmt;
				_usdcAmt = _usdcPsmAmt;
			}
			// uint256 _calcMorAmt = _usdcAmt + _usdcAmt * _psm.tout() / 1e18;
			_usdcAmt /= 1e12;
			_pair.swap(_morAmt, 0, address(this), abi.encode(_usdcAmt));
			return;
		}
		require(false, "balanced");
	}

	function joeCall(address, uint256 _morAmt, uint256 _usdcAmt, bytes calldata _data) external
	{
		if (_usdcAmt > 0) {
			_morAmt = abi.decode(_data, (uint256));
			PSM(BRDGMORUSDC).sellGem(address(this), _usdcAmt);
			require(IERC20(MOR).transfer(msg.sender, _morAmt));
		} else {
			_usdcAmt = abi.decode(_data, (uint256));
			PSM(BRDGMORUSDC).buyGem(msg.sender, _usdcAmt);
		}
		uint256 _balance = IERC20(MOR).balanceOf(address(this));
		require(_balance >= MIN_PROFIT, "unprofitable");
		require(IERC20(MOR).transfer(TREASURY, _balance));
	}

	function _sqrt(uint256 _y) internal pure returns (uint256 _z)
	{
		if (_y > 3) {
			_z = _y;
			uint256 _x = _y / 2 + 1;
			while (_x < _z) {
				_z = _x;
				_x = (_y / _x + _x) / 2;
			}
			return _z;
		}
		if (_y > 0) return 1;
		return 0;
	}
}