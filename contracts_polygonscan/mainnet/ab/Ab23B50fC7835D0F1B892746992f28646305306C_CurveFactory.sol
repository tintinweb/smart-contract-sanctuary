// SPDX-License-Identifier: MIT

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.3;

// Finds new Curves! logs their addresses and provides `isCurve(address) -> (bool)`

import "./Curve.sol";

import "./IFreeFromUpTo.sol";

import "./Ownable.sol";

contract CurveFactory is Ownable {
    event NewCurve(address indexed caller, bytes32 indexed id, address indexed curve);

    mapping(bytes32 => address) public curves;

    function getCurve(address _baseCurrency, address _quoteCurrency) external view returns (address) {
        bytes32 curveId = keccak256(abi.encode(_baseCurrency, _quoteCurrency));
        return (curves[curveId]);
    }

    function newCurve(
        string memory _name,
        string memory _symbol,
        address _baseCurrency,
        address _quoteCurrency,
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _baseAssimilator,
        address _quoteAssimilator
    ) public onlyOwner returns (Curve) {
        bytes32 curveId = keccak256(abi.encode(_baseCurrency, _quoteCurrency));
        if (curves[curveId] != address(0)) revert("CurveFactory/currency-pair-already-exists");

        address[] memory _assets = new address[](10);
        uint256[] memory _assetWeights = new uint256[](2);

        // Base Currency
        _assets[0] = _baseCurrency;
        _assets[1] = _baseAssimilator;
        _assets[2] = _baseCurrency;
        _assets[3] = _baseAssimilator;
        _assets[4] = _baseCurrency;

        // Quote Currency (typically USDC)
        _assets[5] = _quoteCurrency;
        _assets[6] = _quoteAssimilator;
        _assets[7] = _quoteCurrency;
        _assets[8] = _quoteAssimilator;
        _assets[9] = _quoteCurrency;

        // Weights
        _assetWeights[0] = _baseWeight;
        _assetWeights[1] = _quoteWeight;

        // New curve
        Curve curve = new Curve(_name, _symbol, _assets, _assetWeights);
        curve.transferOwnership(msg.sender);
        curves[curveId] = address(curve);

        emit NewCurve(msg.sender, curveId, address(curve));

        return curve;
    }
}